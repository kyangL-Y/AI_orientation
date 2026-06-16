"""
工具类 - 缓存管理器

支持 Redis 缓存，提供异步接口
"""

import json
from typing import Any, Optional
import redis.asyncio as redis
import structlog
from ..config import settings

logger = structlog.get_logger(__name__)


class CacheManager:
    """Redis 缓存管理器"""

    def __init__(self):
        self.redis_client: Optional[redis.Redis] = None
        self.enabled = settings.ENABLE_RESULT_CACHE

    async def connect(self):
        """连接 Redis"""
        if not self.enabled:
            logger.info("cache_disabled")
            return

        try:
            self.redis_client = redis.Redis(
                host=settings.REDIS_HOST,
                port=settings.REDIS_PORT,
                password=settings.REDIS_PASSWORD or None,
                db=settings.REDIS_DB,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5,
            )
            await self.redis_client.ping()
            logger.info("redis_connected", host=settings.REDIS_HOST, port=settings.REDIS_PORT)
        except Exception as e:
            logger.error("redis_connection_failed", error=str(e))
            self.enabled = False

    async def disconnect(self):
        """断开 Redis 连接"""
        if self.redis_client:
            await self.redis_client.close()
            logger.info("redis_disconnected")

    async def get(self, key: str) -> Optional[Any]:
        """获取缓存"""
        if not self.enabled or not self.redis_client:
            return None

        try:
            value = await self.redis_client.get(key)
            if value:
                logger.debug("cache_get_success", key=key)
                return json.loads(value)
            return None
        except Exception as e:
            logger.warning("cache_get_failed", key=key, error=str(e))
            return None

    async def set(self, key: str, value: Any, ttl: int = 600):
        """设置缓存"""
        if not self.enabled or not self.redis_client:
            return

        try:
            serialized = json.dumps(value, default=str)
            await self.redis_client.setex(key, ttl, serialized)
            logger.debug("cache_set_success", key=key, ttl=ttl)
        except Exception as e:
            logger.warning("cache_set_failed", key=key, error=str(e))

    async def delete(self, key: str):
        """删除缓存"""
        if not self.enabled or not self.redis_client:
            return

        try:
            await self.redis_client.delete(key)
            logger.debug("cache_delete_success", key=key)
        except Exception as e:
            logger.warning("cache_delete_failed", key=key, error=str(e))

    async def delete_pattern(self, pattern: str):
        """批量删除缓存（按模式）"""
        if not self.enabled or not self.redis_client:
            return

        try:
            keys = []
            async for key in self.redis_client.scan_iter(match=pattern):
                keys.append(key)

            if keys:
                await self.redis_client.delete(*keys)
                logger.info("cache_pattern_deleted", pattern=pattern, count=len(keys))
        except Exception as e:
            logger.warning("cache_pattern_delete_failed", pattern=pattern, error=str(e))

    async def exists(self, key: str) -> bool:
        """检查缓存是否存在"""
        if not self.enabled or not self.redis_client:
            return False

        try:
            return await self.redis_client.exists(key) > 0
        except Exception as e:
            logger.warning("cache_exists_check_failed", key=key, error=str(e))
            return False
