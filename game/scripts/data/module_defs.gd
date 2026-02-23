## Canonical data definitions for all ship module types, tiers, and catalog entries.
class_name ModuleDefs
extends RefCounted

# ── Enums ─────────────────────────────────────────────────

## Module categories matching the mobile-base spec.
enum ModuleType {
	NONE = 0,
	POWER_GENERATION = 1,
	PROPULSION = 2,
	STRUCTURAL = 3,
	EXTRACTION_BAY = 4,
	AUTOMATION_HUB = 5,
	THERMAL_MANAGEMENT = 6,
	LIFE_SUPPORT = 7,
	STORAGE = 8,
	SCANNER_ARRAY = 9,
}

## Module tier — determines power draw, cost, and capability.
enum ModuleTier {
	TIER_1 = 1,
	TIER_2 = 2,
	TIER_3 = 3,
}

# ── Constants ─────────────────────────────────────────────

## Module catalog — keyed by a unique string ID.
## Each entry defines display name, module type, tier, power draw,
## install cost (resource type, purity, quantity), and description.
## Adding a new module only requires a new entry here.
const MODULE_CATALOG: Dictionary = {
	"recycler": {
		"name": "Recycler",
		"description": "Converts raw Scrap Metal into refined Metal. Essential for crafting and upgrades.",
		"module_type": ModuleType.EXTRACTION_BAY,
		"tier": ModuleTier.TIER_1,
		"power_draw": 10.0,
		"install_cost": {
			"resource_type": ResourceDefs.ResourceType.SCRAP_METAL,
			"purity": ResourceDefs.Purity.ONE_STAR,
			"quantity": 20,
		},
	},
}

## Display names for module types.
const MODULE_TYPE_NAMES: Dictionary = {
	ModuleType.NONE: "None",
	ModuleType.POWER_GENERATION: "Power Generation",
	ModuleType.PROPULSION: "Propulsion",
	ModuleType.STRUCTURAL: "Structural",
	ModuleType.EXTRACTION_BAY: "Extraction Bay",
	ModuleType.AUTOMATION_HUB: "Automation Hub",
	ModuleType.THERMAL_MANAGEMENT: "Thermal Management",
	ModuleType.LIFE_SUPPORT: "Life Support",
	ModuleType.STORAGE: "Storage",
	ModuleType.SCANNER_ARRAY: "Scanner Array",
}

## Display names for module tiers.
const MODULE_TIER_NAMES: Dictionary = {
	ModuleTier.TIER_1: "Tier 1",
	ModuleTier.TIER_2: "Tier 2",
	ModuleTier.TIER_3: "Tier 3",
}

# ── Static Helpers ────────────────────────────────────────

## Returns the catalog entry for a module ID, or empty dict if not found.
static func get_module_entry(module_id: String) -> Dictionary:
	return MODULE_CATALOG.get(module_id, {})

## Returns the display name for a module ID.
static func get_module_name(module_id: String) -> String:
	var entry: Dictionary = MODULE_CATALOG.get(module_id, {})
	return entry.get("name", "Unknown") as String

## Returns the power draw for a module ID.
static func get_power_draw(module_id: String) -> float:
	var entry: Dictionary = MODULE_CATALOG.get(module_id, {})
	return entry.get("power_draw", 0.0) as float

## Returns the install cost dictionary for a module ID.
static func get_install_cost(module_id: String) -> Dictionary:
	var entry: Dictionary = MODULE_CATALOG.get(module_id, {})
	return entry.get("install_cost", {})

## Returns the module type for a module ID.
static func get_module_type(module_id: String) -> ModuleType:
	var entry: Dictionary = MODULE_CATALOG.get(module_id, {})
	return entry.get("module_type", ModuleType.NONE) as ModuleType

## Returns the tier for a module ID.
static func get_module_tier(module_id: String) -> ModuleTier:
	var entry: Dictionary = MODULE_CATALOG.get(module_id, {})
	return entry.get("tier", ModuleTier.TIER_1) as ModuleTier

## Returns all module IDs in the catalog.
static func get_all_module_ids() -> Array[String]:
	var ids: Array[String] = []
	for key: String in MODULE_CATALOG.keys():
		ids.append(key)
	return ids

## Returns the display name for a module type enum value.
static func get_type_name(module_type: ModuleType) -> String:
	return MODULE_TYPE_NAMES.get(module_type, "Unknown") as String
