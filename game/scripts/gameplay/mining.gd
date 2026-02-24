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

## Physics layers for interaction raycast
const LAYER_INTERACTABLE: int = 1 << 3  # Layer 4
const MINING_RAY_LENGTH: float = 6.0

## Minigame tuning
const BONUS_MULTIPLIER: float = 0.5
const LINE_TRACE_DWELL: float = 0.4  ## Seconds crosshair must dwell on a line to trace it
const LINE_TRACE_RADIUS: float = 0.45  ## Max ray-to-line distance for dwell accumulation

## 3D line visual dimensions
const LINE_MESH_LENGTH: float = 1.4
const LINE_MESH_HEIGHT: float = 0.12
const LINE_MESH_DEPTH: float = 0.06

## Line glow colors
const COLOR_LINE_PENDING := Color("#00D4AA")  # Teal
const COLOR_LINE_TRACED := Color("#4ADE80")  # Green

## Line offsets in player-facing local space (X=right, Y=up, Z=toward player from deposit center)
const LINE_OFFSETS: Array = [
	Vector3(0.0, -0.3, 1.35),
	Vector3(0.25, 0.5, 1.2),
	Vector3(-0.2, 1.2, 1.0),
	Vector3(0.4, 0.1, 1.3),
]

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
var _line_world_positions: Array[Vector3] = []
var _line_meshes: Array[MeshInstance3D] = []
var _line_materials: Array[StandardMaterial3D] = []

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

		_mining_progress += delta / EXTRACTION_DURATION
		mining_progress_changed.emit(clampf(_mining_progress, 0.0, 1.0))

		# Drain battery proportionally over extraction duration
		var total_cost: float = SuitBattery.estimate_mining_cost(aimed_deposit.deposit_tier, EXTRACTION_AMOUNT)
		var drain_per_second: float = total_cost / EXTRACTION_DURATION
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
	var bonus: int = 0
	if all_traced and _minigame_active and _pattern_line_count > 0:
		bonus = ceili(extracted * BONUS_MULTIPLIER)

	var total_to_add: int = extracted + bonus
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
	_line_world_positions.clear()

	for i in range(_pattern_line_count):
		_lines_traced.append(false)
		_line_dwell_times.append(0.0)

	_create_pattern_lines(deposit)
	Global.log("Mining: minigame started — %d lines to trace" % _pattern_line_count)
	minigame_started.emit(_pattern_line_count)

func _create_pattern_lines(deposit: Deposit) -> void:
	# Compute player-facing orientation for line placement
	var deposit_center: Vector3 = deposit.global_position + Vector3(0, 0.9, 0)
	var to_player: Vector3 = _player.global_position - deposit_center
	to_player.y = 0.0
	if to_player.length_squared() < 0.01:
		to_player = Vector3(0, 0, 1)
	to_player = to_player.normalized()
	var right: Vector3 = to_player.cross(Vector3.UP).normalized()

	for i in range(_pattern_line_count):
		var offset: Vector3 = LINE_OFFSETS[i]
		var world_offset: Vector3 = right * offset.x + Vector3.UP * offset.y + to_player * offset.z
		var line_pos: Vector3 = deposit_center + world_offset
		_line_world_positions.append(line_pos)

		# Visual mesh
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "PatternLine%d" % i
		var box := BoxMesh.new()
		box.size = Vector3(LINE_MESH_LENGTH, LINE_MESH_HEIGHT, LINE_MESH_DEPTH)
		mesh_inst.mesh = box
		mesh_inst.global_position = line_pos
		mesh_inst.look_at(line_pos + to_player, Vector3.UP)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = COLOR_LINE_PENDING
		mat.emission_enabled = true
		mat.emission = COLOR_LINE_PENDING
		mat.emission_energy_multiplier = 2.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh_inst.material_override = mat

		deposit.add_child(mesh_inst)
		_line_meshes.append(mesh_inst)
		_line_materials.append(mat)

func _update_minigame_trace(delta: float) -> void:
	var hovered_index: int = _get_hovered_line_index()

	for i in range(_pattern_line_count):
		if _lines_traced[i]:
			continue
		if i == hovered_index:
			_line_dwell_times[i] += delta
			if _line_dwell_times[i] >= LINE_TRACE_DWELL:
				_lines_traced[i] = true
				_mark_line_visual_traced(i)
				Global.log("Mining: minigame line %d traced" % i)
				line_traced.emit(i)
		else:
			# Dwell resets when crosshair leaves the line
			_line_dwell_times[i] = maxf(_line_dwell_times[i] - delta * 2.0, 0.0)

func _get_hovered_line_index() -> int:
	if not _camera or _line_world_positions.is_empty():
		return -1

	var ray_origin: Vector3 = _camera.global_position
	var ray_dir: Vector3 = -_camera.global_transform.basis.z

	var best_index: int = -1
	var best_dist: float = LINE_TRACE_RADIUS

	for i in range(_pattern_line_count):
		var line_pos: Vector3 = _line_world_positions[i]
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

func _mark_line_visual_traced(index: int) -> void:
	if index >= 0 and index < _line_materials.size():
		_line_materials[index].albedo_color = COLOR_LINE_TRACED
		_line_materials[index].emission = COLOR_LINE_TRACED

func _are_all_lines_traced() -> bool:
	for traced: bool in _lines_traced:
		if not traced:
			return false
	return true

func _cleanup_minigame() -> void:
	for mesh: MeshInstance3D in _line_meshes:
		if is_instance_valid(mesh):
			mesh.queue_free()
	_line_meshes.clear()
	_line_materials.clear()
	_line_world_positions.clear()
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
