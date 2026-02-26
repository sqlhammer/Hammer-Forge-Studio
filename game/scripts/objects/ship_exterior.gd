## Ship exterior wrapper: provides a recharge zone and entrance marker for the ship hull.
class_name ShipExterior
extends StaticBody3D

# ── Signals ──────────────────────────────────────────────
signal recharge_zone_entered(body: Node3D)
signal recharge_zone_exited(body: Node3D)

# ── Onready Variables ─────────────────────────────────────
@onready var _recharge_zone: Area3D = $RechargeZone

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_recharge_zone.body_entered.connect(_on_body_entered_recharge)
	_recharge_zone.body_exited.connect(_on_body_exited_recharge)
	Global.log("ShipExterior: ready")

# ── Public Methods ───────────────────────────────────────

## Returns true if the given body is currently inside the recharge zone.
func is_body_in_recharge_zone(body: Node3D) -> bool:
	if not _recharge_zone:
		return false
	return _recharge_zone.get_overlapping_bodies().has(body)

# ── Private Methods ───────────────────────────────────────

func _on_body_entered_recharge(body: Node3D) -> void:
	recharge_zone_entered.emit(body)

func _on_body_exited_recharge(body: Node3D) -> void:
	recharge_zone_exited.emit(body)
