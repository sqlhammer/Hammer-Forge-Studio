## Global utility autoload for shared helper functions and debug logging.
extends Node

# ── Public Methods ────────────────────────────────────────
## Logs a debug message if running in debug build.
func log(message: String) -> void:
	if OS.is_debug_build():
		print("[%s] %s" % [Time.get_ticks_msec(), message])
