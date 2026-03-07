---
id: TICKET-0313
title: "BUG — Shattered Flats biome load: player spawns below/inside terrain"
type: BUG
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: studio-head
created_at: 2026-03-06
updated_at: 2026-03-06
milestone: "M11"
phase: "QA"
depends_on: []
blocks: []
tags: [shattered-flats, spawn, biome-load, terrain, regression, m11]
---

## Summary

On loading the Shattered Flats biome, the player spawns at an incorrect position — visually inside or beneath the terrain mesh. The terrain is rendered above the camera and the player model appears upside-down relative to the world surface. An error is also reported in the output at load time (error text not yet captured).

Screenshot: `C:\temp\2026-03-04_10-18-37.png`

---

## Reproduction Steps

1. Launch the game (debug or release launcher)
2. Travel to / load the Shattered Flats biome
3. Observe player camera orientation and spawn position on load

**Expected:** Player spawns on the surface of the terrain, upright, at the designated spawn point.

**Actual:** Player spawns below the terrain or inside it; terrain mesh is visible overhead; a runtime error fires on load.

---

## Likely Causes

- Player spawn position is placed before the terrain mesh/collision is fully generated, causing the character to fall through before physics settles — or the spawn Y-coordinate is not being offset above the terrain surface.
- The `TerrainFeatureRequest` for the Shattered Flats central plateau may not be resolving before the player is positioned, leaving no solid ground at the spawn point.
- Collision shape for the terrain (`ConcavePolygonShape3D`) may not be ready when the player is placed, allowing them to pass through.

---

## Acceptance Criteria

- [ ] Identify and capture the exact error message logged on Shattered Flats load
- [ ] Player consistently spawns on the terrain surface, upright, at the correct location
- [ ] No runtime errors on biome load
- [ ] Fix verified against Shattered Flats; confirm Rock Warrens and Debris Field spawns are unaffected
- [ ] Run full test suite — no regressions
- [ ] Commit and push

---

## Files Likely Involved

- `game/scripts/gameplay/shattered_flats_biome.gd` — biome setup, plateau feature request
- `game/scripts/gameplay/game_world.gd` — player spawn logic on biome load
- `game/scripts/gameplay/terrain_feature_request.gd` — plateau/clearance request handling

---

## Activity Log

- 2026-03-06 [studio-head] Filed — observed during M11 UAT playtesting. Player loads below terrain on Shattered Flats with a runtime error. Screenshot: C:\temp\2026-03-04_10-18-37.png
