from collections.abc import AsyncIterator
from typing import Any

import httpx

from app.inference.base import InferenceAdapter


class OpenAICompatibleAdapter(InferenceAdapter):
    def __init__(self, backend: str, base_url: str, api_key: str):
        self.backend = backend
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key

    @property
    def _headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self.api_key}"}

    async def health(self) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=5.0) as client:
            r = await client.get(f"{self.base_url}/models", headers=self._headers)
            return {"ok": r.status_code < 400, "status_code": r.status_code}

    async def list_models(self) -> list[dict[str, Any]]:
        async with httpx.AsyncClient(timeout=10.0) as client:
            r = await client.get(f"{self.base_url}/models", headers=self._headers)
            r.raise_for_status()
            return r.json().get("data", [])

    async def chat(self, payload: dict[str, Any]) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=120.0) as client:
            r = await client.post(
                f"{self.base_url}/chat/completions", json=payload, headers=self._headers
            )
            r.raise_for_status()
            return r.json()

    async def stream(self, payload: dict[str, Any]) -> AsyncIterator[str]:
        request_payload = {**payload, "stream": True}
        async with httpx.AsyncClient(timeout=120.0) as client:
            async with client.stream(
                "POST",
                f"{self.base_url}/chat/completions",
                json=request_payload,
                headers=self._headers,
            ) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if line:
                        yield line
