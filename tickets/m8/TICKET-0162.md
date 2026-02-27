---
id: TICKET-0162
title: "Procedural terrain system — declarative feature requests, ArrayMesh, seed-based generation"
type: FEATURE
status: PENDING
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Foundation"
depends_on: []
blocks: []
tags: [terrain, procedural, noise, arraymesh, biome, feature-request, m8-foundation]
---

## Summary

Implement a seed-based procedural terrain generation system built around a declarative `TerrainFeatureRequest` API. Biome scene tickets describe *what terrain features they need* — plateaus, clearings, ramps, resource spawn zones — and the generator shapes the mesh to satisfy those requests before returning confirmed world-space positions. No biome-specific logic lives inside the generator.

Each biome has a fixed integer seed ensuring deterministic, consistent layouts on every visit. Terrain is 500m × 500m, generated as an `ArrayMesh` with a baked `ConcavePolygonShape3D` for collision. Internal data structures are organized in a chunk-friendly spatial grid so a future streaming system can be added without restructuring the generator.

All three biome scene tickets (TICKET-0170–0172) build on top of this system.

## TerrainFeatureRequest API

Biome tickets construct a list of `TerrainFeatureRequest` resources and pass them to `TerrainGenerator.generate()` before terrain is finalized. The generator processes all requests, shapes the mesh to satisfy them, and returns a `TerrainGenerationResult` containing confirmed world-space positions for each request.

### Supported request types (minimum for M8)

**`plateau`** — Raises a flat elevated area of specified dimensions with a player-accessible ascent method.
```
TerrainFeatureRequest {
  type: "plateau"
  width: float          # X extent in metres
  depth: float          # Z extent in metres
  height: float         # elevation above base terrain
  access: "ramp" | "none"
  ramp_width: float     # width of ascent path (when access = "ramp")
  position_hint: "center" | Vector2  # world-space XZ or named anchor
}
```

**`clearing`** — Guarantees a flat, obstacle-free circular area. Used for ship spawn zones, landmark bases.
```
TerrainFeatureRequest {
  type: "clearing"
  radius: float
  position_hint: Vector2 | "edge"
}
```

**`resource_spawn`** — Samples N surface positions meeting slope and clearance criteria. Used by biome tickets to place resource nodes.
```
TerrainFeatureRequest {
  type: "resource_spawn"
  count: int
  slope_max: float      # degrees — filters steep faces
  clearance_radius: float
  position_hint: Vector2 | null  # optional clustering hint
}
```

**`walkable_clearance`** — Guarantees a minimum walkable radius around a specific position. Used by Rock Warrens to ensure resource nodes and the ship spawn are not enclosed by rock geometry.
```
TerrainFeatureRequest {
  type: "walkable_clearance"
  position: Vector2
  radius: float         # minimum unobstructed ground radius
}
```

New request types can be added in future milestones without modifying the generator core — each type is a handler registered in a dispatch table.

## Acceptance Criteria

- [ ] `TerrainFeatureRequest` resource defined with typed fields as specified above
- [ ] `TerrainGenerator` accepts: `seed: int`, `archetype: BiomeArchetypeConfig`, `requests: Array[TerrainFeatureRequest]`
- [ ] `TerrainGenerationResult` returned containing: terrain `ArrayMesh`, confirmed positions per request, any unresolvable request warnings
- [ ] Terrain generation is fully deterministic — same seed + same archetype + same requests always produces identical output
- [ ] `ConcavePolygonShape3D` baked from the final `ArrayMesh` at generation time (one-time, not dynamic)
- [ ] Terrain size: 500m × 500m — no geometry outside world boundary extents (TICKET-0163)
- [ ] Internal geometry organized in a chunk-aligned spatial grid (chunk size TBD by implementer, consistent with likely future streaming granularity) — grid structure accessible for future LOD/streaming work without refactor
- [ ] Three biome archetype configs defined with noise parameters appropriate to their character:
  - `shattered_flats`: low-frequency noise, gentle undulation, open traversal — biome ticket submits a `plateau` request for the central landmark area
  - `rock_warrens`: high-frequency noise, dense vertical variation — biome ticket submits `walkable_clearance` requests around all placement points; clearance-based corridor emergence is the primary strategy; if testing reveals dead-end corridors, fallback to path-based carving (see Implementation Notes)
  - `debris_field`: medium-frequency noise, scattered mound clusters, flat clearings between them
- [ ] All placement requests resolved before mesh is finalized — no post-hoc terrain flattening
- [ ] Terrain walkable — no enclosed geometry trapping the player; all `walkable_clearance` requests honored
- [ ] Unit tests cover:
  - Determinism (same inputs → identical `ArrayMesh` vertex data)
  - Boundary compliance (no vertex outside 500m × 500m)
  - `plateau` request produces a flat elevated area within tolerance
  - `clearing` request produces an obstacle-free flat zone of specified radius
  - `resource_spawn` request returns N positions meeting slope and clearance criteria
  - `walkable_clearance` request produces unobstructed ground of specified radius
  - Chunk grid covers full terrain extent with no gaps
- [ ] Full test suite passes

## Implementation Notes

- **Noise source:** Godot's `FastNoiseLite` — use multiple octaves for natural layering; archetype config controls frequency, octave count, and amplitude per layer
- **Mesh approach:** `ArrayMesh` via `SurfaceTool` or direct `PackedVector3Array` construction from noise samples; `ConcavePolygonShape3D` baked from the same vertex data for collision fidelity
- **Rock Warrens corridor strategy:** Primary approach is clearance-based — `walkable_clearance` requests around every placement point guarantee the player can reach each node. If post-generation testing (TICKET-0164) reveals unreachable areas or dead-end corridors between clusters, implement path-based carving as fallback: accept waypoint pairs from the biome ticket and carve a minimum-width (3m) path between them using terrain flattening along a Bezier or A* path on the noise grid
- **Chunk grid:** Organize generated vertices into a 2D spatial grid at generation time. Chunk size should align to a power of two (e.g., 32m × 32m or 64m × 64m). Each chunk stores its mesh section and collision shape independently. In M8, all chunks are loaded simultaneously. The grid structure is the interface point for a future streaming system — do not couple it to the full-load assumption
- **Feature request dispatch:** Implement as a dictionary of `type → handler callable` so new request types can be registered without modifying `TerrainGenerator` core
- **Position hints:** `"center"` resolves to `Vector2(250, 250)` for a 500m terrain; `"edge"` resolves to a position near the boundary clearance zone

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase. Planning session with Studio Head scheduled to refine implementation approach.
- 2026-02-27 [producer] Refined — Studio Head planning session complete. Full architecture specified: declarative TerrainFeatureRequest API, ArrayMesh + ConcavePolygonShape3D, 500m × 500m chunk-grid layout, clearance-based Rock Warrens corridors with path-carving fallback, Shattered Flats plateau via feature request (not hardcoded flag).
