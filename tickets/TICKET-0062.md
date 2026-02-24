---
id: TICKET-0062
title: "Spare Battery — item data layer"
type: FEATURE
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0073]
tags: [spare-battery, inventory, player-suit, data]
---

## Summary
Define the Spare Battery as a carriable inventory item. A Spare Battery occupies inventory slots, is crafted at the Fabricator, and can be used in the field to recharge the player's suit battery — extending field time without returning to the ship. Single-use: depletes fully on use. Implements deferred item D-011.

## Acceptance Criteria
- [ ] `SpareBattery` item resource defined and registered in the item catalog
- [ ] Item properties: stack size of 1 (each battery occupies its own slot), carriable, consumable (single-use)
- [ ] `use()` method defined: restores suit battery to 100%, marks item as consumed, removes from inventory
- [ ] Item integrates with existing Inventory system (M3) without modification to Inventory core
- [ ] Fabricator recipe registered: placeholder cost of 10 Metal per battery (confirm with Studio Head)
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Reference `docs/design/systems/player-suit.md` and deferred item D-011 in `docs/studio/deferred-items.md`
- Stack size 1 is intentional — spare batteries are bulky field equipment, not stackable consumables
- The use mechanic (TICKET-0073) depends on this data layer
- Recipe cost of 10 Metal is a placeholder — adjust during QA balance pass if needed

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket
- 2026-02-24 [systems-programmer] Started implementation
- 2026-02-24 [systems-programmer] Added SPARE_BATTERY to ResourceDefs enum and catalog (stack_size=1, consumable). Created SpareBattery class (scripts/systems/spare_battery.gd) with static use() method. Recipe constants defined for Fabricator integration.
