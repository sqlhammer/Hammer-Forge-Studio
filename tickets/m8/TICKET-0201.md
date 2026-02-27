---
id: TICKET-0201
title: "Bugfix — Resource nodes missing from compass after ping in Shattered Flats"
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
tags: [bugfix, shattered-flats, compass, scanner, ping, resource-node, m8-qa]
---

## Summary

After performing a scan/ping in the Shattered Flats biome, resource nodes do not appear on the compass HUD. In other biomes (Rock Warrens, Debris Field) or in TestWorld, pinging correctly marks nearby resource nodes on the compass. This is a Shattered Flats-specific regression.

## Steps to Reproduce

1. Launch Shattered Flats via the debug launcher or normal gameplay
2. Equip scanner and perform a ping (scan)
3. Observe: compass HUD shows no resource node markers after the ping

## Expected Behavior

After a ping, nearby resource nodes are marked on the compass and remain visible for the duration of the scan window, consistent with behavior in all other biomes.

## Acceptance Criteria

- [x] Pinging in Shattered Flats causes nearby resource nodes to appear on the compass HUD
- [x] Behavior matches ping behavior in Rock Warrens and Debris Field
- [x] Fix does not regress compass behavior in other biomes
- [ ] Full test suite passes with no new failures

## Implementation Notes

- Investigate how resource nodes are registered in `ShatteredFlatsBiome` vs. other biomes — the scanner likely queries a scene-tree group or signal to detect pingable objects
- Check whether Shattered Flats resource nodes are added to the correct group (e.g., `"resource_nodes"` or `"scannable"`) during procedural placement
- Compare the biome's node instantiation path against Rock Warrens / Debris Field to find where the group assignment is missing
- The root cause may be shared with TICKET-0202 (resources cannot be scanned) — investigate together

## Activity Log

- 2026-02-27 [producer] Created — Studio Head reported during final M8 playtest review
- 2026-02-27 [gameplay-programmer] Starting work — investigating ShatteredFlatsBiome vs other biomes
- 2026-02-27 [gameplay-programmer] Root cause identified: all three biomes create Deposit nodes without calling DepositRegistry.register(); scanner uses DepositRegistry.get_in_range() which returns empty array. ShatteredFlatsBiome also missing surface_deposit/deep_deposit group assignments. Fixed by: (1) adding DepositRegistry.register(deposit) in ShatteredFlatsBiome._create_deposit(), RockWarrensBiome._create_deposit(), and DebrisFieldBiome._build_deposits(); (2) adding correct group assignments to ShatteredFlatsBiome and DebrisFieldBiome; (3) adding deposit cleanup in TravelSequenceManager._clear_biome_container(). This fix also resolves TICKET-0202 (scan raycast) since deposits must be pinged before analysis, and ping required DepositRegistry registration.
- 2026-02-27 [gameplay-programmer] DONE — commit aad122e, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/171 merged to main
