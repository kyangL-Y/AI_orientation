"""
多智能体学习报告系统 - 架构设计文档

## 系统架构

### Supervisor 分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Supervisor Agent                          │
│  - 协调所有子智能体                                           │
│  - 管理共享状态                                              │
│  - 实现条件路由                                              │
│  - 聚合结果生成报告                                          │
└──────────────────┬──────────────────────────────────────────┘
                   │
        ┌──────────┼──────────┬──────────────┐
        │          │          │              │
        ▼          ▼          ▼              ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│Statistics│ │ Analysis │ │Recommend │ │ Fallback │
│  Agent   │ │  Agent   │ │  Agent   │ │  Handler │
└──────────┘ └──────────┘ └──────────┘ └──────────┘
     │            │             │
     │            │             │
     ▼            ▼             ▼
┌────────────────────────────────────┐
│        Shared State (AgentState)   │
│  - 用户数据                         │
│  - 统计结果                         │
│  - 分析结果                         │
│  - 推荐结果                         │
│  - 缓存状态                         │
│  - 错误信息                         │
└────────────────────────────────────┘
```

### LangGraph 工作流设计

```
START
  │
  ▼
┌────────────────┐
│   Supervisor   │ ◄─────────┐
│  (路由决策)     │           │
└────────┬───────┘           │
         │                   │
   并行执行(fan-out)          │
    ┌────┼────┬─────┐        │
    │    │    │     │        │
    ▼    ▼    ▼     ▼        │
  ┌───┐┌───┐┌───┐┌───┐      │
  │学习││课程││考试││错题│    │
  │时长││进度││成绩││分布│    │
  └─┬─┘└─┬─┘└─┬─┘└─┬─┘      │
    │    │    │    │         │
    └────┴────┴────┘         │
           │                 │
       汇总(fan-in)          │
           │                 │
           ▼                 │
    ┌─────────────┐          │
    │ 数据完整度   │          │
    │   检查       │          │
    └──┬──────┬───┘          │
       │      │              │
  完整 │      │ 缺失         │
       │      └──► 兜底处理 ──┘
       │
       ▼
  ┌─────────┐
  │ Analysis│
  │  Agent  │
  └────┬────┘
       │
       ▼
  ┌──────────┐
  │Recommend │
  │  Agent   │
  └────┬─────┘
       │
       ▼
  ┌──────────┐
  │Supervisor│
  │生成报告   │
  └────┬─────┘
       │
       ▼
      END
```

### 条件路由逻辑

1. **数据完整度检查**
   - `data_completeness >= 0.8`: 正常流程
   - `0.5 <= data_completeness < 0.8`: 部分兜底 + 继续
   - `data_completeness < 0.5`: 完全兜底，使用历史数据

2. **分析智能体路由**
   - 有错题数据: 深度分析
   - 无错题数据: 基础分析
   - 数据严重缺失: 跳过分析

3. **推荐智能体路由**
   - 有分析结果: 精准推荐
   - 无分析结果: 通用推荐
   - 完全无数据: 使用默认推荐模板

### 智能体职责

#### 1. Statistics Agent (统计智能体)
**职责**: 并行获取用户学习数据
**子任务**:
- 学习时长统计
- 课程进度查询
- 考试成绩汇总
- 错题分布分析
- 部门排名计算

**输出**: `StatisticsData` 对象

**并行策略**: 5个子任务同时执行，使用 asyncio.gather()

**兜底策略**:
- 单个数据源失败 → 标记缺失，继续其他任务
- 全部失败 → 返回空数据 + 错误列表

#### 2. Analysis Agent (分析智能体)
**职责**: 识别薄弱点、分析趋势、对比部门
**输入**: `StatisticsData`
**输出**: `AnalysisResult` 对象

**分析维度**:
1. 薄弱知识点识别
   - 错误率 > 30% → 高风险
   - 错误率 20-30% → 中风险
   - 错误率 < 20% → 低风险

2. 知识掌握趋势
   - 对比历史数据
   - 计算变化率
   - 识别进步/退步模块

3. 部门对比
   - 用户 vs 部门平均
   - 排名百分位
   - 优劣势分析

**兜底策略**:
- 数据不足 → 基础统计分析
- 无历史数据 → 仅当前期分析

#### 3. Recommendation Agent (推荐智能体)
**职责**: 推荐复习内容和下一步课程
**输入**: `AnalysisResult` + `StatisticsData`
**输出**: `RecommendationResult` 对象

**推荐策略**:
1. 复习内容推荐
   - 按薄弱点严重程度排序
   - 提取相关错题
   - 推荐相关课程章节

2. 下一步课程推荐
   - 基于当前进度
   - 匹配知识图谱
   - 考虑难度梯度

**兜底策略**:
- 无分析结果 → 推荐热门课程
- 无错题数据 → 推荐进阶课程

#### 4. Supervisor Agent (主管智能体)
**职责**: 协调、路由、聚合、生成报告
**核心功能**:

1. **状态管理**
   - 维护 AgentState
   - 追踪执行进度
   - 记录缓存命中

2. **条件路由**
   ```python
   def route_next(state: AgentState) -> str:
       if state["data_completeness"] < 0.5:
           return "fallback_handler"
       if state["statistics_data"] is None:
           return "fallback_handler"
       if state["current_agent"] == "statistics":
           return "analysis"
       if state["current_agent"] == "analysis":
           return "recommendation"
       if state["current_agent"] == "recommendation":
           return "generate_report"
       return END
   ```

3. **结果聚合**
   - 整合所有智能体输出
   - 生成文字总结
   - 生成图表数据
   - 格式化最终报告

4. **图表生成**
   - 学习时长趋势图（折线图）
   - 错题分布图（饼图）
   - 能力雷达图（雷达图）
   - 部门排名对比图（条形图）
   - 知识掌握热力图（热力图）

### 状态共享机制

**AgentState 流转**:
```python
# 初始状态
state = {
    "user_id": 123,
    "period_type": "weekly",
    "agents_executed": [],
    "errors": [],
    "cache_hits": [],
    "cache_misses": []
}

# Statistics Agent 更新
state["statistics_data"] = StatisticsData(...)
state["data_completeness"] = 0.85
state["agents_executed"].append("statistics")

# Analysis Agent 读取 + 更新
stats = state["statistics_data"]  # 读取上游数据
state["analysis_result"] = AnalysisResult(...)
state["agents_executed"].append("analysis")

# Recommendation Agent 读取 + 更新
analysis = state["analysis_result"]
state["recommendation_result"] = RecommendationResult(...)

# Supervisor 聚合
state["final_report"] = LearningReport(...)
```

### 缓存策略

#### 三级缓存
1. **智能体结果缓存** (Redis)
   - Key: `agent:{agent_name}:{user_id}:{period_hash}`
   - TTL: 10分钟
   - 命中 → 跳过执行

2. **数据库查询缓存** (Redis)
   - Key: `db:{table}:{query_hash}`
   - TTL: 5分钟
   - 减少重复查询

3. **AI 调用缓存** (Redis)
   - Key: `ai:{prompt_hash}:{model}`
   - TTL: 30分钟
   - 相同输入复用结果

#### 缓存失效策略
- 用户新增学习记录 → 清除该用户所有缓存
- 部门数据更新 → 清除部门相关缓存
- 手动触发 → 清除指定缓存

### 重试机制

```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10),
    reraise=True
)
async def execute_agent_with_retry(agent, state):
    return await agent.execute(state)
```

**重试场景**:
- 网络超时
- 数据库连接失败
- AI API 限流
- 临时性错误

**不重试场景**:
- 参数错误
- 权限不足
- 数据不存在
- 业务逻辑错误

### 性能优化目标

**目标**: 报告生成速度提升 30%

**优化手段**:
1. 并行执行统计任务 → 节省 40% 时间
2. 三级缓存机制 → 节省 60% 重复计算
3. 数据库查询优化 → 节省 20% IO 时间
4. 智能体结果复用 → 节省 50% AI 调用

**理论提升**:
- 无缓存场景: 25-30% 提升（并行化）
- 有缓存场景: 50-60% 提升（缓存 + 并行）
- 综合平均: 35-40% 提升

### 监控指标

1. **性能指标**
   - 总生成时间
   - 各智能体执行时间
   - 缓存命中率
   - 数据库查询时间

2. **质量指标**
   - 数据完整度
   - 分析置信度
   - 推荐相关性
   - 报告可读性

3. **可用性指标**
   - 成功率
   - 错误率
   - 重试次数
   - 兜底触发率
