# Forge

Forge is a production-oriented local desktop/web operator console for running Qwen-powered coding and research agent jobs against local repositories and document collections.

## Highlights
- **Two-subsystem architecture**: inference adapters are cleanly separated from project/job orchestration.
- **Primary inference backend**: vLLM OpenAI-compatible API.
- **Optional backend**: oobabooga (feature-flag gated).
- **FastAPI + Dramatiq backend** with PostgreSQL/pgvector + Redis.
- **Next.js 15 frontend** with dark-mode operator UX, dashboard, jobs, artifacts, and control center.
- **Template studio primitives** and seed job templates for analysis/docs/tests/refactor/research.

## Monorepo structure
- `apps/frontend` – Next.js 15 UI shell.
- `apps/backend` – FastAPI API, inference adapters, orchestration services, worker actors.
- `docs` – architecture, model setup, job types, security, roadmap.

## Quickstart
1. Copy env:
   ```bash
   cp .env.example .env
   ```
2. Start infra + apps:
   ```bash
   docker compose up --build
   ```
3. Open UI: `http://localhost:3000`.
4. API docs: `http://localhost:8000/docs`.


## Windows one-click setup
Run `update_and_install.bat` from the repo root. It will:
- Create `.venv` and install backend/frontend dependencies.
- Create `.env` from `.env.example` if missing.
- Install a vLLM-compatible `setuptools` version and pin `vllm==0.11.0` to avoid long pip resolver backtracking.
- Prompt to optionally download Qwen 3.6 quantized variants from Unsloth.
- Prompt to toggle all-local/offline mode defaults in `.env`.

Then run `start_forge.bat` to launch local services (backend + frontend; and dockerized postgres/redis when Docker is available).

## Local dev commands
```bash
make setup
make up
make down
make backend
make frontend
make test
```

## First run wizard flow
1. Add a model profile (vLLM endpoint + key, local key accepted).
2. Validate connectivity from Control Panel.
3. Register local project path.
4. Run **Codebase Analysis** template.
5. Inspect generated artifacts in Artifact Viewer.

## Environment variables
See `.env.example`.

- `ALL_LOCAL_MODE=true` blocks non-local inference endpoints so Forge stays local-only.
- `HF_HUB_OFFLINE=1` and `TRANSFORMERS_OFFLINE=1` enforce offline model cache behavior.

## Seed/demo mode
The job worker generates starter artifacts per job type so UI and orchestration are testable immediately, then can be replaced with richer agents.

## Limitations
- Current vertical slice ships full architecture and core flows, but advanced steps (real file diff application, AST-level refactors, and full embeddings pipeline) are scaffolded and intentionally conservative.
- Job execution currently uses template-driven placeholder artifact generation as default safe behavior.
- GPU metrics widget is currently reserved for NVML integration.

## Roadmap
See `docs/roadmap.md` for SGLang, Ollama, remote provider support, richer trace UX, and advanced memory/retrieval policy layers.
