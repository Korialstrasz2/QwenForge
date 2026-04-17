from datetime import datetime
from enum import Enum
from typing import Optional

from sqlmodel import Field, SQLModel


class JobStatus(str, Enum):
    queued = "queued"
    running = "running"
    completed = "completed"
    failed = "failed"
    paused = "paused"
    cancelled = "cancelled"


class Project(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    path: str
    include_globs: str = "**/*"
    exclude_globs: str = "**/.git/**,**/node_modules/**"
    indexed: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)


class Job(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    project_id: int
    job_type: str
    status: JobStatus = Field(default=JobStatus.queued)
    backend: str
    model_id: str
    template_version: str = "v1"
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class Artifact(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    job_id: int
    artifact_type: str
    title: str
    path: str
    content: str
    created_at: datetime = Field(default_factory=datetime.utcnow)


class ModelProfile(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
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
