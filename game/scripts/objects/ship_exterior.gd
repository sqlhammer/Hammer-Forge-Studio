## Ship exterior wrapper: loads the mesh, generates collision, provides a recharge zone and entrance marker.
class_name ShipExterior
extends Node3D

# ── Signals ──────────────────────────────────────────────
signal recharge_zone_entered(body: Node3D)
signal recharge_zone_exited(body: Node3D)

# ── Constants ─────────────────────────────────────────────
const MESH_PATH: String = "res://assets/meshes/vehicles/mesh_ship_exterior.glb"
const MESH_SCALE := Vector3(24.0, 24.0, 24.0)
const MESH_Y_OFFSET: float = 6.5

const RECHARGE_BOX_SIZE := Vector3(32.0, 15.0, 52.0)
const RECHARGE_BOX_Y: float = 4.5

const DECOMP_MAX_HULLS: int = 64
const DECOMP_RESOLUTION: int = 100000
const DECOMP_MAX_VERTS: int = 64

const LAYER_PLAYER: int = 1 << 0   # Layer 1
const LAYER_ENVIRONMENT: int = 1 << 2  # Layer 3

# ── Private Variables ─────────────────────────────────────
var _recharge_zone: Area3D = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_build_mesh()
	_build_recharge_zone()
	_build_entrance_marker()
	Global.log("ShipExterior: ready")

# ── Private Methods ───────────────────────────────────────

func _build_mesh() -> void:
	var ship_scene: Resource = load(MESH_PATH)
	if not ship_scene or not ship_scene is PackedScene:
		push_error("ShipExterior: failed to load mesh at %s" % MESH_PATH)
		return

	var ship_mesh: Node3D = (ship_scene as PackedScene).instantiate()
	ship_mesh.name = "ShipMesh"
	ship_mesh.scale = MESH_SCALE
	ship_mesh.position.y = MESH_Y_OFFSET
	add_child(ship_mesh)

	# Generate convex decomposition collision from mesh geometry
	var decomp := MeshConvexDecompositionSettings.new()
	decomp.max_convex_hulls = DECOMP_MAX_HULLS
	decomp.resolution = DECOMP_RESOLUTION
	decomp.max_num_vertices_per_convex_hull = DECOMP_MAX_VERTS
	for child: Node in ship_mesh.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).create_multiple_convex_collisions(decomp)
			for body_child: Node in child.get_children():
				if body_child is StaticBody3D:
					(body_child as StaticBody3D).collision_layer = LAYER_ENVIRONMENT
					(body_child as StaticBody3D).collision_mask = 0
			break

func _build_recharge_zone() -> void:
	_recharge_zone = Area3D.new()
	_recharge_zone.name = "RechargeZone"
	_recharge_zone.collision_layer = 0
	_recharge_zone.collision_mask = LAYER_PLAYER

	var recharge_col := CollisionShape3D.new()
	var recharge_shape := BoxShape3D.new()
	recharge_shape.size = RECHARGE_BOX_SIZE
	recharge_col.shape = recharge_shape
	recharge_col.position.y = RECHARGE_BOX_Y
	_recharge_zone.add_child(recharge_col)
	add_child(_recharge_zone)

	_recharge_zone.body_entered.connect(_on_body_entered_recharge)
	_recharge_zone.body_exited.connect(_on_body_exited_recharge)

func _build_entrance_marker() -> void:
	var marker := Marker3D.new()
	marker.name = "EntranceDoor"
	marker.position = Vector3(0.0, 0.0, 23.0)
	add_child(marker)

func _on_body_entered_recharge(body: Node3D) -> void:
	recharge_zone_entered.emit(body)

func _on_body_exited_recharge(body: Node3D) -> void:
	recharge_zone_exited.emit(body)
