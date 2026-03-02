---
id: TICKET-0274
title: "T3 Integration — Wire GodotInstanceManager into conductor; remove lock system"
type: TASK
status: OPEN
priority: P1
owner: tools-devops-engineer
created_by: producer
created_at: 2026-03-02
updated_at: 2026-03-02
milestone: "T3"
phase: "Integration"
depends_on: [TICKET-0272, TICKET-0273]
blocks: [TICKET-0275]
tags: [tooling, orchestrator, godot-mcp, parallelization]
---

## Summary

Wire `GodotInstanceManager` into `orchestrator/conductor.py`. Remove the old file-based
lock system entirely and replace it with slot-based lifecycle management. After this ticket,
multiple agents with `needs_godot_mcp: true` can run in parallel (up to `max_instances`
concurrently), and Godot is launched and terminated automatically per agent — no manual
setup required.

Reference: `docs/studio/t3-design.md` — "Modify: `_do_dispatching`" and
"Modify: `_do_working` results loop" sections.

---

## Acceptance Criteria

### Remove: Old Lock System
- [ ] Delete constant `GODOT_MCP_LOCK_PATH`
- [ ] Delete function `acquire_godot_mcp_lock()`
- [ ] Delete function `release_godot_mcp_lock()`
- [ ] Delete function `read_godot_mcp_lock()`
- [ ] Remove all lock logic from `_do_dispatching`:
  - The `godot_lock_acquired_for` variable and the `if needs_godot:` guard that checks/sets it
- [ ] Remove any reference to `godot_mcp_exclusive` from conductor logic

### Add: GodotInstanceManager Integration
- [ ] Import `GodotInstanceManager` from `godot_instance_manager` at top of conductor.py
- [ ] Instantiate `GodotInstanceManager` once at conductor startup; call `recover_orphans()`
      immediately on instantiation to clear stale processes from previous runs
- [ ] In `_do_dispatching`, for each ticket with `needs_godot_mcp: true`:
  ```python
  slot = godot_mgr.allocate_slot()
  if slot is None:
      # All slots busy — defer to next wave (same graceful behavior as old lock)
      deferred.append(assignment)
      continue
  pid = godot_mgr.launch(slot, worktree_path, godot_config)
  ready = godot_mgr.wait_for_ready(base_mcp_port + slot, startup_wait_seconds)
  if not ready:
      godot_mgr.terminate(slot)
      self._queue_retry(ticket_id)
      continue
  godot_mgr.write_mcp_config(worktree_path, base_mcp_port + slot, base_runtime_port + slot)
  worker["godot_slot"] = slot
  ```
- [ ] In the `_do_working` results loop, after each worker task completes (success or failure):
  ```python
  if worker.get("godot_slot") is not None:
      godot_mgr.terminate(worker["godot_slot"])
  ```

### Deferral Behavior Preserved
- [ ] When all slots are occupied, extra `needs_godot_mcp` tickets are deferred to the next
      planning wave — identical behavior to the old lock-based deferral

### No Regressions for Non-Godot Agents
- [ ] Agents without `needs_godot_mcp: true` are completely unaffected — no `.mcp.json`
      written, no Godot launched, no slot allocated

---

## Implementation Notes

`godot_config` passed to `godot_mgr.launch()` is the `godot` section of `config.json`
(added in TICKET-0272). Load it via the existing `load_config()` utility.

The `godot_slot` key on the worker dict is transient — it does not need to be persisted to
`state.json`. It only needs to survive within a single conductor run's in-memory state.

If the conductor process itself is killed (not a graceful shutdown), `recover_orphans()` on
the next run will clean up any Godot processes that were not terminated.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-02 [producer] Created ticket — T3 Integration: wire GodotInstanceManager into conductor
