## Unit tests for the Mining system. Verifies constants, extraction data flow,
## battery cost calculations, and inventory integration edge cases.
class_name TestMiningUnit
extends TestSuite

# ── Private Variables ─────────────────────────────────────
var _deposit: Deposit = null
var _battery: SuitBatteryType = null
var _inventory: Inventory = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_deposit = Deposit.new()
	_deposit.setup(
		ResourceDefs.ResourceType.SCRAP_METAL,
		ResourceDefs.Purity.THREE_STAR,
		ResourceDefs.DensityTier.MEDIUM,
		40,
	)
	add_child(_deposit)
	_battery = SuitBatteryType.new()
	add_child(_battery)
	_inventory = Inventory.new()
	add_child(_inventory)
	_spy = SignalSpy.new()
	_spy.watch(_deposit, "quantity_changed")
	_spy.watch(_deposit, "depleted")
	_spy.watch(_inventory, "item_added")
	_spy.watch(_inventory, "inventory_full")


func after_each() -> void:
	_spy.clear()
	_spy = null
	_inventory.queue_free()
	_inventory = null
	_battery.queue_free()
	_battery = null
	_deposit.queue_free()
	_deposit = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Constants
	add_test("extraction_duration_is_3_seconds", _test_extraction_duration_is_3_seconds)
	add_test("extraction_amount_is_8", _test_extraction_amount_is_8)
	add_test("mining_max_range_is_5", _test_mining_max_range_is_5)
	add_test("mining_ray_length_is_6", _test_mining_ray_length_is_6)

	# Extraction data flow (P1 bugfix area)
	add_test("extract_returns_dictionary", _test_extract_returns_dictionary)
	add_test("extract_dict_has_resource_type", _test_extract_dict_has_resource_type)
	add_test("extract_dict_has_purity", _test_extract_dict_has_purity)
	add_test("extract_dict_has_quantity", _test_extract_dict_has_quantity)
	add_test("extract_amount_matches_requested", _test_extract_amount_matches_requested)
	add_test("extract_partial_when_remaining_less_than_amount", _test_extract_partial_when_remaining_less_than_amount)
	add_test("extract_depleted_returns_empty_dict", _test_extract_depleted_returns_empty_dict)
	add_test("extract_emits_quantity_changed", _test_extract_emits_quantity_changed)
	add_test("extract_to_zero_emits_depleted", _test_extract_to_zero_emits_depleted)

	# Extraction → inventory integration
	add_test("extract_then_add_to_inventory", _test_extract_then_add_to_inventory)
	add_test("extract_then_add_stacks_correctly", _test_extract_then_add_stacks_correctly)
	add_test("multiple_extractions_accumulate_in_inventory", _test_multiple_extractions_accumulate_in_inventory)
	add_test("extract_add_to_full_inventory_returns_leftover", _test_extract_add_to_full_inventory_returns_leftover)
	add_test("full_inventory_emits_inventory_full_signal", _test_full_inventory_emits_inventory_full_signal)

	# Battery drain during mining
	add_test("mining_cost_per_extraction_cycle", _test_mining_cost_per_extraction_cycle)
	add_test("can_mine_with_enough_charge", _test_can_mine_with_enough_charge)
	add_test("cannot_mine_when_depleted", _test_cannot_mine_when_depleted)
	add_test("battery_drain_per_second_during_mining", _test_battery_drain_per_second_during_mining)
	add_test("mining_depletes_battery_over_multiple_cycles", _test_mining_depletes_battery_over_multiple_cycles)

	# Complete mining flow simulation
	add_test("complete_mining_flow_extract_add_drain", _test_complete_mining_flow_extract_add_drain)
	add_test("mine_until_deposit_depleted", _test_mine_until_deposit_depleted)
	add_test("mine_until_battery_depleted", _test_mine_until_battery_depleted)


# ── Test Methods: Constants ──────────────────────────────

func _test_extraction_duration_is_3_seconds() -> void:
	assert_equal(Mining.EXTRACTION_DURATION, 3.0,
		"EXTRACTION_DURATION should be 3.0 seconds")


func _test_extraction_amount_is_8() -> void:
	assert_equal(Mining.EXTRACTION_AMOUNT, 8,
		"EXTRACTION_AMOUNT should be 8 units per cycle")


func _test_mining_max_range_is_5() -> void:
	assert_equal(Mining.MINING_MAX_RANGE, 5.0,
		"MINING_MAX_RANGE should be 5.0 meters")


func _test_mining_ray_length_is_6() -> void:
	assert_equal(Mining.MINING_RAY_LENGTH, 6.0,
		"MINING_RAY_LENGTH should be 6.0 meters")


# ── Test Methods: Extraction Data Flow ───────────────────

func _test_extract_returns_dictionary() -> void:
	var result: Dictionary = _deposit.extract(Mining.EXTRACTION_AMOUNT)
	assert_false(result.is_empty(),
		"extract() should return non-empty Dictionary")


func _test_extract_dict_has_resource_type() -> void:
	var result: Dictionary = _deposit.extract(Mining.EXTRACTION_AMOUNT)
	assert_true(result.has("resource_type"),
		"Extract result should contain resource_type key")
	assert_equal(result.get("resource_type"), ResourceDefs.ResourceType.SCRAP_METAL,
		"resource_type should be SCRAP_METAL")


func _test_extract_dict_has_purity() -> void:
	var result: Dictionary = _deposit.extract(Mining.EXTRACTION_AMOUNT)
	assert_true(result.has("purity"),
		"Extract result should contain purity key")
	assert_equal(result.get("purity"), ResourceDefs.Purity.THREE_STAR,
		"purity should be THREE_STAR")


func _test_extract_dict_has_quantity() -> void:
	var result: Dictionary = _deposit.extract(Mining.EXTRACTION_AMOUNT)
	assert_true(result.has("quantity"),
		"Extract result should contain quantity key")
	assert_equal(result.get("quantity"), Mining.EXTRACTION_AMOUNT,
		"quantity should equal EXTRACTION_AMOUNT")


func _test_extract_amount_matches_requested() -> void:
	var result: Dictionary = _deposit.extract(8)
	var extracted: int = result.get("quantity", 0) as int
	assert_equal(extracted, 8, "Should extract exactly 8 units")
	assert_equal(_deposit.get_remaining(), 32,
		"Remaining should be 32 after extracting 8 from 40")


func _test_extract_partial_when_remaining_less_than_amount() -> void:
	# Extract most of the deposit first
	_deposit.extract(35)
	# Only 5 remain, try to extract 8
	var result: Dictionary = _deposit.extract(Mining.EXTRACTION_AMOUNT)
	var extracted: int = result.get("quantity", 0) as int
	assert_equal(extracted, 5,
		"Should only extract 5 when 5 remain and 8 requested")
	assert_true(_deposit.is_depleted(),
		"Deposit should be depleted after extracting all remaining")


func _test_extract_depleted_returns_empty_dict() -> void:
	_deposit.extract(40)
	var result: Dictionary = _deposit.extract(Mining.EXTRACTION_AMOUNT)
	assert_true(result.is_empty(),
		"Extracting from depleted deposit should return empty dict")


func _test_extract_emits_quantity_changed() -> void:
	_deposit.extract(Mining.EXTRACTION_AMOUNT)
	assert_signal_emitted(_spy, "quantity_changed",
		"extract() should emit quantity_changed")
	var args: Array = _spy.get_emission_args("quantity_changed", 0)
	assert_equal(args[0], 32, "First arg (remaining) should be 32")
	assert_equal(args[1], 40, "Second arg (total) should be 40")


func _test_extract_to_zero_emits_depleted() -> void:
	_deposit.extract(40)
	assert_signal_emitted(_spy, "depleted",
		"Extracting all should emit depleted signal")


# ── Test Methods: Extraction → Inventory Integration ─────

func _test_extract_then_add_to_inventory() -> void:
	var result: Dictionary = _deposit.extract(Mining.EXTRACTION_AMOUNT)
	var extracted: int = result.get("quantity", 0) as int
	var leftover: int = _inventory.add_item(
		result.get("resource_type") as ResourceDefs.ResourceType,
		result.get("purity") as ResourceDefs.Purity,
		extracted,
	)
	assert_equal(leftover, 0, "All extracted items should fit in empty inventory")
	assert_equal(_inventory.get_used_slot_count(), 1,
		"Should use 1 inventory slot")
	assert_signal_emitted(_spy, "item_added",
		"Inventory should emit item_added")


func _test_extract_then_add_stacks_correctly() -> void:
	# Two extractions of the same resource+purity should stack
	var r1: Dictionary = _deposit.extract(8)
	_inventory.add_item(
		r1.get("resource_type") as ResourceDefs.ResourceType,
		r1.get("purity") as ResourceDefs.Purity,
		r1.get("quantity", 0) as int,
	)
	var r2: Dictionary = _deposit.extract(8)
	_inventory.add_item(
		r2.get("resource_type") as ResourceDefs.ResourceType,
		r2.get("purity") as ResourceDefs.Purity,
		r2.get("quantity", 0) as int,
	)
	assert_equal(_inventory.get_used_slot_count(), 1,
		"Same resource+purity should stack into 1 slot")
	assert_equal(
		_inventory.get_count(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR),
		16,
		"Total count should be 16 after two 8-unit extractions",
	)


func _test_multiple_extractions_accumulate_in_inventory() -> void:
	# Extract 5 times (8 units each = 40 total, depleting deposit)
	var total_added: int = 0
	for i: int in range(5):
		var result: Dictionary = _deposit.extract(Mining.EXTRACTION_AMOUNT)
		if result.is_empty():
			break
		var extracted: int = result.get("quantity", 0) as int
		_inventory.add_item(
			result.get("resource_type") as ResourceDefs.ResourceType,
			result.get("purity") as ResourceDefs.Purity,
			extracted,
		)
		total_added += extracted
	assert_equal(total_added, 40, "Should extract total of 40 over multiple cycles")
	assert_true(_deposit.is_depleted(), "Deposit should be depleted")
	assert_equal(
		_inventory.get_count(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR),
		40,
		"Inventory should contain all 40 extracted units",
	)


func _test_extract_add_to_full_inventory_returns_leftover() -> void:
	# Fill all 15 inventory slots with different purities
	for i: int in range(Inventory.MAX_SLOTS):
		var purity_val: int = (i % 5) + 1
		_inventory.add_item(
			ResourceDefs.ResourceType.SCRAP_METAL,
			purity_val as ResourceDefs.Purity,
			Inventory.DEFAULT_STACK_SIZE,
		)
	assert_true(_inventory.is_full(), "Inventory should be full")
	# Extract and try to add
	var result: Dictionary = _deposit.extract(Mining.EXTRACTION_AMOUNT)
	var extracted: int = result.get("quantity", 0) as int
	var leftover: int = _inventory.add_item(
		result.get("resource_type") as ResourceDefs.ResourceType,
		result.get("purity") as ResourceDefs.Purity,
		extracted,
	)
	assert_equal(leftover, extracted,
		"All items should be leftover when inventory is truly full (all stacks maxed)")


func _test_full_inventory_emits_inventory_full_signal() -> void:
	# Fill all slots to max
	for i: int in range(Inventory.MAX_SLOTS):
		var purity_val: int = (i % 5) + 1
		_inventory.add_item(
			ResourceDefs.ResourceType.SCRAP_METAL,
			purity_val as ResourceDefs.Purity,
			Inventory.DEFAULT_STACK_SIZE,
		)
	_spy.clear()
	_spy.watch(_inventory, "inventory_full")
	var result: Dictionary = _deposit.extract(8)
	_inventory.add_item(
		result.get("resource_type") as ResourceDefs.ResourceType,
		result.get("purity") as ResourceDefs.Purity,
		result.get("quantity", 0) as int,
	)
	assert_signal_emitted(_spy, "inventory_full",
		"Should emit inventory_full when adding to full inventory")


# ── Test Methods: Battery Drain During Mining ────────────

func _test_mining_cost_per_extraction_cycle() -> void:
	# Mining cost = drain_rate * EXTRACTION_AMOUNT over EXTRACTION_DURATION
	var total_cost: float = _battery.estimate_mining_cost(
		_deposit.deposit_tier, Mining.EXTRACTION_AMOUNT
	)
	# Tier 1 = 2.0 per unit * 8 units = 16.0
	assert_equal(total_cost, 16.0,
		"Mining cost for 8 units at Tier 1 should be 16.0")


func _test_can_mine_with_enough_charge() -> void:
	assert_true(_battery.can_mine(_deposit.deposit_tier),
		"Should be able to mine at full charge")


func _test_cannot_mine_when_depleted() -> void:
	_battery.drain(100.0)
	assert_false(_battery.can_mine(_deposit.deposit_tier),
		"Should not be able to mine when battery depleted")


func _test_battery_drain_per_second_during_mining() -> void:
	# Simulate what mining._update_mining does: drain proportionally over duration
	var total_cost: float = _battery.estimate_mining_cost(
		_deposit.deposit_tier, Mining.EXTRACTION_AMOUNT
	)
	var drain_per_second: float = total_cost / Mining.EXTRACTION_DURATION
	# For Tier 1 + 8 units: 16.0 / 3.0 = 5.333...
	assert_in_range(drain_per_second, 5.3, 5.4,
		"Drain per second should be ~5.33 for Tier 1 with 8 units")
	# Simulate 1 second of mining
	_battery.drain(drain_per_second * 1.0)
	assert_in_range(_battery.get_charge(), 94.6, 94.7,
		"After 1 second of mining, charge should be ~94.67")


func _test_mining_depletes_battery_over_multiple_cycles() -> void:
	var total_cost_per_cycle: float = _battery.estimate_mining_cost(
		_deposit.deposit_tier, Mining.EXTRACTION_AMOUNT
	)
	var cycles: int = 0
	while _battery.can_mine(_deposit.deposit_tier) and cycles < 20:
		_battery.drain(total_cost_per_cycle)
		cycles += 1
	# 100 / 16 = 6.25, but can_mine checks per-unit rate not full cycle cost
	assert_equal(cycles, 7,
		"Should complete 7 mining cycles before battery insufficient")
	assert_true(_battery.get_charge() < total_cost_per_cycle,
		"Remaining charge should be less than one cycle cost")


# ── Test Methods: Complete Mining Flow Simulation ────────

func _test_complete_mining_flow_extract_add_drain() -> void:
	# Simulate one complete mining cycle: extract + add to inventory + drain battery
	_deposit.ping()
	_deposit.mark_analyzed()
	assert_true(_deposit.is_analyzed(), "Deposit must be analyzed before mining")
	assert_true(_battery.can_mine(_deposit.deposit_tier), "Battery should have charge")
	assert_false(_inventory.is_full(), "Inventory should have space")

	# Extract
	var result: Dictionary = _deposit.extract(Mining.EXTRACTION_AMOUNT)
	assert_false(result.is_empty(), "Extraction should succeed")
	var extracted: int = result.get("quantity", 0) as int

	# Add to inventory
	var leftover: int = _inventory.add_item(
		result.get("resource_type") as ResourceDefs.ResourceType,
		result.get("purity") as ResourceDefs.Purity,
		extracted,
	)
	assert_equal(leftover, 0, "All items should fit in inventory")

	# Drain battery
	var cost: float = _battery.estimate_mining_cost(_deposit.deposit_tier, extracted)
	_battery.drain(cost)

	# Verify final state
	assert_equal(_deposit.get_remaining(), 32, "Deposit should have 32 remaining")
	assert_equal(
		_inventory.get_count(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR),
		8,
		"Inventory should have 8 items",
	)
	assert_equal(_battery.get_charge(), 84.0,
		"Battery should be 84.0 after draining 16.0")


func _test_mine_until_deposit_depleted() -> void:
	_deposit.ping()
	_deposit.mark_analyzed()
	var total_mined: int = 0
	var cycles: int = 0
	while not _deposit.is_depleted() and _battery.can_mine(_deposit.deposit_tier) and cycles < 20:
		var result: Dictionary = _deposit.extract(Mining.EXTRACTION_AMOUNT)
		if result.is_empty():
			break
		var extracted: int = result.get("quantity", 0) as int
		_inventory.add_item(
			result.get("resource_type") as ResourceDefs.ResourceType,
			result.get("purity") as ResourceDefs.Purity,
			extracted,
		)
		var cost: float = _battery.estimate_mining_cost(_deposit.deposit_tier, extracted)
		_battery.drain(cost)
		total_mined += extracted
		cycles += 1
	assert_equal(total_mined, 40,
		"Should mine entire deposit of 40 units")
	assert_true(_deposit.is_depleted(),
		"Deposit should be depleted")
	# 5 cycles: 8+8+8+8+8=40, cost: 5*16=80, charge: 100-80=20
	assert_equal(_battery.get_charge(), 20.0,
		"Battery should have 20.0 charge remaining after mining 40 units")


func _test_mine_until_battery_depleted() -> void:
	# Large deposit so battery runs out first
	_deposit.setup(
		ResourceDefs.ResourceType.SCRAP_METAL,
		ResourceDefs.Purity.THREE_STAR,
		ResourceDefs.DensityTier.HIGH,
		200,
	)
	_deposit.ping()
	_deposit.mark_analyzed()
	var total_mined: int = 0
	var cycles: int = 0
	while _battery.can_mine(_deposit.deposit_tier) and not _deposit.is_depleted() and cycles < 30:
		var result: Dictionary = _deposit.extract(Mining.EXTRACTION_AMOUNT)
		if result.is_empty():
			break
		var extracted: int = result.get("quantity", 0) as int
		_inventory.add_item(
			result.get("resource_type") as ResourceDefs.ResourceType,
			result.get("purity") as ResourceDefs.Purity,
			extracted,
		)
		var cost: float = _battery.estimate_mining_cost(_deposit.deposit_tier, extracted)
		_battery.drain(cost)
		total_mined += extracted
		cycles += 1
	assert_equal(cycles, 7,
		"Should complete 7 cycles before battery too low")
	assert_equal(total_mined, 56,
		"Should mine 56 units (7 cycles * 8 units)")
	assert_false(_deposit.is_depleted(),
		"Deposit should still have resources")
	assert_false(_battery.can_mine(_deposit.deposit_tier),
		"Battery should be too low to mine")
