## Manages all physical drone instances in the world.
## Spawns DroneController nodes, assigns targets from DepositRegistry, and handles recall.
class_name DroneManager
extends Node3D

# ── Constants ─────────────────────────────────────────────
const MINING_DRONE_SCENE: String = "res://scenes/objects/mining_drone.tscn"

# ── Private Variables ─────────────────────────────────────
var _home_position: Vector3 = Vector3.ZERO
var _drones: Dictionary = {}  # drone_id (int) → DroneController

# ── Public Methods ────────────────────────────────────────

## Initializes the manager with the ship's home position for drone return.
func setup(home_position: Vector3) -> void:
	_home_position = home_position
	Global.debug_log("DroneManager: setup with home at %s" % str(home_position))

## Spawns a new physical drone with the given ID and program.
func spawn_drone(drone_id: int, program: DroneProgram) -> void:
	if _drones.has(drone_id):
		Global.debug_log("DroneManager: drone %d already exists, skipping spawn" % drone_id)
		return
	var drone_scene: PackedScene = load(MINING_DRONE_SCENE) as PackedScene
	var controller: DroneController = drone_scene.instantiate() as DroneController
	controller.setup(drone_id, _home_position, program)
	add_child(controller)
	_drones[drone_id] = controller
	# Auto-assign first target
	_assign_next_target(controller)
	Global.debug_log("DroneManager: spawned drone %d" % drone_id)

## Recalls all active drones, forcing them to return home.
func recall_all_drones() -> void:
	for drone_id: int in _drones.keys():
		var controller: DroneController = _drones[drone_id] as DroneController
		controller.recall()
	Global.debug_log("DroneManager: recalled all drones")

## Returns a drone controller by ID, or null if not found.
func get_drone_controller(drone_id: int) -> DroneController:
	return _drones.get(drone_id, null) as DroneController

# ── Built-in Virtual Methods ──────────────────────────────

func _process(_delta: float) -> void:
	if _drones.is_empty():
		return
	# Auto-assign idle drones to new targets
	for drone_id: int in _drones.keys():
		var controller: DroneController = _drones[drone_id] as DroneController
		if controller.is_idle():
			_assign_next_target(controller)

# ── Private Methods ───────────────────────────────────────

## Finds the best matching deposit for an idle drone and assigns it.
func _assign_next_target(controller: DroneController) -> void:
	var program: DroneProgram = controller.get_program()
	if not program:
		return

	var candidates: Array[Deposit] = DepositRegistry.get_in_range(_home_position, program.extraction_radius)
	var valid_targets: Array[Deposit] = []

	for deposit: Deposit in candidates:
		if program.accepts_deposit(deposit):
			valid_targets.append(deposit)

	if valid_targets.is_empty():
		return

	# Sort by priority
	var sorted_target: Deposit = _select_by_priority(valid_targets, program.priority_order)
	if sorted_target:
		var success: bool = AutomationHub.assign_target(controller.get_drone_id(), sorted_target)
		if success:
			controller.assign_target(sorted_target)

## Selects the best deposit from candidates based on priority order.
func _select_by_priority(candidates: Array[Deposit], priority_order: int) -> Deposit:
	if candidates.is_empty():
		return null

	match priority_order:
		0:  # Highest Purity First
			var best: Deposit = candidates[0]
			for deposit: Deposit in candidates:
				if deposit.purity > best.purity:
					best = deposit
			return best
		1:  # Nearest First
			var best: Deposit = candidates[0]
			var best_dist_sq: float = _home_position.distance_squared_to(best.global_position)
			for deposit: Deposit in candidates:
				var dist_sq: float = _home_position.distance_squared_to(deposit.global_position)
				if dist_sq < best_dist_sq:
					best = deposit
					best_dist_sq = dist_sq
			return best
		2:  # Highest Density First
			var best: Deposit = candidates[0]
			for deposit: Deposit in candidates:
				if deposit.density_tier > best.density_tier:
					best = deposit
			return best
		_:
			return candidates[0]
