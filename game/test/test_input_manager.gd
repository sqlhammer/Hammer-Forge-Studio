## Test scene script for InputManager autoload.
## Displays real-time input state including movement, camera, and action keys.
class_name TestInputManager
extends Control

# ── Onready Variables ─────────────────────────────────────
@onready var _title_label: Label = $TitleLabel
@onready var _device_label: Label = $MainContainer/DeviceLabel
@onready var _movement_label: Label = $MainContainer/MovementLabel
@onready var _camera_label: Label = $MainContainer/CameraLabel
@onready var _action_label: Label = $MainContainer/ActionLabel

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	_title_label.text = "InputManager Test Scene"
	_setup_ui()
	InputManager.input_device_changed.connect(_on_input_device_changed)
	Global.debug_log("TestInputManager scene loaded")

func _process(_delta: float) -> void:
	_update_display()

# ── Private Methods ───────────────────────────────────────
## Initializes UI element properties.
func _setup_ui() -> void:
	_title_label.add_theme_font_size_override("font_size", 24)
	for label in [_device_label, _movement_label, _camera_label, _action_label]:
		label.add_theme_font_size_override("font_size", 14)
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

## Updates display labels with current input state.
func _update_display() -> void:
	# Device status
	var device: String = InputManager.get_current_input_device()
	var gamepad_connected: String = "Yes" if InputManager.is_gamepad_connected() else "No"
	_device_label.text = "Device: %s | Gamepad Connected: %s" % [device.to_upper(), gamepad_connected]
	
	# Movement input
	var move_forward: float = InputManager.get_action_strength("move_forward")
	var move_backward: float = InputManager.get_action_strength("move_backward")
	var move_left: float = InputManager.get_action_strength("move_left")
	var move_right: float = InputManager.get_action_strength("move_right")
	_movement_label.text = "Movement: F=%.2f B=%.2f L=%.2f R=%.2f" % [move_forward, move_backward, move_left, move_right]
	
	# Camera / analog input
	var left_stick: Vector2 = InputManager.get_analog_input("left")
	var right_stick: Vector2 = InputManager.get_analog_input("right")
	_camera_label.text = "Sticks: Left(%.2f, %.2f) Right(%.2f, %.2f)" % [left_stick.x, left_stick.y, right_stick.x, right_stick.y]
	
	# Action buttons
	var interact: String = "E" if InputManager.is_action_pressed("interact") else "-"
	var scan: String = "Q" if InputManager.is_action_pressed("scan") else "-"
	var switch_view: String = "Tab" if InputManager.is_action_pressed("switch_view") else "-"
	_action_label.text = "Actions: Interact=%s Scan=%s SwitchView=%s" % [interact, scan, switch_view]

## Called when InputManager detects device change.
func _on_input_device_changed(device: String) -> void:
	Global.debug_log("Test scene detected device change: %s" % device)
