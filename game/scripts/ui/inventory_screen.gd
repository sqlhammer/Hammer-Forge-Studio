## Inventory overlay: 15-slot grid with item display, gamepad navigation, item details,
## drop action, and destroy action with confirmation dialog. Owner: gameplay-programmer
class_name InventoryScreen
extends CanvasLayer

# ── Signals ──────────────────────────────────────────────
signal item_destroyed(resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int)
signal item_drop_requested(resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int)

# ── Constants ─────────────────────────────────────────────
const SLOT_SIZE: float = 80.0
const SLOT_GAP: float = 12.0
const GRID_COLUMNS: int = 5
const GRID_ROWS: int = 3
const PANEL_WIDTH: float = 580.0
const PANEL_HEIGHT: float = 480.0
const STICK_DEAD_ZONE: float = 0.5

## Sidebar width for combined centering
const SIDEBAR_WIDTH: float = 180.0
const COMBINED_WIDTH: float = PANEL_WIDTH + SIDEBAR_WIDTH

## Style colors matching UI style guide
const COLOR_SURFACE := Color("#0A0F18", 0.95)
const COLOR_BORDER := Color("#007A63")
const COLOR_SLOT_BG := Color("#1A2736", 0.6)
const COLOR_SLOT_BG_OCCUPIED := Color("#1A2736", 0.8)
const COLOR_SLOT_BORDER := Color("#1A2736")
const COLOR_TEAL := Color("#00D4AA")
const COLOR_AMBER := Color("#FFB830")
const COLOR_CORAL := Color("#FF6B5A")
const COLOR_TEXT_PRIMARY := Color("#F1F5F9")
const COLOR_TEXT_SECONDARY := Color("#94A3B8")
const COLOR_NEUTRAL := Color("#94A3B8")
const COLOR_DIM := Color("#000000", 0.5)

# ── Private Variables ─────────────────────────────────────
var _is_open: bool = false
var _focused_slot: int = 0
var _slot_panels: Array[PanelContainer] = []
var _slot_icons: Array[TextureRect] = []
var _slot_count_labels: Array[Label] = []

## Edge-triggered latch for analog stick navigation (per-axis)
var _stick_latched_x: bool = false
var _stick_latched_y: bool = false

## Destroy confirmation dialog state
var _confirm_visible: bool = false

# ── Onready Variables ─────────────────────────────────────
@onready var _dim_rect: ColorRect = %DimRect
@onready var _main_panel: PanelContainer = %MainPanel
@onready var _combined_container: HBoxContainer = %CombinedContainer
@onready var _ship_sidebar: ShipStatsSidebar = %ShipStatsSidebar
@onready var _detail_icon: TextureRect = %DetailIcon
@onready var _detail_name_label: Label = %DetailNameLabel
@onready var _detail_stars_container: HBoxContainer = %DetailStarsContainer
@onready var _detail_quantity_label: Label = %DetailQuantityLabel
@onready var _detail_drop_hint: Label = %DetailDropHint
@onready var _detail_panel: PanelContainer = %DetailPanel
@onready var _action_popup: InventoryActionPopup = %InventoryActionPopup
@onready var _confirm_overlay: Control = %ConfirmOverlay
@onready var _confirm_title_label: Label = %ConfirmTitleLabel
@onready var _confirm_message_label: Label = %ConfirmMessageLabel
@onready var _destroy_confirm_button: Button = %DestroyConfirmButton
@onready var _cancel_confirm_button: Button = %CancelConfirmButton

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_populate_slot_arrays()
	_apply_styles()
	_connect_signals()
	Global.debug_log("InventoryScreen: ready")

func _process(_delta: float) -> void:
	if _is_open:
		# Closing bypasses gameplay suppression so the toggle key always works
		if InputManager.is_action_just_pressed_unsuppressed("inventory_toggle"):
			close_inventory()
	else:
		if InputManager.is_action_just_pressed("inventory_toggle"):
			open_inventory()

func _input(event: InputEvent) -> void:
	if not _is_open:
		return

	# When the action popup is open, it traps all input via set_input_as_handled
	# so this method won't be reached — but guard defensively
	if _action_popup and _action_popup.is_open():
		return

	# Analog stick uses edge-triggered latch to prevent continuous scrolling
	if event is InputEventJoypadMotion:
		_handle_stick_input(event as InputEventJoypadMotion)
		return

	# When the destroy confirm dialog is open, handle its input exclusively
	if _confirm_visible:
		if event.is_action_pressed("ui_cancel"):
			_close_destroy_confirm()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			if _destroy_confirm_button.has_focus():
				_on_destroy_confirmed()
			elif _cancel_confirm_button.has_focus():
				_close_destroy_confirm()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_left"):
			_destroy_confirm_button.grab_focus()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_right"):
			_cancel_confirm_button.grab_focus()
			get_viewport().set_input_as_handled()
		return

	# Y button (ui_action_menu) opens the action popup for the focused slot
	if event.is_action_pressed("ui_action_menu"):
		if not PlayerInventory.is_slot_empty(_focused_slot):
			_open_action_popup()
		get_viewport().set_input_as_handled()
		return

	# Navigation (only when inventory is open and confirm dialog is closed)
	if event.is_action_pressed("ui_right"):
		_move_focus(1, 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_move_focus(-1, 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_focus(0, 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_move_focus(0, -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		close_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("use_item"):
		# G key drops the focused slot's item onto the ground
		_drop_focused_slot()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_request_destroy()
		get_viewport().set_input_as_handled()

# ── Public Methods ────────────────────────────────────────

## Toggles the inventory open/closed.
func toggle() -> void:
	if _is_open:
		close_inventory()
	else:
		open_inventory()

## Opens the inventory.
func open_inventory() -> void:
	Global.debug_log("InventoryScreen: opened")
	_is_open = true
	visible = true
	_focused_slot = 0
	_stick_latched_x = false
	_stick_latched_y = false
	_refresh_all_slots()
	_update_focus_visual()
	_update_detail_area()
	_refresh_controls_descriptor()
	InputManager.set_gameplay_inputs_enabled(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Refresh sidebar values
	if _ship_sidebar:
		_ship_sidebar.refresh()
	# Appear animation
	_dim_rect.modulate.a = 0.0
	_combined_container.modulate.a = 0.0
	_combined_container.scale = Vector2(0.95, 0.95)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_dim_rect, "modulate:a", 1.0, 0.15)
	tween.tween_property(_combined_container, "modulate:a", 1.0, 0.2)
	tween.tween_property(_combined_container, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)

## Closes the inventory.
func close_inventory() -> void:
	if _action_popup and _action_popup.is_open():
		_action_popup._close()
	if _confirm_visible:
		_close_destroy_confirm()
	Global.debug_log("InventoryScreen: closed")
	_is_open = false
	InputManager.set_gameplay_inputs_enabled(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_dim_rect, "modulate:a", 0.0, 0.15)
	tween.tween_property(_combined_container, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func() -> void: visible = false)

## Returns true if the inventory is currently open.
func is_open() -> bool:
	return _is_open

## Returns the currently focused slot index.
func get_focused_slot() -> int:
	return _focused_slot

## Selects the given slot by index, matching keyboard navigation behavior.
func select_slot(index: int) -> void:
	if index < 0 or index >= Inventory.MAX_SLOTS:
		return
	_focused_slot = index
	_update_focus_visual()
	_update_detail_area()

## Returns true if the destroy confirmation dialog is currently visible.
func is_destroy_confirm_visible() -> bool:
	return _confirm_visible

## Returns true if the gamepad action popup is currently open.
func is_action_popup_open() -> bool:
	return _action_popup != null and _action_popup.is_open()

## Returns the InventoryActionPopup instance for signal connections and testing.
func get_action_popup() -> InventoryActionPopup:
	return _action_popup

## Returns the current controls descriptor text (for testing device-aware switching).
func get_controls_descriptor_text() -> String:
	if _detail_drop_hint:
		return _detail_drop_hint.text
	return ""

# ── Private Methods ───────────────────────────────────────

func _populate_slot_arrays() -> void:
	# Build indexed arrays from the scene's unique-named slot nodes for O(1) access
	for i: int in range(Inventory.MAX_SLOTS):
		var slot_name: String = "Slot%d" % i
		var icon_name: String = "Icon%d" % i
		var count_name: String = "Count%d" % i
		var slot: PanelContainer = get_node("%" + slot_name) as PanelContainer
		var icon: TextureRect = get_node("%" + icon_name) as TextureRect
		var count_label: Label = get_node("%" + count_name) as Label
		_slot_panels.append(slot)
		_slot_icons.append(icon)
		_slot_count_labels.append(count_label)

func _apply_styles() -> void:
	# Main panel style
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_SURFACE
	panel_style.border_color = COLOR_BORDER
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_top_right = 0
	panel_style.corner_radius_bottom_right = 0
	panel_style.set_content_margin_all(24)
	_main_panel.add_theme_stylebox_override("panel", panel_style)

	# Slot styles
	for i: int in range(Inventory.MAX_SLOTS):
		var style := StyleBoxFlat.new()
		style.bg_color = COLOR_SLOT_BG
		style.border_color = COLOR_SLOT_BORDER
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(4)
		_slot_panels[i].add_theme_stylebox_override("panel", style)

	# Detail panel style
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color("#1A2736", 0.8)
	detail_style.set_corner_radius_all(4)
	detail_style.set_content_margin_all(12)
	_detail_panel.add_theme_stylebox_override("panel", detail_style)

	# Divider style
	var divider: HSeparator = _main_panel.get_node("VBox/Divider") as HSeparator
	var div_style := StyleBoxFlat.new()
	div_style.bg_color = Color(COLOR_NEUTRAL, 0.4)
	div_style.set_content_margin_all(0)
	divider.add_theme_stylebox_override("separator", div_style)

	# Confirm dialog style
	var confirm_dialog: PanelContainer = _confirm_overlay.get_node("ConfirmCenter/ConfirmDialog") as PanelContainer
	var confirm_style := StyleBoxFlat.new()
	confirm_style.bg_color = COLOR_SURFACE
	confirm_style.border_color = COLOR_CORAL
	confirm_style.set_border_width_all(1)
	confirm_style.set_corner_radius_all(8)
	confirm_style.set_content_margin_all(24)
	confirm_dialog.add_theme_stylebox_override("panel", confirm_style)

	# Confirm dialog divider style
	var dialog_divider: HSeparator = confirm_dialog.get_node("DialogVBox/DialogDivider") as HSeparator
	var dialog_div_style := StyleBoxFlat.new()
	dialog_div_style.bg_color = Color(COLOR_NEUTRAL, 0.4)
	dialog_div_style.set_content_margin_all(0)
	dialog_divider.add_theme_stylebox_override("separator", dialog_div_style)

	# Button styles
	_style_button(_destroy_confirm_button, COLOR_CORAL)
	_style_button(_cancel_confirm_button, COLOR_NEUTRAL)

func _connect_signals() -> void:
	PlayerInventory.slot_changed.connect(_on_slot_changed)
	InputManager.input_device_changed.connect(_on_input_device_changed)
	_action_popup.action_requested.connect(_on_action_popup_action_requested)
	_action_popup.cancelled.connect(_on_action_popup_cancelled)
	_destroy_confirm_button.pressed.connect(_on_destroy_confirmed)
	_cancel_confirm_button.pressed.connect(_close_destroy_confirm)
	# Mouse hover and click for each slot
	for i: int in range(Inventory.MAX_SLOTS):
		_slot_panels[i].mouse_entered.connect(_on_slot_mouse_entered.bind(i))
		_slot_panels[i].gui_input.connect(_on_slot_gui_input.bind(i))

func _refresh_all_slots() -> void:
	for i: int in range(Inventory.MAX_SLOTS):
		_refresh_slot(i)

func _refresh_slot(index: int) -> void:
	var slot_data: Dictionary = PlayerInventory.get_slot(index)
	var is_empty: bool = slot_data.is_empty()

	# Update slot background
	var style: StyleBoxFlat = _slot_panels[index].get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = COLOR_SLOT_BG if is_empty else COLOR_SLOT_BG_OCCUPIED
	_slot_panels[index].add_theme_stylebox_override("panel", style)

	# Update icon
	_slot_icons[index].visible = not is_empty
	if not is_empty:
		var resource_type: ResourceDefs.ResourceType = slot_data.get("resource_type") as ResourceDefs.ResourceType
		var icon_path: String = ResourceDefs.get_icon_path(resource_type)
		if not icon_path.is_empty():
			_slot_icons[index].texture = load(icon_path) as Texture2D
		else:
			_slot_icons[index].texture = null

	# Update count
	var quantity: int = slot_data.get("quantity", 0) as int
	_slot_count_labels[index].visible = quantity > 1
	_slot_count_labels[index].text = "x%d" % quantity

func _update_focus_visual() -> void:
	for i: int in range(Inventory.MAX_SLOTS):
		var style: StyleBoxFlat = _slot_panels[i].get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if i == _focused_slot:
			style.border_color = COLOR_TEAL
			style.set_border_width_all(2)
		else:
			style.border_color = COLOR_SLOT_BORDER
			style.set_border_width_all(1)
		_slot_panels[i].add_theme_stylebox_override("panel", style)

func _update_detail_area() -> void:
	var slot_data: Dictionary = PlayerInventory.get_slot(_focused_slot)
	if slot_data.is_empty():
		_detail_icon.visible = false
		_detail_name_label.text = "Empty Slot"
		_detail_name_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		_detail_quantity_label.text = ""
		if _detail_drop_hint:
			_detail_drop_hint.visible = false
		for i: int in range(5):
			(_detail_stars_container.get_child(i) as Label).visible = false
		return

	var resource_type: ResourceDefs.ResourceType = slot_data.get("resource_type") as ResourceDefs.ResourceType
	var purity: ResourceDefs.Purity = slot_data.get("purity") as ResourceDefs.Purity
	var quantity: int = slot_data.get("quantity", 0) as int

	# Detail icon
	var detail_icon_path: String = ResourceDefs.get_icon_path(resource_type)
	if not detail_icon_path.is_empty():
		_detail_icon.texture = load(detail_icon_path) as Texture2D
		_detail_icon.visible = true
	else:
		_detail_icon.visible = false

	_detail_name_label.text = ResourceDefs.get_resource_name(resource_type)
	_detail_name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	_detail_quantity_label.text = "x %d" % quantity

	# Show drop/destroy hints for non-empty slots
	_refresh_controls_descriptor()

	# Update stars
	var purity_val: int = purity as int
	for i: int in range(5):
		var star: Label = _detail_stars_container.get_child(i) as Label
		star.visible = true
		if i < purity_val:
			star.add_theme_color_override("font_color", COLOR_AMBER)
		else:
			star.add_theme_color_override("font_color", COLOR_NEUTRAL)

func _request_destroy() -> void:
	if PlayerInventory.is_slot_empty(_focused_slot):
		return
	_open_destroy_confirm()

func _open_destroy_confirm() -> void:
	var slot_data: Dictionary = PlayerInventory.get_slot(_focused_slot)
	var resource_type: ResourceDefs.ResourceType = slot_data.get("resource_type") as ResourceDefs.ResourceType
	var quantity: int = slot_data.get("quantity", 0) as int
	var item_name: String = ResourceDefs.get_resource_name(resource_type)

	_confirm_title_label.text = "Destroy %s?" % item_name
	_confirm_message_label.text = "x%d %s will be permanently destroyed. This cannot be undone." % [quantity, item_name]
	_confirm_overlay.visible = true
	_confirm_visible = true
	# CANCEL focused by default to prevent accidental destruction
	_cancel_confirm_button.grab_focus()
	Global.debug_log("InventoryScreen: destroy confirm opened for slot %d" % _focused_slot)

func _close_destroy_confirm() -> void:
	_confirm_overlay.visible = false
	_confirm_visible = false
	Global.debug_log("InventoryScreen: destroy confirm cancelled")

func _on_destroy_confirmed() -> void:
	var slot_data: Dictionary = PlayerInventory.get_slot(_focused_slot)
	if slot_data.is_empty():
		_close_destroy_confirm()
		return
	var resource_type: ResourceDefs.ResourceType = slot_data.get("resource_type") as ResourceDefs.ResourceType
	var purity: ResourceDefs.Purity = slot_data.get("purity") as ResourceDefs.Purity
	var quantity: int = slot_data.get("quantity", 0) as int
	PlayerInventory.remove_from_slot(_focused_slot, quantity)
	item_destroyed.emit(resource_type, purity, quantity)
	Global.debug_log("InventoryScreen: destroyed %d %s from slot %d" % [quantity, ResourceDefs.get_resource_name(resource_type), _focused_slot])
	_close_destroy_confirm()
	_update_detail_area()

func _drop_focused_slot() -> void:
	var slot_data: Dictionary = PlayerInventory.get_slot(_focused_slot)
	if slot_data.is_empty():
		return
	var resource_type: ResourceDefs.ResourceType = slot_data.get("resource_type") as ResourceDefs.ResourceType
	var purity: ResourceDefs.Purity = slot_data.get("purity") as ResourceDefs.Purity
	var quantity: int = slot_data.get("quantity", 0) as int
	PlayerInventory.remove_from_slot(_focused_slot, quantity)
	var resource_name: String = ResourceDefs.get_resource_name(resource_type)
	Global.debug_log("InventoryScreen: drop requested — %s x%d" % [resource_name, quantity])
	item_drop_requested.emit(resource_type, purity, quantity)
	_refresh_slot(_focused_slot)
	_update_detail_area()

func _style_button(button: Button, accent_color: Color) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(accent_color, 0.2)
	normal_style.border_color = accent_color
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(4)
	normal_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", normal_style)

	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(accent_color, 0.4)
	button.add_theme_stylebox_override("pressed", pressed_style)

	var focus_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	focus_style.border_color = COLOR_TEAL
	focus_style.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus_style)

	button.add_theme_color_override("font_color", accent_color)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT_PRIMARY)

func _handle_stick_input(event: InputEventJoypadMotion) -> void:
	# Block grid stick navigation while the action popup is open
	if _action_popup and _action_popup.is_open():
		return

	var axis: int = event.axis
	var value: float = event.axis_value

	if axis == JOY_AXIS_LEFT_X:
		if absf(value) < STICK_DEAD_ZONE:
			_stick_latched_x = false
			return
		if _stick_latched_x:
			get_viewport().set_input_as_handled()
			return
		_stick_latched_x = true
		var direction: int = 1 if value > 0 else -1
		if _confirm_visible:
			# Left/right switches between Destroy and Cancel buttons
			if direction < 0:
				_destroy_confirm_button.grab_focus()
			else:
				_cancel_confirm_button.grab_focus()
		else:
			_move_focus(direction, 0)
		get_viewport().set_input_as_handled()
	elif axis == JOY_AXIS_LEFT_Y:
		if absf(value) < STICK_DEAD_ZONE:
			_stick_latched_y = false
			return
		if _stick_latched_y:
			get_viewport().set_input_as_handled()
			return
		_stick_latched_y = true
		if not _confirm_visible:
			var direction: int = 1 if value > 0 else -1
			_move_focus(0, direction)
		get_viewport().set_input_as_handled()

func _move_focus(dx: int, dy: int) -> void:
	var col: int = _focused_slot % GRID_COLUMNS
	var row: int = _focused_slot / GRID_COLUMNS

	col = (col + dx) % GRID_COLUMNS
	if col < 0:
		col += GRID_COLUMNS
	row = (row + dy) % GRID_ROWS
	if row < 0:
		row += GRID_ROWS

	_focused_slot = row * GRID_COLUMNS + col
	_update_focus_visual()
	_update_detail_area()

func _on_slot_mouse_entered(index: int) -> void:
	if not _is_open or _confirm_visible or is_action_popup_open():
		return
	select_slot(index)

func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if not _is_open or _confirm_visible or is_action_popup_open():
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null:
		return
	if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		select_slot(index)
	elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		select_slot(index)
		_drop_focused_slot()

func _on_slot_changed(slot_index: int) -> void:
	Global.debug_log("InventoryScreen: slot %d changed" % slot_index)
	if _is_open:
		_refresh_slot(slot_index)
		if slot_index == _focused_slot:
			_update_detail_area()

func _open_action_popup() -> void:
	if _action_popup == null:
		return
	_action_popup.show_for_slot(_focused_slot)
	_refresh_controls_descriptor()
	Global.debug_log("InventoryScreen: action popup opened for slot %d" % _focused_slot)

func _on_action_popup_action_requested(action: String, slot_index: int) -> void:
	_refresh_controls_descriptor()
	match action:
		"drop":
			# Route to existing drop logic — same path as G / right-click
			_focused_slot = slot_index
			_drop_focused_slot()
		"destroy":
			# Route to existing destroy logic directly — popup hold-to-confirm
			# replaces the keyboard confirm dialog, so no re-prompt
			_focused_slot = slot_index
			_destroy_from_popup()
	Global.debug_log("InventoryScreen: action popup routed '%s' for slot %d" % [action, slot_index])

func _on_action_popup_cancelled() -> void:
	_refresh_controls_descriptor()
	Global.debug_log("InventoryScreen: action popup cancelled, grid navigation resumed")

func _destroy_from_popup() -> void:
	var slot_data: Dictionary = PlayerInventory.get_slot(_focused_slot)
	if slot_data.is_empty():
		return
	var resource_type: ResourceDefs.ResourceType = slot_data.get("resource_type") as ResourceDefs.ResourceType
	var purity: ResourceDefs.Purity = slot_data.get("purity") as ResourceDefs.Purity
	var quantity: int = slot_data.get("quantity", 0) as int
	PlayerInventory.remove_from_slot(_focused_slot, quantity)
	item_destroyed.emit(resource_type, purity, quantity)
	Global.debug_log("InventoryScreen: destroyed %d %s from slot %d (via popup)" % [quantity, ResourceDefs.get_resource_name(resource_type), _focused_slot])
	_update_detail_area()

func _refresh_controls_descriptor() -> void:
	if _detail_drop_hint == null:
		return

	# While popup is open, show popup navigation hints
	if _action_popup and _action_popup.is_open():
		_detail_drop_hint.text = "[A] Confirm / Hold to Destroy   [B] Cancel   D-pad ↑↓ Navigate"
		_detail_drop_hint.visible = true
		return

	# Hide descriptor when focused slot is empty
	var slot_data: Dictionary = PlayerInventory.get_slot(_focused_slot)
	if slot_data.is_empty():
		_detail_drop_hint.visible = false
		return

	# Show device-appropriate controls descriptor
	var current_device: String = InputManager.get_current_input_device()
	if current_device == "gamepad":
		_detail_drop_hint.text = "[Y] Actions"
	else:
		_detail_drop_hint.text = "[G] Drop  |  [Enter/A] Destroy  |  [Right-Click] Drop"
	_detail_drop_hint.visible = true

func _on_input_device_changed(_device: String) -> void:
	if _is_open:
		_refresh_controls_descriptor()
