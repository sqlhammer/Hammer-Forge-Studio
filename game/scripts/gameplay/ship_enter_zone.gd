## Interaction prompt provider for the ship entrance zone.
## Returns contextual prompt data when the player is near the ship entrance.
## Owner: gameplay-programmer
class_name ShipEnterZone
extends Area3D

# ── Private Variables ─────────────────────────────────────
var _prompt_enabled: bool = true
var _aim_valid: bool = false

# ── Public Methods ────────────────────────────────────────

## Returns the interaction prompt dictionary for the ship entrance.
## Returns empty when prompt is disabled (e.g., player is already inside the ship)
## or when the player is not aiming at the ship hull.
func get_interaction_prompt() -> Dictionary:
	if not _prompt_enabled or not _aim_valid:
		return {}
	return {
		"key": "E",
		"action": "interact",
		"label": "Enter Ship",
		"hold": false,
	}

## Enables or disables the interaction prompt (disable when player is inside ship).
func set_prompt_enabled(enabled: bool) -> void:
	_prompt_enabled = enabled

## Sets whether the player is currently aiming at the ship hull.
## Called per-frame by DebugShipBoardingHandler to sync prompt with aim check.
func set_aim_valid(valid: bool) -> void:
	_aim_valid = valid
