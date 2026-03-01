## Cockpit navigation console — triggers the navigation console modal when
## the player interacts. Physical collision body only; interaction prompt is
## provided by CockpitConsolePromptArea (area-based detection, TICKET-0245).
## Owner: gameplay-programmer
## Ticket: TICKET-0167
class_name CockpitConsole
extends StaticBody3D

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	collision_layer = PhysicsLayers.INTERACTABLE
	collision_mask = 0
	Global.log("CockpitConsole: ready")
