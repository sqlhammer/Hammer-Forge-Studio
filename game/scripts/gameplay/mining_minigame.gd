## Visual pattern lines for the mining minigame, displayed on a deposit during extraction.
## Parented to a Deposit node — lines are defined in local space and scale with this node.
## Owner: gameplay-programmer
class_name MiningMinigame
extends Node3D

# ── Constants ─────────────────────────────────────────────

## 3D line visual dimensions (local space — scaled by this node's transform)
const LINE_MESH_LENGTH: float = 0.4375
const LINE_MESH_HEIGHT: float = 0.0375
const LINE_MESH_DEPTH: float = 0.01875

## Line glow colors
const COLOR_LINE_PENDING := Color("#00D4AA")  # Teal
const COLOR_LINE_TRACED := Color("#4ADE80")  # Green

## Line offsets in local space (X=right, Y=up, -Z=toward player after look_at).
## Normalized for scale 1.0 — this node's scale controls final world-space size.
const LINE_OFFSETS: Array = [
	Vector3(0.0, -0.094, -0.422),
	Vector3(0.078, 0.156, -0.375),
	Vector3(-0.063, 0.375, -0.313),
	Vector3(0.125, 0.031, -0.406),
]

## Base crosshair-to-line proximity radius at scale 1.0
const BASE_TRACE_RADIUS: float = 0.141

# ── Private Variables ─────────────────────────────────────

var _line_meshes: Array[MeshInstance3D] = []
var _line_materials: Array[StandardMaterial3D] = []
var _line_count: int = 0

# ── Public Methods ────────────────────────────────────────

## Creates pattern lines oriented toward the player.
func create_lines(line_count: int, player_global_position: Vector3) -> void:
	cleanup()
	_line_count = line_count

	# Orient this node so local -Z faces the player (Y-axis rotation only)
	var look_target: Vector3 = player_global_position
	look_target.y = global_position.y
	if global_position.distance_squared_to(look_target) > 0.01:
		look_at(look_target, Vector3.UP)

	for i: int in range(line_count):
		var offset: Vector3 = LINE_OFFSETS[i]

		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "PatternLine%d" % i
		var box := BoxMesh.new()
		box.size = Vector3(LINE_MESH_LENGTH, LINE_MESH_HEIGHT, LINE_MESH_DEPTH)
		mesh_inst.mesh = box

		var mat := StandardMaterial3D.new()
		mat.albedo_color = COLOR_LINE_PENDING
		mat.emission_enabled = true
		mat.emission = COLOR_LINE_PENDING
		mat.emission_energy_multiplier = 2.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh_inst.material_override = mat

		add_child(mesh_inst)
		mesh_inst.position = offset

		_line_meshes.append(mesh_inst)
		_line_materials.append(mat)


## Returns the world position of a specific pattern line.
func get_line_world_position(index: int) -> Vector3:
	if index >= 0 and index < _line_meshes.size():
		return _line_meshes[index].global_position
	return Vector3.ZERO


## Returns world positions of all pattern lines.
func get_line_world_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for mesh: MeshInstance3D in _line_meshes:
		positions.append(mesh.global_position)
	return positions


## Returns the number of active pattern lines.
func get_line_count() -> int:
	return _line_count


## Returns the trace detection radius scaled by this node's transform.
func get_trace_radius() -> float:
	return BASE_TRACE_RADIUS * scale.x


## Marks a pattern line as successfully traced (changes color from teal to green).
func mark_line_traced(index: int) -> void:
	if index >= 0 and index < _line_materials.size():
		_line_materials[index].albedo_color = COLOR_LINE_TRACED
		_line_materials[index].emission = COLOR_LINE_TRACED


## Removes all pattern line meshes and resets state.
func cleanup() -> void:
	for mesh: MeshInstance3D in _line_meshes:
		if is_instance_valid(mesh):
			mesh.queue_free()
	_line_meshes.clear()
	_line_materials.clear()
	_line_count = 0
