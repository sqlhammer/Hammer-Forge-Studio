## Unit tests for the FuelSystem autoload. Verifies fuel tank data layer, consumption
## formula, low-fuel and empty signal emissions, refuel from inventory Fuel Cells,
## travel feasibility checks, and ship weight calculation.
##
## Coverage target: 80% (per docs/studio/tdd-process-m8.md)
## Ticket: TICKET-0158
class_name TestFuelSystemUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	FuelSystem.reset_to_full()
	PlayerInventory.clear_all()
	ShipState.reset()
	_spy = SignalSpy.new()
	_spy.watch(FuelSystem, "fuel_changed")
	_spy.watch(FuelSystem, "fuel_low")
	_spy.watch(FuelSystem, "fuel_empty")


func after_each() -> void:
	FuelSystem.reset_to_full()
	PlayerInventory.clear_all()
	ShipState.reset()
	_spy.clear()
	_spy = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Tank data layer (initial state, capacity, constants)
	add_test("initial_fuel_equals_max", _test_initial_fuel_equals_max)
	add_test("fuel_max_equals_defs_capacity", _test_fuel_max_equals_defs_capacity)
	add_test("defs_fuel_cell_units_is_100", _test_defs_fuel_cell_units_is_100)
	add_test("defs_low_threshold_is_25_percent", _test_defs_low_threshold_is_25_percent)
	add_test("defs_biome_distance_placeholder_is_1000", _test_defs_biome_distance_placeholder_is_1000)

	# Consumption formula (distance-based, weight-based)
	add_test("calculate_cost_formula_correctness", _test_calculate_cost_formula_correctness)
	add_test("calculate_cost_zero_distance_is_zero", _test_calculate_cost_zero_distance_is_zero)
	add_test("calculate_cost_zero_weight_is_zero", _test_calculate_cost_zero_weight_is_zero)
	add_test("calculate_cost_scales_linearly_with_distance", _test_calculate_cost_scales_linearly_with_distance)
	add_test("calculate_cost_scales_linearly_with_weight", _test_calculate_cost_scales_linearly_with_weight)

	# consume_fuel mechanics
	add_test("consume_fuel_deducts_amount", _test_consume_fuel_deducts_amount)
	add_test("consume_fuel_emits_fuel_changed", _test_consume_fuel_emits_fuel_changed)
	add_test("consume_fuel_clamps_to_zero", _test_consume_fuel_clamps_to_zero)
	add_test("consume_fuel_does_not_go_negative", _test_consume_fuel_does_not_go_negative)
	add_test("consume_zero_fuel_does_nothing", _test_consume_zero_fuel_does_nothing)
	add_test("consume_negative_fuel_does_nothing", _test_consume_negative_fuel_does_nothing)

	# Low-fuel signal (fires when crossing ≤25% threshold)
	add_test("fuel_low_emitted_when_crossing_threshold", _test_fuel_low_emitted_when_crossing_threshold)
	add_test("fuel_low_emitted_at_exactly_25_percent", _test_fuel_low_emitted_at_exactly_25_percent)
	add_test("fuel_low_not_emitted_above_threshold", _test_fuel_low_not_emitted_above_threshold)
	add_test("fuel_low_emitted_only_once_per_crossing", _test_fuel_low_emitted_only_once_per_crossing)
	add_test("fuel_low_resets_after_refuel_above_threshold", _test_fuel_low_resets_after_refuel_above_threshold)

	# Empty signal (fires when fuel reaches 0)
	add_test("fuel_empty_emitted_at_zero", _test_fuel_empty_emitted_at_zero)
	add_test("fuel_empty_not_emitted_above_zero", _test_fuel_empty_not_emitted_above_zero)
	add_test("fuel_empty_emitted_only_once_per_depletion", _test_fuel_empty_emitted_only_once_per_depletion)
	add_test("fuel_empty_resets_after_refuel", _test_fuel_empty_resets_after_refuel)

	# Refuel from inventory
	add_test("refuel_adds_correct_fuel_units", _test_refuel_adds_correct_fuel_units)
	add_test("refuel_removes_fuel_cells_from_inventory", _test_refuel_removes_fuel_cells_from_inventory)
	add_test("refuel_returns_cells_consumed", _test_refuel_returns_cells_consumed)
	add_test("refuel_does_not_exceed_tank_capacity", _test_refuel_does_not_exceed_tank_capacity)
	add_test("refuel_with_empty_inventory_returns_zero", _test_refuel_with_empty_inventory_returns_zero)
	add_test("refuel_with_zero_cells_returns_zero", _test_refuel_with_zero_cells_returns_zero)
	add_test("refuel_consumes_only_needed_cells", _test_refuel_consumes_only_needed_cells)
	add_test("refuel_emits_fuel_changed", _test_refuel_emits_fuel_changed)
	add_test("refuel_on_full_tank_does_nothing", _test_refuel_on_full_tank_does_nothing)

	# can_travel — travel block when insufficient fuel
	add_test("can_travel_true_when_enough_fuel", _test_can_travel_true_when_enough_fuel)
	add_test("can_travel_false_when_insufficient_fuel", _test_can_travel_false_when_insufficient_fuel)
	add_test("can_travel_false_when_tank_empty", _test_can_travel_false_when_tank_empty)
	add_test("can_travel_true_at_exact_fuel_cost", _test_can_travel_true_at_exact_fuel_cost)

	# Ship weight calculation
	add_test("ship_weight_no_modules_no_inventory", _test_ship_weight_no_modules_no_inventory)
	add_test("weight_per_module_constant_is_10", _test_weight_per_module_constant_is_10)
	add_test("ship_weight_base_weight_is_50", _test_ship_weight_base_weight_is_50)
	add_test("ship_weight_inventory_does_not_affect_weight", _test_ship_weight_inventory_does_not_affect_weight)
	add_test("ship_weight_module_weight_formula_constants", _test_ship_weight_module_weight_formula_constants)
	add_test("full_tank_affords_rock_warrens_with_inventory", _test_full_tank_affords_rock_warrens_with_inventory)


# ── Helpers ───────────────────────────────────────────────

## Adds fuel cells to inventory for refuel tests.
func _add_fuel_cells(quantity: int) -> void:
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.FUEL_CELL, ResourceDefs.Purity.THREE_STAR, quantity)


## Drains FuelSystem to a specific level by consuming the difference.
func _drain_to(target_level: float) -> void:
	var to_consume: float = FuelSystem.fuel_current - target_level
	if to_consume > 0.0:
		FuelSystem.consume_fuel(to_consume)


# ── Test Methods ──────────────────────────────────────────

# -- Tank data layer --

func _test_initial_fuel_equals_max() -> void:
	assert_equal(FuelSystem.fuel_current, FuelSystem.fuel_max,
		"Initial fuel_current should equal fuel_max")


func _test_fuel_max_equals_defs_capacity() -> void:
	assert_equal(FuelSystem.fuel_max, FuelSystemDefs.FUEL_TANK_CAPACITY,
		"fuel_max should equal FuelSystemDefs.FUEL_TANK_CAPACITY (1000.0)")


func _test_defs_fuel_cell_units_is_100() -> void:
	assert_equal(FuelSystemDefs.FUEL_CELL_UNITS, 100.0,
		"FUEL_CELL_UNITS should be 100.0 fuel units per Fuel Cell")


func _test_defs_low_threshold_is_25_percent() -> void:
	assert_equal(FuelSystemDefs.LOW_FUEL_THRESHOLD_PERCENT, 0.25,
		"LOW_FUEL_THRESHOLD_PERCENT should be 0.25 (25%)")


func _test_defs_biome_distance_placeholder_is_1000() -> void:
	assert_equal(FuelSystemDefs.BIOME_DISTANCE_PLACEHOLDER, 1000.0,
		"BIOME_DISTANCE_PLACEHOLDER should be 1000.0")


# -- Consumption formula --

func _test_calculate_cost_formula_correctness() -> void:
	# distance=1000, weight=50 → 1000 * 50 * 0.005 = 250.0
	var cost: float = FuelSystem.calculate_cost(1000.0, 50.0)
	assert_equal(cost, 250.0,
		"calculate_cost(1000.0, 50.0) should return 250.0")


func _test_calculate_cost_zero_distance_is_zero() -> void:
	var cost: float = FuelSystem.calculate_cost(0.0, 50.0)
	assert_equal(cost, 0.0,
		"calculate_cost with zero distance should return 0.0")


func _test_calculate_cost_zero_weight_is_zero() -> void:
	var cost: float = FuelSystem.calculate_cost(1000.0, 0.0)
	assert_equal(cost, 0.0,
		"calculate_cost with zero weight should return 0.0")


func _test_calculate_cost_scales_linearly_with_distance() -> void:
	var cost_1x: float = FuelSystem.calculate_cost(500.0, 40.0)
	var cost_2x: float = FuelSystem.calculate_cost(1000.0, 40.0)
	assert_equal(cost_2x, cost_1x * 2.0,
		"Doubling distance should double the fuel cost")


func _test_calculate_cost_scales_linearly_with_weight() -> void:
	var cost_1x: float = FuelSystem.calculate_cost(1000.0, 20.0)
	var cost_2x: float = FuelSystem.calculate_cost(1000.0, 40.0)
	assert_equal(cost_2x, cost_1x * 2.0,
		"Doubling ship weight should double the fuel cost")


# -- consume_fuel mechanics --

func _test_consume_fuel_deducts_amount() -> void:
	FuelSystem.consume_fuel(200.0)
	assert_equal(FuelSystem.fuel_current, 800.0,
		"Consuming 200 from 1000 should leave 800")


func _test_consume_fuel_emits_fuel_changed() -> void:
	FuelSystem.consume_fuel(100.0)
	assert_signal_emitted(_spy, "fuel_changed",
		"consume_fuel should emit fuel_changed")


func _test_consume_fuel_clamps_to_zero() -> void:
	FuelSystem.consume_fuel(9999.0)
	assert_equal(FuelSystem.fuel_current, 0.0,
		"Consuming more than available should clamp to 0.0")


func _test_consume_fuel_does_not_go_negative() -> void:
	FuelSystem.consume_fuel(1500.0)
	assert_true(FuelSystem.fuel_current >= 0.0,
		"fuel_current must never go negative")


func _test_consume_zero_fuel_does_nothing() -> void:
	FuelSystem.consume_fuel(0.0)
	assert_equal(FuelSystem.fuel_current, FuelSystem.fuel_max,
		"Consuming 0 fuel should leave tank unchanged")
	assert_false(_spy.was_emitted("fuel_changed"),
		"Consuming 0 fuel should not emit fuel_changed")


func _test_consume_negative_fuel_does_nothing() -> void:
	FuelSystem.consume_fuel(-50.0)
	assert_equal(FuelSystem.fuel_current, FuelSystem.fuel_max,
		"Consuming negative fuel should leave tank unchanged")


# -- Low-fuel signal --

func _test_fuel_low_emitted_when_crossing_threshold() -> void:
	# Drain to just below 25% (249.0 < 250.0 = 25% of 1000)
	_drain_to(249.0)
	assert_signal_emitted(_spy, "fuel_low",
		"fuel_low should fire when fuel drops below 25% of max")


func _test_fuel_low_emitted_at_exactly_25_percent() -> void:
	# Drain to exactly 250.0 (25% of 1000) — threshold is ≤ so this should fire
	_drain_to(250.0)
	assert_signal_emitted(_spy, "fuel_low",
		"fuel_low should fire when fuel is exactly at 25% threshold")


func _test_fuel_low_not_emitted_above_threshold() -> void:
	# Drain to 251.0 — just above 25%, should not fire
	_drain_to(251.0)
	assert_false(_spy.was_emitted("fuel_low"),
		"fuel_low should not fire when fuel is above 25% threshold")


func _test_fuel_low_emitted_only_once_per_crossing() -> void:
	_drain_to(200.0)
	var first_emission_count: int = _spy.get_emission_count("fuel_low")
	# Consume more — already below threshold, should not fire again
	FuelSystem.consume_fuel(50.0)
	var second_emission_count: int = _spy.get_emission_count("fuel_low")
	assert_equal(first_emission_count, 1,
		"fuel_low should fire once when crossing threshold")
	assert_equal(second_emission_count, 1,
		"fuel_low should not fire again when already below threshold")


func _test_fuel_low_resets_after_refuel_above_threshold() -> void:
	# Drain below threshold to trigger fuel_low
	_drain_to(200.0)
	assert_signal_emitted(_spy, "fuel_low", "fuel_low should fire on first crossing")
	# Refuel back above threshold (add 10 cells = 1000 units → full tank)
	_add_fuel_cells(10)
	FuelSystem.refuel(10)
	_spy.clear()
	# Drain below threshold again — fuel_low should fire again
	_drain_to(200.0)
	assert_signal_emitted(_spy, "fuel_low",
		"fuel_low should fire again after refueling above threshold and draining again")


# -- Empty signal --

func _test_fuel_empty_emitted_at_zero() -> void:
	FuelSystem.consume_fuel(FuelSystem.fuel_max)
	assert_signal_emitted(_spy, "fuel_empty",
		"fuel_empty should fire when tank reaches 0")


func _test_fuel_empty_not_emitted_above_zero() -> void:
	FuelSystem.consume_fuel(999.0)
	assert_false(_spy.was_emitted("fuel_empty"),
		"fuel_empty should not fire when fuel is above 0")


func _test_fuel_empty_emitted_only_once_per_depletion() -> void:
	FuelSystem.consume_fuel(FuelSystem.fuel_max)
	assert_equal(_spy.get_emission_count("fuel_empty"), 1,
		"fuel_empty should fire exactly once when tank first hits 0")
	# Additional consume call on already-empty tank — should not fire again
	FuelSystem.consume_fuel(100.0)
	assert_equal(_spy.get_emission_count("fuel_empty"), 1,
		"fuel_empty should not fire again when tank is already empty")


func _test_fuel_empty_resets_after_refuel() -> void:
	# Drain to empty
	FuelSystem.consume_fuel(FuelSystem.fuel_max)
	assert_signal_emitted(_spy, "fuel_empty", "fuel_empty fires on depletion")
	# Refuel
	_add_fuel_cells(5)
	FuelSystem.refuel(5)
	_spy.clear()
	# Drain to empty again — fuel_empty should fire again
	FuelSystem.consume_fuel(FuelSystem.fuel_max)
	assert_signal_emitted(_spy, "fuel_empty",
		"fuel_empty should fire again after refueling and depleting again")


# -- Refuel from inventory --

func _test_refuel_adds_correct_fuel_units() -> void:
	# Drain 300 units, refuel with 3 cells → should restore 300 units (full tank)
	FuelSystem.consume_fuel(300.0)
	_add_fuel_cells(3)
	FuelSystem.refuel(3)
	assert_equal(FuelSystem.fuel_current, FuelSystem.fuel_max,
		"Refueling 3 Fuel Cells (300 units) should restore the drained 300 fuel")


func _test_refuel_removes_fuel_cells_from_inventory() -> void:
	FuelSystem.consume_fuel(300.0)
	_add_fuel_cells(3)
	FuelSystem.refuel(3)
	assert_equal(PlayerInventory.get_total_count(ResourceDefs.ResourceType.FUEL_CELL), 0,
		"Refueling should remove the consumed Fuel Cells from inventory")


func _test_refuel_returns_cells_consumed() -> void:
	# Drain 200 units. Refuel request for 3 cells, but only 2 needed (ceili(200/100)=2).
	FuelSystem.consume_fuel(200.0)
	_add_fuel_cells(5)
	var consumed: int = FuelSystem.refuel(3)
	assert_equal(consumed, 2,
		"refuel(3) with only 200 units needed should consume 2 cells (ceili(200/100)=2)")


func _test_refuel_does_not_exceed_tank_capacity() -> void:
	# Drain only 50 units, try to refuel 10 cells — tank should stop at max
	FuelSystem.consume_fuel(50.0)
	_add_fuel_cells(10)
	FuelSystem.refuel(10)
	assert_equal(FuelSystem.fuel_current, FuelSystem.fuel_max,
		"Refueling should not exceed tank capacity")


func _test_refuel_with_empty_inventory_returns_zero() -> void:
	FuelSystem.consume_fuel(300.0)
	var consumed: int = FuelSystem.refuel(3)
	assert_equal(consumed, 0,
		"refuel with no inventory Fuel Cells should return 0")


func _test_refuel_with_zero_cells_returns_zero() -> void:
	_add_fuel_cells(5)
	var consumed: int = FuelSystem.refuel(0)
	assert_equal(consumed, 0,
		"refuel(0) should return 0 and consume nothing")


func _test_refuel_consumes_only_needed_cells() -> void:
	# Drain 150 units. Refuel with 5 cells. Only ceili(150/100)=2 cells needed.
	FuelSystem.consume_fuel(150.0)
	_add_fuel_cells(5)
	var consumed: int = FuelSystem.refuel(5)
	assert_equal(consumed, 2,
		"Should consume only the cells needed to fill the tank (ceili(150/100)=2)")
	assert_equal(PlayerInventory.get_total_count(ResourceDefs.ResourceType.FUEL_CELL), 3,
		"3 Fuel Cells should remain in inventory after using 2")


func _test_refuel_emits_fuel_changed() -> void:
	FuelSystem.consume_fuel(200.0)
	_spy.clear()
	_add_fuel_cells(2)
	FuelSystem.refuel(2)
	assert_signal_emitted(_spy, "fuel_changed",
		"refuel should emit fuel_changed when fuel level changes")


func _test_refuel_on_full_tank_does_nothing() -> void:
	_add_fuel_cells(5)
	var consumed: int = FuelSystem.refuel(5)
	assert_equal(consumed, 0,
		"refuel on a full tank should consume 0 Fuel Cells")
	assert_equal(FuelSystem.fuel_current, FuelSystem.fuel_max,
		"Tank should remain full after refuel on full tank")


# -- can_travel --

func _test_can_travel_true_when_enough_fuel() -> void:
	# Full tank (1000). Cost for distance=500, weight=40 = 500*40*0.005 = 100
	assert_true(FuelSystem.can_travel(500.0, 40.0),
		"can_travel should return true when tank has enough fuel")


func _test_can_travel_false_when_insufficient_fuel() -> void:
	# Drain to 100 units. Cost for distance=1000, weight=50 = 250 > 100.
	_drain_to(100.0)
	assert_false(FuelSystem.can_travel(1000.0, 50.0),
		"can_travel should return false when tank has insufficient fuel")


func _test_can_travel_false_when_tank_empty() -> void:
	FuelSystem.consume_fuel(FuelSystem.fuel_max)
	assert_false(FuelSystem.can_travel(100.0, 10.0),
		"can_travel should return false when tank is empty")


func _test_can_travel_true_at_exact_fuel_cost() -> void:
	# Drain to exactly the cost amount. cost = 1000*50*0.005 = 250
	_drain_to(250.0)
	assert_true(FuelSystem.can_travel(1000.0, 50.0),
		"can_travel should return true when fuel equals exactly the cost")


# -- Ship weight calculation --

func _test_ship_weight_no_modules_no_inventory() -> void:
	var weight: int = FuelSystem.calculate_ship_weight()
	assert_equal(weight, FuelSystemDefs.BASE_SHIP_WEIGHT,
		"Ship weight with no modules and empty inventory should equal BASE_SHIP_WEIGHT (50)")


func _test_weight_per_module_constant_is_10() -> void:
	assert_equal(FuelSystemDefs.WEIGHT_PER_MODULE, 10,
		"WEIGHT_PER_MODULE should be 10 weight units per installed module")


func _test_ship_weight_base_weight_is_50() -> void:
	assert_equal(FuelSystemDefs.BASE_SHIP_WEIGHT, 50,
		"BASE_SHIP_WEIGHT should be 50 weight units")


func _test_ship_weight_inventory_does_not_affect_weight() -> void:
	# Add items to inventory — weight should remain at BASE_SHIP_WEIGHT (TICKET-0247 fix)
	PlayerInventory.add_item(ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 50)
	var weight: int = FuelSystem.calculate_ship_weight()
	assert_equal(weight, FuelSystemDefs.BASE_SHIP_WEIGHT,
		"Inventory items should not affect ship weight (WEIGHT_PER_INVENTORY_ITEM=0)")


func _test_ship_weight_module_weight_formula_constants() -> void:
	# Validate formula constants are consistent with expected game balance
	# BASE_SHIP_WEIGHT (50) + 3 modules * 10 weight = 80 weight units total
	var expected_module_weight: int = 3 * FuelSystemDefs.WEIGHT_PER_MODULE
	var expected_total: int = FuelSystemDefs.BASE_SHIP_WEIGHT + expected_module_weight
	assert_equal(expected_module_weight, 30,
		"3 modules * 10 weight/module = 30 weight units")
	assert_equal(expected_total, 80,
		"Base weight (50) + 3 modules (30) should equal 80")


func _test_full_tank_affords_rock_warrens_with_inventory() -> void:
	# TICKET-0247 regression: full tank must afford Rock Warrens even with heavy inventory
	PlayerInventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 100)
	PlayerInventory.add_item(ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.THREE_STAR, 100)
	PlayerInventory.add_item(ResourceDefs.ResourceType.CRYONITE, ResourceDefs.Purity.THREE_STAR, 100)
	var ship_weight: float = FuelSystem.calculate_ship_weight()
	var cost: float = FuelSystem.calculate_cost(800.0, ship_weight)
	assert_true(FuelSystem.fuel_current >= cost,
		"Full tank (%.0f) should afford Rock Warrens (cost=%.0f, weight=%.0f) with heavy inventory" % [
			FuelSystem.fuel_current, cost, ship_weight])
