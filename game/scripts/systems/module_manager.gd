## Manages installed ship modules: install, remove, and query operations.
## Validates resource costs against PlayerInventory and power draw against ShipState.
class_name ModuleManagerType
extends Node

# ── Signals ──────────────────────────────────────────────
signal module_installed(module_id: String)
signal module_removed(module_id: String)
signal install_failed(module_id: String, reason: String)

# ── Private Variables ─────────────────────────────────────

## Tracks installed modules. Key: module_id (String), Value: install data Dictionary.
var _installed_modules: Dictionary = {}

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	Global.log("ModuleManager: initialized")

# ── Public Methods ────────────────────────────────────────

## Attempts to install a module by ID. Validates cost and power capacity.
## Returns true on success, false on failure (emits install_failed with reason).
func install_module(module_id: String) -> bool:
	var entry: Dictionary = ModuleDefs.get_module_entry(module_id)
	if entry.is_empty():
		install_failed.emit(module_id, "UNKNOWN_MODULE")
		Global.log("ModuleManager: install failed — unknown module '%s'" % module_id)
		return false

	if is_installed(module_id):
		install_failed.emit(module_id, "ALREADY_INSTALLED")
		Global.log("ModuleManager: install failed — '%s' already installed" % module_id)
		return false

	# Validate tech tree gate — module cannot be installed until the required node is unlocked.
	var tech_tree_gate: String = ModuleDefs.get_tech_tree_gate(module_id)
	if not tech_tree_gate.is_empty() and not TechTree.is_unlocked(tech_tree_gate):
		install_failed.emit(module_id, "TECH_TREE_LOCKED")
		Global.log("ModuleManager: install failed — '%s' requires tech tree node '%s' to be unlocked" % [module_id, tech_tree_gate])
		return false

	# Validate power capacity
	var power_draw: float = entry.get("power_draw", 0.0) as float
	if ShipState.would_exceed_capacity(power_draw):
		install_failed.emit(module_id, "POWER_OVERLOAD")
		Global.log("ModuleManager: install failed — '%s' would overload power (draw=%.1f)" % [module_id, power_draw])
		return false

	# Validate and deduct resource cost (any purity accepted, lowest consumed first)
	var cost: Dictionary = entry.get("install_cost", {})
	if not cost.is_empty():
		var resource_type: ResourceDefs.ResourceType = cost.get("resource_type", ResourceDefs.ResourceType.NONE) as ResourceDefs.ResourceType
		var quantity: int = cost.get("quantity", 0) as int
		var total_available: int = PlayerInventory.get_total_count(resource_type)
		if total_available < quantity:
			var resource_name: String = ResourceDefs.get_resource_name(resource_type)
			install_failed.emit(module_id, "INSUFFICIENT_RESOURCES")
			Global.log("ModuleManager: install failed — need %d %s for '%s' (have %d)" % [quantity, resource_name, module_id, total_available])
			return false
		_remove_any_purity(resource_type, quantity)

	# Register power draw with ShipState
	if not ShipState.register_module_draw(power_draw):
		install_failed.emit(module_id, "POWER_REGISTRATION_FAILED")
		return false

	# Track installed module
	_installed_modules[module_id] = {
		"power_draw": power_draw,
	}

	module_installed.emit(module_id)
	Global.log("ModuleManager: installed '%s' (power_draw=%.1f)" % [module_id, power_draw])
	return true

## Removes an installed module by ID. No resource refund in M4.
## Returns true on success, false if module is not installed.
func remove_module(module_id: String) -> bool:
	if not is_installed(module_id):
		Global.log("ModuleManager: remove failed — '%s' not installed" % module_id)
		return false

	var module_data: Dictionary = _installed_modules[module_id]
	var power_draw: float = module_data.get("power_draw", 0.0) as float

	# Deregister power draw
	ShipState.deregister_module_draw(power_draw)

	_installed_modules.erase(module_id)
	module_removed.emit(module_id)
	Global.log("ModuleManager: removed '%s'" % module_id)
	return true

## Returns true if a module is currently installed.
func is_installed(module_id: String) -> bool:
	return _installed_modules.has(module_id)

## Returns a list of all installed module IDs.
func get_installed_module_ids() -> Array[String]:
	var ids: Array[String] = []
	for key: String in _installed_modules.keys():
		ids.append(key)
	return ids

## Returns the number of installed modules.
func get_installed_count() -> int:
	return _installed_modules.size()

## Returns the install data for a module, or empty dict if not installed.
func get_module_data(module_id: String) -> Dictionary:
	return _installed_modules.get(module_id, {})

# ── Private Methods ───────────────────────────────────────

## Removes resources across any purity level, consuming lowest purity first.
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
