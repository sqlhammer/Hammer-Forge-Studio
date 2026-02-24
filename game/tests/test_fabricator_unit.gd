## Unit tests for the Fabricator module. Verifies job lifecycle (queue, progress, complete,
## cancel), recipe validation, tech tree gating, resource deduction, and signal emissions.
## Uses TechTree, PlayerInventory, ModuleManager, ShipState, and HeadLamp autoloads (reset between tests).
class_name TestFabricatorUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _fabricator: Node = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	TechTree.reset()
	PlayerInventory.clear_all()
	ShipState.reset()
	if ModuleManager.is_installed("recycler"):
		ModuleManager.remove_module("recycler")
	if ModuleManager.is_installed("fabricator"):
		ModuleManager.remove_module("fabricator")
	if ModuleManager.is_installed("automation_hub"):
		ModuleManager.remove_module("automation_hub")

	# Fabricator is an autoload Node — create a fresh instance for isolation
	var script: Script = load("res://scripts/systems/fabricator.gd")
	_fabricator = script.new()
	add_child(_fabricator)

	_spy = SignalSpy.new()
	_spy.watch(_fabricator, "job_started")
	_spy.watch(_fabricator, "job_progress_changed")
	_spy.watch(_fabricator, "job_completed")
	_spy.watch(_fabricator, "job_cancelled")


func after_each() -> void:
	_spy.clear()
	_spy = null
	if is_instance_valid(_fabricator):
		_fabricator.queue_free()
	_fabricator = null
	# Reset HeadLamp autoload to prevent state leaking to disk for other tests
	HeadLamp._is_equipped = false
	HeadLamp._active = false
	HeadLamp.set_process(false)
	TechTree.reset()
	PlayerInventory.clear_all()
	ShipState.reset()
	if ModuleManager.is_installed("fabricator"):
		ModuleManager.remove_module("fabricator")


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Constants
	add_test("module_id_is_fabricator", _test_module_id_is_fabricator)
	# Initial state
	add_test("initial_state_not_active", _test_initial_state_not_active)
	add_test("initial_progress_is_zero", _test_initial_progress_is_zero)
	# Queue job success
	add_test("queue_job_succeeds_with_all_preconditions", _test_queue_job_succeeds_with_all_preconditions)
	add_test("queue_job_emits_job_started", _test_queue_job_emits_job_started)
	add_test("queue_job_deducts_input_resources", _test_queue_job_deducts_input_resources)
	# Queue job failure modes
	add_test("queue_job_fails_without_module", _test_queue_job_fails_without_module)
	add_test("queue_job_fails_without_tech_tree_unlock", _test_queue_job_fails_without_tech_tree_unlock)
	add_test("queue_job_fails_while_processing", _test_queue_job_fails_while_processing)
	add_test("queue_job_fails_unknown_recipe", _test_queue_job_fails_unknown_recipe)
	add_test("queue_job_fails_insufficient_resources", _test_queue_job_fails_insufficient_resources)
	# Job progress and completion — spare battery
	add_test("process_advances_job_progress", _test_process_advances_job_progress)
	add_test("spare_battery_job_completes_and_adds_to_inventory", _test_spare_battery_job_completes_and_adds_to_inventory)
	add_test("job_completed_emits_signal", _test_job_completed_emits_signal)
	# Head lamp recipe — equip output mode
	add_test("head_lamp_job_completes_and_equips", _test_head_lamp_job_completes_and_equips)
	# Cancel
	add_test("cancel_stops_active_job", _test_cancel_stops_active_job)
	add_test("cancel_emits_job_cancelled", _test_cancel_emits_job_cancelled)
	add_test("cancel_inactive_is_noop", _test_cancel_inactive_is_noop)
	# Recipe queries
	add_test("get_available_recipes_returns_all", _test_get_available_recipes_returns_all)


# ── Helpers ───────────────────────────────────────────────

## Unlocks fabricator_module in tech tree and installs the Fabricator module.
func _setup_fabricator() -> void:
	# Unlock tech tree node
	PlayerInventory.add_item(ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 200)
	TechTree.unlock_node("fabricator_module")
	# Install module (costs 20 Metal)
	ModuleManager.install_module("fabricator")


## Seeds enough Metal for one spare battery recipe (10 Metal).
func _seed_spare_battery_resources() -> void:
	PlayerInventory.add_item(ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 10)


## Seeds enough Metal for one head lamp recipe (5 Metal).
func _seed_head_lamp_resources() -> void:
	PlayerInventory.add_item(ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 5)


## Simulates processing until job completes.
func _simulate_job_completion(recipe_id: String) -> void:
	var duration: float = FabricatorDefs.get_duration(recipe_id)
	var ticks: int = ceili(duration / 0.5) + 1
	for i: int in range(ticks):
		_fabricator._process(0.5)


# ── Test Methods ──────────────────────────────────────────

# -- Constants --

func _test_module_id_is_fabricator() -> void:
	var script: Script = load("res://scripts/systems/fabricator.gd")
	assert_equal(script.get("MODULE_ID"), "fabricator", "MODULE_ID should be 'fabricator'")


# -- Initial state --

func _test_initial_state_not_active() -> void:
	assert_false(_fabricator.is_job_active(), "No job should be active initially")


func _test_initial_progress_is_zero() -> void:
	assert_equal(_fabricator.get_job_progress(), 0.0, "Progress should be 0.0 initially")


# -- Queue job success --

func _test_queue_job_succeeds_with_all_preconditions() -> void:
	_setup_fabricator()
	_seed_spare_battery_resources()
	var result: bool = _fabricator.queue_job("spare_battery")
	assert_true(result, "queue_job should succeed with module, tech tree, and resources")
	assert_true(_fabricator.is_job_active(), "Job should be active after queue")


func _test_queue_job_emits_job_started() -> void:
	_setup_fabricator()
	_seed_spare_battery_resources()
	_fabricator.queue_job("spare_battery")
	assert_signal_emitted(_spy, "job_started", "job_started should emit on queue")
	var args: Array = _spy.get_emission_args("job_started", 0)
	assert_equal(args[0], "spare_battery", "Signal should carry recipe_id")


func _test_queue_job_deducts_input_resources() -> void:
	_setup_fabricator()
	# After setup: 200 seeded - 100 unlock - 20 install = 80 remaining
	var before: int = PlayerInventory.get_total_count(ResourceDefs.ResourceType.METAL)
	_seed_spare_battery_resources()
	_fabricator.queue_job("spare_battery")
	var after: int = PlayerInventory.get_total_count(ResourceDefs.ResourceType.METAL)
	# Seeded 10 more, recipe consumed 10 = net zero change from before
	assert_equal(after, before, "queue_job should deduct recipe input (10 Metal seeded then consumed)")


# -- Queue job failure modes --

func _test_queue_job_fails_without_module() -> void:
	# Tech tree unlocked but module not installed
	PlayerInventory.add_item(ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 200)
	TechTree.unlock_node("fabricator_module")
	_seed_spare_battery_resources()
	var result: bool = _fabricator.queue_job("spare_battery")
	assert_false(result, "queue_job should fail without module installed")


func _test_queue_job_fails_without_tech_tree_unlock() -> void:
	var result: bool = _fabricator.queue_job("spare_battery")
	assert_false(result, "queue_job should fail without tech tree unlock")


func _test_queue_job_fails_while_processing() -> void:
	_setup_fabricator()
	_seed_spare_battery_resources()
	_fabricator.queue_job("spare_battery")
	_seed_spare_battery_resources()
	var result: bool = _fabricator.queue_job("spare_battery")
	assert_false(result, "queue_job should fail while already processing")


func _test_queue_job_fails_unknown_recipe() -> void:
	_setup_fabricator()
	var result: bool = _fabricator.queue_job("nonexistent_recipe")
	assert_false(result, "queue_job should fail for unknown recipe")


func _test_queue_job_fails_insufficient_resources() -> void:
	_setup_fabricator()
	# After setup, 80 Metal remains — drain it so spare_battery (needs 10) fails
	PlayerInventory.clear_all()
	var result: bool = _fabricator.queue_job("spare_battery")
	assert_false(result, "queue_job should fail with insufficient resources")


# -- Job progress and completion --

func _test_process_advances_job_progress() -> void:
	_setup_fabricator()
	_seed_spare_battery_resources()
	_fabricator.queue_job("spare_battery")
	_spy.clear()
	_fabricator._process(1.0)
	var progress: float = _fabricator.get_job_progress()
	# Spare battery duration = 8.0s, so 1s = 0.125
	assert_in_range(progress, 0.12, 0.13, "Progress should be ~0.125 after 1s of 8s job")
	assert_signal_emitted(_spy, "job_progress_changed", "job_progress_changed should emit")


func _test_spare_battery_job_completes_and_adds_to_inventory() -> void:
	_setup_fabricator()
	_seed_spare_battery_resources()
	_fabricator.queue_job("spare_battery")
	_simulate_job_completion("spare_battery")
	assert_false(_fabricator.is_job_active(), "Job should not be active after completion")
	var battery_count: int = PlayerInventory.get_total_count(ResourceDefs.ResourceType.SPARE_BATTERY)
	assert_equal(battery_count, 1, "Inventory should contain 1 Spare Battery")


func _test_job_completed_emits_signal() -> void:
	_setup_fabricator()
	_seed_spare_battery_resources()
	_fabricator.queue_job("spare_battery")
	_spy.clear()
	_simulate_job_completion("spare_battery")
	assert_signal_emitted(_spy, "job_completed", "job_completed should emit")
	var args: Array = _spy.get_emission_args("job_completed", 0)
	assert_equal(args[0], "spare_battery", "Signal should carry recipe_id")


# -- Head lamp recipe --

func _test_head_lamp_job_completes_and_equips() -> void:
	_setup_fabricator()
	# Reset HeadLamp state
	HeadLamp._is_equipped = false
	HeadLamp._active = false
	_seed_head_lamp_resources()
	_fabricator.queue_job("head_lamp")
	_simulate_job_completion("head_lamp")
	assert_true(HeadLamp.is_equipped(), "Head Lamp should be equipped after crafting")


# -- Cancel --

func _test_cancel_stops_active_job() -> void:
	_setup_fabricator()
	_seed_spare_battery_resources()
	_fabricator.queue_job("spare_battery")
	_fabricator.cancel_job()
	assert_false(_fabricator.is_job_active(), "Job should not be active after cancel")
	assert_equal(_fabricator.get_job_progress(), 0.0, "Progress should reset to 0")


func _test_cancel_emits_job_cancelled() -> void:
	_setup_fabricator()
	_seed_spare_battery_resources()
	_fabricator.queue_job("spare_battery")
	_spy.clear()
	_fabricator.cancel_job()
	assert_signal_emitted(_spy, "job_cancelled", "job_cancelled should emit")


func _test_cancel_inactive_is_noop() -> void:
	_fabricator.cancel_job()
	assert_false(_spy.was_emitted("job_cancelled"), "Cancel on inactive should not emit signal")


# -- Recipe queries --

func _test_get_available_recipes_returns_all() -> void:
	var recipes: Array[String] = _fabricator.get_available_recipes()
	assert_true(recipes.has("spare_battery"), "Should include spare_battery recipe")
	assert_true(recipes.has("head_lamp"), "Should include head_lamp recipe")
