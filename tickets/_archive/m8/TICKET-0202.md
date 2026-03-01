---
id: TICKET-0202
title: "Bugfix — Resources cannot be scanned in Shattered Flats"
type: BUGFIX
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, shattered-flats, scanner, resource-node, interaction, raycast, m8-qa]
---

## Summary

Resource nodes in the Shattered Flats biome cannot be scanned by the player's scanner. Aiming at a node and activating the scanner produces no scan result. Scanning works correctly in other biomes and in TestWorld. This is a Shattered Flats-specific regression.

## Steps to Reproduce

1. Launch Shattered Flats via the debug launcher or normal gameplay
2. Equip the scanner
3. Aim at a resource node and activate the scanner
4. Observe: no scan result is produced; the node is not identified

## Expected Behavior

Aiming the scanner at a resource node and activating it produces a scan result identifying the node type and resource, consistent with behavior in all other biomes.

## Acceptance Criteria

- [x] Scanner successfully scans resource nodes in Shattered Flats
- [x] Scan results display correctly (node type, resource type) as in other biomes
- [x] Fix does not regress scanner behavior in other biomes or TestWorld
- [x] Full test suite passes with no new failures

## Implementation Notes

- The scanner uses a raycast to detect scannable objects; check whether Shattered Flats resource nodes have the correct collision layer/mask set for the scanner's raycast
- Also check whether nodes have the correct collision shape enabled at runtime — procedural placement may be spawning nodes without physics shapes active
- Possible overlap with TICKET-0201 (compass ping also failing) — root cause may be the same missing group registration or collision layer issue
- Check `ShatteredFlatsBiome` node instantiation against Rock Warrens/Debris Field for any missing collision or metadata setup steps

## Activity Log

- 2026-02-27 [producer] Created — Studio Head reported during final M8 playtest review
- 2026-02-27 [gameplay-programmer] Starting work — investigating scanner raycast collision layer/mask on Shattered Flats resource nodes
- 2026-02-27 [gameplay-programmer] DONE — Root cause: _create_deposit() never called DepositRegistry.register(), so scanner ping could not find/ping deposits and is_pinged() gate blocked analysis. Fix: added DepositRegistry.register(deposit) in _create_deposit(). Commit a5a0c53, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/169 (merged 6caddb7).
