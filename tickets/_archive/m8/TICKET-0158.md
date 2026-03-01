---
id: TICKET-0158
title: "Fuel system — data layer, tank mechanics, consumption formula, low-fuel signal"
type: FEATURE
status: DONE
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

- [x] `FuelSystem` autoload or ship subsystem with:
  - `fuel_current: float` and `fuel_max: float` (tank capacity)
  - `consume_fuel(amount: float)` — deducts fuel, emits `fuel_changed` signal
  - `refuel(fuel_cells: int)` — converts Fuel Cells from inventory into fuel units
  - `calculate_cost(distance: float, ship_weight: float) -> float` — deterministic formula
  - `can_travel(distance: float, ship_weight: float) -> bool` — true if tank has enough fuel
  - `fuel_low` signal — fires when fuel drops below 25% capacity
  - `fuel_empty` signal — fires when fuel reaches 0
- [x] Ship weight calculation accounts for: installed module count (flat weight per module) + total inventory item count
- [x] Fuel Cell conversion rate defined (e.g., 1 Fuel Cell = N fuel units) and data-driven (not hardcoded)
- [x] Travel is blocked at the system level when `can_travel()` returns false — navigation system must check this
- [x] Unit tests cover: consumption formula, refuel from inventory, low-fuel threshold signal, empty signal, travel block when insufficient fuel, weight calculation
- [x] Full test suite passes

## Implementation Notes

- Distance between biomes is defined in the biome registry (TICKET-0159) — use a placeholder constant for testing until that ticket lands
- Ship weight formula should be simple and readable — avoid floating-point gotchas; use integer weights where possible
- Fuel Cell conversion rate must be tunable in a data file, not a magic number in code
- This ticket is data + logic only; the HUD gauge and warning display are in TICKET-0169

## Handoff Notes

FuelSystem autoload is registered in project.godot. Key API for downstream consumers:
- `FuelSystem.fuel_current` / `FuelSystem.fuel_max` — current and max fuel levels
- `FuelSystem.consume_fuel(amount)` — deduct fuel; emits fuel_changed, fuel_low, fuel_empty
- `FuelSystem.refuel(cells)` — consume N Fuel Cells from PlayerInventory; returns cells consumed
- `FuelSystem.calculate_cost(distance, weight)` — deterministic formula (distance * weight * 0.005)
- `FuelSystem.can_travel(distance, weight)` — returns bool; navigation MUST check before initiating travel
- `FuelSystem.calculate_ship_weight()` — module count * 10 + inventory item count
- `FuelSystemDefs.BIOME_DISTANCE_PLACEHOLDER` — 1000.0, replace with real distance when TICKET-0159 lands
- `FuelSystem.reset_to_full()` — new-game initialization and test setup

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase
- 2026-02-27 [systems-programmer] Starting work — implementing FuelSystem autoload, FuelSystemDefs data layer, ship weight formula, and full unit test suite
- 2026-02-27 [systems-programmer] DONE — commit 496edb8, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/134 (merged). Implemented FuelSystemDefs (game/scripts/data/fuel_system_defs.gd), FuelSystem autoload (game/scripts/systems/fuel_system.gd), registered in project.godot, 47 unit tests in test_fuel_system_unit.gd. GDScript UIDs pending Godot filesystem scan (no MCP access in this session; main branch is in TICKET-0160 worktree).
