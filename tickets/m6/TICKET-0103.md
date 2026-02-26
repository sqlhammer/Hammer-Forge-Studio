---
id: TICKET-0103
title: "BUGFIX: Suit recharge no longer triggers when near the ship"
type: BUGFIX
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M6"
phase: "Integration & QA"
depends_on: []
blocks: [TICKET-0102]
tags: [bug, suit, recharge, ship, proximity, battery]
---

## Summary

The suit battery recharge mechanic no longer activates when the player is in proximity to the ship. This was working in M4. The regression was discovered during M6 Integration & QA work and must be resolved before TICKET-0102 (QA sign-off) can close.

## Steps to Reproduce

1. Start the game and exit the ship on foot
2. Deplete suit battery (walk away from ship, use suit systems)
3. Return to ship proximity (within the recharge trigger radius)
4. **Expected:** Suit battery begins recharging
5. **Actual:** Suit battery does not recharge; no recharge indicator appears

## Acceptance Criteria

- [ ] Suit battery recharges when the player is within the ship's recharge trigger radius, matching pre-M4 behavior
- [ ] Recharge rate and threshold distance are unchanged from prior implementation
- [ ] No recharge occurs outside the trigger radius
- [ ] All existing `suit_battery` tests pass
- [ ] Full test suite passes with zero failures

## Investigation Notes

- Start in `game/scripts/systems/suit_battery.gd` — check if the proximity check or signal connection was broken
- The ship proximity trigger likely lives in `game/scenes/gameplay/` or a ship-related scene — verify the Area3D / collision shape is still present and connected
- Check git log on `suit_battery.gd` and any ship scene files since the last known-good commit (M4 close: `edb82f4` or earlier) for changes that may have broken the signal chain
- M6 icon integration (TICKET-0099–0100) touched several scenes — verify no scene edits accidentally removed or disconnected the recharge trigger node

## Activity Log

- 2026-02-25 [producer] Created bug ticket — regression reported during M6 Integration & QA
