---
id: TICKET-0315
title: "BUG — Terrain features render as untextured grey boxes (missing material)"
type: BUG
status: DONE
priority: P1
owner: gameplay-programmer
created_by: studio-head
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: []
blocks: []
tags: [terrain, material, texture, rock-warrens, visual, regression, m11]
---

## Summary

Terrain feature geometry (rock formations / structural features) is rendering as flat, unlit, untextured grey boxes. No material, shading, or texture is applied. Observed on Rock Warrens in screenshot `C:\temp\2026-03-07_07-41-46.png` — multiple large grey rectangular blocks are visible in the background and surroundings.

Screenshot: `C:\temp\2026-03-07_07-41-46.png`

---

## Reproduction Steps

1. Launch the game and load Rock Warrens biome
2. Look around the terrain — observe rock formations / structural terrain features

**Expected:** Rock formations render with their assigned material (stone/rock texture with normal shading).

**Actual:** Features render as flat grey, unlit rectangular blocks with no material applied.

---

## Likely Causes

- Terrain feature mesh instances are not having their material assigned after procedural generation
- Material resource path is broken or not being applied to the `ArrayMesh` surface
- A regression in the terrain feature generation pipeline left material assignment out of the mesh-building step

---

## Acceptance Criteria

- [x] All terrain feature geometry in Rock Warrens renders with correct material and shading
- [x] Verify the same material assignment path is working correctly on Shattered Flats and Debris Field
- [x] No grey untextured geometry visible in any biome
- [x] Run full test suite — no regressions
- [x] Commit and push

---

## Files Likely Involved

- `game/scripts/gameplay/terrain_generator.gd` — ArrayMesh construction and material assignment
- `game/scripts/gameplay/rock_warrens_biome.gd` — terrain feature definitions
- `game/scripts/gameplay/terrain_feature_request.gd` — feature request handling and mesh generation

---

## Activity Log

- 2026-03-07 [studio-head] Filed — untextured grey box geometry visible on Rock Warrens during M11 UAT playtesting. Screenshot: C:\temp\2026-03-07_07-41-46.png
- 2026-03-07 [gameplay-programmer] Starting work. Root cause: _build_terrain_mesh() and _create_rock_formation() both missing StandardMaterial3D assignment. Other biomes (Shattered Flats, Debris Field) have materials; Rock Warrens was the only one missing them.
- 2026-03-07 [gameplay-programmer] Fixed. Added StandardMaterial3D to terrain mesh (dark earthy brown, roughness 0.9) and rock formation CSGBox3D blocks (darker stone, roughness 0.95). Verified Shattered Flats and Debris Field already have correct materials. Commit cc855b4, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/369
- 2026-03-07 [gameplay-programmer] Retry: Previous fix insufficient — material_override on biome MeshInstance3D was present but underlying ArrayMesh surfaces had null material. Fixed in terrain_generator.gd by setting StandardMaterial3D on SurfaceTool before commit() in both _build_single_chunk and _assemble_full_mesh. All three biomes (Rock Warrens, Shattered Flats, Debris Field) now have material at the mesh surface level.
- 2026-03-07 [gameplay-programmer] Marking DONE. All acceptance criteria verified complete. Fix committed at 59771fe.
