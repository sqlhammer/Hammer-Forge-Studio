## Module placement selection UI: lists available modules for a ship placement zone.
## Player selects a module, confirms install, resources are deducted, module is placed.
class_name ModulePlacementUI
extends CanvasLayer

# ── Signals ──────────────────────────────────────────────
signal module_installed(module_id: String, zone_index: int)
signal closed

# ── Constants ─────────────────────────────────────────────
const PANEL_WIDTH: float = 420.0
const PANEL_HEIGHT: float = 320.0

## Style colors matching UI style guide
const COLOR_SURFACE := Color("#0A0F18", 0.95)
const COLOR_BORDER := Color("#007A63")
const COLOR_TEAL := Color("#00D4AA")
const COLOR_AMBER := Color("#FFB830")
const COLOR_CORAL := Color("#FF6B5A")
const COLOR_TEXT_PRIMARY := Color("#F1F5F9")
const COLOR_TEXT_SECONDARY := Color("#94A3B8")
const COLOR_NEUTRAL := Color("#94A3B8")
const COLOR_SLOT_BG := Color("#1A2736", 0.8)
const COLOR_DIM := Color("#000000", 0.5)

# ── Private Variables ─────────────────────────────────────
var _is_open: bool = false
var _zone_index: int = -1
var _module_ids: Array[String] = []
var _selected_index: int = 0
var _row_panels: Array[PanelContainer] = []
var _cost_label: Label = null
var _power_label: Label = null
var _description_label: Label = null
var _feedback_label: Label = null
var _dim_rect: ColorRect = null
var _main_panel: PanelContainer = null
var _module_list_container: VBoxContainer = null
var _empty_label: Label = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	layer = 3
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = false
	_build_ui()

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_attempt_install()
		get_viewport().set_input_as_handled()

# ── Public Methods ────────────────────────────────────────

## Opens the placement UI for the given zone.
func open(zone_index: int) -> void:
	if _is_open:
		return
	_zone_index = zone_index
	_is_open = true
	visible = true
	_selected_index = 0
	_build_available_module_list()
	_feedback_label.text = ""
	InputManager.set_gameplay_inputs_enabled(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_animate_open()
	Global.log("ModulePlacementUI: opened for zone %d" % zone_index)

## Closes the placement UI.
func close() -> void:
	if not _is_open:
		return
	_is_open = false
	InputManager.set_gameplay_inputs_enabled(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_animate_close()
	closed.emit()
	Global.log("ModulePlacementUI: closed")

## Returns true if the UI is open.
func is_open() -> bool:
	return _is_open

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

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_layer.add_child(center)

	# Main panel
	_main_panel = PanelContainer.new()
	_main_panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	_main_panel.pivot_offset = Vector2(PANEL_WIDTH / 2.0, PANEL_HEIGHT / 2.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_SURFACE
	panel_style.border_color = COLOR_BORDER
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(20)
	_main_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(_main_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_main_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "INSTALL MODULE"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	vbox.add_child(title)

	# Divider
	_add_divider(vbox)

	# Module list container
	_module_list_container = VBoxContainer.new()
	_module_list_container.add_theme_constant_override("separation", 4)
	vbox.add_child(_module_list_container)

	# Empty label (shown when no modules available)
	_empty_label = Label.new()
	_empty_label.text = "All modules installed"
	_empty_label.add_theme_font_size_override("font_size", 18)
	_empty_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.visible = false
	vbox.add_child(_empty_label)

	# Detail area
	var detail_panel := PanelContainer.new()
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = COLOR_SLOT_BG
	detail_style.set_corner_radius_all(4)
	detail_style.set_content_margin_all(12)
	detail_panel.add_theme_stylebox_override("panel", detail_style)
	vbox.add_child(detail_panel)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 4)
	detail_panel.add_child(detail_vbox)

	_description_label = Label.new()
	_description_label.add_theme_font_size_override("font_size", 16)
	_description_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_vbox.add_child(_description_label)

	_cost_label = Label.new()
	_cost_label.add_theme_font_size_override("font_size", 18)
	_cost_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	detail_vbox.add_child(_cost_label)

	_power_label = Label.new()
	_power_label.add_theme_font_size_override("font_size", 18)
	_power_label.add_theme_color_override("font_color", COLOR_AMBER)
	detail_vbox.add_child(_power_label)

	# Feedback label
	_feedback_label = Label.new()
	_feedback_label.add_theme_font_size_override("font_size", 18)
	_feedback_label.add_theme_color_override("font_color", COLOR_CORAL)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_feedback_label)

	# Footer row: instructions + cancel button
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 16)
	vbox.add_child(footer)

	var instructions := Label.new()
	instructions.text = "[Up/Down] Select  [Enter] Install  [Esc] Cancel"
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	footer.add_child(instructions)

	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(80, 32)
	cancel_button.add_theme_font_size_override("font_size", 14)
	_style_close_button(cancel_button)
	cancel_button.pressed.connect(close)
	footer.add_child(cancel_button)

func _build_available_module_list() -> void:
	# Filter to modules not already installed
	_module_ids.clear()
	var all_ids: Array[String] = ModuleDefs.get_all_module_ids()
	for module_id: String in all_ids:
		if not ModuleManager.is_installed(module_id):
			_module_ids.append(module_id)

	# Clear existing rows
	for child: Node in _module_list_container.get_children():
		child.queue_free()
	_row_panels.clear()

	if _module_ids.is_empty():
		_empty_label.visible = true
		_description_label.text = ""
		_cost_label.text = ""
		_power_label.text = ""
		return

	_empty_label.visible = false
	_selected_index = 0

	for i: int in range(_module_ids.size()):
		var module_id: String = _module_ids[i]
		var entry: Dictionary = ModuleDefs.get_module_entry(module_id)
		var module_name: String = entry.get("name", "Unknown") as String

		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 36)
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = COLOR_SLOT_BG
		row_style.set_corner_radius_all(4)
		row_style.set_content_margin_all(8)
		row.add_theme_stylebox_override("panel", row_style)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		row.add_child(hbox)

		var name_label := Label.new()
		name_label.text = module_name
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)

		var tier_enum: ModuleDefs.ModuleTier = entry.get("tier", ModuleDefs.ModuleTier.TIER_1) as ModuleDefs.ModuleTier
		var tier_text: String = ModuleDefs.MODULE_TIER_NAMES.get(tier_enum, "?") as String
		var tier_label := Label.new()
		tier_label.text = tier_text
		tier_label.add_theme_font_size_override("font_size", 16)
		tier_label.add_theme_color_override("font_color", COLOR_TEAL)
		hbox.add_child(tier_label)

		_module_list_container.add_child(row)
		_row_panels.append(row)

	_update_selection_visual()
	_update_detail_area()

func _update_selection_visual() -> void:
	for i: int in range(_row_panels.size()):
		var style: StyleBoxFlat = _row_panels[i].get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if i == _selected_index:
			style.border_color = COLOR_TEAL
			style.set_border_width_all(2)
		else:
			style.border_color = Color.TRANSPARENT
			style.set_border_width_all(0)
		_row_panels[i].add_theme_stylebox_override("panel", style)

func _update_detail_area() -> void:
	if _module_ids.is_empty():
		return

	var module_id: String = _module_ids[_selected_index]
	var entry: Dictionary = ModuleDefs.get_module_entry(module_id)

	_description_label.text = entry.get("description", "") as String

	# Cost display
	var cost: Dictionary = entry.get("install_cost", {})
	if not cost.is_empty():
		var resource_type: ResourceDefs.ResourceType = cost.get("resource_type", ResourceDefs.ResourceType.NONE) as ResourceDefs.ResourceType
		var quantity: int = cost.get("quantity", 0) as int
		var resource_name: String = ResourceDefs.get_resource_name(resource_type)
		var available: int = PlayerInventory.get_total_count(resource_type)
		var has_enough: bool = available >= quantity
		var color: Color = COLOR_TEAL if has_enough else COLOR_CORAL
		_cost_label.text = "Cost: %d %s (have %d)" % [quantity, resource_name, available]
		_cost_label.add_theme_color_override("font_color", color)
	else:
		_cost_label.text = "Cost: Free"
		_cost_label.add_theme_color_override("font_color", COLOR_TEAL)

	# Power display
	var power_draw: float = entry.get("power_draw", 0.0) as float
	var available_power: float = ShipState.get_available_power_capacity()
	var has_power: bool = available_power >= power_draw
	var power_color: Color = COLOR_AMBER if has_power else COLOR_CORAL
	_power_label.text = "Power: %.0f / %.0f available" % [power_draw, available_power]
	_power_label.add_theme_color_override("font_color", power_color)

func _move_selection(direction: int) -> void:
	if _module_ids.is_empty():
		return
	_selected_index = (_selected_index + direction) % _module_ids.size()
	if _selected_index < 0:
		_selected_index += _module_ids.size()
	_update_selection_visual()
	_update_detail_area()
	_feedback_label.text = ""

func _attempt_install() -> void:
	if _module_ids.is_empty():
		return
	var module_id: String = _module_ids[_selected_index]
	var success: bool = ModuleManager.install_module(module_id)
	if success:
		Global.log("ModulePlacementUI: installed '%s' in zone %d" % [module_id, _zone_index])
		_is_open = false
		InputManager.set_gameplay_inputs_enabled(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_animate_close()
		module_installed.emit(module_id, _zone_index)
	else:
		_feedback_label.text = "Cannot install — check resources and power"
		_feedback_label.add_theme_color_override("font_color", COLOR_CORAL)
		Global.log("ModulePlacementUI: install failed for '%s'" % module_id)

func _style_close_button(button: Button) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(COLOR_NEUTRAL, 0.2)
	normal_style.border_color = COLOR_NEUTRAL
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(4)
	normal_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", normal_style)
	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(COLOR_NEUTRAL, 0.4)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", COLOR_NEUTRAL)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT_PRIMARY)

func _add_divider(parent: Node) -> void:
	var divider := HSeparator.new()
	var div_style := StyleBoxFlat.new()
	div_style.bg_color = Color(COLOR_NEUTRAL, 0.4)
	div_style.set_content_margin_all(0)
	divider.add_theme_stylebox_override("separator", div_style)
	parent.add_child(divider)

func _animate_open() -> void:
	_dim_rect.modulate.a = 0.0
	_main_panel.modulate.a = 0.0
	_main_panel.scale = Vector2(0.95, 0.95)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_dim_rect, "modulate:a", 1.0, 0.15)
	tween.tween_property(_main_panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(_main_panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)

func _animate_close() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_dim_rect, "modulate:a", 0.0, 0.15)
	tween.tween_property(_main_panel, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func() -> void: visible = false)
