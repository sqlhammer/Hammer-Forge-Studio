## Fabricator module logic: crafts equipment and components from refined resources.
## Must be installed via ModuleManager (requires tech tree node 'fabricator_module' unlocked).
## Recipes are defined in FabricatorDefs. Output goes to PlayerInventory or directly equips.
extends Node

# ── Signals ──────────────────────────────────────────────
signal job_started(recipe_id: String)
signal job_progress_changed(progress: float)
signal job_completed(recipe_id: String)
signal job_cancelled

# ── Constants ─────────────────────────────────────────────

## Module ID matching the catalog entry in ModuleDefs.
const MODULE_ID: String = "fabricator"

# ── Private Variables ─────────────────────────────────────
var _is_processing: bool = false
var _current_recipe_id: String = ""
var _job_progress: float = 0.0

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	set_process(false)
	Global.debug_log("Fabricator: initialized")

func _process(delta: float) -> void:
	if not _is_processing:
		return
	var duration: float = FabricatorDefs.get_duration(_current_recipe_id)
	_job_progress += delta / duration
	job_progress_changed.emit(clampf(_job_progress, 0.0, 1.0))
	if _job_progress >= 1.0:
		_complete_job()

# ── Public Methods ────────────────────────────────────────

## Attempts to queue a crafting job by recipe ID.
## Validates module is installed, tech tree node is unlocked, and inputs are available.
## Deducts inputs immediately on start. Returns true on success, false on failure.
func queue_job(recipe_id: String) -> bool:
	if not ModuleManager.is_installed(MODULE_ID):
		Global.debug_log("Fabricator: cannot start — module not installed")
		return false

	if not TechTree.is_unlocked("fabricator_module"):
		Global.debug_log("Fabricator: cannot start — tech tree node 'fabricator_module' not unlocked")
		return false

	if _is_processing:
		Global.debug_log("Fabricator: cannot start — already processing recipe '%s'" % _current_recipe_id)
		return false

	var entry: Dictionary = FabricatorDefs.get_recipe_entry(recipe_id)
	if entry.is_empty():
		Global.debug_log("Fabricator: cannot start — unknown recipe '%s'" % recipe_id)
		return false

	# Validate and deduct all inputs.
	var inputs: Array = FabricatorDefs.get_inputs(recipe_id)
	if not _validate_inputs(inputs):
		return false
	_deduct_inputs(inputs)

	_is_processing = true
	_current_recipe_id = recipe_id
	_job_progress = 0.0
	set_process(true)
	job_started.emit(recipe_id)
	Global.debug_log("Fabricator: job started — recipe '%s'" % recipe_id)
	return true

## Cancels the current job. Input resources are NOT refunded.
func cancel_job() -> void:
	if not _is_processing:
		return
	_is_processing = false
	_job_progress = 0.0
	set_process(false)
	job_cancelled.emit()
	Global.debug_log("Fabricator: job cancelled (inputs consumed, no refund)")

## Returns true if a job is currently in progress.
func is_job_active() -> bool:
	return _is_processing

## Returns the current job progress (0.0 to 1.0).
func get_job_progress() -> float:
	return _job_progress

## Returns the recipe ID of the currently active job, or empty string if idle.
func get_current_recipe_id() -> String:
	return _current_recipe_id

## Returns all recipe IDs available in the Fabricator catalog.
func get_available_recipes() -> Array[String]:
	return FabricatorDefs.get_all_recipe_ids()

# ── Private Methods ───────────────────────────────────────

## Returns true if the player has sufficient resources for all recipe inputs.
func _validate_inputs(inputs: Array) -> bool:
	for input: Dictionary in inputs:
		var resource_type: ResourceDefs.ResourceType = input.get("resource_type", ResourceDefs.ResourceType.NONE) as ResourceDefs.ResourceType
		var quantity: int = input.get("quantity", 0) as int
		var available: int = PlayerInventory.get_total_count(resource_type)
		if available < quantity:
			var resource_name: String = ResourceDefs.get_resource_name(resource_type)
			Global.debug_log("Fabricator: insufficient %s (have %d, need %d)" % [resource_name, available, quantity])
			return false
	return true

## Removes all recipe inputs from the player inventory (any purity, lowest first).
func _deduct_inputs(inputs: Array) -> void:
	for input: Dictionary in inputs:
		var resource_type: ResourceDefs.ResourceType = input.get("resource_type", ResourceDefs.ResourceType.NONE) as ResourceDefs.ResourceType
		var quantity: int = input.get("quantity", 0) as int
		_remove_any_purity(resource_type, quantity)

## Removes resources across all purity levels, consuming lowest purity first.
func _remove_any_purity(resource_type: ResourceDefs.ResourceType, quantity: int) -> void:
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

## Finalizes the current job: delivers output and resets state.
func _complete_job() -> void:
	_is_processing = false
	_job_progress = 0.0
	set_process(false)

	var completed_recipe_id: String = _current_recipe_id
	_current_recipe_id = ""

	var output_mode: String = FabricatorDefs.get_output_mode(completed_recipe_id)
	var output: Dictionary = FabricatorDefs.get_output(completed_recipe_id)

	if output_mode == FabricatorDefs.OUTPUT_MODE_INVENTORY and not output.is_empty():
		var resource_type: ResourceDefs.ResourceType = output.get("resource_type", ResourceDefs.ResourceType.NONE) as ResourceDefs.ResourceType
		var quantity: int = output.get("quantity", 0) as int
		var leftover: int = PlayerInventory.add_item(resource_type, ResourceDefs.Purity.THREE_STAR, quantity)
		var delivered: int = quantity - leftover
		Global.debug_log("Fabricator: job complete — added %d %s to inventory" % [delivered, ResourceDefs.get_resource_name(resource_type)])
	elif output_mode == FabricatorDefs.OUTPUT_MODE_EQUIP_HEAD_LAMP:
		HeadLamp.equip()
		Global.debug_log("Fabricator: job complete — Head Lamp equipped")
	else:
		Global.debug_log("Fabricator: job complete — recipe '%s' (no output action)" % completed_recipe_id)

	job_completed.emit(completed_recipe_id)
