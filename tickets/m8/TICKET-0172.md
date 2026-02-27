---
id: TICKET-0172
title: "Debris Field biome — terrain, wreckage clusters, resource placement"
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
tags: [biome, debris-field, terrain, m8-gameplay]
---

## Summary

Build the Debris Field biome scene. Scattered wreckage clusters on uneven ground. High-risk, high-reward: Cryonite-heavy with low Scrap Metal — the primary biome for fuel farming. Must contain sufficient resources to craft at least one Fuel Cell.

## Acceptance Criteria

- [ ] Scene generated using `TerrainGenerator` with the `debris_field` archetype and its fixed seed
- [ ] Layout is consistent on every visit (deterministic seed)
- [ ] Wreckage clusters scattered across terrain — minimum 5 distinct clusters of greybox debris geometry
- [ ] Terrain uneven — mounds and depressions between flat clearings
- [ ] Resource nodes placed on generated terrain:
  - Scrap Metal nodes: 2–4 surface nodes (sparse)
  - Cryonite nodes: 7–10 surface nodes (high concentration — primary Cryonite source)
  - At least 2 deep Cryonite nodes (rich deep veins beneath surface pockets)
  - At least 1 deep Scrap Metal node
- [ ] Biome contains sufficient Metal + Cryonite to craft ≥1 Fuel Cell before depletion
- [ ] Player and ship spawn points defined
- [ ] World boundary active and tested
- [ ] Full test suite passes

## Implementation Notes

- Wreckage is greybox geometry — reuse/remix ship exterior mesh fragments or use CSG primitives
- The higher Cryonite concentration makes this the most fuel-rich biome — resource placement must reflect this clearly
- Deep Cryonite nodes here should be visually notable (larger pressurized formation)

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
