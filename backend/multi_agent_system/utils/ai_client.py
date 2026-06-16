"""
工具类 - AI 客户端

支持 DashScope API 调用，提供文本生成和结构化输出
"""

import json
from typing import Dict, Any, Optional
import httpx
import structlog
from tenacity import retry, stop_after_attempt, wait_exponential

from ..config import settings

logger = structlog.get_logger(__name__)


class AIClient:
    """AI 客户端（DashScope）"""

    def __init__(self):
        self.api_key = settings.DASHSCOPE_API_KEY
        self.base_url = settings.DASHSCOPE_BASE_URL
        self.model = settings.AI_MODEL
        self.timeout = httpx.Timeout(30.0, connect=10.0)

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        reraise=True
    )
    async def generate_text(
        self,
        prompt: str,
        max_tokens: int = 2000,
        temperature: float = 0.7,
        system_prompt: Optional[str] = None
    ) -> str:
        """生成文本"""
        logger.debug("ai_generate_text_started", prompt_length=len(prompt))

        messages = []

        if system_prompt:
            messages.append({
                "role": "system",
                "content": system_prompt
            })

        messages.append({
            "role": "user",
            "content": prompt
        })

        request_body = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens
        }

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                f"{self.base_url}/chat/completions",
                json=request_body,
                headers=headers
            )

            response.raise_for_status()
            result = response.json()

            if "choices" not in result or not result["choices"]:
                raise ValueError("AI API returned invalid response")

            content = result["choices"][0]["message"]["content"]
            logger.debug("ai_generate_text_completed", response_length=len(content))
            return content

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        reraise=True
    )
    async def generate_json(
        self,
        prompt: str,
        max_tokens: int = 2000,
        temperature: float = 0.7,
        system_prompt: Optional[str] = None
    ) -> Dict[str, Any]:
        """生成 JSON 格式响应"""
        logger.debug("ai_generate_json_started", prompt_length=len(prompt))

        if not system_prompt:
            system_prompt = "你是一个专业的数据分析助手。请严格按照JSON格式返回结果，不要包含任何其他内容。"

        text_response = await self.generate_text(
            prompt=prompt,
            max_tokens=max_tokens,
            temperature=temperature,
            system_prompt=system_prompt
        )

        # 清理可能的 markdown 代码块标记
        cleaned = text_response.strip()
        if cleaned.startswith("```json"):
            cleaned = cleaned[7:]
        elif cleaned.startswith("```"):
            cleaned = cleaned[3:]
        if cleaned.endswith("```"):
            cleaned = cleaned[:-3]
        cleaned = cleaned.strip()

        try:
            result = json.loads(cleaned)
            logger.debug("ai_generate_json_completed")
            return result
        except json.JSONDecodeError as e:
            logger.error("json_parse_failed", error=str(e), response=cleaned[:200])
            raise ValueError(f"Failed to parse AI response as JSON: {e}")
