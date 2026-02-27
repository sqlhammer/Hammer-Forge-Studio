## Canonical data definitions for all resource types, purity ratings, and deposit tiers.
class_name ResourceDefs
extends RefCounted

# ── Enums ─────────────────────────────────────────────────

## Unique resource types. SCRAP_METAL (M3), METAL (M4 — refined from Scrap Metal).
## SPARE_BATTERY (M5 — crafted consumable, restores suit battery).
## CRYONITE (M8 — pressurized raw mineral). FUEL_CELL (M8 — ship fuel, crafted consumable).
enum ResourceType {
	NONE = 0,
	SCRAP_METAL = 1,
	METAL = 2,
	SPARE_BATTERY = 3,
	CRYONITE = 4,
	FUEL_CELL = 5,
}

## Purity rating from 1-star (lowest) to 5-star (highest).
## Affects crafting energy cost via PURITY_MODIFIERS.
enum Purity {
	ONE_STAR = 1,
	TWO_STAR = 2,
	THREE_STAR = 3,
	FOUR_STAR = 4,
	FIVE_STAR = 5,
}

## Quantity density of a deposit — determines total extractable units.
enum DensityTier {
	LOW = 0,
	MEDIUM = 1,
	HIGH = 2,
}

## Tool tier required to mine a deposit. Higher tiers need better tools.
enum DepositTier {
	TIER_1 = 1,  # Hand Drill (game start)
	TIER_2 = 2,  # Pneumatic Drill (early game)
	TIER_3 = 3,  # Thermal Drill (mid-game)
	TIER_4 = 4,  # Plasma Cutter / Resonance Bore (late-game)
}

# ── Constants ─────────────────────────────────────────────

## Crafting energy cost multiplier per purity level.
## Formula: Crafting Energy Cost = Base Cost * (1.0 / modifier)
const PURITY_MODIFIERS: Dictionary = {
	Purity.ONE_STAR: 0.60,
	Purity.TWO_STAR: 0.80,
	Purity.THREE_STAR: 1.00,
	Purity.FOUR_STAR: 1.25,
	Purity.FIVE_STAR: 1.60,
}

## Display names for purity levels.
const PURITY_NAMES: Dictionary = {
	Purity.ONE_STAR: "1-Star",
	Purity.TWO_STAR: "2-Star",
	Purity.THREE_STAR: "3-Star",
	Purity.FOUR_STAR: "4-Star",
	Purity.FIVE_STAR: "5-Star",
}

## Display names for density tiers.
const DENSITY_NAMES: Dictionary = {
	DensityTier.LOW: "Low",
	DensityTier.MEDIUM: "Medium",
	DensityTier.HIGH: "High",
}

## Base quantity ranges per density tier (min, max units extractable).
const DENSITY_QUANTITY_RANGES: Dictionary = {
	DensityTier.LOW: Vector2i(10, 25),
	DensityTier.MEDIUM: Vector2i(26, 60),
	DensityTier.HIGH: Vector2i(61, 100),
}

## Resource catalog — keyed by ResourceType.
## Each entry defines display name, description, stack size, icon path, category,
## deposit tier, and base energy cost per unit.
const RESOURCE_CATALOG: Dictionary = {
	ResourceType.SCRAP_METAL: {
		"name": "Scrap Metal",
		"description": "Salvaged metal fragments. Common building material for basic repairs and crafting.",
		"stack_size": 100,
		"icon": "res://assets/icons/item/icon_item_scrap_metal.svg",
		"category": "raw_material",
		"deposit_tier": DepositTier.TIER_1,
		"base_energy_per_unit": 2.0,
	},
	ResourceType.METAL: {
		"name": "Metal",
		"description": "Refined metal ingot. Processed from Scrap Metal via the Recycler. Used for crafting and upgrades.",
		"stack_size": 50,
		"icon": "res://assets/icons/item/icon_item_metal.svg",
		"category": "processed_material",
		"deposit_tier": DepositTier.TIER_1,
		"base_energy_per_unit": 0.0,
	},
	ResourceType.SPARE_BATTERY: {
		"name": "Spare Battery",
		"description": "A portable power cell for the player's suit. Single-use: restores suit battery to 100% when consumed in the field. Crafted at the Fabricator.",
		"stack_size": 1,
		"icon": "res://assets/icons/item/icon_item_spare_battery.svg",
		"category": "consumable",
		"deposit_tier": DepositTier.TIER_1,
		"base_energy_per_unit": 0.0,
	},
	ResourceType.CRYONITE: {
		"name": "Cryonite",
		"description": "A volatile mineral trapped in pressurized rock formations. Handle with care — mishandling causes it to vent and partially dissipate. Required to produce Fuel Cells.",
		"stack_size": 50,
		"icon": "res://assets/icons/item/icon_item_cryonite.svg",
		"category": "raw_material",
		"deposit_tier": DepositTier.TIER_1,
		"base_energy_per_unit": 2.5,
		"pressurized": true,
	},
	ResourceType.FUEL_CELL: {
		"name": "Fuel Cell",
		"description": "A pressurized energy cell used to power the ship's jump drive. Crafted at the Fabricator from Metal and Cryonite. Consumed by the ship fuel system — not player-equippable.",
		"stack_size": 10,
		"icon": "res://assets/icons/item/icon_item_fuel_cell.svg",
		"category": "ship_consumable",
		"deposit_tier": DepositTier.TIER_1,
		"base_energy_per_unit": 0.0,
	},
}

## Display names for deposit tiers.
const DEPOSIT_TIER_NAMES: Dictionary = {
	DepositTier.TIER_1: "Tier 1 — Hand Drill",
	DepositTier.TIER_2: "Tier 2 — Pneumatic Drill",
	DepositTier.TIER_3: "Tier 3 — Thermal Drill",
	DepositTier.TIER_4: "Tier 4 — Plasma Cutter",
}

# ── Static Helpers ────────────────────────────────────────

## Returns the crafting cost multiplier for a given purity.
static func get_purity_modifier(purity: Purity) -> float:
	return PURITY_MODIFIERS.get(purity, 1.0)

## Returns the display name for a resource type.
static func get_resource_name(resource_type: ResourceType) -> String:
	var entry: Dictionary = RESOURCE_CATALOG.get(resource_type, {})
	return entry.get("name", "Unknown") as String

## Returns the required deposit tier for a resource type.
static func get_required_tier(resource_type: ResourceType) -> DepositTier:
	var entry: Dictionary = RESOURCE_CATALOG.get(resource_type, {})
	return entry.get("deposit_tier", DepositTier.TIER_1) as DepositTier

## Returns the base energy cost per unit for a resource type.
static func get_base_energy_per_unit(resource_type: ResourceType) -> float:
	var entry: Dictionary = RESOURCE_CATALOG.get(resource_type, {})
	return entry.get("base_energy_per_unit", 1.0) as float

## Returns the max stack size for a resource type (default 100).
static func get_stack_size(resource_type: ResourceType) -> int:
	var entry: Dictionary = RESOURCE_CATALOG.get(resource_type, {})
	return entry.get("stack_size", 100) as int

## Returns the description for a resource type.
static func get_description(resource_type: ResourceType) -> String:
	var entry: Dictionary = RESOURCE_CATALOG.get(resource_type, {})
	return entry.get("description", "") as String

## Returns the category for a resource type.
static func get_category(resource_type: ResourceType) -> String:
	var entry: Dictionary = RESOURCE_CATALOG.get(resource_type, {})
	return entry.get("category", "") as String

## Returns the icon path for a resource type, or empty string if none defined.
static func get_icon_path(resource_type: ResourceType) -> String:
	var entry: Dictionary = RESOURCE_CATALOG.get(resource_type, {})
	return entry.get("icon", "") as String

## Returns true if the resource type is pressurized (e.g., Cryonite).
## Pressurized resources apply a 50% partial-yield penalty when the mining minigame fails or is skipped.
static func is_pressurized(resource_type: ResourceType) -> bool:
	var entry: Dictionary = RESOURCE_CATALOG.get(resource_type, {})
	return entry.get("pressurized", false) as bool
