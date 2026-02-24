---
id: TICKET-0081
title: "Ship exterior — scale mesh to 3× current size"
type: TASK
status: DONE
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M5"
milestone_gate: "M4"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0082]
tags: [technical-art, ship-exterior, scale, 3d-asset]
---

## Summary

The ship exterior mesh is currently too small relative to the player and game world. Scale it to 3× its current dimensions so it reads as a credible vessel that a player character could plausibly live and work inside. This is a geometry change — apply the scale in Blender with transforms applied, then update all in-engine placements and collision nodes accordingly.

## Acceptance Criteria

- [x] Ship exterior mesh scaled to exactly 3× its current dimensions (uniform scale on all axes)
- [x] Transform applied in Blender before export — no non-uniform scale remaining on the root object
- [x] Mesh re-exported to `game/assets/meshes/vehicles/mesh_ship_exterior.glb` at the new size
- [x] Ship node in the test world scene (`game/scenes/gameplay/`) updated to display at the new scale with no in-engine scale override (scale = `(1, 1, 1)`)
- [x] Existing collision shape(s) on the ship updated to match the rescaled hull
- [x] Player recharge zone (suit battery recharge trigger area) repositioned to remain at the ship's entrance at the new scale
- [x] No z-fighting, mesh clipping, or visible seam artifacts introduced by the rescale
- [x] No Godot import errors or warnings
- [x] Scene saved and committed

## Implementation Notes

- Ship exterior mesh: `game/assets/meshes/vehicles/mesh_ship_exterior.glb`
- Test world scene: `game/scenes/gameplay/test_world.tscn` (or equivalent) — ship placement is managed here
- Apply scale in Blender (Object > Apply > Scale) before export — do not adjust scale in-engine
- The ship's recharge zone is a trigger area defined in the scene; its position and radius must be manually repositioned after rescale to remain snug with the new hull entrance
- The greybox ship interior (M4, TICKET-0043) is a separate scene — interior scene dimensions do not need to change unless interior now clips visibly outside the rescaled exterior hull; do a quick visual check but a full interior rescale is out of scope

## Handoff Notes

- Ship exterior mesh re-exported at 3× native scale (~45m long, ~24m wide, ~15m tall)
- Blender build script: 3× uniform scale applied post-build via `obj.scale *= 3` + `transform_apply(scale=True)`
- GLB file: `game/assets/meshes/vehicles/mesh_ship_exterior.glb` (88 KB, same tri count)
- In-engine scale override removed — mesh displays at (1,1,1)
- Collision box: `Vector3(21.0, 12.0, 42.0)` matching 3× hull envelope
- Recharge zone: `Vector3(24.0, 15.0, 30.0)` repositioned at ship entrance
- Ship enter zone: `Vector3(9.0, 6.0, 6.0)` at position `(0, 3.0, 13.5)`
- Player spawn and exterior exit positions scaled to match new hull
- Ship interior at `INTERIOR_Y_OFFSET = -50.0` — no clipping with rescaled exterior

## Activity Log

- 2026-02-25 [producer] Created ticket
- 2026-02-25 [technical-artist] Implemented: mesh scaled 3× in Blender pipeline, GLB re-exported, test_world.gd updated with matching collision/zone shapes, in-engine scale override removed. Status → DONE.
