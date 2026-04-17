# Forge Architecture

## High-level split

### A) Inference subsystem
- Adapter boundary: `app/inference/base.py`
- OpenAI-compatible implementation: `app/inference/openai_compatible.py`
- Adapter registry/factory: `app/inference/adapters.py`
- Supported capabilities:
  - health
  - model listing
  - chat/completions
  - streaming
  - config metadata and backend feature flags

### B) Project/job subsystem
- Domain models: `app/models/entities.py`
- API contracts: `app/schemas/contracts.py`
- Orchestration service: `app/services/jobs.py`
- Queue worker: `app/workers/runner.py`

## Data & execution flow
1. Frontend creates project/model/job.
2. API persists records in PostgreSQL.
3. API enqueues Dramatiq actor via Redis.
4. Worker processes job with policy/template constraints.
5. Artifacts are persisted and surfaced in UI.

## Retrieval and indexing design
- PostgreSQL + pgvector planned as primary vector store.
- Parser/index workers in Python for file-type aware ingestion.
- Include/exclude glob controls per project and knowledge source.

## API/UI contract stability
- Pydantic + TypeScript contracts drive clear boundaries.
- All backend-specific inference logic is hidden behind adapter interfaces.

## Diagram
```text
Next.js UI -> FastAPI -> Job service -> Dramatiq -> Worker
                     |              |
                     |              -> Inference adapters (vLLM/oobabooga)
                     -> PostgreSQL (app + pgvector), Redis (queue)
```
