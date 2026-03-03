## Centralized input management system that normalizes keyboard and gamepad input.
## Provides a unified interface for querying input state across all gameplay contexts.
extends Node

# ── Constants ─────────────────────────────────────────────
const GAMEPAD_DEAD_ZONE_MOVEMENT: float = 0.15
const GAMEPAD_DEAD_ZONE_CAMERA: float = 0.10
const GAMEPAD_DEAD_ZONE_TRIGGER: float = 0.05
const INPUT_DEVICE_SWITCH_DEBOUNCE: float = 0.1

# ── Signals ───────────────────────────────────────────────
signal input_device_changed(device: String)  # "keyboard" or "gamepad"

# ── Exported Variables ────────────────────────────────────
@export var mouse_sensitivity_x: float = 1.0
@export var mouse_sensitivity_y: float = 1.0
@export var gamepad_sensitivity_x: float = 15.0
@export var gamepad_sensitivity_y: float = 7.0
@export var invert_gamepad_look_y: bool = false

# ── Constants (gameplay actions suppressed when UI is open) ─
const GAMEPLAY_ACTIONS: Array[String] = [
	"move_forward", "move_backward", "move_left", "move_right",
	"interact", "scan", "use_tool", "switch_view", "jump",
	"inventory_toggle", "use_item", "toggle_head_lamp",
	"ship_forward", "ship_backward", "ship_left", "ship_right",
	"ship_accelerate", "ship_emergency_stop",
]

# ── Private Variables ─────────────────────────────────────
var _current_input_device: String = "keyboard"  # "keyboard" or "gamepad"
var _device_switch_timer: float = 0.0
var _gamepad_index: int = 0
var _last_keyboard_activity: float = 0.0
var _last_gamepad_activity: float = 0.0
var _gameplay_inputs_enabled: bool = true

# ── Onready Variables ─────────────────────────────────────
# (None)

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	set_process_input(true)
	_setup_input_actions()

func _input(event: InputEvent) -> void:
	# Track which input device is being used
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		_last_keyboard_activity = Time.get_ticks_msec() / 1000.0
		if _current_input_device != "keyboard":
			_switch_input_device("keyboard")
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_last_gamepad_activity = Time.get_ticks_msec() / 1000.0
		if _current_input_device != "gamepad":
			_switch_input_device("gamepad")

func _process(delta: float) -> void:
	_device_switch_timer += delta

# ── Public Methods ────────────────────────────────────────
## Enables or disables gameplay input processing.
## When disabled, gameplay actions return false/zero; UI actions (ui_*) still work.
func set_gameplay_inputs_enabled(enabled: bool) -> void:
	_gameplay_inputs_enabled = enabled

## Returns true if gameplay inputs are currently enabled.
func is_gameplay_inputs_enabled() -> bool:
	return _gameplay_inputs_enabled

## Returns true if the specified action is currently pressed.
func is_action_pressed(action: String) -> bool:
	if not _gameplay_inputs_enabled and action in GAMEPLAY_ACTIONS:
		return false
	return Input.is_action_pressed(action)

## Returns true if the specified action was just pressed this frame.
func is_action_just_pressed(action: String) -> bool:
	if not _gameplay_inputs_enabled and action in GAMEPLAY_ACTIONS:
		return false
	return Input.is_action_just_pressed(action)

## Returns the analog strength (0.0 - 1.0) of the specified action.
func get_action_strength(action: String) -> float:
	if not _gameplay_inputs_enabled and action in GAMEPLAY_ACTIONS:
		return 0.0
	return Input.get_action_strength(action)

## Returns analog input from left or right stick with dead zone applied.
## stick: "left" or "right"
## Returns a Vector2 with x/y in range [-1.0, 1.0]
func get_analog_input(stick: String) -> Vector2:
	if not _gameplay_inputs_enabled:
		return Vector2.ZERO
	var raw_input: Vector2 = Vector2.ZERO

	match stick:
		"left":
			raw_input.x = Input.get_joy_axis(_gamepad_index, JOY_AXIS_LEFT_X)
			raw_input.y = Input.get_joy_axis(_gamepad_index, JOY_AXIS_LEFT_Y)
			return _apply_dead_zone(raw_input, GAMEPAD_DEAD_ZONE_MOVEMENT)
		"right":
			raw_input.x = Input.get_joy_axis(_gamepad_index, JOY_AXIS_RIGHT_X)
			raw_input.y = Input.get_joy_axis(_gamepad_index, JOY_AXIS_RIGHT_Y)
			return _apply_dead_zone(raw_input, GAMEPAD_DEAD_ZONE_CAMERA)
		_:
			push_warning("InputManager: Invalid stick name '%s'" % stick)
			return Vector2.ZERO

## Returns analog input from left or right trigger with dead zone applied.
## trigger: "left" or "right"
## Returns a value in range [0.0, 1.0]
func get_trigger_input(trigger: String) -> float:
	var raw_input: float = 0.0
	
	match trigger:
		"left":
			raw_input = Input.get_joy_axis(_gamepad_index, JOY_AXIS_TRIGGER_LEFT)
		"right":
			raw_input = Input.get_joy_axis(_gamepad_index, JOY_AXIS_TRIGGER_RIGHT)
		_:
			push_warning("InputManager: Invalid trigger name '%s'" % trigger)
			return 0.0
	
	# Normalize trigger input from [-1, 1] to [0, 1] and apply dead zone
	raw_input = (raw_input + 1.0) / 2.0
	if abs(raw_input) < GAMEPAD_DEAD_ZONE_TRIGGER:
		return 0.0
	return clamp(raw_input, 0.0, 1.0)

## Returns the current active input device: "keyboard" or "gamepad"
func get_current_input_device() -> String:
	return _current_input_device

## Returns mouse movement delta in pixels (only valid during first-person).
func get_mouse_delta() -> Vector2:
	return Input.get_last_mouse_velocity()

## Returns true if any gamepad is connected.
func is_gamepad_connected() -> bool:
	return Input.get_connected_joypads().size() > 0

# ── Private Methods ───────────────────────────────────────
## Sets up all input actions in the project.
func _setup_input_actions() -> void:
	# First-Person Context Actions
	_add_action_if_missing("move_forward", [KEY_W, KEY_UP])
	_add_action_if_missing("move_backward", [KEY_S, KEY_DOWN])
	_add_action_if_missing("move_left", [KEY_A, KEY_LEFT])
	_add_action_if_missing("move_right", [KEY_D, KEY_RIGHT])
	_add_action_if_missing("camera_look_horizontal", [])  # Mouse only
	_add_action_if_missing("camera_look_vertical", [])  # Mouse only
	_add_action_if_missing("interact", [KEY_E], [], [JOY_BUTTON_X])
	_add_action_if_missing("scan", [KEY_Q])
	_add_action_if_missing("use_tool", [], [MOUSE_BUTTON_LEFT])
	_add_action_if_missing("switch_view", [KEY_TAB])
	_add_action_if_missing("pause", [KEY_ESCAPE])
	_add_action_if_missing("jump", [KEY_SPACE])
	_add_action_if_missing("inventory_toggle", [KEY_I], [], [JOY_BUTTON_BACK])
	_add_action_if_missing("use_item", [KEY_G])
	_add_action_if_missing("toggle_head_lamp", [KEY_F])

	# UI Context Actions
	_add_action_if_missing("ui_action_menu", [], [], [JOY_BUTTON_Y])

	# Ensure Godot built-in UI actions include gamepad buttons (Godot 4 defaults
	# only map keyboard keys — Enter/Space for ui_accept, Escape for ui_cancel)
	_add_joy_button_to_existing_action("ui_accept", JOY_BUTTON_A)
	_add_joy_button_to_existing_action("ui_cancel", JOY_BUTTON_B)

	# Third-Person Context Actions
	_add_action_if_missing("ship_forward", [KEY_W, KEY_UP])
	_add_action_if_missing("ship_backward", [KEY_S, KEY_DOWN])
	_add_action_if_missing("ship_left", [KEY_A, KEY_LEFT])
	_add_action_if_missing("ship_right", [KEY_D, KEY_RIGHT])
	_add_action_if_missing("ship_accelerate", [KEY_SPACE])
	_add_action_if_missing("ship_emergency_stop", [KEY_X])

## Adds an input action if it doesn't already exist.
func _add_action_if_missing(action_name: String, keys: Array = [], mouse_buttons: Array = [], joy_buttons: Array = []) -> void:
	if InputMap.has_action(action_name):
		return

	InputMap.add_action(action_name)
	for key in keys:
		var event := InputEventKey.new()
		event.keycode = key
		InputMap.action_add_event(action_name, event)
	for button in mouse_buttons:
		var event := InputEventMouseButton.new()
		event.button_index = button
		InputMap.action_add_event(action_name, event)
	for joy_button in joy_buttons:
		var event := InputEventJoypadButton.new()
		event.button_index = joy_button
		InputMap.action_add_event(action_name, event)

## Adds a joypad button to an existing input action if not already mapped.
## Unlike _add_action_if_missing, this works on actions that already exist (e.g., Godot built-ins).
func _add_joy_button_to_existing_action(action_name: String, joy_button: int) -> void:
	if not InputMap.has_action(action_name):
		return
	for existing_event: InputEvent in InputMap.action_get_events(action_name):
		if existing_event is InputEventJoypadButton:
			var existing_joy: InputEventJoypadButton = existing_event as InputEventJoypadButton
			if existing_joy.button_index == joy_button:
				return
	var event := InputEventJoypadButton.new()
	event.button_index = joy_button
	InputMap.action_add_event(action_name, event)

## Applies dead zone to a 2D axis input (typically from analog stick).
func _apply_dead_zone(input: Vector2, dead_zone: float) -> Vector2:
	var magnitude: float = input.length()
	if magnitude < dead_zone:
		return Vector2.ZERO
	
	# Scale the input so it maps from [dead_zone, 1.0] to [0.0, 1.0]
	var normalized: Vector2 = input.normalized() * ((magnitude - dead_zone) / (1.0 - dead_zone))
	return normalized.clamp(Vector2(-1, -1), Vector2(1, 1))

## Switches the active input device and emits a signal.
func _switch_input_device(device: String) -> void:
	if _device_switch_timer < INPUT_DEVICE_SWITCH_DEBOUNCE:
		return
	
	if device == _current_input_device:
		return
	
	_current_input_device = device
	_device_switch_timer = 0.0
	input_device_changed.emit(device)
