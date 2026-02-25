---
id: TICKET-0105
title: "Bugfix — Player falls through world after exiting the ship"
type: BUGFIX
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M5"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, player, ship, collision, critical]
---

## Summary
When the player exits the ship, they fall through the world geometry and are lost. This is a critical regression that blocks all surface gameplay after disembarking.

## Reproduction
1. Start the game and board the ship
2. Use the ship exit mechanic to disembark
3. Observe that the player falls through the ground immediately after exit

## Root Cause (Suspected)
Likely one of:
- The player spawn/exit point is positioned below the world collision mesh
- The ship scale-up (M5) moved the exit point relative to the ground such that the exit position is now underground
- The world collision shape does not cover the area beneath the new ship exit position

## Fix
- Inspect the ship exit node position relative to ground level after the M5 scale change
- Adjust the exit spawn point so the player is placed on solid ground
- Verify that the ground/terrain collision shape covers the exit area
- If the ship was repositioned during M5, ensure exit points were updated accordingly

## Acceptance Criteria
- [ ] Player exits the ship and lands on the ground without falling
- [ ] Player is fully controllable immediately after exiting
- [ ] No regression for ship entry

## Activity Log
- 2026-02-25 [producer] Created from UAT feedback. Critical — blocks all surface gameplay post-disembark.
- 2026-02-25 [gameplay-programmer] DONE — moved exit position from Z=18 (inside hull collision) to Z=24 (outside hull), added velocity reset on exit teleport. Commit 9b6e53d, PR #53.
