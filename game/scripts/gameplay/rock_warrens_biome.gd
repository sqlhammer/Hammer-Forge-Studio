## Rock Warrens biome — dense rock formations creating tight navigable corridors
## with low visibility. Mixed resource profile: Scrap Metal and Cryonite pockets.
## Must contain sufficient resources to craft at least one Fuel Cell.
## Owner: gameplay-programmer
class_name RockWarrensBiome
extends Node3D


# ── Signals ──────────────────────────────────────────────

signal generation_completed


# ── Constants ─────────────────────────────────────────────

## Fixed seed for deterministic terrain generation (from BiomeRegistry).
const BIOME_SEED: int = 2047

## Terrain extent in metres.
const TERRAIN_SIZE: float = 500.0

## Ship/player spawn clearing radius in metres.
const SHIP_CLEARING_RADIUS: float = 20.0

## Walkable clearance radius around resource positions in metres.
const RESOURCE_CLEARANCE_RADIUS: float = 3.0

## Maximum terrain slope for resource placement (degrees).
const RESOURCE_SLOPE_MAX: float = 30.0

## Minimum spacing between resource positions (metres).
const RESOURCE_SPACING: float = 15.0

## Scrap Metal surface deposit count range per acceptance criteria.
const SCRAP_METAL_SURFACE_MIN: int = 5
const SCRAP_METAL_SURFACE_MAX: int = 8

## Cryonite surface deposit count range per acceptance criteria.
const CRYONITE_SURFACE_MIN: int = 4
const CRYONITE_SURFACE_MAX: int = 7

## Number of deep nodes per resource type.
const DEEP_NODES_PER_TYPE: int = 1

## Deep node quantity — high value; infinite flag means it never depletes.
const DEEP_NODE_QUANTITY: int = 100

## Surface deposit quantity range.
const SURFACE_NODE_MIN_QUANTITY: int = 15
const SURFACE_NODE_MAX_QUANTITY: int = 40

## Deep node yield rate multiplier (10% of surface speed).
const DEEP_NODE_YIELD_RATE: float = 0.1

## Rock formation grid spacing — metres between formation placement checks.
const FORMATION_GRID_SPACING: float = 12.0

## Exclusion radius around spawn and resource positions — no formations placed here.
const FORMATION_EXCLUSION_RADIUS: float = 6.0

## Rock formation height range (metres).
const MIN_FORMATION_HEIGHT: float = 6.0
const MAX_FORMATION_HEIGHT: float = 18.0

## Rock formation width range (metres).
const MIN_FORMATION_WIDTH: float = 2.0
const MAX_FORMATION_WIDTH: float = 6.0

## Probability of placing a formation at a valid grid point.
const FORMATION_DENSITY: float = 0.65

## Margin from terrain edges for formation placement (metres).
const FORMATION_EDGE_MARGIN: float = 30.0

## Player spawn offset from ship spawn (metres).
const PLAYER_SPAWN_OFFSET: Vector3 = Vector3(5.0, 0.0, 5.0)

## Margin from terrain edges for resource placement (metres).
const RESOURCE_EDGE_MARGIN: float = 50.0

## RNG seed offsets for independent deterministic sequences.
const RNG_OFFSET_FORMATIONS: int = 7919
const RNG_OFFSET_DEPOSITS: int = 3571


# ── Private Variables ─────────────────────────────────────

var _terrain_result: TerrainGenerationResult = null
var _archetype: BiomeArchetypeConfig = null
var _player_spawn_position: Vector3 = Vector3.ZERO
var _ship_spawn_position: Vector3 = Vector3.ZERO
var _rock_formation_count: int = 0

## Pre-computed resource positions (Vector3 with Y from heightmap).
var _scrap_metal_surface_positions: Array[Vector3] = []
var _cryonite_surface_positions: Array[Vector3] = []
var _deep_scrap_metal_positions: Array[Vector3] = []
var _deep_cryonite_positions: Array[Vector3] = []

## Per-deposit quantities for fuel cell sufficiency tracking.
var _surface_scrap_metal_quantities: Array[int] = []
var _surface_cryonite_quantities: Array[int] = []


# ── Public Methods ────────────────────────────────────────

## Returns the fixed seed used for this biome.
func get_biome_seed() -> int:
	return BIOME_SEED


## Returns the biome archetype configuration.
func get_archetype() -> BiomeArchetypeConfig:
	return _archetype


## Returns the terrain generation result.
func get_terrain_result() -> TerrainGenerationResult:
	return _terrain_result


## Returns the player spawn world position.
func get_player_spawn_position() -> Vector3:
	return _player_spawn_position


## Returns the ship spawn world position.
func get_ship_spawn_position() -> Vector3:
	return _ship_spawn_position


## Returns the number of Scrap Metal surface deposit nodes.
func get_scrap_metal_surface_count() -> int:
	return _scrap_metal_surface_positions.size()


## Returns the number of Cryonite surface deposit nodes.
func get_cryonite_surface_count() -> int:
	return _cryonite_surface_positions.size()


## Returns the number of deep Scrap Metal nodes.
func get_deep_scrap_metal_count() -> int:
	return _deep_scrap_metal_positions.size()


## Returns the number of deep Cryonite nodes.
func get_deep_cryonite_count() -> int:
	return _deep_cryonite_positions.size()


## Returns the count of rock formations placed in the biome.
func get_rock_formation_count() -> int:
	return _rock_formation_count


## Returns the total extractable Scrap Metal quantity across all surface and deep deposits.
func get_total_scrap_metal_quantity() -> int:
	var total: int = 0
	for qty: int in _surface_scrap_metal_quantities:
		total += qty
	# Deep nodes contribute their nominal quantity
	total += _deep_scrap_metal_positions.size() * DEEP_NODE_QUANTITY
	return total


## Returns the total extractable Cryonite quantity across all surface and deep deposits.
func get_total_cryonite_quantity() -> int:
	var total: int = 0
	for qty: int in _surface_cryonite_quantities:
		total += qty
	total += _deep_cryonite_positions.size() * DEEP_NODE_QUANTITY
	return total


## Generates the entire Rock Warrens biome: terrain, rock formations,
## resource deposits, spawn points, and world boundary.
func generate() -> void:
	_archetype = BiomeArchetypeConfig.rock_warrens()

	# Pre-compute resource positions using seeded RNG
	var position_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	position_rng.seed = BIOME_SEED
	_precompute_resource_positions(position_rng)

	# Build feature requests and generate terrain
	var requests: Array[TerrainFeatureRequest] = _build_feature_requests()
	var generator: TerrainGenerator = TerrainGenerator.new()
	_terrain_result = generator.generate(BIOME_SEED, _archetype, requests)

	# Update positions with confirmed terrain heights
	_update_positions_from_result()

	# Build visual scene
	_build_terrain_mesh()
	_build_rock_formations()
	_place_deposits()
	_create_spawn_points()
	_setup_world_boundary()

	Global.log("RockWarrensBiome: generation complete — %d formations, %d scrap deposits, %d cryonite deposits" % [
		_rock_formation_count,
		get_scrap_metal_surface_count() + get_deep_scrap_metal_count(),
		get_cryonite_surface_count() + get_deep_cryonite_count(),
	])
	generation_completed.emit()


# ── Private Methods: Position Pre-computation ────────────

## Pre-computes resource node positions using a seeded RNG for deterministic layout.
## Positions are distributed across the biome with minimum spacing between them.
func _precompute_resource_positions(rng: RandomNumberGenerator) -> void:
	var all_positions: Array[Vector2] = []
	var usable_min: float = RESOURCE_EDGE_MARGIN
	var usable_max: float = TERRAIN_SIZE - RESOURCE_EDGE_MARGIN

	# Determine counts from seeded RNG for deterministic variability
	var scrap_count: int = rng.randi_range(SCRAP_METAL_SURFACE_MIN, SCRAP_METAL_SURFACE_MAX)
	var cryo_count: int = rng.randi_range(CRYONITE_SURFACE_MIN, CRYONITE_SURFACE_MAX)

	# Scrap Metal surface positions
	for i: int in range(scrap_count):
		var pos: Vector2 = _find_valid_position(rng, all_positions, usable_min, usable_max)
		all_positions.append(pos)
		_scrap_metal_surface_positions.append(Vector3(pos.x, 0.0, pos.y))

	# Cryonite surface positions
	for i: int in range(cryo_count):
		var pos: Vector2 = _find_valid_position(rng, all_positions, usable_min, usable_max)
		all_positions.append(pos)
		_cryonite_surface_positions.append(Vector3(pos.x, 0.0, pos.y))

	# Deep Scrap Metal positions
	for i: int in range(DEEP_NODES_PER_TYPE):
		var pos: Vector2 = _find_valid_position(rng, all_positions, usable_min, usable_max)
		all_positions.append(pos)
		_deep_scrap_metal_positions.append(Vector3(pos.x, 0.0, pos.y))

	# Deep Cryonite positions
	for i: int in range(DEEP_NODES_PER_TYPE):
		var pos: Vector2 = _find_valid_position(rng, all_positions, usable_min, usable_max)
		all_positions.append(pos)
		_deep_cryonite_positions.append(Vector3(pos.x, 0.0, pos.y))


## Finds a valid XZ position spaced away from existing positions.
func _find_valid_position(
	rng: RandomNumberGenerator,
	existing: Array[Vector2],
	pos_min: float,
	pos_max: float
) -> Vector2:
	var max_attempts: int = 100
	for attempt: int in range(max_attempts):
		var candidate: Vector2 = Vector2(
			rng.randf_range(pos_min, pos_max),
			rng.randf_range(pos_min, pos_max)
		)
		var too_close: bool = false
		for other: Vector2 in existing:
			if candidate.distance_to(other) < RESOURCE_SPACING:
				too_close = true
				break
		if not too_close:
			return candidate
	# Fallback — return a random position if spacing can't be satisfied
	return Vector2(rng.randf_range(pos_min, pos_max), rng.randf_range(pos_min, pos_max))


# ── Private Methods: Feature Requests ────────────────────

## Builds the array of TerrainFeatureRequests for terrain generation.
## Request 0: clearing at edge for ship spawn.
## Requests 1..N: walkable clearance around each resource position.
func _build_feature_requests() -> Array[TerrainFeatureRequest]:
	var requests: Array[TerrainFeatureRequest] = []

	# Request 0: Ship/player spawn clearing near the biome edge
	requests.append(TerrainFeatureRequest.create_clearing(SHIP_CLEARING_RADIUS, "edge"))

	# Walkable clearance around every resource position to guarantee reachability
	var all_resource_positions: Array[Vector3] = []
	all_resource_positions.append_array(_scrap_metal_surface_positions)
	all_resource_positions.append_array(_cryonite_surface_positions)
	all_resource_positions.append_array(_deep_scrap_metal_positions)
	all_resource_positions.append_array(_deep_cryonite_positions)

	for pos: Vector3 in all_resource_positions:
		var clearance_position: Vector2 = Vector2(pos.x, pos.z)
		requests.append(
			TerrainFeatureRequest.create_walkable_clearance(clearance_position, RESOURCE_CLEARANCE_RADIUS)
		)

	return requests


# ── Private Methods: Position Update ─────────────────────

## Updates pre-computed resource positions with actual terrain heights from the
## generation result's confirmed positions.
func _update_positions_from_result() -> void:
	if _terrain_result == null:
		return

	# Request 0 is the clearing — extract spawn position
	if _terrain_result.confirmed_positions.has(0):
		var clearing_positions: Array = _terrain_result.confirmed_positions[0]
		if clearing_positions.size() > 0:
			var clearing_center: Vector3 = clearing_positions[0]
			_ship_spawn_position = clearing_center
			_player_spawn_position = clearing_center + PLAYER_SPAWN_OFFSET

	# Requests 1..N are walkable clearances — update Y heights in order
	var request_index: int = 1

	for i: int in range(_scrap_metal_surface_positions.size()):
		if _terrain_result.confirmed_positions.has(request_index):
			var positions: Array = _terrain_result.confirmed_positions[request_index]
			if positions.size() > 0:
				_scrap_metal_surface_positions[i] = positions[0]
		request_index += 1

	for i: int in range(_cryonite_surface_positions.size()):
		if _terrain_result.confirmed_positions.has(request_index):
			var positions: Array = _terrain_result.confirmed_positions[request_index]
			if positions.size() > 0:
				_cryonite_surface_positions[i] = positions[0]
		request_index += 1

	for i: int in range(_deep_scrap_metal_positions.size()):
		if _terrain_result.confirmed_positions.has(request_index):
			var positions: Array = _terrain_result.confirmed_positions[request_index]
			if positions.size() > 0:
				_deep_scrap_metal_positions[i] = positions[0]
		request_index += 1

	for i: int in range(_deep_cryonite_positions.size()):
		if _terrain_result.confirmed_positions.has(request_index):
			var positions: Array = _terrain_result.confirmed_positions[request_index]
			if positions.size() > 0:
				_deep_cryonite_positions[i] = positions[0]
		request_index += 1


# ── Private Methods: Scene Construction ──────────────────

## Creates the terrain visual mesh and collision body from the generation result.
func _build_terrain_mesh() -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = "TerrainMesh"
	mesh_instance.mesh = _terrain_result.terrain_mesh
	add_child(mesh_instance)

	var static_body: StaticBody3D = StaticBody3D.new()
	static_body.name = "TerrainCollision"
	static_body.collision_layer = PhysicsLayers.ENVIRONMENT
	static_body.collision_mask = 0

	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	collision_shape.shape = _terrain_result.collision_shape
	static_body.add_child(collision_shape)
	add_child(static_body)


## Places rock formations (CSGBox3D stacks) across the biome, avoiding cleared zones.
## Formations create tight corridors with short sight lines between navigable areas.
func _build_rock_formations() -> void:
	var formations_parent: Node3D = Node3D.new()
	formations_parent.name = "RockFormations"
	add_child(formations_parent)

	var formation_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	formation_rng.seed = BIOME_SEED + RNG_OFFSET_FORMATIONS

	# Build exclusion zones from spawn clearing and resource positions
	var exclusion_zones: Array[Vector2] = _get_exclusion_zones()

	# Place formations on a grid with randomized offset and density filtering
	var grid_start: float = FORMATION_EDGE_MARGIN
	var grid_end: float = TERRAIN_SIZE - FORMATION_EDGE_MARGIN
	var x: float = grid_start

	while x < grid_end:
		var z: float = grid_start
		while z < grid_end:
			var offset_x: float = formation_rng.randf_range(-3.0, 3.0)
			var offset_z: float = formation_rng.randf_range(-3.0, 3.0)
			var world_x: float = clampf(x + offset_x, grid_start, grid_end)
			var world_z: float = clampf(z + offset_z, grid_start, grid_end)

			# Skip if inside an exclusion zone
			var excluded: bool = false
			var candidate_2d: Vector2 = Vector2(world_x, world_z)
			for zone: Vector2 in exclusion_zones:
				if candidate_2d.distance_to(zone) < FORMATION_EXCLUSION_RADIUS:
					excluded = true
					break

			# Density filtering — skip some grid points for corridor variety
			if not excluded and formation_rng.randf() < FORMATION_DENSITY:
				var terrain_y: float = _get_terrain_height(world_x, world_z)
				var formation: Node3D = _create_rock_formation(
					formation_rng, world_x, terrain_y, world_z
				)
				formations_parent.add_child(formation)
				_rock_formation_count += 1

			z += FORMATION_GRID_SPACING
		x += FORMATION_GRID_SPACING


## Returns exclusion zones (XZ positions) where rock formations must not be placed.
func _get_exclusion_zones() -> Array[Vector2]:
	var zones: Array[Vector2] = []

	# Ship spawn clearing
	zones.append(Vector2(_ship_spawn_position.x, _ship_spawn_position.z))

	# All resource positions
	for pos: Vector3 in _scrap_metal_surface_positions:
		zones.append(Vector2(pos.x, pos.z))
	for pos: Vector3 in _cryonite_surface_positions:
		zones.append(Vector2(pos.x, pos.z))
	for pos: Vector3 in _deep_scrap_metal_positions:
		zones.append(Vector2(pos.x, pos.z))
	for pos: Vector3 in _deep_cryonite_positions:
		zones.append(Vector2(pos.x, pos.z))

	return zones


## Creates a single rock formation node with 1–3 stacked CSGBox3D blocks.
func _create_rock_formation(
	formation_rng: RandomNumberGenerator,
	world_x: float,
	terrain_y: float,
	world_z: float
) -> Node3D:
	var formation: Node3D = Node3D.new()
	formation.name = "RockFormation_%04d" % _rock_formation_count
	formation.position = Vector3(world_x, terrain_y, world_z)

	var stack_count: int = formation_rng.randi_range(1, 3)
	var current_y: float = 0.0

	for i: int in range(stack_count):
		var block: CSGBox3D = CSGBox3D.new()
		block.name = "Block_%d" % i

		var block_width: float = formation_rng.randf_range(MIN_FORMATION_WIDTH, MAX_FORMATION_WIDTH)
		var per_block_min: float = MIN_FORMATION_HEIGHT / float(stack_count)
		var per_block_max: float = MAX_FORMATION_HEIGHT / float(stack_count)
		var block_height: float = formation_rng.randf_range(per_block_min, per_block_max)
		var block_depth: float = formation_rng.randf_range(MIN_FORMATION_WIDTH, MAX_FORMATION_WIDTH)

		block.size = Vector3(block_width, block_height, block_depth)
		block.position = Vector3(0.0, current_y + block_height * 0.5, 0.0)
		# Slight yaw rotation for natural rocky appearance
		block.rotation.y = formation_rng.randf_range(-0.3, 0.3)
		block.use_collision = true

		formation.add_child(block)
		current_y += block_height

	return formation


## Places deposit nodes at confirmed resource positions.
func _place_deposits() -> void:
	var deposits_parent: Node3D = Node3D.new()
	deposits_parent.name = "Deposits"
	add_child(deposits_parent)

	var deposit_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	deposit_rng.seed = BIOME_SEED + RNG_OFFSET_DEPOSITS

	# Place Scrap Metal surface deposits
	_surface_scrap_metal_quantities.clear()
	for i: int in range(_scrap_metal_surface_positions.size()):
		var pos: Vector3 = _scrap_metal_surface_positions[i]
		var quantity: int = deposit_rng.randi_range(SURFACE_NODE_MIN_QUANTITY, SURFACE_NODE_MAX_QUANTITY)
		_surface_scrap_metal_quantities.append(quantity)
		var deposit: Deposit = _create_deposit(
			ResourceDefs.ResourceType.SCRAP_METAL,
			quantity,
			pos,
			false,
			"ScrapMetal_%d" % i
		)
		deposits_parent.add_child(deposit)

	# Place Cryonite surface deposits
	_surface_cryonite_quantities.clear()
	for i: int in range(_cryonite_surface_positions.size()):
		var pos: Vector3 = _cryonite_surface_positions[i]
		var quantity: int = deposit_rng.randi_range(SURFACE_NODE_MIN_QUANTITY, SURFACE_NODE_MAX_QUANTITY)
		_surface_cryonite_quantities.append(quantity)
		var deposit: Deposit = _create_deposit(
			ResourceDefs.ResourceType.CRYONITE,
			quantity,
			pos,
			false,
			"Cryonite_%d" % i
		)
		deposits_parent.add_child(deposit)

	# Place deep Scrap Metal nodes
	for i: int in range(_deep_scrap_metal_positions.size()):
		var pos: Vector3 = _deep_scrap_metal_positions[i]
		var deposit: Deposit = _create_deposit(
			ResourceDefs.ResourceType.SCRAP_METAL,
			DEEP_NODE_QUANTITY,
			pos,
			true,
			"DeepScrapMetal_%d" % i
		)
		deposits_parent.add_child(deposit)

	# Place deep Cryonite nodes
	for i: int in range(_deep_cryonite_positions.size()):
		var pos: Vector3 = _deep_cryonite_positions[i]
		var deposit: Deposit = _create_deposit(
			ResourceDefs.ResourceType.CRYONITE,
			DEEP_NODE_QUANTITY,
			pos,
			true,
			"DeepCryonite_%d" % i
		)
		deposits_parent.add_child(deposit)


## Creates a single deposit node configured for the given resource type and position.
func _create_deposit(
	resource_type: ResourceDefs.ResourceType,
	quantity: int,
	world_position: Vector3,
	is_deep: bool,
	deposit_name: String
) -> Deposit:
	var deposit: Deposit = Deposit.new()
	deposit.name = deposit_name
	deposit.setup(
		resource_type,
		ResourceDefs.Purity.THREE_STAR,
		ResourceDefs.DensityTier.MEDIUM,
		quantity
	)
	deposit.position = world_position

	if is_deep:
		deposit.infinite = true
		deposit.yield_rate = DEEP_NODE_YIELD_RATE
		deposit.add_to_group("deep_deposit")
	else:
		deposit.add_to_group("surface_deposit")

	deposit.add_to_group("interactable")
	return deposit


## Creates Marker3D nodes for player and ship spawn points.
func _create_spawn_points() -> void:
	var player_marker: Marker3D = Marker3D.new()
	player_marker.name = "PlayerSpawnPoint"
	player_marker.position = _player_spawn_position
	add_child(player_marker)

	var ship_marker: Marker3D = Marker3D.new()
	ship_marker.name = "ShipSpawnPoint"
	ship_marker.position = _ship_spawn_position
	add_child(ship_marker)


## Sets up the world boundary manager with invisible walls.
func _setup_world_boundary() -> void:
	var boundary: WorldBoundaryManager = WorldBoundaryManager.new()
	boundary.name = "WorldBoundaryManager"
	add_child(boundary)
	boundary.initialize(_archetype)


# ── Private Methods: Helpers ─────────────────────────────

## Gets the terrain height at a world XZ position by sampling the heightmap.
func _get_terrain_height(world_x: float, world_z: float) -> float:
	if _terrain_result == null or _terrain_result.heightmap.is_empty():
		return 0.0
	var resolution: int = _terrain_result.heightmap_resolution
	var spacing: float = TERRAIN_SIZE / float(resolution - 1)
	var xi: int = clampi(roundi(world_x / spacing), 0, resolution - 1)
	var zi: int = clampi(roundi(world_z / spacing), 0, resolution - 1)
	return _terrain_result.heightmap[zi * resolution + xi]
