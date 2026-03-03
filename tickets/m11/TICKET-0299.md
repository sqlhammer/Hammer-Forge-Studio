---
id: TICKET-0299
title: "M11 Scene-First remediation — Ship Status Display and Travel Fade Layer"
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
tags: [standards, scene-first, remediation, ship]
---

## Summary

Refactor `ship_status_display.gd` and `travel_sequence_manager.gd` to author their persistent nodes in the scene editor rather than in code.

---

## Acceptance Criteria

- [ ] `ship_status_display.gd`: create `ship_status_display.tscn`; author the 3D status panel (MeshInstance3D frame, SubViewport with Panel+2 Labels+ProgressBar, screen mesh with ViewportTexture) in the scene editor; replace `_build_display()` construction with `@onready` vars
- [ ] `travel_sequence_manager.gd`: move TravelFadeLayer CanvasLayer + ColorRect (lines 208–219) to the parent scene (`game_world.tscn` or `travel_sequence_manager.tscn`) as persistent children; remove CANVAS_LAYER_NEW violation; pass the fade layer reference via an exported var or `@onready`
- [ ] Verify ship status display renders correctly on ship exterior; verify travel fade sequence works

---

## Implementation Notes

See audit report `docs/studio/reports/2026-03-03-m11-gdscript-audit.md` Section 2 rows for `ship_status_display.gd` (lines 48–159) and `travel_sequence_manager.gd` (lines 208–219). Priority 4 in Section 5.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — Phase 2 remediation from M11 GDScript audit report (TICKET-0290)
