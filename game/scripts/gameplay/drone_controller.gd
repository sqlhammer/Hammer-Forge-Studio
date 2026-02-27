## Physical drone entity: greybox mesh that travels to deposits, extracts resources, and returns.
## Managed by DroneManager. Drives the DroneAgent state machine in AutomationHub.
class_name DroneController
extends CharacterBody3D

# ── Constants ─────────────────────────────────────────────
const DRONE_SPEED: float = 8.0
const ARRIVAL_THRESHOLD: float = 2.0
const HOVER_HEIGHT: float = 3.0

# ── Private Variables ─────────────────────────────────────
var _drone_id: int = -1
var _home_position: Vector3 = Vector3.ZERO
var _program: DroneProgram = null
var _target_deposit: Deposit = null
var _target_position: Vector3 = Vector3.ZERO
var _state: DroneAgent.DroneState = DroneAgent.DroneState.IDLE
var _extraction_accumulator: float = 0.0
var _total_yield: int = 0

# ── Built-in Virtual Methods ──────────────────────────────

func _process(delta: float) -> void:
	match _state:
		DroneAgent.DroneState.TRAVELING:
			_process_traveling(delta)
		DroneAgent.DroneState.EXTRACTING:
			_process_extracting(delta)
		DroneAgent.DroneState.RETURNING:
			_process_returning(delta)

# ── Public Methods ────────────────────────────────────────

## Initializes the drone with an ID, home position, and program.
func setup(drone_id: int, home_position: Vector3, program: DroneProgram) -> void:
	_drone_id = drone_id
	_home_position = home_position
	_program = program
	_state = DroneAgent.DroneState.IDLE
	name = "Drone_%d" % drone_id
	global_position = Vector3(home_position.x, HOVER_HEIGHT, home_position.z)
	Global.log("DroneController: drone %d initialized at home" % drone_id)

## Returns this drone's unique ID.
func get_drone_id() -> int:
	return _drone_id

## Returns the current state.
func get_state() -> DroneAgent.DroneState:
	return _state

## Returns true if the drone is idle and ready for a new assignment.
func is_idle() -> bool:
	return _state == DroneAgent.DroneState.IDLE

## Returns the assigned program.
func get_program() -> DroneProgram:
	return _program

## Assigns a target deposit and transitions to TRAVELING state.
func assign_target(deposit: Deposit) -> void:
	_target_deposit = deposit
	_target_position = Vector3(deposit.global_position.x, HOVER_HEIGHT, deposit.global_position.z)
	_state = DroneAgent.DroneState.TRAVELING
	_extraction_accumulator = 0.0
	_total_yield = 0
	Global.log("DroneController: drone %d assigned to '%s'" % [_drone_id, deposit.name])

## Forces the drone to return home immediately.
func recall() -> void:
	_target_deposit = null
	_state = DroneAgent.DroneState.RETURNING
	Global.log("DroneController: drone %d recalled" % _drone_id)

# ── Private Methods ───────────────────────────────────────

func _process_traveling(delta: float) -> void:
	global_position = global_position.move_toward(_target_position, DRONE_SPEED * delta)
	var distance: float = global_position.distance_to(_target_position)
	if distance <= ARRIVAL_THRESHOLD:
		_state = DroneAgent.DroneState.EXTRACTING
		AutomationHub.notify_drone_arrived(_drone_id)
		Global.log("DroneController: drone %d arrived at target, extracting" % _drone_id)

func _process_extracting(delta: float) -> void:
	if not _target_deposit or _target_deposit.is_depleted():
		_finish_extraction()
		return

	# Deep nodes extract slower based on yield_rate (0.1 = 10% of normal speed)
	var effective_rate: float = AutomationHub.DRONE_EXTRACTION_RATE * _target_deposit.yield_rate
	_extraction_accumulator += effective_rate * delta
	var units_to_extract: int = int(_extraction_accumulator)
	if units_to_extract > 0:
		_extraction_accumulator -= units_to_extract
		var result: Dictionary = _target_deposit.extract(units_to_extract)
		if not result.is_empty():
			var extracted_qty: int = result.get("quantity", 0) as int
			var resource_type: ResourceDefs.ResourceType = result.get("resource_type", ResourceDefs.ResourceType.NONE) as ResourceDefs.ResourceType
			var purity: ResourceDefs.Purity = result.get("purity", ResourceDefs.Purity.ONE_STAR) as ResourceDefs.Purity
			PlayerInventory.add_item(resource_type, purity, extracted_qty)
			_total_yield += extracted_qty

	if _target_deposit.is_depleted():
		_finish_extraction()

func _finish_extraction() -> void:
	var deposit_name: String = _target_deposit.name if _target_deposit else "unknown"
	AutomationHub.notify_extraction_complete(_drone_id, deposit_name, _total_yield)
	_target_deposit = null
	_state = DroneAgent.DroneState.RETURNING
	Global.log("DroneController: drone %d finished extraction (yield=%d), returning" % [_drone_id, _total_yield])

func _process_returning(delta: float) -> void:
	var home_hover: Vector3 = Vector3(_home_position.x, HOVER_HEIGHT, _home_position.z)
	global_position = global_position.move_toward(home_hover, DRONE_SPEED * delta)
	var distance: float = global_position.distance_to(home_hover)
	if distance <= ARRIVAL_THRESHOLD:
		AutomationHub.notify_drone_returned(_drone_id)
		_state = DroneAgent.DroneState.IDLE
		Global.log("DroneController: drone %d returned home" % _drone_id)

