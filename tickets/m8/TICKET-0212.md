---
id: TICKET-0212
title: "Bugfix — Cryonite cannot be scanned and therefore cannot be mined"
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
tags: [bugfix, cryonite, scanner, scan, mining, resource-node, m8-qa]
---

## Summary

Cryonite deposit nodes cannot be scanned by the player's scanner. Aiming at a Cryonite node and activating the scanner produces no result, meaning the deposit cannot be analyzed and is therefore unmineble. Other deposit types scan correctly.

## Steps to Reproduce

1. Launch any biome containing Cryonite deposits
2. Equip the scanner
3. Aim at a Cryonite node and activate the scanner
4. Observe: no scan result is produced; the node is not identified and cannot be mined

## Expected Behavior

Aiming the scanner at a Cryonite deposit and activating it produces a scan result identifying the node, enabling it to be analyzed and mined, consistent with all other deposit types.

## Acceptance Criteria

- [ ] Scanner successfully scans and analyzes Cryonite deposit nodes
- [ ] Analyzed Cryonite nodes can be mined normally
- [ ] Fix does not regress scanning of other deposit types
- [ ] Full test suite passes with no new failures

## Implementation Notes

- Likely shares the same root cause as TICKET-0210 (Cryonite missing from compass): Cryonite nodes may not be calling `DepositRegistry.register()` on instantiation, and/or may be missing the correct collision layer/mask for the scanner raycast
- Check `deposit_deep_cryonite.tscn` and any surface Cryonite scene variants: confirm collision shapes are active, collision layers match the scanner's raycast mask, and `DepositRegistry.register()` is called in `_ready()` or during biome placement
- Investigate together with TICKET-0210 — a single fix may resolve both

## Activity Log

- 2026-02-28 [producer] Created — Studio Head reported during M8 playtest
