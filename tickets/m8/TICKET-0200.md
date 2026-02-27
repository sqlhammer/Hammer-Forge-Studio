---
id: TICKET-0200
title: "Bugfix — Resource node meshes are too small in Shattered Flats"
type: BUGFIX
status: TODO
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, shattered-flats, resource-node, mesh, scale, m8-qa]
---

## Summary

Resource node meshes in the Shattered Flats biome appear smaller than their previous size. The nodes need to be restored to their original scale. This is a regression — prior to M8 terrain generation changes, node sizes were correct.

## Steps to Reproduce

1. Launch Shattered Flats via the debug launcher (`res://game/scenes/debug/debug_launcher.tscn`) or normal gameplay
2. Locate any resource node in the biome
3. Observe: node mesh is visually smaller than expected

## Expected Behavior

Resource nodes render at the same scale they had in prior milestones (M7 and earlier). Nodes should be clearly visible and appropriately sized relative to the player and terrain.

## Acceptance Criteria

- [ ] Resource node mesh scale in Shattered Flats matches the scale used in prior milestones
- [ ] Fix applies to all node types present in Shattered Flats (Scrap Metal, Cryonite, etc.)
- [ ] No regression to Rock Warrens or Debris Field node sizes
- [ ] Full test suite passes with no new failures

## Implementation Notes

- Check the `ShatteredFlatsBiome` scene/script for any node scale overrides applied during procedural placement
- Compare node `scale` values against those used in `TestWorld` or earlier biome implementations
- The regression may have been introduced in TICKET-0157 (terrain generation) or TICKET-0159/0160 (biome scene setup)
- Look for scale being set on the node instance during `TerrainFeatureRequest` placement or in the biome's `generate()` method

## Activity Log

- 2026-02-27 [producer] Created — Studio Head reported during final M8 playtest review
