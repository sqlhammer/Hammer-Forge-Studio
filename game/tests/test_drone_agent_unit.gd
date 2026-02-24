## Unit tests for the DroneAgent data container. Verifies setup, state machine transitions
## (IDLE → TRAVELING → EXTRACTING → RETURNING → IDLE), and status summary.
class_name TestDroneAgentUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _agent: DroneAgent = null
var _program: DroneProgram = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_program = DroneProgram.new()
	_program.target_resource_type = ResourceDefs.ResourceType.SCRAP_METAL
	_program.minimum_purity = ResourceDefs.Purity.ONE_STAR
	_program.tool_tier_assignment = ResourceDefs.DepositTier.TIER_1

	_agent = DroneAgent.new()
	_agent.setup(42, _program)


func after_each() -> void:
	_agent = null
	_program = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Setup
	add_test("setup_assigns_id", _test_setup_assigns_id)
	add_test("setup_assigns_program", _test_setup_assigns_program)
	add_test("setup_sets_idle_state", _test_setup_sets_idle_state)
	# State machine: IDLE
	add_test("initial_state_is_idle", _test_initial_state_is_idle)
	add_test("is_idle_returns_true_initially", _test_is_idle_returns_true_initially)
	add_test("no_target_initially", _test_no_target_initially)
	# State machine: TRAVELING
	add_test("start_travel_sets_traveling", _test_start_travel_sets_traveling)
	add_test("start_travel_stores_deposit_id", _test_start_travel_stores_deposit_id)
	add_test("is_idle_false_when_traveling", _test_is_idle_false_when_traveling)
	# State machine: EXTRACTING
	add_test("start_extracting_sets_extracting", _test_start_extracting_sets_extracting)
	# State machine: RETURNING
	add_test("start_returning_sets_returning", _test_start_returning_sets_returning)
	# State machine: back to IDLE
	add_test("return_to_idle_clears_state", _test_return_to_idle_clears_state)
	# Program assignment
	add_test("assign_program_updates_program", _test_assign_program_updates_program)
	# Status summary
	add_test("status_summary_has_required_keys", _test_status_summary_has_required_keys)
	add_test("status_summary_reflects_state", _test_status_summary_reflects_state)


# ── Test Methods ──────────────────────────────────────────

# -- Setup --

func _test_setup_assigns_id() -> void:
	assert_equal(_agent.get_drone_id(), 42, "Drone ID should be 42")


func _test_setup_assigns_program() -> void:
	assert_equal(_agent.get_program(), _program, "Program should match assigned program")


func _test_setup_sets_idle_state() -> void:
	assert_equal(_agent.get_state(), DroneAgent.DroneState.IDLE, "State should be IDLE after setup")


# -- State machine: IDLE --

func _test_initial_state_is_idle() -> void:
	assert_equal(_agent.get_state(), DroneAgent.DroneState.IDLE, "Initial state should be IDLE")


func _test_is_idle_returns_true_initially() -> void:
	assert_true(_agent.is_idle(), "is_idle should return true initially")


func _test_no_target_initially() -> void:
	assert_equal(_agent.get_target_deposit_id(), "", "No target deposit initially")


# -- State machine: TRAVELING --

func _test_start_travel_sets_traveling() -> void:
	_agent.start_travel("Deposit_A")
	assert_equal(_agent.get_state(), DroneAgent.DroneState.TRAVELING, "Should be TRAVELING")


func _test_start_travel_stores_deposit_id() -> void:
	_agent.start_travel("Deposit_A")
	assert_equal(_agent.get_target_deposit_id(), "Deposit_A", "Target deposit ID should be stored")


func _test_is_idle_false_when_traveling() -> void:
	_agent.start_travel("Deposit_A")
	assert_false(_agent.is_idle(), "is_idle should be false when traveling")


# -- State machine: EXTRACTING --

func _test_start_extracting_sets_extracting() -> void:
	_agent.start_travel("Deposit_A")
	_agent.start_extracting()
	assert_equal(_agent.get_state(), DroneAgent.DroneState.EXTRACTING, "Should be EXTRACTING")


# -- State machine: RETURNING --

func _test_start_returning_sets_returning() -> void:
	_agent.start_travel("Deposit_A")
	_agent.start_extracting()
	_agent.start_returning()
	assert_equal(_agent.get_state(), DroneAgent.DroneState.RETURNING, "Should be RETURNING")


# -- State machine: back to IDLE --

func _test_return_to_idle_clears_state() -> void:
	_agent.start_travel("Deposit_A")
	_agent.start_extracting()
	_agent.start_returning()
	_agent.return_to_idle()
	assert_equal(_agent.get_state(), DroneAgent.DroneState.IDLE, "Should be IDLE")
	assert_equal(_agent.get_target_deposit_id(), "", "Target should be cleared")
	assert_true(_agent.is_idle(), "is_idle should be true")


# -- Program assignment --

func _test_assign_program_updates_program() -> void:
	var new_program: DroneProgram = DroneProgram.new()
	new_program.target_resource_type = ResourceDefs.ResourceType.METAL
	_agent.assign_program(new_program)
	assert_equal(_agent.get_program(), new_program, "Program should be updated")


# -- Status summary --

func _test_status_summary_has_required_keys() -> void:
	var summary: Dictionary = _agent.get_status_summary()
	assert_true(summary.has("drone_id"), "Summary should include drone_id")
	assert_true(summary.has("state"), "Summary should include state")
	assert_true(summary.has("target_deposit_id"), "Summary should include target_deposit_id")
	assert_true(summary.has("has_program"), "Summary should include has_program")


func _test_status_summary_reflects_state() -> void:
	_agent.start_travel("Deposit_A")
	var summary: Dictionary = _agent.get_status_summary()
	assert_equal(summary.get("state"), "TRAVELING", "Summary state should be TRAVELING")
	assert_equal(summary.get("target_deposit_id"), "Deposit_A", "Summary should show target")
	assert_equal(summary.get("has_program"), true, "Summary should show has_program = true")
