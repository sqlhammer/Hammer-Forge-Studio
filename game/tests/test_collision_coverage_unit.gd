## Parameterized collision coverage tests for all mesh assets with solid collision shapes.
## Registers AABB coverage and perimeter sweep tests for each configured model.
## Adding a new model: append a ModelConfig in _build_model_configs(), run test_runner.tscn.
class_name TestCollisionCoverageUnit
extends TestSuite


# ── Constants ─────────────────────────────────────────────
const LAYER_ENVIRONMENT: int = 1 << 2
const LAYER_INTERACTABLE: int = 1 << 3
const MODEL_SPACING: float = 100.0
const DEFAULT_COVERAGE_THRESHOLD: float = 0.85
const LARGE_MODEL_COVERAGE_THRESHOLD: float = 0.92
const SWEEP_RADIUS_MULTIPLIER: float = 1.5
const PERIMETER_HEIGHT_FRACTIONS: Array[float] = [0.1, 0.25, 0.4, 0.55, 0.7, 0.85]
const TANGENTIAL_HEIGHT_FRACTIONS: Array[float] = [0.15, 0.3, 0.45, 0.6, 0.75]
const TANGENTIAL_SURFACE_OFFSET: float = 1.0


# ── Private Variables ─────────────────────────────────────
var _probe: CollisionProbe = null
var _configs: Array = []
var _spawned_models: Dictionary = {}


# ── Setup / Teardown ──────────────────────────────────────

func before_all() -> void:
	_probe = CollisionProbe.new()
	_probe.setup(self)
	_spawn_all_models()


func after_all() -> void:
	if _probe:
		_probe.teardown()
	_probe = null
	for label: String in _spawned_models:
		var data: Dictionary = _spawned_models[label]
		var root: Node3D = data.get("root") as Node3D
		if is_instance_valid(root):
			root.queue_free()
	_spawned_models.clear()


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	_build_model_configs()
	for i: int in range(_configs.size()):
		var config: ModelConfig = _configs[i] as ModelConfig
		if not config.expect_solid:
			continue
		var label: String = config.label
		add_test(
			"%s_aabb_coverage" % label,
			_run_aabb_coverage_test.bind(config)
		)
		# Perimeter sweep at 6 height fractions
		for frac: float in PERIMETER_HEIGHT_FRACTIONS:
			var tag: String = _height_tag(frac)
			var heights: Array[float] = [frac]
			add_test(
				"%s_perimeter_no_clip_%s" % [label, tag],
				_run_perimeter_test.bind(config, heights)
			)
		# Tangential surface sweep
		add_test(
			"%s_tangential_no_clip" % label,
			_run_tangential_test.bind(config)
		)
	# Camera-within-capsule validation
	add_test(
		"player_camera_within_capsule",
		_run_camera_within_capsule_test
	)


# ── Test Methods ──────────────────────────────────────────

func _run_aabb_coverage_test(config: ModelConfig) -> void:
	var data: Dictionary = _spawned_models.get(config.label, {})
	var body: StaticBody3D = data.get("body") as StaticBody3D
	var mesh_aabb: AABB = data.get("mesh_aabb", AABB())
	var root: Node3D = data.get("root") as Node3D
	if body == null:
		assert_true(false, "%s: collision body not found" % config.label)
		return

	var coverage: Dictionary = _probe.check_aabb_coverage(body, mesh_aabb, root)
	var threshold: float = config.coverage_threshold

	var x_coverage: float = coverage["x"]
	assert_true(
		x_coverage >= threshold,
		"%s X-axis coverage %.2f below threshold %.2f" % [config.label, x_coverage, threshold]
	)
	var y_coverage: float = coverage["y"]
	assert_true(
		y_coverage >= threshold,
		"%s Y-axis coverage %.2f below threshold %.2f" % [config.label, y_coverage, threshold]
	)
	var z_coverage: float = coverage["z"]
	assert_true(
		z_coverage >= threshold,
		"%s Z-axis coverage %.2f below threshold %.2f" % [config.label, z_coverage, threshold]
	)


func _run_perimeter_test(config: ModelConfig, heights: Array[float]) -> void:
	var data: Dictionary = _spawned_models.get(config.label, {})
	var mesh_aabb: AABB = data.get("mesh_aabb", AABB())
	if mesh_aabb.size == Vector3.ZERO:
		assert_true(false, "%s: mesh AABB not computed" % config.label)
		return

	# Build world-space AABB offset by model position
	var world_aabb := AABB(mesh_aabb.position + config.position, mesh_aabb.size)
	var center: Vector3 = world_aabb.get_center()

	var results: Array = _probe.sweep_all_directions(
		center, world_aabb, config.collision_mask, heights, SWEEP_RADIUS_MULTIPLIER
	)

	var gaps: int = 0
	var gap_labels: Array[String] = []
	for result in results:
		var probe_result: CollisionProbe.ProbeResult = result as CollisionProbe.ProbeResult
		if probe_result.is_clipping_gap:
			gaps += 1
			gap_labels.append(probe_result.direction_label)

	var gap_summary: String = ", ".join(gap_labels) if gap_labels.size() > 0 else "none"
	assert_true(
		gaps <= config.max_allowed_gaps,
		"%s: %d clipping gaps (max %d) at: %s" % [
			config.label, gaps, config.max_allowed_gaps, gap_summary
		]
	)


func _run_tangential_test(config: ModelConfig) -> void:
	var data: Dictionary = _spawned_models.get(config.label, {})
	var mesh_aabb: AABB = data.get("mesh_aabb", AABB())
	if mesh_aabb.size == Vector3.ZERO:
		assert_true(false, "%s: mesh AABB not computed" % config.label)
		return

	var world_aabb := AABB(mesh_aabb.position + config.position, mesh_aabb.size)
	var center: Vector3 = world_aabb.get_center()

	var results: Array = _probe.sweep_tangential(
		center, world_aabb, config.collision_mask,
		TANGENTIAL_HEIGHT_FRACTIONS, TANGENTIAL_SURFACE_OFFSET,
		config.tangential_segment_count
	)

	var gaps: int = 0
	var gap_labels: Array[String] = []
	for result in results:
		var probe_result: CollisionProbe.ProbeResult = result as CollisionProbe.ProbeResult
		if probe_result.is_clipping_gap:
			gaps += 1
			gap_labels.append(probe_result.direction_label)

	var gap_summary: String = ", ".join(gap_labels) if gap_labels.size() > 0 else "none"
	assert_true(
		gaps <= config.tangential_max_allowed_gaps,
		"%s tangential: %d clipping gaps (max %d) at: %s" % [
			config.label, gaps, config.tangential_max_allowed_gaps, gap_summary
		]
	)


func _run_camera_within_capsule_test() -> void:
	var scene: PackedScene = load("res://scenes/gameplay/player_first_person.tscn") as PackedScene
	if not scene:
		assert_true(false, "Could not load player_first_person.tscn")
		return

	var player: CharacterBody3D = scene.instantiate() as CharacterBody3D
	add_child(player)

	# Read the collision shape position and capsule dimensions
	var col_shape: CollisionShape3D = player.get_node("CollisionShape") as CollisionShape3D
	if not col_shape or not col_shape.shape is CapsuleShape3D:
		assert_true(false, "Player CollisionShape3D with CapsuleShape3D not found")
		player.queue_free()
		return

	var capsule: CapsuleShape3D = col_shape.shape as CapsuleShape3D
	var capsule_top_local: float = col_shape.position.y + capsule.height / 2.0

	# Read head_height from the player script
	var head_height: float = player.get("head_height") as float
	var margin: float = 0.1  # Minimum coverage above camera

	assert_true(
		head_height <= capsule_top_local - margin,
		"Camera head_height %.2f must be <= capsule top %.2f - margin %.2f (= %.2f)" % [
			head_height, capsule_top_local, margin, capsule_top_local - margin
		]
	)

	player.queue_free()


# ── Helpers ───────────────────────────────────────────────

func _build_model_configs() -> void:
	_configs.clear()

	# Ship exterior — VHACD convex decomposition matching test_world.gd ship collision
	var ship := ModelConfig.new()
	ship.label = "ship_exterior"
	ship.scene_path = "res://assets/meshes/vehicles/mesh_ship_exterior.glb"
	ship.scale = Vector3(24.0, 24.0, 24.0)
	ship.mesh_offset = Vector3(0.0, 6.5, 0.0)
	ship.position = Vector3(0.0, 0.0, 0.0)
	ship.collision_mask = LAYER_ENVIRONMENT
	ship.expect_solid = true
	ship.max_allowed_gaps = 0
	ship.coverage_threshold = LARGE_MODEL_COVERAGE_THRESHOLD
	ship.tangential_segment_count = 6
	ship.tangential_max_allowed_gaps = 2
	ship.collision_setup = func(root: Node3D) -> StaticBody3D:
		return _create_vhacd_collision(root)
	_configs.append(ship)

	# Recycler module — BoxShape3D matching SOP dimensions (1.8m x 1.4m x 1.2m)
	var recycler := ModelConfig.new()
	recycler.label = "recycler_module"
	recycler.scene_path = "res://assets/meshes/machines/mesh_recycler_module.glb"
	recycler.scale = Vector3.ONE
	recycler.position = Vector3(MODEL_SPACING, 0.0, 0.0)
	recycler.collision_mask = LAYER_ENVIRONMENT
	recycler.expect_solid = true
	recycler.max_allowed_gaps = 0
	recycler.coverage_threshold = DEFAULT_COVERAGE_THRESHOLD
	recycler.collision_setup = func(root: Node3D) -> StaticBody3D:
		return _create_box_collision(
			root, Vector3(1.8, 1.4, 1.2), Vector3(0.0, 0.7, 0.0), LAYER_ENVIRONMENT
		)
	_configs.append(recycler)

	# Fabricator module — BoxShape3D matching SOP dimensions (2.0m x 1.2m x 1.0m)
	# Z-axis mesh extends slightly beyond the 1.0m collision box (~0.83 coverage)
	var fabricator := ModelConfig.new()
	fabricator.label = "fabricator_module"
	fabricator.scene_path = "res://assets/meshes/machines/mesh_fabricator_module.glb"
	fabricator.scale = Vector3.ONE
	fabricator.position = Vector3(MODEL_SPACING * 2.0, 0.0, 0.0)
	fabricator.collision_mask = LAYER_ENVIRONMENT
	fabricator.expect_solid = true
	fabricator.max_allowed_gaps = 0
	fabricator.coverage_threshold = 0.80
	fabricator.collision_setup = func(root: Node3D) -> StaticBody3D:
		return _create_box_collision(
			root, Vector3(2.0, 1.2, 1.0), Vector3(0.0, 0.6, 0.0), LAYER_ENVIRONMENT
		)
	_configs.append(fabricator)

	# Resource node (scrap) — SphereShape3D matching test_world.gd deposit collision
	var resource_node := ModelConfig.new()
	resource_node.label = "resource_node"
	resource_node.scene_path = "res://assets/meshes/props/mesh_resource_node_scrap.glb"
	resource_node.scale = Vector3(3.2, 3.2, 3.2)
	resource_node.mesh_offset = Vector3(0.0, 0.9, 0.0)
	resource_node.position = Vector3(MODEL_SPACING * 3.0, 0.0, 0.0)
	resource_node.collision_mask = LAYER_INTERACTABLE
	resource_node.expect_solid = true
	resource_node.max_allowed_gaps = 0
	resource_node.coverage_threshold = DEFAULT_COVERAGE_THRESHOLD
	resource_node.collision_setup = func(root: Node3D) -> StaticBody3D:
		return _create_sphere_collision(
			root, 1.5, Vector3(0.0, 0.9, 0.0), LAYER_INTERACTABLE
		)
	_configs.append(resource_node)


## Converts a height fraction to a short tag for test names (e.g., 0.1 → "h10", 0.55 → "h55").
func _height_tag(fraction: float) -> String:
	return "h%d" % int(fraction * 100.0)


func _spawn_all_models() -> void:
	for i: int in range(_configs.size()):
		var config: ModelConfig = _configs[i] as ModelConfig
		if not config.expect_solid:
			continue
		var scene: PackedScene = load(config.scene_path) as PackedScene
		if not scene:
			push_warning("CollisionCoverageTest: could not load %s" % config.scene_path)
			continue

		var root := Node3D.new()
		root.name = "Model_%s" % config.label
		root.position = config.position
		add_child(root)

		var mesh_node: Node3D = scene.instantiate()
		mesh_node.name = "Mesh"
		mesh_node.scale = config.scale
		mesh_node.position = config.mesh_offset
		root.add_child(mesh_node)

		# Compute mesh AABB relative to root from all MeshInstance3D descendants
		var mesh_aabb: AABB = _compute_mesh_aabb(root, mesh_node)

		# Attach collision via config's callable
		var body: StaticBody3D = config.collision_setup.call(root) as StaticBody3D

		_spawned_models[config.label] = {
			"root": root,
			"mesh_node": mesh_node,
			"body": body,
			"mesh_aabb": mesh_aabb,
		}


func _create_box_collision(
	parent: Node3D, size: Vector3, offset: Vector3, layer: int
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	body.collision_layer = layer
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	col.name = "CollisionShape"
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = offset
	body.add_child(col)
	parent.add_child(body)
	return body


func _create_sphere_collision(
	parent: Node3D, radius: float, offset: Vector3, layer: int
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	body.collision_layer = layer
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	col.name = "CollisionShape"
	var shape := SphereShape3D.new()
	shape.radius = radius
	col.shape = shape
	col.position = offset
	body.add_child(col)
	parent.add_child(body)
	return body


## Creates VHACD convex decomposition collision matching the ship's test_world.gd setup.
func _create_vhacd_collision(root: Node3D) -> StaticBody3D:
	var mesh_node: Node3D = root.get_node("Mesh")
	var decomp := MeshConvexDecompositionSettings.new()
	decomp.max_convex_hulls = 64
	decomp.resolution = 100000
	decomp.max_num_vertices_per_convex_hull = 64
	for child: Node in mesh_node.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).create_multiple_convex_collisions(decomp)
			for body_child: Node in child.get_children():
				if body_child is StaticBody3D:
					(body_child as StaticBody3D).collision_layer = LAYER_ENVIRONMENT
					(body_child as StaticBody3D).collision_mask = 0
					return body_child as StaticBody3D
			break
	push_warning("CollisionCoverageTest: VHACD failed to generate collision for %s" % root.name)
	return null


## Computes the combined AABB of all MeshInstance3D descendants relative to root.
func _compute_mesh_aabb(root: Node3D, mesh_node: Node3D) -> AABB:
	var combined := AABB()
	var found_mesh: bool = false

	var descendants: Array[Node] = _get_all_descendants(mesh_node)
	# Include mesh_node itself if it is a MeshInstance3D
	descendants.insert(0, mesh_node)

	for node: Node in descendants:
		if not node is MeshInstance3D:
			continue
		var mesh_inst: MeshInstance3D = node as MeshInstance3D
		if mesh_inst.mesh == null:
			continue
		var local_aabb: AABB = mesh_inst.mesh.get_aabb()
		# Transform AABB corners from mesh_inst local space to root local space
		var relative_xform: Transform3D = _get_relative_transform(root, mesh_inst)
		var transformed_aabb: AABB = _transform_aabb(relative_xform, local_aabb)
		if not found_mesh:
			combined = transformed_aabb
			found_mesh = true
		else:
			combined = combined.merge(transformed_aabb)

	return combined


## Returns the transform of child relative to parent (parent-space coordinates).
func _get_relative_transform(parent: Node3D, child: Node3D) -> Transform3D:
	return parent.global_transform.affine_inverse() * child.global_transform


## Transforms an AABB by a Transform3D by projecting all 8 corners.
func _transform_aabb(xform: Transform3D, aabb: AABB) -> AABB:
	var pos: Vector3 = aabb.position
	var end_pos: Vector3 = aabb.end
	var corner_0: Vector3 = xform * pos
	var result := AABB(corner_0, Vector3.ZERO)
	result = result.expand(xform * Vector3(end_pos.x, pos.y, pos.z))
	result = result.expand(xform * Vector3(pos.x, end_pos.y, pos.z))
	result = result.expand(xform * Vector3(pos.x, pos.y, end_pos.z))
	result = result.expand(xform * Vector3(end_pos.x, end_pos.y, pos.z))
	result = result.expand(xform * Vector3(end_pos.x, pos.y, end_pos.z))
	result = result.expand(xform * Vector3(pos.x, end_pos.y, end_pos.z))
	result = result.expand(xform * end_pos)
	return result


func _get_all_descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child: Node in node.get_children():
		result.append(child)
		result.append_array(_get_all_descendants(child))
	return result


# ── Inner Classes ─────────────────────────────────────────

## Configuration for a single model to test collision coverage against.
class ModelConfig:
	extends RefCounted

	## Display label used in test names (e.g., "ship_exterior").
	var label: String = ""
	## Resource path to the GLB scene file.
	var scene_path: String = ""
	## In-engine scale applied to the mesh (matches game usage).
	var scale: Vector3 = Vector3.ONE
	## Offset applied to the mesh node relative to its parent (matches game positioning).
	var mesh_offset: Vector3 = Vector3.ZERO
	## World position to isolate this model from others during testing.
	var position: Vector3 = Vector3.ZERO
	## Physics layer mask to probe against.
	var collision_mask: int = 0
	## False for decoration-only props that should not block the player.
	var expect_solid: bool = true
	## Maximum number of clipping gaps permitted (0 = zero tolerance).
	var max_allowed_gaps: int = 0
	## Minimum AABB coverage ratio per axis.
	var coverage_threshold: float = 0.85
	## Number of probe positions per AABB face edge for tangential sweeps.
	var tangential_segment_count: int = 4
	## Maximum tangential clipping gaps allowed (separate from perimeter gaps).
	var tangential_max_allowed_gaps: int = 0
	## Callable that attaches collision to the model root, mirroring in-game collision setup.
	var collision_setup: Callable = Callable()
