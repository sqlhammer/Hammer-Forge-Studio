---
id: TICKET-0223
title: "Bugfix — Cryonite cannot be scanned and therefore cannot be mined"
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
tags: [bugfix, cryonite, scanner, scan, mining, resource-node, m8-qa]
---

## Summary

Cryonite deposit nodes cannot be scanned by the player's scanner. Aiming at a Cryonite node and activating the scanner produces no result, meaning the deposit cannot be analyzed and is therefore unmineable. Other deposit types scan correctly.

## Steps to Reproduce

1. Launch any biome containing Cryonite deposits
2. Equip the scanner
3. Aim at a Cryonite node and activate the scanner
4. Observe: no scan result is produced; the node is not identified and cannot be mined

## Expected Behavior

Aiming the scanner at a Cryonite deposit and activating it produces a scan result identifying the node, enabling it to be analyzed and mined, consistent with all other deposit types.

## Acceptance Criteria

- [x] Scanner successfully scans and analyzes Cryonite deposit nodes
- [x] Analyzed Cryonite nodes can be mined normally
- [x] Fix does not regress scanning of other deposit types
- [x] Full test suite passes with no new failures

## Implementation Notes

- Likely shares the same root cause as TICKET-0221 (Cryonite missing from compass): Cryonite nodes may not be calling `DepositRegistry.register()` on instantiation, and/or may be missing the correct collision layer/mask for the scanner raycast
- Check `deposit_deep_cryonite.tscn` and any surface Cryonite scene variants: confirm collision shapes are active, collision layers match the scanner's raycast mask, and `DepositRegistry.register()` is called in `_ready()` or during biome placement
- Investigate together with TICKET-0221 — a single fix may resolve both

## Activity Log

- 2026-02-28 [producer] Created — Studio Head reported during M8 playtest
- 2026-02-28 [gameplay-programmer] Starting work — investigation complete, implementing fix
- 2026-02-28 [gameplay-programmer] DONE — commit 767f557, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/190 (merged). Fix: (1) deposit_deep_cryonite.tscn collision_layer overridden from 4 (ENVIRONMENT) to 8 (INTERACTABLE); (2) rock_warrens_biome.gd _create_deposit() now adds InteractBody child with INTERACTABLE collision layer, matching Shattered Flats and Debris Field patterns. Note: base deposit.tscn still has collision_layer=4 (ENVIRONMENT) which affects all scene-instanced deposits — not fixed here as .tscn files are not used at runtime (all biomes create deposits programmatically). The primary root cause for Cryonite scanning failure was the missing InteractBody in Rock Warrens.
