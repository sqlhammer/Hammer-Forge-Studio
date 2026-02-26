## Unit tests for BatteryBar color state logic. Verifies that the correct tint color
## is returned for each charge tier: full (green), normal (teal), warning (amber), and critical (coral).
class_name TestBatteryBarUnit
extends TestSuite

# ── Private Variables ─────────────────────────────────────
var _bar: BatteryBar = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_bar = BatteryBar.new()
	# Bypass _ready() signal connections by not adding to tree;
	# set internal state directly for isolated color logic tests.
	_bar._charge_percent = 1.0
	_bar._is_depleted = false
	_bar._pulse_timer = 0.0


func after_each() -> void:
	_bar.free()
	_bar = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	add_test("warning_threshold_constant_is_0_50", _test_warning_threshold_constant_is_0_50)
	add_test("critical_threshold_constant_is_0_25", _test_critical_threshold_constant_is_0_25)
	add_test("color_warning_is_amber", _test_color_warning_is_amber)
	add_test("full_charge_returns_green", _test_full_charge_returns_green)
	add_test("above_warning_threshold_returns_teal", _test_above_warning_threshold_returns_teal)
	add_test("at_warning_threshold_returns_amber", _test_at_warning_threshold_returns_amber)
	add_test("below_warning_threshold_returns_amber", _test_below_warning_threshold_returns_amber)
	add_test("at_critical_threshold_returns_critical_color", _test_at_critical_threshold_returns_critical_color)
	add_test("depleted_returns_critical_color", _test_depleted_returns_critical_color)
	add_test("zero_charge_returns_critical_color", _test_zero_charge_returns_critical_color)
	add_test("just_above_warning_returns_teal", _test_just_above_warning_returns_teal)
	add_test("just_above_critical_returns_amber", _test_just_above_critical_returns_amber)


# ── Test Methods ──────────────────────────────────────────

func _test_warning_threshold_constant_is_0_50() -> void:
	assert_equal(BatteryBar.WARNING_THRESHOLD, 0.50,
		"WARNING_THRESHOLD should be 0.50")


func _test_critical_threshold_constant_is_0_25() -> void:
	assert_equal(BatteryBar.CRITICAL_THRESHOLD, 0.25,
		"CRITICAL_THRESHOLD should be 0.25")


func _test_color_warning_is_amber() -> void:
	var expected_amber: Color = Color("#FFB830")
	assert_equal(BatteryBar.COLOR_WARNING, expected_amber,
		"COLOR_WARNING should be amber #FFB830")


func _test_full_charge_returns_green() -> void:
	_bar._charge_percent = 1.0
	var color: Color = _bar._get_state_color()
	assert_equal(color, BatteryBar.COLOR_FULL,
		"Full charge should return green COLOR_FULL")


func _test_above_warning_threshold_returns_teal() -> void:
	_bar._charge_percent = 0.75
	var color: Color = _bar._get_state_color()
	assert_equal(color, BatteryBar.COLOR_NORMAL,
		"Charge above WARNING_THRESHOLD (75%) should return teal COLOR_NORMAL")


func _test_at_warning_threshold_returns_amber() -> void:
	_bar._charge_percent = 0.50
	var color: Color = _bar._get_state_color()
	assert_equal(color, BatteryBar.COLOR_WARNING,
		"Charge at WARNING_THRESHOLD (50%) should return amber COLOR_WARNING")


func _test_below_warning_threshold_returns_amber() -> void:
	_bar._charge_percent = 0.40
	var color: Color = _bar._get_state_color()
	assert_equal(color, BatteryBar.COLOR_WARNING,
		"Charge below WARNING_THRESHOLD (40%) but above CRITICAL should return amber COLOR_WARNING")


func _test_at_critical_threshold_returns_critical_color() -> void:
	_bar._charge_percent = 0.25
	var color: Color = _bar._get_state_color()
	# Critical state pulses — check only that the base RGB matches coral
	assert_equal(color.r, BatteryBar.COLOR_CRITICAL.r,
		"Critical charge R channel should match COLOR_CRITICAL")
	assert_equal(color.g, BatteryBar.COLOR_CRITICAL.g,
		"Critical charge G channel should match COLOR_CRITICAL")
	assert_equal(color.b, BatteryBar.COLOR_CRITICAL.b,
		"Critical charge B channel should match COLOR_CRITICAL")


func _test_depleted_returns_critical_color() -> void:
	_bar._charge_percent = 0.5
	_bar._is_depleted = true
	var color: Color = _bar._get_state_color()
	assert_equal(color, BatteryBar.COLOR_CRITICAL,
		"Depleted battery should return coral COLOR_CRITICAL regardless of charge percent")


func _test_zero_charge_returns_critical_color() -> void:
	_bar._charge_percent = 0.0
	var color: Color = _bar._get_state_color()
	assert_equal(color, BatteryBar.COLOR_CRITICAL,
		"Zero charge should return coral COLOR_CRITICAL")


func _test_just_above_warning_returns_teal() -> void:
	_bar._charge_percent = 0.51
	var color: Color = _bar._get_state_color()
	assert_equal(color, BatteryBar.COLOR_NORMAL,
		"Charge just above WARNING_THRESHOLD (51%) should return teal COLOR_NORMAL")


func _test_just_above_critical_returns_amber() -> void:
	_bar._charge_percent = 0.26
	var color: Color = _bar._get_state_color()
	assert_equal(color, BatteryBar.COLOR_WARNING,
		"Charge just above CRITICAL_THRESHOLD (26%) should return amber COLOR_WARNING")
