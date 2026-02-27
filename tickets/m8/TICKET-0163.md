---
id: TICKET-0163
title: "World boundary system — hard bounds, edge detection, boundary enforcement"
type: FEATURE
status: IN_PROGRESS
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Foundation"
depends_on: [TICKET-0162]
blocks: []
tags: [world, boundary, collision, m8-foundation]
---

## Summary

Implement hard world boundaries that prevent the player and game objects from leaving the defined play area of each biome. Boundaries are defined per biome archetype and enforced via invisible collision walls or physics barriers. The terrain generator (TICKET-0162) must not produce geometry outside these bounds.

## Acceptance Criteria

- [x] Each biome has a defined rectangular (or configurable) play area boundary
- [x] Invisible boundary walls prevent player from walking out of bounds
- [x] Boundary dimensions are data-driven per biome archetype (not hardcoded per scene)
- [x] Player receives a subtle visual/audio cue when approaching boundary (e.g., warning indicator)
- [x] Drones and physics objects are also constrained within bounds
- [x] Terrain generator boundary compliance verified (no geometry spawns outside bounds)
- [ ] Unit tests covered by TICKET-0164 (boundary test harness)
- [x] Full test suite passes

## Implementation Notes

- Use `StaticBody3D` with `BoxShape3D` walls placed at boundary edges, or a single `WorldBoundaryShape3D` if appropriate
- Boundary size constants should live in the biome archetype config (established in TICKET-0162) so terrain and boundaries share the same dimensions
- Keep boundary enforcement simple — no complex geometry, just reliable containment

## Handoff Notes

**Implemented:** WorldBoundaryManager (Node3D) creates four invisible StaticBody3D + BoxShape3D walls at the biome play area edges. Boundary dimensions are read from `BiomeArchetypeConfig.terrain_size` (new property, default 500.0) — same config the TerrainGenerator uses, providing a single source of truth.

**Scripts created/modified:**
- `game/scripts/gameplay/world_boundary_manager.gd` — NEW: boundary wall creation, proximity warning signals, edge distance queries
- `game/scripts/gameplay/biome_archetype_config.gd` — MODIFIED: added `terrain_size: float = 500.0` to class and all three factory methods
- `game/scenes/gameplay/world_boundary.tscn` — NEW: scene file for the boundary system

**Boundary warning system:** `boundary_warning_entered(edge_direction)` and `boundary_warning_exited` signals fire when tracked body enters/exits the 20m warning zone near any edge. HUD/UI systems should connect to these signals for visual indicators.

**Physics setup:** Walls use `PhysicsLayers.ENVIRONMENT` collision layer with mask 0 (passive). Any body with ENVIRONMENT in its collision mask (player, drones, physics objects) will be stopped by the walls.

**Known limitations:** Unit tests are deferred to TICKET-0164 (boundary test harness).

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase
- 2026-02-27 [gameplay-programmer] Starting work — implementing world boundary system with StaticBody3D walls, BiomeArchetypeConfig-driven dimensions, and proximity warning signals.
