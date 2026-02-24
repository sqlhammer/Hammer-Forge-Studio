## Data container for a single mining drone agent.
## Tracks assignment, target, and state machine state. Owned by AutomationHub.
class_name DroneAgent
extends RefCounted

# ── Enums ─────────────────────────────────────────────────

## Drone operational state machine.
enum DroneState {
	IDLE = 0,        ## No target assigned; waiting for a valid deposit.
	TRAVELING = 1,   ## Moving toward the assigned deposit.
	EXTRACTING = 2,  ## Actively mining the assigned deposit.
	RETURNING = 3,   ## Returning to the Automation Hub after extraction.
}

# ── Private Variables ─────────────────────────────────────
var _drone_id: int = 0
var _program: DroneProgram = null
var _current_target_deposit_id: String = ""
var _state: DroneState = DroneState.IDLE

# ── Public Methods ────────────────────────────────────────

## Initializes the drone with a unique ID and an assigned program.
func setup(drone_id: int, program: DroneProgram) -> void:
	_drone_id = drone_id
	_program = program
	_state = DroneState.IDLE

## Returns this drone's unique ID.
func get_drone_id() -> int:
	return _drone_id

## Returns the assigned DroneProgram, or null if none assigned.
func get_program() -> DroneProgram:
	return _program

## Assigns a new program to this drone. Only valid when idle.
func assign_program(program: DroneProgram) -> void:
	_program = program

## Returns the node path string of the current target deposit, or empty if none.
func get_target_deposit_id() -> String:
	return _current_target_deposit_id

## Returns the current operational state.
func get_state() -> DroneState:
	return _state

## Returns true if the drone is idle (no active assignment).
func is_idle() -> bool:
	return _state == DroneState.IDLE

## Transitions the drone to the TRAVELING state toward the given deposit ID.
func start_travel(deposit_id: String) -> void:
	_current_target_deposit_id = deposit_id
	_state = DroneState.TRAVELING

## Transitions the drone to the EXTRACTING state (arrived at deposit).
func start_extracting() -> void:
	_state = DroneState.EXTRACTING

## Transitions the drone to the RETURNING state (extraction complete).
func start_returning() -> void:
	_state = DroneState.RETURNING

## Resets the drone to IDLE and clears the current target.
func return_to_idle() -> void:
	_current_target_deposit_id = ""
	_state = DroneState.IDLE

## Returns a summary dictionary for logging and UI display.
func get_status_summary() -> Dictionary:
	return {
		"drone_id": _drone_id,
		"state": DroneState.keys()[_state],
		"target_deposit_id": _current_target_deposit_id,
		"has_program": _program != null,
	}
