## Unit tests for the Deposit system. Verifies extraction, analysis, energy cost
## calculations, signal emissions, setup, and serialization/deserialization.
class_name TestDepositUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _deposit: Deposit = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_deposit = Deposit.new()
	_deposit.resource_type = ResourceDefs.ResourceType.SCRAP_METAL
	_deposit.purity = ResourceDefs.Purity.THREE_STAR
	_deposit.density_tier = ResourceDefs.DensityTier.MEDIUM
	_deposit.deposit_tier = ResourceDefs.DepositTier.TIER_1
	_deposit.total_quantity = 40
	add_child(_deposit)
	_spy = SignalSpy.new()
	_spy.watch(_deposit, "quantity_changed")
	_spy.watch(_deposit, "depleted")


func after_each() -> void:
	_spy.clear()
	_spy = null
	_deposit.queue_free()
	_deposit = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	add_test("initial_remaining_equals_total", _test_initial_remaining_equals_total)
	add_test("initial_not_depleted", _test_initial_not_depleted)
	add_test("initial_not_analyzed", _test_initial_not_analyzed)
	add_test("extract_valid_amount", _test_extract_valid_amount)
	add_test("extract_more_than_remaining_returns_partial", _test_extract_more_than_remaining_returns_partial)
	add_test("extract_from_depleted_returns_zero", _test_extract_from_depleted_returns_zero)
	add_test("extract_zero_returns_zero", _test_extract_zero_returns_zero)
	add_test("extract_negative_returns_zero", _test_extract_negative_returns_zero)
	add_test("is_depleted_after_full_extraction", _test_is_depleted_after_full_extraction)
	add_test("extract_emits_quantity_changed", _test_extract_emits_quantity_changed)
	add_test("extract_emits_depleted_on_empty", _test_extract_emits_depleted_on_empty)
	add_test("mark_analyzed_sets_flag", _test_mark_analyzed_sets_flag)
	add_test("get_total_energy_cost_calculation", _test_get_total_energy_cost_calculation)
	add_test("get_total_energy_cost_decreases_after_extraction", _test_get_total_energy_cost_decreases_after_extraction)
	add_test("get_analysis_summary_structure", _test_get_analysis_summary_structure)
	add_test("setup_configures_all_fields", _test_setup_configures_all_fields)
	add_test("serialize_produces_complete_dict", _test_serialize_produces_complete_dict)
	add_test("deserialize_restores_state", _test_deserialize_restores_state)
	add_test("get_total_returns_original_quantity", _test_get_total_returns_original_quantity)
	add_test("multiple_extractions_track_correctly", _test_multiple_extractions_track_correctly)


# ── Test Methods ──────────────────────────────────────────

func _test_initial_remaining_equals_total() -> void:
	assert_equal(_deposit.get_remaining(), 40,
		"Initial remaining should equal total_quantity")


func _test_initial_not_depleted() -> void:
	assert_false(_deposit.is_depleted(),
		"New deposit should not be depleted")


func _test_initial_not_analyzed() -> void:
	assert_false(_deposit.is_analyzed(),
		"New deposit should not be analyzed")


func _test_extract_valid_amount() -> void:
	var result: Dictionary = _deposit.extract(10)
	var extracted: int = result.get("quantity", 0) as int
	assert_equal(extracted, 10, "Should extract requested amount")
	assert_equal(_deposit.get_remaining(), 30, "Remaining should decrease by extracted")


func _test_extract_more_than_remaining_returns_partial() -> void:
	var result: Dictionary = _deposit.extract(50)
	var extracted: int = result.get("quantity", 0) as int
	assert_equal(extracted, 40, "Should extract only what is remaining")
	assert_equal(_deposit.get_remaining(), 0, "Remaining should be 0")


func _test_extract_from_depleted_returns_zero() -> void:
	_deposit.extract(40)
	var result: Dictionary = _deposit.extract(10)
	assert_true(result.is_empty(), "Depleted deposit should return empty dict")


func _test_extract_zero_returns_zero() -> void:
	var result: Dictionary = _deposit.extract(0)
	assert_true(result.is_empty(), "Extracting 0 should return empty dict")
	assert_equal(_deposit.get_remaining(), 40, "Remaining should be unchanged")


func _test_extract_negative_returns_zero() -> void:
	var result: Dictionary = _deposit.extract(-5)
	assert_true(result.is_empty(), "Extracting negative should return empty dict")
	assert_equal(_deposit.get_remaining(), 40, "Remaining should be unchanged")


func _test_is_depleted_after_full_extraction() -> void:
	_deposit.extract(40)
	assert_true(_deposit.is_depleted(),
		"Deposit should be depleted after extracting all")


func _test_extract_emits_quantity_changed() -> void:
	_deposit.extract(10)
	assert_signal_emitted(_spy, "quantity_changed",
		"quantity_changed should be emitted on extract")
	var args: Array = _spy.get_emission_args("quantity_changed", 0)
	assert_equal(args[0], 30, "First arg should be remaining (30)")
	assert_equal(args[1], 40, "Second arg should be total (40)")


func _test_extract_emits_depleted_on_empty() -> void:
	_deposit.extract(40)
	assert_signal_emitted(_spy, "depleted",
		"depleted signal should be emitted when fully extracted")


func _test_mark_analyzed_sets_flag() -> void:
	_deposit.mark_analyzed()
	assert_true(_deposit.is_analyzed(),
		"is_analyzed should return true after mark_analyzed")


func _test_get_total_energy_cost_calculation() -> void:
	# SCRAP_METAL base_energy_per_unit = 2.0, remaining = 40
	var cost: float = _deposit.get_total_energy_cost()
	assert_equal(cost, 80.0, "Energy cost should be 2.0 * 40 = 80.0")


func _test_get_total_energy_cost_decreases_after_extraction() -> void:
	_deposit.extract(10)
	var cost: float = _deposit.get_total_energy_cost()
	assert_equal(cost, 60.0, "Energy cost should be 2.0 * 30 = 60.0 after extracting 10")


func _test_get_analysis_summary_structure() -> void:
	_deposit.mark_analyzed()
	var summary: Dictionary = _deposit.get_analysis_summary()
	assert_equal(summary.get("resource_name"), "Scrap Metal",
		"Summary should have resource name")
	assert_equal(summary.get("purity"), ResourceDefs.Purity.THREE_STAR,
		"Summary should have purity enum")
	assert_equal(summary.get("purity_name"), "3-Star",
		"Summary should have purity display name")
	assert_equal(summary.get("density_name"), "Medium",
		"Summary should have density display name")
	assert_equal(summary.get("remaining"), 40,
		"Summary should have remaining count")
	assert_equal(summary.get("total"), 40,
		"Summary should have total count")
	assert_equal(summary.get("energy_cost"), 80.0,
		"Summary should have energy cost")
	assert_false(summary.get("is_depleted") as bool,
		"Summary should report not depleted")


func _test_setup_configures_all_fields() -> void:
	var fresh_deposit: Deposit = Deposit.new()
	add_child(fresh_deposit)
	fresh_deposit.setup(
		ResourceDefs.ResourceType.SCRAP_METAL,
		ResourceDefs.Purity.FIVE_STAR,
		ResourceDefs.DensityTier.HIGH,
		75)
	assert_equal(fresh_deposit.resource_type, ResourceDefs.ResourceType.SCRAP_METAL,
		"setup should set resource_type")
	assert_equal(fresh_deposit.purity, ResourceDefs.Purity.FIVE_STAR,
		"setup should set purity")
	assert_equal(fresh_deposit.density_tier, ResourceDefs.DensityTier.HIGH,
		"setup should set density_tier")
	assert_equal(fresh_deposit.deposit_tier, ResourceDefs.DepositTier.TIER_1,
		"setup should set deposit_tier from resource catalog")
	assert_equal(fresh_deposit.get_remaining(), 75,
		"setup should set remaining quantity")
	assert_equal(fresh_deposit.get_total(), 75,
		"setup should set total quantity")
	fresh_deposit.queue_free()


func _test_serialize_produces_complete_dict() -> void:
	_deposit.mark_analyzed()
	_deposit.extract(10)
	var data: Dictionary = _deposit.serialize()
	assert_equal(data.get("resource_type"), ResourceDefs.ResourceType.SCRAP_METAL,
		"Serialized resource_type")
	assert_equal(data.get("purity"), ResourceDefs.Purity.THREE_STAR,
		"Serialized purity")
	assert_equal(data.get("total_quantity"), 40, "Serialized total_quantity")
	assert_equal(data.get("remaining_quantity"), 30, "Serialized remaining_quantity")
	assert_equal(data.get("scan_state"), Deposit.ScanState.ANALYZED, "Serialized scan_state")
	assert_true(data.has("position"), "Serialized data should include position")


func _test_deserialize_restores_state() -> void:
	var data: Dictionary = {
		"resource_type": ResourceDefs.ResourceType.SCRAP_METAL,
		"purity": ResourceDefs.Purity.FIVE_STAR,
		"density_tier": ResourceDefs.DensityTier.HIGH,
		"deposit_tier": ResourceDefs.DepositTier.TIER_1,
		"total_quantity": 80,
		"remaining_quantity": 25,
		"is_analyzed": true,
		"position": {"x": 10.0, "y": 0.0, "z": 20.0},
	}
	_deposit.deserialize(data)
	assert_equal(_deposit.purity, ResourceDefs.Purity.FIVE_STAR,
		"Deserialized purity should be FIVE_STAR")
	assert_equal(_deposit.total_quantity, 80, "Deserialized total should be 80")
	assert_equal(_deposit.get_remaining(), 25, "Deserialized remaining should be 25")
	assert_true(_deposit.is_analyzed(), "Deserialized is_analyzed should be true")


func _test_get_total_returns_original_quantity() -> void:
	_deposit.extract(20)
	assert_equal(_deposit.get_total(), 40,
		"get_total should always return original total_quantity")


func _test_multiple_extractions_track_correctly() -> void:
	_deposit.extract(10)
	_deposit.extract(15)
	_deposit.extract(5)
	assert_equal(_deposit.get_remaining(), 10,
		"Remaining after 10+15+5=30 extracted from 40 should be 10")
	assert_equal(_spy.get_emission_count("quantity_changed"), 3,
		"quantity_changed should fire for each extraction")
