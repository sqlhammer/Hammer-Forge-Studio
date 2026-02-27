## Fuel Cell item: a ship-consumed energy cell that powers the ship's jump drive.
## Crafted at the Fabricator from Metal and Cryonite. Not player-equippable.
## Consumed by the ship fuel system during travel sequences.
class_name FuelCell
extends RefCounted

# ── Constants ─────────────────────────────────────────────

## Fabricator recipe constants — used by FabricatorDefs to register the recipe.
const RECIPE_INPUT_RESOURCE_TYPE_A: ResourceDefs.ResourceType = ResourceDefs.ResourceType.METAL
const RECIPE_INPUT_QUANTITY_A: int = 2
const RECIPE_INPUT_RESOURCE_TYPE_B: ResourceDefs.ResourceType = ResourceDefs.ResourceType.CRYONITE
const RECIPE_INPUT_QUANTITY_B: int = 1
const RECIPE_OUTPUT_RESOURCE_TYPE: ResourceDefs.ResourceType = ResourceDefs.ResourceType.FUEL_CELL
const RECIPE_OUTPUT_QUANTITY: int = 1
const RECIPE_DURATION: float = 12.0

# ── Public Methods ────────────────────────────────────────

## Returns the quantity of Fuel Cells currently in the player's inventory.
static func get_inventory_count() -> int:
	return PlayerInventory.get_total_count(ResourceDefs.ResourceType.FUEL_CELL)
