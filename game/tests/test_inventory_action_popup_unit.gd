## Unit tests for InventoryActionPopup. Verifies signal emission for drop, destroy, and cancel
## actions, hold-to-destroy cancellation on early release, B/Y close behavior, row navigation,
## and show_for_slot API behavior.
class_name TestInventoryActionPopupUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _popup: InventoryActionPopup = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	var scene: PackedScene = load("res://scenes/ui/inventory_action_popup.tscn")
	_popup = scene.instantiate() as InventoryActionPopup
	add_child(_popup)
	_spy = SignalSpy.new()
	_spy.watch(_popup, "action_requested")
	_spy.watch(_popup, "cancelled")


func after_each() -> void:
	_spy.clear()
	_spy = null
	_popup.queue_free()
	_popup = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Visibility and initialization
	add_test("hidden_by_default", _test_hidden_by_default)
	add_test("show_for_slot_makes_visible", _test_show_for_slot_makes_visible)
	add_test("show_for_slot_sets_open_state", _test_show_for_slot_sets_open_state)
	add_test("show_for_slot_defaults_focus_to_drop", _test_show_for_slot_defaults_focus_to_drop)

	# Drop action
	add_test("drop_action_emits_signal", _test_drop_action_emits_signal)
	add_test("drop_action_passes_slot_index", _test_drop_action_passes_slot_index)
	add_test("drop_action_closes_popup", _test_drop_action_closes_popup)

	# Cancel action (via row select)
	add_test("cancel_row_emits_cancelled", _test_cancel_row_emits_cancelled)
	add_test("cancel_row_closes_popup", _test_cancel_row_closes_popup)

	# B/Y cancel at any time
	add_test("b_cancel_emits_cancelled", _test_b_cancel_emits_cancelled)
	add_test("b_cancel_closes_popup", _test_b_cancel_closes_popup)

	# Destroy hold-to-confirm
	add_test("destroy_hold_starts_on_confirm", _test_destroy_hold_starts_on_confirm)
	add_test("destroy_hold_completes_after_duration", _test_destroy_hold_completes_after_duration)
	add_test("destroy_hold_cancels_on_early_release", _test_destroy_hold_cancels_on_early_release)
	add_test("destroy_hold_emits_correct_signal", _test_destroy_hold_emits_correct_signal)
	add_test("destroy_hold_resets_on_row_change", _test_destroy_hold_resets_on_row_change)

	# Navigation
	add_test("navigate_down_moves_focus", _test_navigate_down_moves_focus)
	add_test("navigate_up_moves_focus", _test_navigate_up_moves_focus)
	add_test("navigate_clamps_at_top", _test_navigate_clamps_at_top)
	add_test("navigate_clamps_at_bottom", _test_navigate_clamps_at_bottom)

	# Reopening resets state
	add_test("reopen_resets_focus_and_hold", _test_reopen_resets_focus_and_hold)

	# Gamepad input mapping regression guards (TICKET-0270 / TICKET-0271)
	add_test("ui_accept_includes_joypad_a", _test_ui_accept_includes_joypad_a)
	add_test("ui_cancel_includes_joypad_b", _test_ui_cancel_includes_joypad_b)


# ── Test Methods ──────────────────────────────────────────

func _test_hidden_by_default() -> void:
	assert_false(_popup.visible, "Popup should be hidden by default")
	assert_false(_popup.is_open(), "Popup should not be open by default")


func _test_show_for_slot_makes_visible() -> void:
	_popup.show_for_slot(3)
	assert_true(_popup.visible, "Popup should be visible after show_for_slot")


func _test_show_for_slot_sets_open_state() -> void:
	_popup.show_for_slot(5)
	assert_true(_popup.is_open(), "Popup should report open after show_for_slot")


func _test_show_for_slot_defaults_focus_to_drop() -> void:
	_popup.show_for_slot(0)
	assert_equal(_popup.get_focused_row(), InventoryActionPopup.ROW_DROP,
		"Default focus should be on Drop row")


func _test_drop_action_emits_signal() -> void:
	_popup.show_for_slot(2)
	# Focus is already on Drop (row 0) — simulate confirm
	_simulate_action_pressed("ui_accept")
	assert_signal_emitted(_spy, "action_requested",
		"action_requested should be emitted for drop")


func _test_drop_action_passes_slot_index() -> void:
	_popup.show_for_slot(7)
	_simulate_action_pressed("ui_accept")
	var args: Array = _spy.get_emission_args("action_requested", 0)
	assert_equal(args[0], "drop", "Action should be 'drop'")
	assert_equal(args[1], 7, "Slot index should be 7")


func _test_drop_action_closes_popup() -> void:
	_popup.show_for_slot(0)
	_simulate_action_pressed("ui_accept")
	assert_false(_popup.is_open(), "Popup should be closed after drop action")
	assert_false(_popup.visible, "Popup should be hidden after drop action")


func _test_cancel_row_emits_cancelled() -> void:
	_popup.show_for_slot(0)
	# Navigate to Cancel row (index 2): down twice
	_simulate_action_pressed("ui_down")
	_simulate_action_pressed("ui_down")
	assert_equal(_popup.get_focused_row(), InventoryActionPopup.ROW_CANCEL,
		"Focus should be on Cancel row")
	_simulate_action_pressed("ui_accept")
	assert_signal_emitted(_spy, "cancelled", "cancelled should be emitted from Cancel row")


func _test_cancel_row_closes_popup() -> void:
	_popup.show_for_slot(0)
	_simulate_action_pressed("ui_down")
	_simulate_action_pressed("ui_down")
	_simulate_action_pressed("ui_accept")
	assert_false(_popup.is_open(), "Popup should be closed after cancel row confirm")


func _test_b_cancel_emits_cancelled() -> void:
	_popup.show_for_slot(0)
	_simulate_action_pressed("ui_cancel")
	assert_signal_emitted(_spy, "cancelled",
		"cancelled should be emitted when B/Escape pressed")


func _test_b_cancel_closes_popup() -> void:
	_popup.show_for_slot(0)
	_simulate_action_pressed("ui_cancel")
	assert_false(_popup.is_open(), "Popup should be closed after B/Escape cancel")
	assert_false(_popup.visible, "Popup should be hidden after B/Escape cancel")


func _test_destroy_hold_starts_on_confirm() -> void:
	_popup.show_for_slot(0)
	# Navigate to Destroy row
	_simulate_action_pressed("ui_down")
	assert_equal(_popup.get_focused_row(), InventoryActionPopup.ROW_DESTROY,
		"Focus should be on Destroy row")
	# Press confirm to start hold
	_simulate_action_pressed("ui_accept")
	# Destroy does not emit immediately — it starts a hold timer
	assert_false(_spy.was_emitted("action_requested"),
		"action_requested should NOT be emitted immediately on destroy confirm press")


func _test_destroy_hold_completes_after_duration() -> void:
	_popup.show_for_slot(4)
	_simulate_action_pressed("ui_down")
	_simulate_action_pressed("ui_accept")
	# Simulate enough process frames to exceed HOLD_DURATION
	_popup._process(0.5)
	assert_false(_spy.was_emitted("action_requested"),
		"Should not emit before hold duration completes")
	_popup._process(0.4)
	assert_signal_emitted(_spy, "action_requested",
		"action_requested should be emitted after full hold duration")


func _test_destroy_hold_cancels_on_early_release() -> void:
	_popup.show_for_slot(0)
	_simulate_action_pressed("ui_down")
	_simulate_action_pressed("ui_accept")
	# Partial hold
	_popup._process(0.3)
	# Release the confirm button early
	_simulate_action_released("ui_accept")
	assert_false(_spy.was_emitted("action_requested"),
		"action_requested should NOT be emitted on early release")
	assert_true(_popup.is_open(), "Popup should remain open after early release")
	# Verify hold progress was reset
	assert_equal(_popup.get_hold_progress(), 0.0,
		"Hold progress should reset to 0 after early release")


func _test_destroy_hold_emits_correct_signal() -> void:
	_popup.show_for_slot(9)
	_simulate_action_pressed("ui_down")
	_simulate_action_pressed("ui_accept")
	_popup._process(0.9)
	var args: Array = _spy.get_emission_args("action_requested", 0)
	assert_equal(args[0], "destroy", "Action should be 'destroy'")
	assert_equal(args[1], 9, "Slot index should be 9")


func _test_destroy_hold_resets_on_row_change() -> void:
	_popup.show_for_slot(0)
	_simulate_action_pressed("ui_down")
	_simulate_action_pressed("ui_accept")
	_popup._process(0.3)
	# Move away from destroy row
	_simulate_action_pressed("ui_up")
	assert_equal(_popup.get_hold_progress(), 0.0,
		"Hold progress should reset when navigating away from Destroy row")
	assert_false(_spy.was_emitted("action_requested"),
		"action_requested should not emit after navigating away during hold")


func _test_navigate_down_moves_focus() -> void:
	_popup.show_for_slot(0)
	assert_equal(_popup.get_focused_row(), InventoryActionPopup.ROW_DROP,
		"Initial focus on Drop")
	_simulate_action_pressed("ui_down")
	assert_equal(_popup.get_focused_row(), InventoryActionPopup.ROW_DESTROY,
		"Focus should move to Destroy after down")
	_simulate_action_pressed("ui_down")
	assert_equal(_popup.get_focused_row(), InventoryActionPopup.ROW_CANCEL,
		"Focus should move to Cancel after second down")


func _test_navigate_up_moves_focus() -> void:
	_popup.show_for_slot(0)
	# Go to bottom first
	_simulate_action_pressed("ui_down")
	_simulate_action_pressed("ui_down")
	assert_equal(_popup.get_focused_row(), InventoryActionPopup.ROW_CANCEL,
		"Focus should be on Cancel")
	_simulate_action_pressed("ui_up")
	assert_equal(_popup.get_focused_row(), InventoryActionPopup.ROW_DESTROY,
		"Focus should move to Destroy after up")
	_simulate_action_pressed("ui_up")
	assert_equal(_popup.get_focused_row(), InventoryActionPopup.ROW_DROP,
		"Focus should move to Drop after second up")


func _test_navigate_clamps_at_top() -> void:
	_popup.show_for_slot(0)
	_simulate_action_pressed("ui_up")
	assert_equal(_popup.get_focused_row(), InventoryActionPopup.ROW_DROP,
		"Focus should stay on Drop when pressing up at top")


func _test_navigate_clamps_at_bottom() -> void:
	_popup.show_for_slot(0)
	_simulate_action_pressed("ui_down")
	_simulate_action_pressed("ui_down")
	_simulate_action_pressed("ui_down")
	assert_equal(_popup.get_focused_row(), InventoryActionPopup.ROW_CANCEL,
		"Focus should stay on Cancel when pressing down at bottom")


func _test_reopen_resets_focus_and_hold() -> void:
	_popup.show_for_slot(0)
	# Navigate to Destroy and start hold
	_simulate_action_pressed("ui_down")
	_simulate_action_pressed("ui_accept")
	_popup._process(0.3)
	# Cancel the popup
	_simulate_action_pressed("ui_cancel")
	assert_false(_popup.is_open(), "Popup should be closed after cancel")
	# Reopen
	_popup.show_for_slot(5)
	assert_equal(_popup.get_focused_row(), InventoryActionPopup.ROW_DROP,
		"Focus should reset to Drop on reopen")
	assert_equal(_popup.get_hold_progress(), 0.0,
		"Hold progress should reset on reopen")


func _test_ui_accept_includes_joypad_a() -> void:
	var found: bool = false
	for event: InputEvent in InputMap.action_get_events("ui_accept"):
		if event is InputEventJoypadButton:
			var joy_event: InputEventJoypadButton = event as InputEventJoypadButton
			if joy_event.button_index == JOY_BUTTON_A:
				found = true
				break
	assert_true(found,
		"ui_accept must include JOY_BUTTON_A for gamepad popup confirm (TICKET-0270)")


func _test_ui_cancel_includes_joypad_b() -> void:
	var found: bool = false
	for event: InputEvent in InputMap.action_get_events("ui_cancel"):
		if event is InputEventJoypadButton:
			var joy_event: InputEventJoypadButton = event as InputEventJoypadButton
			if joy_event.button_index == JOY_BUTTON_B:
				found = true
				break
	assert_true(found,
		"ui_cancel must include JOY_BUTTON_B for gamepad popup cancel (TICKET-0271)")


# ── Helper Methods ───────────────────────────────────────

func _simulate_action_pressed(action_name: String) -> void:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = true
	_popup._input(event)


func _simulate_action_released(action_name: String) -> void:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = false
	_popup._input(event)
