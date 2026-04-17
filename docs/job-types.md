# Job Types

Forge exposes these templates:
1. Codebase analysis
2. Documentation generation
3. Architecture summarization
4. API map generation
5. Test generation
6. Refactor proposal generation
7. Bug-hunt / smell detection
8. Changelog / release note drafting
9. Repository onboarding summary
10. Project Q&A
11. Document ingestion/summarization/topic extraction
12. Long-running multi-step agent jobs with checkpoints

## Implemented vertical slice
- Job creation, queuing, status updates.
- Artifact generation and review in UI.
- Policies for dry-run, branch-per-job, and tool controls.

## Planned deepening
- Real multi-step checkpoint graph.
- Full tool-runtime invocation with per-step approval gates.
- Native branch/worktree orchestration and rollback.
