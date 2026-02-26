## Interaction prompt provider for the ship entrance zone.
## Returns contextual prompt data when the player is near the ship entrance.
## Owner: gameplay-programmer
class_name ShipEnterZone
extends Area3D

# ── Private Variables ─────────────────────────────────────
var _prompt_enabled: bool = true

# ── Public Methods ────────────────────────────────────────

## Returns the interaction prompt dictionary for the ship entrance.
## Returns empty when prompt is disabled (e.g., player is already inside the ship).
func get_interaction_prompt() -> Dictionary:
	if not _prompt_enabled:
		return {}
	return {
		"key": "E",
		"label": "Enter Ship",
		"hold": false,
	}

## Enables or disables the interaction prompt (disable when player is inside ship).
func set_prompt_enabled(enabled: bool) -> void:
	_prompt_enabled = enabled
