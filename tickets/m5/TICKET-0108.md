---
id: TICKET-0108
title: "Bugfix — Energy recharge area too small to reach around scaled-up ship"
type: BUGFIX
status: TODO
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M5"
phase: "QA"
depends_on: [TICKET-0103]
blocks: []
tags: [bugfix, ship, energy, recharge, collision]
---

## Summary
The ship's suit energy recharge trigger area was not updated when the ship was scaled up in M5. As a result, the recharge zone does not extend far enough to cover the full perimeter of the larger ship, leaving portions of the ship's exterior where the player cannot recharge.

## Reproduction
1. Exit the ship and walk to the far sides or rear of the ship
2. Observe that the recharge indicator does not activate in those positions
3. Compare recharge coverage area against the ship's full footprint

## Expected Behavior
The player should be able to recharge their suit energy anywhere within a reasonable proximity to the ship, covering the full perimeter of the new larger scale.

## Fix
- Locate the energy recharge area node (likely an `Area3D` or `CollisionShape3D` on the ship scene)
- Scale or resize the collision shape to match the new ship dimensions
- Ensure coverage wraps the full ship footprint with appropriate margin
- Note: this ticket depends on TICKET-0103 (ship model restoration) — verify against the correct ship scale after that fix lands

## Acceptance Criteria
- [ ] Player can recharge suit energy when standing anywhere near the ship exterior (full perimeter)
- [ ] Recharge does not trigger at unreasonably large distances from the ship
- [ ] No regression on existing recharge behavior inside the ship

## Activity Log
- 2026-02-25 [producer] Created from UAT feedback. Recharge zone was not updated to match M5 ship scale-up. Depends on TICKET-0103 to establish correct ship scale first.
