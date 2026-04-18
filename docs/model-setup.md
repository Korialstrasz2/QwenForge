# Model Setup (Local Qwen)

## Choosing the recommended backend
Use **vLLM OpenAI-compatible server** as the default backend for Forge. It provides robust throughput, streaming, and model introspection APIs.

Forge now also supports a **GGUF mode** via `llama_cpp` OpenAI-compatible server for lower-memory deployments.

## Starting the inference server
Example vLLM launch:
```bash
python -m vllm.entrypoints.openai.api_server \
  --host 0.0.0.0 \
  --port 8001 \
  --model unsloth/Qwen3.6-35B-A3B-Instruct \
  --dtype auto \
  --max-model-len 32768
```

Example GGUF launch (llama.cpp server):
```bash
python -m llama_cpp.server \
  --host 0.0.0.0 \
  --port 8001 \
  --model models/qwen3_6_35b_a3b/your-model.Q4_K_M.gguf \
  --api_key local-key \
  --chat_format chatml
```

## Switching runtime mode at startup
- Run `start_forge.bat`.
- Choose startup mode:
  - `1` = vLLM
  - `2` = GGUF (`llama_cpp`)
- The script starts an OpenAI-compatible inference server for the selected mode on `http://localhost:8001/v1`.
- API/UI features stay the same because Forge talks to both modes through the same OpenAI-compatible interface.

## Adding the local model profile in the UI
1. Open Forge Control Panel.
2. Add model profile with:
   - Display name: `Qwen Coder Local`
   - Backend: `vllm` or `llama_cpp`
   - Endpoint: `http://localhost:8001/v1`
   - Model ID: `unsloth/Qwen3.6-35B-A3B-Instruct` (or `unsloth/Qwen3.6-35B-A3B` for base)
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
