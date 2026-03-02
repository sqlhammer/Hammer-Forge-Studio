# InventoryActionPopup - Context popup for gamepad inventory item actions (drop, destroy, cancel) - Owner: gameplay-programmer
## Self-contained action popup that presents Drop Item, Destroy (hold-to-confirm), and Cancel
## rows over a focused inventory slot. Manages its own focus, D-pad/stick navigation, and
## hold-to-confirm logic. Emits action_requested or cancelled signals without calling any
## inventory logic directly.
class_name InventoryActionPopup
extends Control

# ── Signals ──────────────────────────────────────────────
signal action_requested(action: String, slot_index: int)
signal cancelled()

# ── Constants ─────────────────────────────────────────────
const HOLD_DURATION: float = 0.8
const STICK_DEAD_ZONE: float = 0.5
const ROW_COUNT: int = 3

const POPUP_WIDTH: float = 260.0
const ROW_HEIGHT: float = 40.0
const TITLE_HEIGHT: float = 36.0
const PADDING: float = 12.0

## Row indices
const ROW_DROP: int = 0
const ROW_DESTROY: int = 1
const ROW_CANCEL: int = 2

## Style colors matching UI style guide
const COLOR_SURFACE := Color("#0A0F18", 0.95)
const COLOR_BORDER := Color("#007A63")
const COLOR_TEAL := Color("#00D4AA")
const COLOR_CORAL := Color("#FF6B5A")
const COLOR_TEXT_PRIMARY := Color("#F1F5F9")
const COLOR_TEXT_SECONDARY := Color("#94A3B8")
const COLOR_ROW_NORMAL := Color("#1A2736", 0.8)
const COLOR_ROW_FOCUSED := Color("#007A63", 0.3)
const COLOR_DESTROY_FILL := Color("#FF6B5A", 0.4)

# ── Private Variables ─────────────────────────────────────
var _slot_index: int = -1
var _focused_row: int = ROW_DROP
var _is_open: bool = false
var _is_holding_destroy: bool = false
var _hold_progress: float = 0.0
var _font: Font = null

## Edge-triggered latch for analog stick navigation
var _stick_latched_y: bool = false

# ── Onready Variables ─────────────────────────────────────
var _panel: PanelContainer = null
var _row_panels: Array[PanelContainer] = []
var _row_labels: Array[Label] = []
var _indicator_labels: Array[Label] = []
var _destroy_fill_rect: ColorRect = null
var _title_label: Label = null

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = ThemeDB.fallback_font
	_build_ui()
	Global.debug_log("InventoryActionPopup: ready")


func _process(delta: float) -> void:
	if not _is_open:
		return

	if _is_holding_destroy:
		_hold_progress += delta
		_update_destroy_fill()
		if _hold_progress >= HOLD_DURATION:
			# Hold completed — emit destroy action and close
			_is_holding_destroy = false
			_hold_progress = 0.0
			_update_destroy_fill()
			Global.debug_log("InventoryActionPopup: destroy hold completed for slot %d" % _slot_index)
			action_requested.emit("destroy", _slot_index)
			_close()


func _input(event: InputEvent) -> void:
	if not _is_open:
		return

	# Analog stick edge-triggered navigation (Y axis only — popup is vertical)
	if event is InputEventJoypadMotion:
		_handle_stick_input(event as InputEventJoypadMotion)
		return

	# B (ui_cancel / Escape) at any time cancels
	if event.is_action_pressed("ui_cancel"):
		_cancel_and_close()
		get_viewport().set_input_as_handled()
		return

	# Y button (JOY_BUTTON_Y) also cancels — no input action exists yet for Y
	if event is InputEventJoypadButton:
		var joy_event: InputEventJoypadButton = event as InputEventJoypadButton
		if joy_event.button_index == JOY_BUTTON_Y and joy_event.pressed:
			_cancel_and_close()
			get_viewport().set_input_as_handled()
			return

	# D-pad / arrow key navigation
	if event.is_action_pressed("ui_down"):
		_move_focus(1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_up"):
		_move_focus(-1)
		get_viewport().set_input_as_handled()
		return

	# Confirm (A button / Enter) — action depends on focused row
	if event.is_action_pressed("ui_accept"):
		_on_confirm_pressed()
		get_viewport().set_input_as_handled()
		return

	# Detect release of confirm button while holding destroy
	if _is_holding_destroy and event.is_action_released("ui_accept"):
		# Released before hold completed — cancel the hold
		_is_holding_destroy = false
		_hold_progress = 0.0
		_update_destroy_fill()
		Global.debug_log("InventoryActionPopup: destroy hold cancelled (early release)")
		get_viewport().set_input_as_handled()
		return

	# Trap all other input while open so nothing leaks to inventory grid
	get_viewport().set_input_as_handled()


# ── Public Methods ────────────────────────────────────────

## Shows the popup for the given slot index and gives it focus.
func show_for_slot(index: int) -> void:
	_slot_index = index
	_focused_row = ROW_DROP
	_is_holding_destroy = false
	_hold_progress = 0.0
	_stick_latched_y = false
	_is_open = true
	visible = true
	_update_focus_visual()
	_update_destroy_fill()
	Global.debug_log("InventoryActionPopup: opened for slot %d" % index)


## Returns the currently focused row index.
func get_focused_row() -> int:
	return _focused_row


## Returns true if the popup is currently open.
func is_open() -> bool:
	return _is_open


## Returns the current hold-to-destroy progress (0.0 to HOLD_DURATION).
func get_hold_progress() -> float:
	return _hold_progress


# ── Private Methods ───────────────────────────────────────

func _build_ui() -> void:
	# Root panel
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(POPUP_WIDTH, 0.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_SURFACE
	panel_style.border_color = COLOR_BORDER
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(PADDING)
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(vbox)

	# Title
	_title_label = Label.new()
	_title_label.text = "Item Actions"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.custom_minimum_size.y = TITLE_HEIGHT
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	vbox.add_child(_title_label)

	# Separator line
	var separator := HSeparator.new()
	separator.add_theme_constant_override("separation", 4)
	vbox.add_child(separator)

	# Action rows
	var row_texts: Array[String] = ["Drop Item", "Destroy", "Cancel"]
	for i: int in range(ROW_COUNT):
		var row_container := PanelContainer.new()
		row_container.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = COLOR_ROW_NORMAL
		row_style.set_corner_radius_all(4)
		row_style.set_content_margin_all(8)
		row_container.add_theme_stylebox_override("panel", row_style)

		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_BEGIN

		# Focus indicator (arrow for focused row)
		var indicator := Label.new()
		indicator.custom_minimum_size.x = 20.0
		indicator.add_theme_font_size_override("font_size", 16)
		indicator.add_theme_color_override("font_color", COLOR_TEAL)
		hbox.add_child(indicator)
		_indicator_labels.append(indicator)

		# Row text label
		var label := Label.new()
		label.text = row_texts[i]
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(label)
		_row_labels.append(label)

		row_container.add_child(hbox)

		# Destroy row gets a fill rect for hold-to-confirm progress
		if i == ROW_DESTROY:
			var fill := ColorRect.new()
			fill.color = COLOR_DESTROY_FILL
			fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fill.set_anchors_preset(Control.PRESET_FULL_RECT)
			fill.size.x = 0.0
			row_container.add_child(fill)
			# Move fill behind the HBox so text is readable
			row_container.move_child(fill, 0)
			_destroy_fill_rect = fill

		vbox.add_child(row_container)
		_row_panels.append(row_container)


func _handle_stick_input(event: InputEventJoypadMotion) -> void:
	var axis: int = event.axis
	var value: float = event.axis_value

	# Only handle left stick Y axis for vertical navigation
	if axis != JOY_AXIS_LEFT_Y:
		get_viewport().set_input_as_handled()
		return

	if absf(value) < STICK_DEAD_ZONE:
		_stick_latched_y = false
		get_viewport().set_input_as_handled()
		return

	if _stick_latched_y:
		get_viewport().set_input_as_handled()
		return

	_stick_latched_y = true
	var direction: int = 1 if value > 0 else -1
	_move_focus(direction)
	get_viewport().set_input_as_handled()


func _move_focus(direction: int) -> void:
	var new_row: int = clampi(_focused_row + direction, 0, ROW_COUNT - 1)
	if new_row != _focused_row:
		# Moving away from destroy row cancels any in-progress hold
		if _focused_row == ROW_DESTROY and _is_holding_destroy:
			_is_holding_destroy = false
			_hold_progress = 0.0
			_update_destroy_fill()
		_focused_row = new_row
		_update_focus_visual()


func _update_focus_visual() -> void:
	for i: int in range(ROW_COUNT):
		var is_focused: bool = (i == _focused_row)
		_indicator_labels[i].text = ">" if is_focused else ""

		var style: StyleBoxFlat = _row_panels[i].get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.bg_color = COLOR_ROW_FOCUSED if is_focused else COLOR_ROW_NORMAL
			# Teal left border on focused row
			style.border_width_left = 3 if is_focused else 0
			style.border_color = COLOR_TEAL


func _update_destroy_fill() -> void:
	if _destroy_fill_rect == null:
		return
	var parent_panel: PanelContainer = _row_panels[ROW_DESTROY]
	var ratio: float = clampf(_hold_progress / HOLD_DURATION, 0.0, 1.0)
	var total_width: float = parent_panel.size.x
	_destroy_fill_rect.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_destroy_fill_rect.size.x = total_width * ratio


func _on_confirm_pressed() -> void:
	match _focused_row:
		ROW_DROP:
			Global.debug_log("InventoryActionPopup: drop requested for slot %d" % _slot_index)
			action_requested.emit("drop", _slot_index)
			_close()
		ROW_DESTROY:
			# Start hold-to-confirm — actual confirmation happens in _process
			_is_holding_destroy = true
			_hold_progress = 0.0
			Global.debug_log("InventoryActionPopup: destroy hold started for slot %d" % _slot_index)
		ROW_CANCEL:
			_cancel_and_close()


func _cancel_and_close() -> void:
	Global.debug_log("InventoryActionPopup: cancelled for slot %d" % _slot_index)
	cancelled.emit()
	_close()


func _close() -> void:
	_is_open = false
	_is_holding_destroy = false
	_hold_progress = 0.0
	_stick_latched_y = false
	visible = false
