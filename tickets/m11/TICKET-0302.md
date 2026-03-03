---
id: TICKET-0302
title: "M11 Standards remediation — Add element types to Array declarations and type loop variables (6 files)"
type: TASK
status: IN_PROGRESS
priority: P2
owner: systems-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M11"
phase: "Remediation"
depends_on: []
blocks: []
tags: [standards, typing, remediation]
---

## Summary

Fix untyped Array parameters, return types, variables, and loop variables across 6 files to comply with the GDScript typing standards.

---

## Acceptance Criteria

- [ ] `InputManager.gd` line 180: change Array params to `Array[int]` for `keys`, `mouse_buttons`, `joy_buttons`
- [ ] `InputManager.gd` line 185: change `for key in keys:` to `for key: int in keys:`
- [ ] `InputManager.gd` line 189: change `for button in mouse_buttons:` to `for button: int in mouse_buttons:`
- [ ] `InputManager.gd` line 193: change `for joy_button in joy_buttons:` to `for joy_button: int in joy_buttons:`
- [ ] `collision_probe.gd` line 79: change return type to `Array[ProbeResult]`
- [ ] `collision_probe.gd` line 131: change return type to `Array[ProbeResult]`
- [ ] `collision_probe.gd` lines 80 and 132: change `var results: Array = []` to `var results: Array[ProbeResult] = []`
- [ ] `terrain_generator.gd` line 208: change `var positions: Array = []` to `var positions: Array[Vector3] = []`
- [ ] `fabricator_panel.gd` lines 508/614/692: change `var inputs: Array = ...` to `var inputs: Array[Dictionary] = ...`
- [ ] `mining_minigame_overlay.gd` lines 82/99/121: change `for i in range(...)` to `for i: int in range(...)`
- [ ] `tech_tree_defs.gd` line 53: add element type to `var raw: Array = entry.get(...)` (use `Array[String]` or appropriate type)
- [ ] All changes: verify no type errors introduced; run full test suite

---

## Implementation Notes

See audit report `docs/studio/reports/2026-03-03-m11-gdscript-audit.md` Section 3 Variable Typing table. Priority 7 in Section 5. Most impactful change is `InputManager.gd` as it is a foundational autoload.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — Phase 2 remediation from M11 GDScript audit report (TICKET-0290)
- 2026-03-03 [systems-programmer] Starting work — applying type annotations across 6 files
