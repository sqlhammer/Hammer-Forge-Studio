---
id: TICKET-0203
title: "Bugfix — Ship entry point not findable in Shattered Flats"
type: BUGFIX
status: IN_PROGRESS
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

- [ ] The ship entry point is clearly visible and accessible in Shattered Flats
- [ ] The ship is not buried in or clipped through the terrain mesh
- [ ] Boarding interaction triggers correctly at the entry point
- [ ] Fix applies to both debug launcher and normal gameplay spawns
- [ ] No regression to ship entry in Rock Warrens or Debris Field
- [ ] Full test suite passes with no new failures

## Implementation Notes

- Check the ship spawn position in `ShatteredFlatsBiome` — the Y coordinate may be 0 (flat ground assumption) while the procedural terrain surface is higher or uneven at the spawn XZ location
- Investigate whether the fix from TICKET-0199 (player spawn height) was applied to the ship spawn as well — the same terrain-height mismatch may affect the ship
- Look at how `_get_spawn_positions()` in `debug_launcher.gd` determines ship Y position for Shattered Flats specifically
- If the ship is below the terrain surface, check whether `TerrainGenerator` provides a height query API that can be used to place the ship at the correct surface elevation

## Activity Log

- 2026-02-27 [producer] Created — Studio Head reported during final M8 playtest review
- 2026-02-27 [gameplay-programmer] Starting work — investigating ship spawn position in Shattered Flats
