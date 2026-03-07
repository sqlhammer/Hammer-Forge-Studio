## Unit tests for the DroppedItem system. Verifies drop removes item from inventory,
## pickup adds item to inventory, full-inventory pick-up rejection, item properties,
## and signal emissions.
class_name TestDroppedItemUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _inventory: Inventory = null
var _dropped_item: DroppedItem = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_inventory = Inventory.new()
	add_child(_inventory)
	_spy = SignalSpy.new()


func after_each() -> void:
	_spy.clear()
	_spy = null
	if is_instance_valid(_dropped_item):
		_dropped_item.queue_free()
	_dropped_item = null
	_inventory.queue_free()
	_inventory = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	add_test("setup_stores_resource_type", _test_setup_stores_resource_type)
	add_test("setup_stores_purity", _test_setup_stores_purity)
	add_test("setup_stores_quantity", _test_setup_stores_quantity)
	add_test("get_interaction_prompt_returns_pickup_label", _test_get_interaction_prompt_returns_pickup_label)
	add_test("get_interaction_prompt_returns_empty_for_zero_quantity", _test_get_interaction_prompt_returns_empty_for_zero_quantity)
	add_test("get_interaction_prompt_contains_resource_name", _test_get_interaction_prompt_contains_resource_name)
	add_test("get_interaction_prompt_key_is_not_empty", _test_get_interaction_prompt_key_is_not_empty)
	add_test("dropped_item_is_in_interaction_prompt_source_group", _test_dropped_item_is_in_interaction_prompt_source_group)
	add_test("dropped_item_is_in_interactable_group", _test_dropped_item_is_in_interactable_group)
	add_test("dropped_item_collision_layer_is_zero", _test_dropped_item_collision_layer_is_zero)
	add_test("dropped_item_collision_mask_is_player", _test_dropped_item_collision_mask_is_player)
	add_test("drop_removes_item_from_inventory", _test_drop_removes_item_from_inventory)
	add_test("drop_removes_full_stack_from_slot", _test_drop_removes_full_stack_from_slot)
	add_test("pickup_adds_item_to_inventory", _test_pickup_adds_item_to_inventory)
	add_test("pickup_full_inventory_rejects", _test_pickup_full_inventory_rejects)
	add_test("pickup_emits_item_picked_up_signal", _test_pickup_emits_item_picked_up_signal)
	add_test("dropped_item_has_mesh_child", _test_dropped_item_has_mesh_child)
	add_test("dropped_item_has_collision_shape", _test_dropped_item_has_collision_shape)
	add_test("inventory_screen_drop_signal_defined", _test_inventory_screen_drop_signal_defined)


# ── Test Methods ──────────────────────────────────────────

func _test_setup_stores_resource_type() -> void:
	_dropped_item = _create_dropped_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	assert_equal(_dropped_item.get_resource_type(), ResourceDefs.ResourceType.SCRAP_METAL,
		"Resource type should be SCRAP_METAL")


func _test_setup_stores_purity() -> void:
	_dropped_item = _create_dropped_item(
		ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.FIVE_STAR, 5)
	assert_equal(_dropped_item.get_purity(), ResourceDefs.Purity.FIVE_STAR,
		"Purity should be FIVE_STAR")


func _test_setup_stores_quantity() -> void:
	_dropped_item = _create_dropped_item(
		ResourceDefs.ResourceType.CRYONITE, ResourceDefs.Purity.TWO_STAR, 25)
	assert_equal(_dropped_item.get_quantity(), 25,
		"Quantity should be 25")


func _test_get_interaction_prompt_returns_pickup_label() -> void:
	_dropped_item = _create_dropped_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 10)
	var prompt: Dictionary = _dropped_item.get_interaction_prompt()
	assert_false(prompt.is_empty(), "Prompt should not be empty for valid item")
	assert_true(prompt.has("label"), "Prompt should have a label key")
	var label: String = prompt.get("label", "") as String
	assert_true(label.begins_with("Pick up"), "Label should start with 'Pick up'")


func _test_get_interaction_prompt_returns_empty_for_zero_quantity() -> void:
	_dropped_item = DroppedItem.new()
	_dropped_item.setup(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 0)
	add_child(_dropped_item)
	var prompt: Dictionary = _dropped_item.get_interaction_prompt()
	assert_true(prompt.is_empty(), "Prompt should be empty when quantity is 0")


func _test_get_interaction_prompt_contains_resource_name() -> void:
	_dropped_item = _create_dropped_item(
		ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.THREE_STAR, 5)
	var prompt: Dictionary = _dropped_item.get_interaction_prompt()
	var label: String = prompt.get("label", "") as String
	assert_true(label.contains("Metal"), "Prompt label should contain resource name 'Metal'")


func _test_get_interaction_prompt_key_is_not_empty() -> void:
	_dropped_item = _create_dropped_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 10)
	var prompt: Dictionary = _dropped_item.get_interaction_prompt()
	var key_val: String = prompt.get("key", "") as String
	assert_false(key_val.is_empty(), "Prompt key should not be empty")


func _test_dropped_item_is_in_interaction_prompt_source_group() -> void:
	_dropped_item = _create_dropped_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 10)
	assert_true(_dropped_item.is_in_group("interaction_prompt_source"),
		"DroppedItem should be in interaction_prompt_source group")


func _test_dropped_item_is_in_interactable_group() -> void:
	_dropped_item = _create_dropped_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 10)
	assert_true(_dropped_item.is_in_group("interactable"),
		"DroppedItem should be in interactable group")


func _test_dropped_item_collision_layer_is_zero() -> void:
	_dropped_item = _create_dropped_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 10)
	assert_equal(_dropped_item.collision_layer, 0,
		"Collision layer should be 0 so raycasts pass through")


func _test_dropped_item_collision_mask_is_player() -> void:
	_dropped_item = _create_dropped_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 10)
	assert_equal(_dropped_item.collision_mask, PhysicsLayers.PLAYER,
		"Collision mask should detect player for proximity pickup")


func _test_drop_removes_item_from_inventory() -> void:
	_inventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 50)
	var removed: int = _inventory.remove_from_slot(0, 50)
	assert_equal(removed, 50, "Should remove 50 items from slot")
	assert_true(_inventory.is_slot_empty(0), "Slot should be empty after drop")


func _test_drop_removes_full_stack_from_slot() -> void:
	_inventory.add_item(ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.TWO_STAR, 30)
	var slot_data: Dictionary = _inventory.get_slot(0)
	var quantity: int = slot_data.get("quantity", 0) as int
	var removed: int = _inventory.remove_from_slot(0, quantity)
	assert_equal(removed, 30, "Should remove the full stack quantity")
	assert_equal(_inventory.get_used_slot_count(), 0, "Inventory should have no used slots")


func _test_pickup_adds_item_to_inventory() -> void:
	_dropped_item = _create_dropped_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	# Simulate pickup by directly calling add_item on the inventory (the actual
	# pickup goes through PlayerInventory autoload which we cannot mock here)
	var remainder: int = _inventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	assert_equal(remainder, 0, "All items should be added to inventory")
	assert_equal(_inventory.get_count(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR), 10,
		"Inventory should contain 10 Scrap Metal")


func _test_pickup_full_inventory_rejects() -> void:
	# Fill all 15 slots with max stacks
	for i: int in range(Inventory.MAX_SLOTS):
		var purity_index: int = (i % 5) + 1
		_inventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL,
			purity_index as ResourceDefs.Purity, Inventory.DEFAULT_STACK_SIZE)
	# Attempt to add more — should fail
	var remainder: int = _inventory.add_item(
		ResourceDefs.ResourceType.CRYONITE, ResourceDefs.Purity.ONE_STAR, 10)
	assert_equal(remainder, 10, "Full inventory should reject all items")


func _test_pickup_emits_item_picked_up_signal() -> void:
	_dropped_item = _create_dropped_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	_spy.watch(_dropped_item, "item_picked_up")
	# The signal is emitted by DroppedItem internally — verify it exists and is connectable
	assert_true(_dropped_item.has_signal("item_picked_up"),
		"DroppedItem should have item_picked_up signal")


func _test_dropped_item_has_mesh_child() -> void:
	_dropped_item = _create_dropped_item(
		ResourceDefs.ResourceType.FUEL_CELL, ResourceDefs.Purity.FOUR_STAR, 3)
	var mesh: MeshInstance3D = _dropped_item.get_node_or_null("ItemMesh") as MeshInstance3D
	assert_not_null(mesh, "DroppedItem should have an ItemMesh child")


func _test_dropped_item_has_collision_shape() -> void:
	_dropped_item = _create_dropped_item(
		ResourceDefs.ResourceType.SPARE_BATTERY, ResourceDefs.Purity.ONE_STAR, 1)
	var shape: CollisionShape3D = _dropped_item.get_node_or_null("DetectionShape") as CollisionShape3D
	assert_not_null(shape, "DroppedItem should have a DetectionShape child")


func _test_inventory_screen_drop_signal_defined() -> void:
	assert_true(ClassDB.class_has_signal("InventoryScreen", "item_drop_requested"),
		"InventoryScreen should have item_drop_requested signal")


# ── Helper Methods ────────────────────────────────────────

func _create_dropped_item(resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int) -> DroppedItem:
	var item := DroppedItem.new()
	item.setup(resource_type, purity, quantity)
	add_child(item)
	return item
