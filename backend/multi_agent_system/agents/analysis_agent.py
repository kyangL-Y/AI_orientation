"""
分析智能体 - 识别薄弱点、分析趋势、对比部门

职责：
1. 识别薄弱知识点（基于错题分布和正确率）
2. 分析知识掌握趋势（对比历史数据）
3. 部门对比分析（用户 vs 部门平均）
4. 数据缺失时自动兜底
"""

import time
from typing import List, Dict, Any
from datetime import datetime, timedelta
import structlog
from tenacity import retry, stop_after_attempt, wait_exponential

from ..models.state import (
    AgentState, StatisticsData, AnalysisResult,
    WeakPoint, KnowledgeTrend, DepartmentComparison
)
from ..utils.cache import CacheManager
from ..utils.database import DatabaseManager
from ..utils.ai_client import AIClient
from ..config import settings

logger = structlog.get_logger(__name__)


class AnalysisAgent:
    """分析智能体 - 深度数据分析"""

    def __init__(
        self,
        cache_manager: CacheManager,
        db_manager: DatabaseManager,
        ai_client: AIClient
    ):
        self.cache_manager = cache_manager
        self.db_manager = db_manager
        self.ai_client = ai_client
        self.agent_name = "analysis"
        self.logger = logger.bind(agent=self.agent_name)

    async def execute(self, state: AgentState) -> AgentState:
        """执行分析任务"""
        start_time = time.time()
        self.logger.info("analysis_agent_started", user_id=state["user_id"])

        try:
            # 检查是否应该跳过分析
            if state.get("should_skip_analysis", False):
                self.logger.info("analysis_skipped", reason="should_skip_analysis flag set")
                state["agents_executed"].append(self.agent_name)
                return state

            # 检查统计数据是否存在
            statistics_data = state.get("statistics_data")
            if not statistics_data:
                self.logger.warning("no_statistics_data", message="Using fallback analysis")
                state["should_use_fallback"] = True
                state["analysis_result"] = self._create_fallback_analysis()
                state["agents_executed"].append(self.agent_name)
                return state

            # 检查缓存
            cache_key = self._build_cache_key(state)
            cached_result = await self.cache_manager.get(cache_key)

            if cached_result and settings.ENABLE_RESULT_CACHE:
                self.logger.info("cache_hit", cache_key=cache_key)
                state["cache_hits"].append(self.agent_name)
                state["analysis_result"] = AnalysisResult(**cached_result)
                return state

            state["cache_misses"].append(self.agent_name)

            # 执行分析
            weak_points = await self._identify_weak_points(state, statistics_data)
            knowledge_trends = await self._analyze_knowledge_trends(state, statistics_data)
            dept_comparisons = await self._compare_with_department(state, statistics_data)

            # 生成总体评估（使用 AI）
            overall_assessment = await self._generate_overall_assessment(
                state, weak_points, knowledge_trends, dept_comparisons
            )

            # 计算分析置信度
            confidence = self._calculate_confidence(statistics_data, weak_points, knowledge_trends)

            # 构建分析结果
            analysis_result = AnalysisResult(
                weak_points=weak_points,
                knowledge_trends=knowledge_trends,
                department_comparisons=dept_comparisons,
                overall_assessment=overall_assessment,
                analysis_confidence=confidence
            )

            # 更新状态
            state["analysis_result"] = analysis_result
            state["agents_executed"].append(self.agent_name)

            # 缓存结果
            if settings.ENABLE_RESULT_CACHE:
                await self.cache_manager.set(
                    cache_key,
                    analysis_result.dict(),
                    ttl=settings.CACHE_DURATION_SECONDS
                )

            execution_time = (time.time() - start_time) * 1000
            state["agent_timings"][self.agent_name] = execution_time

            self.logger.info(
                "analysis_agent_completed",
                execution_time_ms=execution_time,
                weak_points_count=len(weak_points),
                confidence=confidence
            )

            return state

        except Exception as e:
            self.logger.error("analysis_agent_failed", error=str(e), exc_info=True)
            state["errors"].append({
                "agent": self.agent_name,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            })
            state["analysis_errors"] = [str(e)]
            # 使用兜底分析
            state["analysis_result"] = self._create_fallback_analysis()
            return state

    async def _identify_weak_points(
        self,
        state: AgentState,
        statistics_data: StatisticsData
    ) -> List[WeakPoint]:
        """识别薄弱知识点"""
        self.logger.debug("identifying_weak_points")
        weak_points = []

        if not statistics_data.wrong_question_distribution:
            return weak_points

        wrong_dist = statistics_data.wrong_question_distribution
        category_dist = wrong_dist.category_distribution

        if not category_dist:
            return weak_points

        # 计算每个分类的错误率（需要查询总答题数）
        for category, wrong_count in category_dist.items():
            # 查询该分类的总答题数
            total_count = await self._get_category_total_count(
                state["user_id"],
                state["tenant_id"],
                category,
                state["period_start"],
                state["period_end"]
            )

            if total_count == 0:
                continue

            error_rate = (wrong_count / total_count) * 100

            # 判断严重程度
            if error_rate >= 30:
                severity = "high"
            elif error_rate >= 20:
                severity = "medium"
            else:
                severity = "low"

            # 生成描述
            description = f"在{category}模块答错了{wrong_count}道题，错误率{error_rate:.1f}%"

            weak_points.append(WeakPoint(
                category=category,
                error_rate=round(error_rate, 2),
                error_count=wrong_count,
                severity=severity,
                description=description
            ))

        # 按错误率排序
        weak_points.sort(key=lambda x: x.error_rate, reverse=True)

        return weak_points

    async def _get_category_total_count(
        self,
        user_id: int,
        tenant_id: str,
        category: str,
        period_start: datetime,
        period_end: datetime
    ) -> int:
        """获取某个分类的总答题数"""
        query = """
            SELECT COUNT(*) as total
            FROM train_answer_attempt aa
            JOIN train_question q ON aa.question_id = q.id
            WHERE aa.user_id = %s
                AND aa.tenant_id = %s
                AND q.category = %s
                AND aa.answer_time BETWEEN %s AND %s
        """

        try:
            async with self.db_manager.get_connection() as conn:
                async with conn.cursor() as cursor:
                    await cursor.execute(query, (user_id, tenant_id, category, period_start, period_end))
                    row = await cursor.fetchone()
                    return row[0] if row else 0
        except Exception as e:
            self.logger.warning("get_category_total_count_failed", category=category, error=str(e))
            return 0

    async def _analyze_knowledge_trends(
        self,
        state: AgentState,
        statistics_data: StatisticsData
    ) -> List[KnowledgeTrend]:
        """分析知识掌握趋势"""
        self.logger.debug("analyzing_knowledge_trends")
        trends = []

        if not statistics_data.wrong_question_distribution:
            return trends

        category_dist = statistics_data.wrong_question_distribution.category_distribution

        # 获取上一个周期的数据进行对比
        previous_period_start, previous_period_end = self._get_previous_period(
            state["period_start"],
            state["period_end"],
            state["period_type"]
        )

        for category in category_dist.keys():
            # 当前周期正确率
            current_accuracy = await self._get_category_accuracy(
                state["user_id"],
                state["tenant_id"],
                category,
                state["period_start"],
                state["period_end"]
            )

            # 上一周期正确率
            previous_accuracy = await self._get_category_accuracy(
                state["user_id"],
                state["tenant_id"],
                category,
                previous_period_start,
                previous_period_end
            )

            # 判断趋势
            if previous_accuracy is None:
                trend = "stable"
                change_percentage = None
            else:
                change_percentage = current_accuracy - previous_accuracy
                if change_percentage > 5:
                    trend = "improving"
                elif change_percentage < -5:
                    trend = "declining"
                else:
                    trend = "stable"

            trends.append(KnowledgeTrend(
                category=category,
                trend=trend,
                current_accuracy=round(current_accuracy, 2),
                previous_accuracy=round(previous_accuracy, 2) if previous_accuracy else None,
                change_percentage=round(change_percentage, 2) if change_percentage else None
            ))

        return trends

    async def _get_category_accuracy(
        self,
        user_id: int,
        tenant_id: str,
        category: str,
        period_start: datetime,
        period_end: datetime
    ) -> float:
        """获取某个分类的正确率"""
        query = """
            SELECT
                COUNT(*) as total,
                SUM(CASE WHEN aa.is_correct = 1 THEN 1 ELSE 0 END) as correct
            FROM train_answer_attempt aa
            JOIN train_question q ON aa.question_id = q.id
            WHERE aa.user_id = %s
                AND aa.tenant_id = %s
                AND q.category = %s
                AND aa.answer_time BETWEEN %s AND %s
        """

        try:
            async with self.db_manager.get_connection() as conn:
                async with conn.cursor() as cursor:
                    await cursor.execute(query, (user_id, tenant_id, category, period_start, period_end))
                    row = await cursor.fetchone()
                    if row and row[0] > 0:
                        return (row[1] / row[0]) * 100
                    return 0.0
        except Exception as e:
            self.logger.warning("get_category_accuracy_failed", category=category, error=str(e))
            return 0.0

    def _get_previous_period(
        self,
        period_start: datetime,
        period_end: datetime,
        period_type: str
    ) -> tuple:
        """获取上一个周期的起止时间"""
        duration = period_end - period_start

        if period_type == "weekly":
            previous_end = period_start - timedelta(days=1)
            previous_start = previous_end - timedelta(days=7)
        elif period_type == "monthly":
            previous_end = period_start - timedelta(days=1)
            previous_start = previous_end - timedelta(days=30)
        else:  # quarterly
            previous_end = period_start - timedelta(days=1)
            previous_start = previous_end - timedelta(days=90)

        return previous_start, previous_end

    async def _compare_with_department(
        self,
        state: AgentState,
        statistics_data: StatisticsData
    ) -> List[DepartmentComparison]:
        """部门对比分析"""
        self.logger.debug("comparing_with_department")
        comparisons = []

        if not statistics_data.department_ranking:
            return comparisons

        dept_ranking = statistics_data.department_ranking

        # 1. 综合得分对比
        if dept_ranking.user_score > 0:
            deviation = dept_ranking.user_score - dept_ranking.dept_average_score
            evaluation = "above" if deviation > 5 else "below" if deviation < -5 else "average"

            comparisons.append(DepartmentComparison(
                comparison_type="综合得分",
                user_value=dept_ranking.user_score,
                dept_average=dept_ranking.dept_average_score,
                deviation=round(deviation, 2),
                evaluation=evaluation
            ))

        # 2. 学习时长对比
        if statistics_data.learning_duration:
            user_duration = statistics_data.learning_duration.total_minutes
            dept_avg_duration = await self._get_dept_average_duration(state)

            if dept_avg_duration > 0:
                deviation = user_duration - dept_avg_duration
                evaluation = "above" if deviation > 30 else "below" if deviation < -30 else "average"

                comparisons.append(DepartmentComparison(
                    comparison_type="学习时长",
                    user_value=user_duration,
                    dept_average=dept_avg_duration,
                    deviation=round(deviation, 2),
                    evaluation=evaluation
                ))

        # 3. 考试平均分对比
        if statistics_data.exam_score and statistics_data.exam_score.total_exams > 0:
            user_avg = statistics_data.exam_score.average_score
            dept_avg_score = await self._get_dept_average_exam_score(state)

            if dept_avg_score > 0:
                deviation = user_avg - dept_avg_score
                evaluation = "above" if deviation > 5 else "below" if deviation < -5 else "average"

                comparisons.append(DepartmentComparison(
                    comparison_type="考试平均分",
                    user_value=user_avg,
                    dept_average=dept_avg_score,
                    deviation=round(deviation, 2),
                    evaluation=evaluation
                ))

        return comparisons

    async def _get_dept_average_duration(self, state: AgentState) -> float:
        """获取部门平均学习时长"""
        dept_id = state.get("dept_id")
        if not dept_id:
            return 0.0

        query = """
            SELECT AVG(total_minutes) as avg_duration
            FROM (
                SELECT
                    ll.user_id,
                    SUM(ll.duration_minutes) as total_minutes
                FROM train_learning_log ll
                JOIN sys_user u ON ll.user_id = u.user_id
                WHERE u.dept_id = %s
                    AND ll.tenant_id = %s
                    AND ll.create_time BETWEEN %s AND %s
                GROUP BY ll.user_id
            ) as user_durations
        """

        try:
            async with self.db_manager.get_connection() as conn:
                async with conn.cursor() as cursor:
                    await cursor.execute(query, (
                        dept_id,
                        state["tenant_id"],
                        state["period_start"],
                        state["period_end"]
                    ))
                    row = await cursor.fetchone()
                    return row[0] if row and row[0] else 0.0
        except Exception as e:
            self.logger.warning("get_dept_average_duration_failed", error=str(e))
            return 0.0

    async def _get_dept_average_exam_score(self, state: AgentState) -> float:
        """获取部门考试平均分"""
        dept_id = state.get("dept_id")
        if not dept_id:
            return 0.0

        query = """
            SELECT AVG(qa.score) as avg_score
            FROM train_quiz_attempt qa
            JOIN sys_user u ON qa.user_id = u.user_id
            WHERE u.dept_id = %s
                AND qa.tenant_id = %s
                AND qa.submit_time BETWEEN %s AND %s
                AND qa.status = 'completed'
        """

        try:
            async with self.db_manager.get_connection() as conn:
                async with conn.cursor() as cursor:
                    await cursor.execute(query, (
                        dept_id,
                        state["tenant_id"],
                        state["period_start"],
                        state["period_end"]
                    ))
                    row = await cursor.fetchone()
                    return row[0] if row and row[0] else 0.0
        except Exception as e:
            self.logger.warning("get_dept_average_exam_score_failed", error=str(e))
            return 0.0

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        reraise=True
    )
    async def _generate_overall_assessment(
        self,
        state: AgentState,
        weak_points: List[WeakPoint],
        trends: List[KnowledgeTrend],
        comparisons: List[DepartmentComparison]
    ) -> str:
        """生成总体评估（使用AI）"""
        self.logger.debug("generating_overall_assessment")

        prompt = self._build_assessment_prompt(weak_points, trends, comparisons)

        try:
            assessment = await self.ai_client.generate_text(
                prompt=prompt,
                max_tokens=500,
                temperature=0.7
            )
            return assessment.strip()
        except Exception as e:
            self.logger.warning("ai_assessment_failed", error=str(e))
            return self._generate_rule_based_assessment(weak_points, trends, comparisons)

    def _build_assessment_prompt(
        self,
        weak_points: List[WeakPoint],
        trends: List[KnowledgeTrend],
        comparisons: List[DepartmentComparison]
    ) -> str:
        """构建评估提示词"""
        prompt = "请基于以下学习数据，生成一段100-150字的总体评估：\n\n"

        if weak_points:
            prompt += "【薄弱知识点】\n"
            for wp in weak_points[:3]:
                prompt += f"- {wp.category}: 错误率{wp.error_rate}% (严重程度: {wp.severity})\n"
            prompt += "\n"

        if trends:
            improving = [t for t in trends if t.trend == "improving"]
            declining = [t for t in trends if t.trend == "declining"]
            if improving:
                prompt += "【进步模块】\n"
                for t in improving[:2]:
                    prompt += f"- {t.category}: 正确率从{t.previous_accuracy}%提升到{t.current_accuracy}%\n"
            if declining:
                prompt += "【退步模块】\n"
                for t in declining[:2]:
                    prompt += f"- {t.category}: 正确率从{t.previous_accuracy}%下降到{t.current_accuracy}%\n"
            prompt += "\n"

        if comparisons:
            prompt += "【部门对比】\n"
            for c in comparisons:
                prompt += f"- {c.comparison_type}: 用户{c.user_value} vs 部门平均{c.dept_average} ({c.evaluation})\n"
            prompt += "\n"

        prompt += "请用温暖、鼓励的语气，客观评价学习表现，指出主要优势和需要改进的地方。"

        return prompt

    def _generate_rule_based_assessment(
        self,
        weak_points: List[WeakPoint],
        trends: List[KnowledgeTrend],
        comparisons: List[DepartmentComparison]
    ) -> str:
        """基于规则生成评估（AI失败时的兜底）"""
        parts = []

        # 总体表现
        if comparisons:
            above_count = sum(1 for c in comparisons if c.evaluation == "above")
            if above_count >= len(comparisons) / 2:
                parts.append("本周期整体表现优秀，多项指标超过部门平均水平。")
            else:
                parts.append("本周期整体表现中等，部分指标有待提升。")

        # 进步情况
        improving = [t for t in trends if t.trend == "improving"]
        if improving:
            parts.append(f"在{', '.join([t.category for t in improving[:2]])}等模块取得了明显进步。")

        # 薄弱点
        if weak_points:
            high_severity = [wp for wp in weak_points if wp.severity == "high"]
            if high_severity:
                parts.append(f"需要重点关注{', '.join([wp.category for wp in high_severity[:2]])}等薄弱知识点。")

        # 鼓励
        parts.append("继续保持学习热情，针对薄弱环节加强练习，相信会取得更大进步。")

        return " ".join(parts)

    def _calculate_confidence(
        self,
        statistics_data: StatisticsData,
        weak_points: List[WeakPoint],
        trends: List[KnowledgeTrend]
    ) -> float:
        """计算分析置信度"""
        confidence = 0.0

        # 数据完整度权重 40%
        confidence += statistics_data.data_completeness * 0.4

        # 错题数据充分性权重 30%
        if statistics_data.wrong_question_distribution:
            wrong_count = statistics_data.wrong_question_distribution.total_wrong_count
            if wrong_count >= 20:
                confidence += 0.3
            elif wrong_count >= 10:
                confidence += 0.2
            elif wrong_count >= 5:
                confidence += 0.1

        # 趋势分析可用性权重 30%
        if len(trends) >= 3:
            confidence += 0.3
        elif len(trends) >= 1:
            confidence += 0.15

        return round(min(confidence, 1.0), 2)

    def _create_fallback_analysis(self) -> AnalysisResult:
        """创建兜底分析结果"""
        return AnalysisResult(
            weak_points=[],
            knowledge_trends=[],
            department_comparisons=[],
            overall_assessment="由于数据不足，暂时无法生成详细分析。建议继续学习和练习，积累更多数据后再查看分析报告。",
            analysis_confidence=0.1
        )

    def _build_cache_key(self, state: AgentState) -> str:
        """构建缓存键"""
        return f"agent:analysis:{state['user_id']}:{state['period_type']}:{state['period_start'].date()}:{state['period_end'].date()}"
