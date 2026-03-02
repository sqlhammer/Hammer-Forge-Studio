## Ship fuel system autoload: manages the fuel tank, consumption on travel,
## refueling from inventory Fuel Cells, and travel feasibility checks.
## Emits fuel_changed on any fuel change, fuel_low when crossing below 25% capacity,
## and fuel_empty when the tank reaches zero.
## Ticket: TICKET-0158
class_name FuelSystemType
extends Node

# ── Signals ──────────────────────────────────────────────
## Emitted whenever fuel_current changes (consume or refuel).
signal fuel_changed(current: float, maximum: float)
## Emitted once when fuel first drops to or below 25% of max capacity.
## Resets when fuel rises above the threshold (e.g. after refueling).
signal fuel_low
## Emitted once when fuel first reaches exactly zero.
## Resets when fuel rises above zero (e.g. after refueling).
signal fuel_empty

# ── Exported Variables ────────────────────────────────────
## Maximum tank capacity. Set from FuelSystemDefs so it can be overridden in editor.
@export var fuel_max: float = FuelSystemDefs.FUEL_TANK_CAPACITY

# ── Private Variables ─────────────────────────────────────
var _fuel_current: float = 0.0
## Tracks whether the fuel_low signal has already been emitted for the current
## below-threshold period. Reset when fuel rises above threshold.
var _low_signal_emitted: bool = false
## Tracks whether the fuel_empty signal has already been emitted for the current
## empty period. Reset when fuel rises above zero.
var _empty_signal_emitted: bool = false

# ── Public Variables ──────────────────────────────────────
## Current fuel level. Read-only externally — mutate via consume_fuel / refuel.
var fuel_current: float:
	get:
		return _fuel_current

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	_fuel_current = fuel_max
	Global.debug_log("FuelSystem: initialized (fuel=%.1f/%.1f)" % [_fuel_current, fuel_max])

# ── Public Methods ────────────────────────────────────────

## Deducts fuel from the tank by the given amount. Clamps to zero.
## Emits fuel_changed every call.
## Emits fuel_low (once per threshold crossing) when fuel drops to ≤25% capacity.
## Emits fuel_empty (once per depletion) when fuel reaches 0.
func consume_fuel(amount: float) -> void:
	if amount <= 0.0:
		return
	var threshold: float = fuel_max * FuelSystemDefs.LOW_FUEL_THRESHOLD_PERCENT
	_fuel_current = maxf(_fuel_current - amount, 0.0)
	fuel_changed.emit(_fuel_current, fuel_max)
	Global.debug_log("FuelSystem: consumed %.1f fuel (current=%.1f/%.1f)" % [
		amount, _fuel_current, fuel_max])
	if _fuel_current <= threshold and not _low_signal_emitted:
		_low_signal_emitted = true
		fuel_low.emit()
		Global.debug_log("FuelSystem: LOW FUEL — %.1f/%.1f (%.0f%%)" % [
			_fuel_current, fuel_max, _fuel_current / fuel_max * 100.0])
	if _fuel_current <= 0.0 and not _empty_signal_emitted:
		_empty_signal_emitted = true
		fuel_empty.emit()
		Global.debug_log("FuelSystem: FUEL EMPTY — tank depleted")

## Converts up to fuel_cells Fuel Cells from the player inventory into fuel units.
## Removes consumed Fuel Cells from PlayerInventory.
## Does not exceed tank capacity.
## Returns the number of Fuel Cells actually consumed.
func refuel(fuel_cells: int) -> int:
	if fuel_cells <= 0:
		return 0
	var available: int = PlayerInventory.get_total_count(ResourceDefs.ResourceType.FUEL_CELL)
	var to_consume: int = mini(fuel_cells, available)
	if to_consume <= 0:
		Global.debug_log("FuelSystem: refuel requested but no Fuel Cells in inventory")
		return 0
	# Calculate how many cells are actually needed to fill the tank
	var space_remaining: float = fuel_max - _fuel_current
	if space_remaining <= 0.0:
		Global.debug_log("FuelSystem: refuel skipped — tank already full")
		return 0
	var cells_needed_for_full: int = ceili(space_remaining / FuelSystemDefs.FUEL_CELL_UNITS)
	to_consume = mini(to_consume, cells_needed_for_full)
	# Remove cells from inventory (consume any purity, lowest first)
	var removed: int = _remove_fuel_cells(to_consume)
	if removed <= 0:
		return 0
	var fuel_gained: float = removed * FuelSystemDefs.FUEL_CELL_UNITS
	var previous_fuel: float = _fuel_current
	_fuel_current = minf(_fuel_current + fuel_gained, fuel_max)
	# Reset signal flags when fuel rises above thresholds
	var threshold: float = fuel_max * FuelSystemDefs.LOW_FUEL_THRESHOLD_PERCENT
	if _fuel_current > threshold:
		_low_signal_emitted = false
	if _fuel_current > 0.0:
		_empty_signal_emitted = false
	if _fuel_current != previous_fuel:
		fuel_changed.emit(_fuel_current, fuel_max)
	Global.debug_log("FuelSystem: refueled %d Fuel Cells (+%.1f fuel) (current=%.1f/%.1f)" % [
		removed, fuel_gained, _fuel_current, fuel_max])
	return removed

## Calculates the fuel cost for a jump of the given distance with the given ship weight.
## Formula: distance * ship_weight * FuelSystemDefs.FUEL_COST_MULTIPLIER
func calculate_cost(distance: float, ship_weight: float) -> float:
	return distance * ship_weight * FuelSystemDefs.FUEL_COST_MULTIPLIER

## Returns true if the current tank has enough fuel to make the jump.
## distance and ship_weight are used to compute the cost via calculate_cost.
func can_travel(distance: float, ship_weight: float) -> bool:
	var cost: float = calculate_cost(distance, ship_weight)
	return _fuel_current >= cost

## Calculates the current total ship weight.
## Weight = BASE_SHIP_WEIGHT + (installed module count * WEIGHT_PER_MODULE) + (total inventory item count * WEIGHT_PER_INVENTORY_ITEM)
func calculate_ship_weight() -> int:
	var module_weight: int = ModuleManager.get_installed_count() * FuelSystemDefs.WEIGHT_PER_MODULE
	var inventory_weight: int = _get_total_inventory_items() * FuelSystemDefs.WEIGHT_PER_INVENTORY_ITEM
	return FuelSystemDefs.BASE_SHIP_WEIGHT + module_weight + inventory_weight

## Resets fuel to maximum capacity. Clears signal-emitted flags.
## Used for new-game initialization and test teardown.
func reset_to_full() -> void:
	_fuel_current = fuel_max
	_low_signal_emitted = false
	_empty_signal_emitted = false
	fuel_changed.emit(_fuel_current, fuel_max)
	Global.debug_log("FuelSystem: reset to full (%.1f/%.1f)" % [_fuel_current, fuel_max])

# ── Private Methods ───────────────────────────────────────

## Returns the total count of all items across all non-NONE resource types in inventory.
func _get_total_inventory_items() -> int:
	var total: int = 0
	for resource_type_value: int in ResourceDefs.ResourceType.values():
		var resource_type: ResourceDefs.ResourceType = resource_type_value as ResourceDefs.ResourceType
		if resource_type == ResourceDefs.ResourceType.NONE:
			continue
		total += PlayerInventory.get_total_count(resource_type)
	return total

## Removes a specified number of Fuel Cells from inventory, consuming lowest purity first.
## Returns the quantity actually removed.
func _remove_fuel_cells(quantity: int) -> int:
	var remaining: int = quantity
	for purity_value: int in ResourceDefs.Purity.values():
		if remaining <= 0:
			break
		var purity: ResourceDefs.Purity = purity_value as ResourceDefs.Purity
		var available: int = PlayerInventory.get_count(ResourceDefs.ResourceType.FUEL_CELL, purity)
		if available > 0:
			var to_remove: int = mini(remaining, available)
			var removed: int = PlayerInventory.remove_item(
				ResourceDefs.ResourceType.FUEL_CELL, purity, to_remove)
			remaining -= removed
	return quantity - remaining
