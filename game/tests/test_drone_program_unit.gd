## Unit tests for the DroneProgram resource. Verifies deposit filtering logic:
## resource type, purity, tool tier, scan state, and depletion checks.
class_name TestDroneProgramUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _program: DroneProgram = null
var _deposit: Deposit = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_program = DroneProgram.new()
	_program.target_resource_type = ResourceDefs.ResourceType.SCRAP_METAL
	_program.minimum_purity = ResourceDefs.Purity.ONE_STAR
	_program.tool_tier_assignment = ResourceDefs.DepositTier.TIER_1
	_program.extraction_radius = 100.0
	_program.priority_order = 0

	_deposit = Deposit.new()
	_deposit.name = "TestDeposit"
	_deposit.setup(
		ResourceDefs.ResourceType.SCRAP_METAL,
		ResourceDefs.Purity.THREE_STAR,
		ResourceDefs.DensityTier.MEDIUM,
		40
	)
	add_child(_deposit)
	_deposit.ping()
	_deposit.mark_analyzed()


func after_each() -> void:
	_program = null
	if is_instance_valid(_deposit):
		_deposit.queue_free()
	_deposit = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Accept valid deposit
	add_test("accepts_analyzed_matching_deposit", _test_accepts_analyzed_matching_deposit)
	# Rejection: scan state
	add_test("rejects_undiscovered_deposit", _test_rejects_undiscovered_deposit)
	add_test("rejects_pinged_but_not_analyzed", _test_rejects_pinged_but_not_analyzed)
	# Rejection: depleted
	add_test("rejects_depleted_deposit", _test_rejects_depleted_deposit)
	# Rejection: resource type
	add_test("rejects_wrong_resource_type", _test_rejects_wrong_resource_type)
	add_test("accepts_any_type_when_none_filter", _test_accepts_any_type_when_none_filter)
	# Rejection: purity
	add_test("rejects_below_minimum_purity", _test_rejects_below_minimum_purity)
	# Rejection: tool tier
	add_test("rejects_above_tool_tier", _test_rejects_above_tool_tier)
	# Edge cases
	add_test("accepts_exact_minimum_purity", _test_accepts_exact_minimum_purity)
	add_test("accepts_exact_tool_tier", _test_accepts_exact_tool_tier)


# ── Helpers ───────────────────────────────────────────────

func _make_deposit(res_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity,
		tier: ResourceDefs.DepositTier, quantity: int, analyzed: bool) -> Deposit:
	var d: Deposit = Deposit.new()
	d.name = "TempDeposit"
	d.setup(res_type, purity, ResourceDefs.DensityTier.MEDIUM, quantity)
	d.deposit_tier = tier
	add_child(d)
	if analyzed:
		d.ping()
		d.mark_analyzed()
	return d


# ── Test Methods ──────────────────────────────────────────

func _test_accepts_analyzed_matching_deposit() -> void:
	assert_true(_program.accepts_deposit(_deposit),
		"Should accept analyzed deposit matching all filters")


func _test_rejects_undiscovered_deposit() -> void:
	var d: Deposit = _make_deposit(ResourceDefs.ResourceType.SCRAP_METAL,
		ResourceDefs.Purity.THREE_STAR, ResourceDefs.DepositTier.TIER_1, 40, false)
	assert_false(_program.accepts_deposit(d), "Should reject undiscovered deposit")
	d.queue_free()


func _test_rejects_pinged_but_not_analyzed() -> void:
	var d: Deposit = Deposit.new()
	d.name = "PingedDeposit"
	d.setup(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR,
		ResourceDefs.DensityTier.MEDIUM, 40)
	add_child(d)
	d.ping()  # Pinged but NOT analyzed
	assert_false(_program.accepts_deposit(d), "Should reject pinged-but-not-analyzed deposit")
	d.queue_free()


func _test_rejects_depleted_deposit() -> void:
	_deposit.extract(40)  # Fully deplete
	assert_false(_program.accepts_deposit(_deposit), "Should reject depleted deposit")


func _test_rejects_wrong_resource_type() -> void:
	var d: Deposit = _make_deposit(ResourceDefs.ResourceType.METAL,
		ResourceDefs.Purity.THREE_STAR, ResourceDefs.DepositTier.TIER_1, 40, true)
	assert_false(_program.accepts_deposit(d), "Should reject deposit with wrong resource type")
	d.queue_free()


func _test_accepts_any_type_when_none_filter() -> void:
	_program.target_resource_type = ResourceDefs.ResourceType.NONE
	var d: Deposit = _make_deposit(ResourceDefs.ResourceType.METAL,
		ResourceDefs.Purity.THREE_STAR, ResourceDefs.DepositTier.TIER_1, 40, true)
	assert_true(_program.accepts_deposit(d),
		"Should accept any resource type when filter is NONE")
	d.queue_free()


func _test_rejects_below_minimum_purity() -> void:
	_program.minimum_purity = ResourceDefs.Purity.FIVE_STAR
	assert_false(_program.accepts_deposit(_deposit),
		"Should reject deposit below minimum purity")


func _test_rejects_above_tool_tier() -> void:
	var d: Deposit = _make_deposit(ResourceDefs.ResourceType.SCRAP_METAL,
		ResourceDefs.Purity.THREE_STAR, ResourceDefs.DepositTier.TIER_3, 40, true)
	assert_false(_program.accepts_deposit(d),
		"Should reject deposit requiring higher tool tier than assignment")
	d.queue_free()


func _test_accepts_exact_minimum_purity() -> void:
	_program.minimum_purity = ResourceDefs.Purity.THREE_STAR
	assert_true(_program.accepts_deposit(_deposit),
		"Should accept deposit at exact minimum purity")


func _test_accepts_exact_tool_tier() -> void:
	_program.tool_tier_assignment = ResourceDefs.DepositTier.TIER_1
	assert_true(_program.accepts_deposit(_deposit),
		"Should accept deposit at exact tool tier")
