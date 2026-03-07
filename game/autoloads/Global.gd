## Global utility autoload for shared helper functions and debug logging.
extends Node

# ── Public Variables ─────────────────────────────────────
var starting_biome: String = "shattered_flats"
var starting_inventory: Dictionary = {}
var debug_speed_multiplier: float = 1.0

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	debug_log("Global ready — starting_biome: %s, starting_inventory: %s" % [starting_biome, str(starting_inventory)])

# ── Built-in Input Methods ────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_state_dump"):
		_print_state_dump()

# ── Public Methods ────────────────────────────────────────
## Logs a debug message if running in debug build.
func debug_log(message: String) -> void:
	if OS.is_debug_build():
		print("[%s] %s" % [Time.get_ticks_msec(), message])

# ── Private Methods ──────────────────────────────────────
## Prints a structured state dump to the console for play-tester verification.
## Triggered by the debug_state_dump input action (F12).
## Output is delimited by STATE_DUMP_BEGIN/END markers for parsing.
func _print_state_dump() -> void:
	debug_log("=== STATE_DUMP_BEGIN ===")

	# Player state
	var player: Node = get_tree().root.find_child("Player", true, false)
	if player and player is Node3D:
		debug_log("PLAYER_POS: %s" % str((player as Node3D).global_position))
		if player is CharacterBody3D:
			var body: CharacterBody3D = player as CharacterBody3D
			debug_log("PLAYER_ON_FLOOR: %s" % str(body.is_on_floor()))
			debug_log("PLAYER_VELOCITY: %s" % str(body.velocity))

	# System autoload states
	debug_log("BIOME: %s" % NavigationSystem.current_biome)
	debug_log("BATTERY: %.2f" % SuitBattery.get_charge_percent())
	debug_log("INVENTORY_USED: %d" % PlayerInventory.get_used_slot_count())
	debug_log("FUEL: %.1f" % FuelSystem.fuel_current)

	debug_log("=== STATE_DUMP_END ===")
