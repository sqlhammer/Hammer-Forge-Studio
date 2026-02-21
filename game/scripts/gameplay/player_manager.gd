## Master player controller that manages view mode switching between first-person and third-person.
## Handles enabling/disabling controllers and smooth camera transitions.
class_name PlayerManager
extends Node3D

# ── Signals ───────────────────────────────────────────────
signal view_mode_changed(mode: String)  # "first_person" or "third_person"

# ── Constants ─────────────────────────────────────────────
const VIEW_SWITCH_COOLDOWN: float = 0.3
const CAMERA_TRANSITION_SPEED: float = 0.5

# ── Exported Variables ────────────────────────────────────
@export var starting_view_mode: String = "first_person"  # "first_person" or "third_person"

# ── Private Variables ─────────────────────────────────────
var _current_view_mode: String = "first_person"
var _view_switch_timer: float = 0.0
var _camera_transition_progress: float = 0.0
var _is_transitioning: bool = false

# ── Onready Variables ─────────────────────────────────────
@onready var _first_person: PlayerFirstPerson = $FirstPersonController
@onready var _third_person: PlayerThirdPerson = $ThirdPersonController

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	if not _first_person or not _third_person:
		push_error("PlayerManager: Missing first-person or third-person controller!")
		return

	# Initialize with starting view mode
	_set_view_mode(starting_view_mode)
	_view_switch_timer = VIEW_SWITCH_COOLDOWN  # Allow immediate switch

func _process(delta: float) -> void:
	_update_view_switch_input(delta)
	_update_camera_transition(delta)

# ── Public Methods ────────────────────────────────────────
## Returns the current view mode.
func get_view_mode() -> String:
	return _current_view_mode

## Switches to the other view mode.
func toggle_view_mode() -> void:
	if _view_switch_timer < VIEW_SWITCH_COOLDOWN:
		return

	var new_mode: String = "third_person" if _current_view_mode == "first_person" else "first_person"
	_switch_to_view_mode(new_mode)

# ── Private Methods ───────────────────────────────────────
## Updates input detection for view switching.
func _update_view_switch_input(delta: float) -> void:
	_view_switch_timer += delta

	# Check for view switch input
	if InputManager.is_action_pressed("switch_view"):
		toggle_view_mode()

## Updates camera transition animation.
func _update_camera_transition(delta: float) -> void:
	if not _is_transitioning:
		return

	_camera_transition_progress += delta / CAMERA_TRANSITION_SPEED

	if _camera_transition_progress >= 1.0:
		_camera_transition_progress = 1.0
		_is_transitioning = false
		# Hide the view we're switching away from
		if _current_view_mode == "first_person":
			_first_person.visible = false
			_third_person.visible = true
		else:
			_third_person.visible = false
			_first_person.visible = true

## Sets the current view mode and enables/disables controllers.
func _set_view_mode(mode: String) -> void:
	_current_view_mode = mode

	if mode == "first_person":
		_first_person.visible = true
		_first_person.set_process(true)
		_first_person.set_process_input(true)
		_third_person.visible = false
		_third_person.set_process(false)
		_third_person.set_process_input(false)
	else:  # third_person
		_third_person.visible = true
		_third_person.set_process(true)
		_third_person.set_process_input(true)
		_first_person.visible = false
		_first_person.set_process(false)
		_first_person.set_process_input(false)

		# Set third-person orbit center to first-person position
		_third_person.set_orbit_center(_first_person.global_position)

## Switches to a new view mode with transition.
func _switch_to_view_mode(new_mode: String) -> void:
	if new_mode == _current_view_mode:
		return

	_view_switch_timer = 0.0
	_camera_transition_progress = 0.0
	_is_transitioning = true

	# Start showing the new view mode
	if new_mode == "first_person":
		_first_person.visible = true
		_third_person.visible = true
	else:  # third_person
		_third_person.visible = true
		_first_person.visible = true

	# Update the actual mode and enable/disable processing
	_set_view_mode(new_mode)

	view_mode_changed.emit(new_mode)
