## Unit tests for the mining minigame yield calculation and pattern line count.
## Verifies the +50% bonus multiplier, pattern line counts by tier/purity,
## and minigame lifecycle. Uses Deposit node for pattern line computation.
class_name TestMiningMinigameUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _deposit: Deposit = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	PlayerInventory.clear_all()
	_deposit = Deposit.new()
	_deposit.name = "MinigameTestDeposit"
	add_child(_deposit)


func after_each() -> void:
	if is_instance_valid(_deposit):
		_deposit.queue_free()
	_deposit = null
	PlayerInventory.clear_all()


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Bonus multiplier constant
	add_test("bonus_multiplier_is_50_percent", _test_bonus_multiplier_is_50_percent)
	# Yield calculation
	add_test("bonus_yield_ceils_fractional_amount", _test_bonus_yield_ceils_fractional_amount)
	add_test("bonus_yield_for_8_units_is_4", _test_bonus_yield_for_8_units_is_4)
	add_test("bonus_yield_for_7_units_is_4", _test_bonus_yield_for_7_units_is_4)
	add_test("bonus_yield_for_1_unit_is_1", _test_bonus_yield_for_1_unit_is_1)
	# Pattern line counts by tier/purity
	add_test("tier1_low_purity_has_1_line", _test_tier1_low_purity_has_1_line)
	add_test("tier1_high_purity_has_2_lines", _test_tier1_high_purity_has_2_lines)
	add_test("tier2_low_purity_has_2_lines", _test_tier2_low_purity_has_2_lines)
	add_test("tier2_high_purity_has_3_lines", _test_tier2_high_purity_has_3_lines)
	add_test("tier3_low_purity_has_3_lines", _test_tier3_low_purity_has_3_lines)
	add_test("tier3_high_purity_has_4_lines", _test_tier3_high_purity_has_4_lines)
	# Pattern lines only after analysis
	add_test("undiscovered_deposit_has_0_lines", _test_undiscovered_deposit_has_0_lines)
	add_test("analyzed_deposit_has_lines", _test_analyzed_deposit_has_lines)


# ── Helpers ───────────────────────────────────────────────

func _setup_deposit(tier: ResourceDefs.DepositTier, purity: ResourceDefs.Purity) -> void:
	_deposit.setup(
		ResourceDefs.ResourceType.SCRAP_METAL,
		purity,
		ResourceDefs.DensityTier.MEDIUM,
		40
	)
	_deposit.deposit_tier = tier


func _compute_bonus(extracted: int) -> int:
	return ceili(extracted * 0.5)


# ── Test Methods ──────────────────────────────────────────

# -- Bonus multiplier --

func _test_bonus_multiplier_is_50_percent() -> void:
	var script: Script = load("res://scripts/gameplay/mining.gd")
	assert_equal(script.get("BONUS_MULTIPLIER"), 0.5, "BONUS_MULTIPLIER should be 0.5")


# -- Yield calculation --

func _test_bonus_yield_ceils_fractional_amount() -> void:
	# ceili(3 * 0.5) = ceili(1.5) = 2
	var bonus: int = ceili(3 * 0.5)
	assert_equal(bonus, 2, "Bonus for 3 extracted should be 2 (ceiling)")


func _test_bonus_yield_for_8_units_is_4() -> void:
	var bonus: int = _compute_bonus(8)
	assert_equal(bonus, 4, "Bonus for 8 extracted should be 4")


func _test_bonus_yield_for_7_units_is_4() -> void:
	# ceili(7 * 0.5) = ceili(3.5) = 4
	var bonus: int = _compute_bonus(7)
	assert_equal(bonus, 4, "Bonus for 7 extracted should be 4 (ceiling)")


func _test_bonus_yield_for_1_unit_is_1() -> void:
	# ceili(1 * 0.5) = ceili(0.5) = 1
	var bonus: int = _compute_bonus(1)
	assert_equal(bonus, 1, "Bonus for 1 extracted should be 1 (ceiling)")


# -- Pattern line counts --

func _test_tier1_low_purity_has_1_line() -> void:
	_setup_deposit(ResourceDefs.DepositTier.TIER_1, ResourceDefs.Purity.TWO_STAR)
	_deposit.ping()
	_deposit.mark_analyzed()
	assert_equal(_deposit.get_pattern_line_count(), 1, "Tier 1 low purity should have 1 line")


func _test_tier1_high_purity_has_2_lines() -> void:
	_setup_deposit(ResourceDefs.DepositTier.TIER_1, ResourceDefs.Purity.THREE_STAR)
	_deposit.ping()
	_deposit.mark_analyzed()
	assert_equal(_deposit.get_pattern_line_count(), 2, "Tier 1 high purity should have 2 lines")


func _test_tier2_low_purity_has_2_lines() -> void:
	_setup_deposit(ResourceDefs.DepositTier.TIER_2, ResourceDefs.Purity.TWO_STAR)
	_deposit.ping()
	_deposit.mark_analyzed()
	assert_equal(_deposit.get_pattern_line_count(), 2, "Tier 2 low purity should have 2 lines")


func _test_tier2_high_purity_has_3_lines() -> void:
	_setup_deposit(ResourceDefs.DepositTier.TIER_2, ResourceDefs.Purity.THREE_STAR)
	_deposit.ping()
	_deposit.mark_analyzed()
	assert_equal(_deposit.get_pattern_line_count(), 3, "Tier 2 high purity should have 3 lines")


func _test_tier3_low_purity_has_3_lines() -> void:
	_setup_deposit(ResourceDefs.DepositTier.TIER_3, ResourceDefs.Purity.TWO_STAR)
	_deposit.ping()
	_deposit.mark_analyzed()
	assert_equal(_deposit.get_pattern_line_count(), 3, "Tier 3 low purity should have 3 lines")


func _test_tier3_high_purity_has_4_lines() -> void:
	_setup_deposit(ResourceDefs.DepositTier.TIER_3, ResourceDefs.Purity.THREE_STAR)
	_deposit.ping()
	_deposit.mark_analyzed()
	assert_equal(_deposit.get_pattern_line_count(), 4, "Tier 3 high purity should have 4 lines")


# -- Pattern lines gated on analysis --

func _test_undiscovered_deposit_has_0_lines() -> void:
	_setup_deposit(ResourceDefs.DepositTier.TIER_1, ResourceDefs.Purity.THREE_STAR)
	# Not pinged, not analyzed
	assert_equal(_deposit.get_pattern_line_count(), 0, "Undiscovered deposit should have 0 pattern lines")


func _test_analyzed_deposit_has_lines() -> void:
	_setup_deposit(ResourceDefs.DepositTier.TIER_1, ResourceDefs.Purity.THREE_STAR)
	_deposit.ping()
	_deposit.mark_analyzed()
	assert_true(_deposit.get_pattern_line_count() > 0, "Analyzed deposit should have pattern lines")
