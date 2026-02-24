## Spare Battery item: a single-use field consumable that restores the player's suit battery to full.
## Crafted at the Fabricator. Each battery occupies exactly one inventory slot (stack size 1).
class_name SpareBattery
extends RefCounted

# ── Constants ─────────────────────────────────────────────

## Fabricator recipe constants — used by FabricatorDefs to register the recipe.
const RECIPE_INPUT_RESOURCE_TYPE: ResourceDefs.ResourceType = ResourceDefs.ResourceType.METAL
const RECIPE_INPUT_QUANTITY: int = 10
const RECIPE_OUTPUT_RESOURCE_TYPE: ResourceDefs.ResourceType = ResourceDefs.ResourceType.SPARE_BATTERY
const RECIPE_OUTPUT_QUANTITY: int = 1
const RECIPE_DURATION: float = 8.0

# ── Public Methods ────────────────────────────────────────

## Attempts to use one Spare Battery from the player's inventory.
## Restores suit battery to 100% and consumes the item on success.
## Returns true if a battery was available and used, false if inventory is empty.
static func use() -> bool:
	var total: int = PlayerInventory.get_total_count(ResourceDefs.ResourceType.SPARE_BATTERY)
	if total <= 0:
		Global.log("SpareBattery: use failed — no batteries in inventory")
		return false

	# Remove one battery from the lowest-purity slot first.
	var removed: int = _remove_one_battery()
	if removed <= 0:
		Global.log("SpareBattery: use failed — removal returned 0 unexpectedly")
		return false

	SuitBattery.restore_full()
	Global.log("SpareBattery: used — suit battery restored to 100%%")
	return true

## Returns the quantity of Spare Batteries currently in the player's inventory.
static func get_inventory_count() -> int:
	return PlayerInventory.get_total_count(ResourceDefs.ResourceType.SPARE_BATTERY)

# ── Private Methods ───────────────────────────────────────

## Removes exactly one Spare Battery from inventory, consuming any purity slot.
## Returns the quantity actually removed (should be 1 on success).
static func _remove_one_battery() -> int:
	for purity_value: int in ResourceDefs.Purity.values():
		var purity: ResourceDefs.Purity = purity_value as ResourceDefs.Purity
		var available: int = PlayerInventory.get_count(ResourceDefs.ResourceType.SPARE_BATTERY, purity)
		if available > 0:
			return PlayerInventory.remove_item(ResourceDefs.ResourceType.SPARE_BATTERY, purity, 1)
	return 0
