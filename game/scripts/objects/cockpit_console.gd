## Cockpit navigation console — triggers the navigation console modal when
## the player interacts. Provides interaction prompt for the HUD system.
## Owner: gameplay-programmer
## Ticket: TICKET-0167
class_name CockpitConsole
extends StaticBody3D


func _ready() -> void:
	add_to_group("interactable")
	Global.log("CockpitConsole: ready")

# ── Public Methods ────────────────────────────────────────

## Returns the interaction prompt dictionary for the HUD prompt system.
func get_interaction_prompt() -> Dictionary:
	return {
		"key": "E",
		"label": "Navigate",
		"hold": false,
	}
