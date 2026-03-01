## Ship navigation system autoload: manages the biome registry, travel state
## machine, and fuel cost calculation for inter-biome jumps. Emits
## travel_completed and biome_changed on arrival, and travel_blocked if the
## ship lacks the fuel required for the requested jump.
## Ticket: TICKET-0159
class_name NavigationSystemType
extends Node

# ── Signals ──────────────────────────────────────────────

## Emitted when the ship successfully arrives at a new biome.
## Passes the destination biome ID.
signal travel_completed(destination_id: String)

## Emitted when travel is attempted but the ship lacks sufficient fuel.
## Passes the destination biome ID that was requested.
signal travel_blocked(destination_id: String)

## Emitted on arrival at a new biome. Sole integration point for the resource
## respawn system (TICKET-0161) and travel sequence visuals (TICKET-0168).
signal biome_changed(new_biome_id: String)

# ── Constants ─────────────────────────────────────────────

## Travel state machine states for inter-biome jump sequences.
enum TravelState {
	IDLE,       ## No travel in progress. Default/resting state.
	PREPARING,  ## Jump initiated: fuel cost computed, pre-flight checks run.
	IN_TRANSIT, ## Fuel consumed, ship is in mid-jump.
	ARRIVING,   ## Ship is decelerating into destination biome.
}

# ── Public Variables ──────────────────────────────────────

## ID of the biome where the ship currently resides.
## Read externally; mutated only by initiate_travel() on successful arrival.
var current_biome: String = "shattered_flats"

# ── Private Variables ─────────────────────────────────────

## Current state of the travel state machine.
var _state: TravelState = TravelState.IDLE

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	Global.log("NavigationSystem: initialized (current_biome=%s)" % current_biome)

# ── Public Methods ────────────────────────────────────────

## Returns the current travel state machine state.
func get_state() -> TravelState:
	return _state


## Returns the fuel cost (in fuel units) to travel from the current biome to
## destination_id, using the FuelSystem formula with the current ship weight.
## Returns 0.0 if the destination is unknown or is the current biome.
func get_travel_cost(destination_id: String) -> float:
	var distance: float = BiomeRegistry.get_distance(current_biome, destination_id)
	if distance < 0.0:
		return 0.0
	var ship_weight: float = FuelSystem.calculate_ship_weight()
	return FuelSystem.calculate_cost(distance, ship_weight)


## Returns true if the ship currently holds enough fuel to reach destination_id.
## Returns false for unknown destinations or if already at destination_id.
func can_travel_to(destination_id: String) -> bool:
	var distance: float = BiomeRegistry.get_distance(current_biome, destination_id)
	if distance < 0.0:
		return false
	var ship_weight: float = FuelSystem.calculate_ship_weight()
	return FuelSystem.can_travel(distance, ship_weight)


## Initiates travel to destination_id and runs the full state machine sequence:
##   IDLE → PREPARING → IN_TRANSIT → ARRIVING → IDLE
## Consumes fuel via FuelSystem on departure.
## Emits travel_blocked and returns early if fuel is insufficient.
## Emits travel_completed and biome_changed on successful arrival.
## No-ops silently if already in-transit or destination is invalid/current.
func initiate_travel(destination_id: String) -> void:
	if _state != TravelState.IDLE:
		Global.log("NavigationSystem: initiate_travel ignored — state is %s" % \
			TravelState.keys()[_state])
		return
	if not BiomeRegistry.is_valid_biome(destination_id):
		Global.log("NavigationSystem: unknown destination '%s'" % destination_id)
		return
	if destination_id == current_biome:
		Global.log("NavigationSystem: already at '%s' — no travel needed" % destination_id)
		return
	if not can_travel_to(destination_id):
		travel_blocked.emit(destination_id)
		Global.log("NavigationSystem: travel to '%s' blocked — insufficient fuel" % \
			destination_id)
		return

	# PREPARING: validate and compute cost
	_set_state(TravelState.PREPARING)
	var cost: float = get_travel_cost(destination_id)

	# IN_TRANSIT: consume fuel and mark ship as travelling
	FuelSystem.consume_fuel(cost)
	_set_state(TravelState.IN_TRANSIT)

	# ARRIVING: update current biome, return to IDLE, then fire arrival signals
	_set_state(TravelState.ARRIVING)
	var previous_biome: String = current_biome
	current_biome = destination_id
	_set_state(TravelState.IDLE)

	Global.log("NavigationSystem: emitting travel_completed for '%s'" % destination_id)
	travel_completed.emit(destination_id)
	biome_changed.emit(destination_id)
	Global.log("NavigationSystem: arrived at '%s' (from '%s', fuel_cost=%.1f)" % [
		destination_id, previous_biome, cost])


## Resets the navigation system to the starting biome (shattered_flats) and
## the IDLE state. Used for new-game initialization and test teardown.
func reset() -> void:
	current_biome = "shattered_flats"
	_state = TravelState.IDLE
	Global.log("NavigationSystem: reset to shattered_flats (IDLE)")

# ── Private Methods ───────────────────────────────────────

## Transitions to new_state and logs the change.
func _set_state(new_state: TravelState) -> void:
	_state = new_state
	Global.log("NavigationSystem: state → %s" % TravelState.keys()[new_state])
