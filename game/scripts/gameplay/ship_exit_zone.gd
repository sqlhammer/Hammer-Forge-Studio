## Interaction prompt provider for the ship interior exit zone.
## Returns contextual prompt data when the player is near the ship exit.
## Owner: gameplay-programmer
class_name ShipExitZone
extends Area3D

# ── Private Variables ─────────────────────────────────────
var _prompt_enabled: bool = true

# ── Public Methods ────────────────────────────────────────

## Returns the interaction prompt dictionary for the ship exit.
## Resolves the interact key dynamically from the InputMap so the label
## updates immediately if the player remaps the action mid-session.
func get_interaction_prompt() -> Dictionary:
	if not _prompt_enabled:
		return {}
	var key_label: String = _get_interact_key_label()
	return {
		"key": key_label,
		"action": "interact",
		"label": "Exit Ship",
		"hold": false,
	}

## Enables or disables the interaction prompt (disable during transitions).
func set_prompt_enabled(enabled: bool) -> void:
	_prompt_enabled = enabled

# ── Private Methods ───────────────────────────────────────

## Resolves the current key label for the "interact" action from the InputMap.
func _get_interact_key_label() -> String:
	var events: Array[InputEvent] = InputMap.action_get_events("interact")
	for event: InputEvent in events:
		if event is InputEventKey:
			var key_event: InputEventKey = event as InputEventKey
			return OS.get_keycode_string(key_event.keycode)
	return "E"
