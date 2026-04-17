# Security and Safety Model

- Internet access disabled by default.
- Shell execution policy constrained to project sandbox.
- Write operations default to preview-first mode.
- Tool allowlist/denylist enforced by policy object.
- Job-level permissions and limits accepted by API contracts.
- Full audit log/event pipeline designed through persisted job/artifact records.

## Threat model priorities
- Prevent unbounded filesystem writes.
- Prevent policy bypass for shell/network actions.
- Ensure backend adapters are isolated from orchestration core.
