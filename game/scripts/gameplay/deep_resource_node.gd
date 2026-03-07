## Deep resource node — partially submerged deposit that yields indefinitely.
## Mines slowly for manual extraction; drones can mine these forever without depletion.
## Owner: gameplay-programmer
class_name DeepResourceNode
extends Deposit


# ── Constants ─────────────────────────────────────────────

## Default yield rate for deep nodes (10% of surface speed).
const DEEP_YIELD_RATE: float = 0.1

## Y offset to submerge the visual mesh below ground level.
const SUBMERGE_OFFSET: float = -0.5


# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	# Enforce deep node invariants — scene editor sets these too, but
	# programmatic creation (DeepResourceNode.new()) needs enforcement.
	infinite = true
	drone_accessible = true
	if yield_rate >= 1.0:
		yield_rate = DEEP_YIELD_RATE
	# Deep nodes are fully underground — hide visual meshes so they don't
	# protrude through the terrain surface as floating dots.  Scanner
	# detection uses Area3D collision which is unaffected by visibility.
	visible = false
	super._ready()
	Global.debug_log("DeepResourceNode: ready at %s (resource=%s, yield_rate=%f)" % [
		str(global_position), ResourceDefs.get_resource_name(resource_type), yield_rate])
