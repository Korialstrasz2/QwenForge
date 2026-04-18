from app.core.config import get_settings
from app.core.network_policy import require_local_endpoint
from app.inference.openai_compatible import OpenAICompatibleAdapter


def build_adapter(backend: str, endpoint: str | None = None, api_key: str | None = None):
    settings = get_settings()
    resolved_endpoint = endpoint or settings.default_inference_base_url
    resolved_api_key = api_key or settings.default_inference_api_key
    require_local_endpoint(resolved_endpoint, all_local_mode=settings.all_local_mode)

    openai_compatible_backends = {"vllm", "llama_cpp", "gguf"}
    if backend in openai_compatible_backends:
        normalized_backend = "llama_cpp" if backend == "gguf" else backend
        return OpenAICompatibleAdapter(normalized_backend, resolved_endpoint, resolved_api_key)

    if backend == "oobabooga":
        if not settings.feature_oobabooga:
            raise ValueError("oobabooga adapter disabled by feature flag")
        return OpenAICompatibleAdapter("oobabooga", resolved_endpoint, resolved_api_key)

    raise ValueError(f"Unsupported backend: {backend}")
