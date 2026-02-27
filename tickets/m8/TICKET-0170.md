---
id: TICKET-0170
title: "Shattered Flats biome — terrain, alien ruins, collapsed spire, resource placement"
type: FEATURE
status: PENDING
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Gameplay"
depends_on: [TICKET-0162, TICKET-0179]
blocks: []
tags: [biome, shattered-flats, terrain, m8-gameplay]
---

## Summary

Build the Shattered Flats biome scene using the procedural terrain system (TICKET-0162). Shattered Flats is the starter biome — open terrain with long sight lines, alien ruins scattered throughout, and a large collapsed spire as a central landmark. Resource profile: Scrap Metal-heavy with small amounts of Cryonite. Must contain sufficient Metal and Cryonite to craft at least one Fuel Cell before the player must leave.

## Acceptance Criteria

- [ ] Scene generated using `TerrainGenerator` with the `shattered_flats` archetype and its fixed seed
- [ ] Layout is consistent on every visit (deterministic seed)
- [ ] Alien ruins placed as greybox geometry — minimum 3 distinct ruin clusters, varied scale
- [ ] Collapsed spire landmark present — large fallen structure, visible from any point in the biome
- [ ] Resource nodes placed on generated terrain:
  - Scrap Metal nodes: 8–12 surface nodes
  - Cryonite nodes: 3–5 surface nodes (pressurized zones near ruin clusters)
  - At least 1 deep node each (Scrap Metal and Cryonite) beneath surface nodes
- [ ] Biome contains sufficient Metal + Cryonite to craft ≥1 Fuel Cell before depletion
- [ ] Player and ship spawn points defined
- [ ] World boundary active and tested (no escape possible)
- [ ] Full test suite passes

## Implementation Notes

- Ruins and spire are greybox (CSGBox/CSGMesh or simple MeshInstance3D primitives) — art pass is M9
- Resource node placement should use the spawn position API exposed by TerrainGenerator
- Deep nodes placed beneath (slightly lower Y than) their corresponding surface node

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
