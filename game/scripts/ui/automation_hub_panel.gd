## Automation Hub interaction panel: configure drone programs, deploy/recall drones, monitor status.
## Opens when the player interacts with an installed Automation Hub module inside the ship.
class_name AutomationHubPanel
extends CanvasLayer

# ── Signals ──────────────────────────────────────────────
signal closed
signal drone_deployed(drone_id: int, program: DroneProgram)
signal drones_recalled

# ── Constants ─────────────────────────────────────────────
const PANEL_WIDTH: float = 900.0
const PANEL_HEIGHT: float = 620.0
const CONFIG_WIDTH: float = 520.0
const STATUS_WIDTH: float = 340.0
const FILTER_ROW_HEIGHT: float = 56.0

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
const COLOR_DIM := Color("#000000", 0.5)
const COLOR_PANEL_BG := Color("#0F1923", 0.85)
const COLOR_CONTROL_BG := Color("#1A2736", 0.9)

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
var _dim_rect: ColorRect = null
var _main_panel: PanelContainer = null
var _drones_active: bool = false
var _refresh_timer: float = 0.0

## Filter state
var _deposit_type_index: int = 0
var _deposit_type_options: Array[int] = []  # ResourceType enum values
var _min_purity: int = 1
var _tool_tier: int = 1
var _extraction_radius: float = 200.0
var _priority_index: int = 0

## Config column elements
var _deposit_type_label: Label = null
var _purity_label: Label = null
var _purity_stars_label: Label = null
var _tool_tier_label: Label = null
var _radius_slider: HSlider = null
var _radius_value_label: Label = null
var _priority_label: Label = null
var _pool_stats_label: Label = null
var _activate_button: Button = null
var _config_container: VBoxContainer = null

## Status column elements
var _drone_status_container: VBoxContainer = null
var _active_drones_label: Label = null
var _deactivate_button: Button = null

## Hub/ship position for distance calculations
var _hub_position: Vector3 = Vector3.ZERO

## Focus tracking
var _focused_row: int = 0
const FOCUS_ROW_COUNT: int = 6  # 5 filters + activate button

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	layer = 2
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = false
	_build_ui()
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
	Global.log("AutomationHubPanel: opened")

## Closes the panel.
func close() -> void:
	if not _is_open:
		return
	_is_open = false
	InputManager.set_gameplay_inputs_enabled(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_animate_close()
	closed.emit()
	Global.log("AutomationHubPanel: closed")

## Returns true if the panel is open.
func is_open() -> bool:
	return _is_open

## Sets the hub/ship position used for deposit distance calculations.
func setup(hub_position: Vector3) -> void:
	_hub_position = hub_position

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
	title.text = "AUTOMATION HUB"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer_vbox.add_child(title)

	_add_divider(outer_vbox)

	# HBox: config (left) + status (right)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	outer_vbox.add_child(hbox)

	# Left column: program config
	_config_container = _build_config_column()
	hbox.add_child(_config_container)

	# Vertical divider
	var v_divider := VSeparator.new()
	var vdiv_style := StyleBoxFlat.new()
	vdiv_style.bg_color = Color(COLOR_NEUTRAL, 0.3)
	vdiv_style.set_content_margin_all(0)
	v_divider.add_theme_stylebox_override("separator", vdiv_style)
	hbox.add_child(v_divider)

	# Right column: drone status
	var right_col := _build_status_column()
	hbox.add_child(right_col)

	# Footer row: instructions + close button
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 16)
	outer_vbox.add_child(footer)

	var instructions := Label.new()
	instructions.text = "[Up/Down] Navigate  [Left/Right] Adjust  [Enter] Activate  [Esc] Close"
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	footer.add_child(instructions)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(80, 32)
	close_button.add_theme_font_size_override("font_size", 14)
	_style_close_button(close_button)
	close_button.pressed.connect(close)
	footer.add_child(close_button)

func _build_config_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(CONFIG_WIDTH, 0)
	col.add_theme_constant_override("separation", 8)

	var header := Label.new()
	header.text = "DRONE PROGRAM"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	col.add_child(header)

	# Row 0: Deposit Type
	var type_row := _build_filter_row("TARGET: DEPOSIT TYPE")
	col.add_child(type_row)
	_deposit_type_label = type_row.get_meta("value_label") as Label

	# Row 1: Min Purity
	var purity_row := _build_filter_row("MIN PURITY")
	col.add_child(purity_row)
	_purity_label = purity_row.get_meta("value_label") as Label

	# Row 2: Tool Tier
	var tier_row := _build_filter_row("TOOL TIER")
	col.add_child(tier_row)
	_tool_tier_label = tier_row.get_meta("value_label") as Label

	# Row 3: Extraction Radius
	var radius_row := _build_radius_row()
	col.add_child(radius_row)

	# Row 4: Priority
	var priority_row := _build_filter_row("PRIORITY")
	col.add_child(priority_row)
	_priority_label = priority_row.get_meta("value_label") as Label

	# Pool stats
	_pool_stats_label = Label.new()
	_pool_stats_label.add_theme_font_size_override("font_size", 14)
	_pool_stats_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	col.add_child(_pool_stats_label)

	# Activate button (Row 5)
	_activate_button = Button.new()
	_activate_button.text = "ACTIVATE DRONES"
	_activate_button.custom_minimum_size = Vector2(0, 48)
	_activate_button.add_theme_font_size_override("font_size", 18)
	_style_button(_activate_button, COLOR_TEAL)
	_activate_button.pressed.connect(_on_activate_pressed)
	col.add_child(_activate_button)

	return col

func _build_filter_row(label_text: String) -> VBoxContainer:
	var row := VBoxContainer.new()
	row.custom_minimum_size = Vector2(0, FILTER_ROW_HEIGHT)
	row.add_theme_constant_override("separation", 4)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	row.add_child(label)

	var control_hbox := HBoxContainer.new()
	control_hbox.add_theme_constant_override("separation", 8)
	row.add_child(control_hbox)

	var left_arrow := Label.new()
	left_arrow.text = "<"
	left_arrow.add_theme_font_size_override("font_size", 20)
	left_arrow.add_theme_color_override("font_color", COLOR_TEAL)
	control_hbox.add_child(left_arrow)

	var value_label := Label.new()
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", COLOR_TEAL)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control_hbox.add_child(value_label)

	var right_arrow := Label.new()
	right_arrow.text = ">"
	right_arrow.add_theme_font_size_override("font_size", 20)
	right_arrow.add_theme_color_override("font_color", COLOR_TEAL)
	control_hbox.add_child(right_arrow)

	row.set_meta("value_label", value_label)

	return row

func _build_radius_row() -> VBoxContainer:
	var row := VBoxContainer.new()
	row.custom_minimum_size = Vector2(0, FILTER_ROW_HEIGHT)
	row.add_theme_constant_override("separation", 4)

	var label := Label.new()
	label.text = "EXTRACTION RADIUS"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	row.add_child(label)

	var control_hbox := HBoxContainer.new()
	control_hbox.add_theme_constant_override("separation", 8)
	row.add_child(control_hbox)

	_radius_slider = HSlider.new()
	_radius_slider.min_value = RADIUS_MIN
	_radius_slider.max_value = RADIUS_MAX
	_radius_slider.step = RADIUS_STEP
	_radius_slider.value = _extraction_radius
	_radius_slider.custom_minimum_size = Vector2(350, 20)
	_radius_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_radius_slider.value_changed.connect(_on_radius_changed)
	control_hbox.add_child(_radius_slider)

	_radius_value_label = Label.new()
	_radius_value_label.text = "%dm" % int(_extraction_radius)
	_radius_value_label.add_theme_font_size_override("font_size", 18)
	_radius_value_label.add_theme_color_override("font_color", COLOR_TEAL)
	_radius_value_label.custom_minimum_size = Vector2(60, 0)
	control_hbox.add_child(_radius_value_label)

	return row

func _build_status_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(STATUS_WIDTH, 0)
	col.add_theme_constant_override("separation", 8)

	_active_drones_label = Label.new()
	_active_drones_label.text = "ACTIVE DRONES (0/%d)" % AutomationHub.get_max_drones()
	_active_drones_label.add_theme_font_size_override("font_size", 16)
	_active_drones_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	col.add_child(_active_drones_label)

	_add_divider(col)

	# Drone status cards container
	_drone_status_container = VBoxContainer.new()
	_drone_status_container.add_theme_constant_override("separation", 8)
	col.add_child(_drone_status_container)

	# Spacer to push deactivate to bottom
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)

	# Deactivate button
	_deactivate_button = Button.new()
	_deactivate_button.text = "DEACTIVATE DRONES"
	_deactivate_button.custom_minimum_size = Vector2(0, 48)
	_deactivate_button.add_theme_font_size_override("font_size", 16)
	_style_button(_deactivate_button, COLOR_CORAL)
	_deactivate_button.pressed.connect(_on_deactivate_pressed)
	_deactivate_button.visible = false
	col.add_child(_deactivate_button)

	return col

func _connect_signals() -> void:
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

	# Header row: state dot + drone name + state text
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(12, 12)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var state_name: String = status.get("state", "IDLE") as String
	match state_name:
		"IDLE":
			dot.color = COLOR_IDLE
		"TRAVELING":
			dot.color = COLOR_TRAVELING
		"EXTRACTING":
			dot.color = COLOR_EXTRACTING
		"RETURNING":
			dot.color = COLOR_RETURNING
		_:
			dot.color = COLOR_IDLE
	header.add_child(dot)

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
		Global.log("AutomationHubPanel: deployed %d drones" % deployed_count)
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
	Global.log("AutomationHubPanel: recalled all drones")
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
