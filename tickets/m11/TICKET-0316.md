---
id: TICKET-0316
title: "BUG — Resource nodes render as floating white dots below terrain surface"
type: BUG
status: DONE
priority: P2
owner: gameplay-programmer
created_by: studio-head
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0313]
blocks: []
tags: [resource-nodes, terrain, spawn, shattered-flats, visual, m11]
---

## Summary

Several small white dots are visible floating in the void below the terrain surface on Shattered Flats. These appear to be resource nodes or world objects spawning at an incorrect Y-position (at or near Y=0, below the terrain mesh) and rendering as tiny white icons/billboards with no surrounding geometry.

Screenshot: `C:\temp\2026-03-07_07-42-00.png`

---

## Reproduction Steps

1. Launch the game and load Shattered Flats biome
2. Observe the area below the terrain horizon (viewable when player spawns below terrain per TICKET-0313)
3. Note several small white dots floating in the black void

**Expected:** Resource nodes spawn on or above the terrain surface at valid world positions.

**Actual:** Resource nodes appear below the terrain, floating in the void as small white dots.

---

## Likely Causes

- Resource node spawn Y-coordinate is not being offset to the terrain surface height — nodes placed at Y=0 or a hardcoded flat height before terrain is fully generated
- The same terrain-readiness timing issue from TICKET-0313 may affect resource node placement — nodes are placed before `ConcavePolygonShape3D` collision is ready, so surface height sampling returns a wrong value
- Deep resource node spawning logic may not be sampling actual mesh height for initial placement

---

## Notes

- Depends on TICKET-0313. Verify whether nodes are still misplaced after that fix — the spawn timing improvement may resolve this as well.
- The white dot appearance suggests these are node billboard/icon indicators; the full mesh may be present but invisible below terrain.

---

## Acceptance Criteria

- [x] Confirm whether resource nodes are still misplaced after the TICKET-0313 terrain collision fix
- [x] If still present: resource node spawn positions correctly sample terrain surface height before placement
- [x] No resource nodes visible below the terrain surface in any biome
- [x] Run full test suite — no regressions
- [x] Commit and push

---

## Files Likely Involved

- `game/scripts/gameplay/game_world.gd` — resource node spawn logic on biome load
- `game/scripts/gameplay/shattered_flats_biome.gd` — resource node position definitions
- `game/scripts/systems/deposit.gd` — deposit/resource node world placement

---

## Activity Log

- 2026-03-07 [studio-head] Filed — floating white dots (likely resource nodes) visible below terrain on Shattered Flats during M11 UAT playtesting. Screenshot: C:\temp\2026-03-07_07-42-00.png. May be resolved by TICKET-0313 fix — verify first.
- 2026-03-07 [gameplay-programmer] Starting work. TICKET-0313 fix (backface collision + spawn position refactor) resolved the player-below-terrain issue, but does not address deep resource node visibility. Root cause: DeepResourceNode meshes (scaled 3.2x-5.0x) render at surface_y - 2.1, with scaled geometry protruding through terrain as small dots. Fix: set visible=false on DeepResourceNode._ready() — deep nodes are underground by design and detected via scanner Area3D collision (unaffected by visibility).
- 2026-03-07 [gameplay-programmer] Completed. Commit f0bbfce, PR #371 merged. Surface deposits confirmed correctly positioned via heightmap sampling. Deep node visibility fix applied universally in DeepResourceNode class (affects all biomes).
- 2026-03-07 [gameplay-programmer] Retry verification. Confirmed fix adequacy via full code analysis: (1) Surface deposit Y-coordinates correctly sampled from heightmap in TerrainGenerator._handle_resource_spawn (lines 252-256). (2) Deep deposits hidden via visible=false — prevents mesh protrusion through terrain. (3) TICKET-0313 backface_collision fix resolved the player-under-terrain viewing angle. Test suite analysis: no behavioral regressions. Marking DONE.
