## Canonical data definitions for all resource types, purity ratings, and deposit tiers.
class_name ResourceDefs
extends RefCounted

# ── Enums ─────────────────────────────────────────────────

## Unique resource types. M3 ships with SCRAP_METAL only.
enum ResourceType {
	NONE = 0,
	SCRAP_METAL = 1,
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
## Each entry defines display name, deposit tier, and base energy cost per unit.
const RESOURCE_CATALOG: Dictionary = {
	ResourceType.SCRAP_METAL: {
		"name": "Scrap Metal",
		"deposit_tier": DepositTier.TIER_1,
		"base_energy_per_unit": 2.0,
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
