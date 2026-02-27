## Unit tests for headlamp control row in the InteractionPromptHUD persistent controls panel.
## Verifies the headlamp entry appears when equipped, disappears when not, and key label
## resolves dynamically from InputMap.
class_name TestInteractionPromptHudUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _hud: InteractionPromptHUD = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	# Reset HeadLamp autoload state before each test
	HeadLamp._is_equipped = false
	HeadLamp._active = false
	HeadLamp.set_process(false)


func after_each() -> void:
	if is_instance_valid(_hud):
		_hud.queue_free()
	_hud = null
	# Restore HeadLamp autoload state
	HeadLamp._is_equipped = false
	HeadLamp._active = false
	HeadLamp.set_process(false)
	# Restore toggle_head_lamp input mapping to default (KEY_F)
	_restore_headlamp_input_mapping()


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Presence / absence
	add_test("headlamp_absent_when_not_equipped", _test_headlamp_absent_when_not_equipped)
	add_test("headlamp_present_when_equipped_at_start", _test_headlamp_present_when_equipped_at_start)
	add_test("headlamp_appears_on_equip_signal", _test_headlamp_appears_on_equip_signal)
	# Key label
	add_test("headlamp_key_label_matches_input_map", _test_headlamp_key_label_matches_input_map)
	add_test("headlamp_key_label_updates_on_remap", _test_headlamp_key_label_updates_on_remap)
	# Edge cases
	add_test("headlamp_duplicate_equip_no_duplicate_row", _test_headlamp_duplicate_equip_no_duplicate_row)
	add_test("get_action_key_label_returns_question_for_unknown", _test_get_action_key_label_returns_question_for_unknown)


# ── Test Methods ──────────────────────────────────────────

func _test_headlamp_absent_when_not_equipped() -> void:
	_instantiate_hud()
	assert_false(_hud.has_headlamp_control(),
		"Headlamp row should be absent when not equipped")


func _test_headlamp_present_when_equipped_at_start() -> void:
	HeadLamp._is_equipped = true
	_instantiate_hud()
	assert_true(_hud.has_headlamp_control(),
		"Headlamp row should be present when equipped at HUD creation")


func _test_headlamp_appears_on_equip_signal() -> void:
	_instantiate_hud()
	assert_false(_hud.has_headlamp_control(),
		"Should be absent before equip")
	# Simulate equip via the autoload signal
	HeadLamp._is_equipped = true
	HeadLamp.head_lamp_equipped.emit()
	assert_true(_hud.has_headlamp_control(),
		"Should appear after head_lamp_equipped signal")


func _test_headlamp_key_label_matches_input_map() -> void:
	HeadLamp._is_equipped = true
	_instantiate_hud()
	var expected_key: String = _get_expected_key_label("toggle_head_lamp")
	var actual_key: String = _hud.get_headlamp_key_label()
	assert_equal(actual_key, expected_key,
		"Key label should match InputMap binding for toggle_head_lamp")


func _test_headlamp_key_label_updates_on_remap() -> void:
	HeadLamp._is_equipped = true
	_instantiate_hud()
	# Remap toggle_head_lamp to KEY_H
	InputMap.action_erase_events("toggle_head_lamp")
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_H
	InputMap.action_add_event("toggle_head_lamp", event)
	# Trigger a process tick to refresh the label
	_hud._process(0.0)
	var actual_key: String = _hud.get_headlamp_key_label()
	assert_equal(actual_key, "H",
		"Key label should update to H after remap")


func _test_headlamp_duplicate_equip_no_duplicate_row() -> void:
	HeadLamp._is_equipped = true
	_instantiate_hud()
	# Emit equip signal again — should not create a second row
	HeadLamp.head_lamp_equipped.emit()
	assert_true(_hud.has_headlamp_control(),
		"Headlamp row should still be present after duplicate equip signal")


func _test_get_action_key_label_returns_question_for_unknown() -> void:
	_instantiate_hud()
	var label: String = _hud.get_action_key_label("nonexistent_action_xyz")
	assert_equal(label, "?",
		"Unknown action should return '?'")


# ── Helper Methods ────────────────────────────────────────

func _instantiate_hud() -> void:
	var scene: PackedScene = load("res://scenes/ui/interaction_prompt_hud.tscn")
	_hud = scene.instantiate() as InteractionPromptHUD
	add_child(_hud)


func _get_expected_key_label(action: String) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	for event: InputEvent in events:
		if event is InputEventKey:
			var key_event: InputEventKey = event as InputEventKey
			return OS.get_keycode_string(key_event.keycode)
	return "?"


func _restore_headlamp_input_mapping() -> void:
	if not InputMap.has_action("toggle_head_lamp"):
		return
	InputMap.action_erase_events("toggle_head_lamp")
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_F
	InputMap.action_add_event("toggle_head_lamp", event)
