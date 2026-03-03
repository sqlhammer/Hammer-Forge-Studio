## Recycler interaction panel: queue Scrap Metal to Metal jobs, monitor progress, collect output.
## Opens when player interacts with an installed Recycler module inside the ship.
class_name RecyclerPanel
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
const COLOR_TEXT_PRIMARY := Color("#F1F5F9")
const COLOR_TEXT_SECONDARY := Color("#94A3B8")
const COLOR_NEUTRAL := Color("#94A3B8")
const COLOR_SLOT_BG := Color("#1A2736", 0.8)
const COLOR_BAR_BG := Color("#1A2736")

# ── Private Variables ─────────────────────────────────────
var _is_open: bool = false
var _input_icon_tex: Texture2D = null
var _output_icon_tex: Texture2D = null

# ── Onready Variables ─────────────────────────────────────
@onready var _dim_rect: ColorRect = %DimRect
@onready var _main_panel: PanelContainer = %MainPanel
@onready var _input_slot: PanelContainer = %InputSlot
@onready var _input_slot_icon: TextureRect = %InputIcon
@onready var _input_slot_label: Label = %InputCountLabel
@onready var _output_slot: PanelContainer = %OutputSlot
@onready var _output_slot_icon: TextureRect = %OutputIcon
@onready var _output_slot_label: Label = %OutputCountLabel
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _progress_label: Label = %ProgressLabel
@onready var _start_button: Button = %StartButton
@onready var _collect_button: Button = %CollectButton
@onready var _status_label: Label = %StatusLabel
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _available_label: Label = %AvailableLabel
@onready var _recipe_label: Label = %RecipeLabel
@onready var _close_button: Button = %CloseButton
@onready var _divider: HSeparator = %Divider

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_apply_styles()
	_connect_signals()
	_recipe_label.text = "%d Scrap Metal → %d Metal (%.0fs)" % [
		Recycler.RECIPE_INPUT_QUANTITY,
		Recycler.RECIPE_OUTPUT_QUANTITY,
		Recycler.PROCESSING_TIME,
	]
	var input_icon_path: String = ResourceDefs.get_icon_path(Recycler.RECIPE_INPUT_TYPE)
	if not input_icon_path.is_empty():
		_input_icon_tex = load(input_icon_path) as Texture2D
	var output_icon_path: String = ResourceDefs.get_icon_path(Recycler.RECIPE_OUTPUT_TYPE)
	if not output_icon_path.is_empty():
		_output_icon_tex = load(output_icon_path) as Texture2D

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
	Global.debug_log("RecyclerPanel: opened")

## Closes the recycler panel without interrupting active jobs.
func close() -> void:
	if not _is_open:
		return
	_is_open = false
	InputManager.set_gameplay_inputs_enabled(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_animate_close()
	closed.emit()
	Global.debug_log("RecyclerPanel: closed")

## Returns true if the panel is open.
func is_open() -> bool:
	return _is_open

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

	# Divider
	var div_style := StyleBoxFlat.new()
	div_style.bg_color = Color(COLOR_NEUTRAL, 0.4)
	div_style.set_content_margin_all(0)
	_divider.add_theme_stylebox_override("separator", div_style)

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
	_style_button(_collect_button, COLOR_AMBER)
	_style_button(_close_button, COLOR_NEUTRAL)

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

func _connect_signals() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_collect_button.pressed.connect(_on_collect_pressed)
	_close_button.pressed.connect(close)
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
