---
id: TICKET-0178
title: "QA testing — M8 full loop"
type: TASK
status: PENDING
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "QA"
depends_on: [TICKET-0177]
blocks: []
tags: [qa, testing, full-loop, m8-qa]
---

## Summary

Full-loop QA pass for M8. Covers all new systems end-to-end, regression validation against prior milestones, and Studio Head sign-off preparation.

## Acceptance Criteria

- [ ] Full test suite passes with zero failures
- [ ] Manual full loop verified:
  - Player spawns in starting biome, mines Scrap Metal and Cryonite
  - Crafts Fuel Cells at Fabricator
  - Navigates to all three biomes via navigation console
  - Resource nodes respawn correctly after biome change and return
  - Deep nodes mine indefinitely without depleting
  - Drones assigned to deep nodes and confirmed mining
  - Fuel gauge HUD updates correctly throughout
  - Player jump functions in first-person and third-person
  - Headlamp toggle shown in controls panel when equipped
  - Mouse interaction works across inventory, machine builder, tech tree
  - Debug scene: biome selector and begin-wealthy toggle function correctly
- [ ] No P1 or P2 bugs open at sign-off
- [ ] All prior milestone systems unaffected (M1–M7 regression clean)
- [ ] Test count and pass rate documented

## Implementation Notes

- Use the debug scene (TICKET-0180) to accelerate testing of fuel/navigation systems — begin wealthy to skip resource gathering
- Document any P3 findings in `docs/studio/deferred-items.md` for future milestones

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 QA phase
