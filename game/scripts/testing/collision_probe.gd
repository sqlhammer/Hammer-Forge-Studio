## Reusable collision probe utility for sweep-testing a player-sized capsule against 3D models.
## Uses PhysicsServer3D.body_test_motion() for synchronous collision detection without physics frames.
class_name CollisionProbe
extends RefCounted


# ── Constants ─────────────────────────────────────────────
const CAPSULE_RADIUS: float = 0.4
const CAPSULE_HEIGHT: float = 1.8
const SQRT_HALF: float = 0.70711
const SIN_22_5: float = 0.38268
const COS_22_5: float = 0.92388


# ── Private Variables ─────────────────────────────────────
var _probe_body: CharacterBody3D = null
var _direction_vectors: Dictionary = {}


# ── Public Methods ────────────────────────────────────────

## Creates a player-sized capsule probe body and adds it to the scene tree under parent.
func setup(parent: Node) -> void:
	_build_direction_vectors()

	_probe_body = CharacterBody3D.new()
	_probe_body.name = "CollisionProbe"
	_probe_body.collision_layer = 1 << 0
	_probe_body.collision_mask = (1 << 2) | (1 << 3)

	var col_shape := CollisionShape3D.new()
	col_shape.name = "ProbeShape"
	var capsule := CapsuleShape3D.new()
	capsule.radius = CAPSULE_RADIUS
	capsule.height = CAPSULE_HEIGHT
	col_shape.shape = capsule
	col_shape.position.y = CAPSULE_HEIGHT / 2.0
	_probe_body.add_child(col_shape)

	parent.add_child(_probe_body)


## Removes the probe body from the scene tree and frees resources.
func teardown() -> void:
	if is_instance_valid(_probe_body):
		_probe_body.queue_free()
	_probe_body = null


## Sweeps the probe from origin toward target_center and checks for collision against target_aabb.
func sweep_toward(origin: Vector3, target_center: Vector3, target_aabb: AABB, mask: int, distance: float) -> ProbeResult:
	var direction: Vector3 = (target_center - origin).normalized()
	_probe_body.global_position = origin
	_probe_body.collision_mask = mask

	var params := PhysicsTestMotionParameters3D.new()
	params.from = _probe_body.global_transform
	params.motion = direction * distance

	var motion_result := PhysicsTestMotionResult3D.new()
	var hit: bool = PhysicsServer3D.body_test_motion(_probe_body.get_rid(), params, motion_result)

	var result := ProbeResult.new()
	result.direction_label = "custom"
	result.hit_collision = hit
	if hit:
		result.travel_distance = motion_result.get_travel().length()
	else:
		result.travel_distance = distance

	# Gap detection: probe path enters AABB but no collision was detected
	var enters_aabb: bool = _ray_intersects_aabb(origin, direction, distance, target_aabb)
	result.is_clipping_gap = enters_aabb and not hit

	return result


## Sweeps from 16 compass directions at specified height fractions, returning all results.
func sweep_all_directions(center: Vector3, aabb: AABB, mask: int, heights: Array[float], radius_mult: float) -> Array:
	var results: Array = []
	var aabb_size: Vector3 = aabb.size
	var sweep_radius: float = maxf(aabb_size.x, aabb_size.z) * radius_mult

	for height_frac: float in heights:
		var height_label: String = _height_label(height_frac)
		var sweep_y: float = aabb.position.y + aabb_size.y * height_frac

		for dir_name: String in _direction_vectors:
			var dir: Vector3 = _direction_vectors[dir_name]
			var start_x: float = center.x + dir.x * sweep_radius
			var start_z: float = center.z + dir.z * sweep_radius
			var start_pos := Vector3(start_x, sweep_y, start_z)
			var sweep_distance: float = sweep_radius * 2.0
			var inward_dir: Vector3 = -dir

			_probe_body.global_position = start_pos
			_probe_body.collision_mask = mask

			var params := PhysicsTestMotionParameters3D.new()
			params.from = _probe_body.global_transform
			params.motion = inward_dir * sweep_distance

			var motion_result := PhysicsTestMotionResult3D.new()
			var hit: bool = PhysicsServer3D.body_test_motion(
				_probe_body.get_rid(), params, motion_result
			)

			var probe_result := ProbeResult.new()
			probe_result.direction_label = "%s+%s" % [dir_name, height_label]
			probe_result.hit_collision = hit
			if hit:
				probe_result.travel_distance = motion_result.get_travel().length()
			else:
				probe_result.travel_distance = sweep_distance

			var enters_aabb: bool = _ray_intersects_aabb(
				start_pos, inward_dir, sweep_distance, aabb
			)
			probe_result.is_clipping_gap = enters_aabb and not hit

			results.append(probe_result)

	return results


## Sweeps probe tangentially along each AABB face to detect mid-surface gaps between convex hulls.
## Insets sweep range by 15% on each end to avoid AABB-edge artifacts on non-rectangular models.
## center: world-space center of the model. aabb: world-space AABB. mask: collision mask.
## heights: height fractions within the AABB. surface_offset: distance from face to start sweep.
## segment_count: number of probe positions per face edge.
func sweep_tangential(_center: Vector3, aabb: AABB, mask: int, heights: Array[float], surface_offset: float, segment_count: int) -> Array:
	var results: Array = []
	var aabb_min: Vector3 = aabb.position
	var aabb_max: Vector3 = aabb.end
	var aabb_size: Vector3 = aabb.size

	# Inset 15% on each end so sweeps probe the central 70% of each face.
	# Perimeter sweeps already cover AABB edges; tangential sweeps target mid-surface hull gaps.
	var inset_frac: float = 0.25
	var z_range: float = aabb_size.z
	var x_range: float = aabb_size.x
	var z_min_inset: float = aabb_min.z + z_range * inset_frac
	var z_max_inset: float = aabb_max.z - z_range * inset_frac
	var x_min_inset: float = aabb_min.x + x_range * inset_frac
	var x_max_inset: float = aabb_max.x - x_range * inset_frac

	# Four faces: +X, -X, +Z, -Z
	var faces: Array[Dictionary] = [
		{"label": "+X", "normal": Vector3(-1, 0, 0), "origin_x": aabb_max.x + surface_offset, "axis": "z", "min_t": z_min_inset, "max_t": z_max_inset},
		{"label": "-X", "normal": Vector3(1, 0, 0), "origin_x": aabb_min.x - surface_offset, "axis": "z", "min_t": z_min_inset, "max_t": z_max_inset},
		{"label": "+Z", "normal": Vector3(0, 0, -1), "origin_z": aabb_max.z + surface_offset, "axis": "x", "min_t": x_min_inset, "max_t": x_max_inset},
		{"label": "-Z", "normal": Vector3(0, 0, 1), "origin_z": aabb_min.z - surface_offset, "axis": "x", "min_t": x_min_inset, "max_t": x_max_inset},
	]

	for height_frac: float in heights:
		var sweep_y: float = aabb_min.y + aabb_size.y * height_frac
		var h_label: String = _height_label(height_frac)

		for face: Dictionary in faces:
			var face_label: String = face["label"]
			var normal: Vector3 = face["normal"]
			var sweep_distance: float = maxf(aabb_size.x, aabb_size.z) + surface_offset * 2.0
			var min_t: float = face["min_t"]
			var max_t: float = face["max_t"]

			for seg: int in range(segment_count):
				var t: float = min_t + (max_t - min_t) * (float(seg) + 0.5) / float(segment_count)
				var start_pos: Vector3
				if face["axis"] == "z":
					start_pos = Vector3(face.get("origin_x", 0.0), sweep_y, t)
				else:
					start_pos = Vector3(t, sweep_y, face.get("origin_z", 0.0))

				_probe_body.global_position = start_pos
				_probe_body.collision_mask = mask

				var params := PhysicsTestMotionParameters3D.new()
				params.from = _probe_body.global_transform
				params.motion = normal * sweep_distance

				var motion_result := PhysicsTestMotionResult3D.new()
				var hit: bool = PhysicsServer3D.body_test_motion(
					_probe_body.get_rid(), params, motion_result
				)

				var probe_result := ProbeResult.new()
				probe_result.direction_label = "tan_%s+%s_s%d" % [face_label, h_label, seg]
				probe_result.hit_collision = hit
				if hit:
					probe_result.travel_distance = motion_result.get_travel().length()
				else:
					probe_result.travel_distance = sweep_distance

				var enters_aabb: bool = _ray_intersects_aabb(
					start_pos, normal, sweep_distance, aabb
				)
				probe_result.is_clipping_gap = enters_aabb and not hit

				results.append(probe_result)

	return results


## Compares combined collision shape AABB against mesh AABB, returns per-axis coverage ratios.
## Both AABBs are computed in reference node's local space for accurate comparison
## when collision bodies are nested inside scaled mesh hierarchies.
func check_aabb_coverage(body: StaticBody3D, mesh_aabb: AABB, reference: Node3D) -> Dictionary:
	var combined_aabb := AABB()
	var found_shape: bool = false
	var ref_inv: Transform3D = reference.global_transform.affine_inverse()

	for child: Node in body.get_children():
		if not child is CollisionShape3D:
			continue
		var col_child: CollisionShape3D = child as CollisionShape3D
		if col_child.shape == null:
			continue
		var shape_aabb: AABB = _get_shape_aabb(col_child.shape)
		# Transform shape AABB from shape-local space to reference-local space
		var shape_to_ref: Transform3D = ref_inv * col_child.global_transform
		var transformed: AABB = _transform_aabb(shape_to_ref, shape_aabb)
		if not found_shape:
			combined_aabb = transformed
			found_shape = true
		else:
			combined_aabb = combined_aabb.merge(transformed)

	if not found_shape:
		return {"x": 0.0, "y": 0.0, "z": 0.0}

	var mesh_size: Vector3 = mesh_aabb.size
	var col_size: Vector3 = combined_aabb.size
	return {
		"x": col_size.x / maxf(mesh_size.x, 0.001),
		"y": col_size.y / maxf(mesh_size.y, 0.001),
		"z": col_size.z / maxf(mesh_size.z, 0.001),
	}


# ── Private Methods ───────────────────────────────────────

func _build_direction_vectors() -> void:
	_direction_vectors = {
		"N": Vector3(0.0, 0.0, -1.0),
		"NNE": Vector3(SIN_22_5, 0.0, -COS_22_5),
		"NE": Vector3(SQRT_HALF, 0.0, -SQRT_HALF),
		"ENE": Vector3(COS_22_5, 0.0, -SIN_22_5),
		"E": Vector3(1.0, 0.0, 0.0),
		"ESE": Vector3(COS_22_5, 0.0, SIN_22_5),
		"SE": Vector3(SQRT_HALF, 0.0, SQRT_HALF),
		"SSE": Vector3(SIN_22_5, 0.0, COS_22_5),
		"S": Vector3(0.0, 0.0, 1.0),
		"SSW": Vector3(-SIN_22_5, 0.0, COS_22_5),
		"SW": Vector3(-SQRT_HALF, 0.0, SQRT_HALF),
		"WSW": Vector3(-COS_22_5, 0.0, SIN_22_5),
		"W": Vector3(-1.0, 0.0, 0.0),
		"WNW": Vector3(-COS_22_5, 0.0, -SIN_22_5),
		"NW": Vector3(-SQRT_HALF, 0.0, -SQRT_HALF),
		"NNW": Vector3(-SIN_22_5, 0.0, -COS_22_5),
	}


## Returns the local AABB for a physics shape.
func _get_shape_aabb(shape: Shape3D) -> AABB:
	if shape is BoxShape3D:
		var box: BoxShape3D = shape as BoxShape3D
		return AABB(-box.size / 2.0, box.size)
	elif shape is SphereShape3D:
		var sphere: SphereShape3D = shape as SphereShape3D
		var diameter: float = sphere.radius * 2.0
		var radius_vec := Vector3(sphere.radius, sphere.radius, sphere.radius)
		return AABB(-radius_vec, Vector3(diameter, diameter, diameter))
	elif shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = shape as CapsuleShape3D
		var half_height: float = capsule.height / 2.0
		var diameter: float = capsule.radius * 2.0
		return AABB(
			Vector3(-capsule.radius, -half_height, -capsule.radius),
			Vector3(diameter, capsule.height, diameter)
		)
	elif shape is ConvexPolygonShape3D:
		var convex: ConvexPolygonShape3D = shape as ConvexPolygonShape3D
		var points: PackedVector3Array = convex.points
		if points.size() == 0:
			return AABB(Vector3.ZERO, Vector3.ZERO)
		var result := AABB(points[0], Vector3.ZERO)
		for i: int in range(1, points.size()):
			result = result.expand(points[i])
		return result
	# Fallback for other shape types
	return AABB(Vector3(-0.5, -0.5, -0.5), Vector3.ONE)


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


## Ray-AABB intersection test using the slab method.
func _ray_intersects_aabb(origin: Vector3, direction: Vector3, max_distance: float, aabb: AABB) -> bool:
	var aabb_min: Vector3 = aabb.position
	var aabb_max: Vector3 = aabb.end
	var t_min: float = 0.0
	var t_max: float = max_distance

	# X axis slab
	if absf(direction.x) < 0.0001:
		if origin.x < aabb_min.x or origin.x > aabb_max.x:
			return false
	else:
		var inv_d: float = 1.0 / direction.x
		var t1: float = (aabb_min.x - origin.x) * inv_d
		var t2: float = (aabb_max.x - origin.x) * inv_d
		if t1 > t2:
			var temp: float = t1
			t1 = t2
			t2 = temp
		t_min = maxf(t_min, t1)
		t_max = minf(t_max, t2)
		if t_min > t_max:
			return false

	# Y axis slab
	if absf(direction.y) < 0.0001:
		if origin.y < aabb_min.y or origin.y > aabb_max.y:
			return false
	else:
		var inv_d: float = 1.0 / direction.y
		var t1: float = (aabb_min.y - origin.y) * inv_d
		var t2: float = (aabb_max.y - origin.y) * inv_d
		if t1 > t2:
			var temp: float = t1
			t1 = t2
			t2 = temp
		t_min = maxf(t_min, t1)
		t_max = minf(t_max, t2)
		if t_min > t_max:
			return false

	# Z axis slab
	if absf(direction.z) < 0.0001:
		if origin.z < aabb_min.z or origin.z > aabb_max.z:
			return false
	else:
		var inv_d: float = 1.0 / direction.z
		var t1: float = (aabb_min.z - origin.z) * inv_d
		var t2: float = (aabb_max.z - origin.z) * inv_d
		if t1 > t2:
			var temp: float = t1
			t1 = t2
			t2 = temp
		t_min = maxf(t_min, t1)
		t_max = minf(t_max, t2)
		if t_min > t_max:
			return false

	return true


## Converts a height fraction to a readable label.
func _height_label(fraction: float) -> String:
	if fraction <= 0.2:
		return "low"
	elif fraction >= 0.8:
		return "high"
	return "mid"


# ── Inner Classes ─────────────────────────────────────────

## Result of a single collision probe sweep.
class ProbeResult:
	extends RefCounted

	## Direction label for identification (e.g., "NE+mid").
	var direction_label: String = ""
	## Whether the sweep hit any collision shape.
	var hit_collision: bool = false
	## Distance traveled before collision (or full distance if no hit).
	var travel_distance: float = 0.0
	## True if probe entered mesh AABB without collision — indicates a clipping gap.
	var is_clipping_gap: bool = false
