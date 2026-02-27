---
id: TICKET-0163
title: "World boundary system — hard bounds, edge detection, boundary enforcement"
type: FEATURE
status: PENDING
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

- [ ] Each biome has a defined rectangular (or configurable) play area boundary
- [ ] Invisible boundary walls prevent player from walking out of bounds
- [ ] Boundary dimensions are data-driven per biome archetype (not hardcoded per scene)
- [ ] Player receives a subtle visual/audio cue when approaching boundary (e.g., warning indicator)
- [ ] Drones and physics objects are also constrained within bounds
- [ ] Terrain generator boundary compliance verified (no geometry spawns outside bounds)
- [ ] Unit tests covered by TICKET-0164 (boundary test harness)
- [ ] Full test suite passes

## Implementation Notes

- Use `StaticBody3D` with `BoxShape3D` walls placed at boundary edges, or a single `WorldBoundaryShape3D` if appropriate
- Boundary size constants should live in the biome archetype config (established in TICKET-0162) so terrain and boundaries share the same dimensions
- Keep boundary enforcement simple — no complex geometry, just reliable containment

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase
