## Unit tests for the InputManager autoload. Verifies input action registration,
## device detection state, and dead zone configuration values.
class_name TestInputManagerUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_spy = SignalSpy.new()
	_spy.watch(InputManager, "input_device_changed")


func after_each() -> void:
	_spy.clear()
	_spy = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	add_test("first_person_actions_are_registered", _test_first_person_actions_are_registered)
	add_test("third_person_actions_are_registered", _test_third_person_actions_are_registered)
	add_test("shared_actions_are_registered", _test_shared_actions_are_registered)
	add_test("default_device_is_keyboard", _test_default_device_is_keyboard)
	add_test("gamepad_not_connected_in_test_environment", _test_gamepad_not_connected_in_test_environment)
	add_test("invalid_stick_returns_zero_vector", _test_invalid_stick_returns_zero_vector)
	add_test("invalid_trigger_returns_zero", _test_invalid_trigger_returns_zero)
	add_test("movement_dead_zone_in_valid_range", _test_movement_dead_zone_in_valid_range)
	add_test("camera_dead_zone_in_valid_range", _test_camera_dead_zone_in_valid_range)
	add_test("trigger_dead_zone_in_valid_range", _test_trigger_dead_zone_in_valid_range)
	add_test("mouse_sensitivity_defaults_are_positive", _test_mouse_sensitivity_defaults_are_positive)


# ── Test Methods ──────────────────────────────────────────

func _test_first_person_actions_are_registered() -> void:
	assert_true(InputMap.has_action("move_forward"), "move_forward action should exist")
	assert_true(InputMap.has_action("move_backward"), "move_backward action should exist")
	assert_true(InputMap.has_action("move_left"), "move_left action should exist")
	assert_true(InputMap.has_action("move_right"), "move_right action should exist")
	assert_true(InputMap.has_action("jump"), "jump action should exist")
	assert_true(InputMap.has_action("interact"), "interact action should exist")
	assert_true(InputMap.has_action("scan"), "scan action should exist")
	assert_true(InputMap.has_action("use_tool"), "use_tool action should exist")
	assert_true(InputMap.has_action("inventory_toggle"), "inventory_toggle action should exist")


func _test_third_person_actions_are_registered() -> void:
	assert_true(InputMap.has_action("ship_forward"), "ship_forward action should exist")
	assert_true(InputMap.has_action("ship_backward"), "ship_backward action should exist")
	assert_true(InputMap.has_action("ship_left"), "ship_left action should exist")
	assert_true(InputMap.has_action("ship_right"), "ship_right action should exist")
	assert_true(InputMap.has_action("ship_accelerate"), "ship_accelerate action should exist")
	assert_true(InputMap.has_action("ship_emergency_stop"), "ship_emergency_stop action should exist")


func _test_shared_actions_are_registered() -> void:
	assert_true(InputMap.has_action("switch_view"), "switch_view action should exist")
	assert_true(InputMap.has_action("pause"), "pause action should exist")


func _test_default_device_is_keyboard() -> void:
	var device: String = InputManager.get_current_input_device()
	assert_equal(device, "keyboard", "Default input device should be keyboard")


func _test_gamepad_not_connected_in_test_environment() -> void:
	var connected: bool = InputManager.is_gamepad_connected()
	# In a standard test environment no gamepad is expected
	assert_false(connected, "No gamepad should be detected in test environment")


func _test_invalid_stick_returns_zero_vector() -> void:
	var result: Vector2 = InputManager.get_analog_input("invalid")
	assert_equal(result, Vector2.ZERO, "Invalid stick name should return Vector2.ZERO")


func _test_invalid_trigger_returns_zero() -> void:
	var result: float = InputManager.get_trigger_input("invalid")
	assert_equal(result, 0.0, "Invalid trigger name should return 0.0")


func _test_movement_dead_zone_in_valid_range() -> void:
	assert_in_range(InputManager.GAMEPAD_DEAD_ZONE_MOVEMENT, 0.01, 0.5,
		"Movement dead zone should be between 0.01 and 0.5")


func _test_camera_dead_zone_in_valid_range() -> void:
	assert_in_range(InputManager.GAMEPAD_DEAD_ZONE_CAMERA, 0.01, 0.5,
		"Camera dead zone should be between 0.01 and 0.5")


func _test_trigger_dead_zone_in_valid_range() -> void:
	assert_in_range(InputManager.GAMEPAD_DEAD_ZONE_TRIGGER, 0.01, 0.5,
		"Trigger dead zone should be between 0.01 and 0.5")


func _test_mouse_sensitivity_defaults_are_positive() -> void:
	assert_true(InputManager.mouse_sensitivity_x > 0.0,
		"Mouse sensitivity X should be positive")
	assert_true(InputManager.mouse_sensitivity_y > 0.0,
		"Mouse sensitivity Y should be positive")
