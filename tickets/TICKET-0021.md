---
id: TICKET-0021
title: "Inventory system — data layer"
type: FEATURE
status: OPEN
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M3"
depends_on: [TICKET-0020]
blocks: [TICKET-0026, TICKET-0027, TICKET-0028]
tags: [inventory, systems, data]
---

## Summary
Implement the inventory data layer — a slot-based container that stores resources, enforces stack limits, and exposes a clean API for adding, removing, and querying items. This is the backend; the UI is built in TICKET-0028.

## Acceptance Criteria
- [ ] Inventory system implemented with 15 slots
- [ ] Each slot holds one resource type with a max stack size (100 for Scrap Metal, configurable per resource)
- [ ] API: `add_item(resource_id, quantity) -> int` — returns quantity that could not be added (overflow)
- [ ] API: `remove_item(resource_id, quantity) -> int` — returns quantity actually removed
- [ ] API: `get_slot(index) -> {resource_id, quantity}` or null/empty
- [ ] API: `get_total(resource_id) -> int` — total quantity across all slots
- [ ] API: `has_space_for(resource_id, quantity) -> bool`
- [ ] Signals emitted on inventory change (for UI binding): `inventory_changed`, `item_added(resource_id, quantity)`, `item_removed(resource_id, quantity)`
- [ ] Stacking behavior: adding items fills existing partial stacks before occupying new slots
- [ ] Unit tests written and passing for all API methods and edge cases (full inventory, overflow, empty slots)

## Implementation Notes
- Reference TICKET-0020 for resource data definitions
- Consider implementing as an autoload or as a component attached to the player — architect's choice, document rationale
- The inventory is player-scoped in M3 (no ship cargo, no containers)
- Signal-based updates enable decoupled UI binding in TICKET-0028
- Reference `docs/engineering/coding-standards.md` for naming conventions

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-22 [producer] Created ticket
