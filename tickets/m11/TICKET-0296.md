---
id: TICKET-0296
title: "M11 Scene-First remediation — Main Menu"
type: TASK
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M11"
phase: "Remediation"
depends_on: []
blocks: []
tags: [standards, scene-first, remediation, ui, main-menu]
---

## Summary

Refactor `main_menu.gd` from programmatic UI construction into a .tscn scene.

---

## Acceptance Criteria

- [ ] `main_menu.gd`: create `main_menu.tscn`; move entire menu (ColorRect background, CenterContainer, VBoxContainer, logo zone, spacers, 4 styled Buttons, footer) to scene; remove LAYOUT_IN_READY violations (process_mode at lines 67–69)
- [ ] Replace all `_build_ui()` node construction with `@onready` vars
- [ ] Verify main menu renders correctly and all buttons are functional

---

## Implementation Notes

See audit report `docs/studio/reports/2026-03-03-m11-gdscript-audit.md` Section 2 row for `main_menu.gd` (lines 76–131, 67–69). Priority 1 in Section 5.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — Phase 2 remediation from M11 GDScript audit report (TICKET-0290)
