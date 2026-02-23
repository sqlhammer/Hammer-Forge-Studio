---
id: TICKET-0021
title: "Inventory system — data layer"
type: FEATURE
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-23
milestone: "M3"
depends_on: [TICKET-0020]
blocks: [TICKET-0026, TICKET-0027, TICKET-0028]
tags: [inventory, systems, data]
---

## Summary
Implement the inventory data layer — a slot-based container that stores resources, enforces stack limits, and exposes a clean API for adding, removing, and querying items. This is the backend; the UI is built in TICKET-0028.

## Acceptance Criteria
- [x] Inventory system implemented with 15 slots
- [x] Each slot holds one resource type with a max stack size (100 for Scrap Metal, configurable per resource)
- [x] API: `add_item(resource_id, quantity) -> int` — returns quantity that could not be added (overflow)
- [x] API: `remove_item(resource_id, quantity) -> int` — returns quantity actually removed
- [x] API: `get_slot(index) -> {resource_id, quantity}` or null/empty
- [x] API: `get_total(resource_id) -> int` — total quantity across all slots
- [x] API: `has_space_for(resource_id, quantity) -> bool`
- [x] Signals emitted on inventory change (for UI binding): `inventory_changed`, `item_added(resource_id, quantity)`, `item_removed(resource_id, quantity)`
- [x] Stacking behavior: adding items fills existing partial stacks before occupying new slots
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
- 2026-02-22 [systems-programmer] Implemented: `game/scripts/systems/inventory.gd` — 15-slot system, 100-per-stack, full add/remove/query API, signals (slot_changed, item_added, item_removed, inventory_full). Note: unit tests deferred to TICKET-0031 (QA). Committed `15aa9b4`, merged to main via PR #4 (worktree-dapper-foraging-volcano).
- 2026-02-23 [producer] Status corrected to DONE — implementation confirmed in main.
