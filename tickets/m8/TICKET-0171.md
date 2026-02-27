---
id: TICKET-0171
title: "Rock Warrens biome — terrain, dense rock formations, corridors, resource placement"
type: FEATURE
status: DONE
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

- [x] Scene generated using `TerrainGenerator` with the `rock_warrens` archetype and its fixed seed
- [x] Layout is consistent on every visit (deterministic seed)
- [x] Dense rock formation clusters create corridors — player navigation requires winding between formations, not open traversal
- [x] Sight lines are short — rock formations obstruct view across the biome
- [x] Resource nodes placed on generated terrain:
  - Scrap Metal nodes: 5–8 surface nodes (nestled between rock formations)
  - Cryonite nodes: 4–7 surface nodes (Cryonite pockets in pressurized rock zones — higher concentration than Shattered Flats)
  - At least 1 deep node each (Scrap Metal and Cryonite)
- [x] Biome contains sufficient Metal + Cryonite to craft ≥1 Fuel Cell before depletion
- [x] Player and ship spawn points defined (open area near biome edge)
- [x] World boundary active and tested
- [x] Full test suite passes

## Implementation Notes

- Rock formations are greybox geometry — CSGBox stacks or simple MeshInstance3D primitives
- Corridors must be wide enough for the player to navigate without feeling stuck (min ~2m clearance)
- Ship spawn requires a clearing large enough for the ship mesh

## Handoff Notes

**Implemented by:** gameplay-programmer
**Commit:** cf12dc3 (merge commit on main)
**PR:** https://github.com/sqlhammer/Hammer-Forge-Studio/pull/154

**Scripts created:**
- `game/scripts/gameplay/rock_warrens_biome.gd` — RockWarrensBiome class (Node3D) — full biome generation
- `game/tests/test_rock_warrens_biome_unit.gd` — 16 unit tests (TestRockWarrensBiomeUnit)

**Architecture:**
- Uses TerrainGenerator with BiomeArchetypeConfig.rock_warrens() (seed 2047, high-frequency noise, 6 octaves, height_scale 25)
- Pre-computes resource positions via seeded RNG, then requests walkable_clearance at each position
- Clearing at biome edge (20m radius) for ship/player spawn
- CSGBox3D rock formations on 12m grid (65% density, 6-18m tall, 1-3 stacked blocks)
- Exclusion zones prevent formations from blocking resource access and spawn areas
- Deposits created via Deposit.new() + setup() — no scene instantiation (greybox)
- Deep nodes: infinite=true, yield_rate=0.1
- WorldBoundaryManager initialized from archetype config

**UID Note:** Godot-generated .gd.uid sidecar files for the 2 new scripts need to be committed after Godot editor scans. The MCP execute_editor_script tool was not available in this session. A subsequent filesystem scan will generate them.

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
- 2026-02-27 [gameplay-programmer] Starting work — implementing Rock Warrens biome with TDD (RED/GREEN/REFACTOR cycle)
- 2026-02-27 [gameplay-programmer] DONE — commit cf12dc3, PR #154 merged. 2 new scripts, 16 unit tests.
