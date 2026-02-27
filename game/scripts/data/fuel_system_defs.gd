## Canonical data definitions for the ship fuel system.
## All tunable fuel constants live here — nothing is hardcoded in FuelSystem logic.
## Ticket: TICKET-0158
class_name FuelSystemDefs
extends RefCounted

# ── Constants ─────────────────────────────────────────────

## Maximum fuel the ship tank can hold, in fuel units.
const FUEL_TANK_CAPACITY: float = 1000.0

## Fuel units provided by a single Fuel Cell when refueling.
## Tune this to adjust how many jumps a stack of Fuel Cells covers.
const FUEL_CELL_UNITS: float = 100.0

## Fraction of max fuel at or below which the low-fuel signal fires (25%).
const LOW_FUEL_THRESHOLD_PERCENT: float = 0.25

## Fuel cost multiplier: fuel units per weight unit per distance unit.
## Formula: cost = distance * ship_weight * FUEL_COST_MULTIPLIER
## With default values: 1000 distance * 50 weight * 0.005 = 250 fuel per jump.
const FUEL_COST_MULTIPLIER: float = 0.005

## Weight units contributed by each installed ship module.
const WEIGHT_PER_MODULE: int = 10

## Weight units contributed by each item in the player inventory.
## Each individual inventory item (not each slot) counts as one weight unit.
const WEIGHT_PER_INVENTORY_ITEM: int = 1

## Placeholder biome travel distance used for testing and dev until the biome
## registry (TICKET-0159) defines real distances.
const BIOME_DISTANCE_PLACEHOLDER: float = 1000.0
