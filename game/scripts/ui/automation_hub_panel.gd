## Automation Hub interaction panel: configure drone programs, deploy/recall drones, monitor status.
## Opens when the player interacts with an installed Automation Hub module inside the ship.
class_name AutomationHubPanel
extends CanvasLayer

# ── Signals ──────────────────────────────────────────────
signal closed
signal drone_deployed(drone_id: int, program: DroneProgram)
signal drones_recalled

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
const COLOR_PANEL_BG := Color("#0F1923", 0.85)

## Drone state colors
const COLOR_IDLE := Color("#94A3B8")
const COLOR_TRAVELING := Color("#FFB830")
const COLOR_EXTRACTING := Color("#00D4AA")
const COLOR_RETURNING := Color("#4ADE80")

## Filter defaults
const RADIUS_MIN: float = 50.0
const RADIUS_MAX: float = 500.0
const RADIUS_STEP: float = 25.0
const REFRESH_INTERVAL: float = 0.5

## Priority options
const PRIORITY_OPTIONS: Array[String] = ["Highest Purity First", "Nearest First", "Highest Density First"]

# ── Private Variables ─────────────────────────────────────
var _is_open: bool = false
var _drones_active: bool = false
var _refresh_timer: float = 0.0

## Filter state
var _deposit_type_index: int = 0
var _deposit_type_options: Array[int] = []  # ResourceType enum values
var _min_purity: int = 1
var _tool_tier: int = 1
var _extraction_radius: float = 200.0
var _priority_index: int = 0

## Hub/ship position for distance calculations
var _hub_position: Vector3 = Vector3.ZERO

## Focus tracking
var _focused_row: int = 0
const FOCUS_ROW_COUNT: int = 6  # 5 filters + activate button

# ── Onready Variables ─────────────────────────────────────
@onready var _dim_rect: ColorRect = %DimRect
@onready var _main_panel: PanelContainer = %MainPanel
@onready var _config_container: VBoxContainer = %ConfigColumn
@onready var _deposit_type_label: Label = %DepositTypeLabel
@onready var _purity_label: Label = %PurityLabel
@onready var _tool_tier_label: Label = %ToolTierLabel
@onready var _radius_slider: HSlider = %RadiusSlider
@onready var _radius_value_label: Label = %RadiusValueLabel
@onready var _priority_label: Label = %PriorityLabel
@onready var _pool_stats_label: Label = %PoolStatsLabel
@onready var _activate_button: Button = %ActivateButton
@onready var _active_drones_label: Label = %ActiveDronesLabel
@onready var _drone_status_container: VBoxContainer = %DroneStatusContainer
@onready var _deactivate_button: Button = %DeactivateButton
@onready var _close_button: Button = %CloseButton
@onready var _title_divider: HSeparator = %TitleDivider
@onready var _status_divider: HSeparator = %StatusDivider
@onready var _vertical_divider: VSeparator = %VerticalDivider

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_apply_styles()
	_connect_signals()

func _process(delta: float) -> void:
	if not _is_open:
		return
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_INTERVAL:
		_refresh_timer = 0.0
		_refresh_drone_status()

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return

	if _drones_active:
		# When drones are active, only allow closing or deactivating
		if event.is_action_pressed("ui_accept"):
			_on_deactivate_pressed()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_down"):
		_focused_row = mini(_focused_row + 1, FOCUS_ROW_COUNT - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_focused_row = maxi(_focused_row - 1, 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_adjust_filter(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_adjust_filter(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if _focused_row == FOCUS_ROW_COUNT - 1:
			_on_activate_pressed()
		get_viewport().set_input_as_handled()

# ── Public Methods ────────────────────────────────────────

## Opens the automation hub panel.
func open() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	_focused_row = 0
	_refresh_timer = 0.0
	_build_deposit_type_options()
	_refresh_all()
	InputManager.set_gameplay_inputs_enabled(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_animate_open()
	Global.debug_log("AutomationHubPanel: opened")

## Closes the panel.
func close() -> void:
	if not _is_open:
		return
	_is_open = false
	InputManager.set_gameplay_inputs_enabled(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_animate_close()
	closed.emit()
	Global.debug_log("AutomationHubPanel: closed")

## Returns true if the panel is open.
func is_open() -> bool:
	return _is_open

## Sets the hub/ship position used for deposit distance calculations.
func setup(hub_position: Vector3) -> void:
	_hub_position = hub_position

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

	# Dividers
	var div_style := StyleBoxFlat.new()
	div_style.bg_color = Color(COLOR_NEUTRAL, 0.4)
	div_style.set_content_margin_all(0)
	_title_divider.add_theme_stylebox_override("separator", div_style)
	var status_div_style: StyleBoxFlat = div_style.duplicate() as StyleBoxFlat
	_status_divider.add_theme_stylebox_override("separator", status_div_style)

	# Vertical divider
	var vdiv_style := StyleBoxFlat.new()
	vdiv_style.bg_color = Color(COLOR_NEUTRAL, 0.3)
	vdiv_style.set_content_margin_all(0)
	_vertical_divider.add_theme_stylebox_override("separator", vdiv_style)

	# Buttons
	_style_button(_activate_button, COLOR_TEAL)
	_style_button(_deactivate_button, COLOR_CORAL)
	_style_close_button(_close_button)

func _connect_signals() -> void:
	_activate_button.pressed.connect(_on_activate_pressed)
	_deactivate_button.pressed.connect(_on_deactivate_pressed)
	_close_button.pressed.connect(close)
	_radius_slider.value_changed.connect(_on_radius_changed)
	AutomationHub.drone_started.connect(_on_drone_started)
	AutomationHub.drone_completed.connect(_on_drone_completed)
	AutomationHub.drone_returned.connect(_on_drone_returned)

func _build_deposit_type_options() -> void:
	_deposit_type_options.clear()
	_deposit_type_options.append(ResourceDefs.ResourceType.NONE)  # "Any" option

	# Gather unique analyzed resource types from deposit registry
	var seen_types: Dictionary = {}
	var deposits: Array[Deposit] = DepositRegistry.get_all()
	for deposit: Deposit in deposits:
		if deposit.is_analyzed() and not deposit.is_depleted():
			var rt: int = deposit.resource_type
			if not seen_types.has(rt):
				seen_types[rt] = true
				_deposit_type_options.append(rt)

	_deposit_type_index = 0

func _refresh_all() -> void:
	_drones_active = AutomationHub.get_active_drone_count() > 0
	_refresh_filters()
	_refresh_pool_stats()
	_refresh_drone_status()
	_refresh_buttons()
	_update_config_lock()

func _refresh_filters() -> void:
	# Deposit type
	if _deposit_type_index < _deposit_type_options.size():
		var type_value: int = _deposit_type_options[_deposit_type_index]
		if type_value == ResourceDefs.ResourceType.NONE:
			_deposit_type_label.text = "Any"
		else:
			_deposit_type_label.text = ResourceDefs.get_resource_name(type_value as ResourceDefs.ResourceType)
	else:
		_deposit_type_label.text = "No analyzed deposits"

	# Purity
	var star_text: String = ""
	for i: int in range(5):
		star_text += "*" if i < _min_purity else "-"
	_purity_label.text = "%s  %d-Star min" % [star_text, _min_purity]

	# Tool tier
	var tier_enum: ResourceDefs.DepositTier = _tool_tier as ResourceDefs.DepositTier
	_tool_tier_label.text = ResourceDefs.DEPOSIT_TIER_NAMES.get(tier_enum, "Tier %d" % _tool_tier) as String

	# Radius
	_radius_value_label.text = "%dm" % int(_extraction_radius)
	_radius_slider.value = _extraction_radius

	# Priority
	_priority_label.text = PRIORITY_OPTIONS[_priority_index]

func _refresh_pool_stats() -> void:
	var analyzed_count: int = 0
	var matching_count: int = 0
	var program: DroneProgram = _build_program()
	var deposits: Array[Deposit] = DepositRegistry.get_all()

	for deposit: Deposit in deposits:
		if deposit.is_analyzed() and not deposit.is_depleted():
			analyzed_count += 1
			if program.accepts_deposit(deposit):
				var dist: float = _hub_position.distance_to(deposit.global_position)
				if dist <= _extraction_radius:
					matching_count += 1

	_pool_stats_label.text = "Analyzed Deposits: %d  |  Matching Program: %d" % [analyzed_count, matching_count]
	if matching_count > 0:
		_pool_stats_label.add_theme_color_override("font_color", COLOR_TEAL)
	else:
		_pool_stats_label.add_theme_color_override("font_color", COLOR_AMBER)

	_activate_button.disabled = matching_count == 0

func _refresh_drone_status() -> void:
	# Clear existing cards
	for child: Node in _drone_status_container.get_children():
		child.queue_free()

	var status_list: Array[Dictionary] = AutomationHub.get_drone_status_list()
	var active_count: int = status_list.size()
	var max_drones: int = AutomationHub.get_max_drones()
	_active_drones_label.text = "ACTIVE DRONES (%d/%d)" % [active_count, max_drones]

	if active_count == 0:
		var empty_label := Label.new()
		empty_label.text = "No active drones."
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		_drone_status_container.add_child(empty_label)
	else:
		for status: Dictionary in status_list:
			var card := _build_drone_card(status)
			_drone_status_container.add_child(card)

	_deactivate_button.visible = active_count > 0

func _build_drone_card(status: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL_BG
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Header row: drone icon + drone name + state text
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var drone_icon := TextureRect.new()
	drone_icon.custom_minimum_size = Vector2(20, 20)
	drone_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drone_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var drone_tex: Texture2D = load("res://assets/icons/hud/icon_hud_drone.svg") as Texture2D
	if drone_tex:
		drone_icon.texture = drone_tex
	var state_name: String = status.get("state", "IDLE") as String
	match state_name:
		"IDLE":
			drone_icon.modulate = COLOR_IDLE
		"TRAVELING":
			drone_icon.modulate = COLOR_TRAVELING
		"EXTRACTING":
			drone_icon.modulate = COLOR_EXTRACTING
		"RETURNING":
			drone_icon.modulate = COLOR_RETURNING
		_:
			drone_icon.modulate = COLOR_IDLE
	header.add_child(drone_icon)

	var drone_id: int = status.get("drone_id", 0) as int
	var name_label := Label.new()
	name_label.text = "Drone %d" % drone_id
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var state_label := Label.new()
	state_label.text = state_name.capitalize()
	state_label.add_theme_font_size_override("font_size", 14)
	state_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	header.add_child(state_label)

	# Target info
	var target: String = status.get("target_deposit_id", "") as String
	if not target.is_empty():
		var target_label := Label.new()
		target_label.text = "  Target: %s" % target
		target_label.add_theme_font_size_override("font_size", 12)
		target_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		vbox.add_child(target_label)

	return card

func _refresh_buttons() -> void:
	if _drones_active:
		_activate_button.text = "Program Running..."
		_activate_button.disabled = true
	else:
		_activate_button.text = "ACTIVATE DRONES"

func _update_config_lock() -> void:
	if _drones_active:
		_config_container.modulate = Color(1, 1, 1, 0.4)
	else:
		_config_container.modulate = Color.WHITE

func _adjust_filter(direction: int) -> void:
	match _focused_row:
		0:  # Deposit type
			if _deposit_type_options.size() > 0:
				_deposit_type_index = wrapi(_deposit_type_index + direction, 0, _deposit_type_options.size())
		1:  # Min purity
			_min_purity = clampi(_min_purity + direction, 1, 5)
		2:  # Tool tier
			_tool_tier = clampi(_tool_tier + direction, 1, 4)
		3:  # Radius
			_extraction_radius = clampf(_extraction_radius + RADIUS_STEP * direction, RADIUS_MIN, RADIUS_MAX)
		4:  # Priority
			_priority_index = wrapi(_priority_index + direction, 0, PRIORITY_OPTIONS.size())
	_refresh_filters()
	_refresh_pool_stats()

func _build_program() -> DroneProgram:
	var program := DroneProgram.new()
	if _deposit_type_index < _deposit_type_options.size():
		program.target_resource_type = _deposit_type_options[_deposit_type_index] as ResourceDefs.ResourceType
	program.minimum_purity = _min_purity as ResourceDefs.Purity
	program.tool_tier_assignment = _tool_tier as ResourceDefs.DepositTier
	program.extraction_radius = _extraction_radius
	program.priority_order = _priority_index
	return program

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

func _on_radius_changed(value: float) -> void:
	_extraction_radius = value
	_radius_value_label.text = "%dm" % int(value)
	_refresh_pool_stats()

# ── Signal Handlers ──────────────────────────────────────

func _on_activate_pressed() -> void:
	if _drones_active:
		return
	var program: DroneProgram = _build_program()
	var max_drones: int = AutomationHub.get_max_drones()
	var deployed_count: int = 0

	for _i: int in range(max_drones):
		var drone_id: int = AutomationHub.deploy_drone(program)
		if drone_id >= 0:
			drone_deployed.emit(drone_id, program)
			deployed_count += 1
		else:
			break

	if deployed_count > 0:
		_drones_active = true
		Global.debug_log("AutomationHubPanel: deployed %d drones" % deployed_count)
	_refresh_all()

func _on_deactivate_pressed() -> void:
	if not _drones_active:
		return
	var status_list: Array[Dictionary] = AutomationHub.get_drone_status_list()
	for status: Dictionary in status_list:
		var drone_id: int = status.get("drone_id", -1) as int
		if drone_id >= 0:
			AutomationHub.recall_drone(drone_id)
	drones_recalled.emit()
	_drones_active = false
	Global.debug_log("AutomationHubPanel: recalled all drones")
	_refresh_all()

func _on_drone_started(_deposit_id: String) -> void:
	if _is_open:
		_refresh_drone_status()

func _on_drone_completed(_deposit_id: String, _yield_quantity: int) -> void:
	if _is_open:
		_refresh_drone_status()

func _on_drone_returned() -> void:
	if _is_open:
		_drones_active = AutomationHub.get_active_drone_count() > 0
		_refresh_all()
