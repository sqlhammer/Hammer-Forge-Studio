## Unit tests for the Rock Warrens biome. Verifies terrain generation with correct
## seed and archetype, resource placement counts and sufficiency, rock formation
## density, spawn point positioning, world boundary, and deterministic layout.
##
## Coverage target: 70% (per docs/studio/tdd-process-m8.md)
## Ticket: TICKET-0171
## Status: RED — failing tests written before implementation.
class_name TestRockWarrensBiomeUnit
extends TestSuite


# ── Constants ─────────────────────────────────────────────

const EXPECTED_SEED: int = 2047
const TERRAIN_SIZE: float = 500.0
const EDGE_MARGIN: float = 40.0

## Fuel Cell recipe: 2 Metal (refined from Scrap Metal) + 1 Cryonite.
const FUEL_CELL_METAL_COST: int = 2
const FUEL_CELL_CRYONITE_COST: int = 1


# ── Private Variables ─────────────────────────────────────

var _biome: RockWarrensBiome = null


# ── Setup / Teardown ──────────────────────────────────────

func before_all() -> void:
	_biome = RockWarrensBiome.new()
	add_child(_biome)
	_biome.generate()


func after_all() -> void:
	if _biome != null:
		_biome.queue_free()
		_biome = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Seed and archetype
	add_test("biome_seed_is_2047", _test_biome_seed_is_2047)
	add_test("archetype_is_rock_warrens", _test_archetype_is_rock_warrens)

	# Terrain generation
	add_test("terrain_generates_valid_mesh", _test_terrain_generates_valid_mesh)
	add_test("terrain_has_collision_shape", _test_terrain_has_collision_shape)

	# Resource placement — surface nodes
	add_test("scrap_metal_surface_count_in_range", _test_scrap_metal_surface_count_in_range)
	add_test("cryonite_surface_count_in_range", _test_cryonite_surface_count_in_range)

	# Resource placement — deep nodes
	add_test("deep_scrap_metal_node_exists", _test_deep_scrap_metal_node_exists)
	add_test("deep_cryonite_node_exists", _test_deep_cryonite_node_exists)

	# Resource sufficiency
	add_test("sufficient_resources_for_fuel_cell", _test_sufficient_resources_for_fuel_cell)

	# Spawn points
	add_test("player_spawn_defined", _test_player_spawn_defined)
	add_test("ship_spawn_defined", _test_ship_spawn_defined)
	add_test("spawn_near_biome_edge", _test_spawn_near_biome_edge)

	# Rock formations
	add_test("rock_formations_exist", _test_rock_formations_exist)

	# World boundary
	add_test("world_boundary_active", _test_world_boundary_active)

	# Determinism
	add_test("deterministic_layout", _test_deterministic_layout)

	# Signal
	add_test("generation_completed_signal_emitted", _test_generation_completed_signal_emitted)


# ── Test Methods: Seed and archetype ─────────────────────

func _test_biome_seed_is_2047() -> void:
	assert_equal(_biome.get_biome_seed(), EXPECTED_SEED, "Biome seed should be 2047")


func _test_archetype_is_rock_warrens() -> void:
	var archetype: BiomeArchetypeConfig = _biome.get_archetype()
	assert_not_null(archetype, "Archetype should not be null")
	assert_equal(archetype.archetype_name, "rock_warrens", "Archetype should be rock_warrens")


# ── Test Methods: Terrain generation ─────────────────────

func _test_terrain_generates_valid_mesh() -> void:
	var result: TerrainGenerationResult = _biome.get_terrain_result()
	assert_not_null(result, "Terrain result should not be null")
	assert_not_null(result.terrain_mesh, "Terrain mesh should not be null")
	assert_true(result.terrain_mesh.get_surface_count() > 0,
		"Terrain mesh should have at least one surface")


func _test_terrain_has_collision_shape() -> void:
	var result: TerrainGenerationResult = _biome.get_terrain_result()
	assert_not_null(result, "Terrain result should not be null")
	assert_not_null(result.collision_shape, "Collision shape should not be null")


# ── Test Methods: Resource placement — surface ───────────

func _test_scrap_metal_surface_count_in_range() -> void:
	var count: int = _biome.get_scrap_metal_surface_count()
	assert_true(count >= 5,
		"Should have at least 5 Scrap Metal surface nodes, got %d" % count)
	assert_true(count <= 8,
		"Should have at most 8 Scrap Metal surface nodes, got %d" % count)


func _test_cryonite_surface_count_in_range() -> void:
	var count: int = _biome.get_cryonite_surface_count()
	assert_true(count >= 4,
		"Should have at least 4 Cryonite surface nodes, got %d" % count)
	assert_true(count <= 7,
		"Should have at most 7 Cryonite surface nodes, got %d" % count)


# ── Test Methods: Resource placement — deep nodes ────────

func _test_deep_scrap_metal_node_exists() -> void:
	var count: int = _biome.get_deep_scrap_metal_count()
	assert_true(count >= 1,
		"Should have at least 1 deep Scrap Metal node, got %d" % count)


func _test_deep_cryonite_node_exists() -> void:
	var count: int = _biome.get_deep_cryonite_count()
	assert_true(count >= 1,
		"Should have at least 1 deep Cryonite node, got %d" % count)


# ── Test Methods: Resource sufficiency ───────────────────

func _test_sufficient_resources_for_fuel_cell() -> void:
	# Fuel Cell requires 2 Metal (from Scrap Metal) + 1 Cryonite
	var scrap_total: int = _biome.get_total_scrap_metal_quantity()
	var cryonite_total: int = _biome.get_total_cryonite_quantity()
	assert_true(scrap_total >= FUEL_CELL_METAL_COST,
		"Should have >= %d Scrap Metal units for Fuel Cell, got %d" % [
			FUEL_CELL_METAL_COST, scrap_total])
	assert_true(cryonite_total >= FUEL_CELL_CRYONITE_COST,
		"Should have >= %d Cryonite units for Fuel Cell, got %d" % [
			FUEL_CELL_CRYONITE_COST, cryonite_total])


# ── Test Methods: Spawn points ───────────────────────────

func _test_player_spawn_defined() -> void:
	var spawn: Vector3 = _biome.get_player_spawn_position()
	assert_true(spawn != Vector3.ZERO,
		"Player spawn should not be at origin")


func _test_ship_spawn_defined() -> void:
	var spawn: Vector3 = _biome.get_ship_spawn_position()
	assert_true(spawn != Vector3.ZERO,
		"Ship spawn should not be at origin")


func _test_spawn_near_biome_edge() -> void:
	var spawn: Vector3 = _biome.get_ship_spawn_position()
	# Ship spawn should be near one of the four biome boundaries
	var edge_threshold: float = EDGE_MARGIN + 30.0
	var near_west: bool = spawn.x < edge_threshold
	var near_east: bool = spawn.x > TERRAIN_SIZE - edge_threshold
	var near_north: bool = spawn.z < edge_threshold
	var near_south: bool = spawn.z > TERRAIN_SIZE - edge_threshold
	var near_edge: bool = near_west or near_east or near_north or near_south
	assert_true(near_edge,
		"Ship spawn should be near biome edge, position: %s" % str(spawn))


# ── Test Methods: Rock formations ────────────────────────

func _test_rock_formations_exist() -> void:
	var count: int = _biome.get_rock_formation_count()
	assert_true(count > 20,
		"Should have many rock formations for corridor feel, got %d" % count)


# ── Test Methods: World boundary ─────────────────────────

func _test_world_boundary_active() -> void:
	var found: bool = false
	for child: Node in _biome.get_children():
		if child is WorldBoundaryManager:
			found = true
			break
	assert_true(found, "WorldBoundaryManager should be a child of the biome")


# ── Test Methods: Determinism ────────────────────────────

func _test_deterministic_layout() -> void:
	# Generate a second biome and compare outputs
	var biome_b: RockWarrensBiome = RockWarrensBiome.new()
	add_child(biome_b)
	biome_b.generate()

	var spawn_a: Vector3 = _biome.get_player_spawn_position()
	var spawn_b: Vector3 = biome_b.get_player_spawn_position()
	assert_equal(spawn_a, spawn_b,
		"Same seed should produce same player spawn position")

	var scrap_a: int = _biome.get_scrap_metal_surface_count()
	var scrap_b: int = biome_b.get_scrap_metal_surface_count()
	assert_equal(scrap_a, scrap_b,
		"Same seed should produce same scrap metal surface count")

	var cryo_a: int = _biome.get_cryonite_surface_count()
	var cryo_b: int = biome_b.get_cryonite_surface_count()
	assert_equal(cryo_a, cryo_b,
		"Same seed should produce same cryonite surface count")

	biome_b.queue_free()


# ── Test Methods: Signal ─────────────────────────────────

func _test_generation_completed_signal_emitted() -> void:
	var biome_c: RockWarrensBiome = RockWarrensBiome.new()
	var signal_received: bool = false
	biome_c.generation_completed.connect(func() -> void: signal_received = true)
	add_child(biome_c)
	biome_c.generate()
	assert_true(signal_received,
		"generation_completed signal should be emitted after generate()")
	biome_c.queue_free()
