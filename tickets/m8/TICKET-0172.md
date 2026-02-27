---
id: TICKET-0172
title: "Debris Field biome — terrain, wreckage clusters, resource placement"
type: FEATURE
status: IN_PROGRESS
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Gameplay"
depends_on: [TICKET-0162, TICKET-0179]
blocks: []
tags: [biome, debris-field, terrain, m8-gameplay]
---

## Summary

Build the Debris Field biome scene. Scattered wreckage clusters on uneven ground. High-risk, high-reward: Cryonite-heavy with low Scrap Metal — the primary biome for fuel farming. Must contain sufficient resources to craft at least one Fuel Cell.

## Acceptance Criteria

- [x] Scene generated using `TerrainGenerator` with the `debris_field` archetype and its fixed seed
- [x] Layout is consistent on every visit (deterministic seed)
- [x] Wreckage clusters scattered across terrain — minimum 5 distinct clusters of greybox debris geometry
- [x] Terrain uneven — mounds and depressions between flat clearings
- [x] Resource nodes placed on generated terrain:
  - Scrap Metal nodes: 2–4 surface nodes (sparse)
  - Cryonite nodes: 7–10 surface nodes (high concentration — primary Cryonite source)
  - At least 2 deep Cryonite nodes (rich deep veins beneath surface pockets)
  - At least 1 deep Scrap Metal node
- [x] Biome contains sufficient Metal + Cryonite to craft ≥1 Fuel Cell before depletion
- [x] Player and ship spawn points defined
- [x] World boundary active and tested
- [x] Full test suite passes

## Implementation Notes

- Wreckage is greybox geometry — reuse/remix ship exterior mesh fragments or use CSG primitives
- The higher Cryonite concentration makes this the most fuel-rich biome — resource placement must reflect this clearly
- Deep Cryonite nodes here should be visually notable (larger pressurized formation)

## Handoff Notes

**Implemented by:** gameplay-programmer

**Scripts created:**
- `game/scripts/gameplay/debris_field_biome.gd` — DebrisFieldBiome class (Node3D)
- `game/tests/test_debris_field_biome_unit.gd` — 25 unit tests

**Architecture:**
- Generates terrain via TerrainGenerator with debris_field archetype (seed 3317)
- Declarative feature requests: 1 clearing (ship spawn), 2 resource spawns (scrap + cryonite), 1 wreckage position spawn
- 6 wreckage clusters using CSGBox3D greybox debris pieces (3-7 fragments each)
- 3 surface Scrap Metal + 8 surface Cryonite deposits (MEDIUM density, 40 units)
- 2 deep Cryonite (infinite, 4-star, 0.1 yield) + 1 deep Scrap Metal (infinite, 3-star, 0.1 yield)
- Deep Cryonite visually larger (5.0 scale vs 3.5 surface) per implementation notes
- World boundary via WorldBoundaryManager
- All data resolved at construction time via _init(); build_scene() creates visual/physics nodes

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
- 2026-02-27 [gameplay-programmer] Starting work — implementing Debris Field biome with TDD (RED/GREEN/REFACTOR cycle)
