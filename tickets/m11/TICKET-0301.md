---
id: TICKET-0301
title: "M11 Standards remediation — Fix direct Input.is_action_just_pressed() bypass in inventory_screen.gd"
type: TASK
status: OPEN
priority: P2
owner: systems-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M11"
phase: "Remediation"
depends_on: []
blocks: []
tags: [standards, communication, remediation, input-manager, inventory]
---

## Summary

Resolve the architectural violation at `inventory_screen.gd` line 84 where `Input.is_action_just_pressed("inventory_toggle")` is called directly, bypassing InputManager.

---

## Acceptance Criteria

- [ ] `inventory_screen.gd` line 84: remove direct `Input.is_action_just_pressed()` call
- [ ] Implement an architectural solution: either add an InputManager exemption mechanism (e.g., a method that bypasses suppression for designated always-active actions) or a separate always-active action check method
- [ ] The `inventory_toggle` action must still close the inventory screen correctly after the fix
- [ ] No other files should use `Input.is_action_just_pressed()` directly (verify zero remaining violations)

---

## Implementation Notes

See audit report `docs/studio/reports/2026-03-03-m11-gdscript-audit.md` Section 3 Communication table, `inventory_screen.gd` line 84. Priority 6 in Section 5. The comment in the original code notes this bypass is intentional to avoid suppression — the fix must preserve this behavior through a compliant mechanism.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — Phase 2 remediation from M11 GDScript audit report (TICKET-0290)
