## Unit tests for the Navigation system. Verifies biome registry lookups,
## travel cost calculation, travel state machine transitions, and signal
## emissions on arrival and fuel-block events.
##
## Coverage target: 85% (per docs/studio/tdd-process-m8.md)
## Ticket: TICKET-0159
class_name TestNavigationSystemUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────

var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	NavigationSystem.reset()
	FuelSystem.reset_to_full()
	PlayerInventory.clear_all()
	ShipState.reset()
	_spy = SignalSpy.new()
	_spy.watch(NavigationSystem, "travel_completed")
	_spy.watch(NavigationSystem, "travel_blocked")
	_spy.watch(NavigationSystem, "biome_changed")


func after_each() -> void:
	NavigationSystem.reset()
	FuelSystem.reset_to_full()
	PlayerInventory.clear_all()
	ShipState.reset()
	_spy.clear()
	_spy = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Biome registry — registration, lookup, unknown biome rejection
	add_test("biome_registry_has_three_biomes", _test_biome_registry_has_three_biomes)
	add_test("biome_registry_shattered_flats_id_correct", _test_biome_registry_shattered_flats_id_correct)
	add_test("biome_registry_rock_warrens_id_correct", _test_biome_registry_rock_warrens_id_correct)
	add_test("biome_registry_debris_field_id_correct", _test_biome_registry_debris_field_id_correct)
	add_test("biome_registry_get_biome_returns_data", _test_biome_registry_get_biome_returns_data)
	add_test("biome_registry_get_biome_unknown_returns_null", _test_biome_registry_get_biome_unknown_returns_null)
	add_test("biome_registry_is_valid_biome_true_for_known", _test_biome_registry_is_valid_biome_true_for_known)
	add_test("biome_registry_is_valid_biome_false_for_unknown", _test_biome_registry_is_valid_biome_false_for_unknown)
	add_test("biome_registry_terrain_seeds_are_nonzero", _test_biome_registry_terrain_seeds_are_nonzero)
	add_test("biome_registry_terrain_seeds_are_unique", _test_biome_registry_terrain_seeds_are_unique)

	# Biome distances — symmetric, correct values, unknown pairs
	add_test("biome_distance_shattered_flats_to_rock_warrens", _test_biome_distance_shattered_flats_to_rock_warrens)
	add_test("biome_distance_is_symmetric", _test_biome_distance_is_symmetric)
	add_test("biome_distance_same_biome_returns_negative", _test_biome_distance_same_biome_returns_negative)
	add_test("biome_distance_unknown_biome_returns_negative", _test_biome_distance_unknown_biome_returns_negative)
	add_test("biome_distance_all_pairs_are_positive", _test_biome_distance_all_pairs_are_positive)

	# NavigationSystem initial state
	add_test("nav_initial_biome_is_shattered_flats", _test_nav_initial_biome_is_shattered_flats)
	add_test("nav_initial_state_is_idle", _test_nav_initial_state_is_idle)

	# Travel cost calculation
	add_test("nav_get_travel_cost_uses_fuel_formula", _test_nav_get_travel_cost_uses_fuel_formula)
	add_test("nav_get_travel_cost_same_biome_returns_zero", _test_nav_get_travel_cost_same_biome_returns_zero)
	add_test("nav_get_travel_cost_unknown_biome_returns_zero", _test_nav_get_travel_cost_unknown_biome_returns_zero)

	# can_travel_to
	add_test("nav_can_travel_to_true_when_enough_fuel", _test_nav_can_travel_to_true_when_enough_fuel)
	add_test("nav_can_travel_to_false_when_insufficient_fuel", _test_nav_can_travel_to_false_when_insufficient_fuel)
	add_test("nav_can_travel_to_false_for_same_biome", _test_nav_can_travel_to_false_for_same_biome)
	add_test("nav_can_travel_to_false_for_unknown_biome", _test_nav_can_travel_to_false_for_unknown_biome)

	# Travel blocked — insufficient fuel
	add_test("nav_travel_blocked_signal_when_no_fuel", _test_nav_travel_blocked_signal_when_no_fuel)
	add_test("nav_state_idle_after_travel_blocked", _test_nav_state_idle_after_travel_blocked)
	add_test("nav_biome_unchanged_after_travel_blocked", _test_nav_biome_unchanged_after_travel_blocked)
	add_test("nav_travel_completed_not_emitted_when_blocked", _test_nav_travel_completed_not_emitted_when_blocked)

	# State machine transitions — successful travel
	add_test("nav_state_idle_after_successful_travel", _test_nav_state_idle_after_successful_travel)
	add_test("nav_current_biome_updates_on_arrival", _test_nav_current_biome_updates_on_arrival)
	add_test("nav_travel_completed_signal_emitted_on_arrival", _test_nav_travel_completed_signal_emitted_on_arrival)
	add_test("nav_biome_changed_signal_emitted_on_arrival", _test_nav_biome_changed_signal_emitted_on_arrival)
	add_test("nav_fuel_consumed_on_travel", _test_nav_fuel_consumed_on_travel)

	# Edge cases
	add_test("nav_initiate_travel_to_current_biome_is_noop", _test_nav_initiate_travel_to_current_biome_is_noop)
	add_test("nav_initiate_travel_unknown_biome_is_noop", _test_nav_initiate_travel_unknown_biome_is_noop)
	add_test("nav_reset_restores_starting_state", _test_nav_reset_restores_starting_state)


# ── Helpers ───────────────────────────────────────────────

## Drains FuelSystem to zero so any weighted travel attempt will be blocked.
func _drain_fuel_to_zero() -> void:
	FuelSystem.consume_fuel(FuelSystem.fuel_max)


# ── Test Methods ──────────────────────────────────────────

# -- Biome registry --

func _test_biome_registry_has_three_biomes() -> void:
	assert_equal(BiomeRegistry.BIOME_IDS.size(), 3,
		"BiomeRegistry should have exactly 3 registered biomes")


func _test_biome_registry_shattered_flats_id_correct() -> void:
	assert_true("shattered_flats" in BiomeRegistry.BIOME_IDS,
		"shattered_flats should be a registered biome ID")


func _test_biome_registry_rock_warrens_id_correct() -> void:
	assert_true("rock_warrens" in BiomeRegistry.BIOME_IDS,
		"rock_warrens should be a registered biome ID")


func _test_biome_registry_debris_field_id_correct() -> void:
	assert_true("debris_field" in BiomeRegistry.BIOME_IDS,
		"debris_field should be a registered biome ID")


func _test_biome_registry_get_biome_returns_data() -> void:
	var data: BiomeData = BiomeRegistry.get_biome("shattered_flats")
	assert_true(data != null,
		"get_biome('shattered_flats') should return a BiomeData object")
	assert_equal(data.id, "shattered_flats",
		"BiomeData.id should match the requested biome ID")
	assert_false(data.display_name == "",
		"BiomeData.display_name should not be empty")
	assert_true(data.terrain_seed != 0,
		"BiomeData.terrain_seed should be non-zero")


func _test_biome_registry_get_biome_unknown_returns_null() -> void:
	var data: BiomeData = BiomeRegistry.get_biome("unknown_void")
	assert_true(data == null,
		"get_biome with unknown ID should return null")


func _test_biome_registry_is_valid_biome_true_for_known() -> void:
	assert_true(BiomeRegistry.is_valid_biome("shattered_flats"),
		"is_valid_biome should return true for a registered biome ID")


func _test_biome_registry_is_valid_biome_false_for_unknown() -> void:
	assert_false(BiomeRegistry.is_valid_biome("void_sector"),
		"is_valid_biome should return false for an unregistered ID")


func _test_biome_registry_terrain_seeds_are_nonzero() -> void:
	for id: String in BiomeRegistry.BIOME_IDS:
		var data: BiomeData = BiomeRegistry.get_biome(id)
		assert_true(data.terrain_seed != 0,
			"terrain_seed for '%s' should be non-zero" % id)


func _test_biome_registry_terrain_seeds_are_unique() -> void:
	var seen_seeds: Array[int] = []
	for id: String in BiomeRegistry.BIOME_IDS:
		var data: BiomeData = BiomeRegistry.get_biome(id)
		assert_false(data.terrain_seed in seen_seeds,
			"terrain_seed for '%s' (%d) should be unique" % [id, data.terrain_seed])
		seen_seeds.append(data.terrain_seed)


# -- Biome distances --

func _test_biome_distance_shattered_flats_to_rock_warrens() -> void:
	var dist: float = BiomeRegistry.get_distance("shattered_flats", "rock_warrens")
	assert_true(dist > 0.0,
		"Distance from shattered_flats to rock_warrens should be positive")


func _test_biome_distance_is_symmetric() -> void:
	var dist_ab: float = BiomeRegistry.get_distance("shattered_flats", "rock_warrens")
	var dist_ba: float = BiomeRegistry.get_distance("rock_warrens", "shattered_flats")
	assert_equal(dist_ab, dist_ba,
		"Distance A→B should equal distance B→A (symmetric)")


func _test_biome_distance_same_biome_returns_negative() -> void:
	var dist: float = BiomeRegistry.get_distance("shattered_flats", "shattered_flats")
	assert_true(dist < 0.0,
		"Distance from a biome to itself should be negative (no travel)")


func _test_biome_distance_unknown_biome_returns_negative() -> void:
	var dist: float = BiomeRegistry.get_distance("shattered_flats", "unknown_zone")
	assert_true(dist < 0.0,
		"Distance to an unknown biome should be negative")


func _test_biome_distance_all_pairs_are_positive() -> void:
	var ids: PackedStringArray = BiomeRegistry.BIOME_IDS
	for i: int in range(ids.size()):
		for j: int in range(ids.size()):
			if i == j:
				continue
			var dist: float = BiomeRegistry.get_distance(ids[i], ids[j])
			assert_true(dist > 0.0,
				"Distance from '%s' to '%s' should be positive" % [ids[i], ids[j]])


# -- NavigationSystem initial state --

func _test_nav_initial_biome_is_shattered_flats() -> void:
	assert_equal(NavigationSystem.current_biome, "shattered_flats",
		"NavigationSystem should start at shattered_flats")


func _test_nav_initial_state_is_idle() -> void:
	assert_equal(NavigationSystem.get_state(),
		NavigationSystem.TravelState.IDLE,
		"NavigationSystem should start in IDLE state")


# -- Travel cost calculation --

func _test_nav_get_travel_cost_uses_fuel_formula() -> void:
	# Add inventory items so ship_weight > 0 and cost is non-trivial.
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 10)
	var ship_weight: float = FuelSystem.calculate_ship_weight()
	var expected_distance: float = BiomeRegistry.get_distance(
		"shattered_flats", "rock_warrens")
	var expected_cost: float = FuelSystem.calculate_cost(expected_distance, ship_weight)
	var actual_cost: float = NavigationSystem.get_travel_cost("rock_warrens")
	assert_equal(actual_cost, expected_cost,
		"get_travel_cost should match FuelSystem.calculate_cost for the distance and weight")


func _test_nav_get_travel_cost_same_biome_returns_zero() -> void:
	var cost: float = NavigationSystem.get_travel_cost("shattered_flats")
	assert_equal(cost, 0.0,
		"get_travel_cost to current biome should return 0.0")


func _test_nav_get_travel_cost_unknown_biome_returns_zero() -> void:
	var cost: float = NavigationSystem.get_travel_cost("unknown_sector")
	assert_equal(cost, 0.0,
		"get_travel_cost to unknown biome should return 0.0")


# -- can_travel_to --

func _test_nav_can_travel_to_true_when_enough_fuel() -> void:
	# Full tank with base ship weight — cost is affordable.
	assert_true(NavigationSystem.can_travel_to("rock_warrens"),
		"can_travel_to should return true when fuel is sufficient")


func _test_nav_can_travel_to_false_when_insufficient_fuel() -> void:
	# Give ship weight so cost > 0, then empty the tank.
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 50)
	_drain_fuel_to_zero()
	assert_false(NavigationSystem.can_travel_to("rock_warrens"),
		"can_travel_to should return false when tank is empty")


func _test_nav_can_travel_to_false_for_same_biome() -> void:
	assert_false(NavigationSystem.can_travel_to("shattered_flats"),
		"can_travel_to current biome should return false")


func _test_nav_can_travel_to_false_for_unknown_biome() -> void:
	assert_false(NavigationSystem.can_travel_to("phantom_sector"),
		"can_travel_to unknown biome should return false")


# -- Travel blocked --

func _test_nav_travel_blocked_signal_when_no_fuel() -> void:
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 50)
	_drain_fuel_to_zero()
	NavigationSystem.initiate_travel("rock_warrens")
	assert_signal_emitted(_spy, "travel_blocked",
		"travel_blocked should fire when fuel is insufficient")


func _test_nav_state_idle_after_travel_blocked() -> void:
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 50)
	_drain_fuel_to_zero()
	NavigationSystem.initiate_travel("rock_warrens")
	assert_equal(NavigationSystem.get_state(),
		NavigationSystem.TravelState.IDLE,
		"State should remain IDLE after travel is blocked")


func _test_nav_biome_unchanged_after_travel_blocked() -> void:
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 50)
	_drain_fuel_to_zero()
	NavigationSystem.initiate_travel("rock_warrens")
	assert_equal(NavigationSystem.current_biome, "shattered_flats",
		"current_biome should not change when travel is blocked")


func _test_nav_travel_completed_not_emitted_when_blocked() -> void:
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 50)
	_drain_fuel_to_zero()
	NavigationSystem.initiate_travel("rock_warrens")
	assert_false(_spy.was_emitted("travel_completed"),
		"travel_completed should not fire when travel is blocked")


# -- State machine transitions (successful travel) --

func _test_nav_state_idle_after_successful_travel() -> void:
	# Base weight only → cost is affordable → travel succeeds on full tank
	NavigationSystem.initiate_travel("rock_warrens")
	assert_equal(NavigationSystem.get_state(),
		NavigationSystem.TravelState.IDLE,
		"State should be IDLE after successful travel completes")


func _test_nav_current_biome_updates_on_arrival() -> void:
	NavigationSystem.initiate_travel("rock_warrens")
	assert_equal(NavigationSystem.current_biome, "rock_warrens",
		"current_biome should update to destination on arrival")


func _test_nav_travel_completed_signal_emitted_on_arrival() -> void:
	NavigationSystem.initiate_travel("rock_warrens")
	assert_signal_emitted(_spy, "travel_completed",
		"travel_completed should fire on successful arrival")


func _test_nav_biome_changed_signal_emitted_on_arrival() -> void:
	NavigationSystem.initiate_travel("rock_warrens")
	assert_signal_emitted(_spy, "biome_changed",
		"biome_changed should fire on successful arrival")


func _test_nav_fuel_consumed_on_travel() -> void:
	# Add inventory weight so cost is non-zero and fuel consumption is detectable.
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 50)
	var fuel_before: float = FuelSystem.fuel_current
	NavigationSystem.initiate_travel("rock_warrens")
	var fuel_after: float = FuelSystem.fuel_current
	assert_true(fuel_after < fuel_before,
		"Fuel should decrease after a successful jump")


# -- Edge cases --

func _test_nav_initiate_travel_to_current_biome_is_noop() -> void:
	NavigationSystem.initiate_travel("shattered_flats")
	assert_false(_spy.was_emitted("travel_completed"),
		"Initiating travel to current biome should be a no-op (no travel_completed)")
	assert_equal(NavigationSystem.current_biome, "shattered_flats",
		"current_biome should remain unchanged when travelling to current biome")


func _test_nav_initiate_travel_unknown_biome_is_noop() -> void:
	NavigationSystem.initiate_travel("fake_zone")
	assert_false(_spy.was_emitted("travel_completed"),
		"Initiating travel to unknown biome should not emit travel_completed")
	assert_false(_spy.was_emitted("travel_blocked"),
		"Initiating travel to unknown biome should not emit travel_blocked")
	assert_equal(NavigationSystem.current_biome, "shattered_flats",
		"current_biome should remain unchanged for unknown destination")


func _test_nav_reset_restores_starting_state() -> void:
	NavigationSystem.initiate_travel("rock_warrens")
	assert_equal(NavigationSystem.current_biome, "rock_warrens",
		"Sanity check: should have travelled to rock_warrens")
	NavigationSystem.reset()
	assert_equal(NavigationSystem.current_biome, "shattered_flats",
		"reset() should restore current_biome to shattered_flats")
	assert_equal(NavigationSystem.get_state(),
		NavigationSystem.TravelState.IDLE,
		"reset() should restore state to IDLE")
