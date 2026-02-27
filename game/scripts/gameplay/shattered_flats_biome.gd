## ShatteredFlatsBiome - Starter biome scene: open terrain with alien ruins, collapsed spire, and resources - Owner: gameplay-programmer
class_name ShatteredFlatsBiome
extends Node3D


# ── Signals ──────────────────────────────────────────────

## Emitted when biome generation completes and all nodes are placed.
signal biome_generated


# ── Constants ─────────────────────────────────────────────

## Fixed terrain seed from BiomeRegistry for deterministic layout.
const TERRAIN_SEED: int = 1001

## Central plateau dimensions — base for collapsed spire landmark.
const PLATEAU_WIDTH: float = 60.0
const PLATEAU_DEPTH: float = 60.0
const PLATEAU_HEIGHT: float = 6.0
const PLATEAU_RAMP_WIDTH: float = 8.0

## Alien ruin clearing radius in metres.
const RUIN_CLEARING_RADIUS: float = 20.0

## Ship spawn clearing radius — flat area for landing.
const SHIP_CLEARING_RADIUS: float = 15.0

## Scrap Metal surface deposit count range.
const SCRAP_METAL_COUNT_MIN: int = 8
const SCRAP_METAL_COUNT_MAX: int = 12

## Cryonite surface deposit count range.
const CRYONITE_COUNT_MIN: int = 3
const CRYONITE_COUNT_MAX: int = 5

## Minimum clearance between resource spawn positions in metres.
const RESOURCE_CLEARANCE: float = 10.0

## Maximum terrain slope for resource placement in degrees.
const RESOURCE_SLOPE_MAX: float = 20.0

## Deep node vertical offset below the corresponding surface node.
const DEEP_NODE_Y_OFFSET: float = -3.0

## Deep node yield rate (10% of surface speed).
const DEEP_NODE_YIELD_RATE: float = 0.1

## Ruin cluster world-space XZ positions (spread across the biome).
const RUIN_POSITIONS: Array[Vector2] = [
	Vector2(150.0, 150.0),
	Vector2(350.0, 120.0),
	Vector2(120.0, 370.0),
]

## Ship spawn position hint — near southern edge of the biome.
const SHIP_SPAWN_HINT: Vector2 = Vector2(250.0, 430.0)

## Player spawn offset from ship (metres in front of ship).
const PLAYER_SPAWN_OFFSET: Vector3 = Vector3(0.0, 0.0, -5.0)

## Collapsed spire dimensions.
const SPIRE_LENGTH: float = 40.0
const SPIRE_BASE_WIDTH: float = 8.0
const SPIRE_BASE_HEIGHT: float = 12.0
const SPIRE_TIP_WIDTH: float = 3.0
const SPIRE_TIP_HEIGHT: float = 5.0

## Scrap Metal mesh path.
const SCRAP_METAL_MESH_PATH: String = "res://assets/meshes/props/mesh_resource_node_scrap.glb"

## Cryonite deposit mesh path.
const CRYONITE_MESH_PATH: String = "res://assets/meshes/cryonite_deposit.glb"


# ── Private Variables ─────────────────────────────────────

## Generator instance used for terrain creation.
var _generator: TerrainGenerator = null

## Generation result containing terrain mesh, collision, and confirmed positions.
var _generation_result: TerrainGenerationResult = null

## World boundary manager node.
var _boundary_manager: WorldBoundaryManager = null

## Container nodes for organization.
var _terrain_node: StaticBody3D = null
var _ruins_container: Node3D = null
var _deposits_container: Node3D = null
var _spawn_points: Node3D = null

## Player spawn marker.
var _player_spawn: Marker3D = null

## Ship spawn marker.
var _ship_spawn: Marker3D = null

## Feature request indices for position lookup.
var _plateau_request_idx: int = -1
var _ship_clearing_request_idx: int = -1
var _ruin_clearing_request_indices: Array[int] = []
var _scrap_metal_spawn_idx: int = -1
var _cryonite_spawn_idx: int = -1

## RNG for deterministic procedural placement.
var _rng: RandomNumberGenerator = null


# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	generate()


# ── Public Methods ────────────────────────────────────────

## Generates the entire Shattered Flats biome: terrain, landmarks, ruins, resources, and spawn points.
func generate() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = TERRAIN_SEED

	# Build feature requests and generate terrain
	var archetype: BiomeArchetypeConfig = BiomeArchetypeConfig.shattered_flats()
	var requests: Array[TerrainFeatureRequest] = _build_feature_requests()

	_generator = TerrainGenerator.new()
	_generation_result = _generator.generate(TERRAIN_SEED, archetype, requests)

	# Create scene hierarchy
	_create_terrain_node()
	_create_boundary_manager(archetype)
	_create_collapsed_spire()
	_create_alien_ruins()
	_create_resource_deposits()
	_create_spawn_points()

	biome_generated.emit()


## Returns the player spawn position in world space.
func get_player_spawn_position() -> Vector3:
	if _player_spawn != null:
		return _player_spawn.global_position
	return Vector3(250.0, 0.0, 425.0)


## Returns the ship spawn position in world space.
func get_ship_spawn_position() -> Vector3:
	if _ship_spawn != null:
		return _ship_spawn.global_position
	return Vector3(250.0, 0.0, 430.0)


## Returns the WorldBoundaryManager instance.
func get_boundary_manager() -> WorldBoundaryManager:
	return _boundary_manager


## Returns the terrain generation result for external systems.
func get_generation_result() -> TerrainGenerationResult:
	return _generation_result


# ── Private Methods: Feature Requests ─────────────────────

## Builds the ordered list of terrain feature requests for the Shattered Flats biome.
func _build_feature_requests() -> Array[TerrainFeatureRequest]:
	var requests: Array[TerrainFeatureRequest] = []
	var idx: int = 0

	# 0: Central plateau — base for the collapsed spire landmark
	var plateau: TerrainFeatureRequest = TerrainFeatureRequest.create_plateau(
		PLATEAU_WIDTH,
		PLATEAU_DEPTH,
		PLATEAU_HEIGHT,
		TerrainFeatureRequest.AccessType.RAMP,
		PLATEAU_RAMP_WIDTH,
		"center"
	)
	requests.append(plateau)
	_plateau_request_idx = idx
	idx += 1

	# 1: Ship spawn clearing — flat area near southern edge
	var ship_clearing: TerrainFeatureRequest = TerrainFeatureRequest.create_clearing(
		SHIP_CLEARING_RADIUS,
		SHIP_SPAWN_HINT
	)
	requests.append(ship_clearing)
	_ship_clearing_request_idx = idx
	idx += 1

	# 2-4: Alien ruin clearings — 3 flat zones for ruin clusters
	_ruin_clearing_request_indices.clear()
	for ruin_pos: Vector2 in RUIN_POSITIONS:
		var ruin_clearing: TerrainFeatureRequest = TerrainFeatureRequest.create_clearing(
			RUIN_CLEARING_RADIUS,
			ruin_pos
		)
		requests.append(ruin_clearing)
		_ruin_clearing_request_indices.append(idx)
		idx += 1

	# 5: Scrap Metal surface spawn positions — scattered across biome
	var scrap_count: int = _rng.randi_range(SCRAP_METAL_COUNT_MIN, SCRAP_METAL_COUNT_MAX)
	var scrap_spawn: TerrainFeatureRequest = TerrainFeatureRequest.create_resource_spawn(
		scrap_count,
		RESOURCE_SLOPE_MAX,
		RESOURCE_CLEARANCE
	)
	requests.append(scrap_spawn)
	_scrap_metal_spawn_idx = idx
	idx += 1

	# 6: Cryonite surface spawn positions — clustered near ruin areas
	var cryo_count: int = _rng.randi_range(CRYONITE_COUNT_MIN, CRYONITE_COUNT_MAX)
	var cryo_spawn: TerrainFeatureRequest = TerrainFeatureRequest.create_resource_spawn(
		cryo_count,
		RESOURCE_SLOPE_MAX,
		RESOURCE_CLEARANCE,
		RUIN_POSITIONS[0]  # Cluster near first ruin site
	)
	requests.append(cryo_spawn)
	_cryonite_spawn_idx = idx
	idx += 1

	return requests


# ── Private Methods: Scene Construction ───────────────────

## Creates the terrain mesh and collision body from generation result.
func _create_terrain_node() -> void:
	_terrain_node = StaticBody3D.new()
	_terrain_node.name = "Terrain"
	_terrain_node.collision_layer = PhysicsLayers.ENVIRONMENT
	_terrain_node.collision_mask = 0

	# Terrain mesh
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = "TerrainMesh"
	mesh_instance.mesh = _generation_result.terrain_mesh

	# Apply a basic grey material for greybox appearance
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.42, 0.38)
	material.roughness = 0.9
	mesh_instance.material_override = material
	_terrain_node.add_child(mesh_instance)

	# Terrain collision
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "TerrainCollision"
	collision.shape = _generation_result.collision_shape
	_terrain_node.add_child(collision)

	add_child(_terrain_node)


## Creates and initializes the world boundary manager.
func _create_boundary_manager(archetype: BiomeArchetypeConfig) -> void:
	_boundary_manager = WorldBoundaryManager.new()
	_boundary_manager.name = "WorldBoundaryManager"
	add_child(_boundary_manager)
	_boundary_manager.initialize(archetype)


## Creates the collapsed spire landmark on the central plateau.
func _create_collapsed_spire() -> void:
	var plateau_positions: Array = _generation_result.confirmed_positions.get(_plateau_request_idx, [])
	if plateau_positions.is_empty():
		return

	var plateau_center: Vector3 = plateau_positions[0]
	var spire_container: Node3D = Node3D.new()
	spire_container.name = "CollapsedSpire"
	spire_container.position = plateau_center

	# Main fallen body — a long box tilted to represent a collapsed structure
	var spire_body: MeshInstance3D = MeshInstance3D.new()
	spire_body.name = "SpireBody"
	var body_mesh: BoxMesh = BoxMesh.new()
	body_mesh.size = Vector3(SPIRE_BASE_WIDTH, SPIRE_BASE_HEIGHT, SPIRE_LENGTH)
	spire_body.mesh = body_mesh
	# Rotate to lie on its side and offset so base sits on the plateau
	spire_body.rotation_degrees = Vector3(0.0, 15.0, 85.0)
	spire_body.position = Vector3(0.0, SPIRE_BASE_HEIGHT * 0.5, 0.0)

	var body_material: StandardMaterial3D = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.3, 0.28, 0.25)
	body_material.roughness = 0.95
	spire_body.material_override = body_material
	spire_container.add_child(spire_body)

	# Tapered tip section
	var spire_tip: MeshInstance3D = MeshInstance3D.new()
	spire_tip.name = "SpireTip"
	var tip_mesh: BoxMesh = BoxMesh.new()
	tip_mesh.size = Vector3(SPIRE_TIP_WIDTH, SPIRE_TIP_HEIGHT, 15.0)
	spire_tip.mesh = tip_mesh
	spire_tip.rotation_degrees = Vector3(0.0, 15.0, 85.0)
	spire_tip.position = Vector3(-18.0, SPIRE_TIP_HEIGHT * 0.3, 5.0)
	spire_tip.material_override = body_material
	spire_container.add_child(spire_tip)

	# Rubble base — scattered box fragments around the impact point
	var rubble_material: StandardMaterial3D = StandardMaterial3D.new()
	rubble_material.albedo_color = Color(0.35, 0.32, 0.28)
	rubble_material.roughness = 0.9

	_add_rubble_piece(spire_container, "Rubble1", Vector3(10.0, 1.5, -8.0), Vector3(4.0, 3.0, 3.5), rubble_material)
	_add_rubble_piece(spire_container, "Rubble2", Vector3(-6.0, 1.0, 12.0), Vector3(3.0, 2.0, 4.0), rubble_material)
	_add_rubble_piece(spire_container, "Rubble3", Vector3(14.0, 0.8, 6.0), Vector3(2.5, 1.6, 2.5), rubble_material)
	_add_rubble_piece(spire_container, "Rubble4", Vector3(-12.0, 1.2, -5.0), Vector3(3.5, 2.4, 3.0), rubble_material)

	# Collision for spire body — static body so player can walk on/around it
	var spire_static: StaticBody3D = StaticBody3D.new()
	spire_static.name = "SpireCollision"
	spire_static.collision_layer = PhysicsLayers.ENVIRONMENT
	spire_static.collision_mask = 0
	spire_static.position = spire_body.position
	spire_static.rotation_degrees = spire_body.rotation_degrees

	var spire_col_shape: CollisionShape3D = CollisionShape3D.new()
	spire_col_shape.name = "CollisionShape3D"
	var spire_box: BoxShape3D = BoxShape3D.new()
	spire_box.size = body_mesh.size
	spire_col_shape.shape = spire_box
	spire_static.add_child(spire_col_shape)
	spire_container.add_child(spire_static)

	add_child(spire_container)


## Creates greybox alien ruin clusters at confirmed clearing positions.
func _create_alien_ruins() -> void:
	_ruins_container = Node3D.new()
	_ruins_container.name = "AlienRuins"
	add_child(_ruins_container)

	for i: int in range(_ruin_clearing_request_indices.size()):
		var req_idx: int = _ruin_clearing_request_indices[i]
		var positions: Array = _generation_result.confirmed_positions.get(req_idx, [])
		if positions.is_empty():
			continue

		var center: Vector3 = positions[0]
		var cluster: Node3D = _build_ruin_cluster(i, center)
		_ruins_container.add_child(cluster)


## Creates resource deposit nodes at confirmed spawn positions.
func _create_resource_deposits() -> void:
	_deposits_container = Node3D.new()
	_deposits_container.name = "Deposits"
	add_child(_deposits_container)

	# Surface Scrap Metal deposits
	var scrap_positions: Array = _generation_result.confirmed_positions.get(_scrap_metal_spawn_idx, [])
	for i: int in range(scrap_positions.size()):
		var pos: Vector3 = scrap_positions[i]
		var deposit: Deposit = _create_deposit(
			"ScrapMetal_Surface_%d" % i,
			ResourceDefs.ResourceType.SCRAP_METAL,
			pos,
			false
		)
		_deposits_container.add_child(deposit)

	# Deep Scrap Metal node — beneath the first surface Scrap Metal position
	if scrap_positions.size() > 0:
		var deep_scrap_pos: Vector3 = scrap_positions[0] + Vector3(0.0, DEEP_NODE_Y_OFFSET, 0.0)
		var deep_scrap: Deposit = _create_deposit(
			"ScrapMetal_Deep_0",
			ResourceDefs.ResourceType.SCRAP_METAL,
			deep_scrap_pos,
			true
		)
		_deposits_container.add_child(deep_scrap)

	# Surface Cryonite deposits
	var cryo_positions: Array = _generation_result.confirmed_positions.get(_cryonite_spawn_idx, [])
	for i: int in range(cryo_positions.size()):
		var pos: Vector3 = cryo_positions[i]
		var deposit: Deposit = _create_deposit(
			"Cryonite_Surface_%d" % i,
			ResourceDefs.ResourceType.CRYONITE,
			pos,
			false
		)
		_deposits_container.add_child(deposit)

	# Deep Cryonite node — beneath the first surface Cryonite position
	if cryo_positions.size() > 0:
		var deep_cryo_pos: Vector3 = cryo_positions[0] + Vector3(0.0, DEEP_NODE_Y_OFFSET, 0.0)
		var deep_cryo: Deposit = _create_deposit(
			"Cryonite_Deep_0",
			ResourceDefs.ResourceType.CRYONITE,
			deep_cryo_pos,
			true
		)
		_deposits_container.add_child(deep_cryo)


## Creates player and ship spawn point markers.
func _create_spawn_points() -> void:
	_spawn_points = Node3D.new()
	_spawn_points.name = "SpawnPoints"
	add_child(_spawn_points)

	# Ship spawn — at the confirmed clearing position
	var ship_positions: Array = _generation_result.confirmed_positions.get(_ship_clearing_request_idx, [])
	var ship_pos: Vector3 = Vector3(SHIP_SPAWN_HINT.x, 0.0, SHIP_SPAWN_HINT.y)
	if not ship_positions.is_empty():
		ship_pos = ship_positions[0]

	_ship_spawn = Marker3D.new()
	_ship_spawn.name = "ShipSpawn"
	_ship_spawn.position = ship_pos
	_spawn_points.add_child(_ship_spawn)

	# Player spawn — offset in front of ship
	_player_spawn = Marker3D.new()
	_player_spawn.name = "PlayerSpawn"
	_player_spawn.position = ship_pos + PLAYER_SPAWN_OFFSET
	_spawn_points.add_child(_player_spawn)


# ── Private Methods: Geometry Builders ────────────────────

## Builds a single ruin cluster with varied-scale greybox geometry.
func _build_ruin_cluster(cluster_index: int, center: Vector3) -> Node3D:
	var cluster: Node3D = Node3D.new()
	cluster.name = "RuinCluster_%d" % cluster_index
	cluster.position = center

	var ruin_material: StandardMaterial3D = StandardMaterial3D.new()
	ruin_material.albedo_color = Color(0.4, 0.38, 0.35)
	ruin_material.roughness = 0.85

	# Scale factor varies per cluster for visual variety
	var scale_factor: float = 1.0 + float(cluster_index) * 0.3

	# Wall fragment A — tall standing section
	var wall_a: MeshInstance3D = _create_box_mesh(
		"WallFragmentA",
		Vector3(6.0 * scale_factor, 4.0 * scale_factor, 1.0),
		Vector3(-3.0, 2.0 * scale_factor, 0.0),
		ruin_material
	)
	wall_a.rotation_degrees.y = 20.0 * float(cluster_index + 1)
	cluster.add_child(wall_a)
	_add_static_collision(cluster, "WallFragmentA_Col", wall_a)

	# Wall fragment B — shorter, angled
	var wall_b: MeshInstance3D = _create_box_mesh(
		"WallFragmentB",
		Vector3(4.0 * scale_factor, 2.5 * scale_factor, 0.8),
		Vector3(5.0, 1.25 * scale_factor, -4.0),
		ruin_material
	)
	wall_b.rotation_degrees = Vector3(0.0, -35.0 + float(cluster_index) * 15.0, 8.0)
	cluster.add_child(wall_b)
	_add_static_collision(cluster, "WallFragmentB_Col", wall_b)

	# Floor slab — broken ground plate
	var floor_slab: MeshInstance3D = _create_box_mesh(
		"FloorSlab",
		Vector3(8.0 * scale_factor, 0.4, 6.0 * scale_factor),
		Vector3(1.0, 0.2, 2.0),
		ruin_material
	)
	cluster.add_child(floor_slab)
	_add_static_collision(cluster, "FloorSlab_Col", floor_slab)

	# Pillar stump — broken column base
	var pillar: MeshInstance3D = MeshInstance3D.new()
	pillar.name = "PillarStump"
	var cylinder_mesh: CylinderMesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.6 * scale_factor
	cylinder_mesh.bottom_radius = 0.8 * scale_factor
	cylinder_mesh.height = 3.0 * scale_factor
	pillar.mesh = cylinder_mesh
	pillar.position = Vector3(-6.0, 1.5 * scale_factor, -3.0)
	pillar.material_override = ruin_material
	cluster.add_child(pillar)

	# Pillar collision
	var pillar_static: StaticBody3D = StaticBody3D.new()
	pillar_static.name = "PillarStump_Col"
	pillar_static.collision_layer = PhysicsLayers.ENVIRONMENT
	pillar_static.collision_mask = 0
	pillar_static.position = pillar.position
	var pillar_col: CollisionShape3D = CollisionShape3D.new()
	pillar_col.name = "CollisionShape3D"
	var pillar_shape: CylinderShape3D = CylinderShape3D.new()
	pillar_shape.radius = 0.8 * scale_factor
	pillar_shape.height = 3.0 * scale_factor
	pillar_col.shape = pillar_shape
	pillar_static.add_child(pillar_col)
	cluster.add_child(pillar_static)

	# Scattered debris blocks
	_add_rubble_piece(cluster, "Debris1", Vector3(3.0, 0.4, -6.0), Vector3(1.5, 0.8, 1.2) * scale_factor, ruin_material)
	_add_rubble_piece(cluster, "Debris2", Vector3(-4.0, 0.3, 5.0), Vector3(1.0, 0.6, 1.8) * scale_factor, ruin_material)

	return cluster


## Creates a Deposit node configured for the biome.
func _create_deposit(
	deposit_name: String,
	resource_type: ResourceDefs.ResourceType,
	world_position: Vector3,
	is_deep: bool
) -> Deposit:
	var deposit: Deposit = Deposit.new()
	deposit.name = deposit_name

	# Determine purity and density using deterministic RNG
	var purity: ResourceDefs.Purity = _random_purity()
	var density: ResourceDefs.DensityTier = _random_density()
	var quantity_range: Vector2i = ResourceDefs.DENSITY_QUANTITY_RANGES.get(
		density, Vector2i(10, 25)
	)
	var quantity: int = _rng.randi_range(quantity_range.x, quantity_range.y)

	deposit.setup(resource_type, purity, density, quantity)
	deposit.position = world_position

	if is_deep:
		deposit.infinite = true
		deposit.yield_rate = DEEP_NODE_YIELD_RATE

	# Add visual mesh
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = "DepositMesh"
	var mesh_path: String = SCRAP_METAL_MESH_PATH if resource_type == ResourceDefs.ResourceType.SCRAP_METAL else CRYONITE_MESH_PATH
	var mesh_resource: Resource = load(mesh_path)
	if mesh_resource is PackedScene:
		# GLB files load as PackedScene — instantiate and reparent the mesh
		var scene_instance: Node3D = (mesh_resource as PackedScene).instantiate()
		scene_instance.name = "DepositMesh"
		deposit.add_child(scene_instance)
	else:
		deposit.add_child(mesh_instance)

	# Add scan area (Area3D with sphere for scanner detection)
	var scan_area: Area3D = Area3D.new()
	scan_area.name = "ScanArea"
	scan_area.collision_layer = PhysicsLayers.INTERACTABLE
	scan_area.collision_mask = 0
	var scan_col: CollisionShape3D = CollisionShape3D.new()
	scan_col.name = "CollisionShape3D"
	var scan_sphere: SphereShape3D = SphereShape3D.new()
	scan_sphere.radius = 8.0
	scan_col.shape = scan_sphere
	scan_area.add_child(scan_col)
	deposit.add_child(scan_area)

	# Add deposit collision body
	var deposit_body: StaticBody3D = StaticBody3D.new()
	deposit_body.name = "DepositBody"
	deposit_body.collision_layer = PhysicsLayers.INTERACTABLE
	deposit_body.collision_mask = 0
	var deposit_col: CollisionShape3D = CollisionShape3D.new()
	deposit_col.name = "DepositCollision"
	var deposit_box: BoxShape3D = BoxShape3D.new()
	deposit_box.size = Vector3(1.5, 1.5, 1.5)
	deposit_col.shape = deposit_box
	deposit_body.add_child(deposit_col)
	deposit.add_child(deposit_body)

	# Add to appropriate group
	deposit.add_to_group("interactable")

	return deposit


## Creates a box MeshInstance3D with the given parameters.
func _create_box_mesh(
	mesh_name: String,
	box_size: Vector3,
	pos: Vector3,
	material: StandardMaterial3D
) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var box: BoxMesh = BoxMesh.new()
	box.size = box_size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.material_override = material
	return mesh_instance


## Adds a rubble piece (box mesh) to a parent node.
func _add_rubble_piece(
	parent: Node3D,
	piece_name: String,
	pos: Vector3,
	box_size: Vector3,
	material: StandardMaterial3D
) -> void:
	var piece: MeshInstance3D = _create_box_mesh(piece_name, box_size, pos, material)
	# Slight random rotation for natural look (deterministic via _rng)
	piece.rotation_degrees.y = _rng.randf_range(-30.0, 30.0)
	parent.add_child(piece)


## Adds a StaticBody3D collision matching a MeshInstance3D's box mesh to a parent.
func _add_static_collision(parent: Node3D, col_name: String, source_mesh: MeshInstance3D) -> void:
	var static_body: StaticBody3D = StaticBody3D.new()
	static_body.name = col_name
	static_body.collision_layer = PhysicsLayers.ENVIRONMENT
	static_body.collision_mask = 0
	static_body.position = source_mesh.position
	static_body.rotation_degrees = source_mesh.rotation_degrees

	var col_shape: CollisionShape3D = CollisionShape3D.new()
	col_shape.name = "CollisionShape3D"
	var box_shape: BoxShape3D = BoxShape3D.new()
	if source_mesh.mesh is BoxMesh:
		box_shape.size = (source_mesh.mesh as BoxMesh).size
	col_shape.shape = box_shape
	static_body.add_child(col_shape)
	parent.add_child(static_body)


# ── Private Methods: Random Distributions ─────────────────

## Returns a random purity using Tier 1 biome distribution (biased toward low stars).
func _random_purity() -> ResourceDefs.Purity:
	var roll: float = _rng.randf()
	if roll < 0.30:
		return ResourceDefs.Purity.ONE_STAR
	elif roll < 0.60:
		return ResourceDefs.Purity.TWO_STAR
	elif roll < 0.85:
		return ResourceDefs.Purity.THREE_STAR
	elif roll < 0.95:
		return ResourceDefs.Purity.FOUR_STAR
	else:
		return ResourceDefs.Purity.FIVE_STAR


## Returns a random density tier with even distribution.
func _random_density() -> ResourceDefs.DensityTier:
	var roll: int = _rng.randi_range(0, 2)
	return roll as ResourceDefs.DensityTier
