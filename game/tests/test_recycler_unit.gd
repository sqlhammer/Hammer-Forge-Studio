## Unit tests for the Recycler system. Verifies job lifecycle (start, progress, complete,
## collect), failure modes, cancel behavior, recipe queries, and signal emissions.
## Uses ShipState, ModuleManager, and PlayerInventory autoloads (reset between tests).
class_name TestRecyclerUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _recycler: RecyclerType = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	# Reset all autoloads
	ShipState.reset()
	PlayerInventory.clear_all()
	# Remove recycler from autoload ModuleManager if installed
	if ModuleManager.is_installed("recycler"):
		ModuleManager.remove_module("recycler")

	_recycler = RecyclerType.new()
	add_child(_recycler)
	_spy = SignalSpy.new()
	_spy.watch(_recycler, "job_started")
	_spy.watch(_recycler, "job_progress_changed")
	_spy.watch(_recycler, "job_completed")
	_spy.watch(_recycler, "job_cancelled")


func after_each() -> void:
	_spy.clear()
	_spy = null
	_recycler.queue_free()
	_recycler = null
	# Clean up
	if ModuleManager.is_installed("recycler"):
		ModuleManager.remove_module("recycler")
	ShipState.reset()
	PlayerInventory.clear_all()


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Constants
	add_test("module_id_is_recycler", _test_module_id_is_recycler)
	add_test("processing_time_is_5_seconds", _test_processing_time_is_5_seconds)
	add_test("recipe_input_is_3_scrap_metal", _test_recipe_input_is_3_scrap_metal)
	add_test("recipe_output_is_1_metal", _test_recipe_output_is_1_metal)
	# Initial state
	add_test("initial_state_not_active", _test_initial_state_not_active)
	add_test("initial_no_uncollected_output", _test_initial_no_uncollected_output)
	add_test("initial_progress_is_zero", _test_initial_progress_is_zero)
	# Start job success
	add_test("start_job_succeeds_with_module_and_resources", _test_start_job_succeeds_with_module_and_resources)
	add_test("start_job_emits_job_started", _test_start_job_emits_job_started)
	add_test("start_job_deducts_input_resources", _test_start_job_deducts_input_resources)
	add_test("start_job_consumes_lowest_purity_first", _test_start_job_consumes_lowest_purity_first)
	# Start job failure modes
	add_test("start_job_fails_without_module_installed", _test_start_job_fails_without_module_installed)
	add_test("start_job_fails_while_already_processing", _test_start_job_fails_while_already_processing)
	add_test("start_job_fails_with_uncollected_output", _test_start_job_fails_with_uncollected_output)
	add_test("start_job_fails_with_insufficient_resources", _test_start_job_fails_with_insufficient_resources)
	# Job progress and completion
	add_test("process_advances_job_progress", _test_process_advances_job_progress)
	add_test("job_completes_at_full_progress", _test_job_completes_at_full_progress)
	add_test("job_completed_emits_signal", _test_job_completed_emits_signal)
	add_test("completed_job_has_uncollected_output", _test_completed_job_has_uncollected_output)
	# Collect output
	add_test("collect_output_adds_metal_to_inventory", _test_collect_output_adds_metal_to_inventory)
	add_test("collect_output_clears_pending", _test_collect_output_clears_pending)
	add_test("collect_with_no_output_returns_zero", _test_collect_with_no_output_returns_zero)
	# Cancel
	add_test("cancel_stops_active_job", _test_cancel_stops_active_job)
	add_test("cancel_emits_job_cancelled", _test_cancel_emits_job_cancelled)
	add_test("cancel_does_not_refund_input", _test_cancel_does_not_refund_input)
	add_test("cancel_inactive_job_is_noop", _test_cancel_inactive_job_is_noop)
	# Recipe queries
	add_test("get_recipe_input_returns_dict", _test_get_recipe_input_returns_dict)
	add_test("get_recipe_output_returns_dict", _test_get_recipe_output_returns_dict)


# ── Helpers ───────────────────────────────────────────────

## Installs recycler via the autoload ModuleManager (seeds resources first).
func _install_recycler() -> void:
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 20)
	ModuleManager.install_module("recycler")


## Adds enough Scrap Metal for one recycling job (3 units).
func _seed_job_resources() -> void:
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 3)


## Simulates processing by calling _process repeatedly until job completes.
func _simulate_processing() -> void:
	# 5 seconds / 0.5 delta = 10 ticks
	for i: int in range(11):
		_recycler._process(0.5)


# ── Test Methods ──────────────────────────────────────────

# -- Constants --

func _test_module_id_is_recycler() -> void:
	assert_equal(RecyclerType.MODULE_ID, "recycler", "MODULE_ID should be 'recycler'")


func _test_processing_time_is_5_seconds() -> void:
	assert_equal(RecyclerType.PROCESSING_TIME, 5.0, "PROCESSING_TIME should be 5.0")


func _test_recipe_input_is_3_scrap_metal() -> void:
	assert_equal(RecyclerType.RECIPE_INPUT_TYPE, ResourceDefs.ResourceType.SCRAP_METAL,
		"Input type should be SCRAP_METAL")
	assert_equal(RecyclerType.RECIPE_INPUT_QUANTITY, 3, "Input quantity should be 3")


func _test_recipe_output_is_1_metal() -> void:
	assert_equal(RecyclerType.RECIPE_OUTPUT_TYPE, ResourceDefs.ResourceType.METAL,
		"Output type should be METAL")
	assert_equal(RecyclerType.RECIPE_OUTPUT_QUANTITY, 1, "Output quantity should be 1")


# -- Initial state --

func _test_initial_state_not_active() -> void:
	assert_false(_recycler.is_job_active(), "No job should be active initially")


func _test_initial_no_uncollected_output() -> void:
	assert_false(_recycler.has_uncollected_output(), "No uncollected output initially")
	assert_equal(_recycler.get_pending_output_quantity(), 0, "Pending output should be 0")


func _test_initial_progress_is_zero() -> void:
	assert_equal(_recycler.get_job_progress(), 0.0, "Progress should be 0.0 initially")


# -- Start job success --

func _test_start_job_succeeds_with_module_and_resources() -> void:
	_install_recycler()
	_seed_job_resources()
	var result: bool = _recycler.start_job()
	assert_true(result, "start_job should succeed with module installed and resources")
	assert_true(_recycler.is_job_active(), "Job should be active after start")


func _test_start_job_emits_job_started() -> void:
	_install_recycler()
	_seed_job_resources()
	_recycler.start_job()
	assert_signal_emitted(_spy, "job_started", "job_started should emit on start")
	var args: Array = _spy.get_emission_args("job_started", 0)
	assert_equal(args[0], ResourceDefs.ResourceType.SCRAP_METAL,
		"job_started should report SCRAP_METAL input")
	assert_equal(args[1], ResourceDefs.ResourceType.METAL,
		"job_started should report METAL output")


func _test_start_job_deducts_input_resources() -> void:
	_install_recycler()
	_seed_job_resources()
	_recycler.start_job()
	var remaining: int = PlayerInventory.get_total_count(ResourceDefs.ResourceType.SCRAP_METAL)
	assert_equal(remaining, 0, "start_job should deduct 3 Scrap Metal from inventory")


func _test_start_job_consumes_lowest_purity_first() -> void:
	_install_recycler()
	# Add 2 @ 1-star and 2 @ 3-star (total 4, need 3)
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 2)
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 2)
	_recycler.start_job()
	# Should consume all 2 @ 1-star first, then 1 from 3-star
	var one_star: int = PlayerInventory.get_count(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR)
	var three_star: int = PlayerInventory.get_count(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR)
	assert_equal(one_star, 0, "All 1-star should be consumed first")
	assert_equal(three_star, 1, "Only 1 of 2 three-star should be consumed")


# -- Start job failure modes --

func _test_start_job_fails_without_module_installed() -> void:
	# Module NOT installed
	_seed_job_resources()
	var result: bool = _recycler.start_job()
	assert_false(result, "start_job should fail without module installed")
	assert_false(_recycler.is_job_active(), "Job should not be active")


func _test_start_job_fails_while_already_processing() -> void:
	_install_recycler()
	_seed_job_resources()
	_recycler.start_job()
	# Add more resources and try again
	_seed_job_resources()
	var result: bool = _recycler.start_job()
	assert_false(result, "start_job should fail while already processing")


func _test_start_job_fails_with_uncollected_output() -> void:
	_install_recycler()
	_seed_job_resources()
	_recycler.start_job()
	_simulate_processing()
	# Job completed — output uncollected. Try starting new job.
	_seed_job_resources()
	var result: bool = _recycler.start_job()
	assert_false(result, "start_job should fail with uncollected output")


func _test_start_job_fails_with_insufficient_resources() -> void:
	_install_recycler()
	# Add only 2 — need 3
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 2)
	var result: bool = _recycler.start_job()
	assert_false(result, "start_job should fail with insufficient Scrap Metal")


# -- Job progress and completion --

func _test_process_advances_job_progress() -> void:
	_install_recycler()
	_seed_job_resources()
	_recycler.start_job()
	_spy.clear()
	# Simulate 1 second of processing (delta=1.0, time=5.0 → progress=0.2)
	_recycler._process(1.0)
	var progress: float = _recycler.get_job_progress()
	assert_in_range(progress, 0.19, 0.21, "Progress should be ~0.2 after 1s of 5s job")
	assert_signal_emitted(_spy, "job_progress_changed",
		"job_progress_changed should emit during processing")


func _test_job_completes_at_full_progress() -> void:
	_install_recycler()
	_seed_job_resources()
	_recycler.start_job()
	_simulate_processing()
	assert_false(_recycler.is_job_active(), "Job should not be active after completion")
	assert_true(_recycler.has_uncollected_output(), "Should have uncollected output")
	assert_equal(_recycler.get_pending_output_quantity(), 1, "Should have 1 Metal pending")


func _test_job_completed_emits_signal() -> void:
	_install_recycler()
	_seed_job_resources()
	_recycler.start_job()
	_spy.clear()
	_simulate_processing()
	assert_signal_emitted(_spy, "job_completed", "job_completed should emit")
	var args: Array = _spy.get_emission_args("job_completed", 0)
	assert_equal(args[0], ResourceDefs.ResourceType.METAL, "Should report METAL output type")
	assert_equal(args[1], 1, "Should report 1 output quantity")


func _test_completed_job_has_uncollected_output() -> void:
	_install_recycler()
	_seed_job_resources()
	_recycler.start_job()
	_simulate_processing()
	assert_true(_recycler.has_uncollected_output(), "Should have uncollected output after completion")
	assert_equal(_recycler.get_pending_output_quantity(), 1, "Pending quantity should be 1")
	assert_equal(_recycler.get_job_progress(), 0.0, "Progress should reset to 0 after completion")


# -- Collect output --

func _test_collect_output_adds_metal_to_inventory() -> void:
	_install_recycler()
	_seed_job_resources()
	_recycler.start_job()
	_simulate_processing()
	var collected: int = _recycler.collect_output()
	assert_equal(collected, 1, "Should collect 1 Metal")
	var metal_count: int = PlayerInventory.get_count(
		ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.THREE_STAR)
	assert_equal(metal_count, 1, "Inventory should contain 1 Metal @ 3-star")


func _test_collect_output_clears_pending() -> void:
	_install_recycler()
	_seed_job_resources()
	_recycler.start_job()
	_simulate_processing()
	_recycler.collect_output()
	assert_false(_recycler.has_uncollected_output(), "No uncollected output after collect")
	assert_equal(_recycler.get_pending_output_quantity(), 0, "Pending quantity should be 0")


func _test_collect_with_no_output_returns_zero() -> void:
	var collected: int = _recycler.collect_output()
	assert_equal(collected, 0, "Collecting with no pending output should return 0")


# -- Cancel --

func _test_cancel_stops_active_job() -> void:
	_install_recycler()
	_seed_job_resources()
	_recycler.start_job()
	_recycler.cancel_job()
	assert_false(_recycler.is_job_active(), "Job should not be active after cancel")
	assert_equal(_recycler.get_job_progress(), 0.0, "Progress should reset to 0 on cancel")


func _test_cancel_emits_job_cancelled() -> void:
	_install_recycler()
	_seed_job_resources()
	_recycler.start_job()
	_spy.clear()
	_recycler.cancel_job()
	assert_signal_emitted(_spy, "job_cancelled", "job_cancelled should emit")


func _test_cancel_does_not_refund_input() -> void:
	_install_recycler()
	_seed_job_resources()
	_recycler.start_job()
	_recycler.cancel_job()
	var remaining: int = PlayerInventory.get_total_count(ResourceDefs.ResourceType.SCRAP_METAL)
	assert_equal(remaining, 0, "Cancel should not refund consumed Scrap Metal")


func _test_cancel_inactive_job_is_noop() -> void:
	# Should not crash or emit
	_recycler.cancel_job()
	assert_false(_spy.was_emitted("job_cancelled"),
		"Cancel on inactive job should not emit signal")


# -- Recipe queries --

func _test_get_recipe_input_returns_dict() -> void:
	var input: Dictionary = _recycler.get_recipe_input()
	assert_equal(input.get("resource_type"), ResourceDefs.ResourceType.SCRAP_METAL,
		"Recipe input type should be SCRAP_METAL")
	assert_equal(input.get("quantity"), 3, "Recipe input quantity should be 3")


func _test_get_recipe_output_returns_dict() -> void:
	var output: Dictionary = _recycler.get_recipe_output()
	assert_equal(output.get("resource_type"), ResourceDefs.ResourceType.METAL,
		"Recipe output type should be METAL")
	assert_equal(output.get("quantity"), 1, "Recipe output quantity should be 1")
