---
id: TICKET-0220
title: "Feature — Debug launcher toggle for 3× player movement speed"
type: FEATURE
status: DONE
priority: P3
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-03-01
milestone: "M9"
phase: "Gameplay Polish"
depends_on: [TICKET-0233]
blocks: []
tags: [feature, debug, debug-launcher, player, movement, m9]
---

## Summary

Navigating large biomes (500m×500m) during playtesting is time-consuming at normal movement speed. Add a toggle to the debug launcher that enables 3× player movement speed for rapid exploration during development and QA.

## Acceptance Criteria

- [x] The debug launcher UI has a clearly labeled toggle (e.g., "Fast Move (3×)") that enables/disables the speed multiplier
- [x] When enabled, the player's walk and run speeds are multiplied by 3× from the moment the biome loads
- [x] The speed multiplier is applied via a clean multiplier on the existing movement speed constants — no copy-paste of movement logic
- [x] The toggle state persists across debug launches within the same session (saves to the same config mechanism as other debug toggles)
- [x] The multiplier is stripped out in production builds or is clearly gated behind `OS.is_debug_build()` — it must not affect normal gameplay
- [x] Full test suite passes with no new failures

## Implementation Notes

- `debug_launcher.gd` already has the begin-wealthy toggle (TICKET-0180) — follow the same pattern for this new toggle
- Apply the multiplier in `PlayerFirstPerson` by exposing a `debug_speed_multiplier` property (default 1.0); `DebugLauncher` sets it to 3.0 if the toggle is on before calling the biome launch
- Gate the property assignment behind `if OS.is_debug_build()` to ensure it is a no-op in release

## Activity Log

- 2026-02-28 [producer] Created — deferred from M8; Studio Head requested during M8 playtest
- 2026-03-01 [gameplay-programmer] Starting work — dependency TICKET-0233 is DONE
- 2026-03-01 [gameplay-programmer] DONE — Added Fast Move (3×) toggle to DebugLauncher. Global.debug_speed_multiplier stores state, GameWorld applies to PlayerFirstPerson.debug_speed_multiplier gated behind OS.is_debug_build(). Commit: 984929d, PR: #260
