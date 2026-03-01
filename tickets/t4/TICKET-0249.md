---
id: TICKET-0249
title: "Create instance_paths.py shared utility module"
type: FEATURE
status: OPEN
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "T4"
phase: "Foundation"
depends_on: []
blocks: ["TICKET-0250", "TICKET-0251", "TICKET-0252", "TICKET-0253", "TICKET-0254"]
tags: [orchestrator, instance-paths, config-layering, t4-foundation]
---

## Summary

Create `orchestrator/instance_paths.py` — the shared utility module that centralizes all
path resolution and config loading for the multi-milestone orchestrator. Every other T4
ticket depends on this module existing first.

---

## Acceptance Criteria

- [ ] `orchestrator/instance_paths.py` created with:
  - `InstancePaths` dataclass containing all path fields:
    - `orch_dir`, `instance_dir`
    - `config_path` (`orch_dir/config.json`)
    - `config_local_path` (`orch_dir/config.local.json`)
    - `state_path`, `activity_log`, `pending_gate_path`, `gate_response_path`, `godot_mcp_lock_path`
    - `results_dir`, `logs_dir`
    - `prompts_dir`, `schemas_dir` (shared, under `orch_dir`)
  - `resolve_instance(instance_name: str, orch_dir: Path | None = None) -> InstancePaths`:
    - `orch_dir` defaults to `$HFS_ORCH_DIR` env var, then `<repo_root>/orchestrator`
    - `instance_dir = orch_dir / "instances" / instance_name`
    - Creates `instance_dir`, `instance_dir/results`, `instance_dir/logs` on first call
    - Returns fully populated `InstancePaths`
  - `load_config(paths: InstancePaths) -> dict`:
    - Loads `paths.config_path` (required — raises `FileNotFoundError` if absent)
    - If `paths.config_local_path` exists, deep-merges it on top of defaults
    - Returns merged dict
  - `_deep_merge(base: dict, override: dict) -> dict` — private recursive merge helper
    - Merges leaf values: override wins; sub-dicts are merged recursively, not replaced
- [ ] Module has no external dependencies beyond stdlib (`pathlib`, `json`, `os`, `dataclasses`)
- [ ] Module is importable from any script in `orchestrator/`

---

## Implementation Notes

- Repo root detection: walk up from `__file__` to find the directory containing `orchestrator/`
- `_deep_merge` must handle nested dicts (not just top-level keys) — e.g., merging
  `{"budgets": {"session_ceiling_usd": 10}}` must leave other `budgets` keys intact
- Do not add a `per_instance_config_path` — the design calls for two layers only (global defaults + global local override)

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-01 [producer] Created — T4 Foundation phase
