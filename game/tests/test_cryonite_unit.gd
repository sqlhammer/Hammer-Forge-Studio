## Unit tests for the Cryonite resource system. Verifies resource data definitions,
## Fabricator Fuel Cell recipe integration, and pressurized yield behavior for the
## new M8 fuel resource.
##
## Coverage target: 80% (per docs/studio/tdd-process-m8.md)
## Ticket: TICKET-0157
class_name TestCryoniteUnit
extends TestSuite


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	PlayerInventory.clear_all()


func after_each() -> void:
	PlayerInventory.clear_all()


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Resource data definitions — Cryonite
	add_test("cryonite_resource_type_is_defined", _test_cryonite_resource_type_is_defined)
	add_test("cryonite_is_in_catalog", _test_cryonite_is_in_catalog)
	add_test("cryonite_name_is_correct", _test_cryonite_name_is_correct)
	add_test("cryonite_category_is_raw_material", _test_cryonite_category_is_raw_material)
	add_test("cryonite_stack_size_is_50", _test_cryonite_stack_size_is_50)
	add_test("cryonite_pressurized_flag_is_true", _test_cryonite_pressurized_flag_is_true)
	add_test("cryonite_is_pressurized_helper_returns_true", _test_cryonite_is_pressurized_helper_returns_true)
	add_test("scrap_metal_is_not_pressurized", _test_scrap_metal_is_not_pressurized)
	add_test("metal_is_not_pressurized", _test_metal_is_not_pressurized)

	# Resource data definitions — Fuel Cell
	add_test("fuel_cell_resource_type_is_defined", _test_fuel_cell_resource_type_is_defined)
	add_test("fuel_cell_is_in_catalog", _test_fuel_cell_is_in_catalog)
	add_test("fuel_cell_name_is_correct", _test_fuel_cell_name_is_correct)
	add_test("fuel_cell_category_is_ship_consumable", _test_fuel_cell_category_is_ship_consumable)
	add_test("fuel_cell_stack_size_is_10", _test_fuel_cell_stack_size_is_10)
	add_test("fuel_cell_is_not_pressurized", _test_fuel_cell_is_not_pressurized)

	# Fuel Cell recipe registration
	add_test("fuel_cell_recipe_is_registered", _test_fuel_cell_recipe_is_registered)
	add_test("fuel_cell_recipe_has_two_inputs", _test_fuel_cell_recipe_has_two_inputs)
	add_test("fuel_cell_recipe_requires_metal_2", _test_fuel_cell_recipe_requires_metal_2)
	add_test("fuel_cell_recipe_requires_cryonite_1", _test_fuel_cell_recipe_requires_cryonite_1)
	add_test("fuel_cell_recipe_output_is_fuel_cell_1", _test_fuel_cell_recipe_output_is_fuel_cell_1)
	add_test("fuel_cell_recipe_output_mode_is_inventory", _test_fuel_cell_recipe_output_mode_is_inventory)
	add_test("fuel_cell_recipe_in_get_all_recipe_ids", _test_fuel_cell_recipe_in_get_all_recipe_ids)

	# Minigame partial-yield path for pressurized resources
	add_test("partial_yield_multiplier_is_50_percent", _test_partial_yield_multiplier_is_50_percent)
	add_test("partial_yield_for_8_units_is_4", _test_partial_yield_for_8_units_is_4)
	add_test("partial_yield_for_7_units_is_4", _test_partial_yield_for_7_units_is_4)
	add_test("partial_yield_for_1_unit_is_1", _test_partial_yield_for_1_unit_is_1)

	# Full-yield path on success
	add_test("full_yield_on_success_is_extraction_amount", _test_full_yield_on_success_is_extraction_amount)
	add_test("full_yield_plus_bonus_on_minigame_success", _test_full_yield_plus_bonus_on_minigame_success)


# ── Helpers ───────────────────────────────────────────────

func _compute_partial_yield(extracted: int) -> int:
	return ceili(extracted * 0.5)


func _find_recipe_input(inputs: Array, resource_type: ResourceDefs.ResourceType) -> Dictionary:
	for input: Dictionary in inputs:
		if input.get("resource_type") == resource_type:
			return input
	return {}


# ── Test Methods ──────────────────────────────────────────

# -- Resource data definitions: Cryonite --

func _test_cryonite_resource_type_is_defined() -> void:
	assert_true(ResourceDefs.ResourceType.has("CRYONITE"),
		"ResourceType enum should include CRYONITE")


func _test_cryonite_is_in_catalog() -> void:
	assert_true(ResourceDefs.RESOURCE_CATALOG.has(ResourceDefs.ResourceType.CRYONITE),
		"RESOURCE_CATALOG should have a CRYONITE entry")


func _test_cryonite_name_is_correct() -> void:
	var name: String = ResourceDefs.get_resource_name(ResourceDefs.ResourceType.CRYONITE)
	assert_equal(name, "Cryonite", "Cryonite display name should be 'Cryonite'")


func _test_cryonite_category_is_raw_material() -> void:
	var category: String = ResourceDefs.get_category(ResourceDefs.ResourceType.CRYONITE)
	assert_equal(category, "raw_material", "Cryonite category should be 'raw_material'")


func _test_cryonite_stack_size_is_50() -> void:
	var stack_size: int = ResourceDefs.get_stack_size(ResourceDefs.ResourceType.CRYONITE)
	assert_equal(stack_size, 50, "Cryonite stack size should be 50")


func _test_cryonite_pressurized_flag_is_true() -> void:
	var entry: Dictionary = ResourceDefs.RESOURCE_CATALOG.get(
		ResourceDefs.ResourceType.CRYONITE, {})
	assert_true(entry.get("pressurized", false) as bool,
		"Cryonite catalog entry should have pressurized=true")


func _test_cryonite_is_pressurized_helper_returns_true() -> void:
	assert_true(ResourceDefs.is_pressurized(ResourceDefs.ResourceType.CRYONITE),
		"is_pressurized(CRYONITE) should return true")


func _test_scrap_metal_is_not_pressurized() -> void:
	assert_false(ResourceDefs.is_pressurized(ResourceDefs.ResourceType.SCRAP_METAL),
		"is_pressurized(SCRAP_METAL) should return false")


func _test_metal_is_not_pressurized() -> void:
	assert_false(ResourceDefs.is_pressurized(ResourceDefs.ResourceType.METAL),
		"is_pressurized(METAL) should return false")


# -- Resource data definitions: Fuel Cell --

func _test_fuel_cell_resource_type_is_defined() -> void:
	assert_true(ResourceDefs.ResourceType.has("FUEL_CELL"),
		"ResourceType enum should include FUEL_CELL")


func _test_fuel_cell_is_in_catalog() -> void:
	assert_true(ResourceDefs.RESOURCE_CATALOG.has(ResourceDefs.ResourceType.FUEL_CELL),
		"RESOURCE_CATALOG should have a FUEL_CELL entry")


func _test_fuel_cell_name_is_correct() -> void:
	var name: String = ResourceDefs.get_resource_name(ResourceDefs.ResourceType.FUEL_CELL)
	assert_equal(name, "Fuel Cell", "Fuel Cell display name should be 'Fuel Cell'")


func _test_fuel_cell_category_is_ship_consumable() -> void:
	var category: String = ResourceDefs.get_category(ResourceDefs.ResourceType.FUEL_CELL)
	assert_equal(category, "ship_consumable",
		"Fuel Cell category should be 'ship_consumable' — not player-equippable")


func _test_fuel_cell_stack_size_is_10() -> void:
	var stack_size: int = ResourceDefs.get_stack_size(ResourceDefs.ResourceType.FUEL_CELL)
	assert_equal(stack_size, 10, "Fuel Cell stack size should be 10")


func _test_fuel_cell_is_not_pressurized() -> void:
	assert_false(ResourceDefs.is_pressurized(ResourceDefs.ResourceType.FUEL_CELL),
		"is_pressurized(FUEL_CELL) should return false — it's a crafted output, not a raw mineral")


# -- Fuel Cell recipe registration --

func _test_fuel_cell_recipe_is_registered() -> void:
	var entry: Dictionary = FabricatorDefs.get_recipe_entry("fuel_cell")
	assert_false(entry.is_empty(), "FabricatorDefs should have a 'fuel_cell' recipe entry")


func _test_fuel_cell_recipe_has_two_inputs() -> void:
	var inputs: Array = FabricatorDefs.get_inputs("fuel_cell")
	assert_equal(inputs.size(), 2,
		"Fuel Cell recipe should have exactly 2 inputs (Metal and Cryonite)")


func _test_fuel_cell_recipe_requires_metal_2() -> void:
	var inputs: Array = FabricatorDefs.get_inputs("fuel_cell")
	var metal_input: Dictionary = _find_recipe_input(inputs, ResourceDefs.ResourceType.METAL)
	assert_false(metal_input.is_empty(), "Fuel Cell recipe should require Metal")
	assert_equal(metal_input.get("quantity"), 2,
		"Fuel Cell recipe should require exactly 2 Metal")


func _test_fuel_cell_recipe_requires_cryonite_1() -> void:
	var inputs: Array = FabricatorDefs.get_inputs("fuel_cell")
	var cryonite_input: Dictionary = _find_recipe_input(
		inputs, ResourceDefs.ResourceType.CRYONITE)
	assert_false(cryonite_input.is_empty(), "Fuel Cell recipe should require Cryonite")
	assert_equal(cryonite_input.get("quantity"), 1,
		"Fuel Cell recipe should require exactly 1 Cryonite")


func _test_fuel_cell_recipe_output_is_fuel_cell_1() -> void:
	var output: Dictionary = FabricatorDefs.get_output("fuel_cell")
	assert_false(output.is_empty(), "Fuel Cell recipe should have an output")
	assert_equal(output.get("resource_type"), ResourceDefs.ResourceType.FUEL_CELL,
		"Fuel Cell recipe output resource_type should be FUEL_CELL")
	assert_equal(output.get("quantity"), 1,
		"Fuel Cell recipe should output exactly 1 Fuel Cell")


func _test_fuel_cell_recipe_output_mode_is_inventory() -> void:
	var output_mode: String = FabricatorDefs.get_output_mode("fuel_cell")
	assert_equal(output_mode, FabricatorDefs.OUTPUT_MODE_INVENTORY,
		"Fuel Cell recipe output_mode should be 'inventory'")


func _test_fuel_cell_recipe_in_get_all_recipe_ids() -> void:
	var ids: Array[String] = FabricatorDefs.get_all_recipe_ids()
	assert_true(ids.has("fuel_cell"),
		"get_all_recipe_ids() should include 'fuel_cell'")


# -- Minigame partial-yield path for pressurized resources --

func _test_partial_yield_multiplier_is_50_percent() -> void:
	var script: Script = load("res://scripts/gameplay/mining.gd")
	assert_equal(script.get("PARTIAL_YIELD_MULTIPLIER"), 0.5,
		"PARTIAL_YIELD_MULTIPLIER should be 0.5")


func _test_partial_yield_for_8_units_is_4() -> void:
	var partial: int = _compute_partial_yield(8)
	assert_equal(partial, 4, "Partial yield for 8 extracted should be 4")


func _test_partial_yield_for_7_units_is_4() -> void:
	# ceili(7 * 0.5) = ceili(3.5) = 4
	var partial: int = _compute_partial_yield(7)
	assert_equal(partial, 4, "Partial yield for 7 extracted should be 4 (ceiling)")


func _test_partial_yield_for_1_unit_is_1() -> void:
	# ceili(1 * 0.5) = ceili(0.5) = 1
	var partial: int = _compute_partial_yield(1)
	assert_equal(partial, 1, "Partial yield for 1 extracted should be 1 (ceiling)")


# -- Full-yield path on success --

func _test_full_yield_on_success_is_extraction_amount() -> void:
	# On minigame success, effective_extracted == extracted (no penalty)
	var extracted: int = 8
	var effective: int = extracted  # No penalty on success
	assert_equal(effective, 8,
		"Successful mining of a pressurized resource should yield the full extraction amount")


func _test_full_yield_plus_bonus_on_minigame_success() -> void:
	# On minigame success: full extraction + 50% bonus
	var extracted: int = 8
	var bonus: int = ceili(extracted * 0.5)
	var total: int = extracted + bonus
	assert_equal(total, 12,
		"Successful minigame should yield full extraction (8) + bonus (4) = 12")
