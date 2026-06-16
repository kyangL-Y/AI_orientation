"""
工具类 - 数据库管理器

提供异步数据库连接池和查询接口
"""

from typing import Optional
from contextlib import asynccontextmanager
import aiomysql
import structlog
from ..config import settings

logger = structlog.get_logger(__name__)


class DatabaseManager:
    """异步 MySQL 数据库管理器"""

    def __init__(self):
        self.pool: Optional[aiomysql.Pool] = None

    async def connect(self):
        """创建数据库连接池"""
        try:
            self.pool = await aiomysql.create_pool(
                host=settings.DB_HOST,
                port=settings.DB_PORT,
                user=settings.DB_USER,
                password=settings.DB_PASSWORD,
                db=settings.DB_NAME,
                charset='utf8mb4',
                autocommit=True,
                minsize=2,
                maxsize=10,
                pool_recycle=3600,
            )
            logger.info("database_pool_created", host=settings.DB_HOST, db=settings.DB_NAME)
        except Exception as e:
            logger.error("database_connection_failed", error=str(e))
            raise

    async def disconnect(self):
        """关闭数据库连接池"""
        if self.pool:
            self.pool.close()
            await self.pool.wait_closed()
            logger.info("database_pool_closed")

    @asynccontextmanager
    async def get_connection(self):
        """获取数据库连接（上下文管理器）"""
        if not self.pool:
            raise RuntimeError("Database pool not initialized")

        conn = await self.pool.acquire()
        try:
            yield conn
        finally:
            self.pool.release(conn)
