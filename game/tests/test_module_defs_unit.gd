## Unit tests for the ModuleDefs data layer. Verifies module catalog entries, enum display
## names, static helpers, and the recycler module specification.
class_name TestModuleDefsUnit
extends TestSuite


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Catalog
	add_test("recycler_entry_exists_in_catalog", _test_recycler_entry_exists_in_catalog)
	add_test("recycler_power_draw_is_10", _test_recycler_power_draw_is_10)
	add_test("recycler_tier_is_tier_1", _test_recycler_tier_is_tier_1)
	add_test("recycler_type_is_extraction_bay", _test_recycler_type_is_extraction_bay)
	add_test("recycler_install_cost_is_20_scrap_metal", _test_recycler_install_cost_is_20_scrap_metal)
	# Static helpers
	add_test("get_module_entry_unknown_returns_empty", _test_get_module_entry_unknown_returns_empty)
	add_test("get_module_name_returns_display_name", _test_get_module_name_returns_display_name)
	add_test("get_power_draw_returns_correct_value", _test_get_power_draw_returns_correct_value)
	add_test("get_all_module_ids_includes_recycler", _test_get_all_module_ids_includes_recycler)
	# Enum display names
	add_test("module_type_names_cover_all_types", _test_module_type_names_cover_all_types)
	add_test("module_tier_names_cover_all_tiers", _test_module_tier_names_cover_all_tiers)
	add_test("get_type_name_returns_correct_string", _test_get_type_name_returns_correct_string)


# ── Test Methods ──────────────────────────────────────────

# -- Catalog --

func _test_recycler_entry_exists_in_catalog() -> void:
	var entry: Dictionary = ModuleDefs.get_module_entry("recycler")
	assert_false(entry.is_empty(), "Recycler should exist in MODULE_CATALOG")
	assert_true(entry.has("name"), "Entry should have 'name' key")
	assert_true(entry.has("power_draw"), "Entry should have 'power_draw' key")
	assert_true(entry.has("install_cost"), "Entry should have 'install_cost' key")


func _test_recycler_power_draw_is_10() -> void:
	var draw: float = ModuleDefs.get_power_draw("recycler")
	assert_equal(draw, 10.0, "Recycler power draw should be 10.0")


func _test_recycler_tier_is_tier_1() -> void:
	var tier: ModuleDefs.ModuleTier = ModuleDefs.get_module_tier("recycler")
	assert_equal(tier, ModuleDefs.ModuleTier.TIER_1, "Recycler should be Tier 1")


func _test_recycler_type_is_extraction_bay() -> void:
	var module_type: ModuleDefs.ModuleType = ModuleDefs.get_module_type("recycler")
	assert_equal(module_type, ModuleDefs.ModuleType.EXTRACTION_BAY,
		"Recycler should be EXTRACTION_BAY type")


func _test_recycler_install_cost_is_20_scrap_metal() -> void:
	var cost: Dictionary = ModuleDefs.get_install_cost("recycler")
	assert_false(cost.is_empty(), "Recycler should have an install cost")
	assert_equal(cost.get("resource_type"), ResourceDefs.ResourceType.SCRAP_METAL,
		"Install cost resource should be SCRAP_METAL")
	assert_equal(cost.get("purity"), ResourceDefs.Purity.ONE_STAR,
		"Install cost purity should be ONE_STAR")
	assert_equal(cost.get("quantity"), 20, "Install cost quantity should be 20")


# -- Static helpers --

func _test_get_module_entry_unknown_returns_empty() -> void:
	var entry: Dictionary = ModuleDefs.get_module_entry("nonexistent_module")
	assert_true(entry.is_empty(), "Unknown module ID should return empty dict")


func _test_get_module_name_returns_display_name() -> void:
	var module_name: String = ModuleDefs.get_module_name("recycler")
	assert_equal(module_name, "Recycler", "get_module_name should return 'Recycler'")
	var unknown_name: String = ModuleDefs.get_module_name("fake")
	assert_equal(unknown_name, "Unknown", "Unknown module should return 'Unknown'")


func _test_get_power_draw_returns_correct_value() -> void:
	var draw: float = ModuleDefs.get_power_draw("recycler")
	assert_equal(draw, 10.0, "Recycler power draw should be 10.0")
	var unknown_draw: float = ModuleDefs.get_power_draw("fake")
	assert_equal(unknown_draw, 0.0, "Unknown module power draw should default to 0.0")


func _test_get_all_module_ids_includes_recycler() -> void:
	var ids: Array[String] = ModuleDefs.get_all_module_ids()
	assert_true(ids.has("recycler"), "Module IDs should include 'recycler'")
	assert_true(ids.size() >= 1, "Should have at least 1 module in catalog")


# -- Enum display names --

func _test_module_type_names_cover_all_types() -> void:
	for type_value: int in ModuleDefs.ModuleType.values():
		var module_type: ModuleDefs.ModuleType = type_value as ModuleDefs.ModuleType
		assert_true(ModuleDefs.MODULE_TYPE_NAMES.has(module_type),
			"MODULE_TYPE_NAMES should cover type %d" % type_value)


func _test_module_tier_names_cover_all_tiers() -> void:
	for tier_value: int in ModuleDefs.ModuleTier.values():
		var tier: ModuleDefs.ModuleTier = tier_value as ModuleDefs.ModuleTier
		assert_true(ModuleDefs.MODULE_TIER_NAMES.has(tier),
			"MODULE_TIER_NAMES should cover tier %d" % tier_value)


func _test_get_type_name_returns_correct_string() -> void:
	var type_name: String = ModuleDefs.get_type_name(ModuleDefs.ModuleType.EXTRACTION_BAY)
	assert_equal(type_name, "Extraction Bay", "EXTRACTION_BAY display name should be 'Extraction Bay'")
	var none_type_name: String = ModuleDefs.get_type_name(ModuleDefs.ModuleType.NONE)
	assert_equal(none_type_name, "None", "NONE display name should be 'None'")
