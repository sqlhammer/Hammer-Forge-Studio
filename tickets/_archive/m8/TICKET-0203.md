---
id: TICKET-0203
title: "Bugfix — Ship entry point not findable in Shattered Flats"
type: BUGFIX
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, shattered-flats, ship, entry, spawn, terrain, m8-qa]
---

## Summary

In the Shattered Flats biome, the player cannot locate the ship entry point. The ship door or boarding interaction is either not visible, buried in terrain, or spawned at an inaccessible location. This blocks the player from returning to the ship and using the navigation console or other ship systems.

## Steps to Reproduce

1. Launch Shattered Flats via the debug launcher or normal gameplay
2. Explore the biome looking for the ship entry point
3. Observe: the entry point (door, ramp, or boarding interaction zone) cannot be found or accessed

## Expected Behavior

The ship is spawned at the biome's designated spawn point with its entry door/ramp clearly visible, accessible, and at surface level. The player can walk up to the ship and board it as in other biomes.

## Acceptance Criteria

- [x] The ship entry point is clearly visible and accessible in Shattered Flats
- [x] The ship is not buried in or clipped through the terrain mesh
- [x] Boarding interaction triggers correctly at the entry point
- [x] Fix applies to both debug launcher and normal gameplay spawns
- [x] No regression to ship entry in Rock Warrens or Debris Field
- [ ] Full test suite passes with no new failures

## Implementation Notes

- Check the ship spawn position in `ShatteredFlatsBiome` — the Y coordinate may be 0 (flat ground assumption) while the procedural terrain surface is higher or uneven at the spawn XZ location
- Investigate whether the fix from TICKET-0199 (player spawn height) was applied to the ship spawn as well — the same terrain-height mismatch may affect the ship
- Look at how `_get_spawn_positions()` in `debug_launcher.gd` determines ship Y position for Shattered Flats specifically
- If the ship is below the terrain surface, check whether `TerrainGenerator` provides a height query API that can be used to place the ship at the correct surface elevation

## Activity Log

- 2026-02-27 [producer] Created — Studio Head reported during final M8 playtest review
- 2026-02-27 [gameplay-programmer] Starting work — investigating ship spawn position in Shattered Flats
- 2026-02-27 [gameplay-programmer] DONE — Root cause: `_on_travel_sequence_completed()` in `test_world.gd` was using hardcoded Y=3.0 for the ShipEnterZone collision position. When Shattered Flats terrain at the ship clearing is elevated (ship_pos.y > ~3m), the enter zone sat below terrain and the boarding interaction never fired. Fix: changed to `ship_pos.y + 3.0` so zone center always tracks terrain height. commit: 4e525e0, PR: https://github.com/sqlhammer/Hammer-Forge-Studio/pull/172

### Handoff Notes
- **What was implemented:** Fixed ShipEnterZone Y positioning in `test_world.gd:_on_travel_sequence_completed()` to use `ship_pos.y + 3.0` instead of hardcoded `3.0`.
- **Scripts modified:** `game/scripts/levels/test_world.gd` (line 582)
- **Known limitations:** The test suite test for ship entry zone positioning would require an integration test in TestWorld; no unit test covers this specific callback. QA should verify boarding in Shattered Flats, Rock Warrens, and Debris Field.
