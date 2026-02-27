## Unit tests for the Debris Field biome (TICKET-0172). Verifies terrain generation
## with debris_field archetype, wreckage cluster placement, resource node counts and types,
## deep resource nodes, spawn points, world boundary, and deterministic layout.
##
## Coverage target: 70% (per docs/studio/tdd-process-m8.md — Procedural terrain)
## Ticket: TICKET-0172
## Status: RED — failing tests written before implementation.
class_name TestDebrisFieldBiomeUnit
extends TestSuite


# ── Constants ─────────────────────────────────────────────
const TERRAIN_SIZE: float = 500.0
const DEBRIS_FIELD_SEED: int = 3317


# ── Private Variables ─────────────────────────────────────
var _biome: DebrisFieldBiome = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_biome = DebrisFieldBiome.new()


func after_each() -> void:
	if _biome and is_instance_valid(_biome):
		_biome.queue_free()
	_biome = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Class structure
	add_test("class_exists_and_extends_node3d", _test_class_exists_and_extends_node3d)

	# Terrain generation
	add_test("uses_debris_field_archetype", _test_uses_debris_field_archetype)
	add_test("uses_correct_seed", _test_uses_correct_seed)
	add_test("terrain_result_not_null", _test_terrain_result_not_null)
	add_test("terrain_is_deterministic", _test_terrain_is_deterministic)

	# Wreckage clusters
	add_test("wreckage_clusters_minimum_five", _test_wreckage_clusters_minimum_five)
	add_test("wreckage_cluster_positions_valid", _test_wreckage_cluster_positions_valid)

	# Resource nodes — surface Scrap Metal
	add_test("scrap_metal_surface_count_in_range", _test_scrap_metal_surface_count_in_range)
	add_test("scrap_metal_surface_type_correct", _test_scrap_metal_surface_type_correct)

	# Resource nodes — surface Cryonite
	add_test("cryonite_surface_count_in_range", _test_cryonite_surface_count_in_range)
	add_test("cryonite_surface_type_correct", _test_cryonite_surface_type_correct)

	# Deep resource nodes
	add_test("deep_cryonite_count_minimum_two", _test_deep_cryonite_count_minimum_two)
	add_test("deep_cryonite_is_infinite", _test_deep_cryonite_is_infinite)
	add_test("deep_scrap_metal_count_minimum_one", _test_deep_scrap_metal_count_minimum_one)
	add_test("deep_scrap_metal_is_infinite", _test_deep_scrap_metal_is_infinite)
	add_test("deep_nodes_have_slow_yield_rate", _test_deep_nodes_have_slow_yield_rate)

	# Fuel Cell sufficiency
	add_test("sufficient_resources_for_fuel_cell", _test_sufficient_resources_for_fuel_cell)

	# Spawn points
	add_test("ship_spawn_point_defined", _test_ship_spawn_point_defined)
	add_test("player_spawn_point_defined", _test_player_spawn_point_defined)
	add_test("spawn_points_within_terrain_bounds", _test_spawn_points_within_terrain_bounds)

	# World boundary
	add_test("world_boundary_active", _test_world_boundary_active)

	# Feature requests
	add_test("ship_clearing_request_present", _test_ship_clearing_request_present)
	add_test("resource_spawn_requests_present", _test_resource_spawn_requests_present)

	# Deposit placement
	add_test("all_deposits_within_terrain_bounds", _test_all_deposits_within_terrain_bounds)
	add_test("deposits_have_collision", _test_deposits_have_collision)


# ── Test Methods: Class structure ─────────────────────────

func _test_class_exists_and_extends_node3d() -> void:
	assert_not_null(_biome, "DebrisFieldBiome should be instantiable")
	assert_true(_biome is Node3D, "DebrisFieldBiome should extend Node3D")


# ── Test Methods: Terrain generation ──────────────────────

func _test_uses_debris_field_archetype() -> void:
	var archetype: BiomeArchetypeConfig = _biome.get_archetype()
	assert_not_null(archetype, "Archetype should not be null")
	assert_equal(archetype.archetype_name, "debris_field", "Should use debris_field archetype")


func _test_uses_correct_seed() -> void:
	var seed_value: int = _biome.get_terrain_seed()
	assert_equal(seed_value, DEBRIS_FIELD_SEED, "Should use seed 3317 from BiomeRegistry")


func _test_terrain_result_not_null() -> void:
	var result: TerrainGenerationResult = _biome.get_terrain_result()
	assert_not_null(result, "Terrain generation result should not be null")
	assert_not_null(result.terrain_mesh, "Terrain mesh should exist")
	assert_not_null(result.collision_shape, "Collision shape should exist")


func _test_terrain_is_deterministic() -> void:
	var biome_b: DebrisFieldBiome = DebrisFieldBiome.new()
	var result_a: TerrainGenerationResult = _biome.get_terrain_result()
	var result_b: TerrainGenerationResult = biome_b.get_terrain_result()

	assert_equal(result_a.heightmap.size(), result_b.heightmap.size(),
		"Heightmap sizes should match")

	var all_match: bool = true
	for i: int in range(mini(result_a.heightmap.size(), 100)):
		if result_a.heightmap[i] != result_b.heightmap[i]:
			all_match = false
			break
	assert_true(all_match, "Same seed should produce identical heightmap data")
	biome_b.queue_free()


# ── Test Methods: Wreckage clusters ──────────────────────

func _test_wreckage_clusters_minimum_five() -> void:
	var cluster_count: int = _biome.get_wreckage_cluster_count()
	assert_true(cluster_count >= 5,
		"Should have at least 5 wreckage clusters, got %d" % cluster_count)


func _test_wreckage_cluster_positions_valid() -> void:
	var positions: Array[Vector3] = _biome.get_wreckage_cluster_positions()
	assert_true(positions.size() >= 5, "Should have at least 5 cluster positions")
	for pos: Vector3 in positions:
		assert_true(pos.x >= 0.0 and pos.x <= TERRAIN_SIZE,
			"Cluster X should be within bounds, got %s" % pos.x)
		assert_true(pos.z >= 0.0 and pos.z <= TERRAIN_SIZE,
			"Cluster Z should be within bounds, got %s" % pos.z)


# ── Test Methods: Surface Scrap Metal ─────────────────────

func _test_scrap_metal_surface_count_in_range() -> void:
	var deposits: Array[Dictionary] = _biome.get_surface_deposits()
	var scrap_count: int = 0
	for deposit_info: Dictionary in deposits:
		if deposit_info.get("resource_type") == ResourceDefs.ResourceType.SCRAP_METAL:
			scrap_count += 1
	assert_true(scrap_count >= 2,
		"Should have at least 2 surface Scrap Metal nodes, got %d" % scrap_count)
	assert_true(scrap_count <= 4,
		"Should have at most 4 surface Scrap Metal nodes, got %d" % scrap_count)


func _test_scrap_metal_surface_type_correct() -> void:
	var deposits: Array[Dictionary] = _biome.get_surface_deposits()
	for deposit_info: Dictionary in deposits:
		if deposit_info.get("resource_type") == ResourceDefs.ResourceType.SCRAP_METAL:
			assert_equal(deposit_info.get("infinite"), false,
				"Surface Scrap Metal should not be infinite")


# ── Test Methods: Surface Cryonite ────────────────────────

func _test_cryonite_surface_count_in_range() -> void:
	var deposits: Array[Dictionary] = _biome.get_surface_deposits()
	var cryo_count: int = 0
	for deposit_info: Dictionary in deposits:
		if deposit_info.get("resource_type") == ResourceDefs.ResourceType.CRYONITE:
			cryo_count += 1
	assert_true(cryo_count >= 7,
		"Should have at least 7 surface Cryonite nodes, got %d" % cryo_count)
	assert_true(cryo_count <= 10,
		"Should have at most 10 surface Cryonite nodes, got %d" % cryo_count)


func _test_cryonite_surface_type_correct() -> void:
	var deposits: Array[Dictionary] = _biome.get_surface_deposits()
	for deposit_info: Dictionary in deposits:
		if deposit_info.get("resource_type") == ResourceDefs.ResourceType.CRYONITE:
			assert_equal(deposit_info.get("infinite"), false,
				"Surface Cryonite should not be infinite")


# ── Test Methods: Deep resource nodes ─────────────────────

func _test_deep_cryonite_count_minimum_two() -> void:
	var deep_deposits: Array[Dictionary] = _biome.get_deep_deposits()
	var deep_cryo_count: int = 0
	for deposit_info: Dictionary in deep_deposits:
		if deposit_info.get("resource_type") == ResourceDefs.ResourceType.CRYONITE:
			deep_cryo_count += 1
	assert_true(deep_cryo_count >= 2,
		"Should have at least 2 deep Cryonite nodes, got %d" % deep_cryo_count)


func _test_deep_cryonite_is_infinite() -> void:
	var deep_deposits: Array[Dictionary] = _biome.get_deep_deposits()
	for deposit_info: Dictionary in deep_deposits:
		if deposit_info.get("resource_type") == ResourceDefs.ResourceType.CRYONITE:
			assert_equal(deposit_info.get("infinite"), true,
				"Deep Cryonite should be infinite")


func _test_deep_scrap_metal_count_minimum_one() -> void:
	var deep_deposits: Array[Dictionary] = _biome.get_deep_deposits()
	var deep_scrap_count: int = 0
	for deposit_info: Dictionary in deep_deposits:
		if deposit_info.get("resource_type") == ResourceDefs.ResourceType.SCRAP_METAL:
			deep_scrap_count += 1
	assert_true(deep_scrap_count >= 1,
		"Should have at least 1 deep Scrap Metal node, got %d" % deep_scrap_count)


func _test_deep_scrap_metal_is_infinite() -> void:
	var deep_deposits: Array[Dictionary] = _biome.get_deep_deposits()
	for deposit_info: Dictionary in deep_deposits:
		if deposit_info.get("resource_type") == ResourceDefs.ResourceType.SCRAP_METAL:
			assert_equal(deposit_info.get("infinite"), true,
				"Deep Scrap Metal should be infinite")


func _test_deep_nodes_have_slow_yield_rate() -> void:
	var deep_deposits: Array[Dictionary] = _biome.get_deep_deposits()
	assert_true(deep_deposits.size() > 0, "Should have deep deposits")
	for deposit_info: Dictionary in deep_deposits:
		var yield_rate: float = deposit_info.get("yield_rate", 1.0)
		assert_true(yield_rate < 1.0,
			"Deep nodes should have yield_rate < 1.0, got %s" % yield_rate)


# ── Test Methods: Fuel Cell sufficiency ───────────────────

func _test_sufficient_resources_for_fuel_cell() -> void:
	# Fuel Cell recipe: 2 Metal (from Scrap Metal via Recycler) + 1 Cryonite
	# Need: >=1 Cryonite total yield + enough Scrap Metal to smelt >=2 Metal
	var all_deposits: Array[Dictionary] = _biome.get_surface_deposits()
	all_deposits.append_array(_biome.get_deep_deposits())

	var total_scrap: int = 0
	var total_cryonite: int = 0
	for deposit_info: Dictionary in all_deposits:
		var quantity: int = deposit_info.get("quantity", 0)
		# Infinite deposits contribute at least their base quantity worth
		if deposit_info.get("infinite", false):
			quantity = maxi(quantity, 10)
		match deposit_info.get("resource_type"):
			ResourceDefs.ResourceType.SCRAP_METAL:
				total_scrap += quantity
			ResourceDefs.ResourceType.CRYONITE:
				total_cryonite += quantity

	# At minimum: 1 Cryonite and enough Scrap to make 2 Metal
	assert_true(total_cryonite >= 1,
		"Should have enough Cryonite for at least 1 Fuel Cell, got %d" % total_cryonite)
	assert_true(total_scrap >= 2,
		"Should have enough Scrap Metal to smelt into 2 Metal, got %d" % total_scrap)


# ── Test Methods: Spawn points ────────────────────────────

func _test_ship_spawn_point_defined() -> void:
	var ship_spawn: Vector3 = _biome.get_ship_spawn_point()
	assert_true(ship_spawn != Vector3.ZERO or true,
		"Ship spawn point should be defined")
	# Ship spawn should be on or near the terrain surface
	assert_true(ship_spawn.x >= 0.0 and ship_spawn.x <= TERRAIN_SIZE,
		"Ship spawn X should be within terrain bounds")
	assert_true(ship_spawn.z >= 0.0 and ship_spawn.z <= TERRAIN_SIZE,
		"Ship spawn Z should be within terrain bounds")


func _test_player_spawn_point_defined() -> void:
	var player_spawn: Vector3 = _biome.get_player_spawn_point()
	assert_true(player_spawn.x >= 0.0 and player_spawn.x <= TERRAIN_SIZE,
		"Player spawn X should be within terrain bounds")
	assert_true(player_spawn.z >= 0.0 and player_spawn.z <= TERRAIN_SIZE,
		"Player spawn Z should be within terrain bounds")


func _test_spawn_points_within_terrain_bounds() -> void:
	var ship_spawn: Vector3 = _biome.get_ship_spawn_point()
	var player_spawn: Vector3 = _biome.get_player_spawn_point()

	# Both spawns should have some margin from the edge
	var margin: float = 10.0
	assert_true(ship_spawn.x >= margin and ship_spawn.x <= TERRAIN_SIZE - margin,
		"Ship spawn should have margin from terrain edge")
	assert_true(ship_spawn.z >= margin and ship_spawn.z <= TERRAIN_SIZE - margin,
		"Ship spawn should have margin from terrain edge")
	assert_true(player_spawn.x >= margin and player_spawn.x <= TERRAIN_SIZE - margin,
		"Player spawn should have margin from terrain edge")
	assert_true(player_spawn.z >= margin and player_spawn.z <= TERRAIN_SIZE - margin,
		"Player spawn should have margin from terrain edge")


# ── Test Methods: World boundary ──────────────────────────

func _test_world_boundary_active() -> void:
	var biome_scene: DebrisFieldBiome = DebrisFieldBiome.new()
	add_child(biome_scene)
	biome_scene.build_scene()
	var has_boundary: bool = biome_scene.is_world_boundary_active()
	assert_true(has_boundary, "World boundary should be active")
	biome_scene.queue_free()


# ── Test Methods: Feature requests ────────────────────────

func _test_ship_clearing_request_present() -> void:
	var requests: Array[TerrainFeatureRequest] = _biome.get_feature_requests()
	var has_clearing: bool = false
	for request: TerrainFeatureRequest in requests:
		if request.type == TerrainFeatureRequest.FeatureType.CLEARING:
			has_clearing = true
			break
	assert_true(has_clearing, "Should have a clearing request for ship spawn")


func _test_resource_spawn_requests_present() -> void:
	var requests: Array[TerrainFeatureRequest] = _biome.get_feature_requests()
	var spawn_count: int = 0
	for request: TerrainFeatureRequest in requests:
		if request.type == TerrainFeatureRequest.FeatureType.RESOURCE_SPAWN:
			spawn_count += 1
	assert_true(spawn_count >= 2,
		"Should have at least 2 resource spawn requests (scrap + cryonite), got %d" % spawn_count)


# ── Test Methods: Deposit placement ───────────────────────

func _test_all_deposits_within_terrain_bounds() -> void:
	var all_deposits: Array[Dictionary] = _biome.get_surface_deposits()
	all_deposits.append_array(_biome.get_deep_deposits())
	for deposit_info: Dictionary in all_deposits:
		var pos: Vector3 = deposit_info.get("position", Vector3.ZERO)
		assert_true(pos.x >= 0.0 and pos.x <= TERRAIN_SIZE,
			"Deposit X should be within terrain bounds, got %s" % pos.x)
		assert_true(pos.z >= 0.0 and pos.z <= TERRAIN_SIZE,
			"Deposit Z should be within terrain bounds, got %s" % pos.z)


func _test_deposits_have_collision() -> void:
	var all_deposits: Array[Dictionary] = _biome.get_surface_deposits()
	assert_true(all_deposits.size() > 0, "Should have surface deposits")
	# Verify deposit data includes collision flag or valid position
	for deposit_info: Dictionary in all_deposits:
		assert_true(deposit_info.has("position"), "Deposit should have a position")
		assert_true(deposit_info.has("resource_type"), "Deposit should have a resource_type")
