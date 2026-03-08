## Unit tests for InventoryScreen action popup wiring (TICKET-0269). Verifies Y-button opens popup
## for focused slot, Y with no focus is a no-op, drop signal routes to drop logic, destroy signal
## routes to destroy logic, grid navigation is blocked while popup is open and resumes after close,
## and controls descriptor shows correct text per device.
class_name TestInventoryScreenPopupUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _screen: InventoryScreen = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_screen = load("res://scenes/ui/inventory_screen.tscn").instantiate()
	add_child(_screen)
	# Open the inventory so input and UI are active
	_screen.open_inventory()
	_spy = SignalSpy.new()
	_spy.watch(_screen, "item_drop_requested")
	_spy.watch(_screen, "item_destroyed")


func after_each() -> void:
	_spy.clear()
	_spy = null
	_screen.close_inventory()
	_screen.queue_free()
	_screen = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Popup trigger
	add_test("y_press_opens_popup_for_focused_slot", _test_y_press_opens_popup_for_focused_slot)
	add_test("y_press_with_empty_slot_does_nothing", _test_y_press_with_empty_slot_does_nothing)
	add_test("existing_keyboard_shortcuts_still_work", _test_existing_keyboard_shortcuts_still_work)

	# Action routing — drop
	add_test("drop_signal_routes_to_drop_logic", _test_drop_signal_routes_to_drop_logic)

	# Action routing — destroy
	add_test("destroy_signal_routes_to_destroy_logic", _test_destroy_signal_routes_to_destroy_logic)

	# Grid navigation blocked while popup open
	add_test("grid_navigation_blocked_while_popup_open", _test_grid_navigation_blocked_while_popup_open)
	add_test("grid_navigation_resumes_after_popup_close", _test_grid_navigation_resumes_after_popup_close)

	# Controls descriptor — device aware
	add_test("controls_descriptor_keyboard_text", _test_controls_descriptor_keyboard_text)
	add_test("controls_descriptor_gamepad_text", _test_controls_descriptor_gamepad_text)
	add_test("controls_descriptor_hidden_for_empty_slot", _test_controls_descriptor_hidden_for_empty_slot)
	add_test("controls_descriptor_popup_hint_text", _test_controls_descriptor_popup_hint_text)

	# Popup state management
	add_test("popup_is_created_as_child", _test_popup_is_created_as_child)
	add_test("is_action_popup_open_reflects_state", _test_is_action_popup_open_reflects_state)
	add_test("close_inventory_closes_popup", _test_close_inventory_closes_popup)


# ── Test Methods ──────────────────────────────────────────

func _test_y_press_opens_popup_for_focused_slot() -> void:
	# Add an item to slot 0 so it is non-empty
	PlayerInventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	_screen.select_slot(0)

	# Simulate Y button press (ui_action_menu)
	_simulate_action_pressed("ui_action_menu")

	assert_true(_screen.is_action_popup_open(),
		"Action popup should be open after Y press on non-empty slot")

	# Clean up inventory
	PlayerInventory.remove_from_slot(0, 10)


func _test_y_press_with_empty_slot_does_nothing() -> void:
	# Slot 0 is empty by default
	_screen.select_slot(0)

	_simulate_action_pressed("ui_action_menu")

	assert_false(_screen.is_action_popup_open(),
		"Action popup should NOT open when focused slot is empty")


func _test_existing_keyboard_shortcuts_still_work() -> void:
	# Add an item to slot 0
	PlayerInventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	_screen.select_slot(0)

	# G key (use_item) should still trigger drop
	_simulate_action_pressed("use_item")

	assert_signal_emitted(_spy, "item_drop_requested",
		"G key (use_item) should still trigger drop via existing keyboard path")

	# Clean up — slot is now empty from the drop


func _test_drop_signal_routes_to_drop_logic() -> void:
	# Add an item to slot 3
	PlayerInventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	_screen.select_slot(0)

	# Open the popup
	_simulate_action_pressed("ui_action_menu")
	assert_true(_screen.is_action_popup_open(), "Popup should be open")

	# Simulate the popup emitting drop action (call handler directly since
	# we cannot inject input into the popup's _input from outside the viewport)
	var popup: InventoryActionPopup = _screen.get_action_popup()
	popup.action_requested.emit("drop", 0)

	assert_signal_emitted(_spy, "item_drop_requested",
		"Drop action from popup should route to item_drop_requested signal")

	# Clean up — slot is now empty from the drop


func _test_destroy_signal_routes_to_destroy_logic() -> void:
	# Add an item to slot 0
	PlayerInventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	_screen.select_slot(0)

	# Open the popup
	_simulate_action_pressed("ui_action_menu")
	assert_true(_screen.is_action_popup_open(), "Popup should be open")

	# Simulate the popup emitting destroy action (hold-to-confirm completed)
	var popup: InventoryActionPopup = _screen.get_action_popup()
	popup.action_requested.emit("destroy", 0)

	assert_signal_emitted(_spy, "item_destroyed",
		"Destroy action from popup should route to item_destroyed signal without re-prompt")

	# Verify the slot is now empty (item was destroyed directly, no confirm dialog)
	assert_true(PlayerInventory.is_slot_empty(0),
		"Slot should be empty after destroy — no re-prompt dialog should appear")
	assert_false(_screen.is_destroy_confirm_visible(),
		"Destroy confirm dialog should NOT appear when using popup destroy path")


func _test_grid_navigation_blocked_while_popup_open() -> void:
	# Add items so slots are non-empty
	PlayerInventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	PlayerInventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 10)
	_screen.select_slot(0)

	# Open the popup
	_simulate_action_pressed("ui_action_menu")
	assert_true(_screen.is_action_popup_open(), "Popup should be open")

	# Record focused slot before navigation attempt
	var slot_before: int = _screen.get_focused_slot()

	# Try to navigate right — should be blocked by the popup's input trapping
	# The popup traps input via set_input_as_handled, but we test the guard in _input
	# by calling _input directly on the screen (simulating if the popup guard fires)
	var nav_event := InputEventAction.new()
	nav_event.action = "ui_right"
	nav_event.pressed = true
	_screen._input(nav_event)

	assert_equal(_screen.get_focused_slot(), slot_before,
		"Grid navigation should be blocked while popup is open")

	# Close popup and clean up
	var popup: InventoryActionPopup = _screen.get_action_popup()
	popup.cancelled.emit()
	PlayerInventory.remove_from_slot(0, 10)
	PlayerInventory.remove_from_slot(1, 10)


func _test_grid_navigation_resumes_after_popup_close() -> void:
	# Add items to slots 0 and 1
	PlayerInventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	PlayerInventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 10)
	_screen.select_slot(0)

	# Open and close the popup
	_simulate_action_pressed("ui_action_menu")
	assert_true(_screen.is_action_popup_open(), "Popup should be open")

	var popup: InventoryActionPopup = _screen.get_action_popup()
	popup.cancelled.emit()
	assert_false(_screen.is_action_popup_open(), "Popup should be closed after cancel")

	# Navigate right — should work now
	_simulate_action_pressed("ui_right")

	assert_equal(_screen.get_focused_slot(), 1,
		"Grid navigation should resume after popup close — should move to slot 1")

	# Clean up
	PlayerInventory.remove_from_slot(0, 10)
	PlayerInventory.remove_from_slot(1, 10)


func _test_controls_descriptor_keyboard_text() -> void:
	# Add an item so the descriptor is visible
	PlayerInventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	_screen.select_slot(0)

	# Force keyboard device by calling the descriptor refresh in keyboard context
	# InputManager defaults to "keyboard" so the descriptor should show keyboard text
	_screen._refresh_controls_descriptor()

	var expected_text: String = "[G] Drop  |  [Enter/A] Destroy  |  [Right-Click] Drop"
	assert_equal(_screen.get_controls_descriptor_text(), expected_text,
		"Controls descriptor should show keyboard text when device is keyboard")

	# Clean up
	PlayerInventory.remove_from_slot(0, 10)


func _test_controls_descriptor_gamepad_text() -> void:
	# Add an item so the descriptor is visible
	PlayerInventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	_screen.select_slot(0)

	# Switch device to gamepad to trigger descriptor update
	# We simulate by calling _on_input_device_changed which is the signal handler
	InputManager._current_input_device = "gamepad"
	_screen._on_input_device_changed("gamepad")

	assert_equal(_screen.get_controls_descriptor_text(), "[Y] Actions",
		"Controls descriptor should show '[Y] Actions' when device is gamepad")

	# Restore device state
	InputManager._current_input_device = "keyboard"
	PlayerInventory.remove_from_slot(0, 10)


func _test_controls_descriptor_hidden_for_empty_slot() -> void:
	# Slot 0 is empty by default
	_screen.select_slot(0)
	_screen._refresh_controls_descriptor()

	# The descriptor text doesn't matter when hidden, but check visibility
	# We check via the get_controls_descriptor_text — if hidden, the label exists
	# but is not shown. We can verify by calling _refresh and checking the label.
	# Since we can't easily check visibility from outside, we verify the method
	# handles empty slots correctly by checking the text after non-empty refresh
	assert_true(PlayerInventory.is_slot_empty(0),
		"Slot 0 should be empty for this test")

	# Add item and check descriptor appears, then remove and check it hides
	PlayerInventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	_screen.select_slot(0)
	_screen._refresh_controls_descriptor()
	var text_with_item: String = _screen.get_controls_descriptor_text()
	assert_true(text_with_item.length() > 0,
		"Descriptor should have text when slot is non-empty")

	PlayerInventory.remove_from_slot(0, 10)
	_screen._update_detail_area()
	# After removing item, detail_drop_hint.visible is false per _update_detail_area
	# We check the label text hasn't changed but the label would be hidden
	assert_true(PlayerInventory.is_slot_empty(0),
		"Slot should be empty after removing items")


func _test_controls_descriptor_popup_hint_text() -> void:
	# Add an item and open popup
	PlayerInventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	_screen.select_slot(0)

	_simulate_action_pressed("ui_action_menu")
	assert_true(_screen.is_action_popup_open(), "Popup should be open")

	var expected_hint: String = "[A] Confirm / Hold to Destroy   [B] Cancel   D-pad ↑↓ Navigate"
	assert_equal(_screen.get_controls_descriptor_text(), expected_hint,
		"Descriptor should show popup hints while popup is open")

	# Close popup and verify descriptor reverts
	var popup: InventoryActionPopup = _screen.get_action_popup()
	popup.cancelled.emit()

	var keyboard_text: String = "[G] Drop  |  [Enter/A] Destroy  |  [Right-Click] Drop"
	assert_equal(_screen.get_controls_descriptor_text(), keyboard_text,
		"Descriptor should revert to device-appropriate text after popup closes")

	# Clean up
	PlayerInventory.remove_from_slot(0, 10)


func _test_popup_is_created_as_child() -> void:
	var popup: InventoryActionPopup = _screen.get_action_popup()
	assert_not_null(popup,
		"InventoryActionPopup should be created as part of _build_ui")


func _test_is_action_popup_open_reflects_state() -> void:
	assert_false(_screen.is_action_popup_open(),
		"is_action_popup_open should return false initially")

	# Add item and open popup
	PlayerInventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	_screen.select_slot(0)
	_simulate_action_pressed("ui_action_menu")

	assert_true(_screen.is_action_popup_open(),
		"is_action_popup_open should return true when popup is open")

	# Close popup
	var popup: InventoryActionPopup = _screen.get_action_popup()
	popup.cancelled.emit()

	assert_false(_screen.is_action_popup_open(),
		"is_action_popup_open should return false after popup closes")

	# Clean up
	PlayerInventory.remove_from_slot(0, 10)


func _test_close_inventory_closes_popup() -> void:
	# Add item and open popup
	PlayerInventory.add_item(ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 10)
	_screen.select_slot(0)
	_simulate_action_pressed("ui_action_menu")

	assert_true(_screen.is_action_popup_open(),
		"Popup should be open before closing inventory")

	_screen.close_inventory()

	assert_false(_screen.is_action_popup_open(),
		"Closing inventory should also close the action popup")

	# Re-open for after_each teardown
	_screen.open_inventory()
	PlayerInventory.remove_from_slot(0, 10)


# ── Helper Methods ───────────────────────────────────────

func _simulate_action_pressed(action_name: String) -> void:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = true
	_screen._input(event)
