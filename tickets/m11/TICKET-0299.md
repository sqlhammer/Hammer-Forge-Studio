---
id: TICKET-0299
title: "M11 Scene-First remediation — Ship Status Display and Travel Fade Layer"
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
tags: [standards, scene-first, remediation, ship]
---

## Summary

Refactor `ship_status_display.gd` and `travel_sequence_manager.gd` to author their persistent nodes in the scene editor rather than in code.

---

## Acceptance Criteria

- [x] `ship_status_display.gd`: create `ship_status_display.tscn`; author the 3D status panel (MeshInstance3D frame, SubViewport with Panel+2 Labels+ProgressBar, screen mesh with ViewportTexture) in the scene editor; replace `_build_display()` construction with `@onready` vars
- [x] `travel_sequence_manager.gd`: move TravelFadeLayer CanvasLayer + ColorRect (lines 208–219) to the parent scene (`game_world.tscn` or `travel_sequence_manager.tscn`) as persistent children; remove CANVAS_LAYER_NEW violation; pass the fade layer reference via an exported var or `@onready`
- [x] Verify ship status display renders correctly on ship exterior; verify travel fade sequence works

---

## Implementation Notes

See audit report `docs/studio/reports/2026-03-03-m11-gdscript-audit.md` Section 2 rows for `ship_status_display.gd` (lines 48–159) and `travel_sequence_manager.gd` (lines 208–219). Priority 4 in Section 5.

---

## Handoff Notes

**ship_status_display.gd:** Removed `_build_display()`, `_build_frame()`, `_build_viewport_ui()`, `_build_screen_mesh()` methods. All persistent nodes (Frame MeshInstance3D, DisplayViewport SubViewport with Background Panel + NameLabel + ValueLabel + StatusBar ProgressBar, ScreenMesh MeshInstance3D with QuadMesh) now authored in `ship_status_display.tscn`. Script uses `@onready` vars. ViewportTexture wired in `_wire_viewport_texture()` at runtime (duplicates material per instance). Removed unused constants (DISPLAY_WIDTH/HEIGHT, VIEWPORT_WIDTH/HEIGHT, COLOR_PANEL_BG, COLOR_BAR_BG, COLOR_TEXT_SECONDARY, COLOR_FRAME).

**travel_sequence_manager.gd:** Created `travel_sequence_manager.tscn` with TravelFadeLayer (CanvasLayer, layer=10) and TravelFadeRect (ColorRect, black, full rect, alpha=0, mouse_filter=ignore) as persistent children. Removed `_build_fade_overlay()` method and its call from `setup()`. Replaced private var declarations with `@onready` vars. Updated `game_world.gd` to instantiate from scene instead of `.new()`.

**Existing tests:** `test_travel_sequence_unit.gd` uses `TravelSequenceManager.new()` directly (not from scene). The @onready vars remain null when not in tree, and fade methods already guard on null `_fade_rect` and `is_inside_tree()`, so tests are unaffected.

---

## Activity Log

- 2026-03-03 [producer] Created ticket — Phase 2 remediation from M11 GDScript audit report (TICKET-0290)
- 2026-03-03 [gameplay-programmer] Starting work
- 2026-03-03 [gameplay-programmer] Implementation complete. Commit 0ef94e9, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/341 (merged). Marked DONE.
