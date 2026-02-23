---
id: TICKET-0050
title: "QA regression — InputManager refactor (TICKET-0033–0035)"
type: TASK
status: OPEN
priority: P2
owner: qa-engineer
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M3"
milestone_gate: ""
depends_on: [TICKET-0035]
blocks: []
tags: [qa, regression, input, scanning, mining]
---

## Summary
Regression pass on the scan/mine loop following the InputManager refactor (TICKET-0033–0035). Scanner input now routes through InputManager, mining's mouse button registration was corrected, and runtime InputMap modifications were centralized. Confirm no functional regressions were introduced.

## Acceptance Criteria
- [ ] Full test suite passes (all existing suites — no new failures)
- [ ] Scanner input: scan ping triggers correctly via InputManager, compass markers appear, distance readout works
- [ ] Mining input: hold-to-extract works via the corrected mouse button registration, battery drains, resources collected
- [ ] Inventory input: inventory screen opens and closes correctly, input context switches without conflict
- [ ] No crashes or errors in Godot output log during the regression playthrough
- [ ] Results documented with pass/fail note appended to `docs/qa/test-results-M3.md`

## Implementation Notes
- This is a focused regression check, not a full loop QA pass — TICKET-0031 already covers the comprehensive test
- Depends on TICKET-0035 (runtime InputMap centralization) being complete — that is the last functional input change
- TICKET-0033 and TICKET-0034 are already DONE; TICKET-0035 is the final gate
- TICKET-0036 (logging), TICKET-0037 (section ordering), TICKET-0038 (class_name) are non-functional and do not require dedicated QA

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [producer] Created ticket
