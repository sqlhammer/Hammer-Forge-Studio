## Root game scene — single entry point for the entire project.
## In debug builds, instantiates DebugLauncher as a child.
## In release builds, transitions to MainMenu.
# Game - Root game entry point with debug/release routing - Owner: gameplay-programmer
class_name Game
extends Node

# ── Constants ─────────────────────────────────────────────
const DEBUG_LAUNCHER_SCENE: String = "res://scenes/debug/debug_launcher.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	if OS.is_debug_build():
		Global.log("Game: Debug build detected — loading DebugLauncher")
		var launcher: Control = load(DEBUG_LAUNCHER_SCENE).instantiate()
		add_child(launcher)
	else:
		Global.log("Game: Release build detected — transitioning to MainMenu")
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
