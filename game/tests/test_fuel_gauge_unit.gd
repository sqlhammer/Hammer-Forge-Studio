## Unit tests for FuelGauge HUD state logic. Verifies correct tint color for each
## fuel level tier (full, normal, low, empty) and signal-driven update handlers.
##
## Coverage target: 80% (per docs/studio/tdd-process-m8.md)
## Ticket: TICKET-0169
class_name TestFuelGaugeUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _gauge: FuelGauge = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_gauge = FuelGauge.new()
	# Bypass _ready() signal connections by not adding to tree;
	# set internal state directly for isolated color logic tests.
	_gauge._fuel_percent = 1.0
	_gauge._is_empty = false
	_gauge._is_low = false
	_gauge._pulse_timer = 0.0


func after_each() -> void:
	_gauge.free()
	_gauge = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Constants
	add_test("low_threshold_matches_fuel_system_defs", _test_low_threshold_matches_fuel_system_defs)
	add_test("color_full_is_green", _test_color_full_is_green)
	add_test("color_normal_is_teal", _test_color_normal_is_teal)
	add_test("color_low_is_amber", _test_color_low_is_amber)
	add_test("color_empty_is_coral", _test_color_empty_is_coral)

	# State color — full
	add_test("full_charge_returns_green", _test_full_charge_returns_green)

	# State color — normal
	add_test("above_low_threshold_returns_teal", _test_above_low_threshold_returns_teal)
	add_test("just_above_low_threshold_returns_teal", _test_just_above_low_threshold_returns_teal)
	add_test("seventy_five_percent_returns_teal", _test_seventy_five_percent_returns_teal)

	# State color — low fuel (amber pulse)
	add_test("at_low_threshold_returns_amber_base", _test_at_low_threshold_returns_amber_base)
	add_test("below_low_threshold_returns_amber_base", _test_below_low_threshold_returns_amber_base)
	add_test("one_percent_returns_amber_base", _test_one_percent_returns_amber_base)

	# State color — empty (coral)
	add_test("zero_percent_returns_coral", _test_zero_percent_returns_coral)
	add_test("is_empty_flag_returns_coral", _test_is_empty_flag_returns_coral)

	# Signal-driven update handlers
	add_test("on_fuel_changed_updates_percent", _test_on_fuel_changed_updates_percent)
	add_test("on_fuel_changed_zero_max_sets_zero", _test_on_fuel_changed_zero_max_sets_zero)
	add_test("on_fuel_changed_clears_empty_when_nonzero", _test_on_fuel_changed_clears_empty_when_nonzero)
	add_test("on_fuel_low_sets_low_flag", _test_on_fuel_low_sets_low_flag)
	add_test("on_fuel_empty_sets_empty_flag", _test_on_fuel_empty_sets_empty_flag)
	add_test("set_fuel_level_updates_percent", _test_set_fuel_level_updates_percent)

	# Edge cases
	add_test("refuel_from_empty_clears_flags", _test_refuel_from_empty_clears_flags)
	add_test("percent_text_at_full", _test_percent_text_at_full)
	add_test("percent_text_at_zero", _test_percent_text_at_zero)


# ── Test Methods — Constants ─────────────────────────────

func _test_low_threshold_matches_fuel_system_defs() -> void:
	assert_equal(FuelGauge.LOW_THRESHOLD, FuelSystemDefs.LOW_FUEL_THRESHOLD_PERCENT,
		"LOW_THRESHOLD should match FuelSystemDefs.LOW_FUEL_THRESHOLD_PERCENT")


func _test_color_full_is_green() -> void:
	var expected: Color = Color("#4ADE80")
	assert_equal(FuelGauge.COLOR_FULL, expected,
		"COLOR_FULL should be green #4ADE80")


func _test_color_normal_is_teal() -> void:
	var expected: Color = Color("#00D4AA")
	assert_equal(FuelGauge.COLOR_NORMAL, expected,
		"COLOR_NORMAL should be teal #00D4AA")


func _test_color_low_is_amber() -> void:
	var expected: Color = Color("#FFB830")
	assert_equal(FuelGauge.COLOR_LOW, expected,
		"COLOR_LOW should be amber #FFB830")


func _test_color_empty_is_coral() -> void:
	var expected: Color = Color("#FF6B5A")
	assert_equal(FuelGauge.COLOR_EMPTY, expected,
		"COLOR_EMPTY should be coral #FF6B5A")


# ── Test Methods — Full State ────────────────────────────

func _test_full_charge_returns_green() -> void:
	_gauge._fuel_percent = 1.0
	var color: Color = _gauge._get_state_color()
	assert_equal(color, FuelGauge.COLOR_FULL,
		"Full fuel should return green COLOR_FULL")


# ── Test Methods — Normal State ──────────────────────────

func _test_above_low_threshold_returns_teal() -> void:
	_gauge._fuel_percent = 0.75
	var color: Color = _gauge._get_state_color()
	assert_equal(color, FuelGauge.COLOR_NORMAL,
		"Fuel at 75% should return teal COLOR_NORMAL")


func _test_just_above_low_threshold_returns_teal() -> void:
	_gauge._fuel_percent = 0.26
	var color: Color = _gauge._get_state_color()
	assert_equal(color, FuelGauge.COLOR_NORMAL,
		"Fuel just above LOW_THRESHOLD (26%) should return teal COLOR_NORMAL")


func _test_seventy_five_percent_returns_teal() -> void:
	_gauge._fuel_percent = 0.75
	var color: Color = _gauge._get_state_color()
	assert_equal(color, FuelGauge.COLOR_NORMAL,
		"Fuel at 75% should return teal COLOR_NORMAL")


# ── Test Methods — Low State ─────────────────────────────

func _test_at_low_threshold_returns_amber_base() -> void:
	_gauge._fuel_percent = 0.25
	_gauge._is_low = true
	var color: Color = _gauge._get_state_color()
	# Low state pulses — check only that the base RGB matches amber
	assert_equal(color.r, FuelGauge.COLOR_LOW.r,
		"Low fuel R channel should match COLOR_LOW")
	assert_equal(color.g, FuelGauge.COLOR_LOW.g,
		"Low fuel G channel should match COLOR_LOW")
	assert_equal(color.b, FuelGauge.COLOR_LOW.b,
		"Low fuel B channel should match COLOR_LOW")


func _test_below_low_threshold_returns_amber_base() -> void:
	_gauge._fuel_percent = 0.15
	_gauge._is_low = true
	var color: Color = _gauge._get_state_color()
	assert_equal(color.r, FuelGauge.COLOR_LOW.r,
		"Low fuel (15%) R channel should match COLOR_LOW")
	assert_equal(color.g, FuelGauge.COLOR_LOW.g,
		"Low fuel (15%) G channel should match COLOR_LOW")
	assert_equal(color.b, FuelGauge.COLOR_LOW.b,
		"Low fuel (15%) B channel should match COLOR_LOW")


func _test_one_percent_returns_amber_base() -> void:
	_gauge._fuel_percent = 0.01
	_gauge._is_low = true
	var color: Color = _gauge._get_state_color()
	assert_equal(color.r, FuelGauge.COLOR_LOW.r,
		"Low fuel (1%) R channel should match COLOR_LOW")
	assert_equal(color.g, FuelGauge.COLOR_LOW.g,
		"Low fuel (1%) G channel should match COLOR_LOW")
	assert_equal(color.b, FuelGauge.COLOR_LOW.b,
		"Low fuel (1%) B channel should match COLOR_LOW")


# ── Test Methods — Empty State ───────────────────────────

func _test_zero_percent_returns_coral() -> void:
	_gauge._fuel_percent = 0.0
	_gauge._is_empty = true
	var color: Color = _gauge._get_state_color()
	assert_equal(color, FuelGauge.COLOR_EMPTY,
		"Zero fuel should return coral COLOR_EMPTY")


func _test_is_empty_flag_returns_coral() -> void:
	_gauge._fuel_percent = 0.0
	_gauge._is_empty = true
	var color: Color = _gauge._get_state_color()
	assert_equal(color, FuelGauge.COLOR_EMPTY,
		"Empty flag set should return coral COLOR_EMPTY")


# ── Test Methods — Signal Handlers ───────────────────────

func _test_on_fuel_changed_updates_percent() -> void:
	_gauge._on_fuel_changed(500.0, 1000.0)
	assert_equal(_gauge._fuel_percent, 0.5,
		"_on_fuel_changed(500, 1000) should set _fuel_percent to 0.5")


func _test_on_fuel_changed_zero_max_sets_zero() -> void:
	_gauge._on_fuel_changed(100.0, 0.0)
	assert_equal(_gauge._fuel_percent, 0.0,
		"_on_fuel_changed with zero max should set _fuel_percent to 0.0")


func _test_on_fuel_changed_clears_empty_when_nonzero() -> void:
	_gauge._is_empty = true
	_gauge._is_low = true
	_gauge._on_fuel_changed(500.0, 1000.0)
	assert_false(_gauge._is_empty,
		"_on_fuel_changed with nonzero current should clear _is_empty")
	assert_false(_gauge._is_low,
		"_on_fuel_changed above threshold should clear _is_low")


func _test_on_fuel_low_sets_low_flag() -> void:
	_gauge._is_low = false
	_gauge._on_fuel_low()
	assert_true(_gauge._is_low,
		"_on_fuel_low should set _is_low to true")


func _test_on_fuel_empty_sets_empty_flag() -> void:
	_gauge._is_empty = false
	_gauge._on_fuel_empty()
	assert_true(_gauge._is_empty,
		"_on_fuel_empty should set _is_empty to true")


func _test_set_fuel_level_updates_percent() -> void:
	_gauge.set_fuel_level(250.0, 1000.0)
	assert_equal(_gauge._fuel_percent, 0.25,
		"set_fuel_level(250, 1000) should set _fuel_percent to 0.25")


# ── Test Methods — Edge Cases ────────────────────────────

func _test_refuel_from_empty_clears_flags() -> void:
	_gauge._is_empty = true
	_gauge._is_low = true
	_gauge._fuel_percent = 0.0
	# Simulate refueling: fuel rises above threshold
	_gauge._on_fuel_changed(500.0, 1000.0)
	assert_false(_gauge._is_empty,
		"Refueling from empty should clear _is_empty")
	assert_false(_gauge._is_low,
		"Refueling above threshold should clear _is_low")
	assert_equal(_gauge._fuel_percent, 0.5,
		"Refueling should update _fuel_percent correctly")


func _test_percent_text_at_full() -> void:
	_gauge._fuel_percent = 1.0
	var text: String = _gauge.get_percent_text()
	assert_equal(text, "100%",
		"Full fuel should display 100%")


func _test_percent_text_at_zero() -> void:
	_gauge._fuel_percent = 0.0
	var text: String = _gauge.get_percent_text()
	assert_equal(text, "0%",
		"Empty fuel should display 0%")
