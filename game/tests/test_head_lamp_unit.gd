## Unit tests for the HeadLamp autoload. Verifies equip/toggle/force_off lifecycle,
## battery drain while active, recipe constants, and signal emissions.
## Uses SuitBattery autoload (reset between tests). Tests a fresh HeadLamp instance.
class_name TestHeadLampUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _lamp: Node = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	SuitBattery.restore_full()
	# Reset the global HeadLamp autoload so its _save() doesnt pollute disk
	HeadLamp._is_equipped = false
	HeadLamp._active = false
	HeadLamp.set_process(false)
	# Create a fresh HeadLamp instance for isolation
	var script: Script = load("res://scripts/systems/head_lamp.gd")
	_lamp = script.new()
	add_child(_lamp)
	# Force clean state AFTER _ready/_load_save runs (override disk state)
	_lamp._is_equipped = false
	_lamp._active = false
	_lamp.set_process(false)

	_spy = SignalSpy.new()
	_spy.watch(_lamp, "head_lamp_toggled")
	_spy.watch(_lamp, "head_lamp_equipped")


func after_each() -> void:
	_spy.clear()
	_spy = null
	if is_instance_valid(_lamp):
		_lamp.queue_free()
	_lamp = null
	SuitBattery.restore_full()


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Recipe constants
	add_test("recipe_input_is_5_metal", _test_recipe_input_is_5_metal)
	add_test("recipe_duration_is_10_seconds", _test_recipe_duration_is_10_seconds)
	add_test("drain_rate_is_2_per_second", _test_drain_rate_is_2_per_second)
	# Initial state
	add_test("initial_not_equipped", _test_initial_not_equipped)
	add_test("initial_not_active", _test_initial_not_active)
	# Equip
	add_test("equip_sets_equipped_true", _test_equip_sets_equipped_true)
	add_test("equip_emits_signal", _test_equip_emits_signal)
	add_test("equip_twice_is_noop", _test_equip_twice_is_noop)
	# Toggle
	add_test("toggle_on_when_equipped", _test_toggle_on_when_equipped)
	add_test("toggle_off_after_on", _test_toggle_off_after_on)
	add_test("toggle_emits_signal_with_state", _test_toggle_emits_signal_with_state)
	add_test("toggle_ignored_when_not_equipped", _test_toggle_ignored_when_not_equipped)
	# Battery drain
	add_test("active_lamp_drains_battery", _test_active_lamp_drains_battery)
	add_test("inactive_lamp_does_not_drain", _test_inactive_lamp_does_not_drain)
	# Force off
	add_test("force_off_deactivates_lamp", _test_force_off_deactivates_lamp)
	add_test("force_off_emits_toggled_false", _test_force_off_emits_toggled_false)
	add_test("force_off_when_already_off_is_noop", _test_force_off_when_already_off_is_noop)


# ── Test Methods ──────────────────────────────────────────

# -- Recipe constants --

func _test_recipe_input_is_5_metal() -> void:
	var script: Script = load("res://scripts/systems/head_lamp.gd")
	assert_equal(script.get("RECIPE_INPUT_RESOURCE_TYPE"), ResourceDefs.ResourceType.METAL,
		"Recipe input should be METAL")
	assert_equal(script.get("RECIPE_INPUT_QUANTITY"), 5, "Recipe input quantity should be 5")


func _test_recipe_duration_is_10_seconds() -> void:
	var script: Script = load("res://scripts/systems/head_lamp.gd")
	assert_equal(script.get("RECIPE_DURATION"), 10.0, "Recipe duration should be 10.0s")


func _test_drain_rate_is_2_per_second() -> void:
	var script: Script = load("res://scripts/systems/head_lamp.gd")
	assert_equal(script.get("DRAIN_RATE_PER_SECOND"), 2.0, "Drain rate should be 2.0 per second")


# -- Initial state --

func _test_initial_not_equipped() -> void:
	assert_false(_lamp.is_equipped(), "Should not be equipped initially")


func _test_initial_not_active() -> void:
	assert_false(_lamp.is_active(), "Should not be active initially")


# -- Equip --

func _test_equip_sets_equipped_true() -> void:
	_lamp.equip()
	assert_true(_lamp.is_equipped(), "Should be equipped after equip()")


func _test_equip_emits_signal() -> void:
	_lamp.equip()
	assert_signal_emitted(_spy, "head_lamp_equipped", "head_lamp_equipped should be emitted")


func _test_equip_twice_is_noop() -> void:
	_lamp.equip()
	_spy.clear()
	_lamp.equip()
	assert_false(_spy.was_emitted("head_lamp_equipped"),
		"Second equip should not emit signal")


# -- Toggle --

func _test_toggle_on_when_equipped() -> void:
	_lamp.equip()
	_lamp.toggle()
	assert_true(_lamp.is_active(), "Should be active after toggle on")


func _test_toggle_off_after_on() -> void:
	_lamp.equip()
	_lamp.toggle()  # ON
	_lamp.toggle()  # OFF
	assert_false(_lamp.is_active(), "Should be inactive after second toggle")


func _test_toggle_emits_signal_with_state() -> void:
	_lamp.equip()
	_spy.clear()
	_lamp.toggle()
	assert_signal_emitted(_spy, "head_lamp_toggled", "head_lamp_toggled should emit")
	var args: Array = _spy.get_emission_args("head_lamp_toggled", 0)
	assert_true(args[0] as bool, "Signal should carry true when toggling on")


func _test_toggle_ignored_when_not_equipped() -> void:
	_lamp.toggle()
	assert_false(_lamp.is_active(), "Toggle should be ignored when not equipped")
	assert_false(_spy.was_emitted("head_lamp_toggled"), "No signal should emit")


# -- Battery drain --

func _test_active_lamp_drains_battery() -> void:
	_lamp.equip()
	_lamp.toggle()
	var charge_before: float = SuitBattery.get_charge()
	# Simulate 1 second — drain = 2.0 * 1.0 = 2.0
	_lamp._process(1.0)
	var charge_after: float = SuitBattery.get_charge()
	var drained: float = charge_before - charge_after
	assert_in_range(drained, 1.9, 2.1, "Should drain ~2.0 units per second")


func _test_inactive_lamp_does_not_drain() -> void:
	_lamp.equip()
	# Don't toggle — lamp is off
	var charge_before: float = SuitBattery.get_charge()
	_lamp._process(1.0)
	var charge_after: float = SuitBattery.get_charge()
	assert_equal(charge_after, charge_before, "Inactive lamp should not drain battery")


# -- Force off --

func _test_force_off_deactivates_lamp() -> void:
	_lamp.equip()
	_lamp.toggle()
	_lamp.force_off()
	assert_false(_lamp.is_active(), "force_off should deactivate the lamp")


func _test_force_off_emits_toggled_false() -> void:
	_lamp.equip()
	_lamp.toggle()
	_spy.clear()
	_lamp.force_off()
	assert_signal_emitted(_spy, "head_lamp_toggled", "force_off should emit head_lamp_toggled")
	var args: Array = _spy.get_emission_args("head_lamp_toggled", 0)
	assert_false(args[0] as bool, "Signal should carry false")


func _test_force_off_when_already_off_is_noop() -> void:
	_lamp.equip()
	# Lamp is off
	_lamp.force_off()
	assert_false(_spy.was_emitted("head_lamp_toggled"),
		"force_off when already off should not emit signal")
