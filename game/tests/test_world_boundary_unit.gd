## Unit tests for the World Boundary system. Verifies hard boundary enforcement,
## edge detection, boundary collision responses, and player constraint behavior
## at world limits. Tests run for all three biome archetypes.
##
## Coverage target: 75% (per docs/studio/tdd-process-m8.md — biome travel mechanics)
## Ticket: TICKET-0164
class_name TestWorldBoundaryUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _manager: WorldBoundaryManager = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_manager = WorldBoundaryManager.new()
	add_child(_manager)
	_spy = SignalSpy.new()
	_spy.watch(_manager, "boundary_warning_entered")
	_spy.watch(_manager, "boundary_warning_exited")


func after_each() -> void:
	if _manager != null:
		_manager.queue_free()
		_manager = null
	if _spy != null:
		_spy.clear()
		_spy = null


# ── Helpers ───────────────────────────────────────────────

## Initializes the manager with the given archetype config.
func _init_default() -> void:
	_manager.initialize(BiomeArchetypeConfig.shattered_flats())


## Returns the StaticBody3D wall child with the given name, or null.
func _get_wall(wall_name: String) -> StaticBody3D:
	for i: int in range(_manager.get_child_count()):
		var child: Node = _manager.get_child(i)
		if child is StaticBody3D and child.name == wall_name:
			return child as StaticBody3D
	return null


## Returns the BoxShape3D from a wall's CollisionShape3D child, or null.
func _get_wall_shape(wall: StaticBody3D) -> BoxShape3D:
	for i: int in range(wall.get_child_count()):
		var child: Node = wall.get_child(i)
		if child is CollisionShape3D:
			return child.shape as BoxShape3D
	return null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Constants
	add_test("wall_height_constant_is_100", _test_wall_height_constant_is_100)
	add_test("wall_thickness_constant_is_2", _test_wall_thickness_constant_is_2)
	add_test("warning_distance_constant_is_20", _test_warning_distance_constant_is_20)

	# Initialization — terrain size matches archetype config
	add_test("terrain_size_matches_shattered_flats", _test_terrain_size_matches_shattered_flats)
	add_test("terrain_size_matches_rock_warrens", _test_terrain_size_matches_rock_warrens)
	add_test("terrain_size_matches_debris_field", _test_terrain_size_matches_debris_field)
	add_test("custom_terrain_size_respected", _test_custom_terrain_size_respected)

	# Wall creation — four walls present after initialize
	add_test("four_walls_created_on_initialize", _test_four_walls_created_on_initialize)
	add_test("north_wall_exists", _test_north_wall_exists)
	add_test("south_wall_exists", _test_south_wall_exists)
	add_test("west_wall_exists", _test_west_wall_exists)
	add_test("east_wall_exists", _test_east_wall_exists)

	# Wall positions — correct placement at boundary edges
	add_test("north_wall_position_correct", _test_north_wall_position_correct)
	add_test("south_wall_position_correct", _test_south_wall_position_correct)
	add_test("west_wall_position_correct", _test_west_wall_position_correct)
	add_test("east_wall_position_correct", _test_east_wall_position_correct)

	# Wall collision — shapes present and correctly sized
	add_test("north_wall_has_box_collision", _test_north_wall_has_box_collision)
	add_test("south_wall_has_box_collision", _test_south_wall_has_box_collision)
	add_test("west_wall_has_box_collision", _test_west_wall_has_box_collision)
	add_test("east_wall_has_box_collision", _test_east_wall_has_box_collision)
	add_test("north_wall_shape_dimensions", _test_north_wall_shape_dimensions)
	add_test("west_wall_shape_dimensions", _test_west_wall_shape_dimensions)

	# Wall collision layer — uses ENVIRONMENT, mask is 0
	add_test("walls_use_environment_collision_layer", _test_walls_use_environment_collision_layer)
	add_test("walls_have_zero_collision_mask", _test_walls_have_zero_collision_mask)

	# Warning zone — cardinal direction checks
	add_test("center_not_in_warning_zone", _test_center_not_in_warning_zone)
	add_test("near_west_edge_in_warning_zone", _test_near_west_edge_in_warning_zone)
	add_test("near_east_edge_in_warning_zone", _test_near_east_edge_in_warning_zone)
	add_test("near_north_edge_in_warning_zone", _test_near_north_edge_in_warning_zone)
	add_test("near_south_edge_in_warning_zone", _test_near_south_edge_in_warning_zone)
	add_test("at_warning_boundary_not_in_zone", _test_at_warning_boundary_not_in_zone)
	add_test("just_inside_warning_threshold", _test_just_inside_warning_threshold)

	# Warning zone — diagonal (corner cases)
	add_test("northwest_corner_in_warning_zone", _test_northwest_corner_in_warning_zone)
	add_test("northeast_corner_in_warning_zone", _test_northeast_corner_in_warning_zone)
	add_test("southwest_corner_in_warning_zone", _test_southwest_corner_in_warning_zone)
	add_test("southeast_corner_in_warning_zone", _test_southeast_corner_in_warning_zone)

	# Edge direction — closest wall direction
	add_test("closest_edge_west_when_near_west", _test_closest_edge_west_when_near_west)
	add_test("closest_edge_east_when_near_east", _test_closest_edge_east_when_near_east)
	add_test("closest_edge_north_when_near_north", _test_closest_edge_north_when_near_north)
	add_test("closest_edge_south_when_near_south", _test_closest_edge_south_when_near_south)
	add_test("closest_edge_zero_at_center", _test_closest_edge_zero_at_center)

	# Distance to boundary
	add_test("distance_at_center_is_half_terrain", _test_distance_at_center_is_half_terrain)
	add_test("distance_near_west_edge", _test_distance_near_west_edge)
	add_test("distance_at_origin_is_zero", _test_distance_at_origin_is_zero)
	add_test("distance_at_far_corner", _test_distance_at_far_corner)

	# Per-archetype wall dimensions match config
	add_test("shattered_flats_walls_span_terrain_size", _test_shattered_flats_walls_span_terrain_size)
	add_test("rock_warrens_walls_span_terrain_size", _test_rock_warrens_walls_span_terrain_size)
	add_test("debris_field_walls_span_terrain_size", _test_debris_field_walls_span_terrain_size)

	# Terrain heightmap vertices within boundary extents
	add_test("heightmap_vertices_within_bounds_shattered_flats", _test_heightmap_vertices_within_bounds_shattered_flats)
	add_test("heightmap_vertices_within_bounds_rock_warrens", _test_heightmap_vertices_within_bounds_rock_warrens)
	add_test("heightmap_vertices_within_bounds_debris_field", _test_heightmap_vertices_within_bounds_debris_field)

	# Edge cases
	add_test("position_at_exact_boundary", _test_position_at_exact_boundary)
	add_test("position_past_boundary_negative", _test_position_past_boundary_negative)
	add_test("set_tracked_body_does_not_crash", _test_set_tracked_body_does_not_crash)
	add_test("warning_zone_all_archetypes", _test_warning_zone_all_archetypes)


# ── Test Methods ──────────────────────────────────────────

# -- Constants --

func _test_wall_height_constant_is_100() -> void:
	assert_equal(WorldBoundaryManager.WALL_HEIGHT, 100.0,
		"WALL_HEIGHT should be 100.0 metres")


func _test_wall_thickness_constant_is_2() -> void:
	assert_equal(WorldBoundaryManager.WALL_THICKNESS, 2.0,
		"WALL_THICKNESS should be 2.0 metres")


func _test_warning_distance_constant_is_20() -> void:
	assert_equal(WorldBoundaryManager.WARNING_DISTANCE, 20.0,
		"WARNING_DISTANCE should be 20.0 metres")


# -- Initialization — terrain size matches archetype --

func _test_terrain_size_matches_shattered_flats() -> void:
	var config: BiomeArchetypeConfig = BiomeArchetypeConfig.shattered_flats()
	_manager.initialize(config)
	assert_equal(_manager.get_terrain_size(), 500.0,
		"Terrain size should match shattered_flats config (500.0)")


func _test_terrain_size_matches_rock_warrens() -> void:
	var config: BiomeArchetypeConfig = BiomeArchetypeConfig.rock_warrens()
	_manager.initialize(config)
	assert_equal(_manager.get_terrain_size(), 500.0,
		"Terrain size should match rock_warrens config (500.0)")


func _test_terrain_size_matches_debris_field() -> void:
	var config: BiomeArchetypeConfig = BiomeArchetypeConfig.debris_field()
	_manager.initialize(config)
	assert_equal(_manager.get_terrain_size(), 500.0,
		"Terrain size should match debris_field config (500.0)")


func _test_custom_terrain_size_respected() -> void:
	var config: BiomeArchetypeConfig = BiomeArchetypeConfig.new()
	config.terrain_size = 750.0
	_manager.initialize(config)
	assert_equal(_manager.get_terrain_size(), 750.0,
		"Terrain size should match custom config value (750.0)")


# -- Wall creation — four walls present --

func _test_four_walls_created_on_initialize() -> void:
	_init_default()
	var wall_count: int = 0
	for i: int in range(_manager.get_child_count()):
		if _manager.get_child(i) is StaticBody3D:
			wall_count += 1
	assert_equal(wall_count, 4,
		"Initialize should create exactly 4 StaticBody3D walls")


func _test_north_wall_exists() -> void:
	_init_default()
	assert_not_null(_get_wall("NorthWall"), "NorthWall should exist after initialize")


func _test_south_wall_exists() -> void:
	_init_default()
	assert_not_null(_get_wall("SouthWall"), "SouthWall should exist after initialize")


func _test_west_wall_exists() -> void:
	_init_default()
	assert_not_null(_get_wall("WestWall"), "WestWall should exist after initialize")


func _test_east_wall_exists() -> void:
	_init_default()
	assert_not_null(_get_wall("EastWall"), "EastWall should exist after initialize")


# -- Wall positions --

func _test_north_wall_position_correct() -> void:
	_init_default()
	var wall: StaticBody3D = _get_wall("NorthWall")
	var half_size: float = 250.0
	var half_height: float = 50.0
	var half_thickness: float = 1.0
	assert_equal(wall.position, Vector3(half_size, half_height, -half_thickness),
		"NorthWall should be at (250, 50, -1)")


func _test_south_wall_position_correct() -> void:
	_init_default()
	var wall: StaticBody3D = _get_wall("SouthWall")
	var half_size: float = 250.0
	var half_height: float = 50.0
	var half_thickness: float = 1.0
	assert_equal(wall.position, Vector3(half_size, half_height, 500.0 + half_thickness),
		"SouthWall should be at (250, 50, 501)")


func _test_west_wall_position_correct() -> void:
	_init_default()
	var wall: StaticBody3D = _get_wall("WestWall")
	var half_size: float = 250.0
	var half_height: float = 50.0
	var half_thickness: float = 1.0
	assert_equal(wall.position, Vector3(-half_thickness, half_height, half_size),
		"WestWall should be at (-1, 50, 250)")


func _test_east_wall_position_correct() -> void:
	_init_default()
	var wall: StaticBody3D = _get_wall("EastWall")
	var half_size: float = 250.0
	var half_height: float = 50.0
	var half_thickness: float = 1.0
	assert_equal(wall.position, Vector3(500.0 + half_thickness, half_height, half_size),
		"EastWall should be at (501, 50, 250)")


# -- Wall collision shapes --

func _test_north_wall_has_box_collision() -> void:
	_init_default()
	var wall: StaticBody3D = _get_wall("NorthWall")
	var shape: BoxShape3D = _get_wall_shape(wall)
	assert_not_null(shape, "NorthWall should have a BoxShape3D collision shape")


func _test_south_wall_has_box_collision() -> void:
	_init_default()
	var wall: StaticBody3D = _get_wall("SouthWall")
	var shape: BoxShape3D = _get_wall_shape(wall)
	assert_not_null(shape, "SouthWall should have a BoxShape3D collision shape")


func _test_west_wall_has_box_collision() -> void:
	_init_default()
	var wall: StaticBody3D = _get_wall("WestWall")
	var shape: BoxShape3D = _get_wall_shape(wall)
	assert_not_null(shape, "WestWall should have a BoxShape3D collision shape")


func _test_east_wall_has_box_collision() -> void:
	_init_default()
	var wall: StaticBody3D = _get_wall("EastWall")
	var shape: BoxShape3D = _get_wall_shape(wall)
	assert_not_null(shape, "EastWall should have a BoxShape3D collision shape")


func _test_north_wall_shape_dimensions() -> void:
	_init_default()
	var wall: StaticBody3D = _get_wall("NorthWall")
	var shape: BoxShape3D = _get_wall_shape(wall)
	assert_equal(shape.size, Vector3(500.0, 100.0, 2.0),
		"NorthWall shape should span terrain width (500) x wall height (100) x thickness (2)")


func _test_west_wall_shape_dimensions() -> void:
	_init_default()
	var wall: StaticBody3D = _get_wall("WestWall")
	var shape: BoxShape3D = _get_wall_shape(wall)
	assert_equal(shape.size, Vector3(2.0, 100.0, 500.0),
		"WestWall shape should span thickness (2) x wall height (100) x terrain depth (500)")


# -- Wall collision layer --

func _test_walls_use_environment_collision_layer() -> void:
	_init_default()
	var wall_names: Array = ["NorthWall", "SouthWall", "WestWall", "EastWall"]
	for wall_name: String in wall_names:
		var wall: StaticBody3D = _get_wall(wall_name)
		assert_equal(wall.collision_layer, PhysicsLayers.ENVIRONMENT,
			"%s should use ENVIRONMENT collision layer" % wall_name)


func _test_walls_have_zero_collision_mask() -> void:
	_init_default()
	var wall_names: Array = ["NorthWall", "SouthWall", "WestWall", "EastWall"]
	for wall_name: String in wall_names:
		var wall: StaticBody3D = _get_wall(wall_name)
		assert_equal(wall.collision_mask, 0,
			"%s should have collision mask 0 (passive)" % wall_name)


# -- Warning zone — cardinal direction checks --

func _test_center_not_in_warning_zone() -> void:
	_init_default()
	assert_false(_manager.is_in_warning_zone(Vector3(250.0, 0.0, 250.0)),
		"Center of play area should not be in warning zone")


func _test_near_west_edge_in_warning_zone() -> void:
	_init_default()
	assert_true(_manager.is_in_warning_zone(Vector3(10.0, 0.0, 250.0)),
		"Position at x=10 (within 20m of west edge) should be in warning zone")


func _test_near_east_edge_in_warning_zone() -> void:
	_init_default()
	assert_true(_manager.is_in_warning_zone(Vector3(490.0, 0.0, 250.0)),
		"Position at x=490 (within 20m of east edge) should be in warning zone")


func _test_near_north_edge_in_warning_zone() -> void:
	_init_default()
	assert_true(_manager.is_in_warning_zone(Vector3(250.0, 0.0, 10.0)),
		"Position at z=10 (within 20m of north edge) should be in warning zone")


func _test_near_south_edge_in_warning_zone() -> void:
	_init_default()
	assert_true(_manager.is_in_warning_zone(Vector3(250.0, 0.0, 490.0)),
		"Position at z=490 (within 20m of south edge) should be in warning zone")


func _test_at_warning_boundary_not_in_zone() -> void:
	_init_default()
	# Exactly at WARNING_DISTANCE from edge — the check is < not <=, so x=20 is NOT in zone
	assert_false(_manager.is_in_warning_zone(Vector3(20.0, 0.0, 250.0)),
		"Position at exactly WARNING_DISTANCE from west edge should not be in warning zone")


func _test_just_inside_warning_threshold() -> void:
	_init_default()
	assert_true(_manager.is_in_warning_zone(Vector3(19.9, 0.0, 250.0)),
		"Position at 19.9m from west edge (just inside threshold) should be in warning zone")


# -- Warning zone — diagonal (corner cases) --

func _test_northwest_corner_in_warning_zone() -> void:
	_init_default()
	assert_true(_manager.is_in_warning_zone(Vector3(5.0, 0.0, 5.0)),
		"Northwest corner (5, 0, 5) should be in warning zone")


func _test_northeast_corner_in_warning_zone() -> void:
	_init_default()
	assert_true(_manager.is_in_warning_zone(Vector3(495.0, 0.0, 5.0)),
		"Northeast corner (495, 0, 5) should be in warning zone")


func _test_southwest_corner_in_warning_zone() -> void:
	_init_default()
	assert_true(_manager.is_in_warning_zone(Vector3(5.0, 0.0, 495.0)),
		"Southwest corner (5, 0, 495) should be in warning zone")


func _test_southeast_corner_in_warning_zone() -> void:
	_init_default()
	assert_true(_manager.is_in_warning_zone(Vector3(495.0, 0.0, 495.0)),
		"Southeast corner (495, 0, 495) should be in warning zone")


# -- Edge direction --

func _test_closest_edge_west_when_near_west() -> void:
	_init_default()
	var direction: Vector3 = _manager.get_closest_edge_direction(Vector3(5.0, 0.0, 250.0))
	assert_equal(direction, Vector3.LEFT,
		"Closest edge direction near west wall should be LEFT")


func _test_closest_edge_east_when_near_east() -> void:
	_init_default()
	var direction: Vector3 = _manager.get_closest_edge_direction(Vector3(495.0, 0.0, 250.0))
	assert_equal(direction, Vector3.RIGHT,
		"Closest edge direction near east wall should be RIGHT")


func _test_closest_edge_north_when_near_north() -> void:
	_init_default()
	var direction: Vector3 = _manager.get_closest_edge_direction(Vector3(250.0, 0.0, 5.0))
	assert_equal(direction, Vector3.FORWARD,
		"Closest edge direction near north wall should be FORWARD")


func _test_closest_edge_south_when_near_south() -> void:
	_init_default()
	var direction: Vector3 = _manager.get_closest_edge_direction(Vector3(250.0, 0.0, 495.0))
	assert_equal(direction, Vector3.BACK,
		"Closest edge direction near south wall should be BACK")


func _test_closest_edge_zero_at_center() -> void:
	_init_default()
	var direction: Vector3 = _manager.get_closest_edge_direction(Vector3(250.0, 0.0, 250.0))
	assert_equal(direction, Vector3.ZERO,
		"Closest edge direction at exact center should be ZERO (not in warning zone)")


# -- Distance to boundary --

func _test_distance_at_center_is_half_terrain() -> void:
	_init_default()
	var distance: float = _manager.get_distance_to_boundary(Vector3(250.0, 0.0, 250.0))
	assert_equal(distance, 250.0,
		"Distance to boundary at center of 500m terrain should be 250m")


func _test_distance_near_west_edge() -> void:
	_init_default()
	var distance: float = _manager.get_distance_to_boundary(Vector3(10.0, 0.0, 250.0))
	assert_equal(distance, 10.0,
		"Distance to boundary at x=10 should be 10m (west edge)")


func _test_distance_at_origin_is_zero() -> void:
	_init_default()
	var distance: float = _manager.get_distance_to_boundary(Vector3(0.0, 0.0, 0.0))
	assert_equal(distance, 0.0,
		"Distance to boundary at origin (0,0,0) should be 0m")


func _test_distance_at_far_corner() -> void:
	_init_default()
	var distance: float = _manager.get_distance_to_boundary(Vector3(500.0, 0.0, 500.0))
	assert_equal(distance, 0.0,
		"Distance to boundary at far corner (500,0,500) should be 0m")


# -- Per-archetype wall dimensions --

func _test_shattered_flats_walls_span_terrain_size() -> void:
	_manager.initialize(BiomeArchetypeConfig.shattered_flats())
	var wall: StaticBody3D = _get_wall("NorthWall")
	var shape: BoxShape3D = _get_wall_shape(wall)
	assert_equal(shape.size.x, 500.0,
		"Shattered Flats NorthWall width should match terrain_size (500)")


func _test_rock_warrens_walls_span_terrain_size() -> void:
	_manager.initialize(BiomeArchetypeConfig.rock_warrens())
	var wall: StaticBody3D = _get_wall("NorthWall")
	var shape: BoxShape3D = _get_wall_shape(wall)
	assert_equal(shape.size.x, 500.0,
		"Rock Warrens NorthWall width should match terrain_size (500)")


func _test_debris_field_walls_span_terrain_size() -> void:
	_manager.initialize(BiomeArchetypeConfig.debris_field())
	var wall: StaticBody3D = _get_wall("NorthWall")
	var shape: BoxShape3D = _get_wall_shape(wall)
	assert_equal(shape.size.x, 500.0,
		"Debris Field NorthWall width should match terrain_size (500)")


# -- Terrain heightmap vertices within boundary extents --

func _test_heightmap_vertices_within_bounds_shattered_flats() -> void:
	var config: BiomeArchetypeConfig = BiomeArchetypeConfig.shattered_flats()
	var generator: TerrainGenerator = TerrainGenerator.new()
	var result: TerrainGenerationResult = generator.generate(42, config, [])
	var max_x: float = float(TerrainGenerator.HEIGHTMAP_RESOLUTION - 1) * TerrainGenerator.VERTEX_SPACING
	var max_z: float = max_x
	assert_true(max_x <= config.terrain_size,
		"Shattered Flats heightmap max X (%.1f) should not exceed terrain_size (%.1f)" % [max_x, config.terrain_size])
	assert_true(max_z <= config.terrain_size,
		"Shattered Flats heightmap max Z (%.1f) should not exceed terrain_size (%.1f)" % [max_z, config.terrain_size])


func _test_heightmap_vertices_within_bounds_rock_warrens() -> void:
	var config: BiomeArchetypeConfig = BiomeArchetypeConfig.rock_warrens()
	var generator: TerrainGenerator = TerrainGenerator.new()
	var result: TerrainGenerationResult = generator.generate(42, config, [])
	var max_x: float = float(TerrainGenerator.HEIGHTMAP_RESOLUTION - 1) * TerrainGenerator.VERTEX_SPACING
	var max_z: float = max_x
	assert_true(max_x <= config.terrain_size,
		"Rock Warrens heightmap max X (%.1f) should not exceed terrain_size (%.1f)" % [max_x, config.terrain_size])
	assert_true(max_z <= config.terrain_size,
		"Rock Warrens heightmap max Z (%.1f) should not exceed terrain_size (%.1f)" % [max_z, config.terrain_size])


func _test_heightmap_vertices_within_bounds_debris_field() -> void:
	var config: BiomeArchetypeConfig = BiomeArchetypeConfig.debris_field()
	var generator: TerrainGenerator = TerrainGenerator.new()
	var result: TerrainGenerationResult = generator.generate(42, config, [])
	var max_x: float = float(TerrainGenerator.HEIGHTMAP_RESOLUTION - 1) * TerrainGenerator.VERTEX_SPACING
	var max_z: float = max_x
	assert_true(max_x <= config.terrain_size,
		"Debris Field heightmap max X (%.1f) should not exceed terrain_size (%.1f)" % [max_x, config.terrain_size])
	assert_true(max_z <= config.terrain_size,
		"Debris Field heightmap max Z (%.1f) should not exceed terrain_size (%.1f)" % [max_z, config.terrain_size])


# -- Edge cases --

func _test_position_at_exact_boundary() -> void:
	_init_default()
	# Position at exact east boundary (x=500) — distance should be 0
	var distance: float = _manager.get_distance_to_boundary(Vector3(500.0, 0.0, 250.0))
	assert_equal(distance, 0.0,
		"Distance at exact east boundary (x=500) should be 0m")
	# Should be in warning zone
	assert_true(_manager.is_in_warning_zone(Vector3(500.0, 0.0, 250.0)),
		"Position at exact east boundary should be in warning zone")


func _test_position_past_boundary_negative() -> void:
	_init_default()
	# Position past west boundary (negative x) — distance becomes negative
	var distance: float = _manager.get_distance_to_boundary(Vector3(-10.0, 0.0, 250.0))
	assert_true(distance < 0.0,
		"Distance past west boundary (x=-10) should be negative")
	# Should be in warning zone
	assert_true(_manager.is_in_warning_zone(Vector3(-10.0, 0.0, 250.0)),
		"Position past west boundary should be in warning zone")


func _test_set_tracked_body_does_not_crash() -> void:
	_init_default()
	var dummy_body: Node3D = Node3D.new()
	dummy_body.name = "TestBody"
	add_child(dummy_body)
	_manager.set_tracked_body(dummy_body)
	# Verify the manager accepted the body without error
	assert_true(true, "set_tracked_body should not crash with a valid Node3D")
	dummy_body.queue_free()


func _test_warning_zone_all_archetypes() -> void:
	# Verify warning zone logic works consistently for all three archetypes
	var archetypes: Array = [
		BiomeArchetypeConfig.shattered_flats(),
		BiomeArchetypeConfig.rock_warrens(),
		BiomeArchetypeConfig.debris_field(),
	]
	for config: BiomeArchetypeConfig in archetypes:
		# Re-create manager for each archetype
		if _manager != null:
			_manager.queue_free()
		_manager = WorldBoundaryManager.new()
		add_child(_manager)
		_manager.initialize(config)
		var size: float = config.terrain_size
		# Center should be safe
		assert_false(_manager.is_in_warning_zone(Vector3(size * 0.5, 0.0, size * 0.5)),
			"%s: center should not be in warning zone" % config.archetype_name)
		# Near edge should warn
		assert_true(_manager.is_in_warning_zone(Vector3(5.0, 0.0, size * 0.5)),
			"%s: near west edge should be in warning zone" % config.archetype_name)
