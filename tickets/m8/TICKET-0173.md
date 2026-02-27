---
id: TICKET-0173
title: "Deep resource nodes — scene implementation, slow-yield behaviour, drone mining integration"
type: FEATURE
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Gameplay"
depends_on: [TICKET-0160]
blocks: []
tags: [resource, deep-node, scene, drones, m8-gameplay]
---

## Summary

Implement the deep resource node as a scene. Deep nodes are placed slightly below ground beneath some surface nodes. They are slow to yield manually but can be assigned to automated drones for indefinite mining. They never deplete. Implements the scene side of the data layer defined in TICKET-0160.

## Acceptance Criteria

- [x] `DeepResourceNode` scene created (extends or variants the existing deposit scene)
- [x] Visually distinct from surface nodes — partially submerged appearance, visible just below the terrain surface
- [x] Manual mining works but yield interval is visibly slower than surface nodes
- [x] Drones can be assigned to deep nodes and will mine them indefinitely (no depletion)
- [x] Deep nodes do not show a depletion state — no empty visual
- [x] Deep nodes do not respawn (confirmed by respawn system exclusion in TICKET-0161)
- [ ] Placed in all three biome scenes (TICKET-0170–0172 handle placement)
- [x] Unit tests cover: manual yield at slow rate, drone assignment works, no depletion after extended mining, respawn system skips deep nodes
- [ ] Full test suite passes (pending QA run)

## Implementation Notes

- Use the `infinite: true` and `yield_rate` flags from TICKET-0160 data layer
- Placement depth: slightly below terrain surface so the top of the mesh is flush with or just breaking through the ground
- The same mesh can be used for both Scrap Metal and Cryonite deep nodes with a material/color swap

## Handoff Notes

**Implemented by:** gameplay-programmer
**Commit:** 0cc3796 (merge commit on main)
**PR:** https://github.com/sqlhammer/Hammer-Forge-Studio/pull/152

**Scripts created:**
- `game/scripts/gameplay/deep_resource_node.gd` — DeepResourceNode class (extends Deposit, enforces infinite=true, yield_rate=0.1, drone_accessible=true)

**Scripts modified:**
- `game/scripts/gameplay/mining.gd` — Manual mining extraction duration now scaled by deposit.yield_rate (deep nodes mine 10x slower)
- `game/scripts/gameplay/drone_controller.gd` — Drone extraction rate now scaled by deposit.yield_rate

**Scenes created:**
- `game/scenes/objects/deposit_deep.tscn` — Base deep deposit scene (inherits deposit.tscn, uses DeepResourceNode script)
- `game/scenes/objects/deposit_deep_scrap_metal.tscn` — Scrap metal variant (mesh submerged -0.5u)
- `game/scenes/objects/deposit_deep_cryonite.tscn` — Cryonite variant (mesh submerged -0.5u)

**Tests created:**
- `game/tests/test_deep_resource_node_scene.gd` — 14 unit tests covering scene defaults, extraction, mining yield_rate scaling, drone targeting, respawn skip

**Architecture:**
- DeepResourceNode extends Deposit — reuses all existing deposit data/extraction/serialization logic
- `_ready()` enforces infinite=true, drone_accessible=true, and yield_rate < 1.0 as safety net for programmatic creation
- Mining.gd computes `effective_duration = EXTRACTION_DURATION / yield_rate` — surface nodes unaffected (yield_rate=1.0), deep nodes 10x slower (yield_rate=0.1)
- Battery drain rate proportionally adjusted to effective mining duration
- DroneController applies yield_rate to extraction accumulator rate

**Biome placement:** TICKET-0170–0172 handle placing deep nodes in biome scenes — this ticket provides the scene files they instantiate.

**Known:** UID sidecar files for new .gd scripts pending Godot filesystem scan — will be committed once Godot generates them.

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
- 2026-02-27 [gameplay-programmer] Starting work — implementing DeepResourceNode scene, slow-yield behaviour, drone mining integration
- 2026-02-27 [gameplay-programmer] DONE — commit 0cc3796, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/152 merged to main. DeepResourceNode scene + script, mining yield_rate integration, drone extraction scaling, 3 scene variants, 14 unit tests.
