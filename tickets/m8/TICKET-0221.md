---
id: TICKET-0221
title: "Bugfix — Cryonite nodes do not appear on compass when pinged"
type: BUGFIX
status: OPEN
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

- [ ] Pinging in any biome causes nearby Cryonite nodes to appear on the compass HUD
- [ ] Behavior is identical to Scrap Metal and other deposit types
- [ ] Fix does not regress compass ping behavior for any other deposit type
- [ ] Full test suite passes with no new failures

## Implementation Notes

- Check whether `deposit_deep_cryonite.tscn` and its surface Cryonite variants call `DepositRegistry.register()` during instantiation — the root cause of TICKET-0201 was missing `DepositRegistry.register()` calls; Cryonite nodes may have the same omission
- Verify Cryonite nodes are assigned the correct groups (e.g., `"scannable"`, `"resource_nodes"`) in all biomes that place them
- Cross-reference with TICKET-0223 (Cryonite cannot be scanned) — root cause is likely shared

## Activity Log

- 2026-02-28 [producer] Created — Studio Head reported during M8 playtest
