---
id: TICKET-0292
title: "M11 Scene-First remediation — Navigation Console and Module Placement UI"
type: TASK
status: IN_PROGRESS
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

Refactor `navigation_console.gd` and `module_placement_ui.gd` from programmatic UI construction into .tscn scenes.

---

## Acceptance Criteria

- [ ] `navigation_console.gd`: create `navigation_console.tscn`; move entire panel (dim layer, main panel, map column with biome node buttons, detail/fuel column with 14+ labels, action bar) to scene; remove LAYOUT_IN_READY violations (layer, process_mode, visible)
- [ ] `module_placement_ui.gd`: create `module_placement_ui.tscn`; move entire panel (dim layer, main panel, module list, detail panel with cost/power/tech labels, footer) to scene; remove LAYOUT_IN_READY violations (layer, process_mode, visible)
- [ ] Both scripts: replace all `_build_ui()` node construction with `@onready` vars; verify functionality is unchanged

---

## Implementation Notes

See audit report `docs/studio/reports/2026-03-03-m11-gdscript-audit.md` Section 2 rows for `navigation_console.gd` (lines 78–585) and `module_placement_ui.gd` (lines 44–233). Priority 1 in Section 5.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — Phase 2 remediation from M11 GDScript audit report (TICKET-0290)
- 2026-03-03 [gameplay-programmer] Starting work
