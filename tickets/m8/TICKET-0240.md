---
id: TICKET-0240
title: "Feature — Nav console: load fuel cells into ship tank to enable multi-trip refueling"
type: FEATURE
status: TODO
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [feature, navigation-console, fuel-system, refueling, soft-lock, m8-qa]
---

## Summary

The ship has a fuel tank (`FuelSystem`) that is consumed on every biome jump. Once depleted, the player is permanently unable to travel — no refueling mechanism exists in the UI. The `FuelSystem.refuel()` method is implemented but never wired to any player-facing control. This is a soft-lock: a player who has exhausted their tank cannot progress regardless of how many Fuel Cells they craft.

The fix is a "Load Fuel Cells" section in the navigation console that lets the player transfer Fuel Cells from their personal inventory into the ship's tank. Because inventory capacity is limited to 15 slots and a full tank requires up to 10 Fuel Cells (plus the player likely holds other resources), this must support incremental loading over multiple trips — craft cells, load them, repeat until the tank holds enough to travel.

## Root Cause

`FuelSystem._ready()` initializes `_fuel_current = fuel_max` (1000/1000). Travel consumes from this tank via `FuelSystem.consume_fuel(cost)`. After enough jumps the tank drops below the travel cost threshold and `NavigationSystem.can_travel_to()` returns `false`.

`FuelSystem.refuel(cells: int)` already exists and correctly transfers Fuel Cells from `PlayerInventory` to the tank, but it is called from nowhere. The nav console has no button, section, or affordance that invokes it.

The detail panel's "Your Fuel" label (`navigation_console.gd:604-608`) reads `FuelSystem.fuel_current` (the tank) and presents it in Fuel Cell equivalents, but there is no way for the player to increase that value.

## Design

### Nav console changes

Add a **"SHIP FUEL"** section above the destination detail rows, visible whenever the panel is open (not only when a destination is selected). It should show:

| Element | Content |
|---|---|
| Section header | `SHIP FUEL` |
| Tank level | `X / Y units` (e.g., `350 / 1000 units`) |
| Inventory cells | `Cells in backpack: N` |
| Load button | `LOAD FUEL CELLS` (disabled if inventory has 0 cells or tank is already full) |
| Status label | Feedback after loading (e.g., "Loaded 3 cells (+300 units)") or idle |

**Load behavior:**
- Button press calls `FuelSystem.refuel(PlayerInventory.get_total_count(FUEL_CELL))`
- `refuel()` already clamps to tank capacity and removes only the cells it needs — no additional guard logic required
- After loading, refresh the tank display and inventory count
- The sufficiency/confirm-button state in the destination detail panel already reacts to `FuelSystem.fuel_changed` (connected at `navigation_console.gd:514`) — no extra wiring needed there

**Label rename:**
"Your Fuel" in the destination detail panel is ambiguous now that the ship tank and player inventory are two distinct things. Rename the label to **"Ship Tank"** to clarify what is being compared against the travel cost.

### No backend changes required

`FuelSystem.refuel()`, `FuelSystem.fuel_current`, `FuelSystem.fuel_max`, `FuelSystem.fuel_changed`, and `PlayerInventory.get_total_count()` are all sufficient for this feature. Do not modify `fuel_system.gd` or `fuel_system_defs.gd`.

### Scope boundary

Do not implement a quantity picker or partial-load slider in this ticket. "Load all" (transfer everything currently in inventory) is the correct UX — the player controls how many cells they carry per trip. A partial-load control adds complexity without benefit given the 15-slot inventory constraint.

## Acceptance Criteria

- [ ] Navigation console shows a "SHIP FUEL" section with tank level (units) and current inventory Fuel Cell count, visible on open regardless of destination selection
- [ ] "LOAD FUEL CELLS" button transfers all Fuel Cells from player inventory to the ship tank via `FuelSystem.refuel()`
- [ ] Button is disabled when player has 0 Fuel Cells in inventory or the tank is already full
- [ ] Tank level display and inventory count update immediately after loading (reactive to `FuelSystem.fuel_changed`)
- [ ] Destination detail "Your Fuel" label is renamed to "Ship Tank"
- [ ] A player starting with an empty tank can load cells across multiple console visits (each trip: collect/craft cells → board ship → open console → load → repeat) until tank holds enough fuel to travel
- [ ] CONFIRM TRAVEL enables correctly once tank ≥ travel cost (existing logic, no change needed)
- [ ] Full test suite passes with no new failures

## Gameplay Validation

To verify the full loop in-game (debug session, begin-wealthy):

1. Launch Shattered Flats
2. Open `FuelSystem` via console or inspection — confirm tank starts at 1000/1000
3. Board ship, open nav console, confirm fuel cells in backpack count is correct
4. Drain tank: travel to Rock Warrens → travel back → repeat until tank < cost
5. Confirm CONFIRM TRAVEL is disabled with "Need X more Fuel Cell(s)"
6. Craft Fuel Cells (Metal + Cryonite in Fabricator)
7. Board ship → open nav console → press LOAD FUEL CELLS → confirm tank increases, cells removed from inventory
8. Repeat steps 6–7 until tank ≥ cost
9. Confirm CONFIRM TRAVEL enables and travel succeeds

## Activity Log

- 2026-03-01 [producer] Created — Studio Head identified soft-lock: no refueling UI; `FuelSystem.refuel()` exists but is never called; nav console does not expose fuel loading to the player
