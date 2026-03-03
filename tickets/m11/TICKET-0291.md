---
id: TICKET-0291
title: "M11 Scene-First remediation — Ship Machine Panels (recycler_panel, fabricator_panel, automation_hub_panel)"
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
tags: [standards, scene-first, remediation, ui]
---

## Summary

Refactor 3 machine panel scripts that construct their entire UI in `_ready()`/`_build_ui()` into proper .tscn scenes with `@onready` references.

---

## Acceptance Criteria

- [x] `recycler_panel.gd`: create `recycler_panel.tscn` in the editor; move all persistent nodes (dim layer, main panel, slot row, progress section, button row) to scene; replace `_build_ui()` with `@onready` vars; remove LAYOUT_IN_READY violations (layer, process_mode, visible set in `_ready()`)
- [x] `fabricator_panel.gd`: create `fabricator_panel.tscn`; move entire panel tree (dim layer, recipe list with per-recipe rows, detail column with labeled slots, progress section) to scene; fix 3 untyped Array vars at lines 508/614/692 (change to `Array[Dictionary]`); remove LAYOUT_IN_READY violations
- [x] `automation_hub_panel.gd`: create `automation_hub_panel.tscn`; move entire panel tree (dim layer, center container, main panel, title, config/status columns, footer) to scene; remove LAYOUT_IN_READY violations
- [x] All three scripts: replace programmatic node construction with `@onready var` references; verify game functions identically after refactor

---

## Implementation Notes

See audit report `docs/studio/reports/2026-03-03-m11-gdscript-audit.md` Section 2 rows for `recycler_panel.gd`, `fabricator_panel.gd`, `automation_hub_panel.gd`. Priority 1 in the remediation ordering (Section 5). These three files share the same `_build_ui()` anti-pattern and can use a shared refactoring approach.

---

## Handoff Notes

Refactored all 3 ship machine panel scripts to scene-first pattern:
- `recycler_panel.gd` / `.tscn`: 18 @onready vars, removed _build_ui() and 5 sub-builders
- `fabricator_panel.gd` / `.tscn`: 24 @onready vars, removed _build_ui() and 6 sub-builders, kept _build_recipe_row() (dynamic), fixed 3 untyped Array → Array[Dictionary]
- `automation_hub_panel.gd` / `.tscn`: 18 @onready vars, removed _build_ui() and 5 sub-builders, kept _build_drone_card() (dynamic)
- All: StyleBoxFlat overrides moved to _apply_styles(); CanvasLayer properties (layer, visible) in scene file; process_mode removed (default is INHERIT)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — Phase 2 remediation from M11 GDScript audit report (TICKET-0290)
- 2026-03-03 [gameplay-programmer] Starting work — refactoring recycler_panel, fabricator_panel, automation_hub_panel to scene-first pattern
- 2026-03-03 [gameplay-programmer] DONE — commit a0656c1, PR #328 merged to main. All 3 panels refactored to scene-first pattern with .tscn files and @onready vars.
