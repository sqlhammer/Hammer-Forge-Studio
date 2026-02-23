## Unit tests for the Inventory system. Verifies slot management, stacking, add/remove
## operations, capacity limits, signal emissions, and query methods.
class_name TestInventoryUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _inventory: Inventory = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_inventory = Inventory.new()
	add_child(_inventory)
	_spy = SignalSpy.new()
	_spy.watch(_inventory, "slot_changed")
	_spy.watch(_inventory, "item_added")
	_spy.watch(_inventory, "item_removed")
	_spy.watch(_inventory, "inventory_full")


func after_each() -> void:
	_spy.clear()
	_spy = null
	_inventory.queue_free()
	_inventory = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	add_test("initial_state_all_slots_empty", _test_initial_state_all_slots_empty)
	add_test("initial_free_slot_count_is_max", _test_initial_free_slot_count_is_max)
	add_test("add_single_item_to_empty_inventory", _test_add_single_item_to_empty_inventory)
	add_test("add_item_stacks_with_matching_slot", _test_add_item_stacks_with_matching_slot)
	add_test("add_item_uses_new_slot_for_different_purity", _test_add_item_uses_new_slot_for_different_purity)
	add_test("add_item_overflow_splits_across_slots", _test_add_item_overflow_splits_across_slots)
	add_test("add_none_type_returns_quantity", _test_add_none_type_returns_quantity)
	add_test("add_zero_quantity_returns_zero", _test_add_zero_quantity_returns_zero)
	add_test("add_negative_quantity_returns_quantity", _test_add_negative_quantity_returns_quantity)
	add_test("add_item_emits_slot_changed", _test_add_item_emits_slot_changed)
	add_test("add_item_emits_item_added", _test_add_item_emits_item_added)
	add_test("add_to_full_inventory_emits_inventory_full", _test_add_to_full_inventory_emits_inventory_full)
	add_test("add_to_full_inventory_returns_remainder", _test_add_to_full_inventory_returns_remainder)
	add_test("remove_item_reduces_quantity", _test_remove_item_reduces_quantity)
	add_test("remove_item_clears_slot_at_zero", _test_remove_item_clears_slot_at_zero)
	add_test("remove_more_than_available_returns_partial", _test_remove_more_than_available_returns_partial)
	add_test("remove_from_empty_inventory_returns_zero", _test_remove_from_empty_inventory_returns_zero)
	add_test("remove_item_emits_item_removed", _test_remove_item_emits_item_removed)
	add_test("remove_from_slot_works_correctly", _test_remove_from_slot_works_correctly)
	add_test("remove_from_invalid_slot_returns_zero", _test_remove_from_invalid_slot_returns_zero)
	add_test("get_total_count_across_slots", _test_get_total_count_across_slots)
	add_test("get_count_filters_by_purity", _test_get_count_filters_by_purity)
	add_test("has_item_returns_true_when_present", _test_has_item_returns_true_when_present)
	add_test("has_item_returns_false_when_absent", _test_has_item_returns_false_when_absent)
	add_test("get_available_space_with_empty_inventory", _test_get_available_space_with_empty_inventory)
	add_test("get_available_space_with_partial_stacks", _test_get_available_space_with_partial_stacks)
	add_test("clear_all_empties_inventory", _test_clear_all_empties_inventory)
	add_test("get_contents_returns_non_empty_slots", _test_get_contents_returns_non_empty_slots)
	add_test("is_full_when_all_slots_occupied", _test_is_full_when_all_slots_occupied)
	add_test("max_stack_size_is_100", _test_max_stack_size_is_100)
	add_test("max_slots_is_15", _test_max_slots_is_15)
	add_test("get_slot_returns_duplicate", _test_get_slot_returns_duplicate)
	add_test("get_slot_out_of_bounds_returns_empty", _test_get_slot_out_of_bounds_returns_empty)
	add_test("is_slot_empty_out_of_bounds_returns_false", _test_is_slot_empty_out_of_bounds_returns_false)


# ── Test Methods ──────────────────────────────────────────

func _test_initial_state_all_slots_empty() -> void:
	for i: int in range(Inventory.MAX_SLOTS):
		assert_true(_inventory.is_slot_empty(i),
			"Slot %d should be empty on init" % i)


func _test_initial_free_slot_count_is_max() -> void:
	assert_equal(_inventory.get_free_slot_count(), 15,
		"All 15 slots should be free initially")
	assert_equal(_inventory.get_used_slot_count(), 0,
		"No slots should be used initially")


func _test_add_single_item_to_empty_inventory() -> void:
	var remainder: int = _inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	assert_equal(remainder, 0, "All 10 items should be added")
	assert_equal(_inventory.get_used_slot_count(), 1, "One slot should be used")
	var slot: Dictionary = _inventory.get_slot(0)
	assert_equal(slot.get("resource_type"), ResourceDefs.ResourceType.SCRAP_METAL,
		"Slot resource type should be SCRAP_METAL")
	assert_equal(slot.get("purity"), ResourceDefs.Purity.THREE_STAR,
		"Slot purity should be THREE_STAR")
	assert_equal(slot.get("quantity"), 10, "Slot quantity should be 10")


func _test_add_item_stacks_with_matching_slot() -> void:
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 30)
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 20)
	assert_equal(_inventory.get_used_slot_count(), 1,
		"Items should stack into one slot")
	var slot: Dictionary = _inventory.get_slot(0)
	assert_equal(slot.get("quantity"), 50, "Stacked quantity should be 50")


func _test_add_item_uses_new_slot_for_different_purity() -> void:
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 10)
	assert_equal(_inventory.get_used_slot_count(), 2,
		"Different purities should use separate slots")


func _test_add_item_overflow_splits_across_slots() -> void:
	# Add 80, then 40 — should fill first slot to 100 and put 20 in second
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 80)
	var remainder: int = _inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 40)
	assert_equal(remainder, 0, "All items should fit")
	assert_equal(_inventory.get_used_slot_count(), 2, "Should use two slots")
	var slot_0: Dictionary = _inventory.get_slot(0)
	var slot_1: Dictionary = _inventory.get_slot(1)
	assert_equal(slot_0.get("quantity"), 100, "First slot should be full at 100")
	assert_equal(slot_1.get("quantity"), 20, "Second slot should have overflow 20")


func _test_add_none_type_returns_quantity() -> void:
	var remainder: int = _inventory.add_item(
		ResourceDefs.ResourceType.NONE, ResourceDefs.Purity.THREE_STAR, 10)
	assert_equal(remainder, 10, "NONE type should not be added")
	assert_equal(_inventory.get_used_slot_count(), 0, "No slots should be used")


func _test_add_zero_quantity_returns_zero() -> void:
	var remainder: int = _inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 0)
	assert_equal(remainder, 0, "Zero quantity should return 0")


func _test_add_negative_quantity_returns_quantity() -> void:
	var remainder: int = _inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, -5)
	assert_equal(remainder, -5, "Negative quantity should be returned unchanged")


func _test_add_item_emits_slot_changed() -> void:
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	assert_signal_emitted(_spy, "slot_changed", "slot_changed should be emitted on add")


func _test_add_item_emits_item_added() -> void:
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	assert_signal_emitted(_spy, "item_added", "item_added should be emitted")
	var args: Array = _spy.get_emission_args("item_added", 0)
	assert_equal(args[0], ResourceDefs.ResourceType.SCRAP_METAL,
		"item_added should report SCRAP_METAL")
	assert_equal(args[1], ResourceDefs.Purity.THREE_STAR,
		"item_added should report THREE_STAR")
	assert_equal(args[2], 10, "item_added should report quantity 10")


func _test_add_to_full_inventory_emits_inventory_full() -> void:
	# Fill all 15 slots with max stacks (5 purities * 3 full stacks each = 15 slots)
	for i: int in range(Inventory.MAX_SLOTS):
		var purity_index: int = (i % 5) + 1
		_inventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL,
			purity_index as ResourceDefs.Purity, Inventory.DEFAULT_STACK_SIZE)
	_spy.clear()
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 10)
	assert_signal_emitted(_spy, "inventory_full",
		"inventory_full should be emitted when no space")


func _test_add_to_full_inventory_returns_remainder() -> void:
	# Fill all 15 slots — use 5 purities cycling through slots
	for i: int in range(Inventory.MAX_SLOTS):
		var purity_index: int = (i % 5) + 1
		_inventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL,
			purity_index as ResourceDefs.Purity, Inventory.DEFAULT_STACK_SIZE)
	var remainder: int = _inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 50)
	assert_equal(remainder, 50, "Full inventory should return all items as remainder")


func _test_remove_item_reduces_quantity() -> void:
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 50)
	var removed: int = _inventory.remove_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 20)
	assert_equal(removed, 20, "Should remove 20 items")
	var slot: Dictionary = _inventory.get_slot(0)
	assert_equal(slot.get("quantity"), 30, "Remaining quantity should be 30")


func _test_remove_item_clears_slot_at_zero() -> void:
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	_inventory.remove_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	assert_true(_inventory.is_slot_empty(0), "Slot should be empty after removing all items")
	assert_equal(_inventory.get_used_slot_count(), 0, "No slots should be used")


func _test_remove_more_than_available_returns_partial() -> void:
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	var removed: int = _inventory.remove_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 50)
	assert_equal(removed, 10, "Should only remove what is available")


func _test_remove_from_empty_inventory_returns_zero() -> void:
	var removed: int = _inventory.remove_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	assert_equal(removed, 0, "Removing from empty inventory should return 0")


func _test_remove_item_emits_item_removed() -> void:
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 30)
	_spy.clear()
	_inventory.remove_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	assert_signal_emitted(_spy, "item_removed", "item_removed should be emitted")
	var args: Array = _spy.get_emission_args("item_removed", 0)
	assert_equal(args[2], 10, "item_removed should report quantity 10")


func _test_remove_from_slot_works_correctly() -> void:
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 50)
	var removed: int = _inventory.remove_from_slot(0, 15)
	assert_equal(removed, 15, "Should remove 15 from slot 0")
	var slot: Dictionary = _inventory.get_slot(0)
	assert_equal(slot.get("quantity"), 35, "Remaining in slot should be 35")


func _test_remove_from_invalid_slot_returns_zero() -> void:
	var removed_negative: int = _inventory.remove_from_slot(-1, 10)
	assert_equal(removed_negative, 0, "Negative slot index should return 0")
	var removed_overflow: int = _inventory.remove_from_slot(99, 10)
	assert_equal(removed_overflow, 0, "Out-of-bounds slot index should return 0")


func _test_get_total_count_across_slots() -> void:
	# Add same resource type with different purities
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 20)
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 30)
	var total: int = _inventory.get_total_count(ResourceDefs.ResourceType.SCRAP_METAL)
	assert_equal(total, 50, "Total count should sum across purities")


func _test_get_count_filters_by_purity() -> void:
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 20)
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 30)
	var count: int = _inventory.get_count(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR)
	assert_equal(count, 30, "get_count should filter by purity")


func _test_has_item_returns_true_when_present() -> void:
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	assert_true(_inventory.has_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 5),
		"has_item should return true when enough items exist")


func _test_has_item_returns_false_when_absent() -> void:
	assert_false(_inventory.has_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 1),
		"has_item should return false when item is absent")


func _test_get_available_space_with_empty_inventory() -> void:
	var space: int = _inventory.get_available_space(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR)
	var expected: int = Inventory.MAX_SLOTS * Inventory.DEFAULT_STACK_SIZE
	assert_equal(space, expected,
		"Empty inventory should have 15*100 = 1500 available space")


func _test_get_available_space_with_partial_stacks() -> void:
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 60)
	var space: int = _inventory.get_available_space(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR)
	# 40 remaining in slot 0, plus 14 empty slots * 100 = 1440
	assert_equal(space, 1440, "Should account for partial stack space")


func _test_clear_all_empties_inventory() -> void:
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 50)
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 20)
	_inventory.clear_all()
	assert_equal(_inventory.get_used_slot_count(), 0,
		"All slots should be empty after clear_all")


func _test_get_contents_returns_non_empty_slots() -> void:
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 20)
	var contents: Array[Dictionary] = _inventory.get_contents()
	assert_equal(contents.size(), 2, "Contents should have 2 entries")
	assert_true(contents[0].has("slot_index"), "Entry should include slot_index")


func _test_is_full_when_all_slots_occupied() -> void:
	# Fill all 15 slots (5 purities * 3 full stacks each = 15 slots)
	for i: int in range(Inventory.MAX_SLOTS):
		var purity_index: int = (i % 5) + 1
		_inventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL,
			purity_index as ResourceDefs.Purity, Inventory.DEFAULT_STACK_SIZE)
	assert_true(_inventory.is_full(), "Inventory should be full when all slots occupied")


func _test_max_stack_size_is_100() -> void:
	assert_equal(Inventory.DEFAULT_STACK_SIZE, 100,
		"MAX_STACK_SIZE should be 100 per design spec")


func _test_max_slots_is_15() -> void:
	assert_equal(Inventory.MAX_SLOTS, 15,
		"MAX_SLOTS should be 15 per design spec")


func _test_get_slot_returns_duplicate() -> void:
	_inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	var slot: Dictionary = _inventory.get_slot(0)
	slot["quantity"] = 999
	# Original should be unchanged
	var original: Dictionary = _inventory.get_slot(0)
	assert_equal(original.get("quantity"), 10,
		"get_slot should return a duplicate that doesn't affect internal state")


func _test_get_slot_out_of_bounds_returns_empty() -> void:
	var slot: Dictionary = _inventory.get_slot(-1)
	assert_true(slot.is_empty(), "Negative index should return empty dict")
	var slot_high: Dictionary = _inventory.get_slot(99)
	assert_true(slot_high.is_empty(), "Out-of-bounds index should return empty dict")


func _test_is_slot_empty_out_of_bounds_returns_false() -> void:
	assert_false(_inventory.is_slot_empty(-1),
		"is_slot_empty with negative index should return false")
	assert_false(_inventory.is_slot_empty(99),
		"is_slot_empty with out-of-bounds index should return false")
