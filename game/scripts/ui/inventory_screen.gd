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
var _detail_icon: TextureRect = null
var _detail_name_label: Label = null
var _detail_stars_container: HBoxContainer = null
var _detail_quantity_label: Label = null
var _detail_drop_hint: Label = null
var _dim_rect: ColorRect = null
var _main_panel: PanelContainer = null
var _combined_container: HBoxContainer = null
var _ship_sidebar: ShipStatsSidebar = null
var _font: Font = null

## Destroy confirmation dialog state
var _confirm_visible: bool = false
var _confirm_overlay: Control = null
var _confirm_title_label: Label = null
var _confirm_message_label: Label = null
var _destroy_confirm_button: Button = null
var _cancel_confirm_button: Button = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	layer = 2
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = false
	_font = ThemeDB.fallback_font
	_build_ui()
	PlayerInventory.slot_changed.connect(_on_slot_changed)
	Global.log("InventoryScreen: ready")

func _process(_delta: float) -> void:
	if _is_open:
		# Closing must bypass InputManager suppression so the toggle key always works
		if Input.is_action_just_pressed("inventory_toggle"):
			close_inventory()
	else:
		if InputManager.is_action_just_pressed("inventory_toggle"):
			open_inventory()

func _input(event: InputEvent) -> void:
	if not _is_open:
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
	Global.log("InventoryScreen: opened")
	_is_open = true
	visible = true
	_focused_slot = 0
	_refresh_all_slots()
	_update_focus_visual()
	_update_detail_area()
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
	if _confirm_visible:
		_close_destroy_confirm()
	Global.log("InventoryScreen: closed")
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

# ── Private Methods ───────────────────────────────────────

func _build_ui() -> void:
	# Dim background
	var dim_layer := Control.new()
	dim_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim_layer)

	_dim_rect = ColorRect.new()
	_dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim_rect.color = COLOR_DIM
	dim_layer.add_child(_dim_rect)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_layer.add_child(center)

	# Combined container for inventory + sidebar
	_combined_container = HBoxContainer.new()
	_combined_container.add_theme_constant_override("separation", 0)
	_combined_container.pivot_offset = Vector2(COMBINED_WIDTH / 2.0, PANEL_HEIGHT / 2.0)
	center.add_child(_combined_container)

	# Main panel (left side — inventory grid)
	_main_panel = PanelContainer.new()
	_main_panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
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
	_combined_container.add_child(_main_panel)

	# Ship stats sidebar (right side)
	_ship_sidebar = ShipStatsSidebar.new()
	_ship_sidebar.name = "ShipStatsSidebar"
	_combined_container.add_child(_ship_sidebar)

	# Main vertical layout
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_main_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "INVENTORY"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	vbox.add_child(title)

	# Divider
	var divider := HSeparator.new()
	var div_style := StyleBoxFlat.new()
	div_style.bg_color = Color(COLOR_NEUTRAL, 0.4)
	div_style.set_content_margin_all(0)
	divider.add_theme_stylebox_override("separator", div_style)
	vbox.add_child(divider)

	# Grid container centered
	var grid_center := CenterContainer.new()
	vbox.add_child(grid_center)

	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", int(SLOT_GAP))
	grid.add_theme_constant_override("v_separation", int(SLOT_GAP))
	grid_center.add_child(grid)

	# Create slots
	for i: int in range(Inventory.MAX_SLOTS):
		var slot: PanelContainer = _create_slot(i)
		grid.add_child(slot)
		_slot_panels.append(slot)

	# Detail area
	var detail_panel := PanelContainer.new()
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color("#1A2736", 0.8)
	detail_style.set_corner_radius_all(4)
	detail_style.set_content_margin_all(12)
	detail_panel.add_theme_stylebox_override("panel", detail_style)
	vbox.add_child(detail_panel)

	var detail_hbox := HBoxContainer.new()
	detail_hbox.add_theme_constant_override("separation", 12)
	detail_panel.add_child(detail_hbox)

	_detail_icon = TextureRect.new()
	_detail_icon.custom_minimum_size = Vector2(32, 32)
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_detail_icon.visible = false
	detail_hbox.add_child(_detail_icon)

	_detail_name_label = Label.new()
	_detail_name_label.add_theme_font_size_override("font_size", 20)
	_detail_name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	_detail_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_hbox.add_child(_detail_name_label)

	_detail_stars_container = HBoxContainer.new()
	_detail_stars_container.add_theme_constant_override("separation", 2)
	for j: int in range(5):
		var star := Label.new()
		star.text = "★"
		star.add_theme_font_size_override("font_size", 16)
		_detail_stars_container.add_child(star)
	detail_hbox.add_child(_detail_stars_container)

	_detail_quantity_label = Label.new()
	_detail_quantity_label.add_theme_font_size_override("font_size", 18)
	_detail_quantity_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_detail_quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	detail_hbox.add_child(_detail_quantity_label)

	# Drop and destroy hints below the detail area
	_detail_drop_hint = Label.new()
	_detail_drop_hint.add_theme_font_size_override("font_size", 14)
	_detail_drop_hint.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_detail_drop_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_drop_hint.text = "[G] Drop  |  [Enter] Destroy  |  [Right-Click] Drop"
	_detail_drop_hint.visible = false
	vbox.add_child(_detail_drop_hint)

	# Build destroy confirmation dialog on top of everything
	_build_destroy_confirm_dialog(dim_layer)

func _build_destroy_confirm_dialog(parent: Control) -> void:
	_confirm_overlay = Control.new()
	_confirm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_overlay.visible = false
	parent.add_child(_confirm_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color("#000000", 0.3)
	_confirm_overlay.add_child(dim)

	var confirm_center := CenterContainer.new()
	confirm_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_overlay.add_child(confirm_center)

	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(400, 200)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SURFACE
	style.border_color = COLOR_CORAL
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(24)
	dialog.add_theme_stylebox_override("panel", style)
	confirm_center.add_child(dialog)

	var dialog_vbox := VBoxContainer.new()
	dialog_vbox.add_theme_constant_override("separation", 12)
	dialog.add_child(dialog_vbox)

	_confirm_title_label = Label.new()
	_confirm_title_label.add_theme_font_size_override("font_size", 22)
	_confirm_title_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	dialog_vbox.add_child(_confirm_title_label)

	# Dialog divider
	var dialog_divider := HSeparator.new()
	var dialog_div_style := StyleBoxFlat.new()
	dialog_div_style.bg_color = Color(COLOR_NEUTRAL, 0.4)
	dialog_div_style.set_content_margin_all(0)
	dialog_divider.add_theme_stylebox_override("separator", dialog_div_style)
	dialog_vbox.add_child(dialog_divider)

	_confirm_message_label = Label.new()
	_confirm_message_label.add_theme_font_size_override("font_size", 16)
	_confirm_message_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_confirm_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_vbox.add_child(_confirm_message_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 16)
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dialog_vbox.add_child(button_row)

	_destroy_confirm_button = Button.new()
	_destroy_confirm_button.text = "DESTROY"
	_destroy_confirm_button.custom_minimum_size = Vector2(120, 40)
	_destroy_confirm_button.add_theme_font_size_override("font_size", 16)
	_style_button(_destroy_confirm_button, COLOR_CORAL)
	_destroy_confirm_button.pressed.connect(_on_destroy_confirmed)
	button_row.add_child(_destroy_confirm_button)

	_cancel_confirm_button = Button.new()
	_cancel_confirm_button.text = "CANCEL"
	_cancel_confirm_button.custom_minimum_size = Vector2(120, 40)
	_cancel_confirm_button.add_theme_font_size_override("font_size", 16)
	_style_button(_cancel_confirm_button, COLOR_NEUTRAL)
	_cancel_confirm_button.pressed.connect(_close_destroy_confirm)
	button_row.add_child(_cancel_confirm_button)

func _create_slot(index: int) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SLOT_BG
	style.border_color = COLOR_SLOT_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(4)
	slot.add_theme_stylebox_override("panel", style)

	# Mouse hover and click support
	slot.mouse_entered.connect(_on_slot_mouse_entered.bind(index))
	slot.gui_input.connect(_on_slot_gui_input.bind(index))

	# Item icon
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.visible = false
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	_slot_icons.append(icon)

	# Stack count label
	var count_label := Label.new()
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.visible = false
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(count_label)
	_slot_count_labels.append(count_label)

	return slot

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
	if _detail_drop_hint:
		_detail_drop_hint.visible = true

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
	Global.log("InventoryScreen: destroy confirm opened for slot %d" % _focused_slot)

func _close_destroy_confirm() -> void:
	_confirm_overlay.visible = false
	_confirm_visible = false
	Global.log("InventoryScreen: destroy confirm cancelled")

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
	Global.log("InventoryScreen: destroyed %d %s from slot %d" % [quantity, ResourceDefs.get_resource_name(resource_type), _focused_slot])
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
	Global.log("InventoryScreen: drop requested — %s x%d" % [resource_name, quantity])
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
	if not _is_open or _confirm_visible:
		return
	select_slot(index)

func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if not _is_open or _confirm_visible:
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
	Global.log("InventoryScreen: slot %d changed" % slot_index)
	if _is_open:
		_refresh_slot(slot_index)
		if slot_index == _focused_slot:
			_update_detail_area()
