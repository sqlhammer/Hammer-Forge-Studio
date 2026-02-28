---
id: TICKET-0216
title: "Bugfix — Player energy bar is no longer visible"
type: BUGFIX
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, battery-bar, hud, ui, suit-battery, m8-qa]
---

## Summary

The player's suit energy (battery) bar is no longer visible on the HUD in biomes. The bar was previously always-visible in TestWorld. The game HUD is present but the BatteryBar control is not rendering.

## Steps to Reproduce

1. Launch any biome via the debug launcher or normal travel
2. Observe the HUD — the energy/battery bar is absent

## Expected Behavior

The player's suit energy bar is always visible in the HUD, consistent with TestWorld behavior.

## Acceptance Criteria

- [x] The BatteryBar is visible on-screen in all biomes from the moment the scene loads
- [x] The bar updates correctly as the suit battery drains and recharges
- [x] Fix does not regress HUD layout or other HUD elements (compass, interaction prompt, fuel gauge)
- [x] Full test suite passes with no new failures

## Implementation Notes

- `BatteryBar` is defined in `game/scripts/ui/battery_bar.gd` and is part of `GameHUD`; check that the biome gameplay scene instantiates and initializes `GameHUD` the same way TestWorld does
- Check visibility flags on the BatteryBar control node and its parent containers — a layout change or scene refactor may have set `visible = false` or moved the node outside the viewport rect
- Check whether `GameHUD.setup()` is called with valid camera/player references in the biome context; a missing setup call would leave the bar uninitialized but not necessarily hidden, so check both visibility and setup
- Compare the biome scene's HUD wiring against `TestWorld` to identify the divergence

## Activity Log

- 2026-02-28 [producer] Created — Studio Head reported during M8 playtest
- 2026-02-28 [gameplay-programmer] Starting work — root cause identified: set_anchors_preset() + position= anti-pattern (same as TICKET-0152) leaves offset_right stale at 0, giving BatteryBar a negative width (-32px), suppressing rendering
- 2026-02-28 [gameplay-programmer] DONE — commit 9a0e3db, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/188 (merged). Moved BatteryBar and FuelGauge anchor/offsets from GDScript to game_hud.tscn
