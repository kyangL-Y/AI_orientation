"""
配置管理模块

从环境变量加载配置
"""

import os
from typing import Optional
from pydantic_settings import BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    """系统配置"""

    # AI Model Configuration
    DASHSCOPE_API_KEY: str = Field(..., description="DashScope API Key")
    DASHSCOPE_BASE_URL: str = Field(
        default="https://dashscope.aliyuncs.com/compatible-mode/v1",
        description="DashScope API Base URL"
    )
    AI_MODEL: str = Field(default="qwen-plus", description="AI Model Name")
    AI_TEMPERATURE: float = Field(default=0.7, description="AI Temperature")
    AI_MAX_TOKENS: int = Field(default=2000, description="AI Max Tokens")

    # Redis Configuration
    REDIS_HOST: str = Field(default="localhost", description="Redis Host")
    REDIS_PORT: int = Field(default=6379, description="Redis Port")
    REDIS_PASSWORD: Optional[str] = Field(default=None, description="Redis Password")
    REDIS_DB: int = Field(default=0, description="Redis Database")
    REDIS_CACHE_TTL: int = Field(default=300, description="Redis Cache TTL (seconds)")

    # Database Configuration
    DB_HOST: str = Field(default="localhost", description="MySQL Host")
    DB_PORT: int = Field(default=3306, description="MySQL Port")
    DB_NAME: str = Field(default="hz-vue", description="Database Name")
    DB_USER: str = Field(default="root", description="Database User")
    DB_PASSWORD: str = Field(..., description="Database Password")

    # Java Service Bridge
    JAVA_SERVICE_URL: str = Field(default="http://localhost:8080", description="Java Service URL")
    JAVA_SERVICE_TIMEOUT: int = Field(default=30, description="Java Service Timeout (seconds)")

    # Multi-Agent System Configuration
    SUPERVISOR_TIMEOUT: int = Field(default=60, description="Supervisor Timeout (seconds)")
    AGENT_RETRY_MAX_ATTEMPTS: int = Field(default=3, description="Agent Retry Max Attempts")
    AGENT_RETRY_BACKOFF_FACTOR: int = Field(default=2, description="Agent Retry Backoff Factor")
    ENABLE_PARALLEL_EXECUTION: bool = Field(default=True, description="Enable Parallel Execution")
    ENABLE_RESULT_CACHE: bool = Field(default=True, description="Enable Result Cache")
    CACHE_DURATION_SECONDS: int = Field(default=600, description="Cache Duration (seconds)")

    # Logging Configuration
    LOG_LEVEL: str = Field(default="INFO", description="Log Level")
    LOG_FORMAT: str = Field(default="json", description="Log Format (json/console)")

    # Performance Monitoring
    ENABLE_METRICS: bool = Field(default=True, description="Enable Metrics")
    METRICS_PORT: int = Field(default=9090, description="Metrics Port")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


# 全局配置实例
settings = Settings()
