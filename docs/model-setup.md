# Model Setup (Local Qwen)

## Choosing the recommended backend
Use **vLLM OpenAI-compatible server** as the default backend for Forge. It provides robust throughput, streaming, and model introspection APIs.

## Starting the inference server
Example vLLM launch:
```bash
python -m vllm.entrypoints.openai.api_server \
  --host 0.0.0.0 \
  --port 8001 \
  --model Qwen/Qwen2.5-Coder-7B-Instruct \
  --dtype auto \
  --max-model-len 32768
```

## Adding the local model profile in the UI
1. Open Forge Control Panel.
2. Add model profile with:
   - Display name: `Qwen Coder Local`
   - Backend: `vllm`
   - Endpoint: `http://localhost:8001/v1`
   - Model ID: `Qwen/Qwen2.5-Coder-7B-Instruct`
   - API key: `local-key` (or configured token)
3. Save as coding/general/cheap helper role as needed.

## Testing connectivity
- Use API endpoint `GET /api/inference/health?backend=vllm`.
- Use model listing endpoint `GET /api/inference/models?backend=vllm`.
- Verify model appears in Forge model selector.

## Troubleshooting common failures
- **Connection refused**: vLLM not running or wrong host/port.
- **401/403**: key mismatch; align Forge profile key and server auth settings.
- **No models returned**: incorrect endpoint (must include `/v1` root).
- **OOM on load**: reduce context length or use quantized variant.

## Notes for RTX 3090 and quantized local models
- 24GB VRAM supports strong 7B/14B quantized coding configs depending on context.
- Prefer AWQ/GPTQ/GGUF-compatible serving paths where available.
- Tune max context conservatively for stable throughput.
- Keep one heavy coding model + one lighter helper profile for parallel workloads.
