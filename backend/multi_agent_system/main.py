"""
主入口 - FastAPI 服务

提供 REST API 供 Java 服务调用
"""

import asyncio
import structlog
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional

from multi_agent_system.workflow import create_learning_report_workflow, initialize_state
from multi_agent_system.utils import CacheManager, DatabaseManager, AIClient
from multi_agent_system.config import settings

# 配置日志
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer() if settings.LOG_FORMAT == "json" else structlog.dev.ConsoleRenderer(),
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger(__name__)

# 创建 FastAPI 应用
app = FastAPI(
    title="Multi-Agent Learning Report System",
    description="多智能体学习报告生成系统 API",
    version="1.0.0"
)

# 配置 CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 全局依赖
cache_manager = CacheManager()
db_manager = DatabaseManager()
ai_client = AIClient()


class GenerateReportRequest(BaseModel):
    """生成报告请求"""
    user_id: int = Field(..., description="用户ID")
    period_type: str = Field(..., description="周期类型：weekly/monthly/quarterly")
    period_start: datetime = Field(..., description="周期开始时间")
    period_end: datetime = Field(..., description="周期结束时间")
    tenant_id: str = Field(..., description="租户ID")
    dept_id: Optional[int] = Field(None, description="部门ID（可选）")


class GenerateReportResponse(BaseModel):
    """生成报告响应"""
    success: bool
    report_id: Optional[str] = None
    report: Optional[dict] = None
    error: Optional[str] = None
    generation_time_ms: Optional[int] = None
    cache_hit_rate: Optional[float] = None


@app.on_event("startup")
async def startup_event():
    """启动时初始化"""
    logger.info("application_starting")
    try:
        await cache_manager.connect()
        await db_manager.connect()
        logger.info("application_started", cache_enabled=settings.ENABLE_RESULT_CACHE)
    except Exception as e:
        logger.error("startup_failed", error=str(e))
        raise


@app.on_event("shutdown")
async def shutdown_event():
    """关闭时清理"""
    logger.info("application_shutting_down")
    try:
        await cache_manager.disconnect()
        await db_manager.disconnect()
        logger.info("application_stopped")
    except Exception as e:
        logger.error("shutdown_failed", error=str(e))


@app.get("/")
async def root():
    """健康检查"""
    return {
        "status": "healthy",
        "service": "Multi-Agent Learning Report System",
        "version": "1.0.0"
    }


@app.get("/health")
async def health_check():
    """详细健康检查"""
    health = {
        "status": "healthy",
        "redis": "unknown",
        "database": "unknown"
    }

    # 检查 Redis
    try:
        if await cache_manager.redis_client.ping():
            health["redis"] = "connected"
    except Exception:
        health["redis"] = "disconnected"
        health["status"] = "degraded"

    # 检查数据库
    try:
        async with db_manager.get_connection() as conn:
            async with conn.cursor() as cursor:
                await cursor.execute("SELECT 1")
                health["database"] = "connected"
    except Exception:
        health["database"] = "disconnected"
        health["status"] = "degraded"

    return health


@app.post("/api/v1/reports/generate", response_model=GenerateReportResponse)
async def generate_report(request: GenerateReportRequest):
    """
    生成学习报告

    基于多智能体工作流生成个性化学习报告
    """
    logger.info("generate_report_request", user_id=request.user_id, period_type=request.period_type)

    try:
        # 初始化状态
        state = initialize_state(
            user_id=request.user_id,
            period_type=request.period_type,
            period_start=request.period_start,
            period_end=request.period_end,
            tenant_id=request.tenant_id,
            dept_id=request.dept_id
        )

        # 创建工作流
        workflow = create_learning_report_workflow(
            cache_manager=cache_manager,
            db_manager=db_manager,
            ai_client=ai_client
        )

        # 执行工作流
        logger.info("workflow_executing", user_id=request.user_id)
        result = await workflow.ainvoke(state)

        # 提取最终报告
        final_report = result.get("final_report")

        if not final_report:
            logger.error("no_final_report", user_id=request.user_id)
            raise HTTPException(status_code=500, detail="Failed to generate report")

        logger.info(
            "report_generated_successfully",
            user_id=request.user_id,
            report_id=final_report.report_id,
            generation_time_ms=final_report.generation_time_ms,
            cache_hit_rate=final_report.cache_hit_rate
        )

        return GenerateReportResponse(
            success=True,
            report_id=final_report.report_id,
            report=final_report.dict(),
            generation_time_ms=final_report.generation_time_ms,
            cache_hit_rate=final_report.cache_hit_rate
        )

    except Exception as e:
        logger.error("generate_report_failed", user_id=request.user_id, error=str(e), exc_info=True)
        return GenerateReportResponse(
            success=False,
            error=str(e)
        )


@app.post("/api/v1/cache/clear")
async def clear_cache(user_id: Optional[int] = None):
    """
    清除缓存

    Args:
        user_id: 用户ID（可选），如果提供则只清除该用户的缓存
    """
    try:
        if user_id:
            pattern = f"agent:*:{user_id}:*"
            await cache_manager.delete_pattern(pattern)
            logger.info("user_cache_cleared", user_id=user_id)
            return {"success": True, "message": f"User {user_id} cache cleared"}
        else:
            pattern = "agent:*"
            await cache_manager.delete_pattern(pattern)
            logger.info("all_cache_cleared")
            return {"success": True, "message": "All agent cache cleared"}
    except Exception as e:
        logger.error("clear_cache_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level=settings.LOG_LEVEL.lower()
    )
