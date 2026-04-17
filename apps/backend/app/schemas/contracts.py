from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str
    backend: str
    queue: str
    timestamp: datetime


class ProjectCreate(BaseModel):
    name: str
    path: str
    include_globs: str = "**/*"
    exclude_globs: str = "**/.git/**,**/node_modules/**"


class JobCreate(BaseModel):
    project_id: int
    job_type: str
    backend: str
    model_id: str
    permissions: dict[str, Any] = Field(default_factory=dict)
    limits: dict[str, Any] = Field(default_factory=dict)
    prompt_overrides: Optional[dict[str, Any]] = None


class ModelProfileCreate(BaseModel):
    display_name: str
    backend: str
    model_id: str
    endpoint: str
    api_key: str = "local-key"
    quantization_note: str = ""
    context_length: Optional[int] = None
    temperature_default: float = 0.2
    max_output_default: int = 2048
    supports_streaming: bool = True
    supports_tool_calling: bool = True
    supports_reasoning: bool = False
