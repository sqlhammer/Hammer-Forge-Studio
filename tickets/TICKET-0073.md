---
id: TICKET-0073
title: "Spare Battery — field carry and use mechanic"
type: FEATURE
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Gameplay"
depends_on: [TICKET-0062, TICKET-0083]
blocks: [TICKET-0075]
tags: [spare-battery, gameplay, player-suit, inventory]
---

## Summary
Implement the player-facing mechanic for carrying and using Spare Batteries in the field. Spare Batteries are crafted at the Fabricator (TICKET-0069), stored in inventory slots, and used by the player to restore suit battery charge to 100% without returning to the ship. Single-use — depletes on use. Implements deferred item D-011.

## Acceptance Criteria
- [ ] Spare Battery item appears in player inventory after being crafted at the Fabricator
- [ ] Player can use a Spare Battery from inventory (input binding consistent with other item use actions)
- [ ] On use: suit battery restored to 100%, Spare Battery removed from inventory
- [ ] Spare Battery cannot be used if suit battery is already at 100% (with appropriate feedback message)
- [ ] Item is not usable while the player is inside the ship (suit is auto-charging — no need for battery)
- [ ] Pickup notification displayed on use confirming recharge
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Reference TICKET-0062 for the item data layer and `use()` method
- Reference deferred item D-011 in `docs/studio/deferred-items.md`
- The use input binding should be consistent with how other consumable items would be used — check with M3 inventory UI conventions for the right UX pattern
- This mechanic can be implemented and tested independently of the Fabricator (give item directly in debug/test setup)

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket
- 2026-02-25 [gameplay-programmer] DONE — commit f05d446, PR #40 merged. Added use_item action (G key), field use validation (not in ship, not full, has battery), toast notifications.
