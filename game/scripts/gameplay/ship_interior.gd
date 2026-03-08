## Greybox ship interior: multi-room layout (24m×12m) with cockpit, machine room, corridor,
## vestibule, four module zones, and entry/exit transition system.
class_name ShipInterior
extends Node3D

# ── Signals ──────────────────────────────────────────────
signal player_entered_ship
signal player_exited_ship
signal placement_zone_interacted(zone_index: int)

# ── Constants ─────────────────────────────────────────────
## Room dimensions (per M7 wireframe TICKET-0123)
const CEILING_HEIGHT: float = 3.0
const CORRIDOR_WIDTH: float = 4.0
const CORRIDOR_DEPTH: float = 2.0
const VESTIBULE_WIDTH: float = 4.0
const VESTIBULE_DEPTH: float = 4.0

## Zone layout — 4 zones in 2×2 grid within machine room
const ZONE_SIZE: float = 3.0
const ZONE_COUNT: int = 4
const ZONE_A_CENTER := Vector3(-2.5, 0.0, 4.5)
const ZONE_B_CENTER := Vector3(2.5, 0.0, 4.5)
const ZONE_C_CENTER := Vector3(-2.5, 0.0, -0.5)
const ZONE_D_CENTER := Vector3(2.5, 0.0, -0.5)
const ZONE_INTERACT_OFFSET: float = 0.5
const INTERACT_RANGE: float = 2.0

## Greybox materials
const COLOR_ZONE_TEAL := Color("#00D4AA", 0.3)
const COLOR_ZONE_TEAL_OCCUPIED := Color("#00D4AA", 0.15)

## Fade transition
const FADE_DURATION: float = 0.3

# ── Private Variables ─────────────────────────────────────
var _zone_areas: Array[Area3D] = []
var _zone_floor_markers: Array[MeshInstance3D] = []
var _zone_occupied: Array[bool] = [false, false, false, false]
var _zone_module_nodes: Array[Node3D] = [null, null, null, null]
var _player_ref: CharacterBody3D = null
var _is_player_inside: bool = false
var _player_in_exit_zone: bool = false

# ── Onready Variables ─────────────────────────────────────
@onready var _enter_marker: Marker3D = $InteriorSpawn
@onready var _exterior_marker: Marker3D = $ExteriorSpawn
@onready var _exit_zone: ShipExitZone = $ExitTrigger
@onready var _terminal_area: Area3D = $TerminalArea
@onready var _cockpit_console_area: Area3D = $CockpitConsoleArea
@onready var _sub_viewport: SubViewport = $ExteriorViewport
@onready var _viewport_camera: Camera3D = $ExteriorViewport/ExteriorCamera
@onready var _viewport_window: MeshInstance3D = $ViewportWindow
@onready var _fade_layer: CanvasLayer = $FadeLayer
@onready var _fade_rect: ColorRect = $FadeLayer/FadeRect
@onready var _zone_marker_0: MeshInstance3D = $ZoneMarker_0
@onready var _zone_marker_1: MeshInstance3D = $ZoneMarker_1
@onready var _zone_marker_2: MeshInstance3D = $ZoneMarker_2
@onready var _zone_marker_3: MeshInstance3D = $ZoneMarker_3
@onready var _placement_zone_0: Area3D = $PlacementZone_0
@onready var _placement_zone_1: Area3D = $PlacementZone_1
@onready var _placement_zone_2: Area3D = $PlacementZone_2
@onready var _placement_zone_3: Area3D = $PlacementZone_3

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_zone_floor_markers = [_zone_marker_0, _zone_marker_1, _zone_marker_2, _zone_marker_3]
	_zone_areas = [_placement_zone_0, _placement_zone_1, _placement_zone_2, _placement_zone_3]
	# Viewport window texture must be assigned at runtime from the SubViewport
	if _viewport_window and _sub_viewport:
		var viewport_mat: StandardMaterial3D = _viewport_window.material_override as StandardMaterial3D
		if viewport_mat:
			viewport_mat.albedo_texture = _sub_viewport.get_texture()
	Global.debug_log("ShipInterior: initialized — 24m×12m multi-room layout")

# ── Public Methods ────────────────────────────────────────

## Sets the player reference for interaction detection.
func setup(player: CharacterBody3D) -> void:
	_player_ref = player

## Returns true if the player is currently inside the ship.
func is_player_inside() -> bool:
	return _is_player_inside

## Transitions the player into the ship interior with a fade.
func enter_ship(player: CharacterBody3D) -> void:
	if _is_player_inside:
		return
	_player_ref = player
	Global.debug_log("ShipInterior: player entering ship")
	await _fade_out()
	player.global_position = _enter_marker.global_position
	_is_player_inside = true
	player_entered_ship.emit()
	await _fade_in()
	Global.debug_log("ShipInterior: player entered ship")

## Transitions the player out of the ship with a fade.
func exit_ship() -> void:
	if not _is_player_inside or not _player_ref:
		return
	Global.debug_log("ShipInterior: player exiting ship")
	await _fade_out()
	_player_ref.velocity = Vector3.ZERO
	_player_ref.global_position = _exterior_marker.global_position
	_is_player_inside = false
	player_exited_ship.emit()
	await _fade_in()
	Global.debug_log("ShipInterior: player exited ship")

## Returns the exterior marker position for the test world to set.
func get_exterior_marker() -> Marker3D:
	return _exterior_marker

## Sets the exterior exit position.
func set_exterior_position(pos: Vector3) -> void:
	_exterior_marker.global_position = pos

## Returns the enter marker for the interior.
func get_enter_marker() -> Marker3D:
	return _enter_marker

## Returns true if the given zone index is occupied by a module.
func is_zone_occupied(zone_index: int) -> bool:
	if zone_index < 0 or zone_index >= _zone_occupied.size():
		return false
	return _zone_occupied[zone_index]

## Places a module mesh in the given zone. Returns the parent Node3D for the module.
func place_module_in_zone(zone_index: int, module_mesh: Node3D) -> void:
	if zone_index < 0 or zone_index >= _zone_occupied.size():
		return
	_zone_occupied[zone_index] = true
	var zone_centers: Array[Vector3] = [ZONE_A_CENTER, ZONE_B_CENTER, ZONE_C_CENTER, ZONE_D_CENTER]
	module_mesh.position = zone_centers[zone_index]
	add_child(module_mesh)
	_zone_module_nodes[zone_index] = module_mesh
	_update_zone_visual(zone_index)
	Global.debug_log("ShipInterior: module placed in zone %d" % zone_index)

## Removes a module from the given zone.
func remove_module_from_zone(zone_index: int) -> void:
	if zone_index < 0 or zone_index >= _zone_occupied.size():
		return
	if _zone_module_nodes[zone_index]:
		_zone_module_nodes[zone_index].queue_free()
		_zone_module_nodes[zone_index] = null
	_zone_occupied[zone_index] = false
	_update_zone_visual(zone_index)
	Global.debug_log("ShipInterior: module removed from zone %d" % zone_index)

## Returns the module node at a given zone, or null.
func get_module_at_zone(zone_index: int) -> Node3D:
	if zone_index < 0 or zone_index >= _zone_module_nodes.size():
		return null
	return _zone_module_nodes[zone_index]

## Returns the number of placement zones.
func get_zone_count() -> int:
	return _zone_areas.size()

## Returns the first empty zone index, or -1 if all occupied.
func get_first_empty_zone() -> int:
	for i: int in range(_zone_occupied.size()):
		if not _zone_occupied[i]:
			return i
	return -1

## Returns true if the player is standing in the exit zone.
func is_player_in_exit_zone() -> bool:
	return _player_in_exit_zone

## Returns true if the player is near the tech tree terminal.
func is_player_near_terminal() -> bool:
	if not _player_ref or not _terminal_area:
		return false
	return _terminal_area.get_overlapping_bodies().has(_player_ref)

## Returns true if the player is near the cockpit navigation console.
func is_player_near_cockpit_console() -> bool:
	if not _player_ref or not _cockpit_console_area:
		return false
	return _cockpit_console_area.get_overlapping_bodies().has(_player_ref)

## Returns true if the player is near a placement zone. Returns the zone index or -1.
func get_nearby_zone_index() -> int:
	if not _player_ref:
		return -1
	var zone_centers: Array[Vector3] = [ZONE_A_CENTER, ZONE_B_CENTER, ZONE_C_CENTER, ZONE_D_CENTER]
	var player_local: Vector3 = _player_ref.global_position - global_position
	for i: int in range(zone_centers.size()):
		var center: Vector3 = zone_centers[i]
		var dx: float = absf(player_local.x - center.x)
		var dz: float = absf(player_local.z - center.z)
		if dx <= INTERACT_RANGE and dz <= INTERACT_RANGE:
			return i
	return -1

## Configures the viewport window to render the exterior world.
## camera_position is the world-space position for the exterior camera.
## Since the camera's parent (SubViewport) is non-spatial, local position equals world position.
func setup_viewport_world(world: World3D, camera_position: Vector3) -> void:
	if _sub_viewport:
		_sub_viewport.world_3d = world
	if _viewport_camera:
		_viewport_camera.position = camera_position
		Global.debug_log("ShipInterior: viewport camera positioned at %s" % str(camera_position))

# ── Private Methods ───────────────────────────────────────

func _update_zone_visual(zone_index: int) -> void:
	if zone_index < 0 or zone_index >= _zone_floor_markers.size():
		return
	var marker: MeshInstance3D = _zone_floor_markers[zone_index]
	if not marker:
		return
	var mat: StandardMaterial3D = marker.material_override as StandardMaterial3D
	if _zone_occupied[zone_index]:
		mat.albedo_color = COLOR_ZONE_TEAL_OCCUPIED
		mat.emission_energy_multiplier = 0.15
	else:
		mat.albedo_color = COLOR_ZONE_TEAL
		mat.emission_energy_multiplier = 0.3

func _fade_out() -> Signal:
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, FADE_DURATION)
	return tween.finished

func _fade_in() -> Signal:
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, FADE_DURATION)
	return tween.finished

func _on_exit_zone_entered(body: Node3D) -> void:
	if body == _player_ref:
		_player_in_exit_zone = true
		Global.debug_log("ShipInterior: player in exit zone")

func _on_exit_zone_exited(body: Node3D) -> void:
	if body == _player_ref:
		_player_in_exit_zone = false
		Global.debug_log("ShipInterior: player left exit zone")
