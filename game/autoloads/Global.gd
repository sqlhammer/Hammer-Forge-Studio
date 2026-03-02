## Global utility autoload for shared helper functions and debug logging.
extends Node

# ── Public Variables ─────────────────────────────────────
var starting_biome: String = "shattered_flats"
var starting_inventory: Dictionary = {}
var debug_speed_multiplier: float = 1.0

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	debug_log("Global ready — starting_biome: %s, starting_inventory: %s" % [starting_biome, str(starting_inventory)])

# ── Public Methods ────────────────────────────────────────
## Logs a debug message if running in debug build.
func debug_log(message: String) -> void:
	if OS.is_debug_build():
		print("[%s] %s" % [Time.get_ticks_msec(), message])
