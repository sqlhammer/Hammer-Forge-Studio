## Unit tests for the Procedural Terrain system. Verifies TerrainFeatureRequest API,
## BiomeArchetypeConfig definitions, TerrainGenerator determinism, boundary compliance,
## feature request resolution (plateau, clearing, resource_spawn, walkable_clearance),
## and chunk grid coverage.
##
## Coverage target: 70% (per docs/studio/tdd-process-m8.md)
## Ticket: TICKET-0162
## Status: RED — failing tests written before implementation.
class_name TestProceduralTerrainUnit
extends TestSuite


# ── Constants ─────────────────────────────────────────────
const TERRAIN_SIZE: float = 500.0
const HEIGHT_TOLERANCE: float = 0.5
const POSITION_TOLERANCE: float = 2.0


# ── Private Variables ─────────────────────────────────────
var _generator: TerrainGenerator = null
var _archetype: BiomeArchetypeConfig = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_generator = TerrainGenerator.new()
	_archetype = BiomeArchetypeConfig.shattered_flats()


func after_each() -> void:
	_generator = null
	_archetype = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# TerrainFeatureRequest factory methods
	add_test("terrain_feature_request_plateau_factory", _test_terrain_feature_request_plateau_factory)
	add_test("terrain_feature_request_clearing_factory", _test_terrain_feature_request_clearing_factory)
	add_test("terrain_feature_request_resource_spawn_factory", _test_terrain_feature_request_resource_spawn_factory)
	add_test("terrain_feature_request_walkable_clearance_factory", _test_terrain_feature_request_walkable_clearance_factory)

	# BiomeArchetypeConfig definitions
	add_test("biome_archetype_shattered_flats", _test_biome_archetype_shattered_flats)
	add_test("biome_archetype_rock_warrens", _test_biome_archetype_rock_warrens)
	add_test("biome_archetype_debris_field", _test_biome_archetype_debris_field)

	# Determinism
	add_test("determinism_same_seed_same_output", _test_determinism_same_seed_same_output)
	add_test("determinism_different_seed_different_output", _test_determinism_different_seed_different_output)

	# Boundary compliance
	add_test("boundary_no_vertex_outside_terrain_size", _test_boundary_no_vertex_outside_terrain_size)

	# Plateau feature request
	add_test("plateau_creates_flat_elevated_area", _test_plateau_creates_flat_elevated_area)

	# Clearing feature request
	add_test("clearing_creates_flat_zone", _test_clearing_creates_flat_zone)

	# Resource spawn feature request
	add_test("resource_spawn_returns_correct_count", _test_resource_spawn_returns_correct_count)
	add_test("resource_spawn_respects_slope_max", _test_resource_spawn_respects_slope_max)
	add_test("resource_spawn_respects_clearance_radius", _test_resource_spawn_respects_clearance_radius)

	# Walkable clearance feature request
	add_test("walkable_clearance_creates_flat_zone", _test_walkable_clearance_creates_flat_zone)

	# Chunk grid
	add_test("chunk_grid_covers_full_terrain", _test_chunk_grid_covers_full_terrain)
	add_test("chunk_grid_no_gaps", _test_chunk_grid_no_gaps)
	add_test("chunk_grid_each_chunk_has_mesh_and_collision", _test_chunk_grid_each_chunk_has_mesh_and_collision)

	# Result structure
	add_test("result_has_terrain_mesh", _test_result_has_terrain_mesh)
	add_test("result_has_collision_shape", _test_result_has_collision_shape)
	add_test("result_confirmed_positions_per_request", _test_result_confirmed_positions_per_request)

	# Empty / edge cases
	add_test("empty_requests_array_generates_terrain", _test_empty_requests_array_generates_terrain)
	add_test("unresolvable_request_produces_warning", _test_unresolvable_request_produces_warning)

	# Feature request dispatch extensibility
	add_test("feature_type_enum_has_four_types", _test_feature_type_enum_has_four_types)

	# All requests resolved before mesh finalized
	add_test("all_requests_resolved_before_mesh", _test_all_requests_resolved_before_mesh)


# ── Test Methods: TerrainFeatureRequest factories ─────────

func _test_terrain_feature_request_plateau_factory() -> void:
	var request: TerrainFeatureRequest = TerrainFeatureRequest.create_plateau(
		50.0, 40.0, 10.0, TerrainFeatureRequest.AccessType.RAMP, 5.0, "center"
	)
	assert_equal(request.type, TerrainFeatureRequest.FeatureType.PLATEAU, "Type should be PLATEAU")
	assert_equal(request.width, 50.0, "Width should be 50")
	assert_equal(request.depth, 40.0, "Depth should be 40")
	assert_equal(request.height, 10.0, "Height should be 10")
	assert_equal(request.access, TerrainFeatureRequest.AccessType.RAMP, "Access should be RAMP")
	assert_equal(request.ramp_width, 5.0, "Ramp width should be 5")
	assert_equal(request.position_hint, "center", "Position hint should be center")


func _test_terrain_feature_request_clearing_factory() -> void:
	var hint: Vector2 = Vector2(100.0, 200.0)
	var request: TerrainFeatureRequest = TerrainFeatureRequest.create_clearing(25.0, hint)
	assert_equal(request.type, TerrainFeatureRequest.FeatureType.CLEARING, "Type should be CLEARING")
	assert_equal(request.radius, 25.0, "Radius should be 25")
	assert_equal(request.position_hint, hint, "Position hint should match")


func _test_terrain_feature_request_resource_spawn_factory() -> void:
	var request: TerrainFeatureRequest = TerrainFeatureRequest.create_resource_spawn(8, 30.0, 5.0)
	assert_equal(request.type, TerrainFeatureRequest.FeatureType.RESOURCE_SPAWN, "Type should be RESOURCE_SPAWN")
	assert_equal(request.count, 8, "Count should be 8")
	assert_equal(request.slope_max, 30.0, "Slope max should be 30")
	assert_equal(request.clearance_radius, 5.0, "Clearance radius should be 5")


func _test_terrain_feature_request_walkable_clearance_factory() -> void:
	var pos: Vector2 = Vector2(150.0, 300.0)
	var request: TerrainFeatureRequest = TerrainFeatureRequest.create_walkable_clearance(pos, 10.0)
	assert_equal(request.type, TerrainFeatureRequest.FeatureType.WALKABLE_CLEARANCE, "Type should be WALKABLE_CLEARANCE")
	assert_equal(request.position, pos, "Position should match")
	assert_equal(request.radius, 10.0, "Radius should be 10")


# ── Test Methods: BiomeArchetypeConfig ────────────────────

func _test_biome_archetype_shattered_flats() -> void:
	var config: BiomeArchetypeConfig = BiomeArchetypeConfig.shattered_flats()
	assert_equal(config.archetype_name, "shattered_flats", "Name should be shattered_flats")
	assert_true(config.noise_frequency < 0.01, "Shattered flats should have low frequency")
	assert_true(config.noise_octaves <= 4, "Shattered flats should have few octaves")
	assert_true(config.height_scale <= 15.0, "Shattered flats should have gentle undulation")


func _test_biome_archetype_rock_warrens() -> void:
	var config: BiomeArchetypeConfig = BiomeArchetypeConfig.rock_warrens()
	assert_equal(config.archetype_name, "rock_warrens", "Name should be rock_warrens")
	assert_true(config.noise_frequency > 0.01, "Rock warrens should have high frequency")
	assert_true(config.noise_octaves >= 5, "Rock warrens should have many octaves")
	assert_true(config.height_scale >= 20.0, "Rock warrens should have dense vertical variation")


func _test_biome_archetype_debris_field() -> void:
	var config: BiomeArchetypeConfig = BiomeArchetypeConfig.debris_field()
	assert_equal(config.archetype_name, "debris_field", "Name should be debris_field")
	assert_true(config.noise_frequency > 0.005, "Debris field should have medium frequency")
	assert_true(config.noise_frequency < 0.02, "Debris field frequency should be less than rock warrens")
	assert_true(config.height_scale > 10.0, "Debris field should have moderate height scale")


# ── Test Methods: Determinism ─────────────────────────────

func _test_determinism_same_seed_same_output() -> void:
	var seed_value: int = 42
	var requests: Array[TerrainFeatureRequest] = []
	var clearing: TerrainFeatureRequest = TerrainFeatureRequest.create_clearing(20.0, "center")
	requests.append(clearing)

	var result_a: TerrainGenerationResult = _generator.generate(seed_value, _archetype, requests)
	var result_b: TerrainGenerationResult = _generator.generate(seed_value, _archetype, requests)

	# Compare heightmap data for exact match
	assert_equal(result_a.heightmap.size(), result_b.heightmap.size(), "Heightmap sizes should match")
	var all_match: bool = true
	for i: int in range(result_a.heightmap.size()):
		if result_a.heightmap[i] != result_b.heightmap[i]:
			all_match = false
			break
	assert_true(all_match, "Same seed should produce identical heightmap data")


func _test_determinism_different_seed_different_output() -> void:
	var requests: Array[TerrainFeatureRequest] = []

	var result_a: TerrainGenerationResult = _generator.generate(42, _archetype, requests)
	var result_b: TerrainGenerationResult = _generator.generate(99, _archetype, requests)

	# At least some heights should differ
	var any_differ: bool = false
	var check_count: int = mini(result_a.heightmap.size(), 100)
	for i: int in range(check_count):
		if result_a.heightmap[i] != result_b.heightmap[i]:
			any_differ = true
			break
	assert_true(any_differ, "Different seeds should produce different heightmaps")


# ── Test Methods: Boundary compliance ─────────────────────

func _test_boundary_no_vertex_outside_terrain_size() -> void:
	var requests: Array[TerrainFeatureRequest] = []
	var result: TerrainGenerationResult = _generator.generate(42, _archetype, requests)

	assert_not_null(result.terrain_mesh, "Terrain mesh should exist")
	var surface_arrays: Array = result.terrain_mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = surface_arrays[Mesh.ARRAY_VERTEX]

	var all_in_bounds: bool = true
	var out_of_bounds_vertex: Vector3 = Vector3.ZERO
	for vertex: Vector3 in vertices:
		var x_ok: bool = vertex.x >= -0.01 and vertex.x <= TERRAIN_SIZE + 0.01
		var z_ok: bool = vertex.z >= -0.01 and vertex.z <= TERRAIN_SIZE + 0.01
		if not x_ok or not z_ok:
			all_in_bounds = false
			out_of_bounds_vertex = vertex
			break
	assert_true(all_in_bounds, "All vertices should be within 500m x 500m bounds, found: %s" % str(out_of_bounds_vertex))


# ── Test Methods: Plateau ─────────────────────────────────

func _test_plateau_creates_flat_elevated_area() -> void:
	var plateau_height: float = 12.0
	var plateau_width: float = 40.0
	var plateau_depth: float = 40.0
	var center: Vector2 = Vector2(250.0, 250.0)

	var requests: Array[TerrainFeatureRequest] = []
	var plateau: TerrainFeatureRequest = TerrainFeatureRequest.create_plateau(
		plateau_width, plateau_depth, plateau_height, TerrainFeatureRequest.AccessType.NONE, 3.0, center
	)
	requests.append(plateau)

	var result: TerrainGenerationResult = _generator.generate(42, _archetype, requests)

	# Sample the heightmap at the center of the plateau
	var resolution: int = result.heightmap_resolution
	var spacing: float = TERRAIN_SIZE / float(resolution - 1)
	var center_xi: int = roundi(center.x / spacing)
	var center_zi: int = roundi(center.y / spacing)
	var center_height: float = result.heightmap[center_zi * resolution + center_xi]

	# The center should be at approximately plateau_height above base
	assert_true(center_height >= plateau_height - HEIGHT_TOLERANCE,
		"Plateau center should be elevated to at least %s, got %s" % [plateau_height - HEIGHT_TOLERANCE, center_height])

	# Check flatness within the plateau area — sample multiple interior points
	var half_w_idx: int = roundi((plateau_width * 0.3) / spacing)
	var half_d_idx: int = roundi((plateau_depth * 0.3) / spacing)
	var min_height: float = INF
	var max_height: float = -INF
	for dxi: int in range(-half_w_idx, half_w_idx + 1):
		for dzi: int in range(-half_d_idx, half_d_idx + 1):
			var xi: int = center_xi + dxi
			var zi: int = center_zi + dzi
			if xi >= 0 and xi < resolution and zi >= 0 and zi < resolution:
				var h: float = result.heightmap[zi * resolution + xi]
				min_height = minf(min_height, h)
				max_height = maxf(max_height, h)

	var height_variation: float = max_height - min_height
	assert_true(height_variation < HEIGHT_TOLERANCE,
		"Plateau interior should be flat, variation was %s" % height_variation)


# ── Test Methods: Clearing ────────────────────────────────

func _test_clearing_creates_flat_zone() -> void:
	var clearing_radius: float = 30.0
	var center: Vector2 = Vector2(250.0, 250.0)

	var requests: Array[TerrainFeatureRequest] = []
	var clearing: TerrainFeatureRequest = TerrainFeatureRequest.create_clearing(clearing_radius, center)
	requests.append(clearing)

	var result: TerrainGenerationResult = _generator.generate(42, _archetype, requests)

	# Sample heights within the clearing radius — all should be approximately equal
	var resolution: int = result.heightmap_resolution
	var spacing: float = TERRAIN_SIZE / float(resolution - 1)
	var center_xi: int = roundi(center.x / spacing)
	var center_zi: int = roundi(center.y / spacing)
	var inner_radius_idx: int = roundi((clearing_radius * 0.5) / spacing)

	var min_height: float = INF
	var max_height: float = -INF
	var sample_count: int = 0
	for dxi: int in range(-inner_radius_idx, inner_radius_idx + 1):
		for dzi: int in range(-inner_radius_idx, inner_radius_idx + 1):
			var dist: float = sqrt(float(dxi * dxi + dzi * dzi)) * spacing
			if dist > clearing_radius * 0.5:
				continue
			var xi: int = center_xi + dxi
			var zi: int = center_zi + dzi
			if xi >= 0 and xi < resolution and zi >= 0 and zi < resolution:
				var h: float = result.heightmap[zi * resolution + xi]
				min_height = minf(min_height, h)
				max_height = maxf(max_height, h)
				sample_count += 1

	assert_true(sample_count > 0, "Should have sampled points within clearing")
	var height_variation: float = max_height - min_height
	assert_true(height_variation < HEIGHT_TOLERANCE,
		"Clearing interior should be flat, variation was %s" % height_variation)


# ── Test Methods: Resource spawn ──────────────────────────

func _test_resource_spawn_returns_correct_count() -> void:
	var spawn_count: int = 8
	var requests: Array[TerrainFeatureRequest] = []
	var spawn: TerrainFeatureRequest = TerrainFeatureRequest.create_resource_spawn(spawn_count, 45.0, 5.0)
	requests.append(spawn)

	var result: TerrainGenerationResult = _generator.generate(42, _archetype, requests)

	assert_true(result.confirmed_positions.has(0), "Result should have confirmed positions for request 0")
	var positions: Array = result.confirmed_positions[0]
	assert_equal(positions.size(), spawn_count,
		"Should return exactly %d positions, got %d" % [spawn_count, positions.size()])


func _test_resource_spawn_respects_slope_max() -> void:
	var requests: Array[TerrainFeatureRequest] = []
	# Use a low slope max to filter steep areas
	var spawn: TerrainFeatureRequest = TerrainFeatureRequest.create_resource_spawn(5, 15.0, 3.0)
	requests.append(spawn)

	var result: TerrainGenerationResult = _generator.generate(42, _archetype, requests)

	if not result.confirmed_positions.has(0):
		return
	var positions: Array = result.confirmed_positions[0]
	# All returned positions should be on terrain with slope <= slope_max
	var resolution: int = result.heightmap_resolution
	var spacing: float = TERRAIN_SIZE / float(resolution - 1)
	for pos: Vector3 in positions:
		var slope: float = _calculate_slope_at(result.heightmap, resolution, spacing, pos.x, pos.z)
		assert_true(slope <= 15.0 + 1.0,
			"Spawn position slope should be <= 15 degrees, got %s at %s" % [slope, pos])


func _test_resource_spawn_respects_clearance_radius() -> void:
	var clearance: float = 10.0
	var requests: Array[TerrainFeatureRequest] = []
	var spawn: TerrainFeatureRequest = TerrainFeatureRequest.create_resource_spawn(6, 45.0, clearance)
	requests.append(spawn)

	var result: TerrainGenerationResult = _generator.generate(42, _archetype, requests)

	if not result.confirmed_positions.has(0):
		return
	var positions: Array = result.confirmed_positions[0]
	# All positions should be at least clearance_radius apart from each other
	for i: int in range(positions.size()):
		for j: int in range(i + 1, positions.size()):
			var pos_a: Vector3 = positions[i]
			var pos_b: Vector3 = positions[j]
			var xz_dist: float = Vector2(pos_a.x, pos_a.z).distance_to(Vector2(pos_b.x, pos_b.z))
			assert_true(xz_dist >= clearance - 0.1,
				"Positions %d and %d should be >= %s apart, got %s" % [i, j, clearance, xz_dist])


# ── Test Methods: Walkable clearance ──────────────────────

func _test_walkable_clearance_creates_flat_zone() -> void:
	var clear_pos: Vector2 = Vector2(200.0, 200.0)
	var clear_radius: float = 15.0

	var requests: Array[TerrainFeatureRequest] = []
	var clearance: TerrainFeatureRequest = TerrainFeatureRequest.create_walkable_clearance(clear_pos, clear_radius)
	requests.append(clearance)

	# Use rock warrens archetype for high variation base terrain
	var rock_archetype: BiomeArchetypeConfig = BiomeArchetypeConfig.rock_warrens()
	var result: TerrainGenerationResult = _generator.generate(42, rock_archetype, requests)

	# Within the walkable clearance radius, terrain should be flat
	var resolution: int = result.heightmap_resolution
	var spacing: float = TERRAIN_SIZE / float(resolution - 1)
	var center_xi: int = roundi(clear_pos.x / spacing)
	var center_zi: int = roundi(clear_pos.y / spacing)
	var inner_radius_idx: int = roundi((clear_radius * 0.5) / spacing)

	var min_height: float = INF
	var max_height: float = -INF
	for dxi: int in range(-inner_radius_idx, inner_radius_idx + 1):
		for dzi: int in range(-inner_radius_idx, inner_radius_idx + 1):
			var dist: float = sqrt(float(dxi * dxi + dzi * dzi)) * spacing
			if dist > clear_radius * 0.5:
				continue
			var xi: int = center_xi + dxi
			var zi: int = center_zi + dzi
			if xi >= 0 and xi < resolution and zi >= 0 and zi < resolution:
				var h: float = result.heightmap[zi * resolution + xi]
				min_height = minf(min_height, h)
				max_height = maxf(max_height, h)

	var height_variation: float = max_height - min_height
	assert_true(height_variation < HEIGHT_TOLERANCE,
		"Walkable clearance zone should be flat, variation was %s" % height_variation)


# ── Test Methods: Chunk grid ──────────────────────────────

func _test_chunk_grid_covers_full_terrain() -> void:
	var requests: Array[TerrainFeatureRequest] = []
	var result: TerrainGenerationResult = _generator.generate(42, _archetype, requests)

	assert_true(result.chunk_grid.size() > 0, "Chunk grid should not be empty")

	# Verify chunks span from (0,0) to the last chunk
	var max_cx: int = 0
	var max_cz: int = 0
	for grid_pos: Vector2i in result.chunk_grid:
		max_cx = maxi(max_cx, grid_pos.x)
		max_cz = maxi(max_cz, grid_pos.y)

	var expected_chunks: int = ceili(TERRAIN_SIZE / TerrainGenerator.CHUNK_SIZE)
	assert_equal(max_cx, expected_chunks - 1,
		"Max chunk X should be %d" % (expected_chunks - 1))
	assert_equal(max_cz, expected_chunks - 1,
		"Max chunk Z should be %d" % (expected_chunks - 1))


func _test_chunk_grid_no_gaps() -> void:
	var requests: Array[TerrainFeatureRequest] = []
	var result: TerrainGenerationResult = _generator.generate(42, _archetype, requests)

	var chunks_per_axis: int = ceili(TERRAIN_SIZE / TerrainGenerator.CHUNK_SIZE)
	var expected_total: int = chunks_per_axis * chunks_per_axis

	assert_equal(result.chunk_grid.size(), expected_total,
		"Chunk grid should have %d chunks, got %d" % [expected_total, result.chunk_grid.size()])

	# Verify every grid cell is populated
	for cx: int in range(chunks_per_axis):
		for cz: int in range(chunks_per_axis):
			var key: Vector2i = Vector2i(cx, cz)
			assert_true(result.chunk_grid.has(key),
				"Chunk at (%d, %d) should exist" % [cx, cz])


func _test_chunk_grid_each_chunk_has_mesh_and_collision() -> void:
	var requests: Array[TerrainFeatureRequest] = []
	var result: TerrainGenerationResult = _generator.generate(42, _archetype, requests)

	var checked: int = 0
	for grid_pos: Vector2i in result.chunk_grid:
		var chunk: TerrainChunk = result.chunk_grid[grid_pos]
		assert_not_null(chunk.mesh_section, "Chunk at %s should have a mesh" % str(grid_pos))
		assert_not_null(chunk.collision_shape, "Chunk at %s should have collision" % str(grid_pos))
		checked += 1
		if checked >= 4:
			break


# ── Test Methods: Result structure ────────────────────────

func _test_result_has_terrain_mesh() -> void:
	var requests: Array[TerrainFeatureRequest] = []
	var result: TerrainGenerationResult = _generator.generate(42, _archetype, requests)
	assert_not_null(result.terrain_mesh, "Result should have a terrain mesh")
	assert_true(result.terrain_mesh.get_surface_count() > 0, "Terrain mesh should have at least one surface")


func _test_result_has_collision_shape() -> void:
	var requests: Array[TerrainFeatureRequest] = []
	var result: TerrainGenerationResult = _generator.generate(42, _archetype, requests)
	assert_not_null(result.collision_shape, "Result should have a collision shape")


func _test_result_confirmed_positions_per_request() -> void:
	var requests: Array[TerrainFeatureRequest] = []
	var clearing: TerrainFeatureRequest = TerrainFeatureRequest.create_clearing(20.0, "center")
	var spawn: TerrainFeatureRequest = TerrainFeatureRequest.create_resource_spawn(3, 45.0, 5.0)
	requests.append(clearing)
	requests.append(spawn)

	var result: TerrainGenerationResult = _generator.generate(42, _archetype, requests)

	# Each request should have an entry in confirmed_positions
	assert_true(result.confirmed_positions.has(0), "Should have confirmed position for clearing (index 0)")
	assert_true(result.confirmed_positions.has(1), "Should have confirmed position for spawn (index 1)")


# ── Test Methods: Edge cases ──────────────────────────────

func _test_empty_requests_array_generates_terrain() -> void:
	var requests: Array[TerrainFeatureRequest] = []
	var result: TerrainGenerationResult = _generator.generate(42, _archetype, requests)

	assert_not_null(result, "Result should not be null")
	assert_not_null(result.terrain_mesh, "Should still generate terrain mesh with no requests")
	assert_not_null(result.collision_shape, "Should still generate collision with no requests")
	assert_equal(result.warnings.size(), 0, "No warnings expected for empty requests")


func _test_unresolvable_request_produces_warning() -> void:
	# Request resource spawns in a tiny area — more than can fit
	var requests: Array[TerrainFeatureRequest] = []
	var spawn: TerrainFeatureRequest = TerrainFeatureRequest.create_resource_spawn(100, 5.0, 50.0)
	# Huge clearance radius with many points — likely unresolvable
	requests.append(spawn)

	var result: TerrainGenerationResult = _generator.generate(42, _archetype, requests)

	# If not all 100 could be placed, there should be a warning
	if result.confirmed_positions.has(0):
		var positions: Array = result.confirmed_positions[0]
		if positions.size() < 100:
			assert_true(result.warnings.size() > 0,
				"Should produce a warning when not all spawn positions could be resolved")


func _test_feature_type_enum_has_four_types() -> void:
	# Verify the four required feature types exist
	assert_equal(TerrainFeatureRequest.FeatureType.PLATEAU, 0, "PLATEAU should be 0")
	assert_equal(TerrainFeatureRequest.FeatureType.CLEARING, 1, "CLEARING should be 1")
	assert_equal(TerrainFeatureRequest.FeatureType.RESOURCE_SPAWN, 2, "RESOURCE_SPAWN should be 2")
	assert_equal(TerrainFeatureRequest.FeatureType.WALKABLE_CLEARANCE, 3, "WALKABLE_CLEARANCE should be 3")


func _test_all_requests_resolved_before_mesh() -> void:
	var requests: Array[TerrainFeatureRequest] = []
	var plateau: TerrainFeatureRequest = TerrainFeatureRequest.create_plateau(
		30.0, 30.0, 8.0, TerrainFeatureRequest.AccessType.NONE, 3.0, "center"
	)
	var clearing: TerrainFeatureRequest = TerrainFeatureRequest.create_clearing(20.0, Vector2(100.0, 100.0))
	requests.append(plateau)
	requests.append(clearing)

	var result: TerrainGenerationResult = _generator.generate(42, _archetype, requests)

	# Both requests should have confirmed positions
	assert_true(result.confirmed_positions.has(0), "Plateau request should be resolved")
	assert_true(result.confirmed_positions.has(1), "Clearing request should be resolved")

	# Mesh should reflect the plateau — sample center of terrain
	var resolution: int = result.heightmap_resolution
	var spacing: float = TERRAIN_SIZE / float(resolution - 1)
	var center_xi: int = roundi(250.0 / spacing)
	var center_zi: int = roundi(250.0 / spacing)
	var center_h: float = result.heightmap[center_zi * resolution + center_xi]
	assert_true(center_h >= 8.0 - HEIGHT_TOLERANCE,
		"Plateau should be reflected in final heightmap, got height %s" % center_h)


# ── Helper Methods ────────────────────────────────────────

func _calculate_slope_at(heightmap: PackedFloat32Array, resolution: int, spacing: float, world_x: float, world_z: float) -> float:
	var xi: int = roundi(world_x / spacing)
	var zi: int = roundi(world_z / spacing)

	# Clamp to valid range with neighbor margin
	xi = clampi(xi, 1, resolution - 2)
	zi = clampi(zi, 1, resolution - 2)

	var h_center: float = heightmap[zi * resolution + xi]
	var h_left: float = heightmap[zi * resolution + (xi - 1)]
	var h_right: float = heightmap[zi * resolution + (xi + 1)]
	var h_up: float = heightmap[(zi - 1) * resolution + xi]
	var h_down: float = heightmap[(zi + 1) * resolution + xi]

	var dx: float = (h_right - h_left) / (2.0 * spacing)
	var dz: float = (h_down - h_up) / (2.0 * spacing)
	var gradient: float = sqrt(dx * dx + dz * dz)
	var slope_degrees: float = rad_to_deg(atan(gradient))

	return slope_degrees
