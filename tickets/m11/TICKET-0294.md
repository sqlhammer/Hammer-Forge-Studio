---
id: TICKET-0294
title: "M11 Scene-First remediation — HUD Readout components (scanner_readout, ship_globals_hud, ship_stats_sidebar)"
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
tags: [standards, scene-first, remediation, hud]
---

## Summary

Refactor 3 HUD readout scripts that programmatically construct their display nodes into .tscn scenes with `@onready` references.

---

## Acceptance Criteria

- [ ] `scanner_readout.gd`: create `scanner_readout.tscn`; move entire readout (VBoxContainer, icon TextureRect, multiple Labels, HSeparator, 5 star TextureRects, panel style override) to scene; remove LAYOUT_IN_READY violations (visible, custom_minimum_size at lines 42–43)
- [ ] `ship_globals_hud.gd`: create `ship_globals_hud.tscn`; move entire panel (PanelContainer, title Label, HSeparator, 4 variable rows each HBoxContainer+TextureRect+ProgressBar+Label) to scene; remove LAYOUT_IN_READY violations (mouse_filter, position.x, visible, modulate.a at lines 56–62)
- [ ] `ship_stats_sidebar.gd`: create `ship_stats_sidebar.tscn`; move entire sidebar (PanelContainer, title, HSeparator, 4 variable rows, alerts section) to scene
- [ ] All three: replace `_build_ui()`/`_build_display()` node construction with `@onready` vars; verify HUD displays correctly in-game

---

## Implementation Notes

See audit report `docs/studio/reports/2026-03-03-m11-gdscript-audit.md` Section 2 rows for `scanner_readout.gd` (lines 86–184, 42–43), `ship_globals_hud.gd` (lines 93–139, 56–62), `ship_stats_sidebar.gd` (lines 60–131). Priority 1 in Section 5.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — Phase 2 remediation from M11 GDScript audit report (TICKET-0290)
