---
id: TICKET-0256
title: "QA — integration test: two simultaneous instances + config override smoke test"
type: TASK
status: OPEN
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "T4"
phase: "Foundation"
depends_on: ["TICKET-0249", "TICKET-0250", "TICKET-0251", "TICKET-0252", "TICKET-0253", "TICKET-0254", "TICKET-0255"]
blocks: []
tags: [orchestrator, qa, integration-test, instance-paths, t4-foundation]
---

## Summary

Verify that the T4 multi-milestone orchestrator changes work correctly end-to-end:
isolated instance directories, config layering, and all CLI flags function as designed.

---

## Acceptance Criteria

### Instance Isolation
- [ ] `start_milestone.py M8` creates `orchestrator/instances/M8/state.json` (not flat `orchestrator/state.json`)
- [ ] `start_milestone.py T3 --instance T3` creates `orchestrator/instances/T3/state.json`
- [ ] Both instance directories co-exist independently with no file overlap
- [ ] Printed launch command from `start_milestone.py` includes `--instance <name>`

### Config Layering
- [ ] Create `orchestrator/config.local.json` containing `{"budgets": {"session_ceiling_usd": 10}}`
- [ ] `status.py --instance M8` shows `session_ceiling_usd: 10` (overridden) and all other config
  values from `config.json` defaults (not overridden)
- [ ] Remove `config.local.json`; re-run and confirm original session ceiling is restored

### status --all
- [ ] With two populated instance dirs, `python orchestrator/status.py --all` prints a summary
  line for each instance
- [ ] With one instance dir and no flags, `status.py` auto-detects and shows that instance
- [ ] With multiple instances and no `--instance` / `--all`, a helpful disambiguation message
  is printed

### Gate Approval
- [ ] `python orchestrator/approve_gate.py --instance M8` reads from `instances/M8/` correctly
- [ ] Running without `--instance` when multiple instances exist prompts for specification

### Backward Compatibility
- [ ] If old `orchestrator/state.json` exists from a pre-T4 run, it is simply ignored (not
  loaded, not deleted) — no migration path needed

### .gitignore
- [ ] `git status` shows `orchestrator/instances/` as untracked (gitignored) after creating
  instance directories
- [ ] `orchestrator/config.local.json` is gitignored
- [ ] No stale individual-file gitignore entries remain for flat paths (e.g., `orchestrator/state.json`)

---

## Implementation Notes

- These are smoke tests / manual verification steps, not automated unit tests
- Document findings in the Activity Log
- If any acceptance criterion fails, open a bug ticket referencing the failing criterion

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-01 [producer] Created — T4 Foundation phase (QA gate ticket)
