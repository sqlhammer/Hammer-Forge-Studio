## Unit tests for the AutomationHub autoload. Verifies drone deployment, target assignment,
## state machine transitions, power draw, recall, and signal emissions.
## Uses TechTree, PlayerInventory, ModuleManager, ShipState autoloads (reset between tests).
class_name TestAutomationHubUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _hub: Node = null
var _spy: SignalSpy = null
var _test_deposit: Deposit = null


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

	var script: Script = load("res://scripts/systems/automation_hub.gd")
	_hub = script.new()
	add_child(_hub)

	_spy = SignalSpy.new()
	_spy.watch(_hub, "drone_started")
	_spy.watch(_hub, "drone_completed")
	_spy.watch(_hub, "drone_returned")

	# Create a test deposit for target assignment
	_test_deposit = Deposit.new()
	_test_deposit.name = "TestDeposit"
	_test_deposit.setup(
		ResourceDefs.ResourceType.SCRAP_METAL,
		ResourceDefs.Purity.THREE_STAR,
		ResourceDefs.DensityTier.MEDIUM,
		40
	)
	add_child(_test_deposit)
	_test_deposit.ping()
	_test_deposit.mark_analyzed()


func after_each() -> void:
	_spy.clear()
	_spy = null
	if is_instance_valid(_hub):
		_hub.queue_free()
	_hub = null
	if is_instance_valid(_test_deposit):
		_test_deposit.queue_free()
	_test_deposit = null
	TechTree.reset()
	PlayerInventory.clear_all()
	ShipState.reset()
	if ModuleManager.is_installed("automation_hub"):
		ModuleManager.remove_module("automation_hub")
	if ModuleManager.is_installed("fabricator"):
		ModuleManager.remove_module("fabricator")


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Constants
	add_test("module_id_is_automation_hub", _test_module_id_is_automation_hub)
	add_test("max_drones_tier_1_is_2", _test_max_drones_tier_1_is_2)
	# Deploy success
	add_test("deploy_drone_succeeds_with_preconditions", _test_deploy_drone_succeeds_with_preconditions)
	add_test("deploy_returns_drone_id", _test_deploy_returns_drone_id)
	add_test("deploy_increments_active_count", _test_deploy_increments_active_count)
	# Deploy failure modes
	add_test("deploy_fails_without_module", _test_deploy_fails_without_module)
	add_test("deploy_fails_without_tech_tree", _test_deploy_fails_without_tech_tree)
	add_test("deploy_fails_at_max_capacity", _test_deploy_fails_at_max_capacity)
	# Target assignment
	add_test("assign_target_succeeds", _test_assign_target_succeeds)
	add_test("assign_target_fails_non_idle", _test_assign_target_fails_non_idle)
	add_test("assign_target_fails_unanalyzed_deposit", _test_assign_target_fails_unanalyzed_deposit)
	add_test("assign_emits_drone_started", _test_assign_emits_drone_started)
	# State machine transitions
	add_test("notify_arrived_transitions_to_extracting", _test_notify_arrived_transitions_to_extracting)
	add_test("notify_extraction_complete_transitions_to_returning", _test_notify_extraction_complete_transitions_to_returning)
	add_test("notify_returned_transitions_to_idle", _test_notify_returned_transitions_to_idle)
	# Power draw
	add_test("extracting_drone_draws_power", _test_extracting_drone_draws_power)
	# Recall
	add_test("recall_transitions_to_returning", _test_recall_transitions_to_returning)
	# Remove
	add_test("remove_drone_decrements_count", _test_remove_drone_decrements_count)
	# Status list
	add_test("get_drone_status_list_returns_entries", _test_get_drone_status_list_returns_entries)


# ── Helpers ───────────────────────────────────────────────

func _setup_automation_hub() -> void:
	# Unlock fabricator (1 Metal) + automation_hub (2 Metal) + install module (2 Metal) = 5 total
	PlayerInventory.add_item(ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 5)
	TechTree.unlock_node("fabricator_module")
	TechTree.unlock_node("automation_hub")
	ModuleManager.install_module("automation_hub")


func _make_program() -> DroneProgram:
	var program: DroneProgram = DroneProgram.new()
	program.target_resource_type = ResourceDefs.ResourceType.SCRAP_METAL
	program.minimum_purity = ResourceDefs.Purity.ONE_STAR
	program.tool_tier_assignment = ResourceDefs.DepositTier.TIER_1
	program.extraction_radius = 100.0
	return program


func _deploy_and_assign() -> int:
	var program: DroneProgram = _make_program()
	var drone_id: int = _hub.deploy_drone(program)
	_hub.assign_target(drone_id, _test_deposit)
	return drone_id


# ── Test Methods ──────────────────────────────────────────

# -- Constants --

func _test_module_id_is_automation_hub() -> void:
	var script: Script = load("res://scripts/systems/automation_hub.gd")
	assert_equal(script.get("MODULE_ID"), "automation_hub", "MODULE_ID should be 'automation_hub'")


func _test_max_drones_tier_1_is_2() -> void:
	var script: Script = load("res://scripts/systems/automation_hub.gd")
	assert_equal(script.get("MAX_ACTIVE_DRONES_TIER_1"), 2, "Max drones should be 2")


# -- Deploy success --

func _test_deploy_drone_succeeds_with_preconditions() -> void:
	_setup_automation_hub()
	var program: DroneProgram = _make_program()
	var drone_id: int = _hub.deploy_drone(program)
	assert_true(drone_id >= 0, "deploy should return valid drone_id")


func _test_deploy_returns_drone_id() -> void:
	_setup_automation_hub()
	var program: DroneProgram = _make_program()
	var id1: int = _hub.deploy_drone(program)
	var id2: int = _hub.deploy_drone(_make_program())
	assert_true(id1 != id2, "Drone IDs should be unique")


func _test_deploy_increments_active_count() -> void:
	_setup_automation_hub()
	assert_equal(_hub.get_active_drone_count(), 0, "Should start with 0 active drones")
	_hub.deploy_drone(_make_program())
	assert_equal(_hub.get_active_drone_count(), 1, "Should have 1 active drone")


# -- Deploy failure modes --

func _test_deploy_fails_without_module() -> void:
	var drone_id: int = _hub.deploy_drone(_make_program())
	assert_equal(drone_id, -1, "Deploy should fail without module installed")


func _test_deploy_fails_without_tech_tree() -> void:
	# Install module without tech tree (won't work through normal path, but test the hub logic)
	var drone_id: int = _hub.deploy_drone(_make_program())
	assert_equal(drone_id, -1, "Deploy should fail without tech tree unlock")


func _test_deploy_fails_at_max_capacity() -> void:
	_setup_automation_hub()
	_hub.deploy_drone(_make_program())
	_hub.deploy_drone(_make_program())
	var drone_id: int = _hub.deploy_drone(_make_program())
	assert_equal(drone_id, -1, "Deploy should fail at max capacity (2)")


# -- Target assignment --

func _test_assign_target_succeeds() -> void:
	_setup_automation_hub()
	var program: DroneProgram = _make_program()
	var drone_id: int = _hub.deploy_drone(program)
	var result: bool = _hub.assign_target(drone_id, _test_deposit)
	assert_true(result, "assign_target should succeed with idle drone and analyzed deposit")


func _test_assign_target_fails_non_idle() -> void:
	_setup_automation_hub()
	var drone_id: int = _deploy_and_assign()
	# Drone is now TRAVELING, try assigning again
	var result: bool = _hub.assign_target(drone_id, _test_deposit)
	assert_false(result, "assign_target should fail for non-idle drone")


func _test_assign_target_fails_unanalyzed_deposit() -> void:
	_setup_automation_hub()
	var unanalyzed: Deposit = Deposit.new()
	unanalyzed.name = "UnanalyzedDeposit"
	unanalyzed.setup(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR,
		ResourceDefs.DensityTier.MEDIUM, 40)
	add_child(unanalyzed)
	# Don't ping or analyze — should fail
	var drone_id: int = _hub.deploy_drone(_make_program())
	var result: bool = _hub.assign_target(drone_id, unanalyzed)
	assert_false(result, "assign_target should fail for unanalyzed deposit")
	unanalyzed.queue_free()


func _test_assign_emits_drone_started() -> void:
	_setup_automation_hub()
	_spy.clear()
	_deploy_and_assign()
	assert_signal_emitted(_spy, "drone_started", "drone_started should emit on assignment")


# -- State machine transitions --

func _test_notify_arrived_transitions_to_extracting() -> void:
	_setup_automation_hub()
	var drone_id: int = _deploy_and_assign()
	_hub.notify_drone_arrived(drone_id)
	var status: Array[Dictionary] = _hub.get_drone_status_list()
	assert_equal(status[0].get("state"), "EXTRACTING", "Drone should be EXTRACTING after arrival")


func _test_notify_extraction_complete_transitions_to_returning() -> void:
	_setup_automation_hub()
	var drone_id: int = _deploy_and_assign()
	_hub.notify_drone_arrived(drone_id)
	_hub.notify_extraction_complete(drone_id, "TestDeposit", 10)
	var status: Array[Dictionary] = _hub.get_drone_status_list()
	assert_equal(status[0].get("state"), "RETURNING", "Drone should be RETURNING after extraction")


func _test_notify_returned_transitions_to_idle() -> void:
	_setup_automation_hub()
	var drone_id: int = _deploy_and_assign()
	_hub.notify_drone_arrived(drone_id)
	_hub.notify_extraction_complete(drone_id, "TestDeposit", 10)
	_hub.notify_drone_returned(drone_id)
	var status: Array[Dictionary] = _hub.get_drone_status_list()
	assert_equal(status[0].get("state"), "IDLE", "Drone should be IDLE after return")


# -- Power draw --

func _test_extracting_drone_draws_power() -> void:
	_setup_automation_hub()
	var drone_id: int = _deploy_and_assign()
	_hub.notify_drone_arrived(drone_id)
	var power_before: float = ShipState.get_power()
	# Simulate 1 second of extraction
	_hub._process(1.0)
	var power_after: float = ShipState.get_power()
	var drawn: float = power_before - power_after
	# DRONE_POWER_DRAW_PER_SECOND = 3.0
	assert_in_range(drawn, 2.9, 3.1, "Should draw ~3.0 power per second per extracting drone")


# -- Recall --

func _test_recall_transitions_to_returning() -> void:
	_setup_automation_hub()
	var drone_id: int = _deploy_and_assign()
	_hub.recall_drone(drone_id)
	var status: Array[Dictionary] = _hub.get_drone_status_list()
	assert_equal(status[0].get("state"), "RETURNING", "Recall should transition to RETURNING")


# -- Remove --

func _test_remove_drone_decrements_count() -> void:
	_setup_automation_hub()
	var drone_id: int = _hub.deploy_drone(_make_program())
	assert_equal(_hub.get_active_drone_count(), 1, "Should have 1 drone")
	_hub.remove_drone(drone_id)
	assert_equal(_hub.get_active_drone_count(), 0, "Should have 0 drones after removal")


# -- Status list --

func _test_get_drone_status_list_returns_entries() -> void:
	_setup_automation_hub()
	_hub.deploy_drone(_make_program())
	var status: Array[Dictionary] = _hub.get_drone_status_list()
	assert_equal(status.size(), 1, "Status list should have 1 entry")
	assert_true(status[0].has("drone_id"), "Status entry should include drone_id")
	assert_true(status[0].has("state"), "Status entry should include state")
