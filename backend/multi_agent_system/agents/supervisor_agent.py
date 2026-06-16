"""
主管智能体 - 协调所有子智能体，生成最终报告

职责：
1. 协调子智能体执行顺序
2. 管理共享状态
3. 实现条件路由
4. 聚合结果生成结构化报告（含文字和图表）
"""

import time
import uuid
from typing import Dict, Any, List
from datetime import datetime
import structlog
import json

from ..models.state import (
    AgentState, LearningReport, ChartData, StatisticsData,
    AnalysisResult, RecommendationResult
)
from ..utils.cache import CacheManager
from ..utils.ai_client import AIClient
from ..config import settings

logger = structlog.get_logger(__name__)


class SupervisorAgent:
    """主管智能体 - 协调和报告生成"""

    def __init__(self, cache_manager: CacheManager, ai_client: AIClient):
        self.cache_manager = cache_manager
        self.ai_client = ai_client
        self.agent_name = "supervisor"
        self.logger = logger.bind(agent=self.agent_name)

    def should_use_fallback(self, state: AgentState) -> bool:
        """判断是否使用兜底策略"""
        return state.get("data_completeness", 0) < 0.5

    def should_skip_analysis(self, state: AgentState) -> bool:
        """判断是否跳过分析智能体"""
        statistics_data = state.get("statistics_data")
        if not statistics_data:
            return True
        # 如果错题数据为空且考试数据为空，跳过深度分析
        if (not statistics_data.wrong_question_distribution or
            statistics_data.wrong_question_distribution.total_wrong_count == 0):
            if not statistics_data.exam_score or statistics_data.exam_score.total_exams == 0:
                return True
        return False

    def should_skip_recommendation(self, state: AgentState) -> bool:
        """判断是否跳过推荐智能体"""
        # 如果既没有统计数据也没有分析结果，跳过推荐
        if not state.get("statistics_data") and not state.get("analysis_result"):
            return True
        return False

    async def generate_final_report(self, state: AgentState) -> AgentState:
        """生成最终报告"""
        start_time = time.time()
        self.logger.info("generating_final_report", user_id=state["user_id"])

        try:
            # 提取数据
            statistics_data = state.get("statistics_data")
            analysis_result = state.get("analysis_result")
            recommendation_result = state.get("recommendation_result")

            # 生成报告ID
            report_id = f"report_{state['user_id']}_{int(time.time())}"

            # 生成文字总结部分
            executive_summary = await self._generate_executive_summary(
                state, statistics_data, analysis_result
            )

            learning_profile = self._generate_learning_profile(statistics_data, analysis_result)
            dimension_analysis = self._generate_dimension_analysis(
                statistics_data, analysis_result, recommendation_result
            )
            action_plan = self._generate_action_plan(recommendation_result)
            closing_message = self._generate_closing_message(state, analysis_result)

            # 生成图表数据
            charts = self._generate_charts(statistics_data, analysis_result)

            # 计算缓存命中率
            cache_hit_rate = self._calculate_cache_hit_rate(state)

            # 计算生成耗时
            generation_time = int((time.time() - start_time) * 1000)

            # 构建最终报告
            final_report = LearningReport(
                report_id=report_id,
                user_id=state["user_id"],
                period_type=state["period_type"],
                period_start=state["period_start"],
                period_end=state["period_end"],
                executive_summary=executive_summary,
                learning_profile=learning_profile,
                dimension_analysis=dimension_analysis,
                action_plan=action_plan,
                closing_message=closing_message,
                statistics_data=statistics_data or StatisticsData(data_completeness=0, missing_fields=["all"]),
                analysis_result=analysis_result or AnalysisResult(
                    weak_points=[], knowledge_trends=[], department_comparisons=[],
                    overall_assessment="", analysis_confidence=0.0
                ),
                recommendation_result=recommendation_result or RecommendationResult(
                    review_contents=[], next_courses=[],
                    study_plan_summary="", estimated_improvement=""
                ),
                charts=charts,
                generated_at=datetime.now(),
                generation_time_ms=generation_time,
                agents_involved=state.get("agents_executed", []),
                cache_hit_rate=cache_hit_rate
            )

            state["final_report"] = final_report
            state["agents_executed"].append(self.agent_name)

            self.logger.info(
                "final_report_generated",
                report_id=report_id,
                generation_time_ms=generation_time,
                cache_hit_rate=cache_hit_rate
            )

            return state

        except Exception as e:
            self.logger.error("generate_final_report_failed", error=str(e), exc_info=True)
            state["errors"].append({
                "agent": self.agent_name,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            })
            raise

    async def _generate_executive_summary(
        self,
        state: AgentState,
        statistics_data: StatisticsData,
        analysis_result: AnalysisResult
    ) -> str:
        """生成执行摘要"""
        if not statistics_data or statistics_data.data_completeness < 0.3:
            return "本周期数据收集不足，建议继续学习以获得更详细的分析报告。"

        parts = []

        # 学习投入
        if statistics_data.learning_duration:
            duration = statistics_data.learning_duration.total_minutes
            parts.append(f"本周期累计学习{duration}分钟")

        # 学习成果
        if statistics_data.exam_score and statistics_data.exam_score.total_exams > 0:
            avg_score = statistics_data.exam_score.average_score
            parts.append(f"考试平均分{avg_score:.1f}分")

        # 薄弱点
        if analysis_result and analysis_result.weak_points:
            weak_count = len([wp for wp in analysis_result.weak_points if wp.severity == "high"])
            if weak_count > 0:
                parts.append(f"发现{weak_count}个需要重点关注的薄弱知识点")

        # 排名
        if statistics_data.department_ranking and statistics_data.department_ranking.user_rank:
            rank = statistics_data.department_ranking.user_rank
            total = statistics_data.department_ranking.total_users
            parts.append(f"部门排名第{rank}/{total}名")

        if parts:
            return "，".join(parts) + "。"
        else:
            return "本周期学习数据正在收集中，请继续保持学习节奏。"

    def _generate_learning_profile(
        self,
        statistics_data: StatisticsData,
        analysis_result: AnalysisResult
    ) -> Dict[str, Any]:
        """生成学习画像"""
        profile = {
            "duration_value": "0分钟",
            "duration_eval": "⭐⭐⭐☆☆ 待提升",
            "quiz_value": "0题",
            "quiz_eval": "⭐⭐⭐☆☆ 待提升",
            "accuracy_value": "0%",
            "accuracy_eval": "⭐⭐⭐☆☆ 待提升",
            "score_value": "0分",
            "score_eval": "⭐⭐⭐☆☆ 待提升",
            "one_sentence": "继续保持学习热情，稳步提升各项能力。"
        }

        if not statistics_data:
            return profile

        # 学习时长
        if statistics_data.learning_duration:
            duration = statistics_data.learning_duration.total_minutes
            profile["duration_value"] = f"{duration}分钟"
            if duration >= 240:
                profile["duration_eval"] = "⭐⭐⭐⭐⭐ 投入充分"
            elif duration >= 120:
                profile["duration_eval"] = "⭐⭐⭐⭐☆ 较为积极"
            elif duration >= 60:
                profile["duration_eval"] = "⭐⭐⭐☆☆ 有待提升"

        # 答题数量（从错题分布反推）
        if statistics_data.wrong_question_distribution:
            # 这里简化处理，实际应该查询总答题数
            profile["quiz_value"] = f"{statistics_data.wrong_question_distribution.total_wrong_count * 3}题(估算)"

        # 考试成绩
        if statistics_data.exam_score and statistics_data.exam_score.total_exams > 0:
            avg_score = statistics_data.exam_score.average_score
            profile["score_value"] = f"{avg_score:.0f}分"
            if avg_score >= 90:
                profile["score_eval"] = "⭐⭐⭐⭐⭐ 表现优秀"
            elif avg_score >= 75:
                profile["score_eval"] = "⭐⭐⭐⭐☆ 具备实操能力"
            elif avg_score >= 60:
                profile["score_eval"] = "⭐⭐⭐☆☆ 基本合格"

        return profile

    def _generate_dimension_analysis(
        self,
        statistics_data: StatisticsData,
        analysis_result: AnalysisResult,
        recommendation_result: RecommendationResult
    ) -> List[Dict[str, Any]]:
        """生成维度分析"""
        dimensions = []

        # 学习时长维度
        if statistics_data and statistics_data.learning_duration:
            dimensions.append({
                "dimension": "学习时长",
                "value": f"{statistics_data.learning_duration.total_minutes}分钟",
                "title": "学习投入" if statistics_data.learning_duration.total_minutes >= 120 else "学习时间有待增加",
                "analysis": f"本周期学习时长呈{statistics_data.learning_duration.trend}趋势",
                "tip": "建议采用番茄工作法，提高学习效率"
            })

        # 薄弱知识点维度
        if analysis_result and analysis_result.weak_points:
            weak_categories = [wp.category for wp in analysis_result.weak_points[:3]]
            dimensions.append({
                "dimension": "薄弱知识点",
                "value": f"{len(analysis_result.weak_points)}个",
                "title": "需要针对性提升",
                "analysis": f"主要薄弱点：{'、'.join(weak_categories)}",
                "tip": "建议针对薄弱点进行专项练习"
            })

        # 部门排名维度
        if statistics_data and statistics_data.department_ranking and statistics_data.department_ranking.user_rank:
            rank = statistics_data.department_ranking.user_rank
            total = statistics_data.department_ranking.total_users
            dimensions.append({
                "dimension": "部门排名",
                "value": f"第{rank}/{total}名",
                "title": "排名位置" if rank <= total / 2 else "有提升空间",
                "analysis": f"当前排名处于部门{'前' if rank <= total / 2 else '后'}50%",
                "tip": "继续努力，争取提升排名"
            })

        return dimensions

    def _generate_action_plan(
        self,
        recommendation_result: RecommendationResult
    ) -> Dict[str, List[str]]:
        """生成行动计划"""
        if not recommendation_result:
            return {
                "consolidate": ["继续保持学习热情"],
                "improve": ["增加学习时长", "完成更多练习题"]
            }

        consolidate = []
        improve = []

        # 从推荐结果中提取行动计划
        if recommendation_result.study_plan_summary:
            improve.append(recommendation_result.study_plan_summary)

        if recommendation_result.review_contents:
            high_priority = [rc for rc in recommendation_result.review_contents if rc.priority == "high"]
            if high_priority:
                improve.append(f"优先复习{len(high_priority)}个高频错题")

        if recommendation_result.next_courses:
            improve.append(f"学习推荐的{len(recommendation_result.next_courses)}门课程")

        if not improve:
            improve = ["持续学习，保持进步"]

        consolidate.append("保持当前的学习节奏")

        return {
            "consolidate": consolidate,
            "improve": improve
        }

    def _generate_closing_message(
        self,
        state: AgentState,
        analysis_result: AnalysisResult
    ) -> str:
        """生成结语"""
        if analysis_result and analysis_result.analysis_confidence > 0.7:
            return "你已经在学习的道路上取得了不错的进展。继续保持这份认真与热情，针对薄弱环节加强练习，相信会取得更大进步！"
        else:
            return "学习是一个持续积累的过程。继续保持学习热情，多做练习和复习，你的努力一定会有回报！"

    def _generate_charts(
        self,
        statistics_data: StatisticsData,
        analysis_result: AnalysisResult
    ) -> List[ChartData]:
        """生成图表数据"""
        charts = []

        # 1. 学习时长趋势图（折线图）
        if statistics_data and statistics_data.learning_duration and statistics_data.learning_duration.details:
            charts.append(ChartData(
                chart_type="line",
                title="学习时长趋势",
                data={
                    "dates": list(statistics_data.learning_duration.details.keys()),
                    "minutes": list(statistics_data.learning_duration.details.values())
                },
                description="每日学习时长变化趋势"
            ))

        # 2. 错题分布图（饼图）
        if statistics_data and statistics_data.wrong_question_distribution:
            dist = statistics_data.wrong_question_distribution.category_distribution
            if dist:
                charts.append(ChartData(
                    chart_type="pie",
                    title="错题分布",
                    data={
                        "categories": list(dist.keys()),
                        "counts": list(dist.values())
                    },
                    description="按知识点分类的错题数量分布"
                ))

        # 3. 能力雷达图
        if analysis_result and analysis_result.department_comparisons:
            categories = [comp.comparison_type for comp in analysis_result.department_comparisons]
            user_values = [comp.user_value for comp in analysis_result.department_comparisons]
            dept_values = [comp.dept_average for comp in analysis_result.department_comparisons]

            charts.append(ChartData(
                chart_type="radar",
                title="能力雷达图",
                data={
                    "categories": categories,
                    "user": user_values,
                    "department_average": dept_values
                },
                description="用户能力与部门平均水平对比"
            ))

        return charts

    def _calculate_cache_hit_rate(self, state: AgentState) -> float:
        """计算缓存命中率"""
        hits = len(state.get("cache_hits", []))
        misses = len(state.get("cache_misses", []))
        total = hits + misses

        if total == 0:
            return 0.0

        return round(hits / total, 2)
