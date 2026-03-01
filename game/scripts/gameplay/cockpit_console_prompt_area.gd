## Interaction prompt provider for the cockpit navigation console area.
## Returns contextual prompt data when the player is near the cockpit console.
## Owner: gameplay-programmer
## Ticket: TICKET-0245
class_name CockpitConsolePromptArea
extends Area3D

# ── Public Methods ────────────────────────────────────────

## Returns the interaction prompt dictionary for the cockpit console.
## Resolves the interact key dynamically from the InputMap so the label
## updates immediately if the player remaps the action mid-session.
func get_interaction_prompt() -> Dictionary:
	var key_label: String = _get_interact_key_label()
	return {
		"key": key_label,
		"label": "Navigate",
		"hold": false,
	}

# ── Private Methods ───────────────────────────────────────

## Resolves the current key label for the "interact" action from the InputMap.
func _get_interact_key_label() -> String:
	var events: Array[InputEvent] = InputMap.action_get_events("interact")
	for event: InputEvent in events:
		if event is InputEventKey:
			var key_event: InputEventKey = event as InputEventKey
			return OS.get_keycode_string(key_event.keycode)
	return "E"
