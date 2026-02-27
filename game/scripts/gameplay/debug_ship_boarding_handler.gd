# DebugShipBoardingHandler - Boarding logic for debug-launched sessions - Owner: gameplay-programmer
# Mirrors the enter/exit ship logic in TestWorld for DebugWorld sessions where
# TestWorld is never instantiated. Added as a child of DebugWorld by DebugLauncher.
# Ticket: TICKET-0208
class_name DebugShipBoardingHandler
extends Node


# ── Private Variables ─────────────────────────────────────

var _ship_interior: ShipInterior = null
var _first_person: CharacterBody3D = null
var _ship_enter_zone: ShipEnterZone = null
var _hud: GameHUD = null
var _player_near_ship_entrance: bool = false
var _transitioning: bool = false


# ── Built-in Virtual Methods ──────────────────────────────

func _process(_delta: float) -> void:
	if _transitioning or not _ship_interior:
		return

	# Enter ship from exterior
	if _player_near_ship_entrance and not _ship_interior.is_player_inside():
		if InputManager.is_action_just_pressed("interact"):
			_begin_enter_ship()
			return

	# Exit ship from interior exit zone
	if _ship_interior.is_player_inside() and _ship_interior.is_player_in_exit_zone():
		if InputManager.is_action_just_pressed("interact"):
			_begin_exit_ship()
			return


# ── Public Methods ────────────────────────────────────────

## Wires the handler to the ship interior, player, enter zone, and HUD.
## Must be called after all nodes are in the scene tree.
func setup(
	ship_interior: ShipInterior,
	first_person: CharacterBody3D,
	enter_zone: ShipEnterZone,
	hud: GameHUD,
) -> void:
	_ship_interior = ship_interior
	_first_person = first_person
	_ship_enter_zone = enter_zone
	_hud = hud
	enter_zone.body_entered.connect(_on_ship_enter_zone_entered)
	enter_zone.body_exited.connect(_on_ship_enter_zone_exited)
	ship_interior.player_entered_ship.connect(_on_player_entered_ship)
	ship_interior.player_exited_ship.connect(_on_player_exited_ship)


# ── Private Methods ───────────────────────────────────────

func _begin_enter_ship() -> void:
	_transitioning = true
	await _ship_interior.enter_ship(_first_person)
	_transitioning = false


func _begin_exit_ship() -> void:
	_transitioning = true
	await _ship_interior.exit_ship()
	_transitioning = false


func _on_ship_enter_zone_entered(body: Node3D) -> void:
	if body == _first_person:
		_player_near_ship_entrance = true
		Global.log("DebugShipBoardingHandler: player near ship entrance")


func _on_ship_enter_zone_exited(body: Node3D) -> void:
	if body == _first_person:
		_player_near_ship_entrance = false


func _on_player_entered_ship() -> void:
	if _hud:
		_hud.show_ship_globals(true)
	if _ship_enter_zone:
		_ship_enter_zone.set_prompt_enabled(false)


func _on_player_exited_ship() -> void:
	if _ship_enter_zone:
		_ship_enter_zone.set_prompt_enabled(true)
	if _hud:
		_hud.show_ship_globals(false)
