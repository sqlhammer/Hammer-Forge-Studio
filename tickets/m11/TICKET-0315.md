---
id: TICKET-0315
title: "BUG — Terrain features render as untextured grey boxes (missing material)"
type: BUG
status: OPEN
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

- [ ] All terrain feature geometry in Rock Warrens renders with correct material and shading
- [ ] Verify the same material assignment path is working correctly on Shattered Flats and Debris Field
- [ ] No grey untextured geometry visible in any biome
- [ ] Run full test suite — no regressions
- [ ] Commit and push

---

## Files Likely Involved

- `game/scripts/gameplay/terrain_generator.gd` — ArrayMesh construction and material assignment
- `game/scripts/gameplay/rock_warrens_biome.gd` — terrain feature definitions
- `game/scripts/gameplay/terrain_feature_request.gd` — feature request handling and mesh generation

---

## Activity Log

- 2026-03-07 [studio-head] Filed — untextured grey box geometry visible on Rock Warrens during M11 UAT playtesting. Screenshot: C:\temp\2026-03-07_07-41-46.png
