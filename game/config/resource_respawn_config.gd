## Per-resource-type respawn delay configuration for surface deposits.
## Single source of truth for all respawn timers — no magic numbers in deposit logic.
## To add a new resource type, add an entry to RESPAWN_TIMES.
## Owner: gameplay-programmer
class_name ResourceRespawnConfig
extends RefCounted

# ── Constants ─────────────────────────────────────────────

## Respawn delay in seconds per resource type.
## Used by Deposit when a surface node is fully depleted.
const RESPAWN_TIMES: Dictionary = {
	ResourceDefs.ResourceType.SCRAP_METAL: 5 * 60,
	ResourceDefs.ResourceType.METAL: 5 * 60,
	ResourceDefs.ResourceType.SPARE_BATTERY: 5 * 60,
	ResourceDefs.ResourceType.CRYONITE: 5 * 60,
	ResourceDefs.ResourceType.FUEL_CELL: 5 * 60,
}

## Fallback respawn delay used when a resource type has no entry in RESPAWN_TIMES.
const DEFAULT_RESPAWN_TIME: float = 300.0

# ── Static Helpers ────────────────────────────────────────

## Returns the respawn delay in seconds for the given resource type.
static func get_respawn_time(resource_type: ResourceDefs.ResourceType) -> float:
	return RESPAWN_TIMES.get(resource_type, DEFAULT_RESPAWN_TIME) as float
