---
id: TICKET-0158
title: "Fuel system — data layer, tank mechanics, consumption formula, low-fuel signal"
type: FEATURE
status: IN_PROGRESS
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Foundation"
depends_on: [TICKET-0157]
blocks: []
tags: [fuel, ship, data-layer, consumption, m8-foundation]
---

## Summary

Implement the ship fuel system as a data layer and signal bus. The ship has a fuel tank with a defined capacity. Fuel is consumed per jump based on distance between biomes and current ship weight (inventory + installed modules). A low-fuel signal fires when the tank drops below a threshold, enabling HUD warnings and blocking travel when empty.

## Acceptance Criteria

- [ ] `FuelSystem` autoload or ship subsystem with:
  - `fuel_current: float` and `fuel_max: float` (tank capacity)
  - `consume_fuel(amount: float)` — deducts fuel, emits `fuel_changed` signal
  - `refuel(fuel_cells: int)` — converts Fuel Cells from inventory into fuel units
  - `calculate_cost(distance: float, ship_weight: float) -> float` — deterministic formula
  - `can_travel(distance: float, ship_weight: float) -> bool` — true if tank has enough fuel
  - `fuel_low` signal — fires when fuel drops below 25% capacity
  - `fuel_empty` signal — fires when fuel reaches 0
- [ ] Ship weight calculation accounts for: installed module count (flat weight per module) + total inventory item count
- [ ] Fuel Cell conversion rate defined (e.g., 1 Fuel Cell = N fuel units) and data-driven (not hardcoded)
- [ ] Travel is blocked at the system level when `can_travel()` returns false — navigation system must check this
- [ ] Unit tests cover: consumption formula, refuel from inventory, low-fuel threshold signal, empty signal, travel block when insufficient fuel, weight calculation
- [ ] Full test suite passes

## Implementation Notes

- Distance between biomes is defined in the biome registry (TICKET-0159) — use a placeholder constant for testing until that ticket lands
- Ship weight formula should be simple and readable — avoid floating-point gotchas; use integer weights where possible
- Fuel Cell conversion rate must be tunable in a data file, not a magic number in code
- This ticket is data + logic only; the HUD gauge and warning display are in TICKET-0169

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase
- 2026-02-27 [systems-programmer] Starting work — implementing FuelSystem autoload, FuelSystemDefs data layer, ship weight formula, and full unit test suite
