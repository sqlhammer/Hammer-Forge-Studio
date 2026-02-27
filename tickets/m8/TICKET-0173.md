---
id: TICKET-0173
title: "Deep resource nodes — scene implementation, slow-yield behaviour, drone mining integration"
type: FEATURE
status: PENDING
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

- [ ] `DeepResourceNode` scene created (extends or variants the existing deposit scene)
- [ ] Visually distinct from surface nodes — partially submerged appearance, visible just below the terrain surface
- [ ] Manual mining works but yield interval is visibly slower than surface nodes
- [ ] Drones can be assigned to deep nodes and will mine them indefinitely (no depletion)
- [ ] Deep nodes do not show a depletion state — no empty visual
- [ ] Deep nodes do not respawn (confirmed by respawn system exclusion in TICKET-0161)
- [ ] Placed in all three biome scenes (TICKET-0170–0172 handle placement)
- [ ] Unit tests cover: manual yield at slow rate, drone assignment works, no depletion after extended mining, respawn system skips deep nodes
- [ ] Full test suite passes

## Implementation Notes

- Use the `infinite: true` and `yield_rate` flags from TICKET-0160 data layer
- Placement depth: slightly below terrain surface so the top of the mesh is flush with or just breaking through the ground
- The same mesh can be used for both Scrap Metal and Cryonite deep nodes with a material/color swap

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
