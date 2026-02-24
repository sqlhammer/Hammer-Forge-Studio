## Fabricator interaction panel: browse recipes, start crafting jobs, monitor progress.
## Opens when the player interacts with an installed Fabricator module inside the ship.
class_name FabricatorPanel
extends CanvasLayer

# ── Signals ──────────────────────────────────────────────
signal closed

# ── Constants ─────────────────────────────────────────────
const PANEL_WIDTH: float = 860.0
const PANEL_HEIGHT: float = 560.0
const DETAIL_WIDTH: float = 480.0
const LIST_WIDTH: float = 340.0
const SLOT_SIZE: float = 72.0

## Style colors matching UI style guide
const COLOR_SURFACE := Color("#0A0F18", 0.95)
const COLOR_BORDER := Color("#007A63")
const COLOR_TEAL := Color("#00D4AA")
const COLOR_AMBER := Color("#FFB830")
const COLOR_CORAL := Color("#FF6B5A")
const COLOR_GREEN := Color("#4ADE80")
const COLOR_TEXT_PRIMARY := Color("#F1F5F9")
const COLOR_TEXT_SECONDARY := Color("#94A3B8")
const COLOR_NEUTRAL := Color("#94A3B8")
const COLOR_SLOT_BG := Color("#1A2736", 0.8)
const COLOR_BAR_BG := Color("#1A2736")
const COLOR_DIM := Color("#000000", 0.5)
const COLOR_PANEL_BG := Color("#0F1923", 0.85)
const COLOR_LIST_BG := Color("#0F1923", 0.85)

## Recipe categories for the list
const RECIPE_CATEGORIES: Dictionary = {
	"spare_battery": "COMPONENTS",
	"head_lamp": "EQUIPMENT",
}

# ── Private Variables ─────────────────────────────────────
var _is_open: bool = false
var _dim_rect: ColorRect = null
var _main_panel: PanelContainer = null
var _selected_recipe_id: String = ""
var _recipe_ids: Array[String] = []
var _selected_index: int = -1
var _focus_on_list: bool = true

## Left column detail elements
var _recipe_name_label: Label = null
var _input_slot_icon: ColorRect = null
var _input_slot_label: Label = null
var _output_slot_icon: ColorRect = null
var _output_slot_label: Label = null
var _input_desc_label: Label = null
var _output_desc_label: Label = null
var _have_label: Label = null
var _progress_bar: ProgressBar = null
var _progress_label: Label = null
var _start_button: Button = null
var _feedback_label: Label = null

## Right column list elements
var _recipe_list_container: VBoxContainer = null
var _recipe_rows: Array[PanelContainer] = []
var _recipe_row_labels: Array[Label] = []
var _recipe_row_indicators: Array[ColorRect] = []
var _recipe_row_dots: Array[ColorRect] = []
var _list_scroll: ScrollContainer = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	layer = 2
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = false
	_recipe_ids = FabricatorDefs.get_all_recipe_ids()
	_build_ui()
	_connect_signals()

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return

	if _focus_on_list:
		if event.is_action_pressed("ui_down"):
			_move_list_focus(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			_move_list_focus(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_left"):
			if _selected_index >= 0 and not Fabricator.is_job_active():
				_focus_on_list = false
				_start_button.grab_focus()
			get_viewport().set_input_as_handled()
	else:
		if event.is_action_pressed("ui_right"):
			if not Fabricator.is_job_active():
				_focus_on_list = true
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			if _start_button.has_focus() and not _start_button.disabled:
				_on_start_pressed()
			get_viewport().set_input_as_handled()

# ── Public Methods ────────────────────────────────────────

## Opens the fabricator panel.
func open() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	_focus_on_list = true
	_selected_index = -1
	_selected_recipe_id = ""
	# Auto-select first recipe if available
	if _recipe_ids.size() > 0:
		_selected_index = 0
		_selected_recipe_id = _recipe_ids[0]
	_refresh_ui()
	InputManager.set_gameplay_inputs_enabled(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_animate_open()
	Global.log("FabricatorPanel: opened")

## Closes the fabricator panel.
func close() -> void:
	if not _is_open:
		return
	_is_open = false
	InputManager.set_gameplay_inputs_enabled(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_animate_close()
	closed.emit()
	Global.log("FabricatorPanel: closed")

## Returns true if the panel is open.
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
	panel_style.set_content_margin_all(24)
	_main_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(_main_panel)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 12)
	_main_panel.add_child(outer_vbox)

	# Title
	var title := Label.new()
	title.text = "FABRICATOR"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer_vbox.add_child(title)

	_add_divider(outer_vbox)

	# HBox: detail (left) + recipe list (right)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	outer_vbox.add_child(hbox)

	# Left column: job detail
	var left_col := _build_detail_column()
	hbox.add_child(left_col)

	# Vertical divider
	var v_divider := VSeparator.new()
	var vdiv_style := StyleBoxFlat.new()
	vdiv_style.bg_color = Color(COLOR_NEUTRAL, 0.3)
	vdiv_style.set_content_margin_all(0)
	v_divider.add_theme_stylebox_override("separator", vdiv_style)
	hbox.add_child(v_divider)

	# Right column: recipe list
	var right_col := _build_recipe_list()
	hbox.add_child(right_col)

	# Instructions
	var instructions := Label.new()
	instructions.text = "[Up/Down] Select  [Left/Enter] Start  [Esc] Close"
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer_vbox.add_child(instructions)

func _build_detail_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(DETAIL_WIDTH, 0)
	col.add_theme_constant_override("separation", 12)

	# Selected recipe name
	_recipe_name_label = Label.new()
	_recipe_name_label.text = "Select a recipe >"
	_recipe_name_label.add_theme_font_size_override("font_size", 24)
	_recipe_name_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	col.add_child(_recipe_name_label)

	_add_divider(col)

	# Slot row: input → output
	var slot_row := _build_slot_row()
	col.add_child(slot_row)

	# Resource availability
	_have_label = Label.new()
	_have_label.add_theme_font_size_override("font_size", 16)
	_have_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	col.add_child(_have_label)

	_add_divider(col)

	# Progress section
	var progress_section := _build_progress_section()
	col.add_child(progress_section)

	# Button row
	var button_center := CenterContainer.new()
	col.add_child(button_center)

	_start_button = Button.new()
	_start_button.text = "START"
	_start_button.custom_minimum_size = Vector2(120, 48)
	_start_button.add_theme_font_size_override("font_size", 20)
	_style_button(_start_button, COLOR_TEAL)
	_start_button.pressed.connect(_on_start_pressed)
	button_center.add_child(_start_button)

	# Feedback label
	_feedback_label = Label.new()
	_feedback_label.add_theme_font_size_override("font_size", 16)
	_feedback_label.add_theme_color_override("font_color", COLOR_CORAL)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_feedback_label)

	return col

func _build_slot_row() -> CenterContainer:
	var center := CenterContainer.new()

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	center.add_child(hbox)

	# Input slot
	var input_container := _create_labeled_slot("INPUT")
	hbox.add_child(input_container)
	_input_slot_icon = input_container.get_meta("icon") as ColorRect
	_input_slot_label = input_container.get_meta("label") as Label

	# Input description
	_input_desc_label = Label.new()
	_input_desc_label.add_theme_font_size_override("font_size", 12)
	_input_desc_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_input_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	input_container.add_child(_input_desc_label)

	# Arrow
	var arrow := Label.new()
	arrow.text = ">>>"
	arrow.add_theme_font_size_override("font_size", 24)
	arrow.add_theme_color_override("font_color", COLOR_BORDER)
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(arrow)

	# Output slot
	var output_container := _create_labeled_slot("OUTPUT")
	hbox.add_child(output_container)
	_output_slot_icon = output_container.get_meta("icon") as ColorRect
	_output_slot_label = output_container.get_meta("label") as Label

	# Output description
	_output_desc_label = Label.new()
	_output_desc_label.add_theme_font_size_override("font_size", 12)
	_output_desc_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_output_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	output_container.add_child(_output_desc_label)

	return center

func _create_labeled_slot(slot_label_text: String) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	var header := Label.new()
	header.text = slot_label_text
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(header)

	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SLOT_BG
	style.border_color = Color(COLOR_NEUTRAL, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(4)
	slot.add_theme_stylebox_override("panel", style)
	container.add_child(slot)

	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.visible = false
	slot.add_child(icon)

	var count_label := Label.new()
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.visible = false
	slot.add_child(count_label)

	container.set_meta("icon", icon)
	container.set_meta("label", count_label)

	return container

func _build_progress_section() -> VBoxContainer:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(340, 16)
	_progress_bar.max_value = 1.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = COLOR_BAR_BG
	bar_bg.set_corner_radius_all(4)
	_progress_bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = COLOR_TEAL
	bar_fill.set_corner_radius_all(4)
	_progress_bar.add_theme_stylebox_override("fill", bar_fill)
	section.add_child(_progress_bar)

	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 14)
	_progress_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(_progress_label)

	return section

func _build_recipe_list() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(LIST_WIDTH, 0)
	col.add_theme_constant_override("separation", 4)

	# List header
	var header := Label.new()
	header.text = "RECIPES"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	col.add_child(header)

	_add_divider(col)

	# Scroll container
	_list_scroll = ScrollContainer.new()
	_list_scroll.custom_minimum_size = Vector2(LIST_WIDTH, 380)
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(_list_scroll)

	_recipe_list_container = VBoxContainer.new()
	_recipe_list_container.add_theme_constant_override("separation", 4)
	_list_scroll.add_child(_recipe_list_container)

	# Build recipe rows by category
	var last_category: String = ""
	for i: int in range(_recipe_ids.size()):
		var recipe_id: String = _recipe_ids[i]
		var category: String = RECIPE_CATEGORIES.get(recipe_id, "OTHER")

		if category != last_category:
			# Category header
			var cat_label := Label.new()
			cat_label.text = category
			cat_label.add_theme_font_size_override("font_size", 14)
			cat_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
			_recipe_list_container.add_child(cat_label)
			last_category = category

		var row := _build_recipe_row(recipe_id)
		_recipe_list_container.add_child(row)

	return col

func _build_recipe_row(recipe_id: String) -> PanelContainer:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 56)
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color.TRANSPARENT
	row_style.set_content_margin_all(8)
	row.add_theme_stylebox_override("panel", row_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	row.add_child(hbox)

	# Selection indicator
	var indicator := ColorRect.new()
	indicator.custom_minimum_size = Vector2(4, 40)
	indicator.color = Color.TRANSPARENT
	hbox.add_child(indicator)

	# Icon placeholder
	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.color = COLOR_TEAL
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon)

	# Text block
	var text_vbox := VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 2)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var name_label := Label.new()
	name_label.text = FabricatorDefs.get_recipe_name(recipe_id)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	text_vbox.add_child(name_label)

	# Input cost summary
	var inputs: Array = FabricatorDefs.get_inputs(recipe_id)
	var cost_text: String = ""
	for input: Dictionary in inputs:
		var resource_type: ResourceDefs.ResourceType = input.get("resource_type", ResourceDefs.ResourceType.NONE) as ResourceDefs.ResourceType
		var quantity: int = input.get("quantity", 0) as int
		var resource_name: String = ResourceDefs.get_resource_name(resource_type)
		if cost_text.length() > 0:
			cost_text += ", "
		cost_text += "%d %s" % [quantity, resource_name]

	var cost_label := Label.new()
	cost_label.text = cost_text
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	text_vbox.add_child(cost_label)

	# Affordability dot
	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(12, 12)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(dot)

	_recipe_rows.append(row)
	_recipe_row_labels.append(name_label)
	_recipe_row_indicators.append(indicator)
	_recipe_row_dots.append(dot)

	return row

func _connect_signals() -> void:
	Fabricator.job_started.connect(_on_job_started)
	Fabricator.job_progress_changed.connect(_on_job_progress)
	Fabricator.job_completed.connect(_on_job_completed)
	Fabricator.job_cancelled.connect(_on_job_cancelled)
	PlayerInventory.item_added.connect(_on_inventory_changed)
	PlayerInventory.item_removed.connect(_on_inventory_changed)

func _refresh_ui() -> void:
	_feedback_label.text = ""
	_refresh_recipe_list()
	_refresh_detail()
	_refresh_progress()

func _refresh_recipe_list() -> void:
	var is_processing: bool = Fabricator.is_job_active()

	for i: int in range(_recipe_ids.size()):
		var recipe_id: String = _recipe_ids[i]
		var row: PanelContainer = _recipe_rows[i]
		var name_label: Label = _recipe_row_labels[i]
		var indicator: ColorRect = _recipe_row_indicators[i]
		var dot: ColorRect = _recipe_row_dots[i]

		# Selection indicator
		var is_selected: bool = i == _selected_index
		indicator.color = COLOR_TEAL if is_selected else Color.TRANSPARENT

		# Row highlighting
		var row_style: StyleBoxFlat = row.get_theme_stylebox("panel") as StyleBoxFlat
		if is_selected:
			row_style.bg_color = Color(COLOR_SLOT_BG, 0.8)
			name_label.add_theme_color_override("font_color", COLOR_TEAL)
		else:
			row_style.bg_color = Color.TRANSPARENT
			name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)

		# Processing lock
		if is_processing:
			row.modulate = Color(1, 1, 1, 0.4)
		else:
			row.modulate = Color.WHITE

		# Affordability dot
		var can_afford: bool = _can_afford_recipe(recipe_id)
		dot.color = COLOR_GREEN if can_afford else COLOR_AMBER

func _refresh_detail() -> void:
	if _selected_recipe_id.is_empty():
		_recipe_name_label.text = "Select a recipe >"
		_recipe_name_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		_input_slot_icon.visible = false
		_input_slot_label.visible = false
		_output_slot_icon.visible = false
		_output_slot_label.visible = false
		_input_desc_label.text = ""
		_output_desc_label.text = ""
		_have_label.text = ""
		_start_button.disabled = true
		return

	var recipe_id: String = _selected_recipe_id
	_recipe_name_label.text = FabricatorDefs.get_recipe_name(recipe_id)
	_recipe_name_label.add_theme_color_override("font_color", COLOR_TEAL)

	# Input slot
	var inputs: Array = FabricatorDefs.get_inputs(recipe_id)
	if inputs.size() > 0:
		var input: Dictionary = inputs[0]
		var resource_type: ResourceDefs.ResourceType = input.get("resource_type", ResourceDefs.ResourceType.NONE) as ResourceDefs.ResourceType
		var quantity: int = input.get("quantity", 0) as int
		var resource_name: String = ResourceDefs.get_resource_name(resource_type)
		var available: int = PlayerInventory.get_total_count(resource_type)

		_input_slot_icon.visible = true
		_input_slot_icon.color = COLOR_TEAL
		_input_slot_label.visible = true
		_input_slot_label.text = "x%d" % quantity
		_input_desc_label.text = "%s x%d" % [resource_name, quantity]

		_have_label.text = "Have: %d %s" % [available, resource_name]
		if available >= quantity:
			_have_label.add_theme_color_override("font_color", COLOR_GREEN)
		else:
			_have_label.add_theme_color_override("font_color", COLOR_AMBER)
	else:
		_input_slot_icon.visible = false
		_input_slot_label.visible = false
		_input_desc_label.text = ""
		_have_label.text = ""

	# Output slot
	var output_mode: String = FabricatorDefs.get_output_mode(recipe_id)
	var output: Dictionary = FabricatorDefs.get_output(recipe_id)
	if output_mode == FabricatorDefs.OUTPUT_MODE_INVENTORY and not output.is_empty():
		var out_type: ResourceDefs.ResourceType = output.get("resource_type", ResourceDefs.ResourceType.NONE) as ResourceDefs.ResourceType
		var out_qty: int = output.get("quantity", 0) as int
		_output_slot_icon.visible = true
		_output_slot_icon.color = COLOR_GREEN
		_output_slot_label.visible = true
		_output_slot_label.text = "x%d" % out_qty
		_output_desc_label.text = ResourceDefs.get_resource_name(out_type)
	elif output_mode == FabricatorDefs.OUTPUT_MODE_EQUIP_HEAD_LAMP:
		_output_slot_icon.visible = true
		_output_slot_icon.color = COLOR_AMBER
		_output_slot_label.visible = false
		_output_desc_label.text = "Head Lamp (Equip)"
	else:
		_output_slot_icon.visible = false
		_output_slot_label.visible = false
		_output_desc_label.text = ""

	# Button state
	var can_start: bool = not Fabricator.is_job_active() and _can_afford_recipe(recipe_id)
	_start_button.disabled = not can_start

func _refresh_progress() -> void:
	if Fabricator.is_job_active():
		var progress: float = Fabricator.get_job_progress()
		var current_recipe: String = Fabricator.get_current_recipe_id()
		var duration: float = FabricatorDefs.get_duration(current_recipe)
		var time_remaining: float = duration * (1.0 - progress)
		_progress_bar.value = progress
		_progress_label.text = "%d%% . %.0fs remaining" % [int(progress * 100.0), time_remaining]
	else:
		_progress_bar.value = 0.0
		_progress_label.text = ""

func _can_afford_recipe(recipe_id: String) -> bool:
	var inputs: Array = FabricatorDefs.get_inputs(recipe_id)
	for input: Dictionary in inputs:
		var resource_type: ResourceDefs.ResourceType = input.get("resource_type", ResourceDefs.ResourceType.NONE) as ResourceDefs.ResourceType
		var quantity: int = input.get("quantity", 0) as int
		if PlayerInventory.get_total_count(resource_type) < quantity:
			return false
	return true

func _move_list_focus(direction: int) -> void:
	if Fabricator.is_job_active():
		return
	var new_index: int = clampi(_selected_index + direction, 0, _recipe_ids.size() - 1)
	if new_index != _selected_index:
		_selected_index = new_index
		_selected_recipe_id = _recipe_ids[_selected_index]
		_refresh_ui()

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

	var disabled_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color(accent_color, 0.05)
	disabled_style.border_color = Color(accent_color, 0.3)
	button.add_theme_stylebox_override("disabled", disabled_style)

	var focus_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	focus_style.border_color = COLOR_TEAL
	focus_style.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus_style)

	button.add_theme_color_override("font_color", accent_color)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_disabled_color", Color(accent_color, 0.3))

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

# ── Signal Handlers ──────────────────────────────────────

func _on_start_pressed() -> void:
	if _selected_recipe_id.is_empty():
		return
	var success: bool = Fabricator.queue_job(_selected_recipe_id)
	if success:
		_feedback_label.text = ""
		_focus_on_list = false
	else:
		if not _can_afford_recipe(_selected_recipe_id):
			_feedback_label.text = "Not enough resources"
		else:
			_feedback_label.text = "Cannot start job"
		_feedback_label.add_theme_color_override("font_color", COLOR_CORAL)
	_refresh_ui()

func _on_job_started(_recipe_id: String) -> void:
	if _is_open:
		_refresh_ui()

func _on_job_progress(progress: float) -> void:
	if _is_open:
		_progress_bar.value = progress
		var current_recipe: String = Fabricator.get_current_recipe_id()
		var duration: float = FabricatorDefs.get_duration(current_recipe)
		var time_remaining: float = duration * (1.0 - progress)
		_progress_label.text = "%d%% . %.0fs remaining" % [int(progress * 100.0), time_remaining]

func _on_job_completed(_recipe_id: String) -> void:
	if _is_open:
		_feedback_label.text = "Complete!"
		_feedback_label.add_theme_color_override("font_color", COLOR_TEAL)
		_focus_on_list = true
		_refresh_ui()

func _on_job_cancelled() -> void:
	if _is_open:
		_feedback_label.text = "Job cancelled"
		_feedback_label.add_theme_color_override("font_color", COLOR_CORAL)
		_focus_on_list = true
		_refresh_ui()

func _on_inventory_changed(_resource_type: ResourceDefs.ResourceType, _purity: ResourceDefs.Purity, _quantity: int) -> void:
	if _is_open:
		_refresh_ui()
