## Ship survival state: Power, Integrity, Heat, and Oxygen global variables.
## Provides clamped 0.0-100.0 values, change signals, and baseline power generation.
class_name ShipStateType
extends Node

# ── Signals ──────────────────────────────────────────────
signal power_changed(current: float, maximum: float)
signal integrity_changed(current: float, maximum: float)
signal heat_changed(current: float, maximum: float)
signal oxygen_changed(current: float, maximum: float)

# ── Constants ─────────────────────────────────────────────
const MIN_VALUE: float = 0.0
const MAX_VALUE: float = 100.0

## Baseline power output — always-on, sufficient to recharge player suit and run one Tier 1 module.
## This value represents the ship's innate power generation with no additional power modules installed.
const BASELINE_POWER: float = 30.0

# ── Private Variables ─────────────────────────────────────
var _power: float = MAX_VALUE
var _integrity: float = MAX_VALUE
var _heat: float = 50.0
var _oxygen: float = MAX_VALUE

## Total power draw from all installed modules.
var _total_module_draw: float = 0.0

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	Global.log("ShipState: initialized (Power=%.1f, Integrity=%.1f, Heat=%.1f, Oxygen=%.1f)" % [_power, _integrity, _heat, _oxygen])

# ── Public Methods ────────────────────────────────────────

## Returns the current power level.
func get_power() -> float:
	return _power

## Sets the power level, clamped to [0.0, 100.0].
func set_power(value: float) -> void:
	var clamped: float = clampf(value, MIN_VALUE, MAX_VALUE)
	if clamped == _power:
		return
	_power = clamped
	power_changed.emit(_power, MAX_VALUE)

## Returns the current integrity level.
func get_integrity() -> float:
	return _integrity

## Sets the integrity level, clamped to [0.0, 100.0].
func set_integrity(value: float) -> void:
	var clamped: float = clampf(value, MIN_VALUE, MAX_VALUE)
	if clamped == _integrity:
		return
	_integrity = clamped
	integrity_changed.emit(_integrity, MAX_VALUE)

## Returns the current heat level.
func get_heat() -> float:
	return _heat

## Sets the heat level, clamped to [0.0, 100.0].
func set_heat(value: float) -> void:
	var clamped: float = clampf(value, MIN_VALUE, MAX_VALUE)
	if clamped == _heat:
		return
	_heat = clamped
	heat_changed.emit(_heat, MAX_VALUE)

## Returns the current oxygen level.
func get_oxygen() -> float:
	return _oxygen

## Sets the oxygen level, clamped to [0.0, 100.0].
func set_oxygen(value: float) -> void:
	var clamped: float = clampf(value, MIN_VALUE, MAX_VALUE)
	if clamped == _oxygen:
		return
	_oxygen = clamped
	oxygen_changed.emit(_oxygen, MAX_VALUE)

## Returns the baseline power output (always-on generation).
func get_baseline_power() -> float:
	return BASELINE_POWER

## Returns the total power draw from all installed modules.
func get_total_module_draw() -> float:
	return _total_module_draw

## Returns the available power capacity (baseline minus current module draw).
func get_available_power_capacity() -> float:
	return maxf(BASELINE_POWER - _total_module_draw, 0.0)

## Returns true if adding the given draw would exceed baseline power capacity.
func would_exceed_capacity(additional_draw: float) -> bool:
	return (_total_module_draw + additional_draw) > BASELINE_POWER

## Registers a module's power draw. Returns true if successful, false if it would overload.
func register_module_draw(draw: float) -> bool:
	if would_exceed_capacity(draw):
		Global.log("ShipState: power overload — cannot register draw %.1f (current=%.1f, baseline=%.1f)" % [draw, _total_module_draw, BASELINE_POWER])
		return false
	_total_module_draw += draw
	Global.log("ShipState: registered module draw %.1f (total=%.1f/%.1f)" % [draw, _total_module_draw, BASELINE_POWER])
	return true

## Deregisters a module's power draw.
func deregister_module_draw(draw: float) -> void:
	_total_module_draw = maxf(_total_module_draw - draw, 0.0)
	Global.log("ShipState: deregistered module draw %.1f (total=%.1f/%.1f)" % [draw, _total_module_draw, BASELINE_POWER])

## Adjusts power by a delta amount (positive or negative), clamped.
func adjust_power(delta: float) -> void:
	set_power(_power + delta)

## Adjusts integrity by a delta amount (positive or negative), clamped.
func adjust_integrity(delta: float) -> void:
	set_integrity(_integrity + delta)

## Adjusts heat by a delta amount (positive or negative), clamped.
func adjust_heat(delta: float) -> void:
	set_heat(_heat + delta)

## Adjusts oxygen by a delta amount (positive or negative), clamped.
func adjust_oxygen(delta: float) -> void:
	set_oxygen(_oxygen + delta)

## Resets all ship variables to starting values.
func reset() -> void:
	set_power(MAX_VALUE)
	set_integrity(MAX_VALUE)
	set_heat(50.0)
	set_oxygen(MAX_VALUE)
	_total_module_draw = 0.0
	Global.log("ShipState: reset to defaults")
