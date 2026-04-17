TEMPLATES = {
    "codebase_analysis": {
        "version": "v1",
        "system_prompt": "Analyze the repository and produce architecture, risks, test gaps, and a prioritized next-action plan.",
    },
    "documentation_generation": {
        "version": "v1",
        "system_prompt": "Generate high-quality project documentation with setup, architecture, modules, and operational runbooks.",
    },
    "architecture_summarization": {
        "version": "v1",
        "system_prompt": "Summarize system architecture, boundaries, dependencies, and critical execution paths.",
    },
    "api_map_generation": {
        "version": "v1",
        "system_prompt": "Create an API map of routes, handlers, data contracts, and integration dependencies.",
    },
    "test_generation": {
        "version": "v1",
        "system_prompt": "Propose and generate robust tests with a clear plan, edge cases, and execution guidance.",
    },
    "refactor_advisor": {
        "version": "v1",
        "system_prompt": "Identify anti-patterns, duplication, poor boundaries, and propose a concrete refactor plan.",
    },
    "bug_hunt": {
        "version": "v1",
        "system_prompt": "Hunt for defects and code smells, then rank likely impact and remediation urgency.",
    },
    "release_notes": {
        "version": "v1",
        "system_prompt": "Draft changelog and release notes with concise highlights, risks, and upgrade guidance.",
    },
    "repository_onboarding": {
        "version": "v1",
        "system_prompt": "Create an onboarding guide with setup steps, key workflows, and first tasks for new contributors.",
    },
    "project_qa": {
        "version": "v1",
        "system_prompt": "Answer repository questions using grounded citations to indexed files and relevant code snippets.",
    },
    "research_document": {
        "version": "v1",
        "system_prompt": "Summarize, cluster, and extract actionable insights from documents and knowledge sources.",
    },
    "long_running_agent": {
        "version": "v1",
        "system_prompt": "Execute multi-step agent plans with checkpoints, retries, and auditable step outputs.",
    },
}

SUPPORTED_JOB_TYPES = frozenset(TEMPLATES.keys())
