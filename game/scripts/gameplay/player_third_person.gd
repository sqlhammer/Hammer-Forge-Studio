## Third-person orbital camera system for ship navigation and viewing.
## Handles camera orbiting around a target with smooth damping and input control.
class_name PlayerThirdPerson
extends Node3D

# ── Constants ─────────────────────────────────────────────
const CAMERA_DAMPING: float = 0.15  # 0.15 = fast but smooth
const MIN_ORBIT_DISTANCE: float = 5.0
const MAX_ORBIT_DISTANCE: float = 50.0
const DEFAULT_ORBIT_DISTANCE: float = 15.0
const DEFAULT_ORBIT_YAW: float = PI / 4  # 45 degrees
const DEFAULT_ORBIT_PITCH: float = PI / 6  # 30 degrees
const PITCH_LIMIT: float = 1.396  # ~80 degrees

# ── Exported Variables ────────────────────────────────────
@export var camera_sensitivity_x: float = 1.0
@export var camera_sensitivity_y: float = 1.0
@export var zoom_speed: float = 5.0
@export var enable_zoom: bool = true

# ── Private Variables ─────────────────────────────────────
var _orbit_yaw: float = DEFAULT_ORBIT_YAW
var _orbit_pitch: float = DEFAULT_ORBIT_PITCH
var _orbit_distance: float = DEFAULT_ORBIT_DISTANCE
var _target_yaw: float = DEFAULT_ORBIT_YAW
var _target_pitch: float = DEFAULT_ORBIT_PITCH
var _target_distance: float = DEFAULT_ORBIT_DISTANCE
var _orbit_center: Vector3 = Vector3.ZERO

# ── Onready Variables ─────────────────────────────────────
@onready var _camera: Camera3D = $Camera3D

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	if not _camera:
		push_error("PlayerThirdPerson: Camera3D node not found!")
		return

	# Initialize camera position
	_update_camera_position()

func _process(delta: float) -> void:
	_update_orbit_input(delta)
	_apply_orbit_damping()
	_update_camera_position()

func _input(event: InputEvent) -> void:
	# Handle zoom input
	if event is InputEventMouseButton and enable_zoom:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_distance = max(MIN_ORBIT_DISTANCE, _target_distance - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_distance = min(MAX_ORBIT_DISTANCE, _target_distance + zoom_speed)

# ── Public Methods ────────────────────────────────────────
## Sets the orbit target position (what the camera orbits around).
func set_orbit_center(center_position: Vector3) -> void:
	_orbit_center = center_position

## Returns the current orbit center.
func get_orbit_center() -> Vector3:
	return _orbit_center

## Returns the current camera world position.
func get_camera_position() -> Vector3:
	return _camera.global_position

## Resets the camera to default orbit position.
func reset_orbit() -> void:
	_target_yaw = DEFAULT_ORBIT_YAW
	_target_pitch = DEFAULT_ORBIT_PITCH
	_target_distance = DEFAULT_ORBIT_DISTANCE

# ── Private Methods ───────────────────────────────────────
## Updates orbit angles based on input.
func _update_orbit_input(delta: float) -> void:
	var orbit_input: Vector2 = Vector2.ZERO

	# Get input from InputManager
	if InputManager.get_current_input_device() == "gamepad":
		orbit_input = InputManager.get_analog_input("left")
	else:
		# Keyboard: WASD/Arrow keys
		orbit_input.x = InputManager.get_action_strength("ship_right") - InputManager.get_action_strength("ship_left")
		orbit_input.y = InputManager.get_action_strength("ship_forward") - InputManager.get_action_strength("ship_backward")

	# Apply input to target angles
	if orbit_input.length() > 0.01:
		_target_yaw += orbit_input.x * camera_sensitivity_x * delta * 2.0
		_target_pitch = clamp(_target_pitch - orbit_input.y * camera_sensitivity_y * delta * 2.0, -PITCH_LIMIT, PITCH_LIMIT)

## Applies smoothing damping to camera position.
func _apply_orbit_damping() -> void:
	# Smooth interpolation toward target values
	_orbit_yaw = lerp(_orbit_yaw, _target_yaw, CAMERA_DAMPING)
	_orbit_pitch = lerp(_orbit_pitch, _target_pitch, CAMERA_DAMPING)
	_orbit_distance = lerp(_orbit_distance, _target_distance, CAMERA_DAMPING)

## Updates camera position based on spherical coordinates.
func _update_camera_position() -> void:
	# Calculate camera position in spherical coordinates
	# Position = center + distance * (sin(pitch)*cos(yaw), cos(pitch), sin(pitch)*sin(yaw))
	var x: float = sin(_orbit_pitch) * cos(_orbit_yaw) * _orbit_distance
	var y: float = cos(_orbit_pitch) * _orbit_distance
	var z: float = sin(_orbit_pitch) * sin(_orbit_yaw) * _orbit_distance

	var camera_position: Vector3 = _orbit_center + Vector3(x, y, z)
	_camera.global_position = camera_position

	# Look at the orbit center
	_camera.look_at(_orbit_center, Vector3.UP)
