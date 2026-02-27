## Canonical data definitions for all Fabricator crafting recipes.
## Add new recipes here for future milestones — no changes to Fabricator core required.
class_name FabricatorDefs
extends RefCounted

# ── Constants ─────────────────────────────────────────────

## Output mode constants — define how a completed job's output is handled.
const OUTPUT_MODE_INVENTORY: String = "inventory"  ## Add output item to PlayerInventory.
const OUTPUT_MODE_EQUIP_HEAD_LAMP: String = "equip_head_lamp"  ## Directly equip the Head Lamp.

## Fabricator recipe catalog — keyed by unique recipe ID.
## Each entry defines: display_name, inputs (array of {resource_type, quantity}),
## output_mode, output (resource_type + quantity or equip action), and duration (seconds).
## All costs are placeholders — confirm with Studio Head during QA balance pass.
const RECIPE_CATALOG: Dictionary = {
	"spare_battery": {
		"display_name": "Spare Battery",
		"icon": "res://assets/icons/item/icon_item_spare_battery.svg",
		"inputs": [
			{
				"resource_type": SpareBattery.RECIPE_INPUT_RESOURCE_TYPE,
				"quantity": SpareBattery.RECIPE_INPUT_QUANTITY,
			},
		],
		"output_mode": OUTPUT_MODE_INVENTORY,
		"output": {
			"resource_type": SpareBattery.RECIPE_OUTPUT_RESOURCE_TYPE,
			"quantity": SpareBattery.RECIPE_OUTPUT_QUANTITY,
		},
		"duration": SpareBattery.RECIPE_DURATION,
	},
	"head_lamp": {
		"display_name": "Head Lamp",
		"icon": "res://assets/icons/item/icon_item_head_lamp.svg",
		"inputs": [
			{
				"resource_type": HeadLamp.RECIPE_INPUT_RESOURCE_TYPE,
				"quantity": HeadLamp.RECIPE_INPUT_QUANTITY,
			},
		],
		"output_mode": OUTPUT_MODE_EQUIP_HEAD_LAMP,
		# No inventory output — completing this recipe calls HeadLamp.equip() directly.
		"output": {},
		"duration": HeadLamp.RECIPE_DURATION,
	},
	"fuel_cell": {
		"display_name": "Fuel Cell",
		"icon": "res://assets/icons/item/icon_item_fuel_cell.svg",
		"inputs": [
			{
				"resource_type": FuelCell.RECIPE_INPUT_RESOURCE_TYPE_A,
				"quantity": FuelCell.RECIPE_INPUT_QUANTITY_A,
			},
			{
				"resource_type": FuelCell.RECIPE_INPUT_RESOURCE_TYPE_B,
				"quantity": FuelCell.RECIPE_INPUT_QUANTITY_B,
			},
		],
		"output_mode": OUTPUT_MODE_INVENTORY,
		"output": {
			"resource_type": FuelCell.RECIPE_OUTPUT_RESOURCE_TYPE,
			"quantity": FuelCell.RECIPE_OUTPUT_QUANTITY,
		},
		"duration": FuelCell.RECIPE_DURATION,
	},
}

# ── Static Helpers ────────────────────────────────────────

## Returns the catalog entry for a recipe ID, or empty dict if not found.
static func get_recipe_entry(recipe_id: String) -> Dictionary:
	return RECIPE_CATALOG.get(recipe_id, {})

## Returns the display name for a recipe ID.
static func get_recipe_name(recipe_id: String) -> String:
	var entry: Dictionary = RECIPE_CATALOG.get(recipe_id, {})
	return entry.get("display_name", "Unknown") as String

## Returns the inputs array for a recipe ID.
static func get_inputs(recipe_id: String) -> Array:
	var entry: Dictionary = RECIPE_CATALOG.get(recipe_id, {})
	return entry.get("inputs", [])

## Returns the output_mode for a recipe ID.
static func get_output_mode(recipe_id: String) -> String:
	var entry: Dictionary = RECIPE_CATALOG.get(recipe_id, {})
	return entry.get("output_mode", OUTPUT_MODE_INVENTORY) as String

## Returns the output dictionary for a recipe ID.
static func get_output(recipe_id: String) -> Dictionary:
	var entry: Dictionary = RECIPE_CATALOG.get(recipe_id, {})
	return entry.get("output", {})

## Returns the crafting duration in seconds for a recipe ID.
static func get_duration(recipe_id: String) -> float:
	var entry: Dictionary = RECIPE_CATALOG.get(recipe_id, {})
	return entry.get("duration", 5.0) as float

## Returns the icon path for a recipe ID, or empty string if none defined.
static func get_icon_path(recipe_id: String) -> String:
	var entry: Dictionary = RECIPE_CATALOG.get(recipe_id, {})
	return entry.get("icon", "") as String

## Returns all recipe IDs in the catalog.
static func get_all_recipe_ids() -> Array[String]:
	var ids: Array[String] = []
	for key: String in RECIPE_CATALOG.keys():
		ids.append(key)
	return ids
