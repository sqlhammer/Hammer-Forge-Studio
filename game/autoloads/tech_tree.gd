## TechTree autoload: manages tech tree node unlock state.
## Validates prerequisites and resource costs, deducts resources on unlock, persists state across sessions.
extends Node

# ── Signals ──────────────────────────────────────────────
signal node_unlocked(node_id: String)

# ── Constants ─────────────────────────────────────────────
const SAVE_PATH: String = "user://tech_tree.cfg"

# ── Private Variables ─────────────────────────────────────

## Tracks unlocked nodes. Key: node_id (String), Value: true.
var _unlocked_nodes: Dictionary = {}

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	_load_save()
	Global.log("TechTree: initialized (%d node(s) unlocked)" % _unlocked_nodes.size())

# ── Public Methods ────────────────────────────────────────

## Attempts to unlock a tech tree node by ID.
## Validates prerequisites are met and player has sufficient resources.
## Deducts resources on success. Returns true if unlocked, false otherwise.
func unlock_node(node_id: String) -> bool:
	var entry: Dictionary = TechTreeDefs.get_node_entry(node_id)
	if entry.is_empty():
		Global.log("TechTree: unlock failed — unknown node '%s'" % node_id)
		return false

	if is_unlocked(node_id):
		Global.log("TechTree: unlock skipped — node '%s' already unlocked" % node_id)
		return false

	# Validate all prerequisites are met before spending resources.
	var prerequisites: Array[String] = TechTreeDefs.get_prerequisites(node_id)
	for prereq_id: String in prerequisites:
		if not is_unlocked(prereq_id):
			Global.log("TechTree: unlock failed — '%s' requires '%s' to be unlocked first" % [node_id, prereq_id])
			return false

	# Validate and deduct resource cost.
	var cost: Dictionary = TechTreeDefs.get_unlock_cost(node_id)
	if not cost.is_empty():
		var resource_type: ResourceDefs.ResourceType = cost.get("resource_type", ResourceDefs.ResourceType.NONE) as ResourceDefs.ResourceType
		var quantity: int = cost.get("quantity", 0) as int
		var total_available: int = PlayerInventory.get_total_count(resource_type)
		if total_available < quantity:
			var resource_name: String = ResourceDefs.get_resource_name(resource_type)
			Global.log("TechTree: unlock failed — '%s' needs %d %s (have %d)" % [node_id, quantity, resource_name, total_available])
			return false
		_remove_any_purity(resource_type, quantity)

	_unlocked_nodes[node_id] = true
	node_unlocked.emit(node_id)
	_save()
	Global.log("TechTree: unlocked node '%s'" % node_id)
	return true

## Returns true if the given node has been unlocked.
func is_unlocked(node_id: String) -> bool:
	return _unlocked_nodes.get(node_id, false) as bool

## Returns true if the node can be unlocked right now (prerequisites met, resources available, not yet unlocked).
func can_unlock(node_id: String) -> bool:
	var entry: Dictionary = TechTreeDefs.get_node_entry(node_id)
	if entry.is_empty():
		return false
	if is_unlocked(node_id):
		return false

	# Check all prerequisites.
	var prerequisites: Array[String] = TechTreeDefs.get_prerequisites(node_id)
	for prereq_id: String in prerequisites:
		if not is_unlocked(prereq_id):
			return false

	# Check resource availability.
	var cost: Dictionary = TechTreeDefs.get_unlock_cost(node_id)
	if not cost.is_empty():
		var resource_type: ResourceDefs.ResourceType = cost.get("resource_type", ResourceDefs.ResourceType.NONE) as ResourceDefs.ResourceType
		var quantity: int = cost.get("quantity", 0) as int
		if PlayerInventory.get_total_count(resource_type) < quantity:
			return false

	return true

## Returns all node IDs currently available to unlock (prerequisites met, resources available, not yet unlocked).
func get_available_nodes() -> Array[String]:
	var available: Array[String] = []
	for node_id: String in TechTreeDefs.get_all_node_ids():
		if can_unlock(node_id):
			available.append(node_id)
	return available

## Resets all tech tree progress. Primarily used in tests and new game setup.
func reset() -> void:
	_unlocked_nodes.clear()
	_save()
	Global.log("TechTree: reset — all nodes locked")

# ── Private Methods ───────────────────────────────────────

## Removes resources across all purity levels, consuming lowest purity first.
## Returns the total quantity actually removed.
func _remove_any_purity(resource_type: ResourceDefs.ResourceType, quantity: int) -> int:
	var remaining: int = quantity
	for purity_value: int in ResourceDefs.Purity.values():
		if remaining <= 0:
			break
		var purity: ResourceDefs.Purity = purity_value as ResourceDefs.Purity
		var available: int = PlayerInventory.get_count(resource_type, purity)
		if available > 0:
			var to_remove: int = mini(remaining, available)
			var removed: int = PlayerInventory.remove_item(resource_type, purity, to_remove)
			remaining -= removed
	return quantity - remaining

## Persists unlock state to disk so it survives game restarts.
func _save() -> void:
	var config: ConfigFile = ConfigFile.new()
	for node_id: String in _unlocked_nodes.keys():
		config.set_value("unlocked", node_id, true)
	var err: Error = config.save(SAVE_PATH)
	if err != OK:
		push_error("TechTree: failed to save state to '%s' (error %d)" % [SAVE_PATH, err])

## Loads persisted unlock state from disk on startup.
func _load_save() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(SAVE_PATH)
	if err == ERR_FILE_NOT_FOUND:
		Global.log("TechTree: no save file found — starting fresh")
		return
	if err != OK:
		push_error("TechTree: failed to load save from '%s' (error %d)" % [SAVE_PATH, err])
		return
	var keys: Array = config.get_section_keys("unlocked") if config.has_section("unlocked") else []
	for key: Variant in keys:
		_unlocked_nodes[key as String] = true
	Global.log("TechTree: loaded %d unlocked node(s) from save" % _unlocked_nodes.size())
