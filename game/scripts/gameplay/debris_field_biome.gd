## Debris Field biome — scattered wreckage clusters on uneven ground. Cryonite-heavy
## with low Scrap Metal, making it the primary biome for fuel farming. Generates terrain
## using TerrainGenerator with the debris_field archetype (seed 3317), places greybox
## wreckage clusters, and distributes resource deposits at confirmed positions.
## Owner: gameplay-programmer
class_name DebrisFieldBiome
extends Node3D


# ── Constants ─────────────────────────────────────────────

## Terrain seed from BiomeRegistry for the debris_field biome.
const BIOME_SEED: int = 3317

## Number of surface Scrap Metal deposits to place.
const SCRAP_METAL_SURFACE_COUNT: int = 3

## Number of surface Cryonite deposits to place.
const CRYONITE_SURFACE_COUNT: int = 8

## Number of deep Cryonite deposits.
const DEEP_CRYONITE_COUNT: int = 2

## Number of deep Scrap Metal deposits.
const DEEP_SCRAP_METAL_COUNT: int = 1

## Number of wreckage clusters to place across the terrain.
const WRECKAGE_CLUSTER_COUNT: int = 6

## Ship spawn clearing radius in metres.
const SHIP_CLEARING_RADIUS: float = 25.0

## Y offset below surface for deep resource nodes.
const DEEP_NODE_Y_OFFSET: float = -2.0

## Slow extraction rate for deep resource nodes.
const DEEP_NODE_YIELD_RATE: float = 0.1

## Base quantity for surface deposits.
const SURFACE_DEPOSIT_QUANTITY: int = 40

## Base quantity for deep deposits (infinite, but quantity used for display).
const DEEP_DEPOSIT_QUANTITY: int = 100

## Clearance between resource spawn positions in metres.
const RESOURCE_CLEARANCE: float = 15.0

## Maximum slope for resource placement in degrees.
const RESOURCE_SLOPE_MAX: float = 30.0

## Player spawn offset from ship spawn in metres (Z axis).
const PLAYER_SPAWN_OFFSET: float = 8.0

## Visual scale for scrap metal deposit meshes.
const DEPOSIT_VISUAL_SCALE := Vector3(3.2, 3.2, 3.2)

## Visual scale for cryonite deposit meshes.
const CRYONITE_VISUAL_SCALE := Vector3(3.5, 3.5, 3.5)

## Visual scale for deep cryonite deposit meshes (larger pressurized formation).
const DEEP_CRYONITE_VISUAL_SCALE := Vector3(5.0, 5.0, 5.0)

## Collision radius for deposit interaction bodies.
const DEPOSIT_COLLISION_RADIUS: float = 1.5


# ── Private Variables ─────────────────────────────────────

## Biome archetype configuration for terrain generation.
var _archetype: BiomeArchetypeConfig = null

## Terrain generation result containing mesh, collision, and confirmed positions.
var _terrain_result: TerrainGenerationResult = null

## Feature requests submitted to the terrain generator.
var _feature_requests: Array[TerrainFeatureRequest] = []

## Surface deposit metadata (dictionaries with resource_type, position, etc.).
var _surface_deposits: Array[Dictionary] = []

## Deep deposit metadata.
var _deep_deposits: Array[Dictionary] = []

## World-space positions of wreckage clusters.
var _wreckage_cluster_positions: Array[Vector3] = []

## Ship spawn point in world space.
var _ship_spawn_point: Vector3 = Vector3.ZERO

## Player spawn point in world space.
var _player_spawn_point: Vector3 = Vector3.ZERO

## Whether the world boundary has been initialized.
var _boundary_active: bool = false

## Reference to the world boundary manager node.
var _boundary_manager: WorldBoundaryManager = null

## Request index tracking for feature request results.
var _clearing_request_index: int = -1
var _scrap_spawn_request_index: int = -1
var _cryonite_spawn_request_index: int = -1
var _wreckage_spawn_request_index: int = -1


# ── Built-in Virtual Methods ──────────────────────────────

func _init() -> void:
	_archetype = BiomeArchetypeConfig.debris_field()
	_generate_terrain()
	_resolve_spawn_points()
	_resolve_wreckage_positions()
	_resolve_surface_deposits()
	_resolve_deep_deposits()


# ── Public Methods ────────────────────────────────────────

## Returns the biome archetype configuration.
func get_archetype() -> BiomeArchetypeConfig:
	return _archetype


## Returns the terrain seed used for generation.
func get_terrain_seed() -> int:
	return BIOME_SEED


## Returns the terrain generation result.
func get_terrain_result() -> TerrainGenerationResult:
	return _terrain_result


## Returns the number of wreckage clusters.
func get_wreckage_cluster_count() -> int:
	return _wreckage_cluster_positions.size()


## Returns the world-space positions of all wreckage clusters.
func get_wreckage_cluster_positions() -> Array[Vector3]:
	return _wreckage_cluster_positions


## Returns metadata for all surface deposits.
func get_surface_deposits() -> Array[Dictionary]:
	return _surface_deposits


## Returns metadata for all deep deposits.
func get_deep_deposits() -> Array[Dictionary]:
	return _deep_deposits


## Returns the ship spawn point.
func get_ship_spawn_point() -> Vector3:
	return _ship_spawn_point


## Returns the player spawn point.
func get_player_spawn_point() -> Vector3:
	return _player_spawn_point


## Returns whether the world boundary is active.
func is_world_boundary_active() -> bool:
	return _boundary_active


## Returns the list of feature requests submitted to the generator.
func get_feature_requests() -> Array[TerrainFeatureRequest]:
	return _feature_requests


## Builds the full biome scene — terrain mesh, collision, wreckage geometry,
## resource deposits, and world boundary. Call this when adding the biome to the scene tree.
func build_scene() -> void:
	_build_terrain_mesh()
	_build_wreckage_clusters()
	_build_deposits()
	_build_world_boundary()


# ── Private Methods: Terrain Generation ───────────────────

## Generates terrain using the debris_field archetype and submits feature requests.
func _generate_terrain() -> void:
	var generator: TerrainGenerator = TerrainGenerator.new()

	# Build feature requests
	_feature_requests.clear()

	# Ship spawn clearing near the terrain edge
	var ship_hint: Vector2 = Vector2(80.0, 250.0)
	var clearing_request: TerrainFeatureRequest = TerrainFeatureRequest.create_clearing(
		SHIP_CLEARING_RADIUS, ship_hint
	)
	_clearing_request_index = _feature_requests.size()
	_feature_requests.append(clearing_request)

	# Scrap Metal surface resource spawns (2-4, sparse)
	var scrap_spawn: TerrainFeatureRequest = TerrainFeatureRequest.create_resource_spawn(
		SCRAP_METAL_SURFACE_COUNT, RESOURCE_SLOPE_MAX, RESOURCE_CLEARANCE
	)
	_scrap_spawn_request_index = _feature_requests.size()
	_feature_requests.append(scrap_spawn)

	# Cryonite surface resource spawns (7-10, high concentration)
	var cryonite_spawn: TerrainFeatureRequest = TerrainFeatureRequest.create_resource_spawn(
		CRYONITE_SURFACE_COUNT, RESOURCE_SLOPE_MAX, RESOURCE_CLEARANCE
	)
	_cryonite_spawn_request_index = _feature_requests.size()
	_feature_requests.append(cryonite_spawn)

	# Wreckage cluster positions — scattered across the terrain
	var wreckage_spawn: TerrainFeatureRequest = TerrainFeatureRequest.create_resource_spawn(
		WRECKAGE_CLUSTER_COUNT, 40.0, 30.0
	)
	_wreckage_spawn_request_index = _feature_requests.size()
	_feature_requests.append(wreckage_spawn)

	# Generate terrain
	_terrain_result = generator.generate(BIOME_SEED, _archetype, _feature_requests)

	Global.log("DebrisFieldBiome: terrain generated with seed %d, %d warnings" % [
		BIOME_SEED, _terrain_result.warnings.size()])


## Resolves ship and player spawn points from the clearing feature request result.
func _resolve_spawn_points() -> void:
	if _terrain_result == null:
		return

	# Ship spawn is at the clearing center
	if _terrain_result.confirmed_positions.has(_clearing_request_index):
		var clearing_positions: Array = _terrain_result.confirmed_positions[_clearing_request_index]
		if clearing_positions.size() > 0:
			_ship_spawn_point = clearing_positions[0]

	# Player spawn is offset from ship spawn
	_player_spawn_point = _ship_spawn_point + Vector3(0.0, 0.0, PLAYER_SPAWN_OFFSET)

	Global.log("DebrisFieldBiome: ship spawn at %s, player spawn at %s" % [
		_ship_spawn_point, _player_spawn_point])


## Resolves wreckage cluster positions from the wreckage spawn request result.
func _resolve_wreckage_positions() -> void:
	if _terrain_result == null:
		return

	_wreckage_cluster_positions.clear()
	if _terrain_result.confirmed_positions.has(_wreckage_spawn_request_index):
		var positions: Array = _terrain_result.confirmed_positions[_wreckage_spawn_request_index]
		for pos: Vector3 in positions:
			_wreckage_cluster_positions.append(pos)

	Global.log("DebrisFieldBiome: %d wreckage clusters resolved" % _wreckage_cluster_positions.size())


## Resolves surface deposit metadata from resource spawn request results.
func _resolve_surface_deposits() -> void:
	if _terrain_result == null:
		return

	_surface_deposits.clear()

	# Scrap Metal surface deposits
	if _terrain_result.confirmed_positions.has(_scrap_spawn_request_index):
		var scrap_positions: Array = _terrain_result.confirmed_positions[_scrap_spawn_request_index]
		for pos: Vector3 in scrap_positions:
			_surface_deposits.append({
				"resource_type": ResourceDefs.ResourceType.SCRAP_METAL,
				"position": pos,
				"quantity": SURFACE_DEPOSIT_QUANTITY,
				"purity": ResourceDefs.Purity.THREE_STAR,
				"density_tier": ResourceDefs.DensityTier.MEDIUM,
				"infinite": false,
				"yield_rate": 1.0,
				"drone_accessible": true,
			})

	# Cryonite surface deposits
	if _terrain_result.confirmed_positions.has(_cryonite_spawn_request_index):
		var cryonite_positions: Array = _terrain_result.confirmed_positions[_cryonite_spawn_request_index]
		for pos: Vector3 in cryonite_positions:
			_surface_deposits.append({
				"resource_type": ResourceDefs.ResourceType.CRYONITE,
				"position": pos,
				"quantity": SURFACE_DEPOSIT_QUANTITY,
				"purity": ResourceDefs.Purity.THREE_STAR,
				"density_tier": ResourceDefs.DensityTier.MEDIUM,
				"infinite": false,
				"yield_rate": 1.0,
				"drone_accessible": true,
			})

	Global.log("DebrisFieldBiome: %d surface deposits resolved" % _surface_deposits.size())


## Resolves deep deposit metadata beneath surface deposits.
func _resolve_deep_deposits() -> void:
	if _terrain_result == null:
		return

	_deep_deposits.clear()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = BIOME_SEED + 9001

	# Deep Cryonite nodes — pick from existing Cryonite surface positions
	var cryonite_surface_positions: Array[Vector3] = []
	for deposit_info: Dictionary in _surface_deposits:
		if deposit_info.get("resource_type") == ResourceDefs.ResourceType.CRYONITE:
			cryonite_surface_positions.append(deposit_info.get("position") as Vector3)

	# Place deep Cryonite beneath the first N Cryonite surface nodes
	var deep_cryo_placed: int = 0
	for i: int in range(mini(DEEP_CRYONITE_COUNT, cryonite_surface_positions.size())):
		var surface_pos: Vector3 = cryonite_surface_positions[i]
		var deep_pos: Vector3 = Vector3(surface_pos.x, surface_pos.y + DEEP_NODE_Y_OFFSET, surface_pos.z)
		_deep_deposits.append({
			"resource_type": ResourceDefs.ResourceType.CRYONITE,
			"position": deep_pos,
			"quantity": DEEP_DEPOSIT_QUANTITY,
			"purity": ResourceDefs.Purity.FOUR_STAR,
			"density_tier": ResourceDefs.DensityTier.HIGH,
			"infinite": true,
			"yield_rate": DEEP_NODE_YIELD_RATE,
			"drone_accessible": true,
		})
		deep_cryo_placed += 1

	# Deep Scrap Metal nodes — pick from existing Scrap Metal surface positions
	var scrap_surface_positions: Array[Vector3] = []
	for deposit_info: Dictionary in _surface_deposits:
		if deposit_info.get("resource_type") == ResourceDefs.ResourceType.SCRAP_METAL:
			scrap_surface_positions.append(deposit_info.get("position") as Vector3)

	var deep_scrap_placed: int = 0
	for i: int in range(mini(DEEP_SCRAP_METAL_COUNT, scrap_surface_positions.size())):
		var surface_pos: Vector3 = scrap_surface_positions[i]
		var deep_pos: Vector3 = Vector3(surface_pos.x, surface_pos.y + DEEP_NODE_Y_OFFSET, surface_pos.z)
		_deep_deposits.append({
			"resource_type": ResourceDefs.ResourceType.SCRAP_METAL,
			"position": deep_pos,
			"quantity": DEEP_DEPOSIT_QUANTITY,
			"purity": ResourceDefs.Purity.THREE_STAR,
			"density_tier": ResourceDefs.DensityTier.HIGH,
			"infinite": true,
			"yield_rate": DEEP_NODE_YIELD_RATE,
			"drone_accessible": true,
		})
		deep_scrap_placed += 1

	Global.log("DebrisFieldBiome: %d deep deposits resolved (%d Cryonite, %d Scrap Metal)" % [
		_deep_deposits.size(), deep_cryo_placed, deep_scrap_placed])


# ── Private Methods: Scene Construction ───────────────────

## Builds the terrain mesh and collision body from the generation result.
func _build_terrain_mesh() -> void:
	if _terrain_result == null or _terrain_result.terrain_mesh == null:
		return

	# Terrain mesh visual
	var terrain_mesh_instance: MeshInstance3D = MeshInstance3D.new()
	terrain_mesh_instance.name = "TerrainMesh"
	terrain_mesh_instance.mesh = _terrain_result.terrain_mesh

	var terrain_material: StandardMaterial3D = StandardMaterial3D.new()
	terrain_material.albedo_color = Color("#3D3D2E")
	terrain_material.roughness = 0.85
	terrain_mesh_instance.material_override = terrain_material
	add_child(terrain_mesh_instance)

	# Terrain collision
	var terrain_body: StaticBody3D = StaticBody3D.new()
	terrain_body.name = "TerrainCollision"
	terrain_body.collision_layer = PhysicsLayers.ENVIRONMENT
	terrain_body.collision_mask = 0

	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	collision_shape.name = "TerrainShape"
	collision_shape.shape = _terrain_result.collision_shape
	terrain_body.add_child(collision_shape)
	add_child(terrain_body)

	Global.log("DebrisFieldBiome: terrain mesh and collision built")


## Builds greybox wreckage clusters at resolved positions.
func _build_wreckage_clusters() -> void:
	var wreckage_container: Node3D = Node3D.new()
	wreckage_container.name = "WreckageClusters"
	add_child(wreckage_container)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = BIOME_SEED + 5000

	for i: int in range(_wreckage_cluster_positions.size()):
		var cluster_pos: Vector3 = _wreckage_cluster_positions[i]
		var cluster: Node3D = _create_wreckage_cluster(rng, i)
		cluster.name = "WreckageCluster_%d" % i
		cluster.position = cluster_pos
		wreckage_container.add_child(cluster)

	Global.log("DebrisFieldBiome: %d wreckage clusters built" % _wreckage_cluster_positions.size())


## Creates a single wreckage cluster using CSG greybox primitives.
func _create_wreckage_cluster(rng: RandomNumberGenerator, cluster_index: int) -> Node3D:
	var cluster_root: Node3D = Node3D.new()

	# Number of debris pieces per cluster (3-7)
	var piece_count: int = 3 + rng.randi_range(0, 4)

	for j: int in range(piece_count):
		var piece: CSGBox3D = CSGBox3D.new()
		piece.name = "DebrisPiece_%d" % j

		# Random size for each piece — asymmetric to look like hull fragments
		var size_x: float = rng.randf_range(1.0, 5.0)
		var size_y: float = rng.randf_range(0.3, 2.5)
		var size_z: float = rng.randf_range(1.0, 4.0)
		piece.size = Vector3(size_x, size_y, size_z)

		# Random offset from cluster center
		var offset_x: float = rng.randf_range(-8.0, 8.0)
		var offset_z: float = rng.randf_range(-8.0, 8.0)
		piece.position = Vector3(offset_x, size_y * 0.5, offset_z)

		# Random rotation for a scattered look
		var rot_y: float = rng.randf_range(0.0, 360.0)
		var rot_x: float = rng.randf_range(-15.0, 15.0)
		var rot_z: float = rng.randf_range(-15.0, 15.0)
		piece.rotation_degrees = Vector3(rot_x, rot_y, rot_z)

		# Greybox material — dark metallic
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color("#4A4A4A")
		material.metallic = 0.6
		material.roughness = 0.7
		piece.material = material

		# Add collision for the debris piece
		piece.use_collision = true

		cluster_root.add_child(piece)

	return cluster_root


## Builds all deposit nodes (surface and deep) at their resolved positions.
func _build_deposits() -> void:
	var deposit_container: Node3D = Node3D.new()
	deposit_container.name = "Deposits"
	add_child(deposit_container)

	# Load mesh resources
	var scrap_mesh_scene: Resource = load("res://assets/meshes/props/mesh_resource_node_scrap.glb")
	var cryonite_mesh_scene: Resource = load("res://assets/meshes/cryonite_deposit.glb")

	# Build surface deposits
	for deposit_info: Dictionary in _surface_deposits:
		var deposit: Deposit = _create_deposit_from_info(deposit_info)
		deposit_container.add_child(deposit)
		_add_deposit_visual(deposit, deposit_info, scrap_mesh_scene, cryonite_mesh_scene, false)
		_add_deposit_collision(deposit)
		deposit.add_to_group("surface_deposit")
		deposit.add_to_group("interactable")
		DepositRegistry.register(deposit)

	# Build deep deposits
	for deposit_info: Dictionary in _deep_deposits:
		var deposit: Deposit = _create_deposit_from_info(deposit_info)
		deposit_container.add_child(deposit)
		_add_deposit_visual(deposit, deposit_info, scrap_mesh_scene, cryonite_mesh_scene, true)
		_add_deposit_collision(deposit)
		deposit.add_to_group("deep_deposit")
		deposit.add_to_group("interactable")
		DepositRegistry.register(deposit)

	Global.log("DebrisFieldBiome: %d surface + %d deep deposits placed" % [
		_surface_deposits.size(), _deep_deposits.size()])


## Creates a Deposit node from deposit info dictionary.
## Uses DeepResourceNode for infinite (deep) deposits, plain Deposit for surface.
func _create_deposit_from_info(deposit_info: Dictionary) -> Deposit:
	var is_deep: bool = deposit_info.get("infinite", false)
	var deposit: Deposit
	if is_deep:
		deposit = DeepResourceNode.new()
	else:
		deposit = Deposit.new()
	var resource_type: ResourceDefs.ResourceType = deposit_info.get("resource_type", ResourceDefs.ResourceType.SCRAP_METAL)
	var purity: ResourceDefs.Purity = deposit_info.get("purity", ResourceDefs.Purity.THREE_STAR)
	var density_tier: ResourceDefs.DensityTier = deposit_info.get("density_tier", ResourceDefs.DensityTier.MEDIUM)
	var quantity: int = deposit_info.get("quantity", SURFACE_DEPOSIT_QUANTITY)

	deposit.setup(resource_type, purity, density_tier, quantity)
	if not is_deep:
		deposit.yield_rate = deposit_info.get("yield_rate", 1.0)
		deposit.drone_accessible = deposit_info.get("drone_accessible", true)

	var pos: Vector3 = deposit_info.get("position", Vector3.ZERO)
	deposit.position = pos

	# Name the deposit descriptively
	var type_name: String = ResourceDefs.get_resource_name(resource_type)
	var depth_label: String = "Deep" if is_deep else "Surface"
	deposit.name = "%s_%s_%d" % [depth_label, type_name.replace(" ", ""), deposit.get_instance_id()]

	return deposit


## Adds a visual mesh to a deposit node.
func _add_deposit_visual(
	deposit: Deposit,
	deposit_info: Dictionary,
	scrap_mesh_scene: Resource,
	cryonite_mesh_scene: Resource,
	is_deep: bool
) -> void:
	var resource_type: ResourceDefs.ResourceType = deposit_info.get("resource_type", ResourceDefs.ResourceType.SCRAP_METAL)

	if resource_type == ResourceDefs.ResourceType.CRYONITE and cryonite_mesh_scene and cryonite_mesh_scene is PackedScene:
		var mesh_instance: Node3D = (cryonite_mesh_scene as PackedScene).instantiate()
		mesh_instance.name = "Mesh"
		# Deep Cryonite nodes are visually larger (pressurized formation)
		mesh_instance.scale = DEEP_CRYONITE_VISUAL_SCALE if is_deep else CRYONITE_VISUAL_SCALE
		mesh_instance.position.y = 0.9
		deposit.add_child(mesh_instance)
	elif resource_type == ResourceDefs.ResourceType.SCRAP_METAL and scrap_mesh_scene and scrap_mesh_scene is PackedScene:
		var mesh_instance: Node3D = (scrap_mesh_scene as PackedScene).instantiate()
		mesh_instance.name = "Mesh"
		mesh_instance.scale = DEPOSIT_VISUAL_SCALE
		mesh_instance.position.y = 0.9
		deposit.add_child(mesh_instance)
	else:
		# Fallback: colored box
		var fallback: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(1.0, 1.0, 1.0)
		fallback.mesh = box
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		if resource_type == ResourceDefs.ResourceType.CRYONITE:
			mat.albedo_color = Color("#4ECDC4")
		else:
			mat.albedo_color = Color("#D4AA00")
		fallback.material_override = mat
		fallback.name = "Mesh"
		deposit.add_child(fallback)


## Adds an interaction collision body to a deposit node.
func _add_deposit_collision(deposit: Deposit) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "InteractBody"
	body.collision_layer = PhysicsLayers.INTERACTABLE
	body.collision_mask = 0

	var col: CollisionShape3D = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = DEPOSIT_COLLISION_RADIUS
	col.shape = sphere
	col.position.y = 0.9

	body.add_child(col)
	deposit.add_child(body)


## Builds the world boundary around the biome.
func _build_world_boundary() -> void:
	_boundary_manager = WorldBoundaryManager.new()
	_boundary_manager.name = "WorldBoundary"
	add_child(_boundary_manager)
	_boundary_manager.initialize(_archetype)
	_boundary_active = true

	Global.log("DebrisFieldBiome: world boundary active")
