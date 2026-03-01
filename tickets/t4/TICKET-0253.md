---
id: TICKET-0253
title: "Update approve_gate.py for --instance flag"
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
tags: [orchestrator, approve-gate, instance-paths, t4-foundation]
---

## Summary

Update `orchestrator/approve_gate.py` to read `pending_gate.json` from and write
`gate_response.json` to the instance directory rather than the flat `orchestrator/` root.
Add `--instance <name>` with the same auto-detect logic as `status.py`.

---

## Acceptance Criteria

- [ ] `--instance <name>` argument added (optional; required when multiple instances exist)
- [ ] Auto-detect logic (same as `status.py`):
  - If only one instance dir exists, use it automatically
  - If multiple instances exist and no `--instance` passed, prompt user to specify
- [ ] `resolve_instance()` used to derive `paths.pending_gate_path` and `paths.gate_response_path`
- [ ] Old hardcoded flat paths fully removed
- [ ] Script still validates that `pending_gate.json` exists (error if no gate is pending)

---

## Implementation Notes

- Import `resolve_instance` from `instance_paths`
- Auto-detect helper can be shared logic — consider a small `_auto_detect_instance(orch_dir)`
  helper in `instance_paths.py` if multiple scripts need it, or inline it per script

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-01 [producer] Created — T4 Foundation phase
- 2026-03-01 [systems-programmer] Starting work — updating approve_gate.py for instance-scoped paths
