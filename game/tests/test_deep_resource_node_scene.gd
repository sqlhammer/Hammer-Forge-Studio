## Scene-level tests for the DeepResourceNode system. Verifies scene defaults,
## mining yield_rate integration, drone targeting, and respawn system exclusion.
##
## Coverage target: 80% (per docs/studio/tdd-process-m8.md — Cryonite mechanics)
## Ticket: TICKET-0173
class_name TestDeepResourceNodeScene
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _deep_node: DeepResourceNode = null
var _program: DroneProgram = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_deep_node = DeepResourceNode.new()
	_deep_node.resource_type = ResourceDefs.ResourceType.SCRAP_METAL
	_deep_node.purity = ResourceDefs.Purity.THREE_STAR
	_deep_node.density_tier = ResourceDefs.DensityTier.MEDIUM
	_deep_node.deposit_tier = ResourceDefs.DepositTier.TIER_1
	_deep_node.total_quantity = 40
	add_child(_deep_node)

	_program = DroneProgram.new()
	_program.target_resource_type = ResourceDefs.ResourceType.SCRAP_METAL
	_program.minimum_purity = ResourceDefs.Purity.ONE_STAR
	_program.tool_tier_assignment = ResourceDefs.DepositTier.TIER_1
	_program.extraction_radius = 100.0
	_program.priority_order = 0

	_spy = SignalSpy.new()
	_spy.watch(_deep_node, "depleted")
	_spy.watch(_deep_node, "quantity_changed")


func after_each() -> void:
	_spy.clear()
	_spy = null
	if is_instance_valid(_deep_node):
		_deep_node.queue_free()
	_deep_node = null
	_program = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Scene defaults
	add_test("deep_node_is_deposit_subclass", _test_deep_node_is_deposit_subclass)
	add_test("deep_node_infinite_true_by_default", _test_deep_node_infinite_true_by_default)
	add_test("deep_node_yield_rate_below_surface", _test_deep_node_yield_rate_below_surface)
	add_test("deep_node_drone_accessible_true", _test_deep_node_drone_accessible_true)

	# Extraction behavior
	add_test("deep_node_extract_does_not_reduce_stock", _test_deep_node_extract_does_not_reduce_stock)
	add_test("deep_node_not_depleted_after_extraction", _test_deep_node_not_depleted_after_extraction)
	add_test("deep_node_never_emits_depleted_signal", _test_deep_node_never_emits_depleted_signal)
	add_test("deep_node_not_depleted_after_many_extractions", _test_deep_node_not_depleted_after_many_extractions)
	add_test("deep_node_extract_returns_correct_resource", _test_deep_node_extract_returns_correct_resource)

	# Mining integration (yield_rate formula)
	add_test("mining_duration_scales_with_yield_rate", _test_mining_duration_scales_with_yield_rate)
	add_test("mining_duration_normal_for_surface_node", _test_mining_duration_normal_for_surface_node)

	# Drone integration
	add_test("drone_program_accepts_analyzed_deep_node", _test_drone_program_accepts_analyzed_deep_node)
	add_test("drone_extraction_scales_with_yield_rate", _test_drone_extraction_scales_with_yield_rate)

	# Respawn system exclusion
	add_test("deep_node_infinite_for_respawn_skip", _test_deep_node_infinite_for_respawn_skip)


# ── Test Methods ──────────────────────────────────────────

# -- Scene defaults --

func _test_deep_node_is_deposit_subclass() -> void:
	assert_true(_deep_node is Deposit,
		"DeepResourceNode must be a Deposit subclass")


func _test_deep_node_infinite_true_by_default() -> void:
	assert_true(_deep_node.infinite,
		"DeepResourceNode must enforce infinite = true")


func _test_deep_node_yield_rate_below_surface() -> void:
	assert_true(_deep_node.yield_rate < 1.0,
		"DeepResourceNode yield_rate must be below surface baseline (1.0); got %f" % _deep_node.yield_rate)


func _test_deep_node_drone_accessible_true() -> void:
	assert_true(_deep_node.drone_accessible,
		"DeepResourceNode must have drone_accessible = true")


# -- Extraction behavior --

func _test_deep_node_extract_does_not_reduce_stock() -> void:
	var before: int = _deep_node.get_remaining()
	_deep_node.extract(10)
	assert_equal(_deep_node.get_remaining(), before,
		"DeepResourceNode stock must not decrease on extract")


func _test_deep_node_not_depleted_after_extraction() -> void:
	_deep_node.extract(1000)
	assert_false(_deep_node.is_depleted(),
		"DeepResourceNode must not be depleted after extraction")


func _test_deep_node_never_emits_depleted_signal() -> void:
	_deep_node.extract(9999)
	assert_false(_spy.was_emitted("depleted"),
		"DeepResourceNode must never emit depleted signal")


func _test_deep_node_not_depleted_after_many_extractions() -> void:
	for i: int in range(100):
		_deep_node.extract(10)
	assert_false(_deep_node.is_depleted(),
		"DeepResourceNode must not deplete after 100 extractions")


func _test_deep_node_extract_returns_correct_resource() -> void:
	var result: Dictionary = _deep_node.extract(5)
	assert_equal(result.get("resource_type"), ResourceDefs.ResourceType.SCRAP_METAL,
		"Extract must return correct resource_type")
	assert_equal(result.get("purity"), ResourceDefs.Purity.THREE_STAR,
		"Extract must return correct purity")
	assert_equal(result.get("quantity", 0) as int, 5,
		"Extract must return full requested quantity")


# -- Mining integration (yield_rate formula) --

func _test_mining_duration_scales_with_yield_rate() -> void:
	var base_duration: float = Mining.EXTRACTION_DURATION
	var effective_duration: float = base_duration / _deep_node.yield_rate
	assert_true(effective_duration > base_duration,
		"Deep node effective mining duration (%f) must exceed surface duration (%f)" % [
			effective_duration, base_duration])


func _test_mining_duration_normal_for_surface_node() -> void:
	var surface: Deposit = Deposit.new()
	add_child(surface)
	var base_duration: float = Mining.EXTRACTION_DURATION
	var effective_duration: float = base_duration / surface.yield_rate
	assert_equal(effective_duration, base_duration,
		"Surface node effective mining duration must equal base duration")
	surface.queue_free()


# -- Drone integration --

func _test_drone_program_accepts_analyzed_deep_node() -> void:
	_deep_node.ping()
	_deep_node.mark_analyzed()
	assert_true(_program.accepts_deposit(_deep_node),
		"DroneProgram must accept an analyzed DeepResourceNode")


func _test_drone_extraction_scales_with_yield_rate() -> void:
	# Verify that applying yield_rate to a base extraction rate produces a slower rate
	var base_rate: float = 2.0
	var effective_rate: float = base_rate * _deep_node.yield_rate
	assert_true(effective_rate < base_rate,
		"Deep node drone extraction rate (%f) must be less than base (%f)" % [
			effective_rate, base_rate])


# -- Respawn system exclusion --

func _test_deep_node_infinite_for_respawn_skip() -> void:
	assert_true(_deep_node.infinite,
		"DeepResourceNode.infinite must be true (respawn system uses this to skip deep nodes)")
