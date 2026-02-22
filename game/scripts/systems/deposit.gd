## Data and state for a single minable deposit in the world.
class_name Deposit
extends Node3D

# ── Signals ──────────────────────────────────────────────
signal quantity_changed(remaining: int, total: int)
signal depleted

# ── Exported Variables ────────────────────────────────────
@export var resource_type: ResourceDefs.ResourceType = ResourceDefs.ResourceType.SCRAP_METAL
@export var purity: ResourceDefs.Purity = ResourceDefs.Purity.THREE_STAR
@export var density_tier: ResourceDefs.DensityTier = ResourceDefs.DensityTier.MEDIUM
@export var deposit_tier: ResourceDefs.DepositTier = ResourceDefs.DepositTier.TIER_1
@export var total_quantity: int = 40

# ── Private Variables ─────────────────────────────────────
var _remaining_quantity: int = 0
var _is_pinged: bool = false
var _is_analyzed: bool = false

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

## Returns true if the scanner has pinged this deposit.
func is_pinged() -> bool:
	return _is_pinged

## Marks this deposit as pinged by the scanner.
func mark_pinged() -> void:
	_is_pinged = true

## Returns true if the scanner has analyzed this deposit.
func is_analyzed() -> bool:
	return _is_analyzed

## Marks this deposit as analyzed by the scanner.
func mark_analyzed() -> void:
	_is_analyzed = true

## Extracts up to `amount` units from the deposit. Returns the quantity actually extracted.
func extract(amount: int) -> int:
	if amount <= 0 or is_depleted():
		return 0
	var extracted: int = mini(amount, _remaining_quantity)
	_remaining_quantity -= extracted
	quantity_changed.emit(_remaining_quantity, total_quantity)
	if _remaining_quantity <= 0:
		depleted.emit()
	return extracted

## Returns the total energy cost to fully extract this deposit.
func get_total_energy_cost() -> float:
	var base_cost: float = ResourceDefs.get_base_energy_per_unit(resource_type)
	return base_cost * _remaining_quantity

## Returns a summary dict for UI display (scanner Phase 2 output).
func get_analysis_summary() -> Dictionary:
	return {
		"resource_name": ResourceDefs.get_resource_name(resource_type),
		"purity": purity,
		"purity_name": ResourceDefs.PURITY_NAMES.get(purity, "Unknown"),
		"density_name": ResourceDefs.DENSITY_NAMES.get(density_tier, "Unknown"),
		"remaining": _remaining_quantity,
		"total": total_quantity,
		"energy_cost": get_total_energy_cost(),
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

## Serializes deposit state for persistence.
func serialize() -> Dictionary:
	return {
		"resource_type": resource_type,
		"purity": purity,
		"density_tier": density_tier,
		"deposit_tier": deposit_tier,
		"total_quantity": total_quantity,
		"remaining_quantity": _remaining_quantity,
		"is_pinged": _is_pinged,
		"is_analyzed": _is_analyzed,
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
	_is_pinged = data.get("is_pinged", false) as bool
	_is_analyzed = data.get("is_analyzed", false) as bool
	var pos: Dictionary = data.get("position", {})
	if not pos.is_empty():
		global_position = Vector3(
			pos.get("x", 0.0) as float,
			pos.get("y", 0.0) as float,
			pos.get("z", 0.0) as float,
		)
