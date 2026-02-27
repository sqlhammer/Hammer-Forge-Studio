## Unit tests for the player jump mechanic. Verifies jump height formula (50% of
## standing height), physics-correct velocity calculation, ground-only constraint,
## and signal emission for both first-person and third-person controller modes.
class_name TestPlayerJumpUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _player: Node = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	# Build minimal scene structure for PlayerFirstPerson
	_player = PlayerFirstPerson.new()
	var head: Node3D = Node3D.new()
	head.name = "Head"
	var camera: Camera3D = Camera3D.new()
	camera.name = "Camera3D"
	head.add_child(camera)
	_player.add_child(head)
	add_child(_player)

	_spy = SignalSpy.new()
	if _player.has_signal("player_jumped"):
		_spy.watch(_player, "player_jumped")


func after_each() -> void:
	_spy.clear()
	_spy = null
	if is_instance_valid(_player):
		_player.queue_free()
	_player = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Constants
	add_test("jump_height_ratio_is_0_5", _test_jump_height_ratio_is_0_5)
	add_test("gravity_constant_is_9_8", _test_gravity_constant_is_9_8)
	add_test("default_head_height_is_1_6", _test_default_head_height_is_1_6)
	# Jump height formula
	add_test("jump_height_is_50_percent_of_standing", _test_jump_height_is_50_percent_of_standing)
	# Jump velocity formula
	add_test("jump_velocity_matches_physics_formula", _test_jump_velocity_matches_physics_formula)
	add_test("jump_velocity_is_positive", _test_jump_velocity_is_positive)
	# Ground-only constraint
	add_test("jump_blocked_when_not_on_floor", _test_jump_blocked_when_not_on_floor)
	add_test("velocity_unchanged_when_jump_blocked", _test_velocity_unchanged_when_jump_blocked)
	add_test("no_signal_when_jump_blocked", _test_no_signal_when_jump_blocked)
	# Signal
	add_test("player_jumped_signal_exists", _test_player_jumped_signal_exists)
	# Third-person camera follow
	add_test("third_person_camera_follows_vertical_change", _test_third_person_camera_follows_vertical_change)


# ── Test Methods ──────────────────────────────────────────

# -- Constants --

func _test_jump_height_ratio_is_0_5() -> void:
	var script: Script = load("res://scripts/gameplay/player_first_person.gd")
	assert_equal(script.get("JUMP_HEIGHT_RATIO"), 0.5,
		"JUMP_HEIGHT_RATIO should be 0.5")


func _test_gravity_constant_is_9_8() -> void:
	var script: Script = load("res://scripts/gameplay/player_first_person.gd")
	assert_equal(script.get("GRAVITY"), 9.8,
		"GRAVITY should be 9.8")


func _test_default_head_height_is_1_6() -> void:
	assert_equal(_player.head_height, 1.6,
		"Default head_height should be 1.6")


# -- Jump height formula --

func _test_jump_height_is_50_percent_of_standing() -> void:
	var expected: float = _player.head_height * 0.5
	assert_equal(_player.get_jump_height(), expected,
		"Jump height should be 50% of head_height")


# -- Jump velocity formula --

func _test_jump_velocity_matches_physics_formula() -> void:
	var jump_height: float = _player.get_jump_height()
	var expected: float = sqrt(2.0 * 9.8 * jump_height)
	assert_in_range(_player.get_jump_velocity(), expected - 0.01, expected + 0.01,
		"Jump velocity should match sqrt(2 * g * h)")


func _test_jump_velocity_is_positive() -> void:
	assert_true(_player.get_jump_velocity() > 0.0,
		"Jump velocity should be positive (upward)")


# -- Ground-only constraint --

func _test_jump_blocked_when_not_on_floor() -> void:
	# CharacterBody3D not touching physics floor — is_on_floor() returns false
	var result: bool = _player.try_jump()
	assert_false(result, "Jump should fail when not on floor")


func _test_velocity_unchanged_when_jump_blocked() -> void:
	_player._velocity.y = 0.0
	_player.try_jump()
	assert_equal(_player._velocity.y, 0.0,
		"Vertical velocity should not change when jump is blocked")


func _test_no_signal_when_jump_blocked() -> void:
	_player.try_jump()
	assert_false(_spy.was_emitted("player_jumped"),
		"player_jumped should not emit when jump fails")


# -- Signal --

func _test_player_jumped_signal_exists() -> void:
	assert_true(_player.has_signal("player_jumped"),
		"PlayerFirstPerson should have player_jumped signal")


# -- Third-person camera follow --

func _test_third_person_camera_follows_vertical_change() -> void:
	# PlayerThirdPerson is an orbital camera that follows orbit_center
	# When the player jumps, orbit_center changes vertically and camera follows
	var camera_system: Node = PlayerThirdPerson.new()
	var camera: Camera3D = Camera3D.new()
	camera.name = "Camera3D"
	camera_system.add_child(camera)
	add_child(camera_system)

	# Set orbit center to ground level
	camera_system.set_orbit_center(Vector3(0, 0, 0))
	camera_system._update_camera_position()
	var pos_ground: float = camera.global_position.y

	# Simulate player jumping — orbit center moves up
	camera_system.set_orbit_center(Vector3(0, 0.8, 0))
	camera_system._update_camera_position()
	var pos_jumped: float = camera.global_position.y

	assert_true(pos_jumped > pos_ground,
		"Third-person camera should follow vertical position changes during jump")

	camera_system.queue_free()
