## Unit tests for the CompassBar system. Verifies marker management, deduplication,
## capacity limits, depletion cleanup, and bearing-to-screen-x calculation.
class_name TestCompassBarUnit
extends TestSuite

# -- Private Variables ---------------------------------------------
var _compass: CompassBar = null
var _deposit_a: Deposit = null
var _deposit_b: Deposit = null
var _deposit_c: Deposit = null


# -- Setup / Teardown ----------------------------------------------

func before_each() -> void:
	_compass = CompassBar.new()
	add_child(_compass)
	_deposit_a = _create_deposit(40)
	_deposit_b = _create_deposit(40)
	_deposit_c = _create_deposit(40)


func after_each() -> void:
	_deposit_a.queue_free()
	_deposit_a = null
	_deposit_b.queue_free()
	_deposit_b = null
	_deposit_c.queue_free()
	_deposit_c = null
	_compass.queue_free()
	_compass = null


# -- Test Registration ---------------------------------------------

func register_tests() -> void:
	# Constants
	add_test("marker_persist_time_is_60", _test_marker_persist_time_is_60)
	add_test("max_markers_is_30", _test_max_markers_is_30)
	add_test("distance_cone_is_45_degrees", _test_distance_cone_is_45_degrees)
	add_test("compass_width_is_600", _test_compass_width_is_600)

	# Marker management
	add_test("add_ping_markers_tracks_deposits", _test_add_ping_markers_tracks_deposits)
	add_test("add_ping_markers_deduplicates", _test_add_ping_markers_deduplicates)
	add_test("add_ping_markers_respects_max", _test_add_ping_markers_respects_max)
	add_test("remove_marker_removes_correct_deposit", _test_remove_marker_removes_correct_deposit)
	add_test("remove_marker_noop_for_unknown_deposit", _test_remove_marker_noop_for_unknown_deposit)
	add_test("clean_expired_removes_depleted_deposits", _test_clean_expired_removes_depleted_deposits)
	add_test("clean_expired_keeps_active_deposits", _test_clean_expired_keeps_active_deposits)

	# Bearing calculation
	add_test("bearing_center_maps_to_center_x", _test_bearing_center_maps_to_center_x)
	add_test("bearing_90_cw_maps_to_left_edge", _test_bearing_90_cw_maps_to_left_edge)
	add_test("bearing_90_ccw_maps_to_right_edge", _test_bearing_90_ccw_maps_to_right_edge)
	add_test("bearing_wraps_around_360", _test_bearing_wraps_around_360)


# -- Test Methods: Constants ---------------------------------------

func _test_marker_persist_time_is_60() -> void:
	assert_equal(CompassBar.MARKER_PERSIST_TIME, 60.0,
		"MARKER_PERSIST_TIME should be 60.0 seconds")


func _test_max_markers_is_30() -> void:
	assert_equal(CompassBar.MAX_MARKERS, 30,
		"MAX_MARKERS should be 30")


func _test_distance_cone_is_45_degrees() -> void:
	assert_equal(CompassBar.DISTANCE_CONE_DEG, 45.0,
		"DISTANCE_CONE_DEG should be 45.0 degrees")


func _test_compass_width_is_600() -> void:
	assert_equal(CompassBar.COMPASS_WIDTH, 600.0,
		"COMPASS_WIDTH should be 600.0")


# -- Test Methods: Marker Management -------------------------------

func _test_add_ping_markers_tracks_deposits() -> void:
	var deposits: Array[Deposit] = [_deposit_a, _deposit_b]
	_compass.add_ping_markers(deposits)
	assert_equal(_compass._ping_markers.size(), 2,
		"Should track 2 deposits after adding 2")


func _test_add_ping_markers_deduplicates() -> void:
	var deposits: Array[Deposit] = [_deposit_a]
	_compass.add_ping_markers(deposits)
	_compass.add_ping_markers(deposits)
	assert_equal(_compass._ping_markers.size(), 1,
		"Adding same deposit twice should not create duplicate marker")


func _test_add_ping_markers_respects_max() -> void:
	# Fill to MAX_MARKERS with unique deposits
	var extra_deposits: Array[Deposit] = []
	for i: int in range(CompassBar.MAX_MARKERS):
		var deposit: Deposit = _create_deposit(40)
		extra_deposits.append(deposit)
		var batch: Array[Deposit] = [deposit]
		_compass.add_ping_markers(batch)

	assert_equal(_compass._ping_markers.size(), CompassBar.MAX_MARKERS,
		"Should have exactly MAX_MARKERS markers")

	# Try to add one more beyond the limit
	var overflow: Array[Deposit] = [_deposit_a]
	_compass.add_ping_markers(overflow)
	assert_equal(_compass._ping_markers.size(), CompassBar.MAX_MARKERS,
		"Should not exceed MAX_MARKERS")

	# Cleanup extra deposits
	for deposit: Deposit in extra_deposits:
		deposit.queue_free()


func _test_remove_marker_removes_correct_deposit() -> void:
	var deposits: Array[Deposit] = [_deposit_a, _deposit_b]
	_compass.add_ping_markers(deposits)
	_compass.remove_marker(_deposit_a)
	assert_equal(_compass._ping_markers.size(), 1,
		"Should have 1 marker after removing one")
	var remaining: Deposit = _compass._ping_markers[0].get("deposit") as Deposit
	assert_equal(remaining, _deposit_b,
		"Remaining marker should be deposit_b")


func _test_remove_marker_noop_for_unknown_deposit() -> void:
	var deposits: Array[Deposit] = [_deposit_a]
	_compass.add_ping_markers(deposits)
	_compass.remove_marker(_deposit_b)
	assert_equal(_compass._ping_markers.size(), 1,
		"Removing unknown deposit should not affect existing markers")


func _test_clean_expired_removes_depleted_deposits() -> void:
	var deposits: Array[Deposit] = [_deposit_a, _deposit_b]
	_compass.add_ping_markers(deposits)
	# Deplete deposit_a
	_deposit_a.extract(40)
	assert_true(_deposit_a.is_depleted(), "deposit_a should be depleted")
	# Trigger cleanup
	_compass._clean_expired_markers()
	assert_equal(_compass._ping_markers.size(), 1,
		"Depleted deposit marker should be removed")
	var remaining: Deposit = _compass._ping_markers[0].get("deposit") as Deposit
	assert_equal(remaining, _deposit_b,
		"Active deposit marker should remain")


func _test_clean_expired_keeps_active_deposits() -> void:
	var deposits: Array[Deposit] = [_deposit_a, _deposit_b]
	_compass.add_ping_markers(deposits)
	_compass._clean_expired_markers()
	assert_equal(_compass._ping_markers.size(), 2,
		"Active deposits should not be cleaned up")


# -- Test Methods: Bearing Calculation -----------------------------

func _test_bearing_center_maps_to_center_x() -> void:
	# When bearing equals player yaw, screen_x should be center
	var screen_x: float = _compass._bearing_to_screen_x(90.0, 90.0)
	var expected_center: float = CompassBar.COMPASS_WIDTH / 2.0
	assert_equal(screen_x, expected_center,
		"Bearing matching yaw should map to center of compass")


func _test_bearing_90_cw_maps_to_left_edge() -> void:
	# 90 degrees clockwise of yaw should map to left edge (negated mapping)
	var screen_x: float = _compass._bearing_to_screen_x(180.0, 90.0)
	var expected_left: float = 0.0
	assert_equal(screen_x, expected_left,
		"Bearing 90 degrees CW should map to left edge")


func _test_bearing_90_ccw_maps_to_right_edge() -> void:
	# 90 degrees counter-clockwise of yaw should map to right edge (negated mapping)
	var screen_x: float = _compass._bearing_to_screen_x(0.0, 90.0)
	var expected_right: float = CompassBar.COMPASS_WIDTH
	assert_equal(screen_x, expected_right,
		"Bearing 90 degrees CCW should map to right edge")


func _test_bearing_wraps_around_360() -> void:
	# Player facing 350 degrees, bearing at 10 degrees = 20 degrees CW diff
	var screen_x: float = _compass._bearing_to_screen_x(10.0, 350.0)
	var expected: float = (CompassBar.COMPASS_WIDTH / 2.0) - (20.0 / 90.0) * (CompassBar.COMPASS_WIDTH / 2.0)
	assert_equal(screen_x, expected,
		"Bearing wrapping around 360 should calculate correct screen position")


# -- Helper Methods ------------------------------------------------

func _create_deposit(quantity: int) -> Deposit:
	var deposit: Deposit = Deposit.new()
	deposit.setup(
		ResourceDefs.ResourceType.SCRAP_METAL,
		ResourceDefs.Purity.THREE_STAR,
		ResourceDefs.DensityTier.MEDIUM,
		quantity,
	)
	add_child(deposit)
	return deposit
