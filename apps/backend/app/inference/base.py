from abc import ABC, abstractmethod
from typing import Any


class InferenceAdapter(ABC):
    backend: str

    @abstractmethod
    async def health(self) -> dict[str, Any]: ...

    @abstractmethod
    async def list_models(self) -> list[dict[str, Any]]: ...

    @abstractmethod
    async def chat(self, payload: dict[str, Any]) -> dict[str, Any]: ...

    @abstractmethod
    async def stream(self, payload: dict[str, Any]): ...
