---
id: TICKET-0160
title: "Deep resource node — data layer, infinite-yield flag, slow drill rate"
type: FEATURE
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Foundation"
depends_on: []
blocks: []
tags: [resource, deep-node, data-layer, drones, m8-foundation]
---

## Summary

Define the deep resource node as a new deposit subtype. Deep nodes reside just beneath some (not all) surface resource nodes. They yield resources much slower than surface nodes but have infinite supply — they never deplete. Automated drones can mine them indefinitely.

## Acceptance Criteria

- [x] Deep resource node defined as a deposit subtype (extends or variants the existing deposit data layer) with:
  - `infinite: true` flag — node never depletes
  - `yield_rate: float` — significantly slower than surface nodes (data-driven, not hardcoded)
  - `drone_accessible: true` — flagged as valid for automated drone assignment
  - Resource type (Scrap Metal or Cryonite — set per instance in scene)
- [x] Existing deposit system correctly handles `infinite` flag — does not reduce stock on yield
- [x] Drone system (from M5) correctly targets nodes with `drone_accessible: true`
- [x] Deep nodes do NOT respawn (they are already infinite — respawn logic in TICKET-0161 must skip them via `deposit.infinite` flag)
- [x] Unit tests cover: infinite flag prevents depletion, yield_rate slower than surface baseline, drone accessibility flag, respawn system skips infinite nodes
- [ ] Full test suite passes (pending QA run)

## Implementation Notes

- Deep nodes are placed in scenes by the biome tickets (TICKET-0170–0172) — this ticket is data layer only
- The physical scene node implementation (mesh, collision, depth placement) is in TICKET-0173
- Yield rate should be expressed as a multiplier on the base yield interval, e.g., `yield_rate = 0.1` means 10% speed of surface
- Do not create a new parallel system — extend the existing deposit/resource node architecture

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase
- 2026-02-27 [systems-programmer] Starting work — extending deposit data layer with infinite, yield_rate, drone_accessible flags
- 2026-02-27 [systems-programmer] DONE — commit d91e39c, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/126 merged to main. Extended Deposit with infinite/yield_rate/drone_accessible; updated DroneProgram.accepts_deposit(); implemented 25 unit tests in test_deep_resource_node_unit.gd.
