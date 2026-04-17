from pydantic import BaseModel, Field


class ToolPolicy(BaseModel):
    all_local_mode: bool = True
    internet_enabled: bool = False
    shell_allowed: bool = False
    write_requires_preview: bool = True
    allowed_tools: list[str] = Field(default_factory=lambda: ["filesystem_read", "grep", "retriever"])
    denied_tools: list[str] = Field(default_factory=lambda: ["delete_file"])


class ExecutionPolicy(BaseModel):
    max_steps: int = 30
    max_tokens: int = 12000
    max_duration_seconds: int = 1800
    branch_per_job: bool = True
    dry_run: bool = True
