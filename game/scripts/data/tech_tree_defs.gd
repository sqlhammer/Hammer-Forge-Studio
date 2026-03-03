## Canonical data definitions for all tech tree nodes.
## Add new nodes here for future milestones — no changes to TechTree core required.
class_name TechTreeDefs
extends RefCounted

# ── Constants ─────────────────────────────────────────────

## Tech tree node catalog — keyed by unique node ID.
## Each entry defines display_name, unlock_cost (resource type + quantity), and prerequisites.
## Prerequisites are a list of node IDs that must be unlocked before this node can be purchased.
const TECH_TREE_CATALOG: Dictionary = {
	"fabricator_module": {
		"display_name": "Fabricator",
		"icon": "res://assets/icons/item/icon_item_module_fabricator.svg",
		"unlock_cost": {
			"resource_type": ResourceDefs.ResourceType.METAL,
			"quantity": 1,
		},
		"prerequisites": [],
	},
	"automation_hub": {
		"display_name": "Automation Hub",
		"icon": "res://assets/icons/item/icon_item_module_automation_hub.svg",
		# Placeholder — confirm unlock cost with Studio Head before TICKET-0064 implementation.
		"unlock_cost": {
			"resource_type": ResourceDefs.ResourceType.METAL,
			"quantity": 2,
		},
		"prerequisites": ["fabricator_module"],
	},
}

# ── Static Helpers ────────────────────────────────────────

## Returns the catalog entry for a node ID, or empty dict if not found.
static func get_node_entry(node_id: String) -> Dictionary:
	return TECH_TREE_CATALOG.get(node_id, {})

## Returns the display name for a node ID.
static func get_display_name(node_id: String) -> String:
	var entry: Dictionary = TECH_TREE_CATALOG.get(node_id, {})
	return entry.get("display_name", "Unknown") as String

## Returns the unlock cost dictionary for a node ID (resource_type, quantity).
static func get_unlock_cost(node_id: String) -> Dictionary:
	var entry: Dictionary = TECH_TREE_CATALOG.get(node_id, {})
	return entry.get("unlock_cost", {})

## Returns the prerequisite node IDs for a node ID.
static func get_prerequisites(node_id: String) -> Array[String]:
	var entry: Dictionary = TECH_TREE_CATALOG.get(node_id, {})
	var result: Array[String] = []
	var raw: Array[String] = entry.get("prerequisites", [] as Array[String])
	for item: Variant in raw:
		result.append(item as String)
	return result

## Returns the icon path for a node ID, or empty string if none defined.
static func get_icon_path(node_id: String) -> String:
	var entry: Dictionary = TECH_TREE_CATALOG.get(node_id, {})
	return entry.get("icon", "") as String

## Returns all node IDs in the catalog.
static func get_all_node_ids() -> Array[String]:
	var ids: Array[String] = []
	for key: String in TECH_TREE_CATALOG.keys():
		ids.append(key)
	return ids
