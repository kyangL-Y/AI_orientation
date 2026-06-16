"""
统计智能体 - 并行获取用户学习数据

职责：
1. 并行获取学习时长、课程进度、考试成绩、错题分布、部门排名
2. 支持独立运行和数据缓存
3. 数据缺失时自动兜底
"""

import asyncio
import time
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta
import pymysql
from pymysql.cursors import DictCursor
import structlog
from tenacity import retry, stop_after_attempt, wait_exponential

from ..models.state import (
    AgentState, StatisticsData, LearningDuration, CourseProgress,
    ExamScore, WrongQuestionDistribution, DepartmentRanking
)
from ..utils.cache import CacheManager
from ..utils.database import DatabaseManager
from ..config import settings

logger = structlog.get_logger(__name__)


class StatisticsAgent:
    """统计智能体 - 并行数据采集"""

    def __init__(self, cache_manager: CacheManager, db_manager: DatabaseManager):
        self.cache_manager = cache_manager
        self.db_manager = db_manager
        self.agent_name = "statistics"
        self.logger = logger.bind(agent=self.agent_name)

    async def execute(self, state: AgentState) -> AgentState:
        """执行统计任务"""
        start_time = time.time()
        self.logger.info("statistics_agent_started", user_id=state["user_id"])

        try:
            # 检查缓存
            cache_key = self._build_cache_key(state)
            cached_result = await self.cache_manager.get(cache_key)

            if cached_result and settings.ENABLE_RESULT_CACHE:
                self.logger.info("cache_hit", cache_key=cache_key)
                state["cache_hits"].append(self.agent_name)
                state["statistics_data"] = StatisticsData(**cached_result)
                state["data_completeness"] = cached_result.get("data_completeness", 1.0)
                return state

            state["cache_misses"].append(self.agent_name)

            # 并行执行所有统计任务
            tasks = [
                self._get_learning_duration(state),
                self._get_course_progress(state),
                self._get_exam_score(state),
                self._get_wrong_question_distribution(state),
                self._get_department_ranking(state),
            ]

            results = await asyncio.gather(*tasks, return_exceptions=True)

            # 解析结果
            learning_duration, course_progress, exam_score, wrong_dist, dept_ranking = results

            # 构建统计数据
            statistics_data = StatisticsData(
                learning_duration=learning_duration if not isinstance(learning_duration, Exception) else None,
                course_progress=course_progress if not isinstance(course_progress, Exception) else None,
                exam_score=exam_score if not isinstance(exam_score, Exception) else None,
                wrong_question_distribution=wrong_dist if not isinstance(wrong_dist, Exception) else None,
                department_ranking=dept_ranking if not isinstance(dept_ranking, Exception) else None,
                data_completeness=0.0,  # 将在下面计算
                missing_fields=[]
            )

            # 计算数据完整度
            completeness, missing_fields = self._calculate_completeness(statistics_data)
            statistics_data.data_completeness = completeness
            statistics_data.missing_fields = missing_fields

            # 更新状态
            state["statistics_data"] = statistics_data
            state["data_completeness"] = completeness
            state["agents_executed"].append(self.agent_name)

            # 记录错误
            errors = [r for r in results if isinstance(r, Exception)]
            if errors:
                state["statistics_errors"] = [str(e) for e in errors]
                self.logger.warning("partial_data_collected", error_count=len(errors))

            # 缓存结果
            if settings.ENABLE_RESULT_CACHE:
                await self.cache_manager.set(
                    cache_key,
                    statistics_data.dict(),
                    ttl=settings.CACHE_DURATION_SECONDS
                )

            execution_time = (time.time() - start_time) * 1000
            state["agent_timings"][self.agent_name] = execution_time

            self.logger.info(
                "statistics_agent_completed",
                execution_time_ms=execution_time,
                completeness=completeness,
                missing_fields=missing_fields
            )

            return state

        except Exception as e:
            self.logger.error("statistics_agent_failed", error=str(e), exc_info=True)
            state["errors"].append({
                "agent": self.agent_name,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            })
            # 返回空数据结构，让后续智能体可以使用兜底逻辑
            state["statistics_data"] = StatisticsData(
                data_completeness=0.0,
                missing_fields=["all"]
            )
            state["data_completeness"] = 0.0
            return state

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=5),
        reraise=True
    )
    async def _get_learning_duration(self, state: AgentState) -> LearningDuration:
        """获取学习时长数据"""
        self.logger.debug("fetching_learning_duration", user_id=state["user_id"])

        query = """
            SELECT
                DATE(create_time) as date,
                SUM(duration_minutes) as minutes
            FROM train_learning_log
            WHERE user_id = %s
                AND create_time BETWEEN %s AND %s
                AND tenant_id = %s
            GROUP BY DATE(create_time)
            ORDER BY date
        """

        async with self.db_manager.get_connection() as conn:
            async with conn.cursor(DictCursor) as cursor:
                await cursor.execute(query, (
                    state["user_id"],
                    state["period_start"],
                    state["period_end"],
                    state["tenant_id"]
                ))
                rows = await cursor.fetchall()

        if not rows:
            return LearningDuration(
                total_minutes=0,
                daily_average=0.0,
                trend="stable",
                details={}
            )

        details = {row["date"].isoformat(): row["minutes"] for row in rows}
        total_minutes = sum(row["minutes"] for row in rows)
        days = (state["period_end"] - state["period_start"]).days + 1
        daily_average = total_minutes / days if days > 0 else 0

        # 计算趋势
        trend = self._calculate_trend([row["minutes"] for row in rows])

        return LearningDuration(
            total_minutes=total_minutes,
            daily_average=round(daily_average, 2),
            trend=trend,
            details=details
        )

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=5),
        reraise=True
    )
    async def _get_course_progress(self, state: AgentState) -> CourseProgress:
        """获取课程进度数据"""
        self.logger.debug("fetching_course_progress", user_id=state["user_id"])

        query = """
            SELECT
                c.course_id,
                c.course_name,
                uc.progress,
                uc.status,
                uc.start_time,
                uc.complete_time
            FROM train_user_course uc
            JOIN train_course c ON uc.course_id = c.course_id
            WHERE uc.user_id = %s
                AND uc.tenant_id = %s
                AND (uc.start_time BETWEEN %s AND %s
                     OR uc.complete_time BETWEEN %s AND %s)
        """

        async with self.db_manager.get_connection() as conn:
            async with conn.cursor(DictCursor) as cursor:
                await cursor.execute(query, (
                    state["user_id"],
                    state["tenant_id"],
                    state["period_start"],
                    state["period_end"],
                    state["period_start"],
                    state["period_end"]
                ))
                rows = await cursor.fetchall()

        course_details = []
        completed_count = 0
        in_progress_count = 0

        for row in rows:
            course_details.append({
                "course_id": row["course_id"],
                "course_name": row["course_name"],
                "progress": row["progress"],
                "status": row["status"]
            })

            if row["status"] == "completed":
                completed_count += 1
            elif row["status"] == "in_progress":
                in_progress_count += 1

        total_courses = len(course_details)
        completion_rate = (completed_count / total_courses * 100) if total_courses > 0 else 0

        return CourseProgress(
            total_courses=total_courses,
            completed_courses=completed_count,
            in_progress_courses=in_progress_count,
            completion_rate=round(completion_rate, 2),
            course_details=course_details
        )

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=5),
        reraise=True
    )
    async def _get_exam_score(self, state: AgentState) -> ExamScore:
        """获取考试成绩数据"""
        self.logger.debug("fetching_exam_score", user_id=state["user_id"])

        query = """
            SELECT
                qa.attempt_id,
                qa.quiz_id,
                q.quiz_name,
                qa.score,
                qa.total_score,
                qa.pass_status,
                qa.submit_time
            FROM train_quiz_attempt qa
            JOIN train_quiz q ON qa.quiz_id = q.quiz_id
            WHERE qa.user_id = %s
                AND qa.tenant_id = %s
                AND qa.submit_time BETWEEN %s AND %s
                AND qa.status = 'completed'
            ORDER BY qa.submit_time DESC
        """

        async with self.db_manager.get_connection() as conn:
            async with conn.cursor(DictCursor) as cursor:
                await cursor.execute(query, (
                    state["user_id"],
                    state["tenant_id"],
                    state["period_start"],
                    state["period_end"]
                ))
                rows = await cursor.fetchall()

        if not rows:
            return ExamScore(
                total_exams=0,
                average_score=0.0,
                highest_score=0.0,
                lowest_score=0.0,
                pass_rate=0.0,
                recent_exams=[]
            )

        scores = [row["score"] for row in rows]
        passed = sum(1 for row in rows if row["pass_status"] == "passed")

        recent_exams = [{
            "quiz_name": row["quiz_name"],
            "score": row["score"],
            "total_score": row["total_score"],
            "pass_status": row["pass_status"],
            "submit_time": row["submit_time"].isoformat()
        } for row in rows[:10]]  # 最近10次考试

        return ExamScore(
            total_exams=len(rows),
            average_score=round(sum(scores) / len(scores), 2),
            highest_score=max(scores),
            lowest_score=min(scores),
            pass_rate=round(passed / len(rows) * 100, 2),
            recent_exams=recent_exams
        )

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=5),
        reraise=True
    )
    async def _get_wrong_question_distribution(self, state: AgentState) -> WrongQuestionDistribution:
        """获取错题分布数据"""
        self.logger.debug("fetching_wrong_questions", user_id=state["user_id"])

        query = """
            SELECT
                aa.answer_id,
                aa.question_id,
                q.question_text,
                q.category,
                aa.user_answer,
                aa.correct_answer,
                aa.is_correct,
                aa.answer_time
            FROM train_answer_attempt aa
            JOIN train_question q ON aa.question_id = q.id
            WHERE aa.user_id = %s
                AND aa.tenant_id = %s
                AND aa.answer_time BETWEEN %s AND %s
                AND aa.is_correct = 0
            ORDER BY aa.answer_time DESC
            LIMIT 50
        """

        async with self.db_manager.get_connection() as conn:
            async with conn.cursor(DictCursor) as cursor:
                await cursor.execute(query, (
                    state["user_id"],
                    state["tenant_id"],
                    state["period_start"],
                    state["period_end"]
                ))
                rows = await cursor.fetchall()

        # 按分类统计
        category_distribution = {}
        for row in rows:
            category = row["category"] or "未分类"
            category_distribution[category] = category_distribution.get(category, 0) + 1

        # 提取高频错误知识点
        high_frequency = sorted(
            category_distribution.items(),
            key=lambda x: x[1],
            reverse=True
        )[:5]

        recent_wrong = [{
            "question_id": row["question_id"],
            "question_text": row["question_text"][:100],  # 截断过长文本
            "category": row["category"],
            "user_answer": row["user_answer"],
            "correct_answer": row["correct_answer"]
        } for row in rows[:15]]

        return WrongQuestionDistribution(
            total_wrong_count=len(rows),
            category_distribution=category_distribution,
            recent_wrong_questions=recent_wrong,
            high_frequency_errors=[cat for cat, _ in high_frequency]
        )

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=5),
        reraise=True
    )
    async def _get_department_ranking(self, state: AgentState) -> DepartmentRanking:
        """获取部门排名数据"""
        self.logger.debug("fetching_department_ranking", user_id=state["user_id"])

        # 获取用户所属部门
        dept_id = state.get("dept_id")
        if not dept_id:
            dept_id = await self._get_user_dept_id(state["user_id"], state["tenant_id"])

        if not dept_id:
            return DepartmentRanking(
                user_rank=None,
                total_users=None,
                user_score=0.0,
                dept_average_score=0.0,
                percentile=None
            )

        # 获取部门所有用户的得分
        query = """
            SELECT
                lr.user_id,
                lr.total_score
            FROM train_learning_report lr
            JOIN sys_user u ON lr.user_id = u.user_id
            WHERE u.dept_id = %s
                AND lr.tenant_id = %s
                AND lr.period_type = %s
                AND lr.period_start = %s
                AND lr.period_end = %s
            ORDER BY lr.total_score DESC
        """

        async with self.db_manager.get_connection() as conn:
            async with conn.cursor(DictCursor) as cursor:
                await cursor.execute(query, (
                    dept_id,
                    state["tenant_id"],
                    state["period_type"],
                    state["period_start"],
                    state["period_end"]
                ))
                rows = await cursor.fetchall()

        if not rows:
            return DepartmentRanking(
                user_rank=None,
                total_users=0,
                user_score=0.0,
                dept_average_score=0.0,
                percentile=None
            )

        scores = [row["total_score"] for row in rows]
        user_ids = [row["user_id"] for row in rows]

        user_score = 0.0
        user_rank = None

        if state["user_id"] in user_ids:
            user_idx = user_ids.index(state["user_id"])
            user_score = scores[user_idx]
            user_rank = user_idx + 1

        dept_average = sum(scores) / len(scores) if scores else 0.0
        percentile = ((len(scores) - user_rank + 1) / len(scores) * 100) if user_rank else None

        return DepartmentRanking(
            user_rank=user_rank,
            total_users=len(rows),
            user_score=user_score,
            dept_average_score=round(dept_average, 2),
            percentile=round(percentile, 2) if percentile else None
        )

    async def _get_user_dept_id(self, user_id: int, tenant_id: str) -> Optional[int]:
        """获取用户所属部门ID"""
        query = """
            SELECT dept_id
            FROM sys_user
            WHERE user_id = %s AND tenant_id = %s AND del_flag = '0'
        """

        async with self.db_manager.get_connection() as conn:
            async with conn.cursor(DictCursor) as cursor:
                await cursor.execute(query, (user_id, tenant_id))
                row = await cursor.fetchone()
                return row["dept_id"] if row else None

    def _calculate_completeness(self, data: StatisticsData) -> tuple[float, List[str]]:
        """计算数据完整度"""
        fields = {
            "learning_duration": data.learning_duration,
            "course_progress": data.course_progress,
            "exam_score": data.exam_score,
            "wrong_question_distribution": data.wrong_question_distribution,
            "department_ranking": data.department_ranking,
        }

        present_count = sum(1 for v in fields.values() if v is not None)
        total_count = len(fields)
        completeness = present_count / total_count

        missing_fields = [k for k, v in fields.items() if v is None]

        return completeness, missing_fields

    def _calculate_trend(self, values: List[float]) -> str:
        """计算趋势"""
        if len(values) < 2:
            return "stable"

        # 简单线性趋势判断
        first_half = sum(values[:len(values)//2]) / (len(values)//2)
        second_half = sum(values[len(values)//2:]) / (len(values) - len(values)//2)

        if second_half > first_half * 1.1:
            return "increasing"
        elif second_half < first_half * 0.9:
            return "decreasing"
        else:
            return "stable"

    def _build_cache_key(self, state: AgentState) -> str:
        """构建缓存键"""
        return f"agent:statistics:{state['user_id']}:{state['period_type']}:{state['period_start'].date()}:{state['period_end'].date()}"
