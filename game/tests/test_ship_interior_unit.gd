## Unit tests for ShipInterior module placement zones. Verifies 4-zone layout,
## place/remove lifecycle, zone queries, and boundary checks.
class_name TestShipInteriorUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _interior: ShipInterior = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_interior = ShipInterior.new()
	add_child(_interior)


func after_each() -> void:
	_interior.queue_free()
	_interior = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Zone count
	add_test("zone_count_is_four", _test_zone_count_is_four)
	# Initial state
	add_test("all_zones_initially_unoccupied", _test_all_zones_initially_unoccupied)
	add_test("first_empty_zone_returns_zero_initially", _test_first_empty_zone_returns_zero_initially)
	add_test("no_module_at_any_zone_initially", _test_no_module_at_any_zone_initially)
	# Placement
	add_test("place_module_in_zone_0_marks_occupied", _test_place_module_in_zone_0_marks_occupied)
	add_test("place_module_in_zone_1_marks_occupied", _test_place_module_in_zone_1_marks_occupied)
	add_test("place_module_in_zone_2_marks_occupied", _test_place_module_in_zone_2_marks_occupied)
	add_test("place_module_in_zone_3_marks_occupied", _test_place_module_in_zone_3_marks_occupied)
	add_test("place_module_positions_at_zone_center", _test_place_module_positions_at_zone_center)
	add_test("first_empty_zone_skips_occupied", _test_first_empty_zone_skips_occupied)
	add_test("first_empty_zone_returns_neg1_when_all_full", _test_first_empty_zone_returns_neg1_when_all_full)
	# Remove
	add_test("remove_module_frees_zone", _test_remove_module_frees_zone)
	add_test("get_module_at_zone_returns_placed_node", _test_get_module_at_zone_returns_placed_node)
	# Boundary
	add_test("is_zone_occupied_invalid_index_returns_false", _test_is_zone_occupied_invalid_index_returns_false)
	add_test("place_module_invalid_index_does_nothing", _test_place_module_invalid_index_does_nothing)
	add_test("get_module_at_invalid_index_returns_null", _test_get_module_at_invalid_index_returns_null)


# ── Test Methods ──────────────────────────────────────────

func _test_zone_count_is_four() -> void:
	assert_equal(_interior.get_zone_count(), 4, "Ship interior should have 4 placement zones")


func _test_all_zones_initially_unoccupied() -> void:
	assert_false(_interior.is_zone_occupied(0), "Zone 0 should be unoccupied initially")
	assert_false(_interior.is_zone_occupied(1), "Zone 1 should be unoccupied initially")
	assert_false(_interior.is_zone_occupied(2), "Zone 2 should be unoccupied initially")
	assert_false(_interior.is_zone_occupied(3), "Zone 3 should be unoccupied initially")


func _test_first_empty_zone_returns_zero_initially() -> void:
	assert_equal(_interior.get_first_empty_zone(), 0,
		"First empty zone should be 0 when all are empty")


func _test_no_module_at_any_zone_initially() -> void:
	assert_null(_interior.get_module_at_zone(0), "No module at zone 0 initially")
	assert_null(_interior.get_module_at_zone(1), "No module at zone 1 initially")
	assert_null(_interior.get_module_at_zone(2), "No module at zone 2 initially")
	assert_null(_interior.get_module_at_zone(3), "No module at zone 3 initially")


func _test_place_module_in_zone_0_marks_occupied() -> void:
	var mock: Node3D = Node3D.new()
	_interior.place_module_in_zone(0, mock)
	assert_true(_interior.is_zone_occupied(0), "Zone 0 should be occupied after placement")


func _test_place_module_in_zone_1_marks_occupied() -> void:
	var mock: Node3D = Node3D.new()
	_interior.place_module_in_zone(1, mock)
	assert_true(_interior.is_zone_occupied(1), "Zone 1 should be occupied after placement")


func _test_place_module_in_zone_2_marks_occupied() -> void:
	var mock: Node3D = Node3D.new()
	_interior.place_module_in_zone(2, mock)
	assert_true(_interior.is_zone_occupied(2), "Zone 2 should be occupied after placement")


func _test_place_module_in_zone_3_marks_occupied() -> void:
	var mock: Node3D = Node3D.new()
	_interior.place_module_in_zone(3, mock)
	assert_true(_interior.is_zone_occupied(3), "Zone 3 should be occupied after placement")


func _test_place_module_positions_at_zone_center() -> void:
	var mock_a: Node3D = Node3D.new()
	var mock_b: Node3D = Node3D.new()
	var mock_c: Node3D = Node3D.new()
	var mock_d: Node3D = Node3D.new()
	_interior.place_module_in_zone(0, mock_a)
	_interior.place_module_in_zone(1, mock_b)
	_interior.place_module_in_zone(2, mock_c)
	_interior.place_module_in_zone(3, mock_d)
	assert_equal(mock_a.position, Vector3(-2.5, 0.0, 4.5),
		"Zone 0 module should be at ZONE_A_CENTER")
	assert_equal(mock_b.position, Vector3(2.5, 0.0, 4.5),
		"Zone 1 module should be at ZONE_B_CENTER")
	assert_equal(mock_c.position, Vector3(-2.5, 0.0, -0.5),
		"Zone 2 module should be at ZONE_C_CENTER")
	assert_equal(mock_d.position, Vector3(2.5, 0.0, -0.5),
		"Zone 3 module should be at ZONE_D_CENTER")


func _test_first_empty_zone_skips_occupied() -> void:
	_interior.place_module_in_zone(0, Node3D.new())
	_interior.place_module_in_zone(1, Node3D.new())
	_interior.place_module_in_zone(2, Node3D.new())
	assert_equal(_interior.get_first_empty_zone(), 3,
		"First empty zone should be 3 when zones 0-2 are occupied")


func _test_first_empty_zone_returns_neg1_when_all_full() -> void:
	_interior.place_module_in_zone(0, Node3D.new())
	_interior.place_module_in_zone(1, Node3D.new())
	_interior.place_module_in_zone(2, Node3D.new())
	_interior.place_module_in_zone(3, Node3D.new())
	assert_equal(_interior.get_first_empty_zone(), -1,
		"First empty zone should be -1 when all 4 zones are full")


func _test_remove_module_frees_zone() -> void:
	_interior.place_module_in_zone(1, Node3D.new())
	assert_true(_interior.is_zone_occupied(1), "Zone 1 should be occupied before removal")
	_interior.remove_module_from_zone(1)
	assert_false(_interior.is_zone_occupied(1), "Zone 1 should be unoccupied after removal")


func _test_get_module_at_zone_returns_placed_node() -> void:
	var mock: Node3D = Node3D.new()
	_interior.place_module_in_zone(2, mock)
	assert_equal(_interior.get_module_at_zone(2), mock,
		"get_module_at_zone(2) should return the placed node")


func _test_is_zone_occupied_invalid_index_returns_false() -> void:
	assert_false(_interior.is_zone_occupied(-1), "Negative index should return false")
	assert_false(_interior.is_zone_occupied(4), "Index 4 (out of range) should return false")
	assert_false(_interior.is_zone_occupied(99), "Index 99 should return false")


func _test_place_module_invalid_index_does_nothing() -> void:
	var mock: Node3D = Node3D.new()
	_interior.place_module_in_zone(4, mock)
	assert_false(_interior.is_zone_occupied(0), "Zone 0 should remain unoccupied")
	assert_false(_interior.is_zone_occupied(1), "Zone 1 should remain unoccupied")
	assert_false(_interior.is_zone_occupied(2), "Zone 2 should remain unoccupied")
	assert_false(_interior.is_zone_occupied(3), "Zone 3 should remain unoccupied")
	mock.queue_free()


func _test_get_module_at_invalid_index_returns_null() -> void:
	assert_null(_interior.get_module_at_zone(-1), "Negative index should return null")
	assert_null(_interior.get_module_at_zone(4), "Index 4 should return null")
