## Manages the player suit's battery: charge, drain, recharge, and depletion penalties.
class_name SuitBatteryType
extends Node

# ── Signals ──────────────────────────────────────────────
signal charge_changed(current: float, maximum: float)
signal battery_depleted
signal battery_recharged

# ── Constants ─────────────────────────────────────────────
const MOVEMENT_PENALTY: float = 0.25
const RECHARGE_RATE: float = 50.0  # units per second at ship recharge point

## Base energy drain per unit mined, per deposit tier.
const DRAIN_RATES_PER_TIER: Dictionary = {
	ResourceDefs.DepositTier.TIER_1: 2.0,
	ResourceDefs.DepositTier.TIER_2: 4.0,
	ResourceDefs.DepositTier.TIER_3: 7.0,
	ResourceDefs.DepositTier.TIER_4: 12.0,
}

# ── Exported Variables ────────────────────────────────────
@export var max_charge: float = 100.0

# ── Private Variables ─────────────────────────────────────
var _current_charge: float = 0.0
var _is_recharging: bool = false

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	_current_charge = max_charge

# ── Public Methods ────────────────────────────────────────

## Returns the current charge level.
func get_charge() -> float:
	return _current_charge

## Returns charge as a 0.0–1.0 percentage.
func get_charge_percent() -> float:
	if max_charge <= 0.0:
		return 0.0
	return _current_charge / max_charge

## Returns true when battery is at zero.
func is_depleted() -> bool:
	return _current_charge <= 0.0

## Returns the movement speed multiplier (1.0 normal, 0.75 when depleted).
func get_movement_multiplier() -> float:
	if is_depleted():
		return 1.0 - MOVEMENT_PENALTY
	return 1.0

## Drains a flat amount of charge. Returns the actual amount drained.
func drain(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var actual_drain: float = minf(amount, _current_charge)
	_current_charge = maxf(_current_charge - amount, 0.0)
	charge_changed.emit(_current_charge, max_charge)
	if is_depleted() and actual_drain > 0.0:
		battery_depleted.emit()
	return actual_drain

## Drains energy for mining one unit at the given deposit tier.
func drain_for_mining(tier: ResourceDefs.DepositTier) -> float:
	var rate: float = DRAIN_RATES_PER_TIER.get(tier, 2.0)
	return drain(rate)

## Returns the energy cost to mine a given quantity at a deposit tier.
func estimate_mining_cost(tier: ResourceDefs.DepositTier, quantity: int) -> float:
	var rate: float = DRAIN_RATES_PER_TIER.get(tier, 2.0)
	return rate * quantity

## Returns true if there is enough charge to mine one unit at the tier.
func can_mine(tier: ResourceDefs.DepositTier) -> bool:
	var rate: float = DRAIN_RATES_PER_TIER.get(tier, 2.0)
	return _current_charge >= rate

## Begins recharging at the ship. Call process_recharge() each frame while active.
func start_recharge() -> void:
	_is_recharging = true

## Stops recharging.
func stop_recharge() -> void:
	_is_recharging = false

## Returns true if currently recharging.
func is_recharging() -> bool:
	return _is_recharging

## Call each frame while recharging. Returns true when fully charged.
func process_recharge(delta: float) -> bool:
	if not _is_recharging:
		return false
	var previous_charge: float = _current_charge
	_current_charge = minf(_current_charge + RECHARGE_RATE * delta, max_charge)
	if _current_charge != previous_charge:
		charge_changed.emit(_current_charge, max_charge)
	if _current_charge >= max_charge:
		_is_recharging = false
		battery_recharged.emit()
		return true
	return false

## Instantly restores charge to max (for debug or special events).
func restore_full() -> void:
	_current_charge = max_charge
	_is_recharging = false
	charge_changed.emit(_current_charge, max_charge)
	battery_recharged.emit()
