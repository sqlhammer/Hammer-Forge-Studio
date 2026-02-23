## Mining system: hold-to-extract resources from analyzed deposits.
class_name Mining
extends Node

# ── Signals ──────────────────────────────────────────────
signal mining_started(deposit: Deposit)
signal mining_progress_changed(progress: float)
signal mining_completed(deposit: Deposit, resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int)
signal mining_cancelled
signal mining_failed(reason: String)

# ── Constants ─────────────────────────────────────────────
const EXTRACTION_DURATION: float = 3.0
const EXTRACTION_AMOUNT: int = 8
const MINING_MAX_RANGE: float = 5.0

## Physics layers for interaction raycast
const LAYER_INTERACTABLE: int = 1 << 3  # Layer 4
const MINING_RAY_LENGTH: float = 6.0

# ── Private Variables ─────────────────────────────────────
var _camera: Camera3D = null
var _player: CharacterBody3D = null
var _scanner: Scanner = null
var _mining_target: Deposit = null
var _mining_progress: float = 0.0
var _is_mining: bool = false
var _drill_mesh: MeshInstance3D = null

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

func _complete_mining() -> void:
	if not _mining_target:
		return
	var result: Dictionary = _mining_target.extract(EXTRACTION_AMOUNT)
	if result.is_empty():
		Global.log("Mining: extraction returned empty result")
		return
	var extracted: int = result.get("quantity", 0) as int
	if extracted > 0:
		var leftover: int = PlayerInventory.add_item(
			_mining_target.resource_type,
			_mining_target.purity,
			extracted,
		)
		var added: int = extracted - leftover
		Global.log("Mining: extraction completed — extracted %d, added %d to inventory, leftover %d" % [extracted, added, leftover])
		if added > 0:
			mining_completed.emit(_mining_target, _mining_target.resource_type, _mining_target.purity, added)
	_is_mining = false
	_mining_progress = 0.0
	# Auto-restart if deposit still has resources and player is still holding
	_mining_target = null

func _cancel_mining() -> void:
	Global.log("Mining: extraction cancelled")
	_is_mining = false
	_mining_progress = 0.0
	_mining_target = null
	mining_cancelled.emit()

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
