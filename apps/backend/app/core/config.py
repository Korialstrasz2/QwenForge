from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "Forge API"
    app_env: str = "dev"

    database_url: str = "postgresql+psycopg://forge:forge@localhost:5432/forge"
    redis_url: str = "redis://localhost:6379/0"

    feature_oobabooga: bool = False
    default_inference_backend: str = "vllm"
    default_inference_base_url: str = "http://localhost:8001/v1"
    default_inference_api_key: str = "local-key"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
