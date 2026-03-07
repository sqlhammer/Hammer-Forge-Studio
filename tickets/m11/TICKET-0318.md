---
id: TICKET-0318
title: "BUG — Player spawns below terrain on biome load (regression)"
type: BUG
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: studio-head
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0317]
blocks: []
tags: [player, spawn, terrain, biome-load, regression, m11]
---

## Summary

Player spawns below or inside the terrain mesh on biome load. The camera renders with terrain overhead and/or the player falls through the surface. Previously fixed in TICKET-0313 (backface_collision + spawn refactor); this is a regression or partial recurrence observed during continued UAT playtesting.

---

## Reproduction Steps

1. Launch the game (debug or release launcher)
2. Load any biome (Shattered Flats, Rock Warrens, or Debris Field)
3. Observe player spawn position and camera orientation on load

**Expected:** Player spawns upright on the terrain surface at the designated spawn point.

**Actual:** Player spawns below or inside the terrain; terrain mesh is visible overhead.

---

## Acceptance Criteria

- [ ] Identify whether this is a regression of the TICKET-0313 fix or a new code path
- [ ] Player consistently spawns on the terrain surface, upright, on all three biomes
- [ ] No runtime errors on biome load
- [ ] No regression on ship Y-offset fix (TICKET-0314) or ship tilt fix (TICKET-0317)
- [ ] Run full test suite — no regressions
- [ ] Commit and push

---

## Files Likely Involved

- `game/scripts/gameplay/game_world.gd` — player spawn logic on biome load
- `game/scripts/gameplay/terrain_generator.gd` — ConcavePolygonShape3D backface_collision setting
- `game/scripts/gameplay/shattered_flats_biome.gd`
- `game/scripts/gameplay/rock_warrens_biome.gd`
- `game/scripts/gameplay/debris_field_biome.gd`

---

## Activity Log

- 2026-03-07 [studio-head] Filed — player spawning below terrain observed during M11 UAT playtesting. Previously fixed in TICKET-0313; treating as regression. Investigate whether the backface_collision fix or spawn Vector3 refactor was inadvertently reverted or bypassed by subsequent changes.
