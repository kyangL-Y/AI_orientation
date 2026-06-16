"""
多智能体学习报告系统 - 主入口模块
"""
__version__ = "1.0.0"

from .agents.statistics_agent import StatisticsAgent
from .agents.analysis_agent import AnalysisAgent
from .agents.recommendation_agent import RecommendationAgent
from .agents.supervisor_agent import SupervisorAgent
from .workflow.graph import create_learning_report_workflow
from .models.state import AgentState, LearningReport

__all__ = [
    "StatisticsAgent",
    "AnalysisAgent",
    "RecommendationAgent",
    "SupervisorAgent",
    "create_learning_report_workflow",
    "AgentState",
    "LearningReport",
]
