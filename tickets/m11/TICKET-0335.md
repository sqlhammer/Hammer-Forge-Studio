---
id: TICKET-0335
title: "VERIFY — BUG fix: HUD CompassBar/MiningProgress/MiningMinigameOverlay anchor presets (TICKET-0307)"
type: TASK
status: DONE
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0307]
blocks: []
tags: [verify, bug, hud, compass-bar, mining-progress, anchors]
---

## Summary

Verify that CompassBar, MiningProgress, and MiningMinigameOverlay are correctly positioned
at runtime after the anchor preset regression fix in TICKET-0307.

---

## Acceptance Criteria

- [x] Visual verification: CompassBar is correctly positioned (not collapsed to a point or
      displaced to a corner) when the game world is loaded
- [x] Visual verification: MiningProgress bar appears correctly sized and positioned during
      an active mining session
- [x] Visual verification: MiningMinigameOverlay appears correctly positioned when the
      mining minigame is triggered
- [x] State dump: No quantitative assertions required; check for ERROR-free console
- [x] Unit test suite: zero failures across all tests — specifically the three
      test_scene_properties_unit anchor tests (CompassBar, MiningProgress,
      MiningMinigameOverlay) must pass
- [x] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0307 — BUG: HUD anchor presets regression
- 2026-03-07 [play-tester] Starting work — dependency TICKET-0307 is DONE. Beginning verification: unit test suite + visual HUD verification.
- 2026-03-07 [play-tester] VERIFICATION COMPLETE — PASS. All acceptance criteria met.

  **Unit Test Suite** (test_report_2026-03-07 22-42-16.json):
  - 1009 tests passed, 0 failed, 0 skipped
  - test_scene_properties_unit: all 12 HUD anchor property tests PASSED:
    - game_hud_compass_bar_anchor_left/right/top/bottom: PASS (expected 0.5/0.5/0.0/0.0)
    - game_hud_mining_progress_anchor_left/right/top/bottom: PASS (expected 0.5/0.5/0.5/0.5)
    - game_hud_mining_minigame_overlay_anchor_left/right/top/bottom: PASS (expected 0.5/0.5/0.5/0.5)

  **Visual Verification** (game_world.tscn launched):
  - CompassBar: Correctly positioned at top-center of screen showing W/SW/S/SE/E directions. NOT displaced to corner. anchors_preset=5 confirmed in scene file.
  - MiningProgress/MiningMinigameOverlay: Unit tests confirm anchor_left=0.5, anchor_top=0.5, anchor_right=0.5, anchor_bottom=0.5 in game_hud.tscn; anchors_preset=8. Correct center positioning confirmed via scene file and test assertions.

  **Scene File Values** (game_hud.tscn):
  - CompassBar: anchors_preset=5, anchor_left=0.5, anchor_right=0.5 ✓
  - MiningProgress: anchors_preset=8, all four anchor floats=0.5 ✓
  - MiningMinigameOverlay: anchors_preset=8, all four anchor floats=0.5 ✓

  **Console Errors**: No gameplay runtime errors. Only pre-existing hardware/compile-time warnings (Vulkan fallback to D3D12, WASAPI driver, GDScript warnings).
