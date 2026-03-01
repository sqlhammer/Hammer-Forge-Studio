---
id: TICKET-0247
title: "BUG — Navigation console shows insufficient fuel despite full ship tank (unit mismatch)"
type: BUG
status: IN_PROGRESS
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "M8"
phase: "Bug Fix"
depends_on: []
blocks: []
tags: [navigation-console, fuel, bug, p1]
---

## Summary

The ship's fuel tank is full (1000 / 1000 units) but the navigation console reports the tank as containing only **10 Fuel Cell(s)** and blocks travel with "Not enough fuel — Need 7 more Fuel Cell(s)". The core navigation loop is completely broken: the player cannot travel to any biome regardless of fuel state.

## Steps to Reproduce

1. Launch the game (debug or normal).
2. Open the Navigation Console (E key).
3. Select Rock Warrens as destination (cost: 17 Fuel Cell(s)).
4. Observe the SHIP FUEL header: **1000 / 1000 units** (tank is full).
5. Scroll the detail panel to the Ship Tank row.
6. Observe: **Ship Tank: 10 Fuel Cell(s)** displayed in red/orange.
7. Console shows "⚠ Not enough fuel" and "Need 7 more Fuel Cell(s)".
8. CONFIRM TRAVEL button is disabled.

## Expected Behavior

A full tank (1000 / 1000 units) should satisfy any journey whose cost is ≤ the tank's fuel cell equivalent. With a full tank the player should be able to confirm travel to Rock Warrens (17 Fuel Cell(s)).

## Actual Behavior

The console converts 1000 fuel units → 10 fuel cells, then compares against the 17-cell journey cost, concluding 7 more cells are needed. Travel is blocked even though the tank is full.

## Root Cause (Hypothesis)

There is a unit mismatch in the fuel conversion logic inside the navigation console. The ship stores fuel as raw **units** (float, max 1000). The navigation console computes journey cost in **Fuel Cells** (items). The conversion between the two is almost certainly wrong — likely using the wrong divisor, comparing against a cell count instead of the raw unit value, or reading the wrong property from `ShipState`.

Likely locations to investigate:

- `game/scripts/ui/navigation_console.gd` — fuel display and travel validation logic
- `game/scripts/systems/ship_state.gd` — fuel unit storage and any fuel-cell conversion helpers
- `game/scripts/systems/navigation_system.gd` (if it exists) — travel cost calculation

Specific things to check:
1. What is the Fuel Cell → unit conversion ratio? (e.g., 1 cell = 100 units → full tank = 10 cells; that matches the observed "10 Fuel Cell(s)" display)
2. Is the travel-cost comparison done in cells or units? If cost is in cells and the check compares against raw units (1000) without converting, the display bug and the gate bug are separate issues.
3. Is there a hardcoded or stale constant standing in for the live fuel value?

## Acceptance Criteria

- [ ] With a full ship tank (1000 / 1000 units) the navigation console correctly represents available fuel in terms of fuel cells.
- [ ] CONFIRM TRAVEL is enabled when the ship has enough fuel to reach the selected destination.
- [ ] "Not enough fuel" warning and disabled button only appear when the tank genuinely cannot cover the journey cost.
- [ ] The fuel unit ↔ fuel cell conversion is consistent between the SHIP FUEL display and the Ship Tank row in the detail panel.
- [ ] Existing unit tests pass; new unit tests added for the fuel conversion and travel eligibility logic if not already covered.

## Hold Condition

**This ticket must remain OPEN until Studio Head sign-off.** Do not mark DONE without explicit Studio Head approval.

## Activity Log

- 2026-03-01 [producer] Created ticket — player-reported: ship fuel full (1000/1000) but navigation blocks travel claiming only 10 fuel cells available; need 7 more for Rock Warrens (cost 17)
- 2026-03-01 [gameplay-programmer] Starting work. Root cause identified: calculate_ship_weight() counts every inventory item as 1 weight unit with no base ship weight. In begin-wealthy mode (409 items), weight=409, cost to Rock Warrens=1636 units (17 cells), exceeding tank capacity (1000 units, 10 cells). Fix: add BASE_SHIP_WEIGHT=50, set WEIGHT_PER_INVENTORY_ITEM=0.
- 2026-03-01 [gameplay-programmer] Fix committed (894b37f), PR #210 merged. Status remains IN_PROGRESS — awaiting Studio Head sign-off per hold condition.
