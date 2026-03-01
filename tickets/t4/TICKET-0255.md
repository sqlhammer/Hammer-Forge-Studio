---
id: TICKET-0255
title: "Update .gitignore — add instances/ and config.local.json, remove stale flat entries"
type: TASK
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "T4"
phase: "Foundation"
depends_on: []
blocks: ["TICKET-0256"]
tags: [orchestrator, gitignore, cleanup, t4-foundation]
---

## Summary

Update `.gitignore` to reflect the new instance directory model: add the `instances/` directory
and `config.local.json`, and remove the individual flat-path entries that are now subsumed by
the instance directory gitignore rule.

---

## Acceptance Criteria

- [x] `.gitignore` updated to add:
  ```
  orchestrator/instances/
  orchestrator/config.local.json
  ```
- [x] `.gitignore` updated to remove (these are now under `instances/` which is fully gitignored):
  ```
  orchestrator/state.json
  orchestrator/pending_gate.json
  orchestrator/gate_response.json
  orchestrator/godot_mcp.lock
  orchestrator/godot_instances.json
  orchestrator/activity.log
  orchestrator/logs/
  orchestrator/results/
  ```
- [x] Verify `git status` after the change shows no unintended tracked/untracked files

---

## Implementation Notes

- `orchestrator/godot_instances.json` is a T3 artifact — it moves into the instance dir per the
  T4 design; confirm with TICKET-0250 implementer that conductor no longer writes it at the orch root
- This ticket has no code dependency (can be done before or during other tickets) but must be
  complete before QA (TICKET-0256) to avoid stale gitignore entries

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-01 [producer] Created — T4 Foundation phase
- 2026-03-01 [systems-programmer] Starting work — updating .gitignore for T4 instance directory model
- 2026-03-01 [systems-programmer] DONE — commit fb07ff5, pushed to main. Added orchestrator/instances/ and orchestrator/config.local.json; removed 8 stale flat entries. Note: old runtime artifacts (state.json, activity.log, logs/, results/) now appear as untracked at orchestrator root — these are transient runtime files that will be migrated under instances/ by other T4 tickets.
