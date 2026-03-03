## Fabricator interaction panel: browse recipes, start crafting jobs, monitor progress.
## Opens when the player interacts with an installed Fabricator module inside the ship.
class_name FabricatorPanel
extends CanvasLayer

# ── Signals ──────────────────────────────────────────────
signal closed

# ── Constants ─────────────────────────────────────────────

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

## Recipe categories for the list
const RECIPE_CATEGORIES: Dictionary = {
	"spare_battery": "COMPONENTS",
	"head_lamp": "EQUIPMENT",
}

# ── Private Variables ─────────────────────────────────────
var _is_open: bool = false
var _selected_recipe_id: String = ""
var _recipe_ids: Array[String] = []
var _selected_index: int = -1
var _focus_on_list: bool = true
var _recipe_rows: Array[PanelContainer] = []
var _recipe_row_labels: Array[Label] = []
var _recipe_row_indicators: Array[ColorRect] = []
var _recipe_row_dots: Array[ColorRect] = []
var _last_detail_recipe_id: String = ""
var _cached_input_tex: Texture2D = null
var _cached_output_tex: Texture2D = null

# ── Onready Variables ─────────────────────────────────────
@onready var _dim_rect: ColorRect = %DimRect
@onready var _main_panel: PanelContainer = %MainPanel
@onready var _input_slot: PanelContainer = %InputSlot
@onready var _input_slot_icon: TextureRect = %InputIcon
@onready var _input_slot_label: Label = %InputCountLabel
@onready var _input_desc_label: Label = %InputDescLabel
@onready var _output_slot: PanelContainer = %OutputSlot
@onready var _output_slot_icon: TextureRect = %OutputIcon
@onready var _output_slot_label: Label = %OutputCountLabel
@onready var _output_desc_label: Label = %OutputDescLabel
@onready var _recipe_name_label: Label = %RecipeNameLabel
@onready var _have_label: Label = %HaveLabel
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _progress_label: Label = %ProgressLabel
@onready var _start_button: Button = %StartButton
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _close_button: Button = %CloseButton
@onready var _recipe_list_container: VBoxContainer = %RecipeListContainer
@onready var _list_scroll: ScrollContainer = %ListScroll
@onready var _title_divider: HSeparator = %TitleDivider
@onready var _detail_divider: HSeparator = %DetailDivider
@onready var _have_divider: HSeparator = %HaveDivider
@onready var _recipe_divider: HSeparator = %RecipeDivider
@onready var _vertical_divider: VSeparator = %VerticalDivider

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_recipe_ids = FabricatorDefs.get_all_recipe_ids()
	_apply_styles()
	_populate_recipe_list()
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
	_last_detail_recipe_id = ""
	# Auto-select first recipe if available
	if _recipe_ids.size() > 0:
		_selected_index = 0
		_selected_recipe_id = _recipe_ids[0]
	_refresh_ui()
	InputManager.set_gameplay_inputs_enabled(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_animate_open()
	Global.debug_log("FabricatorPanel: opened")

## Closes the fabricator panel.
func close() -> void:
	if not _is_open:
		return
	_is_open = false
	InputManager.set_gameplay_inputs_enabled(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_animate_close()
	closed.emit()
	Global.debug_log("FabricatorPanel: closed")

## Returns true if the panel is open.
func is_open() -> bool:
	return _is_open

## Returns the currently selected recipe list index.
func get_selected_recipe_index() -> int:
	return _selected_index

## Selects a recipe by its list index, matching keyboard navigation behavior.
func select_recipe_by_index(index: int) -> void:
	if index < 0 or index >= _recipe_ids.size():
		return
	if Fabricator.is_job_active():
		return
	_selected_index = index
	_selected_recipe_id = _recipe_ids[index]
	_refresh_ui()

# ── Private Methods ───────────────────────────────────────

func _apply_styles() -> void:
	# Main panel
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_SURFACE
	panel_style.border_color = COLOR_BORDER
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(24)
	_main_panel.add_theme_stylebox_override("panel", panel_style)

	# Slot styles
	var slot_style := StyleBoxFlat.new()
	slot_style.bg_color = COLOR_SLOT_BG
	slot_style.border_color = Color(COLOR_NEUTRAL, 0.3)
	slot_style.set_border_width_all(1)
	slot_style.set_corner_radius_all(4)
	slot_style.set_content_margin_all(4)
	_input_slot.add_theme_stylebox_override("panel", slot_style)
	var output_slot_style: StyleBoxFlat = slot_style.duplicate() as StyleBoxFlat
	_output_slot.add_theme_stylebox_override("panel", output_slot_style)

	# Divider styles
	var div_style := StyleBoxFlat.new()
	div_style.bg_color = Color(COLOR_NEUTRAL, 0.4)
	div_style.set_content_margin_all(0)
	_title_divider.add_theme_stylebox_override("separator", div_style)
	_detail_divider.add_theme_stylebox_override("separator", div_style.duplicate())
	_have_divider.add_theme_stylebox_override("separator", div_style.duplicate())
	_recipe_divider.add_theme_stylebox_override("separator", div_style.duplicate())

	# Vertical divider
	var vdiv_style := StyleBoxFlat.new()
	vdiv_style.bg_color = Color(COLOR_NEUTRAL, 0.3)
	vdiv_style.set_content_margin_all(0)
	_vertical_divider.add_theme_stylebox_override("separator", vdiv_style)

	# Progress bar
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = COLOR_BAR_BG
	bar_bg.set_corner_radius_all(4)
	_progress_bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = COLOR_TEAL
	bar_fill.set_corner_radius_all(4)
	_progress_bar.add_theme_stylebox_override("fill", bar_fill)

	# Buttons
	_style_button(_start_button, COLOR_TEAL)
	_style_close_button(_close_button)

func _populate_recipe_list() -> void:
	# Recipe rows are dynamic (data-driven) — built at runtime from FabricatorDefs
	var last_category: String = ""
	for i: int in range(_recipe_ids.size()):
		var recipe_id: String = _recipe_ids[i]
		var category: String = RECIPE_CATEGORIES.get(recipe_id, "OTHER")

		if category != last_category:
			var cat_label := Label.new()
			cat_label.text = category
			cat_label.add_theme_font_size_override("font_size", 14)
			cat_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
			_recipe_list_container.add_child(cat_label)
			last_category = category

		var row := _build_recipe_row(recipe_id)
		_recipe_list_container.add_child(row)

func _build_recipe_row(recipe_id: String) -> PanelContainer:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 56)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color.TRANSPARENT
	row_style.set_content_margin_all(8)
	row.add_theme_stylebox_override("panel", row_style)

	var row_index: int = _recipe_rows.size()
	row.mouse_entered.connect(_on_recipe_row_mouse_entered.bind(row_index))
	row.gui_input.connect(_on_recipe_row_gui_input.bind(row_index))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(hbox)

	var indicator := ColorRect.new()
	indicator.custom_minimum_size = Vector2(4, 40)
	indicator.color = Color.TRANSPARENT
	hbox.add_child(indicator)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var recipe_icon_path: String = FabricatorDefs.get_icon_path(recipe_id)
	if not recipe_icon_path.is_empty():
		icon.texture = load(recipe_icon_path) as Texture2D
	hbox.add_child(icon)

	var text_vbox := VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 2)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var name_label := Label.new()
	name_label.text = FabricatorDefs.get_recipe_name(recipe_id)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	text_vbox.add_child(name_label)

	var inputs: Array[Dictionary] = FabricatorDefs.get_inputs(recipe_id)
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

	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(12, 12)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(dot)

	_set_descendants_mouse_ignore(row)
	row.mouse_filter = Control.MOUSE_FILTER_STOP

	_recipe_rows.append(row)
	_recipe_row_labels.append(name_label)
	_recipe_row_indicators.append(indicator)
	_recipe_row_dots.append(dot)

	return row

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

func _connect_signals() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_close_button.pressed.connect(close)
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

		var is_selected: bool = i == _selected_index
		indicator.color = COLOR_TEAL if is_selected else Color.TRANSPARENT

		var row_style: StyleBoxFlat = row.get_theme_stylebox("panel") as StyleBoxFlat
		if is_selected:
			row_style.bg_color = Color(COLOR_SLOT_BG, 0.8)
			name_label.add_theme_color_override("font_color", COLOR_TEAL)
		else:
			row_style.bg_color = Color.TRANSPARENT
			name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)

		if is_processing:
			row.modulate = Color(1, 1, 1, 0.4)
		else:
			row.modulate = Color.WHITE

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

	var recipe_changed: bool = recipe_id != _last_detail_recipe_id
	if recipe_changed:
		_last_detail_recipe_id = recipe_id
		_cached_input_tex = null
		_cached_output_tex = null

	# Input slot
	var inputs: Array[Dictionary] = FabricatorDefs.get_inputs(recipe_id)
	if inputs.size() > 0:
		var input: Dictionary = inputs[0]
		var resource_type: ResourceDefs.ResourceType = input.get("resource_type", ResourceDefs.ResourceType.NONE) as ResourceDefs.ResourceType
		var quantity: int = input.get("quantity", 0) as int
		var resource_name: String = ResourceDefs.get_resource_name(resource_type)
		var available: int = PlayerInventory.get_total_count(resource_type)

		_input_slot_icon.visible = true
		if recipe_changed:
			var input_icon_path: String = ResourceDefs.get_icon_path(resource_type)
			if not input_icon_path.is_empty():
				_cached_input_tex = load(input_icon_path) as Texture2D
		if _cached_input_tex:
			_input_slot_icon.texture = _cached_input_tex
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
		if recipe_changed:
			var out_icon_path: String = ResourceDefs.get_icon_path(out_type)
			if not out_icon_path.is_empty():
				_cached_output_tex = load(out_icon_path) as Texture2D
		if _cached_output_tex:
			_output_slot_icon.texture = _cached_output_tex
		_output_slot_label.visible = true
		_output_slot_label.text = "x%d" % out_qty
		_output_desc_label.text = ResourceDefs.get_resource_name(out_type)
	elif output_mode == FabricatorDefs.OUTPUT_MODE_EQUIP_HEAD_LAMP:
		_output_slot_icon.visible = true
		if recipe_changed:
			var lamp_icon_path: String = FabricatorDefs.get_icon_path(recipe_id)
			if not lamp_icon_path.is_empty():
				_cached_output_tex = load(lamp_icon_path) as Texture2D
		if _cached_output_tex:
			_output_slot_icon.texture = _cached_output_tex
		_output_slot_label.visible = false
		_output_desc_label.text = "Head Lamp (Equip)"
	else:
		_output_slot_icon.visible = false
		_output_slot_label.visible = false
		_output_desc_label.text = ""

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
	var inputs: Array[Dictionary] = FabricatorDefs.get_inputs(recipe_id)
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

func _set_descendants_mouse_ignore(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_descendants_mouse_ignore(child)

func _on_recipe_row_mouse_entered(index: int) -> void:
	if not _is_open:
		return
	select_recipe_by_index(index)

func _on_recipe_row_gui_input(event: InputEvent, index: int) -> void:
	if not _is_open:
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null:
		return
	if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		select_recipe_by_index(index)

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
