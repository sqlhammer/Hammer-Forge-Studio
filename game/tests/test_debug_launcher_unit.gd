## Unit tests for the DebugLauncher. Verifies biome list population from
## BiomeRegistry and begin-wealthy resource grants to PlayerInventory.
##
## Coverage target: 85% (per docs/studio/tdd-process-m8.md)
## Ticket: TICKET-0180
class_name TestDebugLauncherUnit
extends TestSuite


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	PlayerInventory.clear_all()
	NavigationSystem.reset()
	FuelSystem.reset_to_full()
	ShipState.reset()


func after_each() -> void:
	PlayerInventory.clear_all()
	NavigationSystem.reset()
	FuelSystem.reset_to_full()
	ShipState.reset()


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Biome list population from registry
	add_test("biome_entries_count_matches_registry", _test_biome_entries_count_matches_registry)
	add_test("biome_entries_contain_valid_ids", _test_biome_entries_contain_valid_ids)
	add_test("biome_entries_have_display_names", _test_biome_entries_have_display_names)
	add_test("biome_entries_cover_all_registry_ids", _test_biome_entries_cover_all_registry_ids)
	add_test("biome_entries_display_names_are_nonempty", _test_biome_entries_display_names_are_nonempty)

	# Begin-wealthy quantity grants
	add_test("wealthy_grants_returns_all_resource_types", _test_wealthy_grants_returns_all_resource_types)
	add_test("wealthy_grants_skips_none_type", _test_wealthy_grants_skips_none_type)
	add_test("wealthy_grants_adds_to_inventory", _test_wealthy_grants_adds_to_inventory)
	add_test("wealthy_grants_correct_quantity_scrap_metal", _test_wealthy_grants_correct_quantity_scrap_metal)
	add_test("wealthy_grants_correct_quantity_metal", _test_wealthy_grants_correct_quantity_metal)
	add_test("wealthy_grants_uses_constant_not_magic_number", _test_wealthy_grants_uses_constant_not_magic_number)
	add_test("wealthy_grants_all_catalog_resources_dynamically", _test_wealthy_grants_all_catalog_resources_dynamically)

	# Edge cases
	add_test("wealthy_grants_on_empty_inventory", _test_wealthy_grants_on_empty_inventory)
	add_test("biome_entries_returns_array", _test_biome_entries_returns_array)


# ── Test Methods: Biome list population ──────────────────

func _test_biome_entries_count_matches_registry() -> void:
	var entries: Array[Dictionary] = DebugLauncher.get_biome_entries()
	assert_equal(entries.size(), BiomeRegistry.BIOME_IDS.size(),
		"biome entry count should match BiomeRegistry.BIOME_IDS.size()")


func _test_biome_entries_contain_valid_ids() -> void:
	var entries: Array[Dictionary] = DebugLauncher.get_biome_entries()
	for entry: Dictionary in entries:
		var biome_id: String = entry["id"] as String
		assert_true(BiomeRegistry.is_valid_biome(biome_id),
			"biome entry id '%s' should be a valid biome in BiomeRegistry" % biome_id)


func _test_biome_entries_have_display_names() -> void:
	var entries: Array[Dictionary] = DebugLauncher.get_biome_entries()
	for entry: Dictionary in entries:
		assert_true(entry.has("display_name"),
			"every biome entry should have a 'display_name' key")


func _test_biome_entries_display_names_are_nonempty() -> void:
	var entries: Array[Dictionary] = DebugLauncher.get_biome_entries()
	for entry: Dictionary in entries:
		var display_name: String = entry["display_name"] as String
		assert_false(display_name == "",
			"biome display_name should not be empty for '%s'" % entry.get("id", "unknown"))


func _test_biome_entries_cover_all_registry_ids() -> void:
	var entries: Array[Dictionary] = DebugLauncher.get_biome_entries()
	var entry_ids: Array[String] = []
	for entry: Dictionary in entries:
		entry_ids.append(entry["id"] as String)
	for biome_id: String in BiomeRegistry.BIOME_IDS:
		assert_true(biome_id in entry_ids,
			"BiomeRegistry ID '%s' should appear in biome entries" % biome_id)


func _test_biome_entries_returns_array() -> void:
	var entries: Array[Dictionary] = DebugLauncher.get_biome_entries()
	assert_true(entries is Array,
		"get_biome_entries should return an Array")


# ── Test Methods: Begin-wealthy grants ───────────────────

func _test_wealthy_grants_returns_all_resource_types() -> void:
	var grants: Dictionary = DebugLauncher.grant_wealthy_resources()
	var expected_count: int = 0
	for resource_key: int in ResourceDefs.RESOURCE_CATALOG:
		var resource_type: ResourceDefs.ResourceType = resource_key as ResourceDefs.ResourceType
		if resource_type == ResourceDefs.ResourceType.NONE:
			continue
		expected_count += 1
		assert_true(grants.has(resource_type),
			"grants should include resource type %s" % ResourceDefs.get_resource_name(resource_type))
	assert_equal(grants.size(), expected_count,
		"grants dictionary should have one entry per non-NONE resource type")


func _test_wealthy_grants_skips_none_type() -> void:
	var grants: Dictionary = DebugLauncher.grant_wealthy_resources()
	assert_false(grants.has(ResourceDefs.ResourceType.NONE),
		"grants should not include NONE resource type")


func _test_wealthy_grants_adds_to_inventory() -> void:
	DebugLauncher.grant_wealthy_resources()
	var total_items: int = 0
	for resource_key: int in ResourceDefs.RESOURCE_CATALOG:
		var resource_type: ResourceDefs.ResourceType = resource_key as ResourceDefs.ResourceType
		if resource_type == ResourceDefs.ResourceType.NONE:
			continue
		total_items += PlayerInventory.get_total_count(resource_type)
	assert_true(total_items > 0,
		"inventory should contain items after grant_wealthy_resources")


func _test_wealthy_grants_correct_quantity_scrap_metal() -> void:
	# Scrap Metal has stack_size=100, so 200 fits in 2 slots on a clean inventory
	DebugLauncher.grant_wealthy_resources()
	var count: int = PlayerInventory.get_total_count(ResourceDefs.ResourceType.SCRAP_METAL)
	assert_equal(count, DebugLauncher.BEGIN_WEALTHY_QUANTITY,
		"should grant full BEGIN_WEALTHY_QUANTITY of Scrap Metal on clean inventory")


func _test_wealthy_grants_correct_quantity_metal() -> void:
	# Metal has stack_size=50, so 200 fits in 4 slots on a clean inventory
	DebugLauncher.grant_wealthy_resources()
	var count: int = PlayerInventory.get_total_count(ResourceDefs.ResourceType.METAL)
	assert_equal(count, DebugLauncher.BEGIN_WEALTHY_QUANTITY,
		"should grant full BEGIN_WEALTHY_QUANTITY of Metal on clean inventory")


func _test_wealthy_grants_uses_constant_not_magic_number() -> void:
	# Verify the constant exists and is 200 (not a magic number in code)
	assert_equal(DebugLauncher.BEGIN_WEALTHY_QUANTITY, 200,
		"BEGIN_WEALTHY_QUANTITY constant should be 200")


func _test_wealthy_grants_all_catalog_resources_dynamically() -> void:
	# Verifies that the grant iterates the RESOURCE_CATALOG dynamically —
	# if a new resource is added to the catalog, it will be included automatically
	var grants: Dictionary = DebugLauncher.grant_wealthy_resources()
	for resource_key: int in ResourceDefs.RESOURCE_CATALOG:
		var resource_type: ResourceDefs.ResourceType = resource_key as ResourceDefs.ResourceType
		if resource_type == ResourceDefs.ResourceType.NONE:
			continue
		assert_true(grants.has(resource_type),
			"grant should dynamically include '%s' from RESOURCE_CATALOG" % ResourceDefs.get_resource_name(resource_type))


func _test_wealthy_grants_on_empty_inventory() -> void:
	# Ensure grants work correctly starting from an empty inventory
	PlayerInventory.clear_all()
	var grants: Dictionary = DebugLauncher.grant_wealthy_resources()
	# At minimum, Scrap Metal (stack 100) should be fully granted
	var scrap_granted: int = grants.get(ResourceDefs.ResourceType.SCRAP_METAL, 0) as int
	assert_equal(scrap_granted, DebugLauncher.BEGIN_WEALTHY_QUANTITY,
		"Scrap Metal grant should equal BEGIN_WEALTHY_QUANTITY on empty inventory")
