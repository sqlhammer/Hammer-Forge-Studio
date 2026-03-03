## Scanner system: handles ping detection and deposit analysis.
## Supports first-person (raycast) and third-person (proximity) targeting.
class_name Scanner
extends Node

# ── Signals ──────────────────────────────────────────────
signal ping_completed(deposits: Array[Deposit])
signal analysis_started(deposit: Deposit)
signal analysis_progress_changed(progress: float)
signal analysis_completed(deposit: Deposit)
signal analysis_cancelled

# ── Constants ─────────────────────────────────────────────
const PING_RANGE: float = 320.0
const PING_COOLDOWN: float = 1.0
const ANALYSIS_DURATION: float = 2.5
const ANALYSIS_MAX_RANGE: float = 5.0
const FACING_DISTANCE_CONE_DEG: float = 45.0

const INTERACTION_RAY_LENGTH: float = 6.0

## Ping ring visual
const PING_RING_DURATION: float = 2.0
const PING_RING_COLOR := Color("#00D4AA", 0.8)
const PING_RING_Y_OFFSET: float = 0.2

# ── Private Variables ─────────────────────────────────────
var _camera: Camera3D = null
var _player: CharacterBody3D = null
var _ping_cooldown_timer: float = 0.0
var _analysis_target: Deposit = null
var _analysis_progress: float = 0.0
var _is_analyzing: bool = false
var _view_mode: String = "first_person"

# ── Built-in Virtual Methods ──────────────────────────────

func _process(delta: float) -> void:
	if not _camera:
		return
	_update_ping_cooldown(delta)
	_check_ping_input()
	_update_analysis(delta)

# ── Public Methods ────────────────────────────────────────

## Initializes the scanner with the player camera reference.
func setup(camera: Camera3D, player: CharacterBody3D) -> void:
	_camera = camera
	_player = player

## Updates the active camera reference (used on view mode switch).
func set_camera(camera: Camera3D) -> void:
	_camera = camera

## Sets the current view mode for targeting behavior.
func set_view_mode(mode: String) -> void:
	_view_mode = mode

## Returns the aimed deposit within interaction range, or null.
func get_aimed_deposit() -> Deposit:
	if _view_mode == "third_person":
		return _get_nearest_deposit()
	return _get_raycast_deposit()

## Returns the current analysis progress (0.0 to 1.0).
func get_analysis_progress() -> float:
	return _analysis_progress

## Returns true if currently analyzing.
func is_analyzing() -> bool:
	return _is_analyzing

## Returns the current analysis target deposit.
func get_analysis_target() -> Deposit:
	return _analysis_target

# ── Private Methods ───────────────────────────────────────

func _update_ping_cooldown(delta: float) -> void:
	_ping_cooldown_timer = maxf(_ping_cooldown_timer - delta, 0.0)

func _check_ping_input() -> void:
	if InputManager.is_action_just_pressed("ping") and _ping_cooldown_timer <= 0.0:
		_do_ping()

func _do_ping() -> void:
	_ping_cooldown_timer = PING_COOLDOWN
	var player_pos: Vector3 = _player.global_position
	var deposits: Array[Deposit] = DepositRegistry.get_in_range(player_pos, PING_RANGE)
	Global.debug_log("Scanner: ping fired — %d deposits in range" % deposits.size())
	for deposit: Deposit in deposits:
		if not deposit.is_pinged():
			deposit.ping()
	_spawn_ping_ring()
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
	Global.debug_log("Scanner: analysis started on deposit at %s" % str(deposit.global_position))
	analysis_started.emit(deposit)

func _complete_analysis() -> void:
	if _analysis_target:
		_analysis_target.mark_analyzed()
		Global.debug_log("Scanner: analysis completed on deposit at %s" % str(_analysis_target.global_position))
		analysis_completed.emit(_analysis_target)
	_is_analyzing = false
	_analysis_progress = 0.0

func _cancel_analysis() -> void:
	Global.debug_log("Scanner: analysis cancelled")
	_is_analyzing = false
	_analysis_progress = 0.0
	_analysis_target = null
	analysis_cancelled.emit()

func _get_raycast_deposit() -> Deposit:
	if not _camera:
		return null
	var result: Dictionary = _cast_interaction_ray()
	if result.is_empty():
		return null
	var collider: Object = result.get("collider")
	if not collider:
		return null
	var parent: Node = collider.get_parent()
	if parent is Deposit:
		return parent as Deposit
	return null

func _get_nearest_deposit() -> Deposit:
	if not _player:
		return null
	var player_pos: Vector3 = _player.global_position
	var deposits: Array[Deposit] = DepositRegistry.get_in_range(player_pos, ANALYSIS_MAX_RANGE)
	var nearest: Deposit = null
	var nearest_dist: float = INF
	for deposit: Deposit in deposits:
		if deposit.is_depleted():
			continue
		var dist: float = player_pos.distance_to(deposit.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = deposit
	return nearest

func _cast_interaction_ray() -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = _camera.get_world_3d().direct_space_state
	var from: Vector3 = _camera.global_position
	var forward: Vector3 = -_camera.global_transform.basis.z
	var to: Vector3 = from + forward * INTERACTION_RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = PhysicsLayers.INTERACTABLE
	return space_state.intersect_ray(query)

func _spawn_ping_ring() -> void:
	var ring := MeshInstance3D.new()
	ring.name = "PingRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.48
	torus.outer_radius = 0.5
	torus.rings = 64
	torus.ring_segments = 6
	ring.mesh = torus

	var mat := StandardMaterial3D.new()
	mat.albedo_color = PING_RING_COLOR
	mat.emission_enabled = true
	mat.emission = Color("#00D4AA")
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	ring.material_override = mat

	var ring_pos := Vector3(_player.global_position.x, PING_RING_Y_OFFSET, _player.global_position.z)
	_player.get_parent().add_child(ring)
	ring.global_position = ring_pos
	ring.scale = Vector3.ONE

	# Torus outer_radius is 0.5, so scale factor = PING_RANGE / 0.5 = PING_RANGE * 2
	var final_scale: float = PING_RANGE * 2.0
	var tween: Tween = ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(final_scale, 1.0, final_scale), PING_RING_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(mat, "albedo_color:a", 0.0, PING_RING_DURATION).set_ease(Tween.EASE_IN)
	tween.tween_property(mat, "emission_energy_multiplier", 0.0, PING_RING_DURATION)
	tween.set_parallel(false)
	tween.tween_callback(ring.queue_free)
	Global.debug_log("Scanner: ping ring spawned")
