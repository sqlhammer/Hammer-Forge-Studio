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
const COLOR_FLOOR := Color("#4A4A4A")
const COLOR_WALLS_MACHINE := Color("#333333")
const COLOR_WALLS_COCKPIT := Color("#2A2A2A")
const COLOR_CEILING := Color("#2A2A2A")
const COLOR_CORRIDOR := Color("#555555")
const COLOR_VESTIBULE := Color("#555555")
const COLOR_ZONE_TEAL := Color("#00D4AA", 0.3)
const COLOR_ZONE_TEAL_OCCUPIED := Color("#00D4AA", 0.15)
const COLOR_VIEWPORT_FRAME := Color("#333333")
const COLOR_LIGHT := Color("#E0E0E0")

## Physics layers
const LAYER_PLAYER: int = 1 << 0
const LAYER_ENVIRONMENT: int = 1 << 2
const LAYER_INTERACTABLE: int = 1 << 3

## Fade transition
const FADE_DURATION: float = 0.3

# ── Private Variables ─────────────────────────────────────
var _enter_marker: Marker3D = null
var _exterior_marker: Marker3D = null
var _zone_areas: Array[Area3D] = []
var _zone_floor_markers: Array[MeshInstance3D] = []
var _zone_occupied: Array[bool] = [false, false, false, false]
var _zone_module_nodes: Array[Node3D] = [null, null, null, null]
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
	_build_cockpit_features()
	_build_lighting()
	_build_fade_overlay()
	_build_terminal()
	Global.log("ShipInterior: initialized — 24m×12m multi-room layout")

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
	var zone_centers: Array[Vector3] = [ZONE_A_CENTER, ZONE_B_CENTER, ZONE_C_CENTER, ZONE_D_CENTER]
	module_mesh.position = zone_centers[zone_index]
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

## Returns true if the player is near the tech tree terminal.
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
	_build_floors()
	_build_ceilings()
	_build_machine_room_walls()
	_build_cockpit_walls()
	_build_corridor_walls()
	_build_vestibule_walls()
	_build_viewport_frame()

func _build_floors() -> void:
	# Machine room: 12m × 12m, center at Z=+2 (Z range: -4 to +8)
	_create_static_surface("MachineRoomFloor",
		Vector3(12.0, 0.1, 12.0), Vector3(0.0, -0.05, 2.0), COLOR_FLOOR, 0.8)
	# Cockpit: 12m × 6m, center at Z=-9 (Z range: -12 to -6)
	_create_static_surface("CockpitFloor",
		Vector3(12.0, 0.1, 6.0), Vector3(0.0, -0.05, -9.0), COLOR_FLOOR, 0.8)
	# Corridor: 4m × 2m, center at Z=-5 (Z range: -6 to -4)
	_create_static_surface("CorridorFloor",
		Vector3(4.0, 0.1, 2.0), Vector3(0.0, -0.05, -5.0), COLOR_CORRIDOR, 0.8)
	# Vestibule: 4m × 4m, center at Z=+10 (Z range: +8 to +12)
	_create_static_surface("VestibuleFloor",
		Vector3(4.0, 0.1, 4.0), Vector3(0.0, -0.05, 10.0), COLOR_VESTIBULE, 0.8)

func _build_ceilings() -> void:
	_create_static_surface("MachineRoomCeiling",
		Vector3(12.0, 0.1, 12.0), Vector3(0.0, 3.0, 2.0), COLOR_CEILING, 0.9)
	_create_static_surface("CockpitCeiling",
		Vector3(12.0, 0.1, 6.0), Vector3(0.0, 3.0, -9.0), COLOR_CEILING, 0.9)
	_create_static_surface("CorridorCeiling",
		Vector3(4.0, 0.1, 2.0), Vector3(0.0, 3.0, -5.0), COLOR_CEILING, 0.9)
	_create_static_surface("VestibuleCeiling",
		Vector3(4.0, 0.1, 4.0), Vector3(0.0, 3.0, 10.0), COLOR_CEILING, 0.9)

func _build_machine_room_walls() -> void:
	var wall_y: float = CEILING_HEIGHT / 2.0
	# West wall: X=-6, Z:-4 to +8
	_create_static_surface("MachineRoomWallWest",
		Vector3(0.2, 3.0, 12.0), Vector3(-6.0, wall_y, 2.0), COLOR_WALLS_MACHINE, 0.9)
	# East wall: X=+6, Z:-4 to +8
	_create_static_surface("MachineRoomWallEast",
		Vector3(0.2, 3.0, 12.0), Vector3(6.0, wall_y, 2.0), COLOR_WALLS_MACHINE, 0.9)
	# North wall left section: X:-6 to -2 at Z=-4 (corridor opening X:-2 to +2)
	_create_static_surface("MachineRoomWallNorthLeft",
		Vector3(4.0, 3.0, 0.2), Vector3(-4.0, wall_y, -4.0), COLOR_WALLS_MACHINE, 0.9)
	# North wall right section: X:+2 to +6 at Z=-4
	_create_static_surface("MachineRoomWallNorthRight",
		Vector3(4.0, 3.0, 0.2), Vector3(4.0, wall_y, -4.0), COLOR_WALLS_MACHINE, 0.9)
	# South wall left section: X:-6 to -2 at Z=+8 (vestibule opening X:-2 to +2)
	_create_static_surface("MachineRoomWallSouthLeft",
		Vector3(4.0, 3.0, 0.2), Vector3(-4.0, wall_y, 8.0), COLOR_WALLS_MACHINE, 0.9)
	# South wall right section: X:+2 to +6 at Z=+8
	_create_static_surface("MachineRoomWallSouthRight",
		Vector3(4.0, 3.0, 0.2), Vector3(4.0, wall_y, 8.0), COLOR_WALLS_MACHINE, 0.9)

func _build_cockpit_walls() -> void:
	var wall_y: float = CEILING_HEIGHT / 2.0
	# West wall: X=-6, Z:-12 to -6
	_create_static_surface("CockpitWallWest",
		Vector3(0.2, 3.0, 6.0), Vector3(-6.0, wall_y, -9.0), COLOR_WALLS_COCKPIT, 0.9)
	# East wall: X=+6, Z:-12 to -6
	_create_static_surface("CockpitWallEast",
		Vector3(0.2, 3.0, 6.0), Vector3(6.0, wall_y, -9.0), COLOR_WALLS_COCKPIT, 0.9)
	# North wall left section: X:-6 to -2 at Z=-12 (viewport opening X:-2 to +2, Y:1.5 to 3.0)
	_create_static_surface("CockpitWallNorthLeft",
		Vector3(4.0, 3.0, 0.2), Vector3(-4.0, wall_y, -12.0), COLOR_WALLS_COCKPIT, 0.9)
	# North wall right section: X:+2 to +6 at Z=-12
	_create_static_surface("CockpitWallNorthRight",
		Vector3(4.0, 3.0, 0.2), Vector3(4.0, wall_y, -12.0), COLOR_WALLS_COCKPIT, 0.9)
	# North wall below viewport: X:-2 to +2, Y:0 to 1.5 at Z=-12
	_create_static_surface("CockpitWallNorthBelow",
		Vector3(4.0, 1.5, 0.2), Vector3(0.0, 0.75, -12.0), COLOR_WALLS_COCKPIT, 0.9)
	# South wall left section: X:-6 to -2 at Z=-6 (corridor opening X:-2 to +2)
	_create_static_surface("CockpitWallSouthLeft",
		Vector3(4.0, 3.0, 0.2), Vector3(-4.0, wall_y, -6.0), COLOR_WALLS_COCKPIT, 0.9)
	# South wall right section: X:+2 to +6 at Z=-6
	_create_static_surface("CockpitWallSouthRight",
		Vector3(4.0, 3.0, 0.2), Vector3(4.0, wall_y, -6.0), COLOR_WALLS_COCKPIT, 0.9)

func _build_corridor_walls() -> void:
	var wall_y: float = CEILING_HEIGHT / 2.0
	# West wall: X=-2, Z:-6 to -4
	_create_static_surface("CorridorWallWest",
		Vector3(0.2, 3.0, 2.0), Vector3(-2.0, wall_y, -5.0), COLOR_CORRIDOR, 0.9)
	# East wall: X=+2, Z:-6 to -4
	_create_static_surface("CorridorWallEast",
		Vector3(0.2, 3.0, 2.0), Vector3(2.0, wall_y, -5.0), COLOR_CORRIDOR, 0.9)
	# Solid fill walls flanking the corridor (seal gaps between machine room and cockpit)
	# West fill: X:-6 to -2, Z:-6 to -4
	_create_static_surface("CorridorFillWest",
		Vector3(4.0, 3.0, 2.0), Vector3(-4.0, wall_y, -5.0), COLOR_WALLS_MACHINE, 0.9)
	# East fill: X:+2 to +6, Z:-6 to -4
	_create_static_surface("CorridorFillEast",
		Vector3(4.0, 3.0, 2.0), Vector3(4.0, wall_y, -5.0), COLOR_WALLS_MACHINE, 0.9)

func _build_vestibule_walls() -> void:
	var wall_y: float = CEILING_HEIGHT / 2.0
	# West wall: X=-2, Z:+8 to +12
	_create_static_surface("VestibuleWallWest",
		Vector3(0.2, 3.0, 4.0), Vector3(-2.0, wall_y, 10.0), COLOR_VESTIBULE, 0.9)
	# East wall: X=+2, Z:+8 to +12
	_create_static_surface("VestibuleWallEast",
		Vector3(0.2, 3.0, 4.0), Vector3(2.0, wall_y, 10.0), COLOR_VESTIBULE, 0.9)
	# South wall (back): X:-2 to +2 at Z=+12
	_create_static_surface("VestibuleWallSouth",
		Vector3(4.0, 3.0, 0.2), Vector3(0.0, wall_y, 12.0), COLOR_VESTIBULE, 0.9)

func _build_viewport_frame() -> void:
	# Thin frame around cockpit viewport opening (X:-2 to +2, Y:1.5 to 3.0, Z=-12)
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = COLOR_VIEWPORT_FRAME
	frame_mat.roughness = 0.9

	# Bottom edge
	var bottom_frame := MeshInstance3D.new()
	bottom_frame.name = "ViewportFrameBottom"
	var bottom_mesh := BoxMesh.new()
	bottom_mesh.size = Vector3(4.2, 0.1, 0.1)
	bottom_frame.mesh = bottom_mesh
	bottom_frame.material_override = frame_mat
	bottom_frame.position = Vector3(0.0, 1.5, -11.95)
	add_child(bottom_frame)

	# Left edge
	var left_frame := MeshInstance3D.new()
	left_frame.name = "ViewportFrameLeft"
	var left_mesh := BoxMesh.new()
	left_mesh.size = Vector3(0.1, 1.5, 0.1)
	left_frame.mesh = left_mesh
	left_frame.material_override = frame_mat
	left_frame.position = Vector3(-2.0, 2.25, -11.95)
	add_child(left_frame)

	# Right edge
	var right_frame := MeshInstance3D.new()
	right_frame.name = "ViewportFrameRight"
	var right_mesh := BoxMesh.new()
	right_mesh.size = Vector3(0.1, 1.5, 0.1)
	right_frame.mesh = right_mesh
	right_frame.material_override = frame_mat
	right_frame.position = Vector3(2.0, 2.25, -11.95)
	add_child(right_frame)

func _build_module_zones() -> void:
	var zone_centers: Array[Vector3] = [ZONE_A_CENTER, ZONE_B_CENTER, ZONE_C_CENTER, ZONE_D_CENTER]
	for i: int in range(ZONE_COUNT):
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
	# Interior entry point — inside vestibule, facing north (per wireframe: X=0, Y=0, Z=+10)
	_enter_marker = Marker3D.new()
	_enter_marker.name = "InteriorSpawn"
	_enter_marker.position = Vector3(0.0, 0.0, 10.0)
	add_child(_enter_marker)

	# Exit trigger area — near the back of the vestibule (Z ≈ +11.5)
	var exit_area := Area3D.new()
	exit_area.name = "ExitTrigger"
	exit_area.collision_layer = 0
	exit_area.collision_mask = LAYER_PLAYER
	var exit_col := CollisionShape3D.new()
	var exit_shape := BoxShape3D.new()
	exit_shape.size = Vector3(VESTIBULE_WIDTH, 2.0, 1.0)
	exit_col.shape = exit_shape
	exit_col.position = Vector3(0.0, 1.0, 11.5)
	exit_area.add_child(exit_col)
	add_child(exit_area)
	exit_area.body_entered.connect(_on_exit_zone_entered)
	exit_area.body_exited.connect(_on_exit_zone_exited)

	# Exterior marker — default position, set by test world after instancing
	_exterior_marker = Marker3D.new()
	_exterior_marker.name = "ExteriorSpawn"
	_exterior_marker.position = Vector3(0.0, 0.0, 14.0)
	add_child(_exterior_marker)

func _build_cockpit_features() -> void:
	# Marker3D placeholder for TICKET-0127 (Status Display Area)
	var status_marker := Marker3D.new()
	status_marker.name = "StatusDisplayArea"
	status_marker.position = Vector3(0.0, 1.5, -9.0)
	add_child(status_marker)

	# Marker3D placeholder for TICKET-0128 (Viewport Area)
	var viewport_marker := Marker3D.new()
	viewport_marker.name = "ViewportArea"
	viewport_marker.position = Vector3(0.0, 2.25, -12.0)
	add_child(viewport_marker)

func _build_lighting() -> void:
	# Machine room light — centered overhead at Y=2.8
	var machine_light := OmniLight3D.new()
	machine_light.name = "MachineRoomLight"
	machine_light.light_color = COLOR_LIGHT
	machine_light.light_energy = 2.0
	machine_light.omni_range = 15.0
	machine_light.omni_attenuation = 0.5
	machine_light.shadow_enabled = false
	machine_light.position = Vector3(0.0, 2.8, 2.0)
	add_child(machine_light)

	# Cockpit light — centered overhead
	var cockpit_light := OmniLight3D.new()
	cockpit_light.name = "CockpitLight"
	cockpit_light.light_color = COLOR_LIGHT
	cockpit_light.light_energy = 2.0
	cockpit_light.omni_range = 12.0
	cockpit_light.omni_attenuation = 0.5
	cockpit_light.shadow_enabled = false
	cockpit_light.position = Vector3(0.0, 2.8, -9.0)
	add_child(cockpit_light)

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

func _build_terminal() -> void:
	# Tech tree terminal on machine room north wall (left of corridor opening)
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
	terminal_mesh.position = Vector3(-4.0, 0.75, -3.8)
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
	col.position = Vector3(-4.0, 1.0, -3.0)
	_terminal_area.add_child(col)
	add_child(_terminal_area)
	Global.log("ShipInterior: tech tree terminal built")

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
