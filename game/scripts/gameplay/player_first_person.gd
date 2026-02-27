## First-person player controller for surface exploration.
## Handles character movement, camera control, jump, and integration with InputManager.
## Owner: gameplay-programmer
class_name PlayerFirstPerson
extends CharacterBody3D

# ── Signals ──────────────────────────────────────────────
signal player_jumped

# ── Constants ─────────────────────────────────────────────
const GRAVITY: float = 9.8
const JUMP_HEIGHT_RATIO: float = 0.5

# ── Exported Variables ────────────────────────────────────
@export var movement_speed: float = 5.0
@export var movement_speed_backward: float = 3.5  # Walking backward is slower
@export var camera_sensitivity: float = 0.003
@export var camera_pitch_limit: float = 1.483  # ~85 degrees
@export var head_height: float = 1.6
@export var use_head_bob: bool = false
@export var head_bob_amount: float = 0.05
@export var head_bob_speed: float = 4.0
@export var invert_gamepad_look_y: bool = false

# ── Private Variables ─────────────────────────────────────
var _velocity: Vector3 = Vector3.ZERO
var _camera_pitch: float = 0.0
var _head_bob_offset: float = 0.0
var _head_bob_timer: float = 0.0
var _is_moving: bool = false

# ── Onready Variables ─────────────────────────────────────
@onready var _camera: Camera3D = $Head/Camera3D

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	# Set camera height to eye level
	$Head.position.y = head_height

func _process(delta: float) -> void:
	_update_movement(delta)
	_update_camera(delta)
	_apply_gravity(delta)
	_update_jump()
	_apply_movement()

func _input(event: InputEvent) -> void:
	# Only handle mouse look when cursor is captured (not while a UI panel is open)
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			return
		if InputManager.get_current_input_device() == "keyboard":
			var mouse_delta: Vector2 = event.relative
			_apply_mouse_look(mouse_delta)

# ── Public Methods ────────────────────────────────────────
## Returns the player's active camera.
func get_camera() -> Camera3D:
	return _camera

## Returns the current velocity of the player.
func get_current_velocity() -> Vector3:
	return _velocity

## Returns true if the player is currently moving.
func is_moving() -> bool:
	return _is_moving

## Returns the calculated jump height (50% of standing height).
func get_jump_height() -> float:
	return head_height * JUMP_HEIGHT_RATIO

## Returns the physics-correct jump impulse velocity for the configured jump height.
func get_jump_velocity() -> float:
	var jump_height: float = get_jump_height()
	var impulse: float = sqrt(2.0 * GRAVITY * jump_height)
	return impulse

## Attempts to perform a jump. Returns true if the jump was executed.
## Only succeeds when the player is on the ground.
func try_jump() -> bool:
	if not is_on_floor():
		return false
	_velocity.y = get_jump_velocity()
	player_jumped.emit()
	var log_message: String = "PlayerFirstPerson: jumped — velocity=%.2f" % get_jump_velocity()
	Global.log(log_message)
	return true

# ── Private Methods ───────────────────────────────────────
## Checks for jump input and applies jump impulse if grounded.
func _update_jump() -> void:
	if InputManager.is_action_just_pressed("jump"):
		try_jump()

## Updates player movement based on input.
func _update_movement(delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO

	# Get analog input from InputManager (works for both keyboard and gamepad)
	if InputManager.get_current_input_device() == "gamepad":
		input_vector = InputManager.get_analog_input("left")
	else:
		# Keyboard input via actions
		input_vector.x = InputManager.get_action_strength("move_right") - InputManager.get_action_strength("move_left")
		input_vector.y = InputManager.get_action_strength("move_forward") - InputManager.get_action_strength("move_backward")

	# Normalize input to prevent faster diagonal movement
	input_vector = input_vector.normalized()

	# Calculate movement direction relative to camera facing
	var forward: Vector3 = -_camera.global_transform.basis.z
	var right: Vector3 = _camera.global_transform.basis.x

	# Determine speed (backward is slower)
	var speed: float = movement_speed
	if input_vector.y < 0:  # Moving backward
		speed = movement_speed_backward

	# Apply battery movement penalty
	speed *= SuitBattery.get_movement_multiplier()

	# Calculate movement velocity (horizontal only)
	var move_direction: Vector3 = (forward * input_vector.y + right * input_vector.x) * speed
	_velocity.x = move_direction.x
	_velocity.z = move_direction.z

	_is_moving = input_vector.length() > 0.1

	# Update head bob timer
	if _is_moving and use_head_bob:
		_head_bob_timer += delta * head_bob_speed
		_head_bob_offset = sin(_head_bob_timer) * head_bob_amount
	else:
		_head_bob_offset = lerp(_head_bob_offset, 0.0, delta * 5.0)

## Updates camera rotation based on input.
func _update_camera(delta: float) -> void:
	var look_input: Vector2 = Vector2.ZERO

	if InputManager.get_current_input_device() == "gamepad":
		look_input = InputManager.get_analog_input("right")
		if invert_gamepad_look_y:
			look_input.y = -look_input.y
	else:
		# Mouse look is handled in _input()
		look_input = Vector2.ZERO

	# Apply gamepad look
	if look_input.length() > 0.01:
		var yaw_delta: float = look_input.x * camera_sensitivity * 60.0  # Framerate-independent
		var pitch_delta: float = look_input.y * camera_sensitivity * 60.0

		# Rotate camera yaw (left/right)
		global_transform.basis = global_transform.basis.rotated(Vector3.UP, -yaw_delta * delta)

		# Rotate camera pitch (up/down) with clamping
		_camera_pitch = clamp(_camera_pitch - pitch_delta * delta, -camera_pitch_limit, camera_pitch_limit)
		_camera.rotation.x = _camera_pitch

	# Apply head bob to camera position
	_camera.position.y = _head_bob_offset

## Applies mouse look rotation.
func _apply_mouse_look(mouse_delta: Vector2) -> void:
	# Rotate character yaw (left/right)
	var yaw_rotation: float = -mouse_delta.x * camera_sensitivity
	global_transform.basis = global_transform.basis.rotated(Vector3.UP, yaw_rotation)

	# Rotate camera pitch (up/down) with clamping
	_camera_pitch = clamp(_camera_pitch - mouse_delta.y * camera_sensitivity, -camera_pitch_limit, camera_pitch_limit)
	_camera.rotation.x = _camera_pitch

## Applies gravity to vertical velocity.
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		_velocity.y -= GRAVITY * delta
	else:
		_velocity.y = 0.0  # Reset vertical velocity when on ground

## Applies velocity and handles collision.
func _apply_movement() -> void:
	velocity = _velocity
	move_and_slide()
