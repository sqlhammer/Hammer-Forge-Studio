## Scanner system: handles ping detection and deposit analysis via camera raycast.
class_name Scanner
extends Node

# ── Signals ──────────────────────────────────────────────
signal ping_completed(deposits: Array[Deposit])
signal analysis_started(deposit: Deposit)
signal analysis_progress_changed(progress: float)
signal analysis_completed(deposit: Deposit)
signal analysis_cancelled

# ── Constants ─────────────────────────────────────────────
const PING_RANGE: float = 80.0
const PING_COOLDOWN: float = 1.0
const ANALYSIS_DURATION: float = 2.5
const ANALYSIS_MAX_RANGE: float = 5.0
const FACING_DISTANCE_CONE_DEG: float = 45.0

## Physics layers for interaction raycast
const LAYER_ENVIRONMENT: int = 1 << 2  # Layer 3
const LAYER_INTERACTABLE: int = 1 << 3  # Layer 4
const INTERACTION_RAY_LENGTH: float = 6.0

# ── Private Variables ─────────────────────────────────────
var _camera: Camera3D = null
var _player: CharacterBody3D = null
var _ping_cooldown_timer: float = 0.0
var _analysis_target: Deposit = null
var _analysis_progress: float = 0.0
var _is_analyzing: bool = false

# ── Public Methods ────────────────────────────────────────

## Initializes the scanner with the player camera reference.
func setup(camera: Camera3D, player: CharacterBody3D) -> void:
	_camera = camera
	_player = player

## Returns the aimed deposit within interaction range, or null.
func get_aimed_deposit() -> Deposit:
	if not _camera:
		return null
	var result: Dictionary = _cast_interaction_ray()
	if result.is_empty():
		return null
	var collider: Object = result.get("collider")
	if not collider:
		return null
	# The collider is the StaticBody3D child of the Deposit node
	var parent: Node = collider.get_parent()
	if parent is Deposit:
		return parent as Deposit
	return null

## Returns the current analysis progress (0.0 to 1.0).
func get_analysis_progress() -> float:
	return _analysis_progress

## Returns true if currently analyzing.
func is_analyzing() -> bool:
	return _is_analyzing

## Returns the current analysis target deposit.
func get_analysis_target() -> Deposit:
	return _analysis_target

# ── Built-in Virtual Methods ──────────────────────────────

func _process(delta: float) -> void:
	if not _camera:
		return
	_update_ping_cooldown(delta)
	_check_ping_input()
	_update_analysis(delta)

# ── Private Methods ───────────────────────────────────────

func _update_ping_cooldown(delta: float) -> void:
	_ping_cooldown_timer = maxf(_ping_cooldown_timer - delta, 0.0)

func _check_ping_input() -> void:
	if Input.is_action_just_pressed("scan") and _ping_cooldown_timer <= 0.0:
		_do_ping()

func _do_ping() -> void:
	_ping_cooldown_timer = PING_COOLDOWN
	var player_pos: Vector3 = _player.global_position
	var deposits: Array[Deposit] = DepositRegistry.get_in_range(player_pos, PING_RANGE)
	for deposit: Deposit in deposits:
		if not deposit.is_pinged():
			deposit.ping()
	ping_completed.emit(deposits)

func _update_analysis(delta: float) -> void:
	var holding_interact: bool = InputManager.is_action_pressed("interact")
	var aimed_deposit: Deposit = get_aimed_deposit()

	if holding_interact and aimed_deposit and aimed_deposit.is_pinged() and not aimed_deposit.is_analyzed():
		# Start or continue analysis
		if not _is_analyzing or _analysis_target != aimed_deposit:
			_start_analysis(aimed_deposit)
		_analysis_progress += delta / ANALYSIS_DURATION
		analysis_progress_changed.emit(clampf(_analysis_progress, 0.0, 1.0))
		if _analysis_progress >= 1.0:
			_complete_analysis()
	elif _is_analyzing:
		_cancel_analysis()

func _start_analysis(deposit: Deposit) -> void:
	_analysis_target = deposit
	_analysis_progress = 0.0
	_is_analyzing = true
	analysis_started.emit(deposit)

func _complete_analysis() -> void:
	if _analysis_target:
		_analysis_target.mark_analyzed()
		analysis_completed.emit(_analysis_target)
	_is_analyzing = false
	_analysis_progress = 0.0

func _cancel_analysis() -> void:
	_is_analyzing = false
	_analysis_progress = 0.0
	_analysis_target = null
	analysis_cancelled.emit()

func _cast_interaction_ray() -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = _camera.get_world_3d().direct_space_state
	var from: Vector3 = _camera.global_position
	var forward: Vector3 = -_camera.global_transform.basis.z
	var to: Vector3 = from + forward * INTERACTION_RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = LAYER_INTERACTABLE
	return space_state.intersect_ray(query)
