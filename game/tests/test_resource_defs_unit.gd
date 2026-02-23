## Unit tests for ResourceDefs. Verifies enum completeness, constant data integrity,
## and static helper methods return correct values for all resource types and tiers.
class_name TestResourceDefsUnit
extends TestSuite


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	add_test("purity_modifiers_cover_all_levels", _test_purity_modifiers_cover_all_levels)
	add_test("purity_modifier_values_are_correct", _test_purity_modifier_values_are_correct)
	add_test("purity_names_cover_all_levels", _test_purity_names_cover_all_levels)
	add_test("density_names_cover_all_tiers", _test_density_names_cover_all_tiers)
	add_test("density_quantity_ranges_cover_all_tiers", _test_density_quantity_ranges_cover_all_tiers)
	add_test("density_ranges_are_non_overlapping", _test_density_ranges_are_non_overlapping)
	add_test("resource_catalog_has_scrap_metal", _test_resource_catalog_has_scrap_metal)
	add_test("deposit_tier_names_cover_all_tiers", _test_deposit_tier_names_cover_all_tiers)
	add_test("get_purity_modifier_returns_correct_values", _test_get_purity_modifier_returns_correct_values)
	add_test("get_purity_modifier_invalid_returns_default", _test_get_purity_modifier_invalid_returns_default)
	add_test("get_resource_name_scrap_metal", _test_get_resource_name_scrap_metal)
	add_test("get_resource_name_none_returns_unknown", _test_get_resource_name_none_returns_unknown)
	add_test("get_required_tier_scrap_metal", _test_get_required_tier_scrap_metal)
	add_test("get_base_energy_per_unit_scrap_metal", _test_get_base_energy_per_unit_scrap_metal)
	add_test("get_base_energy_per_unit_none_returns_default", _test_get_base_energy_per_unit_none_returns_default)


# ── Test Methods ──────────────────────────────────────────

func _test_purity_modifiers_cover_all_levels() -> void:
	assert_true(ResourceDefs.PURITY_MODIFIERS.has(ResourceDefs.Purity.ONE_STAR),
		"PURITY_MODIFIERS should have ONE_STAR")
	assert_true(ResourceDefs.PURITY_MODIFIERS.has(ResourceDefs.Purity.TWO_STAR),
		"PURITY_MODIFIERS should have TWO_STAR")
	assert_true(ResourceDefs.PURITY_MODIFIERS.has(ResourceDefs.Purity.THREE_STAR),
		"PURITY_MODIFIERS should have THREE_STAR")
	assert_true(ResourceDefs.PURITY_MODIFIERS.has(ResourceDefs.Purity.FOUR_STAR),
		"PURITY_MODIFIERS should have FOUR_STAR")
	assert_true(ResourceDefs.PURITY_MODIFIERS.has(ResourceDefs.Purity.FIVE_STAR),
		"PURITY_MODIFIERS should have FIVE_STAR")


func _test_purity_modifier_values_are_correct() -> void:
	assert_equal(ResourceDefs.PURITY_MODIFIERS[ResourceDefs.Purity.ONE_STAR], 0.60,
		"ONE_STAR modifier should be 0.60")
	assert_equal(ResourceDefs.PURITY_MODIFIERS[ResourceDefs.Purity.TWO_STAR], 0.80,
		"TWO_STAR modifier should be 0.80")
	assert_equal(ResourceDefs.PURITY_MODIFIERS[ResourceDefs.Purity.THREE_STAR], 1.00,
		"THREE_STAR modifier should be 1.00")
	assert_equal(ResourceDefs.PURITY_MODIFIERS[ResourceDefs.Purity.FOUR_STAR], 1.25,
		"FOUR_STAR modifier should be 1.25")
	assert_equal(ResourceDefs.PURITY_MODIFIERS[ResourceDefs.Purity.FIVE_STAR], 1.60,
		"FIVE_STAR modifier should be 1.60")


func _test_purity_names_cover_all_levels() -> void:
	assert_equal(ResourceDefs.PURITY_NAMES[ResourceDefs.Purity.ONE_STAR], "1-Star",
		"ONE_STAR display name should be '1-Star'")
	assert_equal(ResourceDefs.PURITY_NAMES[ResourceDefs.Purity.FIVE_STAR], "5-Star",
		"FIVE_STAR display name should be '5-Star'")
	assert_equal(ResourceDefs.PURITY_NAMES.size(), 5,
		"PURITY_NAMES should have 5 entries")


func _test_density_names_cover_all_tiers() -> void:
	assert_equal(ResourceDefs.DENSITY_NAMES[ResourceDefs.DensityTier.LOW], "Low",
		"LOW density name should be 'Low'")
	assert_equal(ResourceDefs.DENSITY_NAMES[ResourceDefs.DensityTier.MEDIUM], "Medium",
		"MEDIUM density name should be 'Medium'")
	assert_equal(ResourceDefs.DENSITY_NAMES[ResourceDefs.DensityTier.HIGH], "High",
		"HIGH density name should be 'High'")


func _test_density_quantity_ranges_cover_all_tiers() -> void:
	assert_equal(ResourceDefs.DENSITY_QUANTITY_RANGES[ResourceDefs.DensityTier.LOW],
		Vector2i(10, 25), "LOW range should be 10-25")
	assert_equal(ResourceDefs.DENSITY_QUANTITY_RANGES[ResourceDefs.DensityTier.MEDIUM],
		Vector2i(26, 60), "MEDIUM range should be 26-60")
	assert_equal(ResourceDefs.DENSITY_QUANTITY_RANGES[ResourceDefs.DensityTier.HIGH],
		Vector2i(61, 100), "HIGH range should be 61-100")


func _test_density_ranges_are_non_overlapping() -> void:
	var low_max: int = ResourceDefs.DENSITY_QUANTITY_RANGES[ResourceDefs.DensityTier.LOW].y
	var med_min: int = ResourceDefs.DENSITY_QUANTITY_RANGES[ResourceDefs.DensityTier.MEDIUM].x
	var med_max: int = ResourceDefs.DENSITY_QUANTITY_RANGES[ResourceDefs.DensityTier.MEDIUM].y
	var high_min: int = ResourceDefs.DENSITY_QUANTITY_RANGES[ResourceDefs.DensityTier.HIGH].x
	assert_true(low_max < med_min, "LOW max should be less than MEDIUM min")
	assert_true(med_max < high_min, "MEDIUM max should be less than HIGH min")


func _test_resource_catalog_has_scrap_metal() -> void:
	assert_true(ResourceDefs.RESOURCE_CATALOG.has(ResourceDefs.ResourceType.SCRAP_METAL),
		"RESOURCE_CATALOG should have SCRAP_METAL entry")
	var entry: Dictionary = ResourceDefs.RESOURCE_CATALOG[ResourceDefs.ResourceType.SCRAP_METAL]
	assert_equal(entry.get("name"), "Scrap Metal",
		"SCRAP_METAL name should be 'Scrap Metal'")
	assert_equal(entry.get("deposit_tier"), ResourceDefs.DepositTier.TIER_1,
		"SCRAP_METAL deposit tier should be TIER_1")
	assert_equal(entry.get("base_energy_per_unit"), 2.0,
		"SCRAP_METAL base energy per unit should be 2.0")


func _test_deposit_tier_names_cover_all_tiers() -> void:
	assert_equal(ResourceDefs.DEPOSIT_TIER_NAMES.size(), 4,
		"DEPOSIT_TIER_NAMES should have 4 entries")
	assert_true(ResourceDefs.DEPOSIT_TIER_NAMES.has(ResourceDefs.DepositTier.TIER_1),
		"Should have TIER_1 name")
	assert_true(ResourceDefs.DEPOSIT_TIER_NAMES.has(ResourceDefs.DepositTier.TIER_4),
		"Should have TIER_4 name")


func _test_get_purity_modifier_returns_correct_values() -> void:
	assert_equal(ResourceDefs.get_purity_modifier(ResourceDefs.Purity.ONE_STAR), 0.60,
		"get_purity_modifier(ONE_STAR) should return 0.60")
	assert_equal(ResourceDefs.get_purity_modifier(ResourceDefs.Purity.THREE_STAR), 1.00,
		"get_purity_modifier(THREE_STAR) should return 1.00")
	assert_equal(ResourceDefs.get_purity_modifier(ResourceDefs.Purity.FIVE_STAR), 1.60,
		"get_purity_modifier(FIVE_STAR) should return 1.60")


func _test_get_purity_modifier_invalid_returns_default() -> void:
	# Passing an invalid enum value should return the default 1.0
	var result: float = ResourceDefs.get_purity_modifier(99 as ResourceDefs.Purity)
	assert_equal(result, 1.0, "Invalid purity should return default 1.0")


func _test_get_resource_name_scrap_metal() -> void:
	var result: String = ResourceDefs.get_resource_name(ResourceDefs.ResourceType.SCRAP_METAL)
	assert_equal(result, "Scrap Metal", "SCRAP_METAL name should be 'Scrap Metal'")


func _test_get_resource_name_none_returns_unknown() -> void:
	var result: String = ResourceDefs.get_resource_name(ResourceDefs.ResourceType.NONE)
	assert_equal(result, "Unknown", "NONE resource name should be 'Unknown'")


func _test_get_required_tier_scrap_metal() -> void:
	var result: ResourceDefs.DepositTier = ResourceDefs.get_required_tier(
		ResourceDefs.ResourceType.SCRAP_METAL)
	assert_equal(result, ResourceDefs.DepositTier.TIER_1,
		"SCRAP_METAL required tier should be TIER_1")


func _test_get_base_energy_per_unit_scrap_metal() -> void:
	var result: float = ResourceDefs.get_base_energy_per_unit(
		ResourceDefs.ResourceType.SCRAP_METAL)
	assert_equal(result, 2.0, "SCRAP_METAL base energy per unit should be 2.0")


func _test_get_base_energy_per_unit_none_returns_default() -> void:
	var result: float = ResourceDefs.get_base_energy_per_unit(ResourceDefs.ResourceType.NONE)
	assert_equal(result, 1.0, "NONE resource type should return default energy 1.0")
