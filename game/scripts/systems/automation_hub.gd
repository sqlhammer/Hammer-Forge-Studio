## AutomationHub autoload: manages mining drone deployment and the Automation Hub module.
## Requires tech tree node 'automation_hub' unlocked and AutomationHub module installed.
## Drones autonomously mine analyzed deposits; energy is drawn from ShipState power.
extends Node

# ── Signals ──────────────────────────────────────────────
signal drone_started(deposit_id: String)
signal drone_completed(deposit_id: String, yield_quantity: int)
signal drone_returned

# ── Constants ─────────────────────────────────────────────

## Module ID matching the catalog entry in ModuleDefs.
const MODULE_ID: String = "automation_hub"

## Maximum simultaneous active drones for Tier 1 Automation Hub. Placeholder — confirm with Studio Head.
const MAX_ACTIVE_DRONES_TIER_1: int = 2

## Ship power draw per active drone (units per second). Drawn from ShipState, not suit battery.
## Placeholder — confirm with Studio Head.
const DRONE_POWER_DRAW_PER_SECOND: float = 3.0

## Units extracted per drone per second while in EXTRACTING state.
## Placeholder — confirm with Studio Head.
const DRONE_EXTRACTION_RATE: float = 2.0

# ── Private Variables ─────────────────────────────────────

## Active drone agents. Key: drone_id (int), Value: DroneAgent.
var _drones: Dictionary = {}

## Next drone ID to assign.
var _next_drone_id: int = 0

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	set_process(false)
	Global.log("AutomationHub: initialized")

func _process(delta: float) -> void:
	if _drones.is_empty():
		set_process(false)
		return
	_tick_drones(delta)

# ── Public Methods ────────────────────────────────────────

## Deploys a new mining drone with the given program.
## Validates module installed, tech tree gate, and active drone limit.
## Returns the drone_id on success, or -1 on failure.
func deploy_drone(program: DroneProgram) -> int:
	if not ModuleManager.is_installed(MODULE_ID):
		Global.log("AutomationHub: deploy failed — module not installed")
		return -1

	if not TechTree.is_unlocked("automation_hub"):
		Global.log("AutomationHub: deploy failed — tech tree node 'automation_hub' not unlocked")
		return -1

	if get_active_drone_count() >= MAX_ACTIVE_DRONES_TIER_1:
		Global.log("AutomationHub: deploy failed — maximum drones active (%d/%d)" % [get_active_drone_count(), MAX_ACTIVE_DRONES_TIER_1])
		return -1

	var drone: DroneAgent = DroneAgent.new()
	drone.setup(_next_drone_id, program)
	_drones[_next_drone_id] = drone
	var assigned_id: int = _next_drone_id
	_next_drone_id += 1

	set_process(true)
	Global.log("AutomationHub: deployed drone %d" % assigned_id)
	return assigned_id

## Assigns a deposit target to an idle drone. The deposit must be Phase 2 analyzed.
## Returns true on success, false on failure.
func assign_target(drone_id: int, deposit: Deposit) -> bool:
	if not _drones.has(drone_id):
		Global.log("AutomationHub: assign failed — drone %d not found" % drone_id)
		return false

	var drone: DroneAgent = _drones[drone_id] as DroneAgent
	if not drone.is_idle():
		Global.log("AutomationHub: assign failed — drone %d is not idle (state: %s)" % [drone_id, DroneAgent.DroneState.keys()[drone.get_state()]])
		return false

	# Enforce scanner-first constraint.
	if deposit.get_scan_state() != Deposit.ScanState.ANALYZED:
		Global.log("AutomationHub: assign failed — deposit '%s' has not completed Phase 2 Analysis" % deposit.name)
		return false

	# Validate drone program accepts this deposit.
	var program: DroneProgram = drone.get_program()
	if program != null and not program.accepts_deposit(deposit):
		Global.log("AutomationHub: assign failed — drone %d program rejects deposit '%s'" % [drone_id, deposit.name])
		return false

	drone.start_travel(deposit.name)
	drone_started.emit(deposit.name)
	Global.log("AutomationHub: drone %d assigned to deposit '%s'" % [drone_id, deposit.name])
	return true

## Recalls a drone, transitioning it to RETURNING and then IDLE.
func recall_drone(drone_id: int) -> void:
	if not _drones.has(drone_id):
		return
	var drone: DroneAgent = _drones[drone_id] as DroneAgent
	drone.start_returning()
	Global.log("AutomationHub: drone %d recalled" % drone_id)

## Removes a drone from the active pool. Call after it has returned.
func remove_drone(drone_id: int) -> void:
	if _drones.has(drone_id):
		_drones.erase(drone_id)
		if _drones.is_empty():
			set_process(false)
		Global.log("AutomationHub: drone %d removed" % drone_id)

## Returns the number of currently active drones.
func get_active_drone_count() -> int:
	return _drones.size()

## Returns the maximum number of simultaneous drones allowed at current tier.
func get_max_drones() -> int:
	return MAX_ACTIVE_DRONES_TIER_1

## Returns a status summary for all active drones.
func get_drone_status_list() -> Array[Dictionary]:
	var status_list: Array[Dictionary] = []
	for drone_id: int in _drones.keys():
		var drone: DroneAgent = _drones[drone_id] as DroneAgent
		status_list.append(drone.get_status_summary())
	return status_list

# ── Private Methods ───────────────────────────────────────

## Advances all drone state machines each frame.
## Handles TRAVELING → EXTRACTING → RETURNING → IDLE transitions.
func _tick_drones(delta: float) -> void:
	var drones_to_remove: Array[int] = []

	for drone_id: int in _drones.keys():
		var drone: DroneAgent = _drones[drone_id] as DroneAgent
		var state: DroneAgent.DroneState = drone.get_state()

		if state == DroneAgent.DroneState.TRAVELING:
			# Physical travel is handled by TICKET-0072 gameplay scripts.
			# Data layer: transition is driven externally when drone arrives.
			pass

		elif state == DroneAgent.DroneState.EXTRACTING:
			# Consume ship power while extracting.
			var power_cost: float = DRONE_POWER_DRAW_PER_SECOND * delta
			ShipState.adjust_power(-power_cost)

		elif state == DroneAgent.DroneState.RETURNING:
			# Physical return travel handled by TICKET-0072.
			# Data layer: mark as returned when arrival is confirmed externally.
			pass

	# Clean up any drones flagged for removal.
	for drone_id: int in drones_to_remove:
		_drones.erase(drone_id)

## Called by gameplay scripts (TICKET-0072) when a drone finishes extraction at a deposit.
## deposit_id: the deposit node name. yield_quantity: units extracted.
func notify_extraction_complete(drone_id: int, deposit_id: String, yield_quantity: int) -> void:
	if not _drones.has(drone_id):
		return
	var drone: DroneAgent = _drones[drone_id] as DroneAgent
	drone.start_returning()
	drone_completed.emit(deposit_id, yield_quantity)
	Global.log("AutomationHub: drone %d completed extraction at '%s' (yield=%d)" % [drone_id, deposit_id, yield_quantity])

## Called by gameplay scripts (TICKET-0072) when a drone physically returns to the hub.
func notify_drone_returned(drone_id: int) -> void:
	if not _drones.has(drone_id):
		return
	var drone: DroneAgent = _drones[drone_id] as DroneAgent
	drone.return_to_idle()
	drone_returned.emit()
	Global.log("AutomationHub: drone %d returned to idle" % drone_id)
