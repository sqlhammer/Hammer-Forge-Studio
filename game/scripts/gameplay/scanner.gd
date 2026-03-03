## Scanner system: handles ping detection and deposit analysis.
## Supports first-person (raycast) and third-person (proximity) targeting.
## Includes radial wheel for resource type selection before ping.
class_name Scanner
extends Node

# ── Signals ──────────────────────────────────────────────
signal ping_completed(deposits: Array[Deposit])
signal deposit_ping_revealed(deposit: Deposit)
signal analysis_started(deposit: Deposit)
signal analysis_progress_changed(progress: float)
signal analysis_completed(deposit: Deposit)
signal analysis_cancelled

# ── Constants ─────────────────────────────────────────────
const PING_RANGE: float = 1000.0
const PING_SPEED: float = 100.0
const PING_COOLDOWN: float = 1.0
const ANALYSIS_DURATION: float = 2.5
const ANALYSIS_MAX_RANGE: float = 5.0
const FACING_DISTANCE_CONE_DEG: float = 45.0

const INTERACTION_RAY_LENGTH: float = 6.0

## Ping ring visual
const PING_RING_COLOR := Color("#00D4AA", 0.8)
const PING_RING_Y_OFFSET: float = 0.2
const PING_RING_FADE_TIME: float = 1.0

## Hold threshold in seconds — hold longer than this to open the radial wheel
const HOLD_THRESHOLD: float = 0.2

## Minimum mouse displacement from center to register as a direction
const MOUSE_DIRECTION_THRESHOLD: float = 30.0

# ── Private Variables ─────────────────────────────────────
var _camera: Camera3D = null
var _player: CharacterBody3D = null
var _ping_cooldown_timer: float = 0.0
var _analysis_target: Deposit = null
var _analysis_progress: float = 0.0
var _is_analyzing: bool = false
var _view_mode: String = "first_person"

## Radial wheel state
var _resource_wheel: ResourceTypeWheel = null
var _ping_was_pressed: bool = false
var _ping_hold_time: float = -1.0
var _wheel_showing: bool = false
var _selected_resource_type: ResourceDefs.ResourceType = ResourceDefs.ResourceType.NONE

## Ping propagation state
var _ping_propagating: bool = false
var _ping_ring_radius: float = 0.0
var _ping_ring_fading: bool = false
var _ping_ring_fade_elapsed: float = 0.0
var _ping_pending_reveals: Array[Dictionary] = []
var _ping_ring_node: MeshInstance3D = null
var _ping_ring_material: StandardMaterial3D = null

# ── Built-in Virtual Methods ──────────────────────────────

func _process(delta: float) -> void:
	if not _camera:
		return
	_update_ping_cooldown(delta)
	_check_ping_input()
	_update_ping_propagation(delta)
	_update_analysis(delta)

# ── Public Methods ────────────────────────────────────────

## Initializes the scanner with the player camera reference.
func setup(camera: Camera3D, player: CharacterBody3D) -> void:
	_camera = camera
	_player = player

## Assigns the radial wheel Control used for resource type selection.
func set_resource_wheel(wheel: ResourceTypeWheel) -> void:
	_resource_wheel = wheel

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

## Handles hold-to-open-wheel and tap-to-quick-ping input logic.
## Hold ping (Q / LB) beyond HOLD_THRESHOLD → opens radial wheel; release fires.
## Tap ping (release before threshold) → fires immediately with last-used type.
func _check_ping_input() -> void:
	var ping_pressed: bool = InputManager.is_action_pressed("ping")
	var ping_just_pressed: bool = InputManager.is_action_just_pressed("ping")

	# Start tracking on initial press
	if ping_just_pressed:
		_ping_hold_time = 0.0
		_wheel_showing = false

	# Accumulate hold time while pressed
	if ping_pressed and _ping_hold_time >= 0.0:
		_ping_hold_time += get_process_delta_time()

		# Open wheel after hold threshold
		var has_wheel: bool = _resource_wheel != null and _resource_wheel.has_segments()
		if _ping_hold_time >= HOLD_THRESHOLD and not _wheel_showing and has_wheel:
			_resource_wheel.show_wheel()
			_wheel_showing = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Global.debug_log("Scanner: radial wheel opened")

		# Update wheel selection each frame while showing
		if _wheel_showing and _resource_wheel:
			var direction: Vector2 = _get_wheel_input_direction()
			_resource_wheel.update_selection(direction)

	# Detect release: was pressed last frame, not pressed this frame
	if _ping_was_pressed and not ping_pressed:
		if _wheel_showing:
			_handle_wheel_release()
		elif _ping_hold_time >= 0.0 and _ping_hold_time < HOLD_THRESHOLD:
			_handle_tap_ping()
		_ping_hold_time = -1.0
		_wheel_showing = false

	_ping_was_pressed = ping_pressed


## Fires the ping with the type selected on the radial wheel.
func _handle_wheel_release() -> void:
	if not _resource_wheel:
		return
	var selected_type: ResourceDefs.ResourceType = _resource_wheel.get_selected_type()
	_resource_wheel.hide_wheel()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if selected_type == ResourceDefs.ResourceType.NONE:
		Global.debug_log("Scanner: wheel released with no type — ping cancelled")
		return
	if _ping_cooldown_timer > 0.0:
		Global.debug_log("Scanner: ping on cooldown — ignoring wheel release")
		return

	_selected_resource_type = selected_type
	_do_ping(selected_type)


## Fires the ping immediately with the last-used resource type (tap behavior).
func _handle_tap_ping() -> void:
	if _ping_cooldown_timer > 0.0:
		return
	var tap_type: ResourceDefs.ResourceType = _get_quick_ping_type()
	if tap_type == ResourceDefs.ResourceType.NONE:
		Global.debug_log("Scanner: tap ping has no type selected — ignoring")
		return
	_do_ping(tap_type)


## Returns the input direction for wheel selection.
## Keyboard/mouse uses cursor position relative to screen center.
## Gamepad uses left stick analog input.
func _get_wheel_input_direction() -> Vector2:
	var device: String = InputManager.get_current_input_device()
	if device == "gamepad":
		return InputManager.get_analog_input("left")
	# Mouse: position relative to viewport center (mouse is uncaptured while wheel is open)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var center: Vector2 = viewport_size / 2.0
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var direction: Vector2 = mouse_pos - center
	if direction.length() > MOUSE_DIRECTION_THRESHOLD:
		return direction.normalized()
	return Vector2.ZERO


## Returns the resource type for a quick-tap ping.
## Uses last manually selected type, falling back to the wheel's default.
func _get_quick_ping_type() -> ResourceDefs.ResourceType:
	if _selected_resource_type != ResourceDefs.ResourceType.NONE:
		return _selected_resource_type
	if _resource_wheel:
		return _resource_wheel.get_last_used_type()
	return ResourceDefs.ResourceType.NONE


## Fires a scanner ping filtered to a specific resource type.
## Only deposits matching the filter type are pinged and included in the result.
## Data is computed upfront; compass markers appear progressively as the ring expands.
func _do_ping(filter_type: ResourceDefs.ResourceType) -> void:
	_ping_cooldown_timer = PING_COOLDOWN
	var player_pos: Vector3 = _player.global_position
	var all_deposits: Array[Deposit] = DepositRegistry.get_in_range(player_pos, PING_RANGE)
	var filtered_deposits: Array[Deposit] = []
	for deposit: Deposit in all_deposits:
		if deposit.resource_type == filter_type:
			filtered_deposits.append(deposit)
	var type_name: String = ResourceDefs.get_resource_name(filter_type)
	Global.debug_log("Scanner: ping fired for %s — %d/%d deposits match" % [type_name, filtered_deposits.size(), all_deposits.size()])
	for deposit: Deposit in filtered_deposits:
		if not deposit.is_pinged():
			deposit.ping()
	_start_ping_propagation(filtered_deposits, player_pos)
	ping_completed.emit(filtered_deposits)


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

## Sets up the progressive reveal state and spawns the expanding ring mesh.
func _start_ping_propagation(deposits: Array[Deposit], origin: Vector3) -> void:
	# Stop any existing propagation before starting a new one
	if _ping_propagating:
		_stop_ping_propagation()

	_ping_ring_radius = 0.0
	_ping_propagating = true
	_ping_ring_fading = false
	_ping_ring_fade_elapsed = 0.0
	_ping_pending_reveals.clear()

	for deposit: Deposit in deposits:
		var distance: float = origin.distance_to(deposit.global_position)
		_ping_pending_reveals.append({
			"deposit": deposit,
			"distance": distance,
		})

	# Sort by distance so closest deposits reveal first
	_ping_pending_reveals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["distance"] < b["distance"]
	)

	_spawn_ping_ring()


## Creates the ring mesh for the propagation VFX. Driven frame-by-frame, not by tween.
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

	_ping_ring_node = ring
	_ping_ring_material = mat
	Global.debug_log("Scanner: ping ring spawned — propagating at %s m/s" % str(PING_SPEED))


## Advances the ring radius each frame and reveals deposits as the ring reaches them.
func _update_ping_propagation(delta: float) -> void:
	if not _ping_propagating:
		return

	if not _ping_ring_fading:
		# Expand the ring at constant speed
		_ping_ring_radius += PING_SPEED * delta

		# Reveal deposits whose distance the ring has reached
		while _ping_pending_reveals.size() > 0:
			var entry: Dictionary = _ping_pending_reveals[0]
			var deposit_distance: float = entry["distance"]
			if _ping_ring_radius >= deposit_distance:
				var deposit: Deposit = entry["deposit"] as Deposit
				if is_instance_valid(deposit):
					deposit_ping_revealed.emit(deposit)
				_ping_pending_reveals.remove_at(0)
			else:
				break

		# Update the ring mesh scale and alpha
		if is_instance_valid(_ping_ring_node):
			# Torus outer_radius is 0.5 — scale factor = radius / 0.5
			var ring_scale: float = _ping_ring_radius * 2.0
			_ping_ring_node.scale = Vector3(ring_scale, 1.0, ring_scale)
			# Fade alpha gradually as ring expands so it doesn't obscure gameplay
			var expansion_progress: float = _ping_ring_radius / PING_RANGE
			var alpha: float = lerpf(0.8, 0.2, expansion_progress)
			_ping_ring_material.albedo_color.a = alpha
			var emission: float = lerpf(2.0, 0.4, expansion_progress)
			_ping_ring_material.emission_energy_multiplier = emission

		# Transition to fade when the ring hits the range cap
		if _ping_ring_radius >= PING_RANGE:
			_ping_ring_fading = true
			_ping_ring_fade_elapsed = 0.0
			# Reveal any remaining deposits that haven't been revealed yet
			for entry: Dictionary in _ping_pending_reveals:
				var deposit: Deposit = entry["deposit"] as Deposit
				if is_instance_valid(deposit):
					deposit_ping_revealed.emit(deposit)
			_ping_pending_reveals.clear()
	else:
		# Fade out the ring after reaching max range
		_ping_ring_fade_elapsed += delta
		var fade_progress: float = _ping_ring_fade_elapsed / PING_RING_FADE_TIME
		if is_instance_valid(_ping_ring_node):
			_ping_ring_material.albedo_color.a = lerpf(0.2, 0.0, fade_progress)
			_ping_ring_material.emission_energy_multiplier = lerpf(0.4, 0.0, fade_progress)
		if fade_progress >= 1.0:
			_stop_ping_propagation()


## Cleans up the propagation state and frees the ring mesh.
func _stop_ping_propagation() -> void:
	_ping_propagating = false
	_ping_ring_fading = false
	_ping_pending_reveals.clear()
	if is_instance_valid(_ping_ring_node):
		_ping_ring_node.queue_free()
	_ping_ring_node = null
	_ping_ring_material = null
