## Unit tests for the DebugLauncher. Verifies biome list population from BiomeRegistry.
## Note: begin-wealthy and Global state tests moved to test_game_startup_unit.gd (TICKET-0235)
## following the TICKET-0233 refactor that removed grant_wealthy_resources(), _launch(),
## and _build_debug_world() from DebugLauncher.
##
## Coverage: biome registry integration
## Ticket: TICKET-0180 (updated TICKET-0235)
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

	# Edge cases
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


