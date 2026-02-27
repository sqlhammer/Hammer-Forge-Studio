---
id: TICKET-0162
title: "Procedural terrain system — seed-based noise heightmap, biome archetype templates"
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
tags: [terrain, procedural, noise, heightmap, biome, m8-foundation]
---

## Summary

Implement a seed-based procedural terrain generation system. Each biome has a fixed integer seed that produces a consistent, deterministic layout on every visit. The system uses noise-based heightmap generation with per-biome archetype templates that control the character of the terrain (open plains vs. dense formations vs. debris clusters). All three biome scene tickets (TICKET-0170–0172) build on top of this system.

**This ticket will be refined further in a dedicated planning session with the Studio Head before implementation begins.**

## Acceptance Criteria

- [ ] `TerrainGenerator` — accepts a seed and a biome archetype config, outputs terrain mesh or heightmap data
- [ ] Terrain generation is fully deterministic: same seed + same archetype always produces identical output
- [ ] Three biome archetype configs defined (parameters only — not the full scenes):
  - `shattered_flats`: large open areas, low frequency noise, gentle undulation, occasional raised formations
  - `rock_warrens`: high frequency noise, dense vertical variation, tight navigable corridors
  - `debris_field`: medium frequency, uneven scattered mounds, flat clearings between debris clusters
- [ ] Terrain size bounded by the world boundary system (TICKET-0163 defines limits; terrain generator must not produce geometry outside them)
- [ ] Terrain is walkable — no geometry that traps the player or creates unreachable areas
- [ ] Generator is callable at scene load time (not runtime streaming) — terrain fully generated on biome entry
- [ ] Unit tests cover: determinism (same seed produces same output), boundary compliance, each archetype produces distinct output measurably different from the others
- [ ] Full test suite passes

## Implementation Notes

*(To be detailed in planning session with Studio Head — see ticket summary note)*

- Godot's `FastNoiseLite` is the expected noise source
- Terrain mesh approach (MeshInstance3D with ArrayMesh) vs. HeightMapShape3D for collision TBD in planning session
- Resource node placement hooks (surface + deep) should be exposed so biome scene tickets can query valid spawn positions from the generated terrain

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase. Planning session with Studio Head scheduled to refine implementation approach.
