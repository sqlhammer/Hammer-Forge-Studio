## Resource respawn system autoload. Listens to NavigationSystem.biome_changed
## and manages per-biome surface deposit depletion state. When the player
## departs a biome, depleted surface nodes are queued for respawn. When the
## player returns to a previously-visited biome, queued deposits are restored
## to full stock (data layer only — physical visibility resets are deferred
## to the biome scene tickets TICKET-0170–0172). Deep nodes (infinite: true)
## are explicitly excluded from all respawn logic.
## Ticket: TICKET-0161
class_name ResourceRespawnSystemType
extends Node

# ── Signals ──────────────────────────────────────────────

## Emitted when the player departs a biome and at least one surface deposit
## in that biome is queued for respawn. Passes the departed biome's ID.
signal respawn_queued(biome_id: String)

## Emitted when the player returns to a previously-departed biome that has
## surface deposits pending respawn. Biome scene tickets listen to this signal
## to restore physical deposit visibility. Passes the biome ID.
signal respawn_applied(biome_id: String)

# ── Private Variables ─────────────────────────────────────

## Active depletion tracking for deposits that have depleted while the player
## is currently in a biome. Structure: { biome_id: Array[String] }
## Each value is the array of deposit IDs that depleted in that biome.
var _active_depletions: Dictionary = {}

## Deposits queued for respawn (moved from _active_depletions on departure).
## Cleared when the player returns and mark_respawns_applied() is called.
## Structure: { biome_id: Array[String] }
var _pending_respawns: Dictionary = {}

## Biomes the player has departed from at least once. Used to distinguish
## a first visit (no respawn) from a return visit (respawn eligible).
## Structure: { biome_id: true }
var _departed_biomes: Dictionary = {}

## Biome the player was in before the most recent biome_changed event.
## Tracked here because NavigationSystem.current_biome is already updated
## when the signal fires.
var _previous_biome: String = ""

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_previous_biome = NavigationSystem.current_biome
	NavigationSystem.biome_changed.connect(_on_biome_changed)
	Global.debug_log("ResourceRespawnSystem: initialized (starting biome='%s')" % _previous_biome)

# ── Public Methods ────────────────────────────────────────

## Reports that a surface deposit has depleted in the given biome.
## The system queues it for respawn when the player next departs.
## Pass infinite=true to identify deep nodes — they are silently excluded.
## deposit_id: unique string identifier for the deposit within its biome.
## biome_id: the biome where the deposit resides.
## infinite: set true for deep nodes (yield_rate < 1.0, never deplete normally).
func report_depleted(deposit_id: String, biome_id: String, infinite: bool = false) -> void:
	if infinite:
		return
	if not _active_depletions.has(biome_id):
		_active_depletions[biome_id] = []
	var biome_list: Array = _active_depletions[biome_id]
	if deposit_id not in biome_list:
		biome_list.append(deposit_id)
		Global.debug_log("ResourceRespawnSystem: tracked depletion '%s' in biome '%s'" % [
			deposit_id, biome_id])


## Returns the array of deposit IDs pending respawn for the given biome.
## Biome scene tickets call this on scene load to determine which deposits
## to restore. Returns an empty array if no respawns are queued.
func get_pending_respawns(biome_id: String) -> Array:
	return (_pending_respawns.get(biome_id, []) as Array).duplicate()


## Returns true if the player has never departed the given biome before.
## A first visit does not trigger respawn; only return visits do.
func is_first_visit(biome_id: String) -> bool:
	return not _departed_biomes.has(biome_id)


## Marks all pending respawns for the given biome as consumed and clears the
## queue. Biome scene tickets call this after restoring physical deposit
## visibility. Does not re-emit respawn_applied.
func mark_respawns_applied(biome_id: String) -> void:
	if _pending_respawns.has(biome_id):
		_pending_respawns.erase(biome_id)
		Global.debug_log("ResourceRespawnSystem: respawns applied and cleared for biome '%s'" % biome_id)


## Resets all respawn state to initial conditions. Previous biome is set to
## NavigationSystem.current_biome. Use for new-game init and test teardown.
func reset() -> void:
	_active_depletions.clear()
	_pending_respawns.clear()
	_departed_biomes.clear()
	_previous_biome = NavigationSystem.current_biome
	Global.debug_log("ResourceRespawnSystem: reset (starting biome='%s')" % _previous_biome)

# ── Private Methods ───────────────────────────────────────

## Handles NavigationSystem.biome_changed signal.
## On departure: moves any depleted surface deposits for the departed biome
## into the pending respawn queue and marks the biome as departed.
## On arrival: emits respawn_applied if the arrived biome has pending respawns
## and this is a return visit (not a first visit).
func _on_biome_changed(new_biome_id: String) -> void:
	var departed_biome: String = _previous_biome

	# -- Departure logic --
	if departed_biome != "":
		var depleted: Array = _active_depletions.get(departed_biome, [])
		if depleted.size() > 0:
			_pending_respawns[departed_biome] = depleted.duplicate()
			_active_depletions.erase(departed_biome)
			respawn_queued.emit(departed_biome)
			Global.debug_log("ResourceRespawnSystem: queued %d deposit(s) for respawn in '%s'" % [
				depleted.size(), departed_biome])
		# Always mark biome departed, even if nothing was depleted.
		_departed_biomes[departed_biome] = true

	# -- Arrival logic --
	# Only apply respawn on return visits (biome previously departed).
	var pending: Array = _pending_respawns.get(new_biome_id, [])
	if _departed_biomes.has(new_biome_id) and pending.size() > 0:
		respawn_applied.emit(new_biome_id)
		Global.debug_log("ResourceRespawnSystem: respawn_applied emitted for '%s' (%d deposit(s))" % [
			new_biome_id, pending.size()])

	_previous_biome = new_biome_id
	Global.debug_log("ResourceRespawnSystem: biome transition '%s' → '%s'" % [
		departed_biome, new_biome_id])
