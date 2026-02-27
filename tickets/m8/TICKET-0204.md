---
id: TICKET-0204
title: "Bugfix — Terrain feature blocks have no collision in Shattered Flats"
type: BUGFIX
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27T00:00:00
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, shattered-flats, terrain, collision, physics, plateau, m8-qa]
---

## Summary

The large raised terrain feature blocks (shattered flat plateaus) in the Shattered Flats biome have no collision. The player walks straight through them as if they are ghost geometry. The terrain mesh itself appears to have collision (player stands on the ground), but the protruding slab/plateau features do not.

Screenshot provided — dark rectangular slab features are clearly visible but have no physics presence.

## Steps to Reproduce

1. Launch Shattered Flats via the debug launcher (`res://game/scenes/debug/debug_launcher.tscn`)
2. Walk toward any raised slab or plateau feature
3. Observe: player walks through the feature without being blocked or standing on top of it

## Expected Behavior

Terrain feature blocks (plateaus, slabs) are solid — the player collides with their sides and can stand on their top surfaces.

## Acceptance Criteria

- [x] Player cannot walk through plateau/slab terrain features in Shattered Flats
- [x] Player can stand on top of slab surfaces
- [x] Collision shapes match the visual geometry of the features (no significant under/overhang)
- [x] Fix does not regress terrain collision for the base ground mesh
- [ ] Full test suite passes with no new failures

## Implementation Notes

- The Shattered Flats terrain generator uses `ArrayMesh` + `ConcavePolygonShape3D` for the base terrain. Check whether the plateau feature geometry is included in the same `StaticBody3D` / collision shape, or whether it is placed as a separate node with no `CollisionShape3D` attached.
- If plateau meshes are instantiated via `TerrainFeatureRequest` placement, verify the placement code adds a `CollisionShape3D` (or a `StaticBody3D` wrapper) to each spawned feature node — the visual mesh may be added without a physics body.
- The debug wireframe in the screenshot shows the base terrain mesh has a collision overlay (cyan lines) but the dark slab blocks have no corresponding wireframe, confirming the collision shape is entirely absent on those nodes.
- Look at the plateau feature scene or the code path that instantiates plateau `MeshInstance3D` nodes — a `StaticBody3D` with a matching `BoxShape3D` or `ConvexPolygonShape3D` needs to be added alongside each mesh.

## Activity Log

- 2026-02-27 [producer] Created — Studio Head reported during final M8 playtest review; screenshot confirms collision wireframe absent on slab features
- 2026-02-27 [gameplay-programmer] Starting work — investigating terrain feature collision in Shattered Flats procedural terrain system
- 2026-02-27 [gameplay-programmer] DONE — Root cause: _add_rubble_piece() created visual MeshInstance3D nodes with no StaticBody3D collision; SpireTip also lacked collision. Fixed by adding _add_static_collision() call in _add_rubble_piece() and for SpireTip in _create_collapsed_spire(). Affects SpireTip (3×5×15m), Rubble1–4 around spire, and Debris1–2 in each of 3 ruin clusters. Commit: 1b8910706a599430772ef21e2d5c2bd9294a7166 PR: https://github.com/sqlhammer/Hammer-Forge-Studio/pull/168
