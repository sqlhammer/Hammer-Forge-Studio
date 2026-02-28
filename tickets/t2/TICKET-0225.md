---
id: TICKET-0225
title: "Feature — Parallel milestone orchestration via isolated per-instance state directories"
type: FEATURE
status: OPEN
priority: P2
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "T2"
phase: "TBD"
depends_on: []
blocks: []
tags: [orchestrator, conductor, parallel, milestone, state, tooling, t2]
---

## Summary

The orchestrator is a single-instance system: one `state.json`, one `godot_mcp.lock`, one `activity.log`, and one `pending_gate.json` — all in the same `orchestrator/` directory. This makes it impossible to run two milestones concurrently (e.g., M8 game tickets alongside T2 tooling tickets), because a second conductor process would either clobber the first's state or fail to start.

This ticket refactors the orchestrator so that each conductor instance operates from its own isolated state directory, enabling multiple milestones to run in parallel without conflict.

## Acceptance Criteria

- [ ] A conductor instance can be launched against a named state directory distinct from the default `orchestrator/` working directory (e.g., via `HFS_ORCH_DIR` environment variable or `--state-dir` CLI flag)
- [ ] All shared singleton files (`state.json`, `godot_mcp.lock`, `activity.log`, `pending_gate.json`, `gate_response.json`) are resolved relative to the instance's state directory — never hardcoded to `orchestrator/`
- [ ] Two conductor instances can run simultaneously on different milestones (e.g., M8 and T2) without either instance reading or writing the other's state
- [ ] `start_milestone.py` accepts a `--state-dir` argument so a new milestone can be initialized in a designated directory
- [ ] `status.py` accepts a `--state-dir` argument (or reads `HFS_ORCH_DIR`) so the correct instance's state is displayed
- [ ] The `godot_mcp.lock` path is per-instance — two parallel instances coordinate Godot editor access through their own locks, not a shared global lock
  - Note: if both instances need Godot editor access simultaneously, external coordination (e.g., a global Godot semaphore file outside both state dirs) may be required; document this limitation and the recommended workaround
- [ ] Existing single-instance behavior is fully preserved — running a conductor without `--state-dir` or `HFS_ORCH_DIR` continues to use `orchestrator/` as the default (no breaking change)
- [ ] Documentation updated: README or engineering doc explains how to launch parallel milestones and manage per-instance state directories
- [ ] Full orchestrator test suite passes with no new failures (both single-instance and multi-instance paths)

## Implementation Notes

### Root Cause

All path constants in `conductor.py` are defined at module level relative to a fixed `orchestrator/` base:

```python
STATE_PATH = Path("orchestrator/state.json")
LOCK_PATH  = Path("orchestrator/godot_mcp.lock")
LOG_PATH   = Path("orchestrator/activity.log")
GATE_PATH  = Path("orchestrator/pending_gate.json")
```

These must become instance-level variables resolved from a configurable base directory.

### Recommended Approach

1. Introduce an `ORCH_DIR` variable resolved at startup:
   ```python
   ORCH_DIR = Path(os.environ.get("HFS_ORCH_DIR", "orchestrator"))
   ```
2. Derive all singleton paths from `ORCH_DIR`:
   ```python
   STATE_PATH = ORCH_DIR / "state.json"
   LOCK_PATH  = ORCH_DIR / "godot_mcp.lock"
   LOG_PATH   = ORCH_DIR / "activity.log"
   GATE_PATH  = ORCH_DIR / "pending_gate.json"
   ```
3. Pass `ORCH_DIR` into `start_milestone.py` and `status.py` via the same env var or a `--state-dir` CLI arg
4. For parallel Godot access: introduce a **global** semaphore at a fixed path outside any instance directory (e.g., `orchestrator/.godot_global.lock`) that all instances must acquire before any Tier-3 Godot tool call, regardless of their own `ORCH_DIR`

### Godot Access Coordination

When two instances both need the Godot editor, they must serialize. Options:
- **Global lock file**: a single `orchestrator/.godot_global.lock` that supersedes the per-instance lock for editor access
- **Port-based mutex**: the Godot MCP server listens on a fixed port; a failed connection attempt indicates another instance holds it
- Document whichever approach is chosen in the resilience runbook

### Non-Goals

- This ticket does NOT implement cross-milestone dependency tracking (a game milestone ticket depending on a tooling milestone ticket)
- This ticket does NOT implement a UI or dashboard for monitoring multiple instances — that is T1 scope

## Activity Log

- 2026-02-28 [producer] Created — Studio Head asked whether parallel milestone orchestration (e.g., T2 alongside M8) is currently possible; it is not; this ticket tracks the fix
