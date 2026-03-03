# DebugShipBoardingHandler - Boarding logic for debug-launched sessions - Owner: gameplay-programmer
# Mirrors the enter/exit ship logic in GameWorld for DebugWorld sessions where
# GameWorld is not instantiated directly. Added as a child of DebugWorld by DebugLauncher.
# Ticket: TICKET-0208
class_name DebugShipBoardingHandler
extends Node


# ── Constants ─────────────────────────────────────────────

## Raycast distance for boarding aim check — generous to avoid needing to press against the hull.
const BOARDING_RAY_LENGTH: float = 30.0

# ── Private Variables ─────────────────────────────────────

var _ship_interior: ShipInterior = null
var _first_person: CharacterBody3D = null
var _ship_enter_zone: ShipEnterZone = null
var _hud: GameHUD = null
var _navigation_console: NavigationConsole = null
var _camera: Camera3D = null
var _ship_exterior: Node3D = null
var _player_near_ship_entrance: bool = false
var _transitioning: bool = false


# ── Built-in Virtual Methods ──────────────────────────────

func _process(_delta: float) -> void:
	if _transitioning or not _ship_interior:
		return

	# Enter ship from exterior — sync aim validity each frame for prompt display
	if _player_near_ship_entrance and not _ship_interior.is_player_inside():
		var aiming: bool = _is_aiming_at_ship()
		_ship_enter_zone.set_aim_valid(aiming)
		if aiming and InputManager.is_action_just_pressed("interact"):
			_begin_enter_ship()
		return

	# Cockpit navigation console — must be checked before exit zone for GameWorld parity
	if _ship_interior.is_player_inside() and not (_navigation_console and _navigation_console.is_open()):
		if _ship_interior.is_player_near_cockpit_console():
			if InputManager.is_action_just_pressed("interact"):
				if _navigation_console:
					_navigation_console.open_panel()
				return

	# Machine slot — open module placement UI when near a placement zone
	if _ship_interior.is_player_inside() and _hud:
		var module_ui: ModulePlacementUI = _hud.get_module_placement_ui()
		if module_ui and not module_ui.is_open():
			var zone_index: int = _ship_interior.get_nearby_zone_index()
			if zone_index >= 0 and InputManager.is_action_just_pressed("interact"):
				module_ui.open(zone_index)
				return

	# Exit ship from interior exit zone
	if _ship_interior.is_player_inside() and _ship_interior.is_player_in_exit_zone():
		if InputManager.is_action_just_pressed("interact"):
			_begin_exit_ship()
			return


# ── Public Methods ────────────────────────────────────────

## Wires the handler to the ship interior, player, enter zone, HUD, and navigation console.
## Must be called after all nodes are in the scene tree.
func setup(
	ship_interior: ShipInterior,
	first_person: CharacterBody3D,
	enter_zone: ShipEnterZone,
	hud: GameHUD,
	navigation_console: NavigationConsole = null,
	camera: Camera3D = null,
	ship_exterior: Node3D = null,
) -> void:
	_ship_interior = ship_interior
	_first_person = first_person
	_ship_enter_zone = enter_zone
	_hud = hud
	_navigation_console = navigation_console
	_camera = camera
	_ship_exterior = ship_exterior
	enter_zone.body_entered.connect(_on_ship_enter_zone_entered)
	enter_zone.body_exited.connect(_on_ship_enter_zone_exited)
	ship_interior.player_entered_ship.connect(_on_player_entered_ship)
	ship_interior.player_exited_ship.connect(_on_player_exited_ship)


# ── Private Methods ───────────────────────────────────────

## Returns true if the player camera is pointing at the ship exterior mesh.
## Casts a ray from the camera along its forward vector and checks if the hit
## collider is a descendant of the ship exterior node (in the "ship" group).
func _is_aiming_at_ship() -> bool:
	if not _camera:
		# No camera reference — fall back to allowing boarding (graceful degradation)
		return true
	var space_state: PhysicsDirectSpaceState3D = _camera.get_world_3d().direct_space_state
	var from: Vector3 = _camera.global_position
	var forward: Vector3 = -_camera.global_transform.basis.z
	var to: Vector3 = from + forward * BOARDING_RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = PhysicsLayers.ENVIRONMENT
	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		return false
	var collider: Object = result.get("collider")
	if not collider or not (collider is Node):
		return false
	# Walk up the parent chain to see if the hit belongs to a ship node
	var node: Node = collider as Node
	while node:
		if node.is_in_group("ship"):
			return true
		node = node.get_parent()
	return false


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
		Global.debug_log("DebugShipBoardingHandler: player near ship entrance")


func _on_ship_enter_zone_exited(body: Node3D) -> void:
	if body == _first_person:
		_player_near_ship_entrance = false
		_ship_enter_zone.set_aim_valid(false)


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
