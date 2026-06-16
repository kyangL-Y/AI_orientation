"""
LangGraph 工作流编排 - 多智能体有向图工作流

基于 LangGraph 构建多智能体协作的有向图工作流，实现：
1. 条件路由
2. 状态共享
3. 并行执行
4. 错误处理
"""

from typing import Literal, Dict, Any
from langgraph.graph import StateGraph, END
import structlog

from ..models.state import AgentState
from ..agents.statistics_agent import StatisticsAgent
from ..agents.analysis_agent import AnalysisAgent
from ..agents.recommendation_agent import RecommendationAgent
from ..agents.supervisor_agent import SupervisorAgent
from ..utils.cache import CacheManager
from ..utils.database import DatabaseManager
from ..utils.ai_client import AIClient

logger = structlog.get_logger(__name__)


def create_learning_report_workflow(
    cache_manager: CacheManager,
    db_manager: DatabaseManager,
    ai_client: AIClient
):
    """
    创建学习报告生成工作流

    工作流结构：
    START -> statistics -> route_after_statistics -> analysis -> recommendation -> generate_report -> END
                                |
                                v
                          fallback_handler -> generate_report -> END
    """

    # 初始化智能体
    statistics_agent = StatisticsAgent(cache_manager, db_manager)
    analysis_agent = AnalysisAgent(cache_manager, db_manager, ai_client)
    recommendation_agent = RecommendationAgent(cache_manager, db_manager, ai_client)
    supervisor_agent = SupervisorAgent(cache_manager, ai_client)

    # 创建状态图
    workflow = StateGraph(AgentState)

    # 添加节点
    workflow.add_node("statistics", statistics_agent.execute)
    workflow.add_node("analysis", analysis_agent.execute)
    workflow.add_node("recommendation", recommendation_agent.execute)
    workflow.add_node("generate_report", supervisor_agent.generate_final_report)
    workflow.add_node("fallback_handler", handle_fallback)

    # 设置入口点
    workflow.set_entry_point("statistics")

    # 添加条件路由
    workflow.add_conditional_edges(
        "statistics",
        route_after_statistics(supervisor_agent),
        {
            "analysis": "analysis",
            "fallback": "fallback_handler",
            END: END
        }
    )

    workflow.add_conditional_edges(
        "analysis",
        route_after_analysis(supervisor_agent),
        {
            "recommendation": "recommendation",
            "generate_report": "generate_report",
            END: END
        }
    )

    workflow.add_edge("recommendation", "generate_report")
    workflow.add_edge("fallback_handler", "generate_report")
    workflow.add_edge("generate_report", END)

    # 编译工作流
    app = workflow.compile()

    logger.info("workflow_created",
                nodes=["statistics", "analysis", "recommendation", "generate_report", "fallback_handler"])

    return app


def route_after_statistics(supervisor: SupervisorAgent):
    """统计智能体执行后的路由决策"""

    def router(state: AgentState) -> Literal["analysis", "fallback", END]:
        """
        路由逻辑：
        - data_completeness >= 0.5: 继续分析
        - data_completeness < 0.5: 使用兜底
        - 严重错误: 终止
        """
        logger.info("routing_after_statistics",
                    data_completeness=state.get("data_completeness", 0))

        # 检查是否有严重错误导致无法继续
        if state.get("statistics_data") is None:
            logger.warning("no_statistics_data", message="Using fallback")
            state["should_use_fallback"] = True
            return "fallback"

        # 检查数据完整度
        data_completeness = state.get("data_completeness", 0)

        if data_completeness < 0.5:
            logger.info("low_data_completeness", completeness=data_completeness, action="fallback")
            state["should_use_fallback"] = True
            return "fallback"

        # 检查是否应该跳过分析
        if supervisor.should_skip_analysis(state):
            logger.info("skip_analysis", reason="insufficient data for analysis")
            state["should_skip_analysis"] = True
            # 直接进入兜底生成报告
            return "fallback"

        logger.info("proceed_to_analysis", completeness=data_completeness)
        return "analysis"

    return router


def route_after_analysis(supervisor: SupervisorAgent):
    """分析智能体执行后的路由决策"""

    def router(state: AgentState) -> Literal["recommendation", "generate_report", END]:
        """
        路由逻辑：
        - 有分析结果: 继续推荐
        - 无分析结果但有统计数据: 直接生成报告
        - 都没有: 终止
        """
        logger.info("routing_after_analysis",
                    has_analysis=state.get("analysis_result") is not None)

        # 检查是否应该跳过推荐
        if supervisor.should_skip_recommendation(state):
            logger.info("skip_recommendation", reason="insufficient data for recommendation")
            state["should_skip_recommendation"] = True
            return "generate_report"

        # 正常流程：继续推荐
        logger.info("proceed_to_recommendation")
        return "recommendation"

    return router


async def handle_fallback(state: AgentState) -> AgentState:
    """
    兜底处理器

    当数据收集不足时，提供基础的报告数据
    """
    logger.info("fallback_handler_started", user_id=state["user_id"])

    # 标记使用了兜底策略
    state["should_use_fallback"] = True

    # 如果没有统计数据，创建空的统计数据
    if not state.get("statistics_data"):
        from ..models.state import StatisticsData
        state["statistics_data"] = StatisticsData(
            data_completeness=0.0,
            missing_fields=["all"]
        )

    # 如果没有分析结果，创建空的分析结果
    if not state.get("analysis_result"):
        from ..models.state import AnalysisResult
        state["analysis_result"] = AnalysisResult(
            weak_points=[],
            knowledge_trends=[],
            department_comparisons=[],
            overall_assessment="由于数据不足，暂时无法生成详细分析。",
            analysis_confidence=0.1
        )

    # 如果没有推荐结果，创建空的推荐结果
    if not state.get("recommendation_result"):
        from ..models.state import RecommendationResult
        state["recommendation_result"] = RecommendationResult(
            review_contents=[],
            next_courses=[],
            study_plan_summary="建议继续完成当前课程和练习，积累更多学习数据。",
            estimated_improvement="持续学习将帮助你稳步提升各项能力。"
        )

    state["agents_executed"].append("fallback_handler")

    logger.info("fallback_handler_completed",
                provided_defaults=["statistics", "analysis", "recommendation"])

    return state


def initialize_state(
    user_id: int,
    period_type: str,
    period_start,
    period_end,
    tenant_id: str,
    dept_id: int = None
) -> AgentState:
    """
    初始化工作流状态

    Args:
        user_id: 用户ID
        period_type: 周期类型 (weekly/monthly/quarterly)
        period_start: 周期开始时间
        period_end: 周期结束时间
        tenant_id: 租户ID
        dept_id: 部门ID（可选）

    Returns:
        初始化的 AgentState
    """
    from datetime import datetime

    state: AgentState = {
        # 输入参数
        "user_id": user_id,
        "period_type": period_type,
        "period_start": period_start,
        "period_end": period_end,
        "tenant_id": tenant_id,
        "dept_id": dept_id,

        # 执行状态
        "current_agent": "statistics",
        "next_agent": None,
        "agents_executed": [],

        # 数据结果
        "statistics_data": None,
        "statistics_errors": [],
        "analysis_result": None,
        "analysis_errors": [],
        "recommendation_result": None,
        "recommendation_errors": [],
        "final_report": None,

        # 条件路由控制
        "data_completeness": 0.0,
        "should_skip_analysis": False,
        "should_skip_recommendation": False,
        "should_use_fallback": False,

        # 缓存控制
        "cache_keys": {},
        "cache_hits": [],
        "cache_misses": [],

        # 错误处理
        "errors": [],
        "retry_count": 0,
        "max_retries": 3,

        # 性能监控
        "start_time": datetime.now(),
        "agent_timings": {},
    }

    logger.info("state_initialized",
                user_id=user_id,
                period_type=period_type,
                period_range=f"{period_start} to {period_end}")

    return state
