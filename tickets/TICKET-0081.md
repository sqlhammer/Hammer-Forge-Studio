---
id: TICKET-0081
title: "Ship exterior — scale mesh to 3× current size"
type: TASK
status: OPEN
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

- [ ] Ship exterior mesh scaled to exactly 3× its current dimensions (uniform scale on all axes)
- [ ] Transform applied in Blender before export — no non-uniform scale remaining on the root object
- [ ] Mesh re-exported to `game/assets/meshes/vehicles/mesh_ship_exterior.glb` at the new size
- [ ] Ship node in the test world scene (`game/scenes/gameplay/`) updated to display at the new scale with no in-engine scale override (scale = `(1, 1, 1)`)
- [ ] Existing collision shape(s) on the ship updated to match the rescaled hull
- [ ] Player recharge zone (suit battery recharge trigger area) repositioned to remain at the ship's entrance at the new scale
- [ ] No z-fighting, mesh clipping, or visible seam artifacts introduced by the rescale
- [ ] No Godot import errors or warnings
- [ ] Scene saved and committed

## Implementation Notes

- Ship exterior mesh: `game/assets/meshes/vehicles/mesh_ship_exterior.glb`
- Test world scene: `game/scenes/gameplay/test_world.tscn` (or equivalent) — ship placement is managed here
- Apply scale in Blender (Object > Apply > Scale) before export — do not adjust scale in-engine
- The ship's recharge zone is a trigger area defined in the scene; its position and radius must be manually repositioned after rescale to remain snug with the new hull entrance
- The greybox ship interior (M4, TICKET-0043) is a separate scene — interior scene dimensions do not need to change unless interior now clips visibly outside the rescaled exterior hull; do a quick visual check but a full interior rescale is out of scope

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-25 [producer] Created ticket
