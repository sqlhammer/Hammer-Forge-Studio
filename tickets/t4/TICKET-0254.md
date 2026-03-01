---
id: TICKET-0254
title: "Update resume_planning.py for --instance flag"
type: FEATURE
status: OPEN
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "T4"
phase: "Foundation"
depends_on: ["TICKET-0249"]
blocks: ["TICKET-0256"]
tags: [orchestrator, resume-planning, instance-paths, t4-foundation]
---

## Summary

Update `orchestrator/resume_planning.py` to read and write `state.json` from the instance
directory. Add `--instance <name>` with the same auto-detect logic used in `approve_gate.py`
and `status.py`.

---

## Acceptance Criteria

- [ ] `--instance <name>` argument added (optional; required when multiple instances exist)
- [ ] Auto-detect logic (same as `approve_gate.py`):
  - If only one instance dir exists, use it automatically
  - If multiple instances exist and no `--instance` passed, prompt user to specify
- [ ] `resolve_instance()` used to derive `paths.state_path`
- [ ] All reads/writes of `state.json` in this script use `paths.state_path`
- [ ] Old hardcoded flat paths fully removed

---

## Implementation Notes

- Import `resolve_instance` from `instance_paths`

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-01 [producer] Created — T4 Foundation phase
