---
id: TICKET-0251
title: "Update status.py for --instance and --all flags"
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
tags: [orchestrator, status, instance-paths, t4-foundation]
---

## Summary

Update `orchestrator/status.py` to support `--instance <name>` (target a specific instance),
`--all` (list all instances with a one-line summary each), and auto-detection (when only one
instance exists, use it without requiring `--instance`).

---

## Acceptance Criteria

- [ ] `--instance <name>` argument added (optional)
- [ ] `--all` flag added: iterates `orchestrator/instances/*/state.json`, prints a one-line
  summary per instance (instance name, milestone, phase, current wave, ticket counts)
- [ ] Auto-detect logic:
  - If `--all` passed: show all instances
  - If `--instance` passed: show that instance
  - If neither and exactly one instance dir exists: use it automatically
  - If neither and multiple instance dirs exist: print a helpful message listing instances and
    ask user to specify `--instance <name>` or `--all`
  - If neither and no instance dirs exist: print "No instances found. Run start_milestone.py first."
- [ ] `resolve_instance()` used for all path resolution (replaces any hardcoded flat paths)
- [ ] Existing status display output format preserved for single-instance view

---

## Implementation Notes

- Import `resolve_instance`, `load_config` from `instance_paths`
- For `--all`, glob `orch_dir / "instances" / "*" / "state.json"` — skip dirs with no state.json
- One-line summary format suggestion: `M8  |  Phase: Foundation  |  Wave: 3  |  Tickets: 12/28 done`

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-01 [producer] Created — T4 Foundation phase
- 2026-03-01 [systems-programmer] Starting work — updating status.py with --instance and --all flags
