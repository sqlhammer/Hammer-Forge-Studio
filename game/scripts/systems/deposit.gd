## Data and state for a single minable deposit in the world.
class_name Deposit
extends Node3D

# ── Enums ────────────────────────────────────────────────

## Scanner discovery state for this deposit.
enum ScanState {
	UNDISCOVERED = 0,  ## Not yet detected by scanner
	PINGED = 1,        ## Located by scanner ping (Phase 1) — appears on compass
	ANALYZED = 2,      ## Fully analyzed (Phase 2) — purity/density/cost visible
}

# ── Signals ──────────────────────────────────────────────
signal quantity_changed(remaining: int, total: int)
signal scan_state_changed(new_state: ScanState)
signal depleted

# ── Exported Variables ────────────────────────────────────
@export var resource_type: ResourceDefs.ResourceType = ResourceDefs.ResourceType.SCRAP_METAL
@export var purity: ResourceDefs.Purity = ResourceDefs.Purity.THREE_STAR
@export var density_tier: ResourceDefs.DensityTier = ResourceDefs.DensityTier.MEDIUM
@export var deposit_tier: ResourceDefs.DepositTier = ResourceDefs.DepositTier.TIER_1
@export var total_quantity: int = 40
## When true, this deposit never depletes — stock is never reduced on extraction.
## Used for deep resource nodes that yield indefinitely.
@export var infinite: bool = false
## Multiplier on the base extraction rate. 1.0 = normal surface speed.
## Deep nodes use a lower value (e.g., 0.1 = 10% of surface speed).
@export var yield_rate: float = 1.0
## When true, automated drones may target this deposit.
## All deposits default to drone-accessible; set false to exclude a deposit from drone targeting.
@export var drone_accessible: bool = true

# ── Private Variables ─────────────────────────────────────
var _remaining_quantity: int = 0
var _scan_state: ScanState = ScanState.UNDISCOVERED
var _pattern_line_count: int = 0

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	_remaining_quantity = total_quantity

# ── Public Methods ────────────────────────────────────────

## Returns the remaining extractable quantity.
func get_remaining() -> int:
	return _remaining_quantity

## Returns the total quantity this deposit started with.
func get_total() -> int:
	return total_quantity

## Returns true if the deposit has been fully mined.
## Infinite deposits never deplete.
func is_depleted() -> bool:
	if infinite:
		return false
	return _remaining_quantity <= 0

## Returns the current scan state.
func get_scan_state() -> ScanState:
	return _scan_state

## Returns true if the deposit has been pinged or analyzed (visible on compass).
func is_pinged() -> bool:
	return _scan_state >= ScanState.PINGED

## Returns true if the scanner has fully analyzed this deposit.
func is_analyzed() -> bool:
	return _scan_state == ScanState.ANALYZED

## Marks this deposit as pinged by scanner Phase 1. Appears on compass.
func ping() -> void:
	if _scan_state < ScanState.PINGED:
		_scan_state = ScanState.PINGED
		scan_state_changed.emit(_scan_state)

## Returns the number of minigame pattern lines for this deposit.
func get_pattern_line_count() -> int:
	return _pattern_line_count

## Marks this deposit as fully analyzed by scanner Phase 2.
func mark_analyzed() -> void:
	if _scan_state < ScanState.ANALYZED:
		_scan_state = ScanState.ANALYZED
		_pattern_line_count = _calculate_pattern_lines()
		scan_state_changed.emit(_scan_state)

## Extracts up to `amount` units from the deposit.
## Returns a Dictionary: { "resource_type", "purity", "quantity" } or empty dict if nothing extracted.
## Infinite deposits always return the full requested amount without reducing stock.
func extract(amount: int) -> Dictionary:
	if amount <= 0:
		return {}
	if infinite:
		return {
			"resource_type": resource_type,
			"purity": purity,
			"quantity": amount,
		}
	if is_depleted():
		return {}
	var extracted: int = mini(amount, _remaining_quantity)
	_remaining_quantity -= extracted
	quantity_changed.emit(_remaining_quantity, total_quantity)
	if _remaining_quantity <= 0:
		depleted.emit()
	return {
		"resource_type": resource_type,
		"purity": purity,
		"quantity": extracted,
	}

## Returns the total energy cost to fully extract this deposit.
func get_total_energy_cost() -> float:
	var base_cost: float = ResourceDefs.get_base_energy_per_unit(resource_type)
	return base_cost * _remaining_quantity

## Returns a summary dict for UI display (scanner Phase 2 output).
func get_analysis_summary() -> Dictionary:
	return {
		"resource_name": ResourceDefs.get_resource_name(resource_type),
		"resource_type": resource_type,
		"purity": purity,
		"purity_name": ResourceDefs.PURITY_NAMES.get(purity, "Unknown"),
		"density_name": ResourceDefs.DENSITY_NAMES.get(density_tier, "Unknown"),
		"remaining": _remaining_quantity,
		"total": total_quantity,
		"energy_cost": get_total_energy_cost(),
		"scan_state": _scan_state,
		"is_depleted": is_depleted(),
	}

## Returns the interaction prompt dictionary for HUD display.
## Unscanned (pinged) deposits show "Scan" with hold; analyzed minable deposits show "Mine".
func get_interaction_prompt() -> Dictionary:
	if is_depleted():
		return {}
	if is_analyzed():
		return {"key": _get_action_key_label("use_tool"), "label": "Mine", "hold": true}
	if is_pinged():
		return {"key": "E", "label": "Scan", "hold": true}
	return {}

## Initializes deposit from parameters (for procedural generation).
func setup(p_resource_type: ResourceDefs.ResourceType, p_purity: ResourceDefs.Purity, p_density_tier: ResourceDefs.DensityTier, p_quantity: int) -> void:
	resource_type = p_resource_type
	purity = p_purity
	density_tier = p_density_tier
	deposit_tier = ResourceDefs.get_required_tier(p_resource_type)
	total_quantity = p_quantity
	_remaining_quantity = p_quantity
	_scan_state = ScanState.UNDISCOVERED

## Serializes deposit state for persistence.
func serialize() -> Dictionary:
	return {
		"resource_type": resource_type,
		"purity": purity,
		"density_tier": density_tier,
		"deposit_tier": deposit_tier,
		"total_quantity": total_quantity,
		"remaining_quantity": _remaining_quantity,
		"scan_state": _scan_state,
		"infinite": infinite,
		"yield_rate": yield_rate,
		"drone_accessible": drone_accessible,
		"position": {
			"x": global_position.x,
			"y": global_position.y,
			"z": global_position.z,
		},
	}

## Restores deposit state from a serialized dict.
func deserialize(data: Dictionary) -> void:
	resource_type = data.get("resource_type", ResourceDefs.ResourceType.SCRAP_METAL) as ResourceDefs.ResourceType
	purity = data.get("purity", ResourceDefs.Purity.THREE_STAR) as ResourceDefs.Purity
	density_tier = data.get("density_tier", ResourceDefs.DensityTier.MEDIUM) as ResourceDefs.DensityTier
	deposit_tier = data.get("deposit_tier", ResourceDefs.DepositTier.TIER_1) as ResourceDefs.DepositTier
	total_quantity = data.get("total_quantity", 40) as int
	_remaining_quantity = data.get("remaining_quantity", total_quantity) as int
	infinite = data.get("infinite", false) as bool
	yield_rate = data.get("yield_rate", 1.0) as float
	drone_accessible = data.get("drone_accessible", true) as bool
	# Backwards-compatible: accept both "scan_state" and legacy "is_analyzed"
	if data.has("scan_state"):
		_scan_state = data.get("scan_state", ScanState.UNDISCOVERED) as ScanState
	elif data.get("is_analyzed", false):
		_scan_state = ScanState.ANALYZED
	else:
		_scan_state = ScanState.UNDISCOVERED
	if _scan_state == ScanState.ANALYZED:
		_pattern_line_count = _calculate_pattern_lines()
	var pos: Dictionary = data.get("position", {})
	if not pos.is_empty():
		global_position = Vector3(
			pos.get("x", 0.0) as float,
			pos.get("y", 0.0) as float,
			pos.get("z", 0.0) as float,
		)

## Resolves the display label for the given input action from the InputMap.
## Handles keyboard keys and mouse buttons. Returns "?" if no event is mapped.
func _get_action_key_label(action: String) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	for event: InputEvent in events:
		if event is InputEventKey:
			var key_event: InputEventKey = event as InputEventKey
			return OS.get_keycode_string(key_event.keycode)
		if event is InputEventMouseButton:
			var mb_event: InputEventMouseButton = event as InputEventMouseButton
			match mb_event.button_index:
				MOUSE_BUTTON_LEFT:
					return "LMB"
				MOUSE_BUTTON_RIGHT:
					return "RMB"
				MOUSE_BUTTON_MIDDLE:
					return "MMB"
				_:
					return "Mouse %d" % mb_event.button_index
	return "?"

func _calculate_pattern_lines() -> int:
	match deposit_tier:
		ResourceDefs.DepositTier.TIER_1:
			return 2 if purity >= ResourceDefs.Purity.THREE_STAR else 1
		ResourceDefs.DepositTier.TIER_2:
			return 3 if purity >= ResourceDefs.Purity.THREE_STAR else 2
		_:
			return 4 if purity >= ResourceDefs.Purity.THREE_STAR else 3
