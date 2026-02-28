---
id: TICKET-0221
title: "Bugfix — Cryonite nodes do not appear on compass when pinged"
type: BUGFIX
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, cryonite, compass, scanner, ping, resource-node, m8-qa]
---

## Summary

After performing a ping in a biome containing Cryonite nodes, those nodes do not appear on the compass HUD. Other resource types (Scrap Metal, etc.) appear correctly after a ping.

## Steps to Reproduce

1. Launch any biome that contains Cryonite deposits via the debug launcher or normal gameplay
2. Equip scanner and perform a ping (Q)
3. Observe: Cryonite nodes are absent from the compass HUD; other node types appear correctly

## Expected Behavior

Cryonite deposits appear on the compass after a ping, consistent with all other deposit types.

## Acceptance Criteria

- [x] Pinging in any biome causes nearby Cryonite nodes to appear on the compass HUD
- [x] Behavior is identical to Scrap Metal and other deposit types
- [x] Fix does not regress compass ping behavior for any other deposit type
- [x] Full test suite passes with no new failures

## Implementation Notes

- Check whether `deposit_deep_cryonite.tscn` and its surface Cryonite variants call `DepositRegistry.register()` during instantiation — the root cause of TICKET-0201 was missing `DepositRegistry.register()` calls; Cryonite nodes may have the same omission
- Verify Cryonite nodes are assigned the correct groups (e.g., `"scannable"`, `"resource_nodes"`) in all biomes that place them
- Cross-reference with TICKET-0223 (Cryonite cannot be scanned) — root cause is likely shared

## Activity Log

- 2026-02-28 [producer] Created — Studio Head reported during M8 playtest
- 2026-02-28 [gameplay-programmer] Starting work — investigating Cryonite compass visibility
- 2026-02-28 [gameplay-programmer] Root cause: CompassBar.MAX_MARKERS was 10 — biomes register scrap metal deposits (8-12) before cryonite (3-8), so the 10-marker cap fills with scrap before any cryonite is added. Fix: raised MAX_MARKERS from 10 to 30 to accommodate all deposit types across all biomes. Updated unit test to match.
- 2026-02-28 [gameplay-programmer] DONE — commit 4443323, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/186 merged to main
