---
id: TICKET-0164
title: "World boundary test harness — unit tests verifying boundary enforcement"
type: TASK
status: PENDING
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Foundation"
depends_on: [TICKET-0163]
blocks: []
tags: [testing, boundary, world, harness, m8-foundation]
---

## Summary

Write a dedicated test harness that verifies the world boundary system functions correctly across all biome archetypes. Tests must confirm the player cannot escape the defined play area, that terrain stays within bounds, and that boundary dimensions match the archetype config.

## Acceptance Criteria

- [ ] Test suite in `game/tests/test_world_boundary.gd` covering:
  - Player position cannot exceed boundary extents in any cardinal direction
  - Player position cannot exceed boundary extents diagonally (corner cases)
  - Terrain heightmap data contains no vertices outside boundary XZ extents
  - Boundary dimensions match the values defined in each biome archetype config
  - Boundary walls are present and have active collision
- [ ] Tests run headlessly without requiring the full game scene loaded
- [ ] All tests pass for each of the three biome archetypes
- [ ] Full test suite passes

## Implementation Notes

- Use programmatic player position injection to test boundary enforcement without manual movement
- Test each biome archetype's boundary independently
- These tests are a hard gate on the Foundation phase — if boundaries are broken, biome scene work cannot begin safely

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase
