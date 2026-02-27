## Canonical biome definitions and symmetric distance matrix for the ship
## navigation system. All biome data and inter-biome travel distances are
## authored here — NavigationSystem delegates lookups to these static methods.
## Ticket: TICKET-0159
class_name BiomeRegistry
extends RefCounted

# ── Constants ─────────────────────────────────────────────

## All registered biome IDs in canonical order.
const BIOME_IDS: PackedStringArray = ["shattered_flats", "rock_warrens", "debris_field"]

## Symmetric inter-biome distance table. Keys are "id_a:id_b" sorted alphabetically
## so that get_distance(A, B) == get_distance(B, A) without a second entry.
## Units match FuelSystemDefs distance expectations (same scale as BIOME_DISTANCE_PLACEHOLDER).
const _DISTANCES: Dictionary = {
	"debris_field:rock_warrens": 1000.0,
	"debris_field:shattered_flats": 1200.0,
	"rock_warrens:shattered_flats": 800.0,
}

# ── Public Methods ────────────────────────────────────────

## Returns true if the given biome ID is registered.
static func is_valid_biome(id: String) -> bool:
	return id in BIOME_IDS


## Returns the BiomeData for the given biome ID, or null if not found.
static func get_biome(id: String) -> BiomeData:
	match id:
		"shattered_flats":
			return _make_shattered_flats()
		"rock_warrens":
			return _make_rock_warrens()
		"debris_field":
			return _make_debris_field()
	return null


## Returns the travel distance between two biome IDs. Returns -1.0 if either ID
## is unknown or the IDs are identical (no travel needed).
static func get_distance(from_id: String, to_id: String) -> float:
	if from_id == to_id:
		return -1.0
	if not is_valid_biome(from_id) or not is_valid_biome(to_id):
		return -1.0
	# Normalise key order so the dictionary only needs one entry per pair.
	var key: String
	if from_id < to_id:
		key = "%s:%s" % [from_id, to_id]
	else:
		key = "%s:%s" % [to_id, from_id]
	return _DISTANCES.get(key, -1.0)

# ── Private Methods ───────────────────────────────────────

## Constructs the Shattered Flats biome data. Starting biome — open plains with
## moderate Cryonite and Scrap Metal deposits.
static func _make_shattered_flats() -> BiomeData:
	var data: BiomeData = BiomeData.new()
	data.id = "shattered_flats"
	data.display_name = "Shattered Flats"
	data.description = "A vast, fractured plain of compressed ice and rock. " \
		+ "Low elevation hazards, moderate resource density."
	data.terrain_seed = 1001
	data.resource_profile = "Cryonite (common), Scrap Metal (uncommon)"
	return data


## Constructs the Rock Warrens biome data. Dense rock corridors with high
## Metal and Crystal concentrations — harder traversal, richer rewards.
static func _make_rock_warrens() -> BiomeData:
	var data: BiomeData = BiomeData.new()
	data.id = "rock_warrens"
	data.display_name = "Rock Warrens"
	data.description = "A labyrinth of towering rock formations. " \
		+ "Tight navigation, high Metal and Crystal yields."
	data.terrain_seed = 2047
	data.resource_profile = "Metal (common), Crystal (common), Cryonite (rare)"
	return data


## Constructs the Debris Field biome data. Scattered wreckage clusters with
## dense Scrap Metal and occasional rare component drops.
static func _make_debris_field() -> BiomeData:
	var data: BiomeData = BiomeData.new()
	data.id = "debris_field"
	data.display_name = "Debris Field"
	data.description = "Drifting wreckage from a long-dead orbital station. " \
		+ "Rich in salvage and rare components."
	data.terrain_seed = 3317
	data.resource_profile = "Scrap Metal (very common), Rare Components (uncommon)"
	return data
