---
id: TICKET-0215
title: "Bugfix — Compass rotates opposite to desired direction"
type: BUGFIX
status: IN_PROGRESS
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, compass, hud, navigation, m8-qa]
---

## Summary

The compass HUD scrolls in the wrong direction as the player turns. When the player rotates right, the compass scrolls right (cardinal labels move right) instead of scrolling left as expected on a standard compass. The result is that the compass reads as a mirror image of the correct bearing.

## Steps to Reproduce

1. Launch any biome
2. Face North and observe the compass
3. Rotate the player to the right (toward East)
4. Observe: the compass labels move right; East does not approach the center indicator from the right side as expected

## Expected Behavior

When the player turns right (clockwise), the compass scrolls left — East moves toward the center from the right, consistent with a standard compass rose. The center indicator always shows the direction the player is currently facing.

## Acceptance Criteria

- [ ] Turning right causes the compass to scroll left (East approaches center from the right)
- [ ] Turning left causes the compass to scroll right (West approaches center from the left)
- [ ] All cardinal labels (N, NE, E, SE, S, SW, W, NW) are in the correct order on the compass
- [ ] Ping markers move consistently with the corrected compass direction
- [ ] Full test suite passes with no new failures; update any tests asserting compass scroll direction

## Implementation Notes

- Root cause is likely in `CompassBar._bearing_to_screen_x()`: the `diff` calculation `bearing - player_yaw` produces a positive value when the bearing is clockwise of the player, mapping it to the right side of the screen — but a compass should show a clockwise bearing arriving from the right (i.e., a positive diff should map to screen left or the sign should be negated)
- Fix: negate the diff-to-screen_x mapping: `var screen_x: float = (COMPASS_WIDTH / 2.0) - (diff / fov_half) * (COMPASS_WIDTH / 2.0)` (change `+` to `-`)
- Verify the fix with all eight cardinal directions and with deposit ping markers

## Activity Log

- 2026-02-28 [producer] Created — Studio Head reported during M8 playtest
- 2026-02-28 [gameplay-programmer] IN_PROGRESS — Starting work
