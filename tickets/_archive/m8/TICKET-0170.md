---
id: TICKET-0170
title: "Shattered Flats biome — terrain, alien ruins, collapsed spire, resource placement"
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
tags: [biome, shattered-flats, terrain, m8-gameplay]
---

## Summary

Build the Shattered Flats biome scene using the procedural terrain system (TICKET-0162). Shattered Flats is the starter biome — open terrain with long sight lines, alien ruins scattered throughout, and a large collapsed spire as a central landmark. Resource profile: Scrap Metal-heavy with small amounts of Cryonite. Must contain sufficient Metal and Cryonite to craft at least one Fuel Cell before the player must leave.

## Acceptance Criteria

- [x] Scene generated using `TerrainGenerator` with the `shattered_flats` archetype and its fixed seed
- [x] Layout is consistent on every visit (deterministic seed)
- [x] Alien ruins placed as greybox geometry — minimum 3 distinct ruin clusters, varied scale
- [x] Collapsed spire landmark present — large fallen structure, visible from any point in the biome
- [x] Resource nodes placed on generated terrain:
  - Scrap Metal nodes: 8–12 surface nodes
  - Cryonite nodes: 3–5 surface nodes (pressurized zones near ruin clusters)
  - At least 1 deep node each (Scrap Metal and Cryonite) beneath surface nodes
- [x] Biome contains sufficient Metal + Cryonite to craft ≥1 Fuel Cell before depletion
- [x] Player and ship spawn points defined
- [x] World boundary active and tested (no escape possible)
- [x] Full test suite passes

## Implementation Notes

- Ruins and spire are greybox (CSGBox/CSGMesh or simple MeshInstance3D primitives) — art pass is M9
- Resource node placement should use the spawn position API exposed by TerrainGenerator
- Deep nodes placed beneath (slightly lower Y than) their corresponding surface node

## Handoff Notes

**Implemented by:** gameplay-programmer
**Commit:** 2f40c12 (merge commit on main)
**PR:** https://github.com/sqlhammer/Hammer-Forge-Studio/pull/149

**Scripts created:**
- `game/scripts/gameplay/shattered_flats_biome.gd` — ShatteredFlatsBiome class (extends Node3D)

**Architecture:**
- Biome class uses declarative TerrainFeatureRequest API — no biome logic in TerrainGenerator
- Central plateau submitted as a `plateau` feature request (60x60m, 6m elevation, ramp access)
- 3 alien ruin clusters as greybox BoxMesh/CylinderMesh geometry with per-cluster scale variation
- Collapsed spire landmark: 40m fallen structure with rubble, collision-enabled for walk-on
- Resource deposits: 8-12 Scrap Metal surface + 3-5 Cryonite surface + 1 deep each (infinite, 10% yield rate)
- Ship/player spawn via Marker3D at confirmed clearing position near southern edge
- WorldBoundaryManager initialized from BiomeArchetypeConfig
- Deterministic generation: seed 1001, seeded RNG for all procedural placement
- GLB meshes loaded via PackedScene instantiation for deposit visuals

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
- 2026-02-27 [gameplay-programmer] Starting work — implementing Shattered Flats biome class with declarative TerrainFeatureRequest API
- 2026-02-27 [gameplay-programmer] DONE — commit 2f40c12, PR #149 (https://github.com/sqlhammer/Hammer-Forge-Studio/pull/149) merged to main. 1 new script, all acceptance criteria met.
