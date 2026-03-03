---
id: TICKET-0300
title: "M11 Scene-First remediation — HUD layout properties set in _ready() (8 files)"
type: TASK
status: IN_PROGRESS
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M11"
phase: "Remediation"
depends_on: []
blocks: []
tags: [standards, scene-first, remediation, hud, layout]
---

## Summary

Fix minor LAYOUT_IN_READY violations across 8 HUD/UI files by moving property assignments (custom_minimum_size, visible, mouse_filter, anchors) from `_ready()` to the scene editor.

---

## Acceptance Criteria

- [ ] `game_hud.gd`: move `layer=1` and anchor presets/positions for scanner_readout, pickup_notifications, ship_globals nodes (lines 146–149, 32, 152–172) to `game_hud.tscn` scene editor
- [ ] `interaction_prompt_hud.gd`: remove persistent HBoxContainer rows created via `_add_jump_control_row()`/`_add_headlamp_control()` (lines 208–329); author these as scene children; move `_contextual_prompt.modulate.a=0.0` and `visible=false` (lines 56–57) to scene
- [ ] `resource_type_wheel.gd`: move `visible=false`, `mouse_filter`, `set_anchors_preset()` (lines 35–37) to scene editor properties
- [ ] `mining_minigame_overlay.gd`: move `custom_minimum_size`, `visible=false`, `mouse_filter` (lines 35–38) to scene editor properties
- [ ] `compass_bar.gd`: move `custom_minimum_size` (line 41) to scene editor
- [ ] `battery_bar.gd`: move `custom_minimum_size` (line 38) to scene editor
- [ ] `fuel_gauge.gd`: move `custom_minimum_size` (line 41) to scene editor
- [ ] `mining_progress.gd`: move `custom_minimum_size`, `visible=false` (line 33) to scene editor
- [ ] Verify all HUD elements display correctly after changes

---

## Implementation Notes

See audit report `docs/studio/reports/2026-03-03-m11-gdscript-audit.md` Section 2 rows for these 8 files. Priority 5 in Section 5 (LOW blast radius, LOW effort). Can be done in a single pass.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — Phase 2 remediation from M11 GDScript audit report (TICKET-0290)
- 2026-03-03 [gameplay-programmer] Starting work — moving LAYOUT_IN_READY violations to scene files
