---
id: TICKET-0250
title: "Update conductor.py for instance-scoped paths and --instance flag"
type: FEATURE
status: IN_PROGRESS
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "T4"
phase: "Foundation"
depends_on: ["TICKET-0249"]
blocks: ["TICKET-0256"]
tags: [orchestrator, conductor, instance-paths, t4-foundation]
---

## Summary

Update `orchestrator/conductor.py` to replace all flat path constants with `resolve_instance()`
from `instance_paths.py`, load config via `load_config()`, and add an `--instance` CLI flag so
multiple conductor processes can run concurrently on different milestones without file collision.

---

## Acceptance Criteria

- [ ] All top-level path constants (`STATE_PATH`, `ACTIVITY_LOG`, `RESULTS_DIR`, `LOGS_DIR`,
  `LOCK_FILE`, `PENDING_GATE_PATH`, `GATE_RESPONSE_PATH`, etc.) removed from module scope
- [ ] `REPO_ROOT` and `ORCH_DIR` retained as module-level constants (needed before arg parsing)
- [ ] `main()` updated:
  - `--instance <name>` argument added (optional; defaults to the `<milestone>` positional arg value)
  - Calls `resolve_instance(instance_name)` → `paths`
  - Calls `load_config(paths)` → `config`
  - Passes `paths` and `config` into `Conductor.__init__`
- [ ] `Conductor.__init__` updated:
  - Accepts `paths: InstancePaths` and `config: dict`
  - All internal references to old path constants replaced with `self.paths.*`
  - All `config` dict accesses updated to use the passed-in `config` (no re-loading)
- [ ] All existing conductor behavior is preserved — no logic changes, only path/config sourcing changes
- [ ] `godot_instances.json` (T3 artifact) path updated to live in `instance_dir` if conductor references it

---

## Implementation Notes

- Import `resolve_instance`, `load_config`, `InstancePaths` from `instance_paths`
- The `Conductor` class may currently load config inline — consolidate all config loading to the `load_config()` call in `main()`
- Run the existing test harness (`orchestrator/test_harness.py`) after changes to confirm no regressions

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-01 [producer] Created — T4 Foundation phase
- 2026-03-01 [systems-programmer] Starting work — updating conductor.py for instance-scoped paths
