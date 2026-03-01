## Unit tests for the travel sequence system. Verifies biome creation by ID,
## transition state management, signal emissions, input toggling, and error
## handling during inter-biome travel. Covers TICKET-0168 acceptance criteria:
## scene transition completes, player position valid after arrival,
## biome_changed signal fired, input re-enabled.
##
## Coverage target: 75% (per docs/studio/tdd-process-m8.md — biome travel mechanics)
## Ticket: TICKET-0168
class_name TestTravelSequenceUnit
extends TestSuite


# ── Mock Classes ─────────────────────────────────────────

## Lightweight mock for ShipInterior — provides is_player_inside() without
## needing the full ship interior scene and geometry.
class MockShipInterior extends Node3D:
	var _player_inside: bool = false

	func is_player_inside() -> bool:
		return _player_inside

	func set_player_inside(value: bool) -> void:
		_player_inside = value


# ── Private Variables ─────────────────────────────────────

var _manager: TravelSequenceManager = null
var _container: Node3D = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	NavigationSystem.reset()
	FuelSystem.reset_to_full()
	PlayerInventory.clear_all()
	ShipState.reset()
	ResourceRespawnSystem.reset()
	InputManager.set_gameplay_inputs_enabled(true)

	_container = Node3D.new()
	_manager = TravelSequenceManager.new()
	_manager.setup(null, null, _container)

	_spy = SignalSpy.new()
	_spy.watch(_manager, "travel_sequence_started")
	_spy.watch(_manager, "travel_sequence_completed")
	_spy.watch(NavigationSystem, "travel_completed")
	_spy.watch(NavigationSystem, "biome_changed")


func after_each() -> void:
	_spy.clear()
	_spy = null

	if _manager:
		_manager.teardown()
		_manager.free()
		_manager = null

	if _container:
		for child: Node in _container.get_children():
			child.free()
		_container.free()
		_container = null

	NavigationSystem.reset()
	FuelSystem.reset_to_full()
	PlayerInventory.clear_all()
	ShipState.reset()
	ResourceRespawnSystem.reset()
	InputManager.set_gameplay_inputs_enabled(true)


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Biome creation by ID
	add_test("create_biome_node_shattered_flats_returns_node", _test_create_biome_node_shattered_flats_returns_node)
	add_test("create_biome_node_rock_warrens_returns_node", _test_create_biome_node_rock_warrens_returns_node)
	add_test("create_biome_node_debris_field_returns_node", _test_create_biome_node_debris_field_returns_node)
	add_test("create_biome_node_invalid_returns_null", _test_create_biome_node_invalid_returns_null)

	# Initial state
	add_test("initial_is_transitioning_is_false", _test_initial_is_transitioning_is_false)

	# Travel sequence signal flow
	add_test("travel_sequence_started_emitted_on_travel", _test_travel_sequence_started_emitted_on_travel)
	add_test("travel_sequence_completed_emitted_after_swap", _test_travel_sequence_completed_emitted_after_swap)
	add_test("biome_changed_signal_fired_on_travel", _test_biome_changed_signal_fired_on_travel)

	# Input management
	add_test("input_re_enabled_after_travel_completes", _test_input_re_enabled_after_travel_completes)

	# Biome swap
	add_test("current_biome_node_updated_after_travel", _test_current_biome_node_updated_after_travel)
	add_test("biome_container_has_child_after_travel", _test_biome_container_has_child_after_travel)
	add_test("old_biome_removed_on_second_travel", _test_old_biome_removed_on_second_travel)

	# Player/ship spawn position
	add_test("get_biome_player_spawn_returns_valid_position", _test_get_biome_player_spawn_returns_valid_position)
	add_test("get_biome_ship_spawn_returns_valid_position", _test_get_biome_ship_spawn_returns_valid_position)

	# Error handling
	add_test("invalid_biome_swap_returns_false", _test_invalid_biome_swap_returns_false)
	add_test("input_stays_enabled_after_failed_swap", _test_input_stays_enabled_after_failed_swap)
	add_test("sequential_travel_works_correctly", _test_sequential_travel_works_correctly)

	# Player reposition when inside ship (BUGFIX: player locked after travel)
	add_test("reposition_skips_player_when_inside_ship", _test_reposition_skips_player_when_inside_ship)
	add_test("reposition_moves_player_when_not_inside_ship", _test_reposition_moves_player_when_not_inside_ship)
	add_test("reposition_moves_player_when_no_ship_interior", _test_reposition_moves_player_when_no_ship_interior)


# ── Test Methods: Biome Creation ─────────────────────────

func _test_create_biome_node_shattered_flats_returns_node() -> void:
	var node: Node3D = TravelSequenceManager.create_biome_node("shattered_flats")
	assert_not_null(node,
		"create_biome_node('shattered_flats') should return a non-null Node3D")
	if node:
		node.free()


func _test_create_biome_node_rock_warrens_returns_node() -> void:
	var node: Node3D = TravelSequenceManager.create_biome_node("rock_warrens")
	assert_not_null(node,
		"create_biome_node('rock_warrens') should return a non-null Node3D")
	if node:
		node.free()


func _test_create_biome_node_debris_field_returns_node() -> void:
	var node: Node3D = TravelSequenceManager.create_biome_node("debris_field")
	assert_not_null(node,
		"create_biome_node('debris_field') should return a non-null Node3D")
	if node:
		node.free()


func _test_create_biome_node_invalid_returns_null() -> void:
	var node: Node3D = TravelSequenceManager.create_biome_node("unknown_void")
	assert_null(node,
		"create_biome_node with invalid ID should return null")


# ── Test Methods: Initial State ──────────────────────────

func _test_initial_is_transitioning_is_false() -> void:
	assert_false(_manager.is_transitioning(),
		"TravelSequenceManager should not be transitioning initially")


# ── Test Methods: Signal Flow ────────────────────────────

func _test_travel_sequence_started_emitted_on_travel() -> void:
	NavigationSystem.initiate_travel("rock_warrens")
	assert_signal_emitted(_spy, "travel_sequence_started",
		"travel_sequence_started should emit when NavigationSystem.travel_completed fires")


func _test_travel_sequence_completed_emitted_after_swap() -> void:
	NavigationSystem.initiate_travel("rock_warrens")
	assert_signal_emitted(_spy, "travel_sequence_completed",
		"travel_sequence_completed should emit after biome swap finishes")


func _test_biome_changed_signal_fired_on_travel() -> void:
	NavigationSystem.initiate_travel("rock_warrens")
	assert_signal_emitted(_spy, "biome_changed",
		"NavigationSystem.biome_changed should fire on successful travel")


# ── Test Methods: Input Management ───────────────────────

func _test_input_re_enabled_after_travel_completes() -> void:
	NavigationSystem.initiate_travel("rock_warrens")
	assert_true(InputManager.is_gameplay_inputs_enabled(),
		"Gameplay inputs should be re-enabled after travel sequence completes")


# ── Test Methods: Biome Swap ─────────────────────────────

func _test_current_biome_node_updated_after_travel() -> void:
	NavigationSystem.initiate_travel("rock_warrens")
	var biome_node: Node3D = _manager.get_current_biome_node()
	assert_not_null(biome_node,
		"Current biome node should be set after travel completes")


func _test_biome_container_has_child_after_travel() -> void:
	NavigationSystem.initiate_travel("rock_warrens")
	assert_true(_container.get_child_count() > 0,
		"Biome container should have a child biome node after travel")


func _test_old_biome_removed_on_second_travel() -> void:
	NavigationSystem.initiate_travel("rock_warrens")
	var first_biome: Node3D = _manager.get_current_biome_node()
	assert_not_null(first_biome,
		"First biome node should exist after first travel")

	NavigationSystem.initiate_travel("debris_field")
	# Container should have exactly one child (the new biome)
	assert_equal(_container.get_child_count(), 1,
		"Container should have exactly one biome node after second travel")
	var second_biome: Node3D = _manager.get_current_biome_node()
	assert_not_null(second_biome,
		"Second biome node should exist after second travel")


# ── Test Methods: Spawn Positions ────────────────────────

func _test_get_biome_player_spawn_returns_valid_position() -> void:
	var biome_node: Node3D = TravelSequenceManager.create_biome_node("rock_warrens")
	assert_not_null(biome_node,
		"Biome node should be created for spawn point test")
	if biome_node:
		add_child(biome_node)
		if biome_node.has_method("generate"):
			biome_node.generate()
		var spawn: Vector3 = TravelSequenceManager.get_biome_player_spawn(biome_node)
		var is_nonzero: bool = spawn != Vector3.ZERO
		assert_true(is_nonzero,
			"Player spawn position should be a non-zero Vector3")
		biome_node.queue_free()


func _test_get_biome_ship_spawn_returns_valid_position() -> void:
	var biome_node: Node3D = TravelSequenceManager.create_biome_node("rock_warrens")
	assert_not_null(biome_node,
		"Biome node should be created for spawn point test")
	if biome_node:
		add_child(biome_node)
		if biome_node.has_method("generate"):
			biome_node.generate()
		var spawn: Vector3 = TravelSequenceManager.get_biome_ship_spawn(biome_node)
		var is_nonzero: bool = spawn != Vector3.ZERO
		assert_true(is_nonzero,
			"Ship spawn position should be a non-zero Vector3")
		biome_node.queue_free()


# ── Test Methods: Error Handling ─────────────────────────

func _test_invalid_biome_swap_returns_false() -> void:
	var result: bool = _manager.execute_biome_swap("nonexistent_biome")
	assert_false(result,
		"execute_biome_swap with invalid biome should return false")


func _test_input_stays_enabled_after_failed_swap() -> void:
	InputManager.set_gameplay_inputs_enabled(true)
	_manager.execute_biome_swap("invalid_zone")
	assert_true(InputManager.is_gameplay_inputs_enabled(),
		"Input should remain enabled after a failed biome swap")


func _test_sequential_travel_works_correctly() -> void:
	NavigationSystem.initiate_travel("rock_warrens")
	assert_equal(NavigationSystem.current_biome, "rock_warrens",
		"Should be at rock_warrens after first travel")

	NavigationSystem.initiate_travel("debris_field")
	assert_equal(NavigationSystem.current_biome, "debris_field",
		"Should be at debris_field after second travel")

	var biome_node: Node3D = _manager.get_current_biome_node()
	assert_not_null(biome_node,
		"Current biome node should be set after sequential travel")


# ── Test Methods: Player Reposition When Inside Ship ─────

## Helper: creates a TravelSequenceManager with a mock player and optional
## mock ship interior, runs a biome swap, and returns the player node so the
## caller can inspect its position. Cleans up the manager on return.
func _swap_with_player(player_inside_ship: bool, include_ship_interior: bool) -> Node3D:
	var player: Node3D = Node3D.new()
	player.name = "MockPlayer"
	player.position = Vector3(99.0, 99.0, 99.0)

	var container: Node3D = Node3D.new()

	var mock_interior: MockShipInterior = null
	if include_ship_interior:
		mock_interior = MockShipInterior.new()
		mock_interior.set_player_inside(player_inside_ship)

	var mgr: TravelSequenceManager = TravelSequenceManager.new()
	mgr.setup(player, null, container, mock_interior)

	# Execute biome swap directly — this calls _reposition_at_spawn internally
	mgr.execute_biome_swap("rock_warrens")

	# Teardown manager and container (but keep player alive for assertions)
	mgr.teardown()
	mgr.free()
	for child: Node in container.get_children():
		child.free()
	container.free()
	if mock_interior:
		mock_interior.free()

	return player


func _test_reposition_skips_player_when_inside_ship() -> void:
	var player: Node3D = _swap_with_player(true, true)
	# Player was at (99, 99, 99) and should NOT have been moved
	assert_equal(player.position, Vector3(99.0, 99.0, 99.0),
		"Player position should be unchanged when inside ship during travel")
	player.free()


func _test_reposition_moves_player_when_not_inside_ship() -> void:
	var player: Node3D = _swap_with_player(false, true)
	# Player was at (99, 99, 99) and SHOULD have been moved to the biome spawn
	var was_moved: bool = player.position != Vector3(99.0, 99.0, 99.0)
	assert_true(was_moved,
		"Player position should change to biome spawn when not inside ship")
	player.free()


func _test_reposition_moves_player_when_no_ship_interior() -> void:
	var player: Node3D = _swap_with_player(false, false)
	# No ship interior reference — backward compat: player SHOULD be repositioned
	var was_moved: bool = player.position != Vector3(99.0, 99.0, 99.0)
	assert_true(was_moved,
		"Player position should change when no ship interior is set (backward compat)")
	player.free()
