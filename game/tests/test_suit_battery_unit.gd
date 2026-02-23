## Unit tests for the SuitBattery system. Verifies charge/drain mechanics, recharge
## behavior, mining cost calculations, depletion penalties, and signal emissions.
class_name TestSuitBatteryUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _battery: SuitBattery = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_battery = SuitBattery.new()
	add_child(_battery)
	_spy = SignalSpy.new()
	_spy.watch(_battery, "charge_changed")
	_spy.watch(_battery, "battery_depleted")
	_spy.watch(_battery, "battery_recharged")


func after_each() -> void:
	_spy.clear()
	_spy = null
	_battery.queue_free()
	_battery = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	add_test("initial_charge_is_max", _test_initial_charge_is_max)
	add_test("initial_charge_percent_is_one", _test_initial_charge_percent_is_one)
	add_test("initial_not_depleted", _test_initial_not_depleted)
	add_test("initial_not_recharging", _test_initial_not_recharging)
	add_test("drain_reduces_charge", _test_drain_reduces_charge)
	add_test("drain_returns_actual_drained", _test_drain_returns_actual_drained)
	add_test("drain_more_than_available", _test_drain_more_than_available)
	add_test("drain_zero_returns_zero", _test_drain_zero_returns_zero)
	add_test("drain_negative_returns_zero", _test_drain_negative_returns_zero)
	add_test("drain_emits_charge_changed", _test_drain_emits_charge_changed)
	add_test("drain_to_zero_emits_battery_depleted", _test_drain_to_zero_emits_battery_depleted)
	add_test("is_depleted_at_zero_charge", _test_is_depleted_at_zero_charge)
	add_test("movement_multiplier_normal", _test_movement_multiplier_normal)
	add_test("movement_multiplier_depleted", _test_movement_multiplier_depleted)
	add_test("movement_penalty_is_25_percent", _test_movement_penalty_is_25_percent)
	add_test("drain_for_mining_tier_1", _test_drain_for_mining_tier_1)
	add_test("drain_for_mining_tier_2", _test_drain_for_mining_tier_2)
	add_test("drain_for_mining_tier_3", _test_drain_for_mining_tier_3)
	add_test("drain_for_mining_tier_4", _test_drain_for_mining_tier_4)
	add_test("estimate_mining_cost_calculation", _test_estimate_mining_cost_calculation)
	add_test("can_mine_with_sufficient_charge", _test_can_mine_with_sufficient_charge)
	add_test("can_mine_returns_false_when_depleted", _test_can_mine_returns_false_when_depleted)
	add_test("start_stop_recharge", _test_start_stop_recharge)
	add_test("process_recharge_increases_charge", _test_process_recharge_increases_charge)
	add_test("process_recharge_caps_at_max", _test_process_recharge_caps_at_max)
	add_test("process_recharge_emits_battery_recharged", _test_process_recharge_emits_battery_recharged)
	add_test("process_recharge_does_nothing_when_not_recharging", _test_process_recharge_does_nothing_when_not_recharging)
	add_test("restore_full_resets_to_max", _test_restore_full_resets_to_max)
	add_test("restore_full_stops_recharging", _test_restore_full_stops_recharging)
	add_test("recharge_rate_is_50_per_second", _test_recharge_rate_is_50_per_second)
	add_test("drain_rates_per_tier_correct", _test_drain_rates_per_tier_correct)
	add_test("charge_never_goes_negative", _test_charge_never_goes_negative)


# ── Test Methods ──────────────────────────────────────────

func _test_initial_charge_is_max() -> void:
	assert_equal(_battery.get_charge(), 100.0,
		"Initial charge should be max_charge (100.0)")


func _test_initial_charge_percent_is_one() -> void:
	assert_equal(_battery.get_charge_percent(), 1.0,
		"Initial charge percent should be 1.0")


func _test_initial_not_depleted() -> void:
	assert_false(_battery.is_depleted(),
		"New battery should not be depleted")


func _test_initial_not_recharging() -> void:
	assert_false(_battery.is_recharging(),
		"New battery should not be recharging")


func _test_drain_reduces_charge() -> void:
	_battery.drain(20.0)
	assert_equal(_battery.get_charge(), 80.0,
		"Charge should be 80.0 after draining 20.0")


func _test_drain_returns_actual_drained() -> void:
	var drained: float = _battery.drain(30.0)
	assert_equal(drained, 30.0, "Should return actual amount drained")


func _test_drain_more_than_available() -> void:
	_battery.drain(80.0)
	var drained: float = _battery.drain(50.0)
	assert_equal(drained, 20.0,
		"Should only drain remaining charge")
	assert_equal(_battery.get_charge(), 0.0,
		"Charge should be 0 after over-drain")


func _test_drain_zero_returns_zero() -> void:
	var drained: float = _battery.drain(0.0)
	assert_equal(drained, 0.0, "Draining 0 should return 0")
	assert_equal(_battery.get_charge(), 100.0,
		"Charge should be unchanged")


func _test_drain_negative_returns_zero() -> void:
	var drained: float = _battery.drain(-10.0)
	assert_equal(drained, 0.0, "Draining negative should return 0")
	assert_equal(_battery.get_charge(), 100.0,
		"Charge should be unchanged")


func _test_drain_emits_charge_changed() -> void:
	_battery.drain(10.0)
	assert_signal_emitted(_spy, "charge_changed",
		"charge_changed should be emitted on drain")
	var args: Array = _spy.get_emission_args("charge_changed", 0)
	assert_equal(args[0], 90.0, "First arg should be current charge (90.0)")
	assert_equal(args[1], 100.0, "Second arg should be max charge (100.0)")


func _test_drain_to_zero_emits_battery_depleted() -> void:
	_battery.drain(100.0)
	assert_signal_emitted(_spy, "battery_depleted",
		"battery_depleted should be emitted at zero charge")


func _test_is_depleted_at_zero_charge() -> void:
	_battery.drain(100.0)
	assert_true(_battery.is_depleted(),
		"Battery should be depleted at 0 charge")


func _test_movement_multiplier_normal() -> void:
	assert_equal(_battery.get_movement_multiplier(), 1.0,
		"Normal movement multiplier should be 1.0")


func _test_movement_multiplier_depleted() -> void:
	_battery.drain(100.0)
	assert_equal(_battery.get_movement_multiplier(), 0.75,
		"Depleted movement multiplier should be 0.75")


func _test_movement_penalty_is_25_percent() -> void:
	assert_equal(SuitBattery.MOVEMENT_PENALTY, 0.25,
		"MOVEMENT_PENALTY constant should be 0.25")


func _test_drain_for_mining_tier_1() -> void:
	var drained: float = _battery.drain_for_mining(ResourceDefs.DepositTier.TIER_1)
	assert_equal(drained, 2.0, "Tier 1 mining should drain 2.0")


func _test_drain_for_mining_tier_2() -> void:
	var drained: float = _battery.drain_for_mining(ResourceDefs.DepositTier.TIER_2)
	assert_equal(drained, 4.0, "Tier 2 mining should drain 4.0")


func _test_drain_for_mining_tier_3() -> void:
	var drained: float = _battery.drain_for_mining(ResourceDefs.DepositTier.TIER_3)
	assert_equal(drained, 7.0, "Tier 3 mining should drain 7.0")


func _test_drain_for_mining_tier_4() -> void:
	var drained: float = _battery.drain_for_mining(ResourceDefs.DepositTier.TIER_4)
	assert_equal(drained, 12.0, "Tier 4 mining should drain 12.0")


func _test_estimate_mining_cost_calculation() -> void:
	var cost: float = _battery.estimate_mining_cost(ResourceDefs.DepositTier.TIER_1, 10)
	assert_equal(cost, 20.0, "Mining 10 units at Tier 1 (2.0 each) should cost 20.0")
	var cost_t3: float = _battery.estimate_mining_cost(ResourceDefs.DepositTier.TIER_3, 5)
	assert_equal(cost_t3, 35.0, "Mining 5 units at Tier 3 (7.0 each) should cost 35.0")


func _test_can_mine_with_sufficient_charge() -> void:
	assert_true(_battery.can_mine(ResourceDefs.DepositTier.TIER_1),
		"Should be able to mine Tier 1 at full charge")
	assert_true(_battery.can_mine(ResourceDefs.DepositTier.TIER_4),
		"Should be able to mine Tier 4 at full charge")


func _test_can_mine_returns_false_when_depleted() -> void:
	_battery.drain(100.0)
	assert_false(_battery.can_mine(ResourceDefs.DepositTier.TIER_1),
		"Should not be able to mine when depleted")


func _test_start_stop_recharge() -> void:
	_battery.start_recharge()
	assert_true(_battery.is_recharging(),
		"Should be recharging after start_recharge")
	_battery.stop_recharge()
	assert_false(_battery.is_recharging(),
		"Should stop recharging after stop_recharge")


func _test_process_recharge_increases_charge() -> void:
	_battery.drain(50.0)
	_spy.clear()
	_battery.start_recharge()
	# Simulate 0.5 seconds — recharge rate is 50/sec, so 25 units
	_battery.process_recharge(0.5)
	assert_equal(_battery.get_charge(), 75.0,
		"Charge should be 75.0 after recharging 25 units")
	assert_signal_emitted(_spy, "charge_changed",
		"charge_changed should emit during recharge")


func _test_process_recharge_caps_at_max() -> void:
	_battery.drain(10.0)
	_battery.start_recharge()
	# Simulate long enough to exceed max
	_battery.process_recharge(5.0)
	assert_equal(_battery.get_charge(), 100.0,
		"Charge should cap at max_charge")


func _test_process_recharge_emits_battery_recharged() -> void:
	_battery.drain(10.0)
	_battery.start_recharge()
	_battery.process_recharge(5.0)
	assert_signal_emitted(_spy, "battery_recharged",
		"battery_recharged should be emitted when fully charged")
	assert_false(_battery.is_recharging(),
		"Should stop recharging after reaching max")


func _test_process_recharge_does_nothing_when_not_recharging() -> void:
	_battery.drain(50.0)
	_spy.clear()
	var result: bool = _battery.process_recharge(1.0)
	assert_false(result, "process_recharge should return false when not recharging")
	assert_equal(_battery.get_charge(), 50.0,
		"Charge should be unchanged when not recharging")


func _test_restore_full_resets_to_max() -> void:
	_battery.drain(80.0)
	_battery.restore_full()
	assert_equal(_battery.get_charge(), 100.0,
		"restore_full should set charge to max")
	assert_signal_emitted(_spy, "battery_recharged",
		"battery_recharged should be emitted on restore_full")


func _test_restore_full_stops_recharging() -> void:
	_battery.start_recharge()
	_battery.restore_full()
	assert_false(_battery.is_recharging(),
		"restore_full should stop recharging state")


func _test_recharge_rate_is_50_per_second() -> void:
	assert_equal(SuitBattery.RECHARGE_RATE, 50.0,
		"RECHARGE_RATE should be 50.0 per design spec")


func _test_drain_rates_per_tier_correct() -> void:
	assert_equal(SuitBattery.DRAIN_RATES_PER_TIER[ResourceDefs.DepositTier.TIER_1], 2.0,
		"Tier 1 drain rate should be 2.0")
	assert_equal(SuitBattery.DRAIN_RATES_PER_TIER[ResourceDefs.DepositTier.TIER_2], 4.0,
		"Tier 2 drain rate should be 4.0")
	assert_equal(SuitBattery.DRAIN_RATES_PER_TIER[ResourceDefs.DepositTier.TIER_3], 7.0,
		"Tier 3 drain rate should be 7.0")
	assert_equal(SuitBattery.DRAIN_RATES_PER_TIER[ResourceDefs.DepositTier.TIER_4], 12.0,
		"Tier 4 drain rate should be 12.0")


func _test_charge_never_goes_negative() -> void:
	_battery.drain(200.0)
	assert_true(_battery.get_charge() >= 0.0,
		"Charge should never go below 0")
