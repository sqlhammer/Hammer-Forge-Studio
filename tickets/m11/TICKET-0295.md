---
id: TICKET-0295
title: "M11 Scene-First remediation — Tech Tree Panel"
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
tags: [standards, scene-first, remediation, ui, tech-tree]
---

## Summary

Refactor `tech_tree_panel.gd` from programmatic UI construction into a .tscn scene.

---

## Acceptance Criteria

- [ ] `tech_tree_panel.gd`: create `tech_tree_panel.tscn`; move entire panel (dim layer, main panel, node cards with icons, Line2D connectors, detail panel, confirm dialog with overlay) to scene; remove LAYOUT_IN_READY violations (layer, process_mode, visible at lines 66–68)
- [ ] Replace all `_build_ui()` node construction with `@onready` vars
- [ ] Verify tech tree opens, displays nodes/connectors, and research unlock flow works correctly

---

## Implementation Notes

See audit report `docs/studio/reports/2026-03-03-m11-gdscript-audit.md` Section 2 row for `tech_tree_panel.gd` (lines 65–449, 66–68). Priority 1 in Section 5.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — Phase 2 remediation from M11 GDScript audit report (TICKET-0290)
