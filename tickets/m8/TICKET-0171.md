---
id: TICKET-0171
title: "Rock Warrens biome — terrain, dense rock formations, corridors, resource placement"
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
tags: [biome, rock-warrens, terrain, m8-gameplay]
---

## Summary

Build the Rock Warrens biome scene. Dense rock formations create tight navigable corridors with low visibility. Mixed resource profile: Scrap Metal and Cryonite pockets. Must contain sufficient resources to craft at least one Fuel Cell.

## Acceptance Criteria

- [ ] Scene generated using `TerrainGenerator` with the `rock_warrens` archetype and its fixed seed
- [ ] Layout is consistent on every visit (deterministic seed)
- [ ] Dense rock formation clusters create corridors — player navigation requires winding between formations, not open traversal
- [ ] Sight lines are short — rock formations obstruct view across the biome
- [ ] Resource nodes placed on generated terrain:
  - Scrap Metal nodes: 5–8 surface nodes (nestled between rock formations)
  - Cryonite nodes: 4–7 surface nodes (Cryonite pockets in pressurized rock zones — higher concentration than Shattered Flats)
  - At least 1 deep node each (Scrap Metal and Cryonite)
- [ ] Biome contains sufficient Metal + Cryonite to craft ≥1 Fuel Cell before depletion
- [ ] Player and ship spawn points defined (open area near biome edge)
- [ ] World boundary active and tested
- [ ] Full test suite passes

## Implementation Notes

- Rock formations are greybox geometry — CSGBox stacks or simple MeshInstance3D primitives
- Corridors must be wide enough for the player to navigate without feeling stuck (min ~2m clearance)
- Ship spawn requires a clearing large enough for the ship mesh

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
- 2026-02-27 [gameplay-programmer] Starting work — implementing Rock Warrens biome with TDD (RED/GREEN/REFACTOR cycle)
