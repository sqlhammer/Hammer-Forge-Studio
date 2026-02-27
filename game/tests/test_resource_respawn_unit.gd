## Unit tests for the Resource Respawn system. Verifies biome-change triggered respawn,
## surface node respawn logic, respawn timing, and interactions with the deposit registry
## and navigation system.
##
## Coverage target: 75% (per docs/studio/tdd-process-m8.md — biome travel mechanics)
## Ticket: TICKET-0161
class_name TestResourceRespawnUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────

var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	NavigationSystem.reset()
	FuelSystem.reset_to_full()
	PlayerInventory.clear_all()
	ShipState.reset()
	ResourceRespawnSystem.reset()
	_spy = SignalSpy.new()
	_spy.watch(ResourceRespawnSystem, "respawn_queued")
	_spy.watch(ResourceRespawnSystem, "respawn_applied")


func after_each() -> void:
	NavigationSystem.reset()
	FuelSystem.reset_to_full()
	PlayerInventory.clear_all()
	ShipState.reset()
	ResourceRespawnSystem.reset()
	_spy.clear()
	_spy = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Initial state
	add_test("respawn_initial_previous_biome_matches_nav", _test_respawn_initial_previous_biome_matches_nav)
	add_test("respawn_no_pending_respawns_on_init", _test_respawn_no_pending_respawns_on_init)
	add_test("respawn_is_first_visit_true_for_unvisited_biome", _test_respawn_is_first_visit_true_for_unvisited_biome)

	# report_depleted — surface nodes tracked
	add_test("report_depleted_surface_node_added_to_active", _test_report_depleted_surface_node_added_to_active)
	add_test("report_depleted_duplicate_deposit_not_double_counted", _test_report_depleted_duplicate_deposit_not_double_counted)

	# Deep nodes excluded
	add_test("deep_node_excluded_from_respawn_queue", _test_deep_node_excluded_from_respawn_queue)
	add_test("deep_node_infinite_true_not_in_pending_after_departure", _test_deep_node_infinite_true_not_in_pending_after_departure)

	# Biome-change trigger — respawn fires on biome transition
	add_test("respawn_queued_fires_on_departure_with_depleted_nodes", _test_respawn_queued_fires_on_departure_with_depleted_nodes)
	add_test("respawn_queued_not_fired_when_no_depletions", _test_respawn_queued_not_fired_when_no_depletions)
	add_test("respawn_queued_passes_correct_biome_id", _test_respawn_queued_passes_correct_biome_id)

	# Correct biome targeted
	add_test("pending_respawns_targets_correct_biome", _test_pending_respawns_targets_correct_biome)
	add_test("pending_respawns_other_biome_unaffected", _test_pending_respawns_other_biome_unaffected)
	add_test("get_pending_respawns_returns_deposit_ids", _test_get_pending_respawns_returns_deposit_ids)
	add_test("get_pending_respawns_empty_for_unknown_biome", _test_get_pending_respawns_empty_for_unknown_biome)

	# No respawn on first visit
	add_test("no_respawn_on_first_visit_to_new_biome", _test_no_respawn_on_first_visit_to_new_biome)
	add_test("is_first_visit_false_after_departure", _test_is_first_visit_false_after_departure)
	add_test("respawn_applied_not_emitted_on_first_visit", _test_respawn_applied_not_emitted_on_first_visit)

	# On arrival — respawn applied on return visit
	add_test("respawn_applied_fires_on_return_visit", _test_respawn_applied_fires_on_return_visit)
	add_test("respawn_applied_passes_correct_biome_id", _test_respawn_applied_passes_correct_biome_id)
	add_test("respawn_applied_not_fired_without_pending_respawns", _test_respawn_applied_not_fired_without_pending_respawns)

	# mark_respawns_applied clears queue
	add_test("mark_respawns_applied_clears_pending_queue", _test_mark_respawns_applied_clears_pending_queue)
	add_test("get_pending_respawns_empty_after_mark_applied", _test_get_pending_respawns_empty_after_mark_applied)

	# Repeated departure/return cycles
	add_test("repeated_departure_return_respawn_fires_each_cycle", _test_repeated_departure_return_respawn_fires_each_cycle)
	add_test("repeated_cycles_correct_emission_counts", _test_repeated_cycles_correct_emission_counts)

	# Reset
	add_test("reset_clears_pending_respawns", _test_reset_clears_pending_respawns)
	add_test("reset_clears_is_first_visit_state", _test_reset_clears_is_first_visit_state)


# ── Helpers ───────────────────────────────────────────────

## Performs a full travel from current biome to destination_id with full fuel.
func _travel_to(destination_id: String) -> void:
	FuelSystem.reset_to_full()
	NavigationSystem.initiate_travel(destination_id)


# ── Test Methods ──────────────────────────────────────────

# -- Initial state --

func _test_respawn_initial_previous_biome_matches_nav() -> void:
	# After reset(), _previous_biome should match NavigationSystem.current_biome
	assert_equal(NavigationSystem.current_biome, "shattered_flats",
		"NavigationSystem should start at shattered_flats after reset")
	assert_true(ResourceRespawnSystem.is_first_visit("shattered_flats"),
		"shattered_flats should be a first visit immediately after reset")


func _test_respawn_no_pending_respawns_on_init() -> void:
	var pending: Array = ResourceRespawnSystem.get_pending_respawns("shattered_flats")
	assert_equal(pending.size(), 0,
		"No pending respawns should exist before any travel occurs")


func _test_respawn_is_first_visit_true_for_unvisited_biome() -> void:
	assert_true(ResourceRespawnSystem.is_first_visit("rock_warrens"),
		"rock_warrens should be a first visit before any travel")
	assert_true(ResourceRespawnSystem.is_first_visit("debris_field"),
		"debris_field should be a first visit before any travel")


# -- report_depleted — surface nodes tracked --

func _test_report_depleted_surface_node_added_to_active() -> void:
	ResourceRespawnSystem.report_depleted("deposit_001", "shattered_flats")
	# Travel away to trigger departure logic
	_travel_to("rock_warrens")
	var pending: Array = ResourceRespawnSystem.get_pending_respawns("shattered_flats")
	assert_equal(pending.size(), 1,
		"One deposit should be pending respawn after departure with one reported depletion")
	assert_true("deposit_001" in pending,
		"deposit_001 should be in the pending respawn list for shattered_flats")


func _test_report_depleted_duplicate_deposit_not_double_counted() -> void:
	ResourceRespawnSystem.report_depleted("deposit_001", "shattered_flats")
	ResourceRespawnSystem.report_depleted("deposit_001", "shattered_flats")
	_travel_to("rock_warrens")
	var pending: Array = ResourceRespawnSystem.get_pending_respawns("shattered_flats")
	assert_equal(pending.size(), 1,
		"Duplicate report_depleted calls should only count the deposit once")


# -- Deep nodes excluded --

func _test_deep_node_excluded_from_respawn_queue() -> void:
	# Report a deep node (infinite=true) — should be silently excluded
	ResourceRespawnSystem.report_depleted("deep_node_001", "shattered_flats", true)
	_travel_to("rock_warrens")
	var pending: Array = ResourceRespawnSystem.get_pending_respawns("shattered_flats")
	assert_equal(pending.size(), 0,
		"Deep node with infinite=true should not appear in pending respawns")


func _test_deep_node_infinite_true_not_in_pending_after_departure() -> void:
	# Mix of surface and deep nodes: only surface should queue
	ResourceRespawnSystem.report_depleted("surface_001", "shattered_flats", false)
	ResourceRespawnSystem.report_depleted("deep_001", "shattered_flats", true)
	ResourceRespawnSystem.report_depleted("surface_002", "shattered_flats", false)
	_travel_to("rock_warrens")
	var pending: Array = ResourceRespawnSystem.get_pending_respawns("shattered_flats")
	assert_equal(pending.size(), 2,
		"Only surface (non-infinite) deposits should be in pending respawns")
	assert_true("surface_001" in pending,
		"surface_001 should be queued for respawn")
	assert_true("surface_002" in pending,
		"surface_002 should be queued for respawn")
	assert_false("deep_001" in pending,
		"deep_001 (infinite) should NOT be queued for respawn")


# -- Biome-change trigger — respawn queued on departure --

func _test_respawn_queued_fires_on_departure_with_depleted_nodes() -> void:
	ResourceRespawnSystem.report_depleted("deposit_001", "shattered_flats")
	_travel_to("rock_warrens")
	assert_signal_emitted(_spy, "respawn_queued",
		"respawn_queued should fire when departing a biome with depleted surface nodes")


func _test_respawn_queued_not_fired_when_no_depletions() -> void:
	# Travel without any depletion reports — respawn_queued should NOT fire
	_travel_to("rock_warrens")
	assert_false(_spy.was_emitted("respawn_queued"),
		"respawn_queued should NOT fire when no surface deposits were depleted in departed biome")


func _test_respawn_queued_passes_correct_biome_id() -> void:
	ResourceRespawnSystem.report_depleted("deposit_001", "shattered_flats")
	_travel_to("rock_warrens")
	var args: Array = _spy.get_emission_args("respawn_queued", 0)
	assert_equal(args.size(), 1,
		"respawn_queued should emit with one argument (biome_id)")
	assert_equal(args[0], "shattered_flats",
		"respawn_queued should pass the departed biome ID (shattered_flats)")


# -- Correct biome targeted --

func _test_pending_respawns_targets_correct_biome() -> void:
	ResourceRespawnSystem.report_depleted("deposit_001", "shattered_flats")
	_travel_to("rock_warrens")
	var pending_flats: Array = ResourceRespawnSystem.get_pending_respawns("shattered_flats")
	assert_equal(pending_flats.size(), 1,
		"shattered_flats should have 1 pending respawn after departure")


func _test_pending_respawns_other_biome_unaffected() -> void:
	ResourceRespawnSystem.report_depleted("deposit_001", "shattered_flats")
	_travel_to("rock_warrens")
	var pending_warrens: Array = ResourceRespawnSystem.get_pending_respawns("rock_warrens")
	assert_equal(pending_warrens.size(), 0,
		"rock_warrens should have 0 pending respawns (deposits were in shattered_flats)")


func _test_get_pending_respawns_returns_deposit_ids() -> void:
	ResourceRespawnSystem.report_depleted("node_alpha", "shattered_flats")
	ResourceRespawnSystem.report_depleted("node_beta", "shattered_flats")
	_travel_to("rock_warrens")
	var pending: Array = ResourceRespawnSystem.get_pending_respawns("shattered_flats")
	assert_equal(pending.size(), 2,
		"Both deposit IDs should be in the pending respawn list")
	assert_true("node_alpha" in pending,
		"node_alpha should be in pending respawns")
	assert_true("node_beta" in pending,
		"node_beta should be in pending respawns")


func _test_get_pending_respawns_empty_for_unknown_biome() -> void:
	var pending: Array = ResourceRespawnSystem.get_pending_respawns("unknown_biome_x")
	assert_equal(pending.size(), 0,
		"get_pending_respawns for an unknown biome ID should return empty array")


# -- No respawn on first visit --

func _test_no_respawn_on_first_visit_to_new_biome() -> void:
	# Travel to rock_warrens for the first time (never departed from it before)
	_travel_to("rock_warrens")
	assert_false(_spy.was_emitted("respawn_applied"),
		"respawn_applied should NOT fire on the first visit to a biome")


func _test_is_first_visit_false_after_departure() -> void:
	_travel_to("rock_warrens")
	# shattered_flats was departed — no longer a first visit
	assert_false(ResourceRespawnSystem.is_first_visit("shattered_flats"),
		"shattered_flats should no longer be a first visit after the player departs")


func _test_respawn_applied_not_emitted_on_first_visit() -> void:
	# Travel A→B→C (both B and C are first visits from this starting state)
	ResourceRespawnSystem.report_depleted("deposit_001", "shattered_flats")
	_travel_to("rock_warrens")
	_spy.clear()
	_travel_to("debris_field")
	assert_false(_spy.was_emitted("respawn_applied"),
		"respawn_applied should NOT fire when arriving at a biome for the first time")


# -- On arrival — respawn applied on return visit --

func _test_respawn_applied_fires_on_return_visit() -> void:
	ResourceRespawnSystem.report_depleted("deposit_001", "shattered_flats")
	_travel_to("rock_warrens")
	_spy.clear()
	_travel_to("shattered_flats")
	assert_signal_emitted(_spy, "respawn_applied",
		"respawn_applied should fire when returning to a biome with pending respawns")


func _test_respawn_applied_passes_correct_biome_id() -> void:
	ResourceRespawnSystem.report_depleted("deposit_001", "shattered_flats")
	_travel_to("rock_warrens")
	_spy.clear()
	_travel_to("shattered_flats")
	var args: Array = _spy.get_emission_args("respawn_applied", 0)
	assert_equal(args.size(), 1,
		"respawn_applied should emit with one argument (biome_id)")
	assert_equal(args[0], "shattered_flats",
		"respawn_applied should pass the returned-to biome ID (shattered_flats)")


func _test_respawn_applied_not_fired_without_pending_respawns() -> void:
	# Return to shattered_flats with NO depletions queued
	_travel_to("rock_warrens")
	_spy.clear()
	_travel_to("shattered_flats")
	assert_false(_spy.was_emitted("respawn_applied"),
		"respawn_applied should NOT fire if no deposits were depleted before departure")


# -- mark_respawns_applied clears queue --

func _test_mark_respawns_applied_clears_pending_queue() -> void:
	ResourceRespawnSystem.report_depleted("deposit_001", "shattered_flats")
	_travel_to("rock_warrens")
	var before_clear: Array = ResourceRespawnSystem.get_pending_respawns("shattered_flats")
	assert_equal(before_clear.size(), 1,
		"Should have 1 pending respawn before clearing")
	ResourceRespawnSystem.mark_respawns_applied("shattered_flats")
	var after_clear: Array = ResourceRespawnSystem.get_pending_respawns("shattered_flats")
	assert_equal(after_clear.size(), 0,
		"Pending respawns should be empty after mark_respawns_applied")


func _test_get_pending_respawns_empty_after_mark_applied() -> void:
	ResourceRespawnSystem.report_depleted("node_a", "shattered_flats")
	ResourceRespawnSystem.report_depleted("node_b", "shattered_flats")
	_travel_to("rock_warrens")
	ResourceRespawnSystem.mark_respawns_applied("shattered_flats")
	var pending: Array = ResourceRespawnSystem.get_pending_respawns("shattered_flats")
	assert_true(pending.is_empty(),
		"get_pending_respawns should return empty array after mark_respawns_applied")


# -- Repeated departure/return cycles --

func _test_repeated_departure_return_respawn_fires_each_cycle() -> void:
	# Cycle 1: depart shattered_flats → return
	ResourceRespawnSystem.report_depleted("deposit_001", "shattered_flats")
	_travel_to("rock_warrens")
	_travel_to("shattered_flats")
	assert_signal_emitted(_spy, "respawn_applied",
		"respawn_applied should fire on first return to shattered_flats")
	ResourceRespawnSystem.mark_respawns_applied("shattered_flats")

	# Cycle 2: deplete again, depart, return
	_spy.clear()
	ResourceRespawnSystem.report_depleted("deposit_002", "shattered_flats")
	_travel_to("rock_warrens")
	_travel_to("shattered_flats")
	assert_signal_emitted(_spy, "respawn_applied",
		"respawn_applied should fire again on the second return to shattered_flats")


func _test_repeated_cycles_correct_emission_counts() -> void:
	# Three full departure/return cycles on shattered_flats
	for i: int in range(3):
		ResourceRespawnSystem.report_depleted("deposit_%d" % i, "shattered_flats")
		_travel_to("rock_warrens")
		_travel_to("shattered_flats")
		ResourceRespawnSystem.mark_respawns_applied("shattered_flats")
	var count: int = _spy.get_emission_count("respawn_applied")
	assert_equal(count, 3,
		"respawn_applied should fire once per return visit across 3 departure/return cycles")


# -- Reset --

func _test_reset_clears_pending_respawns() -> void:
	ResourceRespawnSystem.report_depleted("deposit_001", "shattered_flats")
	_travel_to("rock_warrens")
	# There should be pending respawns now
	var before_reset: Array = ResourceRespawnSystem.get_pending_respawns("shattered_flats")
	assert_equal(before_reset.size(), 1,
		"Should have pending respawn before reset")
	ResourceRespawnSystem.reset()
	var after_reset: Array = ResourceRespawnSystem.get_pending_respawns("shattered_flats")
	assert_equal(after_reset.size(), 0,
		"Pending respawns should be empty after reset")


func _test_reset_clears_is_first_visit_state() -> void:
	_travel_to("rock_warrens")
	assert_false(ResourceRespawnSystem.is_first_visit("shattered_flats"),
		"shattered_flats should not be first visit after departure")
	ResourceRespawnSystem.reset()
	assert_true(ResourceRespawnSystem.is_first_visit("shattered_flats"),
		"shattered_flats should be first visit again after reset")
