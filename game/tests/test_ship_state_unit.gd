## Unit tests for the ShipState system. Verifies ship global variables (Power, Integrity,
## Heat, Oxygen), clamping, signal emissions, power management, and reset behavior.
class_name TestShipStateUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _ship: ShipStateType = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_ship = ShipStateType.new()
	add_child(_ship)
	_spy = SignalSpy.new()
	_spy.watch(_ship, "power_changed")
	_spy.watch(_ship, "integrity_changed")
	_spy.watch(_ship, "heat_changed")
	_spy.watch(_ship, "oxygen_changed")


func after_each() -> void:
	_spy.clear()
	_spy = null
	_ship.queue_free()
	_ship = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Initial state
	add_test("initial_power_is_max", _test_initial_power_is_max)
	add_test("initial_integrity_is_max", _test_initial_integrity_is_max)
	add_test("initial_heat_is_50", _test_initial_heat_is_50)
	add_test("initial_oxygen_is_max", _test_initial_oxygen_is_max)
	add_test("initial_module_draw_is_zero", _test_initial_module_draw_is_zero)
	# Constants
	add_test("min_value_is_zero", _test_min_value_is_zero)
	add_test("max_value_is_100", _test_max_value_is_100)
	add_test("baseline_power_is_50", _test_baseline_power_is_50)
	# Setters and clamping
	add_test("set_power_clamps_to_range", _test_set_power_clamps_to_range)
	add_test("set_integrity_clamps_to_range", _test_set_integrity_clamps_to_range)
	add_test("set_heat_clamps_to_range", _test_set_heat_clamps_to_range)
	add_test("set_oxygen_clamps_to_range", _test_set_oxygen_clamps_to_range)
	add_test("set_same_value_does_not_emit_signal", _test_set_same_value_does_not_emit_signal)
	# Signals
	add_test("set_power_emits_power_changed", _test_set_power_emits_power_changed)
	add_test("set_integrity_emits_integrity_changed", _test_set_integrity_emits_integrity_changed)
	add_test("set_heat_emits_heat_changed", _test_set_heat_emits_heat_changed)
	add_test("set_oxygen_emits_oxygen_changed", _test_set_oxygen_emits_oxygen_changed)
	# Adjust methods
	add_test("adjust_power_adds_delta", _test_adjust_power_adds_delta)
	add_test("adjust_integrity_subtracts_delta", _test_adjust_integrity_subtracts_delta)
	add_test("adjust_heat_clamps_at_max", _test_adjust_heat_clamps_at_max)
	add_test("adjust_oxygen_clamps_at_zero", _test_adjust_oxygen_clamps_at_zero)
	# Power management
	add_test("register_module_draw_succeeds", _test_register_module_draw_succeeds)
	add_test("register_module_draw_fails_on_overload", _test_register_module_draw_fails_on_overload)
	add_test("deregister_module_draw_reduces_total", _test_deregister_module_draw_reduces_total)
	add_test("deregister_draw_clamps_at_zero", _test_deregister_draw_clamps_at_zero)
	add_test("available_capacity_reflects_draw", _test_available_capacity_reflects_draw)
	add_test("would_exceed_capacity_boundary", _test_would_exceed_capacity_boundary)
	add_test("multiple_modules_accumulate_draw", _test_multiple_modules_accumulate_draw)
	# Reset
	add_test("reset_restores_defaults", _test_reset_restores_defaults)
	add_test("reset_clears_module_draw", _test_reset_clears_module_draw)


# ── Test Methods ──────────────────────────────────────────

# -- Initial state --

func _test_initial_power_is_max() -> void:
	assert_equal(_ship.get_power(), 100.0, "Power should start at MAX_VALUE (100)")


func _test_initial_integrity_is_max() -> void:
	assert_equal(_ship.get_integrity(), 100.0, "Integrity should start at MAX_VALUE (100)")


func _test_initial_heat_is_50() -> void:
	assert_equal(_ship.get_heat(), 50.0, "Heat should start at 50.0 (neutral)")


func _test_initial_oxygen_is_max() -> void:
	assert_equal(_ship.get_oxygen(), 100.0, "Oxygen should start at MAX_VALUE (100)")


func _test_initial_module_draw_is_zero() -> void:
	assert_equal(_ship.get_total_module_draw(), 0.0, "Module draw should start at 0")


# -- Constants --

func _test_min_value_is_zero() -> void:
	assert_equal(ShipStateType.MIN_VALUE, 0.0, "MIN_VALUE should be 0.0")


func _test_max_value_is_100() -> void:
	assert_equal(ShipStateType.MAX_VALUE, 100.0, "MAX_VALUE should be 100.0")


func _test_baseline_power_is_50() -> void:
	assert_equal(ShipStateType.BASELINE_POWER, 50.0, "BASELINE_POWER should be 50.0")
	assert_equal(_ship.get_baseline_power(), 50.0, "get_baseline_power() should return 50.0")


# -- Setters and clamping --

func _test_set_power_clamps_to_range() -> void:
	_ship.set_power(150.0)
	assert_equal(_ship.get_power(), 100.0, "Power above 100 should clamp to 100")
	_ship.set_power(-20.0)
	assert_equal(_ship.get_power(), 0.0, "Power below 0 should clamp to 0")


func _test_set_integrity_clamps_to_range() -> void:
	_ship.set_integrity(200.0)
	assert_equal(_ship.get_integrity(), 100.0, "Integrity above 100 should clamp to 100")
	_ship.set_integrity(-50.0)
	assert_equal(_ship.get_integrity(), 0.0, "Integrity below 0 should clamp to 0")


func _test_set_heat_clamps_to_range() -> void:
	_ship.set_heat(999.0)
	assert_equal(_ship.get_heat(), 100.0, "Heat above 100 should clamp to 100")
	_ship.set_heat(-10.0)
	assert_equal(_ship.get_heat(), 0.0, "Heat below 0 should clamp to 0")


func _test_set_oxygen_clamps_to_range() -> void:
	_ship.set_oxygen(150.0)
	assert_equal(_ship.get_oxygen(), 100.0, "Oxygen above 100 should clamp to 100")
	_ship.set_oxygen(-5.0)
	assert_equal(_ship.get_oxygen(), 0.0, "Oxygen below 0 should clamp to 0")


func _test_set_same_value_does_not_emit_signal() -> void:
	# Power starts at 100.0; setting to 100.0 again should not emit
	_ship.set_power(100.0)
	assert_false(_spy.was_emitted("power_changed"),
		"Setting same value should not emit power_changed")


# -- Signals --

func _test_set_power_emits_power_changed() -> void:
	_ship.set_power(75.0)
	assert_signal_emitted(_spy, "power_changed", "power_changed should emit on set_power")
	var args: Array = _spy.get_emission_args("power_changed", 0)
	assert_equal(args[0], 75.0, "Signal should report current=75.0")
	assert_equal(args[1], 100.0, "Signal should report maximum=100.0")


func _test_set_integrity_emits_integrity_changed() -> void:
	_ship.set_integrity(60.0)
	assert_signal_emitted(_spy, "integrity_changed", "integrity_changed should emit")
	var args: Array = _spy.get_emission_args("integrity_changed", 0)
	assert_equal(args[0], 60.0, "Signal should report current=60.0")
	assert_equal(args[1], 100.0, "Signal should report maximum=100.0")


func _test_set_heat_emits_heat_changed() -> void:
	_ship.set_heat(80.0)
	assert_signal_emitted(_spy, "heat_changed", "heat_changed should emit on set_heat")
	var args: Array = _spy.get_emission_args("heat_changed", 0)
	assert_equal(args[0], 80.0, "Signal should report current=80.0")


func _test_set_oxygen_emits_oxygen_changed() -> void:
	_ship.set_oxygen(40.0)
	assert_signal_emitted(_spy, "oxygen_changed", "oxygen_changed should emit on set_oxygen")
	var args: Array = _spy.get_emission_args("oxygen_changed", 0)
	assert_equal(args[0], 40.0, "Signal should report current=40.0")


# -- Adjust methods --

func _test_adjust_power_adds_delta() -> void:
	_ship.set_power(50.0)
	_spy.clear()
	_ship.adjust_power(-10.0)
	assert_equal(_ship.get_power(), 40.0, "adjust_power(-10) from 50 should give 40")
	assert_signal_emitted(_spy, "power_changed", "adjust_power should emit power_changed")


func _test_adjust_integrity_subtracts_delta() -> void:
	_ship.set_integrity(80.0)
	_spy.clear()
	_ship.adjust_integrity(-30.0)
	assert_equal(_ship.get_integrity(), 50.0, "adjust_integrity(-30) from 80 should give 50")


func _test_adjust_heat_clamps_at_max() -> void:
	_ship.set_heat(90.0)
	_spy.clear()
	_ship.adjust_heat(20.0)
	assert_equal(_ship.get_heat(), 100.0, "adjust_heat(+20) from 90 should clamp to 100")


func _test_adjust_oxygen_clamps_at_zero() -> void:
	_ship.set_oxygen(10.0)
	_spy.clear()
	_ship.adjust_oxygen(-20.0)
	assert_equal(_ship.get_oxygen(), 0.0, "adjust_oxygen(-20) from 10 should clamp to 0")


# -- Power management --

func _test_register_module_draw_succeeds() -> void:
	var result: bool = _ship.register_module_draw(10.0)
	assert_true(result, "Register 10.0 draw should succeed (baseline=50)")
	assert_equal(_ship.get_total_module_draw(), 10.0, "Total draw should be 10.0")


func _test_register_module_draw_fails_on_overload() -> void:
	var result: bool = _ship.register_module_draw(51.0)
	assert_false(result, "Register 51.0 draw should fail (exceeds baseline=50)")
	assert_equal(_ship.get_total_module_draw(), 0.0, "Total draw should remain 0 on failure")


func _test_deregister_module_draw_reduces_total() -> void:
	_ship.register_module_draw(20.0)
	_ship.deregister_module_draw(20.0)
	assert_equal(_ship.get_total_module_draw(), 0.0, "Deregister should reduce total to 0")


func _test_deregister_draw_clamps_at_zero() -> void:
	_ship.register_module_draw(5.0)
	_ship.deregister_module_draw(10.0)
	assert_equal(_ship.get_total_module_draw(), 0.0, "Deregister beyond total should clamp to 0")


func _test_available_capacity_reflects_draw() -> void:
	assert_equal(_ship.get_available_power_capacity(), 50.0, "Available should equal baseline with no draw")
	_ship.register_module_draw(10.0)
	assert_equal(_ship.get_available_power_capacity(), 40.0, "Available should be 40 after 10 draw")


func _test_would_exceed_capacity_boundary() -> void:
	# Exactly at capacity should not exceed
	assert_false(_ship.would_exceed_capacity(50.0), "Exactly 50.0 should not exceed baseline=50")
	# Just over should exceed
	assert_true(_ship.would_exceed_capacity(50.1), "50.1 should exceed baseline=50")


func _test_multiple_modules_accumulate_draw() -> void:
	_ship.register_module_draw(10.0)
	_ship.register_module_draw(10.0)
	assert_equal(_ship.get_total_module_draw(), 20.0, "Two 10.0 draws should total 20.0")
	# Third would exceed
	var result: bool = _ship.register_module_draw(31.0)
	assert_false(result, "Third 31.0 draw would exceed capacity (20+31>50)")
	assert_equal(_ship.get_total_module_draw(), 20.0, "Failed register should not change total")


# -- Reset --

func _test_reset_restores_defaults() -> void:
	_ship.set_power(25.0)
	_ship.set_integrity(30.0)
	_ship.set_heat(80.0)
	_ship.set_oxygen(10.0)
	_spy.clear()
	_ship.reset()
	assert_equal(_ship.get_power(), 100.0, "Power should reset to 100")
	assert_equal(_ship.get_integrity(), 100.0, "Integrity should reset to 100")
	assert_equal(_ship.get_heat(), 50.0, "Heat should reset to 50")
	assert_equal(_ship.get_oxygen(), 100.0, "Oxygen should reset to 100")


func _test_reset_clears_module_draw() -> void:
	_ship.register_module_draw(15.0)
	_ship.reset()
	assert_equal(_ship.get_total_module_draw(), 0.0, "Reset should clear module draw")
	assert_equal(_ship.get_available_power_capacity(), 50.0, "Available capacity should be full after reset")
