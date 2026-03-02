---
id: TICKET-0275
title: "T3 QA — End-to-end verification of parallel Godot MCP instances"
type: QA
status: OPEN
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-03-02
updated_at: 2026-03-02
milestone: "T3"
phase: "QA"
depends_on: [TICKET-0274]
blocks: []
tags: [tooling, orchestrator, godot-mcp, qa, verification]
---

## Summary

End-to-end verification that the parallel Godot MCP instance system works correctly.
Confirm that multiple agents with `needs_godot_mcp: true` can run concurrently, each with
its own headless Godot process on a unique port, and that all processes are cleaned up
on completion. Confirm no regressions for non-Godot agents.

Reference: `docs/studio/t3-design.md` — Verification Plan section.

---

## Acceptance Criteria

### Multi-Instance Parallel Launch
- [ ] Create a test wave with at least 2 tickets that have `needs_godot_mcp: true`
- [ ] Run the conductor and verify that 2+ separate Godot processes appear simultaneously
      (headless, no GUI window): check Task Manager or `tasklist | findstr Godot`
- [ ] Verify each agent log shows a **different** `GDAI_MCP_SERVER_PORT` value
- [ ] During the run, inspect `orchestrator/godot_instances.json` — multiple slot entries
      should be present with unique PIDs and ports

### Slot Deferral
- [ ] If all `max_instances` slots are occupied, additional `needs_godot_mcp` tickets are
      deferred to the next wave (not failed or errored)
- [ ] Verify deferred tickets run successfully in the subsequent wave

### Cleanup on Completion
- [ ] After the wave completes, all Godot processes are terminated
- [ ] `orchestrator/godot_instances.json` is empty or absent
- [ ] Confirm with `tasklist | findstr Godot` — no stale Godot processes remain

### Orphan Recovery
- [ ] Simulate a conductor crash mid-run (kill the conductor process)
- [ ] Restart the conductor — verify `recover_orphans()` kills any surviving Godot processes
      before the new run begins
- [ ] Confirm no port conflicts occur on the resumed run

### Non-Godot Agent Regression
- [ ] Run a wave with agents that do NOT have `needs_godot_mcp: true`
- [ ] Confirm no `.mcp.json` is written to their worktrees
- [ ] Confirm no Godot process is launched for them
- [ ] Confirm they complete successfully as before

### Lock System Removal
- [ ] Confirm `orchestrator/godot_mcp.lock` is never created during any of the above runs
- [ ] Confirm the conductor runs without errors related to the old lock functions

### Sign-Off
- [ ] All verification steps pass with zero failures
- [ ] Post a Phase Gate Summary to `docs/studio/reports/` before marking DONE

---

## Implementation Notes

Test tickets for the multi-instance test can be minimal stub tickets with
`needs_godot_mcp: true` set — they do not need to perform meaningful Godot work,
just confirm the instance lifecycle works end-to-end.

Check the conductor logs (`orchestrator/logs/`) for port assignment and lifecycle events.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-02 [producer] Created ticket — T3 QA: end-to-end verification
