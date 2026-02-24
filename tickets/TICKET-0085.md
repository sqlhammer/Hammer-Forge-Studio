---
id: TICKET-0085
title: "Bugfix — AutomationHubPanel pool stats measure distance from world origin"
type: BUGFIX
status: DONE
priority: P2
owner: gameplay-programmer
created_by: systems-programmer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, automation-hub, ui]
---

## Summary
`automation_hub_panel.gd:_refresh_pool_stats()` calculates the "Matching Program" deposit count by measuring distance from `Vector3.ZERO` instead of the actual ship/hub position. When the ship is not at world origin, the displayed count will be incorrect — it may show deposits as "in range" that are physically unreachable, or exclude deposits that are valid targets.

## Reproduction
1. Place the ship at any non-origin position in the world (the test world ship is not at Vector3.ZERO)
2. Open the Automation Hub panel
3. Observe the "Matching Program: N" count in the pool stats label
4. Compare against actual deposits that fall within the extraction radius centered on the ship

## Root Cause
In `_refresh_pool_stats()`:
```gdscript
var dist: float = Vector3.ZERO.distance_to(deposit.global_position)
if dist <= _extraction_radius:
    matching_count += 1
```
Should use the AutomationHub's home position (the ship's global position) as the center, consistent with how `DroneManager._assign_next_target()` calls `DepositRegistry.get_in_range(_home_position, ...)`.

## Fix
Replace `Vector3.ZERO` with the ship/hub position. The panel does not have direct access to the ship node, but can call `DepositRegistry.get_in_range(ship_position, _extraction_radius)` or use the hub node's global position. The simplest fix is to pass the AutomationHub or ship position reference into `_refresh_pool_stats()`, or use a sentinel position from the test world (similar to how `DroneManager` receives `home_position` via `setup()`).

## Acceptance Criteria
- [ ] "Matching Program" count reflects deposits within `_extraction_radius` of the actual ship/hub position
- [ ] Functional drone deployment is unaffected (this was display-only)
- [ ] No new warnings introduced

## Activity Log
- 2026-02-24 [systems-programmer] Created during M5 code review (TICKET-0075). Display-only bug; drone deployment logic is correct.
- 2026-02-25 [gameplay-programmer] DONE — commit 0549179, PR #52 merged. Added setup(hub_position) method; replaced Vector3.ZERO with _hub_position in _refresh_pool_stats().
