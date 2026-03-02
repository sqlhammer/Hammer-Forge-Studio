## Recycler module logic: converts Scrap Metal into Metal via timed processing jobs.
## Must be installed via ModuleManager before use. Output is collected manually by the player.
class_name RecyclerType
extends Node

# ── Signals ──────────────────────────────────────────────
signal job_started(input_type: ResourceDefs.ResourceType, output_type: ResourceDefs.ResourceType)
signal job_progress_changed(progress: float)
signal job_completed(output_type: ResourceDefs.ResourceType, output_quantity: int)
signal job_cancelled

# ── Constants ─────────────────────────────────────────────

## Module ID matching the catalog entry in ModuleDefs.
const MODULE_ID: String = "recycler"

## Processing time in seconds for one recycling job.
const PROCESSING_TIME: float = 5.0

## Recipe: Scrap Metal → Metal conversion.
const RECIPE_INPUT_TYPE: ResourceDefs.ResourceType = ResourceDefs.ResourceType.SCRAP_METAL
const RECIPE_INPUT_QUANTITY: int = 3
const RECIPE_OUTPUT_TYPE: ResourceDefs.ResourceType = ResourceDefs.ResourceType.METAL
const RECIPE_OUTPUT_QUANTITY: int = 1

# ── Private Variables ─────────────────────────────────────
var _is_processing: bool = false
var _job_progress: float = 0.0
var _pending_output_type: ResourceDefs.ResourceType = ResourceDefs.ResourceType.NONE
var _pending_output_quantity: int = 0
var _has_uncollected_output: bool = false

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	set_process(false)
	Global.debug_log("Recycler: initialized (recipe: %d Scrap Metal → %d Metal, %.1fs)" % [RECIPE_INPUT_QUANTITY, RECIPE_OUTPUT_QUANTITY, PROCESSING_TIME])

func _process(delta: float) -> void:
	if not _is_processing:
		return
	_job_progress += delta / PROCESSING_TIME
	job_progress_changed.emit(clampf(_job_progress, 0.0, 1.0))
	if _job_progress >= 1.0:
		_complete_job()

# ── Public Methods ────────────────────────────────────────

## Starts a recycling job. Validates module is installed and resources are available.
## Returns true if job started, false on failure.
func start_job() -> bool:
	if not ModuleManager.is_installed(MODULE_ID):
		Global.debug_log("Recycler: cannot start — module not installed")
		return false

	if _is_processing:
		Global.debug_log("Recycler: cannot start — already processing")
		return false

	if _has_uncollected_output:
		Global.debug_log("Recycler: cannot start — uncollected output pending")
		return false

	# Validate input resources (total across all purities)
	var total_available: int = PlayerInventory.get_total_count(RECIPE_INPUT_TYPE)
	if total_available < RECIPE_INPUT_QUANTITY:
		Global.debug_log("Recycler: cannot start — insufficient Scrap Metal (have %d, need %d)" % [total_available, RECIPE_INPUT_QUANTITY])
		return false

	# Deduct input resources (consume lowest purity first)
	var removed: int = _remove_input_any_purity(RECIPE_INPUT_TYPE, RECIPE_INPUT_QUANTITY)
	if removed < RECIPE_INPUT_QUANTITY:
		Global.debug_log("Recycler: resource deduction failed unexpectedly")
		return false

	_is_processing = true
	_job_progress = 0.0
	set_process(true)
	job_started.emit(RECIPE_INPUT_TYPE, RECIPE_OUTPUT_TYPE)
	Global.debug_log("Recycler: job started (%d Scrap Metal → %d Metal)" % [RECIPE_INPUT_QUANTITY, RECIPE_OUTPUT_QUANTITY])
	return true

## Cancels the current job. Input resources are NOT refunded.
func cancel_job() -> void:
	if not _is_processing:
		return
	_is_processing = false
	_job_progress = 0.0
	set_process(false)
	job_cancelled.emit()
	Global.debug_log("Recycler: job cancelled (input consumed)")

## Collects the output of a completed job into the player inventory.
## Returns the quantity actually added (may be less if inventory is full).
func collect_output() -> int:
	if not _has_uncollected_output:
		return 0

	var leftover: int = PlayerInventory.add_item(
		_pending_output_type,
		ResourceDefs.Purity.THREE_STAR,
		_pending_output_quantity,
	)
	var collected: int = _pending_output_quantity - leftover

	if leftover == 0:
		_has_uncollected_output = false
		_pending_output_type = ResourceDefs.ResourceType.NONE
		_pending_output_quantity = 0
		Global.debug_log("Recycler: output collected (%d Metal)" % collected)
	else:
		_pending_output_quantity = leftover
		Global.debug_log("Recycler: partial collect (%d Metal, %d remaining)" % [collected, leftover])

	return collected

## Returns true if a job is currently processing.
func is_job_active() -> bool:
	return _is_processing

## Returns the current job progress (0.0 to 1.0).
func get_job_progress() -> float:
	return _job_progress

## Returns true if there is uncollected output waiting.
func has_uncollected_output() -> bool:
	return _has_uncollected_output

## Returns the pending output quantity (0 if none).
func get_pending_output_quantity() -> int:
	return _pending_output_quantity

## Returns the recipe input requirement as a dictionary.
func get_recipe_input() -> Dictionary:
	return {
		"resource_type": RECIPE_INPUT_TYPE,
		"quantity": RECIPE_INPUT_QUANTITY,
	}

## Returns the recipe output as a dictionary.
func get_recipe_output() -> Dictionary:
	return {
		"resource_type": RECIPE_OUTPUT_TYPE,
		"quantity": RECIPE_OUTPUT_QUANTITY,
	}

# ── Private Methods ───────────────────────────────────────

func _complete_job() -> void:
	_is_processing = false
	_job_progress = 0.0
	set_process(false)
	_pending_output_type = RECIPE_OUTPUT_TYPE
	_pending_output_quantity = RECIPE_OUTPUT_QUANTITY
	_has_uncollected_output = true
	job_completed.emit(RECIPE_OUTPUT_TYPE, RECIPE_OUTPUT_QUANTITY)
	Global.debug_log("Recycler: job completed — %d Metal ready for collection" % RECIPE_OUTPUT_QUANTITY)

## Removes input resources across any purity levels. Returns total removed.
func _remove_input_any_purity(resource_type: ResourceDefs.ResourceType, quantity: int) -> int:
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
