## Recycler interaction panel: queue Scrap Metal to Metal jobs, monitor progress, collect output.
## Opens when player interacts with an installed Recycler module inside the ship.
class_name RecyclerPanel
extends CanvasLayer

# ── Signals ──────────────────────────────────────────────
signal closed

# ── Constants ─────────────────────────────────────────────
const PANEL_WIDTH: float = 480.0
const PANEL_HEIGHT: float = 400.0
const SLOT_SIZE: float = 72.0

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
const COLOR_BAR_BG := Color("#1A2736")
const COLOR_DIM := Color("#000000", 0.5)

# ── Private Variables ─────────────────────────────────────
var _is_open: bool = false
var _dim_rect: ColorRect = null
var _main_panel: PanelContainer = null
var _input_slot_icon: TextureRect = null
var _input_slot_label: Label = null
var _output_slot_icon: TextureRect = null
var _output_slot_label: Label = null
var _progress_bar: ProgressBar = null
var _progress_label: Label = null
var _start_button: Button = null
var _collect_button: Button = null
var _status_label: Label = null
var _feedback_label: Label = null
var _available_label: Label = null
var _input_icon_tex: Texture2D = null
var _output_icon_tex: Texture2D = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	layer = 3
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = false
	_build_ui()
	_connect_signals()

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

# ── Public Methods ────────────────────────────────────────

## Opens the recycler interaction panel.
func open() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	_refresh_ui()
	InputManager.set_gameplay_inputs_enabled(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_animate_open()
	Global.log("RecyclerPanel: opened")

## Closes the recycler panel without interrupting active jobs.
func close() -> void:
	if not _is_open:
		return
	_is_open = false
	InputManager.set_gameplay_inputs_enabled(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_animate_close()
	closed.emit()
	Global.log("RecyclerPanel: closed")

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

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_main_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "RECYCLER"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Status label
	_status_label = Label.new()
	_status_label.text = "Ready"
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_status_label)

	# Divider
	_add_divider(vbox)

	# Slot row: Input → Arrow → Output
	var slot_row := _build_slot_row()
	vbox.add_child(slot_row)

	# Recipe label
	var recipe_label := Label.new()
	recipe_label.text = "%d Scrap Metal → %d Metal (%.0fs)" % [
		Recycler.RECIPE_INPUT_QUANTITY,
		Recycler.RECIPE_OUTPUT_QUANTITY,
		Recycler.PROCESSING_TIME,
	]
	recipe_label.add_theme_font_size_override("font_size", 16)
	recipe_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	recipe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(recipe_label)

	# Progress section
	var progress_section := _build_progress_section()
	vbox.add_child(progress_section)

	# Button row
	var button_row := _build_button_row()
	vbox.add_child(button_row)

	# Feedback label
	_feedback_label = Label.new()
	_feedback_label.add_theme_font_size_override("font_size", 16)
	_feedback_label.add_theme_color_override("font_color", COLOR_CORAL)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_feedback_label)

	# Available resources label
	_available_label = Label.new()
	_available_label.add_theme_font_size_override("font_size", 14)
	_available_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_available_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_available_label)

	# Footer row: instructions + close button
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 16)
	vbox.add_child(footer)

	var instructions := Label.new()
	instructions.text = "[Esc] Close"
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	footer.add_child(instructions)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(80, 32)
	close_button.add_theme_font_size_override("font_size", 14)
	_style_button(close_button, COLOR_NEUTRAL)
	close_button.pressed.connect(close)
	footer.add_child(close_button)

	# Cache slot icon textures (resource types are constants, textures never change)
	var input_icon_path: String = ResourceDefs.get_icon_path(Recycler.RECIPE_INPUT_TYPE)
	if not input_icon_path.is_empty():
		_input_icon_tex = load(input_icon_path) as Texture2D
	var output_icon_path: String = ResourceDefs.get_icon_path(Recycler.RECIPE_OUTPUT_TYPE)
	if not output_icon_path.is_empty():
		_output_icon_tex = load(output_icon_path) as Texture2D

func _build_slot_row() -> CenterContainer:
	var center := CenterContainer.new()

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	center.add_child(hbox)

	# Input slot
	var input_container := _create_labeled_slot("INPUT")
	hbox.add_child(input_container)
	_input_slot_icon = input_container.get_meta("icon") as TextureRect
	_input_slot_label = input_container.get_meta("label") as Label

	# Arrow
	var arrow := Label.new()
	arrow.text = "→"
	arrow.add_theme_font_size_override("font_size", 32)
	arrow.add_theme_color_override("font_color", COLOR_TEAL)
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(arrow)

	# Output slot
	var output_container := _create_labeled_slot("OUTPUT")
	hbox.add_child(output_container)
	_output_slot_icon = output_container.get_meta("icon") as TextureRect
	_output_slot_label = output_container.get_meta("label") as Label

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

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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

	# Store references as metadata on the container
	container.set_meta("icon", icon)
	container.set_meta("label", count_label)

	return container

func _build_progress_section() -> VBoxContainer:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 16)
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

func _build_button_row() -> CenterContainer:
	var center := CenterContainer.new()

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	center.add_child(hbox)

	# Start button
	_start_button = Button.new()
	_start_button.text = "START"
	_start_button.custom_minimum_size = Vector2(140, 40)
	_start_button.add_theme_font_size_override("font_size", 20)
	_style_button(_start_button, COLOR_TEAL)
	_start_button.pressed.connect(_on_start_pressed)
	hbox.add_child(_start_button)

	# Collect button
	_collect_button = Button.new()
	_collect_button.text = "COLLECT"
	_collect_button.custom_minimum_size = Vector2(140, 40)
	_collect_button.add_theme_font_size_override("font_size", 20)
	_style_button(_collect_button, COLOR_AMBER)
	_collect_button.pressed.connect(_on_collect_pressed)
	hbox.add_child(_collect_button)

	return center

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

func _connect_signals() -> void:
	Recycler.job_started.connect(_on_job_started)
	Recycler.job_progress_changed.connect(_on_job_progress)
	Recycler.job_completed.connect(_on_job_completed)
	Recycler.job_cancelled.connect(_on_job_cancelled)

func _refresh_ui() -> void:
	_feedback_label.text = ""

	# Update available resources
	var scrap_count: int = PlayerInventory.get_total_count(Recycler.RECIPE_INPUT_TYPE)
	_available_label.text = "Scrap Metal available: %d" % scrap_count

	# Update input slot
	var has_input: bool = Recycler.is_job_active() or scrap_count >= Recycler.RECIPE_INPUT_QUANTITY
	_input_slot_icon.visible = has_input
	if _input_icon_tex:
		_input_slot_icon.texture = _input_icon_tex
	_input_slot_label.visible = has_input
	_input_slot_label.text = "x%d" % Recycler.RECIPE_INPUT_QUANTITY

	# Update output slot
	var has_output: bool = Recycler.has_uncollected_output()
	_output_slot_icon.visible = has_output
	if _output_icon_tex:
		_output_slot_icon.texture = _output_icon_tex
	_output_slot_label.visible = has_output
	_output_slot_label.text = "x%d" % Recycler.get_pending_output_quantity()

	# Update progress bar and status
	if Recycler.is_job_active():
		var progress: float = Recycler.get_job_progress()
		_progress_bar.value = progress
		var time_remaining: float = Recycler.PROCESSING_TIME * (1.0 - progress)
		_progress_label.text = "Processing... %.1fs remaining" % time_remaining
		_status_label.text = "Processing"
		_status_label.add_theme_color_override("font_color", COLOR_TEAL)
	elif has_output:
		_progress_bar.value = 1.0
		_progress_label.text = "Complete — collect output"
		_status_label.text = "Output Ready"
		_status_label.add_theme_color_override("font_color", COLOR_AMBER)
	else:
		_progress_bar.value = 0.0
		_progress_label.text = ""
		_status_label.text = "Ready"
		_status_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)

	# Update button states
	var can_start: bool = not Recycler.is_job_active() and not has_output and scrap_count >= Recycler.RECIPE_INPUT_QUANTITY
	_start_button.disabled = not can_start
	_collect_button.disabled = not has_output

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
	var success: bool = Recycler.start_job()
	if success:
		_feedback_label.text = ""
	else:
		var scrap_count: int = PlayerInventory.get_total_count(Recycler.RECIPE_INPUT_TYPE)
		if scrap_count < Recycler.RECIPE_INPUT_QUANTITY:
			_feedback_label.text = "Not enough Scrap Metal (need %d)" % Recycler.RECIPE_INPUT_QUANTITY
		elif Recycler.has_uncollected_output():
			_feedback_label.text = "Collect output before starting"
		else:
			_feedback_label.text = "Cannot start job"
		_feedback_label.add_theme_color_override("font_color", COLOR_CORAL)
	_refresh_ui()

func _on_collect_pressed() -> void:
	var collected: int = Recycler.collect_output()
	if collected > 0:
		_feedback_label.text = "Collected %d Metal" % collected
		_feedback_label.add_theme_color_override("font_color", COLOR_TEAL)
	else:
		_feedback_label.text = "Inventory full"
		_feedback_label.add_theme_color_override("font_color", COLOR_CORAL)
	_refresh_ui()

func _on_job_started(_input_type: ResourceDefs.ResourceType, _output_type: ResourceDefs.ResourceType) -> void:
	if _is_open:
		_refresh_ui()

func _on_job_progress(progress: float) -> void:
	if _is_open:
		_progress_bar.value = progress
		var time_remaining: float = Recycler.PROCESSING_TIME * (1.0 - progress)
		_progress_label.text = "Processing... %.1fs remaining" % time_remaining

func _on_job_completed(_output_type: ResourceDefs.ResourceType, _output_quantity: int) -> void:
	if _is_open:
		_refresh_ui()

func _on_job_cancelled() -> void:
	if _is_open:
		_refresh_ui()
