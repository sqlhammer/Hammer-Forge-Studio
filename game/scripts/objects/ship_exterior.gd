## Ship exterior wrapper: generates VHACD convex hull collision from the ship mesh,
## provides a recharge zone and entrance marker for the ship hull.
## Drives suit battery recharge directly when the player enters the recharge zone,
## eliminating the need for per-scene signal wiring (TICKET-0217).
class_name ShipExterior
extends StaticBody3D

# ── Signals ──────────────────────────────────────────────
signal recharge_zone_entered(body: Node3D)
signal recharge_zone_exited(body: Node3D)
signal ship_position_changed(new_position: Vector3)

# ── Constants ─────────────────────────────────────────────
const DECOMP_MAX_HULLS: int = 64
const DECOMP_RESOLUTION: int = 100000
const DECOMP_MAX_VERTS: int = 64

# ── Private Variables ─────────────────────────────────────
var _player_in_recharge_zone: bool = false

# ── Onready Variables ─────────────────────────────────────
@onready var _recharge_zone: Area3D = $RechargeZone
@onready var _ship_mesh: Node3D = $ShipMesh

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	add_to_group("ship")
	_generate_hull_collision()
	_recharge_zone.body_entered.connect(_on_body_entered_recharge)
	_recharge_zone.body_exited.connect(_on_body_exited_recharge)
	Global.log("ShipExterior: ready")

func _process(delta: float) -> void:
	if _player_in_recharge_zone:
		if not SuitBattery.is_recharging() and SuitBattery.get_charge_percent() < 1.0:
			SuitBattery.start_recharge()
		if SuitBattery.is_recharging():
			SuitBattery.process_recharge(delta)

# ── Public Methods ───────────────────────────────────────

## Returns true if the given body is currently inside the recharge zone.
func is_body_in_recharge_zone(body: Node3D) -> bool:
	if not _recharge_zone:
		return false
	return _recharge_zone.get_overlapping_bodies().has(body)

# ── Private Methods ───────────────────────────────────────

## Generates VHACD convex decomposition collision from the ship mesh geometry.
## Replaces the box primitive that was incorrectly set during the scene refactor.
func _generate_hull_collision() -> void:
	if not _ship_mesh:
		push_error("ShipExterior: ShipMesh node not found — cannot generate collision")
		return

	var decomp := MeshConvexDecompositionSettings.new()
	decomp.max_convex_hulls = DECOMP_MAX_HULLS
	decomp.resolution = DECOMP_RESOLUTION
	decomp.max_num_vertices_per_convex_hull = DECOMP_MAX_VERTS

	for child: Node in _ship_mesh.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).create_multiple_convex_collisions(decomp)
			# Set physics layers on the generated StaticBody3D
			for body_child: Node in child.get_children():
				if body_child is StaticBody3D:
					(body_child as StaticBody3D).collision_layer = PhysicsLayers.ENVIRONMENT
					(body_child as StaticBody3D).collision_mask = 0
			Global.log("ShipExterior: VHACD hull collision generated")
			break

func _on_body_entered_recharge(body: Node3D) -> void:
	recharge_zone_entered.emit(body)
	if body.collision_layer & PhysicsLayers.PLAYER != 0:
		_player_in_recharge_zone = true
		Global.log("ShipExterior: player entered recharge zone")

func _on_body_exited_recharge(body: Node3D) -> void:
	recharge_zone_exited.emit(body)
	if body.collision_layer & PhysicsLayers.PLAYER != 0:
		_player_in_recharge_zone = false
		if SuitBattery.is_recharging():
			SuitBattery.stop_recharge()
		Global.log("ShipExterior: player exited recharge zone")
