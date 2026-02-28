## Mining system: hold-to-extract resources from analyzed deposits.
## Includes optional minigame — trace lit pattern lines during extraction for +50% yield bonus.
class_name Mining
extends Node

# ── Signals ──────────────────────────────────────────────
signal mining_started(deposit: Deposit)
signal mining_progress_changed(progress: float)
signal mining_completed(deposit: Deposit, resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int)
signal mining_cancelled
signal mining_failed(reason: String)
signal minigame_started(line_count: int)
signal line_traced(line_index: int)
signal minigame_completed(all_traced: bool, bonus_quantity: int)

# ── Constants ─────────────────────────────────────────────
const EXTRACTION_DURATION: float = 3.0
const EXTRACTION_AMOUNT: int = 8
const MINING_MAX_RANGE: float = 5.0

const MINING_RAY_LENGTH: float = 6.0

## Minigame tuning
const BONUS_MULTIPLIER: float = 0.5
const PARTIAL_YIELD_MULTIPLIER: float = 0.5  ## Fraction of yield kept when a pressurized resource minigame fails
const LINE_TRACE_DWELL: float = 0.4  ## Seconds crosshair must dwell on a line to trace it

## Scene reference for mining minigame visualization
const MINING_MINIGAME_SCENE: PackedScene = preload("res://scenes/objects/mining_minigame.tscn")

## Default visual mesh scale when no mesh child is found on the deposit
const DEFAULT_VISUAL_SCALE := Vector3(3.2, 3.2, 3.2)

## Default vertical offset for the minigame node when no mesh child is found
const DEFAULT_MESH_Y_OFFSET: float = 0.9

# ── Private Variables ─────────────────────────────────────
var _camera: Camera3D = null
var _player: CharacterBody3D = null
var _scanner: Scanner = null
var _mining_target: Deposit = null
var _mining_progress: float = 0.0
var _is_mining: bool = false
var _drill_mesh: MeshInstance3D = null

## Minigame state
var _minigame_active: bool = false
var _pattern_line_count: int = 0
var _lines_traced: Array[bool] = []
var _line_dwell_times: Array[float] = []
var _minigame_node: MiningMinigame = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if not _camera:
		return
	_update_mining(delta)
	_update_drill_visibility()

# ── Public Methods ────────────────────────────────────────

## Initializes the mining system with required references.
func setup(camera: Camera3D, player: CharacterBody3D, scanner: Scanner) -> void:
	_camera = camera
	_player = player
	_scanner = scanner
	_setup_drill_viewmodel()

## Updates the active camera reference (used on view mode switch).
func set_camera(camera: Camera3D) -> void:
	_camera = camera

## Returns the current mining progress (0.0 to 1.0).
func get_mining_progress() -> float:
	return _mining_progress

## Returns true if currently mining.
func is_mining() -> bool:
	return _is_mining

## Returns the current mining target deposit.
func get_mining_target() -> Deposit:
	return _mining_target

## Returns true if the minigame is currently active.
func is_minigame_active() -> bool:
	return _minigame_active

## Returns the index of the pattern line currently under the crosshair, or -1.
func get_hovered_line_index() -> int:
	if not _minigame_active:
		return -1
	return _get_hovered_line_index()

# ── Private Methods ───────────────────────────────────────

func _update_mining(delta: float) -> void:
	var holding_use_tool: bool = InputManager.is_action_pressed("use_tool")
	var aimed_deposit: Deposit = _scanner.get_aimed_deposit() if _scanner else null

	if holding_use_tool and aimed_deposit and aimed_deposit.is_analyzed() and not aimed_deposit.is_depleted():
		# Check preconditions
		if not SuitBattery.can_mine(aimed_deposit.deposit_tier):
			if _is_mining:
				_cancel_mining()
			Global.log("Mining: failed — insufficient battery charge")
			mining_failed.emit("NO CHARGE")
			return

		if PlayerInventory.is_full():
			if _is_mining:
				_cancel_mining()
			Global.log("Mining: failed — inventory full")
			mining_failed.emit("INVENTORY FULL")
			return

		# Start or continue mining
		if not _is_mining or _mining_target != aimed_deposit:
			_start_mining(aimed_deposit)

		# Deep nodes mine slower based on yield_rate (0.1 = 10x longer)
		var effective_yield_rate: float = maxf(aimed_deposit.yield_rate, 0.01)
		var effective_duration: float = EXTRACTION_DURATION / effective_yield_rate
		_mining_progress += delta / effective_duration
		mining_progress_changed.emit(clampf(_mining_progress, 0.0, 1.0))

		# Drain battery proportionally over extraction duration
		var total_cost: float = SuitBattery.estimate_mining_cost(aimed_deposit.deposit_tier, EXTRACTION_AMOUNT)
		var drain_per_second: float = total_cost / effective_duration
		SuitBattery.drain(drain_per_second * delta)

		# Check if battery depleted during mining
		if SuitBattery.is_depleted():
			_cancel_mining()
			mining_failed.emit("NO CHARGE")
			return

		# Update minigame trace detection
		if _minigame_active:
			_update_minigame_trace(delta)

		if _mining_progress >= 1.0:
			_complete_mining()
	elif _is_mining:
		_cancel_mining()

func _start_mining(deposit: Deposit) -> void:
	_mining_target = deposit
	_mining_progress = 0.0
	_is_mining = true
	Global.log("Mining: extraction started on deposit at %s" % str(deposit.global_position))
	mining_started.emit(deposit)
	_start_minigame(deposit)

func _complete_mining() -> void:
	if not _mining_target:
		return
	var result: Dictionary = _mining_target.extract(EXTRACTION_AMOUNT)
	if result.is_empty():
		Global.log("Mining: extraction returned empty result")
		_cleanup_minigame()
		return

	var extracted: int = result.get("quantity", 0) as int
	var all_traced: bool = _are_all_lines_traced()
	var minigame_succeeded: bool = all_traced and _minigame_active and _pattern_line_count > 0
	var is_pressurized: bool = ResourceDefs.is_pressurized(_mining_target.resource_type)

	var effective_extracted: int = extracted
	var bonus: int = 0

	if is_pressurized and not minigame_succeeded:
		# Pressurized resource with failed or skipped minigame: partial yield (resource vented)
		effective_extracted = ceili(extracted * PARTIAL_YIELD_MULTIPLIER)
		Global.log("Mining: pressurized resource vented — partial yield %d/%d" % [effective_extracted, extracted])
	elif minigame_succeeded:
		bonus = ceili(extracted * BONUS_MULTIPLIER)

	var total_to_add: int = effective_extracted + bonus
	if total_to_add > 0:
		var leftover: int = PlayerInventory.add_item(
			_mining_target.resource_type,
			_mining_target.purity,
			total_to_add,
		)
		var added: int = total_to_add - leftover
		Global.log("Mining: extraction completed — extracted %d, bonus %d, added %d to inventory" % [extracted, bonus, added])
		if added > 0:
			mining_completed.emit(_mining_target, _mining_target.resource_type, _mining_target.purity, added)

	if _minigame_active:
		minigame_completed.emit(all_traced, bonus)

	_cleanup_minigame()
	_is_mining = false
	_mining_progress = 0.0
	_mining_target = null

func _cancel_mining() -> void:
	Global.log("Mining: extraction cancelled")
	_cleanup_minigame()
	_is_mining = false
	_mining_progress = 0.0
	_mining_target = null
	mining_cancelled.emit()

# ── Minigame Methods ─────────────────────────────────────

func _start_minigame(deposit: Deposit) -> void:
	_pattern_line_count = deposit.get_pattern_line_count()
	if _pattern_line_count <= 0:
		_minigame_active = false
		return

	_minigame_active = true
	_lines_traced.clear()
	_line_dwell_times.clear()

	for i: int in range(_pattern_line_count):
		_lines_traced.append(false)
		_line_dwell_times.append(0.0)

	_setup_minigame_node(deposit)
	_minigame_node.create_lines(_pattern_line_count, _player.global_position)
	Global.log("Mining: minigame started — %d lines to trace" % _pattern_line_count)
	minigame_started.emit(_pattern_line_count)

## Finds or creates a MiningMinigame child node on the deposit, positioned and
## scaled to match the deposit's visual mesh.
func _setup_minigame_node(deposit: Deposit) -> void:
	_minigame_node = deposit.get_node_or_null("MiningMinigame") as MiningMinigame
	if _minigame_node:
		return

	_minigame_node = MINING_MINIGAME_SCENE.instantiate() as MiningMinigame
	_minigame_node.name = "MiningMinigame"

	# Match position and scale to the deposit's visual mesh
	var mesh_info: Dictionary = _find_deposit_mesh_info(deposit)
	var y_offset: float = mesh_info.get("y_offset", DEFAULT_MESH_Y_OFFSET) as float
	var visual_scale: Vector3 = mesh_info.get("scale", DEFAULT_VISUAL_SCALE) as Vector3
	_minigame_node.position = Vector3(0.0, y_offset, 0.0)
	_minigame_node.scale = visual_scale

	deposit.add_child(_minigame_node)

## Searches the deposit's children for a visual mesh node and returns its
## position Y offset and scale. Defaults to standard values if no mesh is found.
func _find_deposit_mesh_info(deposit: Deposit) -> Dictionary:
	for child: Node in deposit.get_children():
		if child is Node3D and "Mesh" in child.name:
			var child_3d: Node3D = child as Node3D
			return {
				"y_offset": child_3d.position.y,
				"scale": child_3d.scale,
			}
	return {
		"y_offset": DEFAULT_MESH_Y_OFFSET,
		"scale": DEFAULT_VISUAL_SCALE,
	}

func _update_minigame_trace(delta: float) -> void:
	var hovered_index: int = _get_hovered_line_index()

	for i: int in range(_pattern_line_count):
		if _lines_traced[i]:
			continue
		if i == hovered_index:
			_line_dwell_times[i] += delta
			if _line_dwell_times[i] >= LINE_TRACE_DWELL:
				_lines_traced[i] = true
				if _minigame_node:
					_minigame_node.mark_line_traced(i)
				Global.log("Mining: minigame line %d traced" % i)
				line_traced.emit(i)
		else:
			# Dwell resets when crosshair leaves the line
			_line_dwell_times[i] = maxf(_line_dwell_times[i] - delta * 2.0, 0.0)

func _get_hovered_line_index() -> int:
	if not _camera or not _minigame_node:
		return -1

	var positions: Array[Vector3] = _minigame_node.get_line_world_positions()
	if positions.is_empty():
		return -1

	var ray_origin: Vector3 = _camera.global_position
	var ray_dir: Vector3 = -_camera.global_transform.basis.z
	var trace_radius: float = _minigame_node.get_trace_radius()

	var best_index: int = -1
	var best_dist: float = trace_radius

	for i: int in range(_pattern_line_count):
		if i >= positions.size():
			continue
		var line_pos: Vector3 = positions[i]
		var to_point: Vector3 = line_pos - ray_origin
		var along_ray: float = to_point.dot(ray_dir)
		if along_ray < 0.0:
			continue  # Behind camera
		var closest_on_ray: Vector3 = ray_origin + ray_dir * along_ray
		var dist: float = closest_on_ray.distance_to(line_pos)
		if dist < best_dist:
			best_dist = dist
			best_index = i

	return best_index

func _are_all_lines_traced() -> bool:
	for traced: bool in _lines_traced:
		if not traced:
			return false
	return true

func _cleanup_minigame() -> void:
	if _minigame_node and is_instance_valid(_minigame_node):
		_minigame_node.cleanup()
		_minigame_node.queue_free()
	_minigame_node = null
	_lines_traced.clear()
	_line_dwell_times.clear()
	_minigame_active = false
	_pattern_line_count = 0

# ── Drill Viewmodel ──────────────────────────────────────

func _setup_drill_viewmodel() -> void:
	# Create a simple hand drill mesh visible in first person
	_drill_mesh = MeshInstance3D.new()
	var drill_scene: Resource = load("res://assets/meshes/tools/mesh_hand_drill.glb")
	if drill_scene and drill_scene is PackedScene:
		var drill_instance: Node3D = (drill_scene as PackedScene).instantiate()
		_drill_mesh.add_child(drill_instance)
	else:
		# Fallback: simple box mesh
		var box := BoxMesh.new()
		box.size = Vector3(0.08, 0.08, 0.3)
		_drill_mesh.mesh = box
	_drill_mesh.visible = false
	if _camera:
		_camera.add_child(_drill_mesh)
		# Position in lower-right of view
		_drill_mesh.position = Vector3(0.3, -0.25, -0.5)
		_drill_mesh.rotation_degrees = Vector3(-10, -15, 0)

func _update_drill_visibility() -> void:
	if _drill_mesh:
		_drill_mesh.visible = _is_mining
