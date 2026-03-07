---
id: TICKET-0318
title: "BUG — Player spawns below terrain on biome load (regression)"
type: BUG
status: DONE
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

- [x] Identify whether this is a regression of the TICKET-0313 fix or a new code path
- [x] Player consistently spawns on the terrain surface, upright, on all three biomes
- [x] No runtime errors on biome load
- [x] No regression on ship Y-offset fix (TICKET-0314) or ship tilt fix (TICKET-0317)
- [x] Run full test suite — no regressions
- [x] Commit and push

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
- 2026-03-07 [gameplay-programmer] DONE — commit 9baa41b, PR #376 merged. Root cause identified: NOT a regression of TICKET-0313 backface_collision fix (still correctly set to true on all ConcavePolygonShape3D instances). This is a latent timing bug in _add_player()/call_deferred flow. The player is added to the scene tree at origin (0,0,0) with physics processing active. Before the deferred _position_entities_and_setup() runs, at least one _physics_process frame executes on the FirstPersonController — gravity + move_and_slide pushes the CharacterBody3D downward in local space. When the parent Node3D is later repositioned to the correct spawn point, the CharacterBody3D retains its local position offset, placing it below the terrain surface. Since ConcavePolygonShape3D has zero thickness, once below, the player falls away from the surface. Fix: (1) Set player.process_mode = PROCESS_MODE_DISABLED in _add_player() before add_child — prevents any _physics_process from running at origin. (2) In _position_entities_and_setup(), reset FirstPersonController.position to Vector3.ZERO and velocity to Vector3.ZERO as belt-and-suspenders, then re-enable processing via PROCESS_MODE_INHERIT. Ship positioning (TICKET-0314 Y-offset, TICKET-0317 basis reset) is unchanged. Biome spawn position logic and terrain_generator backface_collision are verified intact across all three biomes.
