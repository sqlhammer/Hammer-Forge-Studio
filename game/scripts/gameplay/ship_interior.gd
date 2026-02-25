## Greybox ship interior: walkable bay with module placement zones and entry/exit transition.
## Instanced by the test world when the player enters the ship. Independently testable.
class_name ShipInterior
extends Node3D

# ── Signals ──────────────────────────────────────────────
signal player_entered_ship
signal player_exited_ship
signal placement_zone_interacted(zone_index: int)

# ── Constants ─────────────────────────────────────────────
const BAY_WIDTH: float = 10.0
const BAY_DEPTH: float = 8.0
const CORRIDOR_WIDTH: float = 2.0
const CORRIDOR_DEPTH: float = 3.0
const CEILING_HEIGHT: float = 3.0

const ZONE_SIZE: float = 3.0
const ZONE_A_CENTER := Vector3(-2.5, 0.0, -1.0)
const ZONE_B_CENTER := Vector3(2.5, 0.0, -1.0)
const ZONE_INTERACT_OFFSET: float = 0.5
const INTERACT_RANGE: float = 2.0

## Greybox materials
const COLOR_FLOOR := Color("#4A4A4A")
const COLOR_WALLS := Color("#333333")
const COLOR_CEILING := Color("#2A2A2A")
const COLOR_CORRIDOR := Color("#555555")
const COLOR_ZONE_TEAL := Color("#00D4AA", 0.3)
const COLOR_ZONE_TEAL_OCCUPIED := Color("#00D4AA", 0.15)
const COLOR_LIGHT := Color("#E0E0E0")

## Physics layers
const LAYER_PLAYER: int = 1 << 0
const LAYER_ENVIRONMENT: int = 1 << 2
const LAYER_INTERACTABLE: int = 1 << 3

## Fade transition
const FADE_DURATION: float = 0.3

# ── Private Variables ─────────────────────────────────────
var _enter_marker: Marker3D = null
var _exit_marker: Marker3D = null
var _exterior_marker: Marker3D = null
var _zone_areas: Array[Area3D] = []
var _zone_floor_markers: Array[MeshInstance3D] = []
var _zone_occupied: Array[bool] = [false, false]
var _zone_module_nodes: Array[Node3D] = [null, null]
var _fade_rect: ColorRect = null
var _fade_layer: CanvasLayer = null
var _player_ref: CharacterBody3D = null
var _is_player_inside: bool = false
var _player_in_exit_zone: bool = false
var _terminal_area: Area3D = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_build_geometry()
	_build_module_zones()
	_build_spawn_markers()
	_build_lighting()
	_build_fade_overlay()
	_build_terminal()
	Global.log("ShipInterior: initialized")

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
	Global.log("ShipInterior: player entering ship")
	await _fade_out()
	player.global_position = _enter_marker.global_position
	_is_player_inside = true
	player_entered_ship.emit()
	await _fade_in()
	Global.log("ShipInterior: player entered ship")

## Transitions the player out of the ship with a fade.
func exit_ship() -> void:
	if not _is_player_inside or not _player_ref:
		return
	Global.log("ShipInterior: player exiting ship")
	await _fade_out()
	_player_ref.velocity = Vector3.ZERO
	_player_ref.global_position = _exterior_marker.global_position
	_is_player_inside = false
	player_exited_ship.emit()
	await _fade_in()
	Global.log("ShipInterior: player exited ship")

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
	var zone_center: Vector3 = ZONE_A_CENTER if zone_index == 0 else ZONE_B_CENTER
	module_mesh.position = zone_center
	add_child(module_mesh)
	_zone_module_nodes[zone_index] = module_mesh
	_update_zone_visual(zone_index)
	Global.log("ShipInterior: module placed in zone %d" % zone_index)

## Removes a module from the given zone.
func remove_module_from_zone(zone_index: int) -> void:
	if zone_index < 0 or zone_index >= _zone_occupied.size():
		return
	if _zone_module_nodes[zone_index]:
		_zone_module_nodes[zone_index].queue_free()
		_zone_module_nodes[zone_index] = null
	_zone_occupied[zone_index] = false
	_update_zone_visual(zone_index)
	Global.log("ShipInterior: module removed from zone %d" % zone_index)

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

## Returns true if the player is near the tech tree terminal on the north wall.
func is_player_near_terminal() -> bool:
	if not _player_ref or not _terminal_area:
		return false
	return _terminal_area.get_overlapping_bodies().has(_player_ref)

## Returns true if the player is near a placement zone. Returns the zone index or -1.
func get_nearby_zone_index() -> int:
	if not _player_ref:
		return -1
	for i: int in range(_zone_areas.size()):
		var zone: Area3D = _zone_areas[i]
		if zone.get_overlapping_bodies().has(_player_ref):
			return i
	return -1

# ── Private Methods ───────────────────────────────────────

func _build_geometry() -> void:
	# Floor (main bay)
	_create_static_surface(
		"BayFloor",
		Vector3(BAY_WIDTH, 0.1, BAY_DEPTH),
		Vector3(0, -0.05, 0),
		COLOR_FLOOR, 0.8
	)

	# Floor (corridor)
	var corridor_z: float = BAY_DEPTH / 2.0 + CORRIDOR_DEPTH / 2.0
	_create_static_surface(
		"CorridorFloor",
		Vector3(CORRIDOR_WIDTH, 0.1, CORRIDOR_DEPTH),
		Vector3(0, -0.05, corridor_z),
		COLOR_CORRIDOR, 0.8
	)

	# Ceiling (main bay)
	_create_static_surface(
		"BayCeiling",
		Vector3(BAY_WIDTH, 0.1, BAY_DEPTH),
		Vector3(0, CEILING_HEIGHT, 0),
		COLOR_CEILING, 0.9
	)

	# Ceiling (corridor)
	_create_static_surface(
		"CorridorCeiling",
		Vector3(CORRIDOR_WIDTH, 0.1, CORRIDOR_DEPTH),
		Vector3(0, CEILING_HEIGHT, corridor_z),
		COLOR_CEILING, 0.9
	)

	# Walls — main bay
	var half_w: float = BAY_WIDTH / 2.0
	var half_d: float = BAY_DEPTH / 2.0
	var wall_h: float = CEILING_HEIGHT
	var wall_y: float = wall_h / 2.0

	# West wall
	_create_static_surface("WallWest", Vector3(0.2, wall_h, BAY_DEPTH), Vector3(-half_w, wall_y, 0), COLOR_WALLS, 0.9)
	# East wall
	_create_static_surface("WallEast", Vector3(0.2, wall_h, BAY_DEPTH), Vector3(half_w, wall_y, 0), COLOR_WALLS, 0.9)
	# North wall
	_create_static_surface("WallNorth", Vector3(BAY_WIDTH, wall_h, 0.2), Vector3(0, wall_y, -half_d), COLOR_WALLS, 0.9)

	# South wall — two sections flanking the corridor opening
	var corridor_half_w: float = CORRIDOR_WIDTH / 2.0
	var south_section_width: float = (BAY_WIDTH - CORRIDOR_WIDTH) / 2.0
	var south_left_x: float = -half_w + south_section_width / 2.0
	var south_right_x: float = half_w - south_section_width / 2.0
	_create_static_surface("WallSouthLeft", Vector3(south_section_width, wall_h, 0.2), Vector3(south_left_x, wall_y, half_d), COLOR_WALLS, 0.9)
	_create_static_surface("WallSouthRight", Vector3(south_section_width, wall_h, 0.2), Vector3(south_right_x, wall_y, half_d), COLOR_WALLS, 0.9)

	# Corridor walls
	var corr_end_z: float = half_d + CORRIDOR_DEPTH
	_create_static_surface("CorridorWallWest", Vector3(0.2, wall_h, CORRIDOR_DEPTH), Vector3(-corridor_half_w, wall_y, corridor_z), COLOR_WALLS, 0.9)
	_create_static_surface("CorridorWallEast", Vector3(0.2, wall_h, CORRIDOR_DEPTH), Vector3(corridor_half_w, wall_y, corridor_z), COLOR_WALLS, 0.9)

	# Corridor back wall (the exit end) — solid wall with exit trigger area
	_create_static_surface("CorridorBack", Vector3(CORRIDOR_WIDTH, wall_h, 0.2), Vector3(0, wall_y, corr_end_z), COLOR_WALLS, 0.9)

func _build_module_zones() -> void:
	var zone_centers: Array[Vector3] = [ZONE_A_CENTER, ZONE_B_CENTER]
	for i: int in range(2):
		var center: Vector3 = zone_centers[i]

		# Floor marking (emissive teal overlay)
		var marker_mesh := MeshInstance3D.new()
		marker_mesh.name = "ZoneMarker_%d" % i
		var plane := PlaneMesh.new()
		plane.size = Vector2(ZONE_SIZE, ZONE_SIZE)
		marker_mesh.mesh = plane
		var marker_mat := StandardMaterial3D.new()
		marker_mat.albedo_color = COLOR_ZONE_TEAL
		marker_mat.emission_enabled = true
		marker_mat.emission = Color("#00D4AA")
		marker_mat.emission_energy_multiplier = 0.3
		marker_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		marker_mesh.material_override = marker_mat
		marker_mesh.position = Vector3(center.x, 0.01, center.z)
		add_child(marker_mesh)
		_zone_floor_markers.append(marker_mesh)

		# Interaction trigger area (slightly larger than zone for player detection)
		var zone_area := Area3D.new()
		zone_area.name = "PlacementZone_%d" % i
		zone_area.collision_layer = 0
		zone_area.collision_mask = LAYER_PLAYER
		var zone_col := CollisionShape3D.new()
		zone_col.name = "ZoneShape_%d" % i
		var zone_shape := BoxShape3D.new()
		zone_shape.size = Vector3(ZONE_SIZE + 1.0, 2.0, ZONE_SIZE + 1.0)
		zone_col.shape = zone_shape
		zone_col.position = Vector3(center.x, 1.0, center.z + ZONE_INTERACT_OFFSET)
		zone_area.add_child(zone_col)
		add_child(zone_area)
		_zone_areas.append(zone_area)

func _build_spawn_markers() -> void:
	# Interior entry point — just inside the corridor, facing north
	_enter_marker = Marker3D.new()
	_enter_marker.name = "EnterMarker"
	var corridor_z: float = BAY_DEPTH / 2.0 + CORRIDOR_DEPTH * 0.3
	_enter_marker.position = Vector3(0, 0.9, corridor_z)
	add_child(_enter_marker)

	# Exit trigger area — near the back of the corridor
	var exit_area := Area3D.new()
	exit_area.name = "ExitTrigger"
	exit_area.collision_layer = 0
	exit_area.collision_mask = LAYER_PLAYER
	var exit_col := CollisionShape3D.new()
	var exit_shape := BoxShape3D.new()
	exit_shape.size = Vector3(CORRIDOR_WIDTH, 2.0, 1.0)
	exit_col.shape = exit_shape
	var exit_z: float = BAY_DEPTH / 2.0 + CORRIDOR_DEPTH - 0.5
	exit_col.position = Vector3(0, 1.0, exit_z)
	exit_area.add_child(exit_col)
	add_child(exit_area)
	exit_area.body_entered.connect(_on_exit_zone_entered)
	exit_area.body_exited.connect(_on_exit_zone_exited)

	# Exterior marker — set by the test world after instancing
	_exterior_marker = Marker3D.new()
	_exterior_marker.name = "ExteriorMarker"
	_exterior_marker.position = Vector3(0, 0.9, 8)
	add_child(_exterior_marker)

func _build_lighting() -> void:
	var light := OmniLight3D.new()
	light.name = "InteriorLight"
	light.light_color = COLOR_LIGHT
	light.light_energy = 2.0
	light.omni_range = 15.0
	light.omni_attenuation = 0.5
	light.shadow_enabled = false
	light.position = Vector3(0, CEILING_HEIGHT - 0.3, 0)
	add_child(light)

	# Secondary light in corridor for even coverage
	var corridor_light := OmniLight3D.new()
	corridor_light.name = "CorridorLight"
	corridor_light.light_color = COLOR_LIGHT
	corridor_light.light_energy = 1.5
	corridor_light.omni_range = 6.0
	corridor_light.omni_attenuation = 0.5
	corridor_light.shadow_enabled = false
	var corridor_z: float = BAY_DEPTH / 2.0 + CORRIDOR_DEPTH / 2.0
	corridor_light.position = Vector3(0, CEILING_HEIGHT - 0.3, corridor_z)
	add_child(corridor_light)

func _build_fade_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "FadeLayer"
	_fade_layer.layer = 10
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)

func _create_static_surface(surface_name: String, size: Vector3, pos: Vector3, color: Color, roughness: float) -> void:
	var body := StaticBody3D.new()
	body.name = surface_name
	body.collision_layer = LAYER_ENVIRONMENT
	body.collision_mask = 0
	body.position = pos

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var col := CollisionShape3D.new()
	var col_shape := BoxShape3D.new()
	col_shape.size = size
	col.shape = col_shape
	body.add_child(col)

	add_child(body)

func _build_terminal() -> void:
	var half_d: float = BAY_DEPTH / 2.0
	# Greybox terminal mesh on the north wall
	var terminal_mesh := MeshInstance3D.new()
	terminal_mesh.name = "TerminalMesh"
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 1.5, 0.3)
	terminal_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#2A4A4A")
	mat.emission_enabled = true
	mat.emission = Color("#00D4AA")
	mat.emission_energy_multiplier = 0.4
	terminal_mesh.material_override = mat
	terminal_mesh.position = Vector3(0, 0.75, -half_d + 0.25)
	add_child(terminal_mesh)

	# Interaction area for terminal
	_terminal_area = Area3D.new()
	_terminal_area.name = "TerminalArea"
	_terminal_area.collision_layer = 0
	_terminal_area.collision_mask = LAYER_PLAYER
	var col := CollisionShape3D.new()
	col.name = "TerminalShape"
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 2.0, 1.5)
	col.shape = shape
	col.position = Vector3(0, 1.0, -half_d + 0.75)
	_terminal_area.add_child(col)
	add_child(_terminal_area)
	Global.log("ShipInterior: tech tree terminal built")

func _update_zone_visual(zone_index: int) -> void:
	if zone_index < 0 or zone_index >= _zone_floor_markers.size():
		return
	var marker: MeshInstance3D = _zone_floor_markers[zone_index]
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
		Global.log("ShipInterior: player in exit zone")

func _on_exit_zone_exited(body: Node3D) -> void:
	if body == _player_ref:
		_player_in_exit_zone = false
		Global.log("ShipInterior: player left exit zone")
