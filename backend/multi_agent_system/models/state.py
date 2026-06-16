"""
多智能体学习报告系统 - 状态模型定义

基于 LangGraph 的共享状态结构，支持智能体间状态传递和条件路由
"""

from typing import Dict, List, Optional, Any, Literal
from datetime import datetime
from pydantic import BaseModel, Field
from typing_extensions import TypedDict


# ==================== 数据传输对象 ====================

class LearningDuration(BaseModel):
    """学习时长数据"""
    total_minutes: int = Field(description="总学习时长（分钟）")
    daily_average: float = Field(description="日均学习时长（分钟）")
    trend: str = Field(description="趋势：increasing/stable/decreasing")
    details: Dict[str, int] = Field(default_factory=dict, description="按日期分组的学习时长")


class CourseProgress(BaseModel):
    """课程进度数据"""
    total_courses: int = Field(description="总课程数")
    completed_courses: int = Field(description="已完成课程数")
    in_progress_courses: int = Field(description="进行中课程数")
    completion_rate: float = Field(description="完成率（0-100）")
    course_details: List[Dict[str, Any]] = Field(default_factory=list, description="课程详情列表")


class ExamScore(BaseModel):
    """考试成绩数据"""
    total_exams: int = Field(description="总考试次数")
    average_score: float = Field(description="平均分")
    highest_score: float = Field(description="最高分")
    lowest_score: float = Field(description="最低分")
    pass_rate: float = Field(description="通过率（0-100）")
    recent_exams: List[Dict[str, Any]] = Field(default_factory=list, description="最近考试记录")


class WrongQuestionDistribution(BaseModel):
    """错题分布数据"""
    total_wrong_count: int = Field(description="总错题数")
    category_distribution: Dict[str, int] = Field(default_factory=dict, description="按分类统计错题数")
    recent_wrong_questions: List[Dict[str, Any]] = Field(default_factory=list, description="最近错题列表")
    high_frequency_errors: List[str] = Field(default_factory=list, description="高频错误知识点")


class DepartmentRanking(BaseModel):
    """部门排名数据"""
    user_rank: Optional[int] = Field(None, description="用户排名")
    total_users: Optional[int] = Field(None, description="部门总人数")
    user_score: float = Field(description="用户得分")
    dept_average_score: float = Field(description="部门平均分")
    percentile: Optional[float] = Field(None, description="百分位（0-100）")


class StatisticsData(BaseModel):
    """统计智能体输出数据"""
    learning_duration: Optional[LearningDuration] = None
    course_progress: Optional[CourseProgress] = None
    exam_score: Optional[ExamScore] = None
    wrong_question_distribution: Optional[WrongQuestionDistribution] = None
    department_ranking: Optional[DepartmentRanking] = None
    data_completeness: float = Field(description="数据完整度（0-1）")
    missing_fields: List[str] = Field(default_factory=list, description="缺失的数据字段")


# ==================== 分析结果对象 ====================

class WeakPoint(BaseModel):
    """薄弱知识点"""
    category: str = Field(description="知识点分类")
    error_rate: float = Field(description="错误率（0-100）")
    error_count: int = Field(description="错误次数")
    severity: Literal["high", "medium", "low"] = Field(description="严重程度")
    description: str = Field(description="薄弱点描述")


class KnowledgeTrend(BaseModel):
    """知识掌握趋势"""
    category: str = Field(description="知识点分类")
    trend: Literal["improving", "stable", "declining"] = Field(description="趋势")
    current_accuracy: float = Field(description="当前正确率（0-100）")
    previous_accuracy: Optional[float] = Field(None, description="之前正确率（0-100）")
    change_percentage: Optional[float] = Field(None, description="变化百分比")


class DepartmentComparison(BaseModel):
    """部门对比分析"""
    comparison_type: str = Field(description="对比维度")
    user_value: float = Field(description="用户数值")
    dept_average: float = Field(description="部门平均值")
    deviation: float = Field(description="偏差值")
    evaluation: Literal["above", "average", "below"] = Field(description="评价")


class AnalysisResult(BaseModel):
    """分析智能体输出结果"""
    weak_points: List[WeakPoint] = Field(default_factory=list, description="薄弱知识点列表")
    knowledge_trends: List[KnowledgeTrend] = Field(default_factory=list, description="知识掌握趋势")
    department_comparisons: List[DepartmentComparison] = Field(default_factory=list, description="部门对比分析")
    overall_assessment: str = Field(description="总体评估")
    analysis_confidence: float = Field(description="分析置信度（0-1）")


# ==================== 推荐结果对象 ====================

class ReviewContent(BaseModel):
    """待复习内容"""
    content_type: Literal["question", "course", "article"] = Field(description="内容类型")
    content_id: str = Field(description="内容ID")
    title: str = Field(description="标题")
    category: str = Field(description="分类")
    priority: Literal["high", "medium", "low"] = Field(description="优先级")
    reason: str = Field(description="推荐理由")


class NextCourse(BaseModel):
    """下一步课程推荐"""
    course_id: str = Field(description="课程ID")
    course_name: str = Field(description="课程名称")
    category: str = Field(description="课程分类")
    difficulty: Literal["beginner", "intermediate", "advanced"] = Field(description="难度等级")
    estimated_duration: int = Field(description="预计学习时长（分钟）")
    relevance_score: float = Field(description="相关性评分（0-1）")
    reason: str = Field(description="推荐理由")


class RecommendationResult(BaseModel):
    """推荐智能体输出结果"""
    review_contents: List[ReviewContent] = Field(default_factory=list, description="待复习内容列表")
    next_courses: List[NextCourse] = Field(default_factory=list, description="下一步课程推荐")
    study_plan_summary: str = Field(description="学习计划摘要")
    estimated_improvement: str = Field(description="预期提升效果")


# ==================== 最终报告对象 ====================

class ChartData(BaseModel):
    """图表数据"""
    chart_type: Literal["bar", "line", "pie", "radar", "heatmap"] = Field(description="图表类型")
    title: str = Field(description="图表标题")
    data: Dict[str, Any] = Field(description="图表数据")
    description: str = Field(description="图表说明")


class LearningReport(BaseModel):
    """最终学习报告"""
    report_id: str = Field(description="报告ID")
    user_id: int = Field(description="用户ID")
    period_type: str = Field(description="周期类型：weekly/monthly/quarterly")
    period_start: datetime = Field(description="周期开始时间")
    period_end: datetime = Field(description="周期结束时间")

    # 文字总结
    executive_summary: str = Field(description="执行摘要")
    learning_profile: Dict[str, Any] = Field(description="学习画像")
    dimension_analysis: List[Dict[str, Any]] = Field(description="维度分析")
    action_plan: Dict[str, List[str]] = Field(description="行动计划")
    closing_message: str = Field(description="结语")

    # 原始数据
    statistics_data: StatisticsData = Field(description="统计数据")
    analysis_result: AnalysisResult = Field(description="分析结果")
    recommendation_result: RecommendationResult = Field(description="推荐结果")

    # 图表数据
    charts: List[ChartData] = Field(default_factory=list, description="图表列表")

    # 元数据
    generated_at: datetime = Field(default_factory=datetime.now, description="生成时间")
    generation_time_ms: int = Field(description="生成耗时（毫秒）")
    agents_involved: List[str] = Field(description="参与的智能体")
    cache_hit_rate: float = Field(description="缓存命中率")


# ==================== LangGraph 共享状态 ====================

class AgentState(TypedDict, total=False):
    """智能体共享状态（LangGraph State）"""

    # 输入参数
    user_id: int
    period_type: str
    period_start: datetime
    period_end: datetime
    tenant_id: str
    dept_id: Optional[int]

    # 智能体执行状态
    current_agent: str
    next_agent: Optional[str]
    agents_executed: List[str]

    # 数据收集结果
    statistics_data: Optional[StatisticsData]
    statistics_errors: List[str]

    # 分析结果
    analysis_result: Optional[AnalysisResult]
    analysis_errors: List[str]

    # 推荐结果
    recommendation_result: Optional[RecommendationResult]
    recommendation_errors: List[str]

    # 最终报告
    final_report: Optional[LearningReport]

    # 条件路由控制
    data_completeness: float  # 0-1，用于判断是否需要兜底
    should_skip_analysis: bool
    should_skip_recommendation: bool
    should_use_fallback: bool

    # 缓存控制
    cache_keys: Dict[str, str]
    cache_hits: List[str]
    cache_misses: List[str]

    # 错误处理
    errors: List[Dict[str, Any]]
    retry_count: int
    max_retries: int

    # 性能监控
    start_time: datetime
    agent_timings: Dict[str, float]  # 每个智能体的执行时间


class AgentMessage(BaseModel):
    """智能体间通信消息"""
    from_agent: str = Field(description="发送方智能体")
    to_agent: str = Field(description="接收方智能体")
    message_type: Literal["data", "command", "error", "status"] = Field(description="消息类型")
    content: Dict[str, Any] = Field(description="消息内容")
    timestamp: datetime = Field(default_factory=datetime.now, description="时间戳")
    priority: Literal["high", "normal", "low"] = Field(default="normal", description="优先级")


class AgentConfig(BaseModel):
    """智能体配置"""
    agent_name: str = Field(description="智能体名称")
    agent_type: Literal["statistics", "analysis", "recommendation", "supervisor"] = Field(description="智能体类型")
    enabled: bool = Field(default=True, description="是否启用")
    timeout_seconds: int = Field(default=30, description="超时时间（秒）")
    max_retries: int = Field(default=3, description="最大重试次数")
    cache_enabled: bool = Field(default=True, description="是否启用缓存")
    cache_ttl_seconds: int = Field(default=600, description="缓存过期时间（秒）")
    parallel_tasks: Optional[List[str]] = Field(None, description="可并行执行的子任务")
    dependencies: List[str] = Field(default_factory=list, description="依赖的其他智能体")
    fallback_strategy: Literal["default", "skip", "retry"] = Field(default="default", description="兜底策略")
