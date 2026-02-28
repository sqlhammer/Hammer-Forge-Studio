---
id: TICKET-0222
title: "Bugfix — Mining minigame lines are too large for the node; couple minigame as child scene to the deposit scene"
type: BUGFIX
status: IN_PROGRESS
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, mining, minigame, resource-node, scene-architecture, m8-qa]
---

## Summary

Resource nodes in the biomes are smaller than in TestWorld. The mining minigame's trace lines are positioned and sized relative to the TestWorld node scale, making them too large and misaligned on biome nodes. Additionally, the minigame line placement is currently computed dynamically in `Mining.gd` using hardcoded world-space offsets — it should instead be a child scene parented to the deposit scene so it inherits the node's transform and scales correctly with any node variant.

## Steps to Reproduce

1. Launch any biome via the debug launcher
2. Locate a resource node and scan + analyze it
3. Begin mining the deposit
4. Observe: the minigame trace lines appear oversized relative to the node's actual mesh

## Expected Behavior

Minigame trace lines are correctly sized and positioned relative to the deposit node, regardless of node scale. The minigame scene is a child of the deposit scene and inherits its transform.

## Acceptance Criteria

- [ ] Minigame trace lines are visually contained within the deposit mesh at all biome node scales
- [ ] Minigame scene is a child scene parented to the deposit scene (not spawned at hardcoded world-space offsets in `Mining.gd`)
- [ ] `Mining.gd` instantiates and activates the minigame via a reference to the child scene rather than constructing lines procedurally
- [ ] Minigame behavior (dwell trace, completion, bonus yield) is unchanged
- [ ] Fix applies to all deposit variants: surface, deep, Scrap Metal, Cryonite
- [ ] Full test suite passes with no new failures

## Implementation Notes

- Current implementation in `Mining._create_pattern_lines()` spawns `MeshInstance3D` nodes at computed world-space offsets relative to `deposit.global_position + Vector3(0, 0.9, 0)` — this ties line size and position to an assumed node height that does not match biome nodes
- Preferred fix: create a `MiningMinigame` child scene (e.g., `game/scenes/objects/mining_minigame.tscn`) with the pattern lines defined in local space relative to the deposit's origin; add an instance of this scene to `deposit.tscn` (and its variants); `Mining.gd` calls `deposit.get_minigame()` (or similar accessor) rather than creating lines itself
- The child scene approach ensures the minigame automatically inherits any scale applied to the parent deposit scene
- If a full child-scene refactor is out of scope, at minimum normalize the LINE_OFFSETS and LINE_MESH dimensions to match the actual biome node mesh extents rather than the TestWorld mesh size

## Activity Log

- 2026-02-28 [producer] Created — Studio Head reported during M8 playtest
- 2026-02-28 [gameplay-programmer] Starting work — creating MiningMinigame child scene, refactoring Mining.gd
