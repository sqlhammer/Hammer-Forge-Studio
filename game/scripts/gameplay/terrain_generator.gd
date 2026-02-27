## Biome-agnostic procedural terrain generator. Accepts a seed, a BiomeArchetypeConfig
## (noise parameters), and an array of TerrainFeatureRequests (declarative terrain shaping).
## Produces a 500m x 500m ArrayMesh with baked ConcavePolygonShape3D, organized in a
## chunk-aligned spatial grid ready for future streaming. No biome-specific logic lives here.
## Owner: gameplay-programmer
class_name TerrainGenerator
extends RefCounted


# ── Constants ─────────────────────────────────────────────

## Terrain extent in metres along each horizontal axis.
const TERRAIN_SIZE: float = 500.0

## Chunk side length in metres — power of two for streaming alignment.
const CHUNK_SIZE: float = 32.0

## Distance between adjacent vertices in the heightmap grid.
const VERTEX_SPACING: float = 2.0

## Number of vertices per axis: floor(TERRAIN_SIZE / VERTEX_SPACING) + 1.
const HEIGHTMAP_RESOLUTION: int = 251

## Smoothing radius (in grid cells) for feature-to-terrain blending.
const BLEND_MARGIN_CELLS: int = 3

## Position hint constants
const HINT_CENTER: String = "center"
const HINT_EDGE: String = "edge"

## Edge hint margin — how far from the boundary edge-hinted features are placed.
const EDGE_MARGIN: float = 40.0


# ── Private Variables ─────────────────────────────────────

## Feature request dispatch table: FeatureType -> handler Callable.
var _dispatch_table: Dictionary = {}


# ── Built-in Virtual Methods ──────────────────────────────

func _init() -> void:
	_dispatch_table = {
		TerrainFeatureRequest.FeatureType.PLATEAU: _handle_plateau,
		TerrainFeatureRequest.FeatureType.CLEARING: _handle_clearing,
		TerrainFeatureRequest.FeatureType.RESOURCE_SPAWN: _handle_resource_spawn,
		TerrainFeatureRequest.FeatureType.WALKABLE_CLEARANCE: _handle_walkable_clearance,
	}


# ── Public Methods ────────────────────────────────────────

## Generates terrain from seed, archetype config, and feature requests.
## Returns a TerrainGenerationResult with mesh, collision, confirmed positions, and chunk grid.
func generate(
	seed_value: int,
	archetype: BiomeArchetypeConfig,
	requests: Array[TerrainFeatureRequest]
) -> TerrainGenerationResult:
	var result: TerrainGenerationResult = TerrainGenerationResult.new()
	result.heightmap_resolution = HEIGHTMAP_RESOLUTION

	# Step 1: Generate base heightmap from noise
	var heightmap: PackedFloat32Array = _generate_heightmap(seed_value, archetype)

	# Step 2: Process all feature requests (modify heightmap, record positions)
	for request_index: int in range(requests.size()):
		var request: TerrainFeatureRequest = requests[request_index]
		var handler: Callable = _dispatch_table.get(request.type, Callable())
		if handler.is_valid():
			handler.call(heightmap, request, request_index, result, seed_value)
		else:
			result.warnings.append("Unknown feature type %d for request %d" % [request.type, request_index])

	# Store the final heightmap on the result
	result.heightmap = heightmap

	# Step 3: Build chunk grid with per-chunk meshes and collision shapes
	_build_chunk_grid(heightmap, result)

	# Step 4: Assemble full terrain mesh and collision from all chunks
	_assemble_full_mesh(result)

	return result


# ── Private Methods: Heightmap Generation ─────────────────

## Generates a heightmap using FastNoiseLite configured from the archetype.
func _generate_heightmap(seed_value: int, archetype: BiomeArchetypeConfig) -> PackedFloat32Array:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = archetype.noise_frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = archetype.noise_octaves
	noise.fractal_lacunarity = archetype.noise_lacunarity
	noise.fractal_gain = archetype.noise_gain

	var total_samples: int = HEIGHTMAP_RESOLUTION * HEIGHTMAP_RESOLUTION
	var heightmap: PackedFloat32Array = PackedFloat32Array()
	heightmap.resize(total_samples)

	for zi: int in range(HEIGHTMAP_RESOLUTION):
		for xi: int in range(HEIGHTMAP_RESOLUTION):
			var world_x: float = float(xi) * VERTEX_SPACING
			var world_z: float = float(zi) * VERTEX_SPACING
			var noise_value: float = noise.get_noise_2d(world_x, world_z)
			var final_height: float = noise_value * archetype.height_scale * archetype.noise_amplitude + archetype.base_height
			heightmap[zi * HEIGHTMAP_RESOLUTION + xi] = final_height

	return heightmap


# ── Private Methods: Feature Request Handlers ─────────────

## Handles a plateau request — raises and flattens a rectangular area.
func _handle_plateau(
	heightmap: PackedFloat32Array,
	request: TerrainFeatureRequest,
	request_index: int,
	result: TerrainGenerationResult,
	seed_value: int
) -> void:
	var center: Vector2 = _resolve_position_hint(request.position_hint)
	var half_w: float = request.width * 0.5
	var half_d: float = request.depth * 0.5

	# Calculate the index bounds for the plateau area
	var min_xi: int = maxi(0, floori((center.x - half_w) / VERTEX_SPACING))
	var max_xi: int = mini(HEIGHTMAP_RESOLUTION - 1, ceili((center.x + half_w) / VERTEX_SPACING))
	var min_zi: int = maxi(0, floori((center.y - half_d) / VERTEX_SPACING))
	var max_zi: int = mini(HEIGHTMAP_RESOLUTION - 1, ceili((center.y + half_d) / VERTEX_SPACING))

	# Set all vertices within the plateau to the requested height
	for zi: int in range(min_zi, max_zi + 1):
		for xi: int in range(min_xi, max_xi + 1):
			heightmap[zi * HEIGHTMAP_RESOLUTION + xi] = request.height

	# Blend edges to smooth transition to surrounding terrain
	_blend_feature_edges(heightmap, min_xi, max_xi, min_zi, max_zi, request.height)

	# Build ramp if access type is RAMP
	if request.access == TerrainFeatureRequest.AccessType.RAMP:
		_build_ramp(heightmap, center, request)

	# Record confirmed position
	var confirmed_y: float = request.height
	result.confirmed_positions[request_index] = [Vector3(center.x, confirmed_y, center.y)]


## Handles a clearing request — flattens a circular area to base height.
func _handle_clearing(
	heightmap: PackedFloat32Array,
	request: TerrainFeatureRequest,
	request_index: int,
	result: TerrainGenerationResult,
	seed_value: int
) -> void:
	var center: Vector2 = _resolve_position_hint(request.position_hint)
	var radius_sq: float = request.radius * request.radius

	# Calculate the average height at the clearing center for the base level
	var center_xi: int = clampi(roundi(center.x / VERTEX_SPACING), 0, HEIGHTMAP_RESOLUTION - 1)
	var center_zi: int = clampi(roundi(center.y / VERTEX_SPACING), 0, HEIGHTMAP_RESOLUTION - 1)
	var base_height: float = heightmap[center_zi * HEIGHTMAP_RESOLUTION + center_xi]

	# Flatten all vertices within the clearing radius
	var radius_idx: int = ceili(request.radius / VERTEX_SPACING) + BLEND_MARGIN_CELLS
	var min_xi: int = maxi(0, center_xi - radius_idx)
	var max_xi: int = mini(HEIGHTMAP_RESOLUTION - 1, center_xi + radius_idx)
	var min_zi: int = maxi(0, center_zi - radius_idx)
	var max_zi: int = mini(HEIGHTMAP_RESOLUTION - 1, center_zi + radius_idx)

	for zi: int in range(min_zi, max_zi + 1):
		for xi: int in range(min_xi, max_xi + 1):
			var world_x: float = float(xi) * VERTEX_SPACING
			var world_z: float = float(zi) * VERTEX_SPACING
			var dx: float = world_x - center.x
			var dz: float = world_z - center.y
			var dist_sq: float = dx * dx + dz * dz

			if dist_sq <= radius_sq:
				# Inside the clearing — flatten to base height
				heightmap[zi * HEIGHTMAP_RESOLUTION + xi] = base_height
			elif dist_sq <= (request.radius + float(BLEND_MARGIN_CELLS) * VERTEX_SPACING) ** 2:
				# In the blend margin — interpolate between clearing height and terrain
				var dist: float = sqrt(dist_sq)
				var blend_start: float = request.radius
				var blend_end: float = request.radius + float(BLEND_MARGIN_CELLS) * VERTEX_SPACING
				var blend_factor: float = (dist - blend_start) / (blend_end - blend_start)
				blend_factor = clampf(blend_factor, 0.0, 1.0)
				var current_h: float = heightmap[zi * HEIGHTMAP_RESOLUTION + xi]
				heightmap[zi * HEIGHTMAP_RESOLUTION + xi] = lerpf(base_height, current_h, blend_factor)

	result.confirmed_positions[request_index] = [Vector3(center.x, base_height, center.y)]


## Handles a resource spawn request — samples N valid surface positions.
func _handle_resource_spawn(
	heightmap: PackedFloat32Array,
	request: TerrainFeatureRequest,
	request_index: int,
	result: TerrainGenerationResult,
	seed_value: int
) -> void:
	var positions: Array = []
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	# Combine seed with request index for unique but deterministic placement
	rng.seed = seed_value + request_index * 7919

	var center: Vector2 = Vector2(TERRAIN_SIZE * 0.5, TERRAIN_SIZE * 0.5)
	if request.position_hint is Vector2:
		center = request.position_hint

	# Scatter search area — search within a reasonable radius from center
	var search_radius: float = TERRAIN_SIZE * 0.4
	var max_attempts: int = request.count * 20
	var attempts: int = 0

	while positions.size() < request.count and attempts < max_attempts:
		attempts += 1

		# Generate random position within search radius
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf() * search_radius
		var candidate_x: float = center.x + cos(angle) * dist
		var candidate_z: float = center.y + sin(angle) * dist

		# Clamp to terrain bounds with margin
		candidate_x = clampf(candidate_x, 5.0, TERRAIN_SIZE - 5.0)
		candidate_z = clampf(candidate_z, 5.0, TERRAIN_SIZE - 5.0)

		# Check slope at candidate position
		var slope: float = _calculate_slope(heightmap, candidate_x, candidate_z)
		if slope > request.slope_max:
			continue

		# Check clearance from existing positions
		var too_close: bool = false
		for existing: Vector3 in positions:
			var existing_xz: Vector2 = Vector2(existing.x, existing.z)
			var candidate_xz: Vector2 = Vector2(candidate_x, candidate_z)
			if existing_xz.distance_to(candidate_xz) < request.clearance_radius:
				too_close = true
				break
		if too_close:
			continue

		# Get height at position
		var xi: int = clampi(roundi(candidate_x / VERTEX_SPACING), 0, HEIGHTMAP_RESOLUTION - 1)
		var zi: int = clampi(roundi(candidate_z / VERTEX_SPACING), 0, HEIGHTMAP_RESOLUTION - 1)
		var candidate_y: float = heightmap[zi * HEIGHTMAP_RESOLUTION + xi]

		positions.append(Vector3(candidate_x, candidate_y, candidate_z))

	if positions.size() < request.count:
		var shortfall: int = request.count - positions.size()
		result.warnings.append(
			"Resource spawn request %d: could only place %d of %d positions (%d short)" % [
				request_index, positions.size(), request.count, shortfall
			]
		)

	result.confirmed_positions[request_index] = positions


## Handles a walkable clearance request — flattens terrain around a position.
func _handle_walkable_clearance(
	heightmap: PackedFloat32Array,
	request: TerrainFeatureRequest,
	request_index: int,
	result: TerrainGenerationResult,
	seed_value: int
) -> void:
	var center: Vector2 = request.position
	var radius_sq: float = request.radius * request.radius

	# Get the base height at the center position
	var center_xi: int = clampi(roundi(center.x / VERTEX_SPACING), 0, HEIGHTMAP_RESOLUTION - 1)
	var center_zi: int = clampi(roundi(center.y / VERTEX_SPACING), 0, HEIGHTMAP_RESOLUTION - 1)
	var base_height: float = heightmap[center_zi * HEIGHTMAP_RESOLUTION + center_xi]

	# Flatten all vertices within the clearance radius
	var radius_idx: int = ceili(request.radius / VERTEX_SPACING) + BLEND_MARGIN_CELLS
	var min_xi: int = maxi(0, center_xi - radius_idx)
	var max_xi: int = mini(HEIGHTMAP_RESOLUTION - 1, center_xi + radius_idx)
	var min_zi: int = maxi(0, center_zi - radius_idx)
	var max_zi: int = mini(HEIGHTMAP_RESOLUTION - 1, center_zi + radius_idx)

	for zi: int in range(min_zi, max_zi + 1):
		for xi: int in range(min_xi, max_xi + 1):
			var world_x: float = float(xi) * VERTEX_SPACING
			var world_z: float = float(zi) * VERTEX_SPACING
			var dx: float = world_x - center.x
			var dz: float = world_z - center.y
			var dist_sq: float = dx * dx + dz * dz

			if dist_sq <= radius_sq:
				heightmap[zi * HEIGHTMAP_RESOLUTION + xi] = base_height
			elif dist_sq <= (request.radius + float(BLEND_MARGIN_CELLS) * VERTEX_SPACING) ** 2:
				var dist: float = sqrt(dist_sq)
				var blend_start: float = request.radius
				var blend_end: float = request.radius + float(BLEND_MARGIN_CELLS) * VERTEX_SPACING
				var blend_factor: float = (dist - blend_start) / (blend_end - blend_start)
				blend_factor = clampf(blend_factor, 0.0, 1.0)
				var current_h: float = heightmap[zi * HEIGHTMAP_RESOLUTION + xi]
				heightmap[zi * HEIGHTMAP_RESOLUTION + xi] = lerpf(base_height, current_h, blend_factor)

	result.confirmed_positions[request_index] = [Vector3(center.x, base_height, center.y)]


# ── Private Methods: Mesh Construction ────────────────────

## Builds the chunk grid from the heightmap, creating per-chunk meshes and collision shapes.
func _build_chunk_grid(heightmap: PackedFloat32Array, result: TerrainGenerationResult) -> void:
	var chunks_per_axis: int = ceili(TERRAIN_SIZE / CHUNK_SIZE)

	for cz: int in range(chunks_per_axis):
		for cx: int in range(chunks_per_axis):
			var chunk: TerrainChunk = _build_single_chunk(heightmap, cx, cz)
			result.chunk_grid[Vector2i(cx, cz)] = chunk


## Builds a single chunk's mesh and collision shape from the heightmap.
func _build_single_chunk(heightmap: PackedFloat32Array, cx: int, cz: int) -> TerrainChunk:
	var chunk: TerrainChunk = TerrainChunk.new()
	chunk.grid_position = Vector2i(cx, cz)

	var chunk_origin_x: float = float(cx) * CHUNK_SIZE
	var chunk_origin_z: float = float(cz) * CHUNK_SIZE
	chunk.world_origin = Vector3(chunk_origin_x, 0.0, chunk_origin_z)

	var chunk_end_x: float = minf(chunk_origin_x + CHUNK_SIZE, TERRAIN_SIZE)
	var chunk_end_z: float = minf(chunk_origin_z + CHUNK_SIZE, TERRAIN_SIZE)

	# Determine vertex index ranges for this chunk
	var xi_start: int = maxi(0, floori(chunk_origin_x / VERTEX_SPACING))
	var xi_end: int = mini(HEIGHTMAP_RESOLUTION - 1, floori(chunk_end_x / VERTEX_SPACING))
	var zi_start: int = maxi(0, floori(chunk_origin_z / VERTEX_SPACING))
	var zi_end: int = mini(HEIGHTMAP_RESOLUTION - 1, floori(chunk_end_z / VERTEX_SPACING))

	# Build mesh using SurfaceTool
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var triangle_vertices: PackedVector3Array = PackedVector3Array()
	var vertex_count: int = 0

	for zi: int in range(zi_start, zi_end):
		for xi: int in range(xi_start, xi_end):
			# Get the four corners of this quad
			var v00: Vector3 = _get_vertex(heightmap, xi, zi)
			var v10: Vector3 = _get_vertex(heightmap, xi + 1, zi)
			var v01: Vector3 = _get_vertex(heightmap, xi, zi + 1)
			var v11: Vector3 = _get_vertex(heightmap, xi + 1, zi + 1)

			# Triangle 1: v00, v10, v01
			var normal_a: Vector3 = _calculate_triangle_normal(v00, v10, v01)
			_add_triangle_to_surface(surface_tool, v00, v10, v01, normal_a)
			triangle_vertices.append(v00)
			triangle_vertices.append(v10)
			triangle_vertices.append(v01)

			# Triangle 2: v10, v11, v01
			var normal_b: Vector3 = _calculate_triangle_normal(v10, v11, v01)
			_add_triangle_to_surface(surface_tool, v10, v11, v01, normal_b)
			triangle_vertices.append(v10)
			triangle_vertices.append(v11)
			triangle_vertices.append(v01)

			vertex_count += 6

	chunk.vertex_count = vertex_count

	if vertex_count > 0:
		chunk.mesh_section = surface_tool.commit()

		# Bake collision shape from triangle vertices
		var collision: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
		collision.set_faces(triangle_vertices)
		chunk.collision_shape = collision
	else:
		chunk.mesh_section = ArrayMesh.new()
		chunk.collision_shape = ConcavePolygonShape3D.new()

	return chunk


## Assembles the full terrain mesh and collision shape from all chunks.
func _assemble_full_mesh(result: TerrainGenerationResult) -> void:
	var all_vertices: PackedVector3Array = PackedVector3Array()
	var all_normals: PackedVector3Array = PackedVector3Array()
	var all_collision_faces: PackedVector3Array = PackedVector3Array()

	# Iterate chunks in order for deterministic assembly
	var chunks_per_axis: int = ceili(TERRAIN_SIZE / CHUNK_SIZE)
	for cz: int in range(chunks_per_axis):
		for cx: int in range(chunks_per_axis):
			var key: Vector2i = Vector2i(cx, cz)
			if not result.chunk_grid.has(key):
				continue
			var chunk: TerrainChunk = result.chunk_grid[key]
			if chunk.mesh_section == null or chunk.mesh_section.get_surface_count() == 0:
				continue

			var arrays: Array = chunk.mesh_section.surface_get_arrays(0)
			var chunk_verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var chunk_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			all_vertices.append_array(chunk_verts)
			all_normals.append_array(chunk_normals)

			# Collision faces from the chunk
			if chunk.collision_shape != null:
				var faces: PackedVector3Array = chunk.collision_shape.get_faces()
				all_collision_faces.append_array(faces)

	# Build the unified terrain mesh
	if all_vertices.size() > 0:
		var surface_tool: SurfaceTool = SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i: int in range(all_vertices.size()):
			surface_tool.set_normal(all_normals[i])
			surface_tool.add_vertex(all_vertices[i])
		result.terrain_mesh = surface_tool.commit()
	else:
		result.terrain_mesh = ArrayMesh.new()

	# Build the unified collision shape
	if all_collision_faces.size() > 0:
		var collision: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
		collision.set_faces(all_collision_faces)
		result.collision_shape = collision
	else:
		result.collision_shape = ConcavePolygonShape3D.new()


# ── Private Methods: Helpers ──────────────────────────────

## Resolves a position hint to world-space XZ coordinates.
func _resolve_position_hint(hint: Variant) -> Vector2:
	if hint is Vector2:
		return hint
	if hint is String:
		if hint == HINT_CENTER:
			return Vector2(TERRAIN_SIZE * 0.5, TERRAIN_SIZE * 0.5)
		if hint == HINT_EDGE:
			return Vector2(EDGE_MARGIN, TERRAIN_SIZE * 0.5)
	# Default to center
	return Vector2(TERRAIN_SIZE * 0.5, TERRAIN_SIZE * 0.5)


## Returns the world-space vertex position from heightmap indices.
func _get_vertex(heightmap: PackedFloat32Array, xi: int, zi: int) -> Vector3:
	var world_x: float = float(xi) * VERTEX_SPACING
	var world_z: float = float(zi) * VERTEX_SPACING
	var height: float = heightmap[zi * HEIGHTMAP_RESOLUTION + xi]
	return Vector3(world_x, height, world_z)


## Calculates the face normal for a triangle defined by three vertices.
func _calculate_triangle_normal(v0: Vector3, v1: Vector3, v2: Vector3) -> Vector3:
	var edge_a: Vector3 = v1 - v0
	var edge_b: Vector3 = v2 - v0
	var normal: Vector3 = edge_a.cross(edge_b).normalized()
	# Ensure normal points upward
	if normal.y < 0.0:
		normal = -normal
	return normal


## Adds a triangle to a SurfaceTool with vertices and a shared normal.
func _add_triangle_to_surface(
	surface_tool: SurfaceTool,
	v0: Vector3,
	v1: Vector3,
	v2: Vector3,
	normal: Vector3
) -> void:
	surface_tool.set_normal(normal)
	surface_tool.add_vertex(v0)
	surface_tool.set_normal(normal)
	surface_tool.add_vertex(v1)
	surface_tool.set_normal(normal)
	surface_tool.add_vertex(v2)


## Calculates the terrain slope in degrees at a world position.
func _calculate_slope(heightmap: PackedFloat32Array, world_x: float, world_z: float) -> float:
	var xi: int = clampi(roundi(world_x / VERTEX_SPACING), 1, HEIGHTMAP_RESOLUTION - 2)
	var zi: int = clampi(roundi(world_z / VERTEX_SPACING), 1, HEIGHTMAP_RESOLUTION - 2)

	var h_left: float = heightmap[zi * HEIGHTMAP_RESOLUTION + (xi - 1)]
	var h_right: float = heightmap[zi * HEIGHTMAP_RESOLUTION + (xi + 1)]
	var h_up: float = heightmap[(zi - 1) * HEIGHTMAP_RESOLUTION + xi]
	var h_down: float = heightmap[(zi + 1) * HEIGHTMAP_RESOLUTION + xi]

	var dx: float = (h_right - h_left) / (2.0 * VERTEX_SPACING)
	var dz: float = (h_down - h_up) / (2.0 * VERTEX_SPACING)
	var gradient: float = sqrt(dx * dx + dz * dz)
	return rad_to_deg(atan(gradient))


## Blends the edges of a rectangular feature into the surrounding terrain.
func _blend_feature_edges(
	heightmap: PackedFloat32Array,
	min_xi: int,
	max_xi: int,
	min_zi: int,
	max_zi: int,
	feature_height: float
) -> void:
	# Apply smoothing in a margin around the feature rectangle
	for margin: int in range(1, BLEND_MARGIN_CELLS + 1):
		var blend_factor: float = float(margin) / float(BLEND_MARGIN_CELLS + 1)

		# Top and bottom edges
		for xi: int in range(min_xi, max_xi + 1):
			var top_zi: int = min_zi - margin
			if top_zi >= 0:
				var current: float = heightmap[top_zi * HEIGHTMAP_RESOLUTION + xi]
				heightmap[top_zi * HEIGHTMAP_RESOLUTION + xi] = lerpf(feature_height, current, blend_factor)

			var bottom_zi: int = max_zi + margin
			if bottom_zi < HEIGHTMAP_RESOLUTION:
				var current: float = heightmap[bottom_zi * HEIGHTMAP_RESOLUTION + xi]
				heightmap[bottom_zi * HEIGHTMAP_RESOLUTION + xi] = lerpf(feature_height, current, blend_factor)

		# Left and right edges
		for zi: int in range(min_zi - margin, max_zi + margin + 1):
			if zi < 0 or zi >= HEIGHTMAP_RESOLUTION:
				continue

			var left_xi: int = min_xi - margin
			if left_xi >= 0:
				var current: float = heightmap[zi * HEIGHTMAP_RESOLUTION + left_xi]
				heightmap[zi * HEIGHTMAP_RESOLUTION + left_xi] = lerpf(feature_height, current, blend_factor)

			var right_xi: int = max_xi + margin
			if right_xi < HEIGHTMAP_RESOLUTION:
				var current: float = heightmap[zi * HEIGHTMAP_RESOLUTION + right_xi]
				heightmap[zi * HEIGHTMAP_RESOLUTION + right_xi] = lerpf(feature_height, current, blend_factor)


## Builds a ramp on the south side of a plateau.
func _build_ramp(
	heightmap: PackedFloat32Array,
	center: Vector2,
	request: TerrainFeatureRequest
) -> void:
	var half_d: float = request.depth * 0.5
	var ramp_half_w: float = request.ramp_width * 0.5
	var ramp_length: float = request.height * 3.0

	# Ramp extends south from the plateau edge
	var ramp_start_z: float = center.y + half_d
	var ramp_end_z: float = minf(ramp_start_z + ramp_length, TERRAIN_SIZE)

	var ramp_min_xi: int = maxi(0, floori((center.x - ramp_half_w) / VERTEX_SPACING))
	var ramp_max_xi: int = mini(HEIGHTMAP_RESOLUTION - 1, ceili((center.x + ramp_half_w) / VERTEX_SPACING))
	var ramp_start_zi: int = maxi(0, floori(ramp_start_z / VERTEX_SPACING))
	var ramp_end_zi: int = mini(HEIGHTMAP_RESOLUTION - 1, ceili(ramp_end_z / VERTEX_SPACING))

	for zi: int in range(ramp_start_zi, ramp_end_zi + 1):
		var world_z: float = float(zi) * VERTEX_SPACING
		# Linear interpolation from plateau height to ground level
		var ramp_progress: float = (world_z - ramp_start_z) / maxf(ramp_length, 0.01)
		ramp_progress = clampf(ramp_progress, 0.0, 1.0)
		var ramp_height: float = lerpf(request.height, 0.0, ramp_progress)
		for xi: int in range(ramp_min_xi, ramp_max_xi + 1):
			heightmap[zi * HEIGHTMAP_RESOLUTION + xi] = ramp_height
