## Unit tests for the SpareBattery consumable item. Verifies recipe constants,
## use mechanic (battery restore), inventory deduction, and failure modes.
## Uses PlayerInventory and SuitBattery autoloads (reset between tests).
class_name TestSpareBatteryUnit
extends TestSuite


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	PlayerInventory.clear_all()
	SuitBattery.restore_full()


func after_each() -> void:
	PlayerInventory.clear_all()
	SuitBattery.restore_full()


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Recipe constants
	add_test("recipe_input_is_10_metal", _test_recipe_input_is_10_metal)
	add_test("recipe_output_is_1_spare_battery", _test_recipe_output_is_1_spare_battery)
	add_test("recipe_duration_is_8_seconds", _test_recipe_duration_is_8_seconds)
	# Use success
	add_test("use_restores_battery_to_full", _test_use_restores_battery_to_full)
	add_test("use_consumes_one_battery", _test_use_consumes_one_battery)
	add_test("use_returns_true_on_success", _test_use_returns_true_on_success)
	# Use failure
	add_test("use_fails_with_empty_inventory", _test_use_fails_with_empty_inventory)
	add_test("use_returns_false_on_failure", _test_use_returns_false_on_failure)
	# Inventory count
	add_test("get_inventory_count_returns_correct_count", _test_get_inventory_count_returns_correct_count)
	add_test("get_inventory_count_zero_initially", _test_get_inventory_count_zero_initially)


# ── Helpers ───────────────────────────────────────────────

func _add_batteries(quantity: int) -> void:
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.SPARE_BATTERY, ResourceDefs.Purity.THREE_STAR, quantity)


# ── Test Methods ──────────────────────────────────────────

# -- Recipe constants --

func _test_recipe_input_is_10_metal() -> void:
	assert_equal(SpareBattery.RECIPE_INPUT_RESOURCE_TYPE, ResourceDefs.ResourceType.METAL,
		"Recipe input should be METAL")
	assert_equal(SpareBattery.RECIPE_INPUT_QUANTITY, 10, "Recipe input quantity should be 10")


func _test_recipe_output_is_1_spare_battery() -> void:
	assert_equal(SpareBattery.RECIPE_OUTPUT_RESOURCE_TYPE, ResourceDefs.ResourceType.SPARE_BATTERY,
		"Recipe output should be SPARE_BATTERY")
	assert_equal(SpareBattery.RECIPE_OUTPUT_QUANTITY, 1, "Recipe output quantity should be 1")


func _test_recipe_duration_is_8_seconds() -> void:
	assert_equal(SpareBattery.RECIPE_DURATION, 8.0, "Recipe duration should be 8.0s")


# -- Use success --

func _test_use_restores_battery_to_full() -> void:
	_add_batteries(1)
	SuitBattery.drain(50.0)
	SpareBattery.use()
	assert_equal(SuitBattery.get_charge(), SuitBattery.max_charge,
		"Battery should be fully restored after use")


func _test_use_consumes_one_battery() -> void:
	_add_batteries(2)
	SpareBattery.use()
	assert_equal(SpareBattery.get_inventory_count(), 1,
		"One battery should be consumed, leaving 1")


func _test_use_returns_true_on_success() -> void:
	_add_batteries(1)
	var result: bool = SpareBattery.use()
	assert_true(result, "use() should return true on success")


# -- Use failure --

func _test_use_fails_with_empty_inventory() -> void:
	SuitBattery.drain(50.0)
	var result: bool = SpareBattery.use()
	assert_false(result, "use() should fail with no batteries in inventory")
	assert_true(SuitBattery.get_charge() < SuitBattery.max_charge,
		"Battery should remain drained on failure")


func _test_use_returns_false_on_failure() -> void:
	var result: bool = SpareBattery.use()
	assert_false(result, "use() should return false when no batteries available")


# -- Inventory count --

func _test_get_inventory_count_returns_correct_count() -> void:
	_add_batteries(3)
	assert_equal(SpareBattery.get_inventory_count(), 3, "Should report 3 batteries")


func _test_get_inventory_count_zero_initially() -> void:
	assert_equal(SpareBattery.get_inventory_count(), 0, "Should report 0 batteries initially")
