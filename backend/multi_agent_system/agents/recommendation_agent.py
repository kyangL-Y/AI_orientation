"""
推荐智能体 - 根据薄弱点推荐复习内容和下一步课程

职责：
1. 根据薄弱点和错题记录推荐待复习内容
2. 推荐下一步课程（基于当前进度和知识图谱）
3. 生成学习计划摘要和预期提升效果
4. 数据缺失时使用通用推荐
"""

import time
from typing import List, Dict, Any
from datetime import datetime
import structlog
from tenacity import retry, stop_after_attempt, wait_exponential

from ..models.state import (
    AgentState, StatisticsData, AnalysisResult, RecommendationResult,
    ReviewContent, NextCourse
)
from ..utils.cache import CacheManager
from ..utils.database import DatabaseManager
from ..utils.ai_client import AIClient
from ..config import settings

logger = structlog.get_logger(__name__)


class RecommendationAgent:
    """推荐智能体 - 个性化学习推荐"""

    def __init__(
        self,
        cache_manager: CacheManager,
        db_manager: DatabaseManager,
        ai_client: AIClient
    ):
        self.cache_manager = cache_manager
        self.db_manager = db_manager
        self.ai_client = ai_client
        self.agent_name = "recommendation"
        self.logger = logger.bind(agent=self.agent_name)

    async def execute(self, state: AgentState) -> AgentState:
        """执行推荐任务"""
        start_time = time.time()
        self.logger.info("recommendation_agent_started", user_id=state["user_id"])

        try:
            # 检查是否应该跳过推荐
            if state.get("should_skip_recommendation", False):
                self.logger.info("recommendation_skipped", reason="should_skip_recommendation flag set")
                state["agents_executed"].append(self.agent_name)
                return state

            # 检查依赖数据
            statistics_data = state.get("statistics_data")
            analysis_result = state.get("analysis_result")

            if not statistics_data and not analysis_result:
                self.logger.warning("no_dependency_data", message="Using fallback recommendation")
                state["recommendation_result"] = self._create_fallback_recommendation()
                state["agents_executed"].append(self.agent_name)
                return state

            # 检查缓存
            cache_key = self._build_cache_key(state)
            cached_result = await self.cache_manager.get(cache_key)

            if cached_result and settings.ENABLE_RESULT_CACHE:
                self.logger.info("cache_hit", cache_key=cache_key)
                state["cache_hits"].append(self.agent_name)
                state["recommendation_result"] = RecommendationResult(**cached_result)
                return state

            state["cache_misses"].append(self.agent_name)

            # 执行推荐
            review_contents = await self._recommend_review_contents(
                state, statistics_data, analysis_result
            )

            next_courses = await self._recommend_next_courses(
                state, statistics_data, analysis_result
            )

            # 生成学习计划摘要
            study_plan = await self._generate_study_plan(
                state, review_contents, next_courses
            )

            # 预期提升效果
            improvement = await self._estimate_improvement(
                state, analysis_result, review_contents, next_courses
            )

            # 构建推荐结果
            recommendation_result = RecommendationResult(
                review_contents=review_contents,
                next_courses=next_courses,
                study_plan_summary=study_plan,
                estimated_improvement=improvement
            )

            # 更新状态
            state["recommendation_result"] = recommendation_result
            state["agents_executed"].append(self.agent_name)

            # 缓存结果
            if settings.ENABLE_RESULT_CACHE:
                await self.cache_manager.set(
                    cache_key,
                    recommendation_result.dict(),
                    ttl=settings.CACHE_DURATION_SECONDS
                )

            execution_time = (time.time() - start_time) * 1000
            state["agent_timings"][self.agent_name] = execution_time

            self.logger.info(
                "recommendation_agent_completed",
                execution_time_ms=execution_time,
                review_count=len(review_contents),
                course_count=len(next_courses)
            )

            return state

        except Exception as e:
            self.logger.error("recommendation_agent_failed", error=str(e), exc_info=True)
            state["errors"].append({
                "agent": self.agent_name,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            })
            state["recommendation_errors"] = [str(e)]
            state["recommendation_result"] = self._create_fallback_recommendation()
            return state

    async def _recommend_review_contents(
        self,
        state: AgentState,
        statistics_data: StatisticsData,
        analysis_result: AnalysisResult
    ) -> List[ReviewContent]:
        """推荐待复习内容"""
        self.logger.debug("recommending_review_contents")
        review_contents = []

        # 策略1: 基于薄弱知识点推荐错题
        if analysis_result and analysis_result.weak_points:
            for weak_point in analysis_result.weak_points[:5]:  # 前5个薄弱点
                # 获取该分类的错题
                wrong_questions = await self._get_wrong_questions_by_category(
                    state["user_id"],
                    state["tenant_id"],
                    weak_point.category,
                    limit=3
                )

                for question in wrong_questions:
                    review_contents.append(ReviewContent(
                        content_type="question",
                        content_id=str(question["question_id"]),
                        title=question["question_text"][:50] + "...",
                        category=weak_point.category,
                        priority="high" if weak_point.severity == "high" else "medium",
                        reason=f"该题属于薄弱知识点「{weak_point.category}」，错误率{weak_point.error_rate}%"
                    ))

        # 策略2: 基于错题分布推荐相关课程
        if statistics_data and statistics_data.wrong_question_distribution:
            high_freq_errors = statistics_data.wrong_question_distribution.high_frequency_errors[:3]

            for category in high_freq_errors:
                courses = await self._get_courses_by_category(
                    category,
                    state["tenant_id"],
                    limit=2
                )

                for course in courses:
                    review_contents.append(ReviewContent(
                        content_type="course",
                        content_id=str(course["course_id"]),
                        title=course["course_name"],
                        category=category,
                        priority="medium",
                        reason=f"该课程涵盖「{category}」知识点，可帮助巩固薄弱环节"
                    ))

        # 按优先级排序
        priority_order = {"high": 0, "medium": 1, "low": 2}
        review_contents.sort(key=lambda x: priority_order[x.priority])

        return review_contents[:10]  # 限制返回数量

    async def _get_wrong_questions_by_category(
        self,
        user_id: int,
        tenant_id: str,
        category: str,
        limit: int = 3
    ) -> List[Dict[str, Any]]:
        """获取某个分类的错题"""
        query = """
            SELECT DISTINCT
                aa.question_id,
                q.question_text,
                q.category
            FROM train_answer_attempt aa
            JOIN train_question q ON aa.question_id = q.id
            WHERE aa.user_id = %s
                AND aa.tenant_id = %s
                AND q.category = %s
                AND aa.is_correct = 0
            ORDER BY aa.answer_time DESC
            LIMIT %s
        """

        try:
            async with self.db_manager.get_connection() as conn:
                async with conn.cursor() as cursor:
                    await cursor.execute(query, (user_id, tenant_id, category, limit))
                    rows = await cursor.fetchall()
                    return [
                        {
                            "question_id": row[0],
                            "question_text": row[1],
                            "category": row[2]
                        }
                        for row in rows
                    ]
        except Exception as e:
            self.logger.warning("get_wrong_questions_failed", error=str(e))
            return []

    async def _get_courses_by_category(
        self,
        category: str,
        tenant_id: str,
        limit: int = 2
    ) -> List[Dict[str, Any]]:
        """根据分类获取课程"""
        query = """
            SELECT
                course_id,
                course_name,
                category
            FROM train_course
            WHERE tenant_id = %s
                AND (category LIKE %s OR course_name LIKE %s)
                AND status = '1'
            LIMIT %s
        """

        try:
            category_pattern = f"%{category}%"
            async with self.db_manager.get_connection() as conn:
                async with conn.cursor() as cursor:
                    await cursor.execute(
                        query,
                        (tenant_id, category_pattern, category_pattern, limit)
                    )
                    rows = await cursor.fetchall()
                    return [
                        {
                            "course_id": row[0],
                            "course_name": row[1],
                            "category": row[2]
                        }
                        for row in rows
                    ]
        except Exception as e:
            self.logger.warning("get_courses_by_category_failed", error=str(e))
            return []

    async def _recommend_next_courses(
        self,
        state: AgentState,
        statistics_data: StatisticsData,
        analysis_result: AnalysisResult
    ) -> List[NextCourse]:
        """推荐下一步课程"""
        self.logger.debug("recommending_next_courses")
        next_courses = []

        # 策略1: 基于课程进度推荐后续课程
        if statistics_data and statistics_data.course_progress:
            completed_course_ids = [
                c["course_id"]
                for c in statistics_data.course_progress.course_details
                if c["status"] == "completed"
            ]

            if completed_course_ids:
                follow_up_courses = await self._get_follow_up_courses(
                    completed_course_ids,
                    state["tenant_id"],
                    limit=3
                )

                for course in follow_up_courses:
                    next_courses.append(NextCourse(
                        course_id=str(course["course_id"]),
                        course_name=course["course_name"],
                        category=course.get("category", "未分类"),
                        difficulty=self._infer_difficulty(course),
                        estimated_duration=course.get("duration", 60),
                        relevance_score=0.9,
                        reason="基于已完成课程的进阶学习路径"
                    ))

        # 策略2: 基于薄弱点推荐针对性课程
        if analysis_result and analysis_result.weak_points:
            for weak_point in analysis_result.weak_points[:2]:
                targeted_courses = await self._get_courses_by_category(
                    weak_point.category,
                    state["tenant_id"],
                    limit=2
                )

                for course in targeted_courses:
                    # 避免重复推荐
                    if any(nc.course_id == str(course["course_id"]) for nc in next_courses):
                        continue

                    next_courses.append(NextCourse(
                        course_id=str(course["course_id"]),
                        course_name=course["course_name"],
                        category=weak_point.category,
                        difficulty="intermediate",
                        estimated_duration=60,
                        relevance_score=0.85,
                        reason=f"针对薄弱知识点「{weak_point.category}」的专项提升课程"
                    ))

        # 策略3: 推荐热门课程（兜底）
        if len(next_courses) < 3:
            popular_courses = await self._get_popular_courses(
                state["tenant_id"],
                limit=5 - len(next_courses)
            )

            for course in popular_courses:
                if any(nc.course_id == str(course["course_id"]) for nc in next_courses):
                    continue

                next_courses.append(NextCourse(
                    course_id=str(course["course_id"]),
                    course_name=course["course_name"],
                    category=course.get("category", "通用"),
                    difficulty="intermediate",
                    estimated_duration=course.get("duration", 60),
                    relevance_score=0.7,
                    reason="平台热门课程推荐"
                ))

        # 按相关性排序
        next_courses.sort(key=lambda x: x.relevance_score, reverse=True)

        return next_courses[:5]  # 限制返回数量

    async def _get_follow_up_courses(
        self,
        completed_course_ids: List[int],
        tenant_id: str,
        limit: int = 3
    ) -> List[Dict[str, Any]]:
        """获取后续课程（基于课程关联）"""
        # 这里简化处理，实际应该有课程依赖关系表
        query = """
            SELECT
                course_id,
                course_name,
                category,
                duration
            FROM train_course
            WHERE tenant_id = %s
                AND status = '1'
                AND course_id NOT IN ({})
            ORDER BY sort_order ASC
            LIMIT %s
        """.format(','.join(['%s'] * len(completed_course_ids)))

        try:
            async with self.db_manager.get_connection() as conn:
                async with conn.cursor() as cursor:
                    await cursor.execute(
                        query,
                        (tenant_id, *completed_course_ids, limit)
                    )
                    rows = await cursor.fetchall()
                    return [
                        {
                            "course_id": row[0],
                            "course_name": row[1],
                            "category": row[2],
                            "duration": row[3]
                        }
                        for row in rows
                    ]
        except Exception as e:
            self.logger.warning("get_follow_up_courses_failed", error=str(e))
            return []

    async def _get_popular_courses(
        self,
        tenant_id: str,
        limit: int = 5
    ) -> List[Dict[str, Any]]:
        """获取热门课程"""
        query = """
            SELECT
                c.course_id,
                c.course_name,
                c.category,
                c.duration,
                COUNT(uc.user_id) as learner_count
            FROM train_course c
            LEFT JOIN train_user_course uc ON c.course_id = uc.course_id
            WHERE c.tenant_id = %s
                AND c.status = '1'
            GROUP BY c.course_id
            ORDER BY learner_count DESC, c.create_time DESC
            LIMIT %s
        """

        try:
            async with self.db_manager.get_connection() as conn:
                async with conn.cursor() as cursor:
                    await cursor.execute(query, (tenant_id, limit))
                    rows = await cursor.fetchall()
                    return [
                        {
                            "course_id": row[0],
                            "course_name": row[1],
                            "category": row[2],
                            "duration": row[3]
                        }
                        for row in rows
                    ]
        except Exception as e:
            self.logger.warning("get_popular_courses_failed", error=str(e))
            return []

    def _infer_difficulty(self, course: Dict[str, Any]) -> str:
        """推断课程难度"""
        # 简单规则推断，实际应该从课程元数据中获取
        course_name = course.get("course_name", "").lower()

        if any(keyword in course_name for keyword in ["入门", "基础", "初级", "beginner"]):
            return "beginner"
        elif any(keyword in course_name for keyword in ["高级", "进阶", "advanced"]):
            return "advanced"
        else:
            return "intermediate"

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        reraise=True
    )
    async def _generate_study_plan(
        self,
        state: AgentState,
        review_contents: List[ReviewContent],
        next_courses: List[NextCourse]
    ) -> str:
        """生成学习计划摘要"""
        self.logger.debug("generating_study_plan")

        prompt = self._build_study_plan_prompt(review_contents, next_courses)

        try:
            plan = await self.ai_client.generate_text(
                prompt=prompt,
                max_tokens=300,
                temperature=0.7
            )
            return plan.strip()
        except Exception as e:
            self.logger.warning("ai_study_plan_failed", error=str(e))
            return self._generate_rule_based_plan(review_contents, next_courses)

    def _build_study_plan_prompt(
        self,
        review_contents: List[ReviewContent],
        next_courses: List[NextCourse]
    ) -> str:
        """构建学习计划提示词"""
        prompt = "请基于以下推荐内容，生成一份简洁的学习计划（100-150字）：\n\n"

        if review_contents:
            prompt += "【待复习内容】\n"
            high_priority = [rc for rc in review_contents if rc.priority == "high"]
            if high_priority:
                prompt += f"- 高优先级: {len(high_priority)}项（错题和薄弱知识点）\n"
            prompt += f"- 总计: {len(review_contents)}项内容需要复习\n\n"

        if next_courses:
            prompt += "【推荐课程】\n"
            for course in next_courses[:3]:
                prompt += f"- {course.course_name} ({course.difficulty}, 约{course.estimated_duration}分钟)\n"
            prompt += "\n"

        prompt += "请用温暖、鼓励的语气，给出具体可执行的学习计划建议（包括时间安排和学习顺序）。"

        return prompt

    def _generate_rule_based_plan(
        self,
        review_contents: List[ReviewContent],
        next_courses: List[NextCourse]
    ) -> str:
        """基于规则生成学习计划（AI失败时的兜底）"""
        parts = []

        if review_contents:
            high_priority = [rc for rc in review_contents if rc.priority == "high"]
            if high_priority:
                parts.append(f"建议优先复习{len(high_priority)}个高频错题和薄弱知识点，巩固基础。")
            else:
                parts.append(f"建议系统复习{len(review_contents)}项内容，查漏补缺。")

        if next_courses:
            parts.append(f"推荐学习{len(next_courses)}门课程，按难度循序渐进。")
            total_duration = sum(c.estimated_duration for c in next_courses)
            parts.append(f"预计总学习时长{total_duration}分钟，建议分3-5天完成。")

        if not parts:
            parts.append("当前学习进度良好，建议保持学习节奏，持续提升。")

        return " ".join(parts)

    async def _estimate_improvement(
        self,
        state: AgentState,
        analysis_result: AnalysisResult,
        review_contents: List[ReviewContent],
        next_courses: List[NextCourse]
    ) -> str:
        """预期提升效果"""
        self.logger.debug("estimating_improvement")

        parts = []

        # 基于复习内容预估
        if review_contents:
            high_priority_count = sum(1 for rc in review_contents if rc.priority == "high")
            if high_priority_count >= 5:
                parts.append("完成复习后，薄弱知识点正确率预计提升15-20%")
            elif high_priority_count >= 3:
                parts.append("完成复习后，薄弱知识点正确率预计提升10-15%")
            else:
                parts.append("完成复习后，薄弱知识点正确率预计提升5-10%")

        # 基于课程学习预估
        if next_courses:
            parts.append(f"完成{len(next_courses)}门推荐课程后，综合能力将得到显著提升")

        # 基于当前分析结果
        if analysis_result and analysis_result.weak_points:
            weak_categories = [wp.category for wp in analysis_result.weak_points[:2]]
            parts.append(f"「{'」、「'.join(weak_categories)}」等模块将从薄弱转为熟练")

        if not parts:
            parts.append("持续学习将帮助你保持当前水平并稳步提升")

        return "；".join(parts) + "。"

    def _create_fallback_recommendation(self) -> RecommendationResult:
        """创建兜底推荐结果"""
        return RecommendationResult(
            review_contents=[],
            next_courses=[],
            study_plan_summary="由于数据不足，暂时无法生成个性化推荐。建议继续完成当前课程和练习，积累更多学习数据。",
            estimated_improvement="持续学习将帮助你稳步提升各项能力。"
        )

    def _build_cache_key(self, state: AgentState) -> str:
        """构建缓存键"""
        return f"agent:recommendation:{state['user_id']}:{state['period_type']}:{state['period_start'].date()}:{state['period_end'].date()}"
