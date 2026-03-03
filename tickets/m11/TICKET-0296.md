---
id: TICKET-0296
title: "M11 Scene-First remediation — Main Menu"
type: TASK
status: DONE
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

- [x] `main_menu.gd`: create `main_menu.tscn`; move entire menu (ColorRect background, CenterContainer, VBoxContainer, logo zone, spacers, 4 styled Buttons, footer) to scene; remove LAYOUT_IN_READY violations (process_mode at lines 67–69)
- [x] Replace all `_build_ui()` node construction with `@onready` vars
- [x] Verify main menu renders correctly and all buttons are functional

---

## Implementation Notes

See audit report `docs/studio/reports/2026-03-03-m11-gdscript-audit.md` Section 2 row for `main_menu.gd` (lines 76–131, 67–69). Priority 1 in Section 5.

---

## Handoff Notes

Moved all persistent UI nodes from _build_ui() into main_menu.tscn. Replaced programmatic node creation with @onready var using %PlayButton unique name. Kept _apply_styles() for runtime StyleBoxFlat theme overrides. Updated 3 MainMenu unit tests to use scene instantiation. No new scripts created.

---

## Activity Log

- 2026-03-03 [producer] Created ticket — Phase 2 remediation from M11 GDScript audit report (TICKET-0290)
- 2026-03-03 [gameplay-programmer] Starting work — scene-first remediation for main menu
- 2026-03-03 [gameplay-programmer] DONE — commit fb5cb26, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/329
