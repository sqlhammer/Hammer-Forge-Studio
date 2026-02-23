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

# ── Private Variables ─────────────────────────────────────
var _remaining_quantity: int = 0
var _scan_state: ScanState = ScanState.UNDISCOVERED

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
func is_depleted() -> bool:
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

## Marks this deposit as fully analyzed by scanner Phase 2.
func mark_analyzed() -> void:
	if _scan_state < ScanState.ANALYZED:
		_scan_state = ScanState.ANALYZED
		scan_state_changed.emit(_scan_state)

## Extracts up to `amount` units from the deposit.
## Returns a Dictionary: { "resource_type", "purity", "quantity" } or empty dict if nothing extracted.
func extract(amount: int) -> Dictionary:
	if amount <= 0 or is_depleted():
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
	# Backwards-compatible: accept both "scan_state" and legacy "is_analyzed"
	if data.has("scan_state"):
		_scan_state = data.get("scan_state", ScanState.UNDISCOVERED) as ScanState
	elif data.get("is_analyzed", false):
		_scan_state = ScanState.ANALYZED
	else:
		_scan_state = ScanState.UNDISCOVERED
	var pos: Dictionary = data.get("position", {})
	if not pos.is_empty():
		global_position = Vector3(
			pos.get("x", 0.0) as float,
			pos.get("y", 0.0) as float,
			pos.get("z", 0.0) as float,
		)
