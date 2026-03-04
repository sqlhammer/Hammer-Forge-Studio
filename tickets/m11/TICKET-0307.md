---
id: TICKET-0307
title: "BUG — HUD CompassBar/MiningProgress/MiningMinigameOverlay anchor presets reset to 0 after TICKET-0300"
type: BUG
status: OPEN
priority: P2
owner: gameplay-programmer
assigned_to: gameplay-programmer
created_by: qa-engineer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M11"
phase: "QA"
depends_on: []
blocks: [TICKET-0304]
tags: [hud, layout, anchors, regression, m11, scene-properties]
---

## Summary

After TICKET-0300 (M11 HUD layout properties set in `_ready()` remediation), three HUD nodes
in `game_hud.tscn` have `anchors_preset = 0` (PRESET_TOP_LEFT) instead of their required
values: CompassBar needs preset 5 (PRESET_CENTER_TOP) and both MiningProgress and
MiningMinigameOverlay need preset 8 (PRESET_CENTER). At runtime, these UI elements render
in the top-left corner instead of their intended positions.

---

## Severity

**P2 — Defect in expected behavior, workaround exists**: HUD elements are visible but
mispositioned. Player can still play; HUD functional but layout broken.

---

## Regression Source

**TICKET-0300** was scoped to remove `LAYOUT_IN_READY` violations — anchor and size
properties set in `_ready()` should instead be authored in the scene editor. TICKET-0300
appears to have removed the `_ready()` anchor-setting code from these components but did
not update the `.tscn` file to preserve the correct anchor values.

---

## Reproduction Steps

1. Launch the game (any scene using GameHUD)
2. Observe CompassBar, MiningProgress bar, and MiningMinigame overlay positions
3. Expected: CompassBar at top-center of screen; MiningProgress and MiningMinigameOverlay
   centered in screen
4. Actual: All three rendered in top-left corner (0,0 anchor position)

Alternatively, run `test_scene_properties_unit` — three assertions fail:
- `game_hud_compass_bar_anchors_preset` FAIL: Expected '5' but got '0'
- `game_hud_mining_progress_anchors_preset` FAIL: Expected '8' but got '0'
- `game_hud_mining_minigame_overlay_anchors_preset` FAIL: Expected '8' but got '0'

---

## Expected Behavior

In `game_hud.tscn` (or equivalent HUD scene file), the following nodes have these anchors:
- `HUDRoot/CompassBar`: `anchors_preset = 5` (PRESET_CENTER_TOP)
- `HUDRoot/MiningProgress`: `anchors_preset = 8` (PRESET_CENTER)
- `HUDRoot/MiningMinigameOverlay`: `anchors_preset = 8` (PRESET_CENTER)

## Actual Behavior

All three nodes have `anchors_preset = 0` in the scene file. HUD elements render in top-left.

---

## Evidence

Test output from M11 Phase Gate QA run (2026-03-03):
```
[208832]   FAIL: game_hud_compass_bar_anchors_preset -- HUDRoot/CompassBar.anchors_preset: Expected '5' but got '0'
[208833]   FAIL: game_hud_mining_progress_anchors_preset -- HUDRoot/MiningProgress.anchors_preset: Expected '8' but got '0'
[208835]   FAIL: game_hud_mining_minigame_overlay_anchors_preset -- HUDRoot/MiningMinigameOverlay.anchors_preset: Expected '8' but got '0'
```

---

## Files Involved

- `game/scripts/ui/hud/game_hud.gd` — verify anchor-setting code removed
- `game/scenes/ui/hud/game_hud.tscn` (or equivalent) — needs anchor preset values set

---

## Activity Log

- 2026-03-03 [qa-engineer] Filed — P2 regression from TICKET-0300; HUD layout broken for 3 nodes. Blocks TICKET-0304 Phase Gate QA sign-off.
- 2026-03-03 [gameplay-programmer] Starting work — root cause: redundant individual anchor_* overrides in game_hud.tscn reset anchors_preset to 0 at runtime
- 2026-03-03 [gameplay-programmer] DONE — commit b552175, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/346 (merged). Removed redundant anchor/grow overrides from 3 instanced nodes.
- 2026-03-04 [qa-engineer] RE-TEST FAILED — Ran full test suite (test_report_2026-03-04 15-30-46.json; 1000 tests, 997 passed, 3 failed). All three HUD anchor preset tests still fail with same assertion errors: game_hud_compass_bar_anchors_preset Expected '5' got '0'; game_hud_mining_progress_anchors_preset Expected '8' got '0'; game_hud_mining_minigame_overlay_anchors_preset Expected '8' got '0'. Root cause analysis: game_hud.tscn instance override now correctly has anchors_preset without redundant anchor_* entries, but the BASE scenes (compass_bar.tscn, mining_progress.tscn, mining_minigame_overlay.tscn) each still have explicit anchor_left/anchor_right/etc. properties stored after anchors_preset. When Godot instantiates these scenes, the explicit anchor_* properties reset stored_layout_preset. The fix must be applied to the BASE scene .tscn files to remove redundant anchor_* properties, or game_hud.tscn must use explicit anchor_left/right/top/bottom overrides instead of anchors_preset. Reopening and reassigning to gameplay-programmer. Blocks TICKET-0304 phase gate.
