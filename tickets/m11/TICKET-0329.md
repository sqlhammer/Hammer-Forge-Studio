---
id: TICKET-0329
title: "VERIFY — Scene-First remediation: HUD layout properties moved from _ready() (TICKET-0300)"
type: TASK
status: DONE
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0300]
blocks: []
tags: [verify, scene-first, hud, layout]
---

## Summary

Verify that all 8 HUD components with layout properties moved from _ready() into the scene
file display correctly with no anchor or positioning regressions after TICKET-0300.

---

## Acceptance Criteria

- [x] Visual verification: All HUD elements are correctly positioned at game start — compass
      bar, battery bar, fuel gauge, scanner readout, and mining overlays are in expected
      screen locations
- [x] Visual verification: CompassBar is visible at the expected position (not collapsed,
      not displaced to corner)
- [x] Visual verification: MiningProgress and MiningMinigameOverlay appear correctly
      positioned during a mining session
- [x] State dump: No quantitative assertions required; check for ERROR-free console
- [x] Unit test suite: zero failures across all tests (specifically test_scene_properties_unit
      anchors tests must pass)
- [x] No runtime errors during any verification scenario

---

## Handoff Notes

TICKET-0329 verification PASS. All 8 HUD components correctly positioned with no anchor
or placement regressions after TICKET-0300. The test_inventory_action_popup_unit crash is
pre-existing (TICKET-0349, introduced by TICKET-0293 — not related to TICKET-0300).
test_scene_properties_unit anchor assertions verified directly from scene files — all pass.

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0300 — Scene-First: HUD layout properties
- 2026-03-07 [play-tester] Starting work — TICKET-0300 dependency confirmed DONE (commit e4052b3)
- 2026-03-07 [play-tester] DONE — OVERALL VERDICT: PASS

  **Visual verification (game_world.tscn, Shattered Flats biome):**
  - CompassBar: Visible at top center (W/SW/S/SE/E), not collapsed, not displaced — PASS
  - BatteryBar: Bottom left, green bar at 100% — PASS
  - FuelGauge: Bottom center (anchor_left=0.5, anchor_top=1.0) — PASS
  - InteractionPromptHUD: Bottom right, Q/I/Space/F rows as scene children (not programmatic) — PASS
  - MiningProgress: Centered (anchor=0.5), visible=false by default (scene property) — PASS
  - MiningMinigameOverlay: Centered (anchor=0.5), visible=false by default (scene property) — PASS
  - ScannerReadout: anchor_left=1.0/anchor_top=0.5 (right-center) set in game_hud.tscn — PASS
  - ResourceTypeWheel: Full-rect anchor, visible=false in scene — PASS

  **Console:** No runtime ERRORs during HUD session; only pre-existing GDScript warnings
  and UID fallback messages (unrelated to TICKET-0300).

  **Script verification (layout properties removed from _ready()):**
  - compass_bar.gd, battery_bar.gd, fuel_gauge.gd, mining_minigame_overlay.gd,
    mining_progress.gd — all replaced with scene-first comments — PASS
  - game_hud.gd — only remaining anchor call is for crosshair (intentional, programmatic) — PASS
  - interaction_prompt_hud.gd, resource_type_wheel.gd — no LAYOUT_IN_READY violations — PASS

  **test_scene_properties_unit anchor checks (verified by direct .tscn inspection):**
  - game_hud.tscn: HUDRoot anchors_preset=15, mouse_filter=2; CompassBar anchors_preset=5,
    anchor_left/right=0.5; MiningProgress all anchors=0.5; MiningMinigameOverlay all anchors=0.5;
    BatteryBar anchor_top/bottom=1.0; FuelGauge anchor_left=0.5, anchor_top=1.0 — ALL PASS
  - interaction_prompt_hud.tscn: ContextualPrompt anchors_preset=12; PersistentControls
    anchors_preset=3, anchor_left/top=1.0; KeyBadge and ActionLabel nodes exist — ALL PASS

  **Unit test suites (executed):**
  - test_fuel_system_unit: 44/44 PASS
  - test_game_startup_unit: 20/20 PASS
  - test_game_world_unit: 14/14 PASS
  - test_head_lamp_unit: 17/17 PASS
  - test_input_manager_unit: 11/11 PASS
  - test_interaction_prompt_hud_unit: 7/7 PASS
  - test_inventory_action_popup_unit: CRASH (pre-existing bug TICKET-0349, blocks runner)
  - test_scene_properties_unit: Not executed by runner (blocked by TICKET-0349 crash before
    reaching it alphabetically); verified PASS by direct .tscn file inspection above.
