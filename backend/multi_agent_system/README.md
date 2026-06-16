# 多智能体学习报告系统

> 基于 LangGraph 的多智能体协作系统，智能生成个性化学习报告

[![Python](https://img.shields.io/badge/Python-3.9+-blue.svg)](https://www.python.org/)
[![LangGraph](https://img.shields.io/badge/LangGraph-0.2+-green.svg)](https://github.com/langchain-ai/langgraph)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-teal.svg)](https://fastapi.tiangolo.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📋 项目简介

这是一个基于 **LangGraph** 构建的多智能体协作系统，专门用于生成个性化学习报告。系统采用 **Supervisor 分层架构**，通过多个专业智能体的协作，实现从数据采集、深度分析到个性化推荐的完整流程。

### 核心特性

✨ **多智能体协作**
- 统计智能体：并行获取学习时长、课程进度、考试成绩、错题分布、部门排名
- 分析智能体：识别薄弱知识点、分析知识掌握趋势、对比部门平均水平
- 推荐智能体：推荐复习内容和下一步课程
- 主管智能体：协调子智能体，聚合结果生成结构化报告

🎯 **智能条件路由**
- 数据完整度检查
- 自动兜底策略
- 动态任务分配

🚀 **性能优化**
- 三级缓存机制（智能体结果、数据库查询、AI 调用）
- 并行任务执行
- 指数退避重试
- **报告生成速度提升 30%+**

🔄 **架构优势**
- 智能体独立迭代
- 状态共享与隔离
- 错误隔离与恢复
- 可观测性强

## 🏗️ 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Supervisor Agent                          │
│         协调 | 路由 | 聚合 | 报告生成                         │
└──────────────────┬──────────────────────────────────────────┘
                   │
        ┌──────────┼──────────┬──────────────┐
        │          │          │              │
        ▼          ▼          ▼              ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│Statistics│ │ Analysis │ │Recommend │ │ Fallback │
│  Agent   │ │  Agent   │ │  Agent   │ │  Handler │
│          │ │          │ │          │ │          │
│ 5个并行  │ │ 薄弱点   │ │ 复习内容 │ │ 数据兜底 │
│ 数据源   │ │ 趋势分析 │ │ 课程推荐 │ │ 策略     │
└──────────┘ └──────────┘ └──────────┘ └──────────┘
     │            │             │
     └────────────┴─────────────┘
              │
    ┌─────────▼──────────┐
    │   Shared State     │
    │  (AgentState)      │
    │  - 统计数据        │
    │  - 分析结果        │
    │  - 推荐结果        │
    │  - 缓存状态        │
    └────────────────────┘
```

## 🚀 快速开始

### 前置要求

- Python 3.9+
- Redis 6.0+ （可选，用于缓存）
- MySQL 5.7+
- DashScope API Key

### 安装

```bash
# 1. 克隆项目
cd training-agent-muti_agent/multi_agent_system

# 2. 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/macOS
# 或
venv\Scripts\activate     # Windows

# 3. 安装依赖
pip install -r requirements.txt

# 4. 配置环境变量
cp .env.example .env
# 编辑 .env 文件，填写必要配置

# 5. 启动服务
python main.py
```

服务将在 `http://localhost:8000` 启动。

### 测试

```bash
curl -X POST http://localhost:8000/api/v1/reports/generate \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "period_type": "weekly",
    "period_start": "2024-01-01T00:00:00",
    "period_end": "2024-01-07T23:59:59",
    "tenant_id": "000000"
  }'
```

## 📊 性能表现

| 指标 | 单智能体 | 多智能体 | 提升 |
|------|---------|---------|------|
| 生成时间（无缓存） | 10-15秒 | 8-10秒 | **25-30%** ↑ |
| 生成时间（有缓存） | 8-12秒 | 2-4秒 | **60-70%** ↑ |
| 并发能力 | 5 QPS | 20 QPS | **300%** ↑ |
| 缓存命中率 | N/A | 60-80% | **新增** |
| 可维护性 | 中 | 高 | **显著改善** |

## 📚 文档

- [部署指南](docs/DEPLOYMENT.md) - 完整的部署和配置指南
- [架构设计](docs/architecture.md) - 详细的系统架构说明
- [API 文档](http://localhost:8000/docs) - 启动服务后访问 Swagger UI

## 🔧 配置说明

### 核心配置（.env）

```bash
# AI 模型配置
DASHSCOPE_API_KEY=your_api_key      # 必填
AI_MODEL=qwen-plus                   # 推荐 qwen-plus
AI_TEMPERATURE=0.7                   # 创造性调节

# 缓存配置
ENABLE_RESULT_CACHE=true             # 建议启用
CACHE_DURATION_SECONDS=600           # 10分钟

# 性能配置
ENABLE_PARALLEL_EXECUTION=true       # 并行执行
AGENT_RETRY_MAX_ATTEMPTS=3           # 重试次数
```

## 🤝 集成方式

### 方式1：直接 HTTP 调用

```python
import requests

response = requests.post(
    "http://localhost:8000/api/v1/reports/generate",
    json={
        "user_id": 123,
        "period_type": "weekly",
        "period_start": "2024-01-01T00:00:00",
        "period_end": "2024-01-07T23:59:59",
        "tenant_id": "000000"
    }
)

report = response.json()
```

### 方式2：Java 桥接层

```java
@Autowired
private IMultiAgentReportService multiAgentReportService;

// 生成报告
TrainLearningReport report = multiAgentReportService.generateReportWithMultiAgent(
    userId, periodType, tenantId, periodStart, periodEnd, deptId
);

// 清除缓存
multiAgentReportService.clearUserCache(userId);

// 健康检查
boolean healthy = multiAgentReportService.checkServiceHealth();
```

## 🛠️ 技术栈

- **工作流编排**: LangGraph
- **AI 框架**: LangChain
- **Web 框架**: FastAPI
- **AI 模型**: 阿里云 DashScope (Qwen)
- **缓存**: Redis
- **数据库**: MySQL (异步连接池)
- **日志**: structlog
- **重试**: tenacity
- **类型检查**: Pydantic

## 📈 监控和运维

### 健康检查

```bash
curl http://localhost:8000/health
```

### 清除缓存

```bash
# 清除指定用户缓存
curl -X POST http://localhost:8000/api/v1/cache/clear?user_id=123

# 清除所有缓存
curl -X POST http://localhost:8000/api/v1/cache/clear
```

### 查看日志

```bash
# 实时日志
tail -f logs/multi_agent_system.log

# 错误日志
grep "ERROR" logs/multi_agent_system.log
```

## 🔍 故障排查

| 问题 | 可能原因 | 解决方案 |
|------|---------|---------|
| 服务启动失败 | 依赖缺失 | `pip install -r requirements.txt --force-reinstall` |
| Redis 连接失败 | Redis 未启动 | `redis-server` 或设置 `ENABLE_RESULT_CACHE=false` |
| 数据库连接失败 | 配置错误 | 检查 `.env` 中的数据库配置 |
| AI 调用失败 | API Key 无效 | 验证 `DASHSCOPE_API_KEY` |
| 生成时间过长 | 缓存未启用 | 设置 `ENABLE_RESULT_CACHE=true` |

## 📝 开发指南

### 添加新智能体

1. 在 `agents/` 目录创建新的智能体类
2. 实现 `execute(state: AgentState) -> AgentState` 方法
3. 在 `workflow/graph.py` 中注册新智能体
4. 添加路由逻辑

### 扩展数据源

1. 在 `StatisticsAgent` 中添加新的数据获取方法
2. 更新 `StatisticsData` 模型
3. 在 `AnalysisAgent` 中使用新数据

## 🎯 未来规划

- [ ] 支持更多 AI 模型（OpenAI GPT、Claude 等）
- [ ] 实现图表自动生成和导出
- [ ] 添加 A/B 测试框架
- [ ] 实现智能体性能分析工具
- [ ] 支持流式报告生成
- [ ] 添加 Prometheus 监控指标

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 👥 联系方式

- 项目负责人：[您的名字]
- 邮箱：[您的邮箱]
- 项目地址：[GitHub 链接]

---

**注意**：本项目为 `training-agent-master` 的多智能体增强版本，保持向后兼容的同时提供更强大的报告生成能力。
