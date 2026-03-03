---
id: TICKET-0291
title: "M11 Scene-First remediation — Ship Machine Panels (recycler_panel, fabricator_panel, automation_hub_panel)"
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
tags: [standards, scene-first, remediation, ui]
---

## Summary

Refactor 3 machine panel scripts that construct their entire UI in `_ready()`/`_build_ui()` into proper .tscn scenes with `@onready` references.

---

## Acceptance Criteria

- [ ] `recycler_panel.gd`: create `recycler_panel.tscn` in the editor; move all persistent nodes (dim layer, main panel, slot row, progress section, button row) to scene; replace `_build_ui()` with `@onready` vars; remove LAYOUT_IN_READY violations (layer, process_mode, visible set in `_ready()`)
- [ ] `fabricator_panel.gd`: create `fabricator_panel.tscn`; move entire panel tree (dim layer, recipe list with per-recipe rows, detail column with labeled slots, progress section) to scene; fix 3 untyped Array vars at lines 508/614/692 (change to `Array[Dictionary]`); remove LAYOUT_IN_READY violations
- [ ] `automation_hub_panel.gd`: create `automation_hub_panel.tscn`; move entire panel tree (dim layer, center container, main panel, title, config/status columns, footer) to scene; remove LAYOUT_IN_READY violations
- [ ] All three scripts: replace programmatic node construction with `@onready var` references; verify game functions identically after refactor

---

## Implementation Notes

See audit report `docs/studio/reports/2026-03-03-m11-gdscript-audit.md` Section 2 rows for `recycler_panel.gd`, `fabricator_panel.gd`, `automation_hub_panel.gd`. Priority 1 in the remediation ordering (Section 5). These three files share the same `_build_ui()` anti-pattern and can use a shared refactoring approach.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — Phase 2 remediation from M11 GDScript audit report (TICKET-0290)
