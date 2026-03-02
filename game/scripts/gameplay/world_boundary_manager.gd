## Manages invisible boundary walls around the biome play area and provides proximity
## warning detection for entities approaching the world edge. Reads boundary dimensions
## from BiomeArchetypeConfig so terrain and boundaries share one source of truth.
## Uses StaticBody3D + BoxShape3D walls at the four edges on the ENVIRONMENT collision layer.
## Owner: gameplay-programmer
class_name WorldBoundaryManager
extends Node3D


# ── Signals ──────────────────────────────────────────────

## Emitted when the tracked body enters the warning zone near a boundary edge.
## edge_direction is a normalized Vector3 pointing from the body toward the nearest wall.
signal boundary_warning_entered(edge_direction: Vector3)

## Emitted when the tracked body leaves all warning zones.
signal boundary_warning_exited


# ── Constants ─────────────────────────────────────────────

## Height of the invisible boundary walls in metres.
const WALL_HEIGHT: float = 100.0

## Thickness of the boundary walls in metres.
const WALL_THICKNESS: float = 2.0

## Distance from the boundary edge at which warnings begin, in metres.
const WARNING_DISTANCE: float = 20.0


# ── Private Variables ─────────────────────────────────────

## Side length of the biome play area, read from BiomeArchetypeConfig.
var _terrain_size: float = 500.0

## Whether the tracked body is currently inside any warning zone.
var _is_in_warning_zone: bool = false

## The body being monitored for boundary proximity warnings.
var _tracked_body: Node3D = null

## References to the four boundary wall StaticBody3D nodes.
var _north_wall: StaticBody3D = null
var _south_wall: StaticBody3D = null
var _west_wall: StaticBody3D = null
var _east_wall: StaticBody3D = null


# ── Public Methods ────────────────────────────────────────

## Initializes the boundary system from a biome archetype config. Creates four invisible
## walls around the play area and prepares proximity warning detection.
func initialize(archetype: BiomeArchetypeConfig) -> void:
	_terrain_size = archetype.terrain_size
	_create_boundary_walls()
	Global.debug_log("WorldBoundaryManager: initialized with terrain_size=%.0f" % _terrain_size)


## Sets the body to track for proximity warnings. Typically the player character.
func set_tracked_body(body: Node3D) -> void:
	_tracked_body = body
	Global.debug_log("WorldBoundaryManager: tracking body '%s'" % body.name)


## Returns the terrain size this boundary enforces.
func get_terrain_size() -> float:
	return _terrain_size


## Checks if a given world position is within the warning zone near any boundary edge.
func is_in_warning_zone(world_position: Vector3) -> bool:
	if world_position.x < WARNING_DISTANCE:
		return true
	if world_position.x > _terrain_size - WARNING_DISTANCE:
		return true
	if world_position.z < WARNING_DISTANCE:
		return true
	if world_position.z > _terrain_size - WARNING_DISTANCE:
		return true
	return false


## Returns a normalized direction vector pointing from the given position toward the
## closest boundary edge. Returns Vector3.ZERO if not in a warning zone.
func get_closest_edge_direction(world_position: Vector3) -> Vector3:
	var closest_direction: Vector3 = Vector3.ZERO
	var closest_distance: float = WARNING_DISTANCE

	# Check west wall (x = 0)
	if world_position.x < closest_distance:
		closest_distance = world_position.x
		closest_direction = Vector3.LEFT

	# Check east wall (x = terrain_size)
	var east_distance: float = _terrain_size - world_position.x
	if east_distance < closest_distance:
		closest_distance = east_distance
		closest_direction = Vector3.RIGHT

	# Check north wall (z = 0)
	if world_position.z < closest_distance:
		closest_distance = world_position.z
		closest_direction = Vector3.FORWARD

	# Check south wall (z = terrain_size)
	var south_distance: float = _terrain_size - world_position.z
	if south_distance < closest_distance:
		closest_distance = south_distance
		closest_direction = Vector3.BACK

	return closest_direction


## Returns the shortest distance from a world position to any boundary edge.
func get_distance_to_boundary(world_position: Vector3) -> float:
	var west_distance: float = world_position.x
	var east_distance: float = _terrain_size - world_position.x
	var north_distance: float = world_position.z
	var south_distance: float = _terrain_size - world_position.z
	return minf(minf(west_distance, east_distance), minf(north_distance, south_distance))


# ── Built-in Virtual Methods ──────────────────────────────

func _physics_process(_delta: float) -> void:
	if _tracked_body == null:
		return

	var body_position: Vector3 = _tracked_body.global_position
	var in_warning: bool = is_in_warning_zone(body_position)

	if in_warning and not _is_in_warning_zone:
		_is_in_warning_zone = true
		var edge_direction: Vector3 = get_closest_edge_direction(body_position)
		boundary_warning_entered.emit(edge_direction)
		Global.debug_log("WorldBoundaryManager: warning zone entered, edge=%s" % str(edge_direction))
	elif not in_warning and _is_in_warning_zone:
		_is_in_warning_zone = false
		boundary_warning_exited.emit()
		Global.debug_log("WorldBoundaryManager: warning zone exited")


# ── Private Methods ───────────────────────────────────────

## Creates the four invisible boundary walls as StaticBody3D + BoxShape3D children.
func _create_boundary_walls() -> void:
	var half_size: float = _terrain_size * 0.5
	var half_height: float = WALL_HEIGHT * 0.5
	var half_thickness: float = WALL_THICKNESS * 0.5

	# North wall — along z = 0
	_north_wall = _create_wall(
		"NorthWall",
		Vector3(half_size, half_height, -half_thickness),
		Vector3(_terrain_size, WALL_HEIGHT, WALL_THICKNESS)
	)

	# South wall — along z = terrain_size
	_south_wall = _create_wall(
		"SouthWall",
		Vector3(half_size, half_height, _terrain_size + half_thickness),
		Vector3(_terrain_size, WALL_HEIGHT, WALL_THICKNESS)
	)

	# West wall — along x = 0
	_west_wall = _create_wall(
		"WestWall",
		Vector3(-half_thickness, half_height, half_size),
		Vector3(WALL_THICKNESS, WALL_HEIGHT, _terrain_size)
	)

	# East wall — along x = terrain_size
	_east_wall = _create_wall(
		"EastWall",
		Vector3(_terrain_size + half_thickness, half_height, half_size),
		Vector3(WALL_THICKNESS, WALL_HEIGHT, _terrain_size)
	)


## Creates a single boundary wall with the given name, position, and box dimensions.
func _create_wall(wall_name: String, wall_position: Vector3, box_size: Vector3) -> StaticBody3D:
	var wall: StaticBody3D = StaticBody3D.new()
	wall.name = wall_name
	wall.position = wall_position
	wall.collision_layer = PhysicsLayers.ENVIRONMENT
	wall.collision_mask = 0

	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "CollisionShape3D"

	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape

	wall.add_child(collision)
	add_child(wall)

	return wall
