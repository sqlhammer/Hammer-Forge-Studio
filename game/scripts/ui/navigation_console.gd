## Navigation console modal: displays biome map, destination detail, fuel cost,
## and confirm travel button. Opens when the player interacts with the cockpit
## console mesh. Follows existing modal panel pattern (Fabricator, TechTree).
## Owner: gameplay-programmer
## Ticket: TICKET-0167
class_name NavigationConsole
extends CanvasLayer

# ── Signals ──────────────────────────────────────────────
signal travel_confirmed(destination_biome_id: String)
signal panel_closed

# ── Constants ─────────────────────────────────────────────
const PANEL_WIDTH: float = 900.0
const PANEL_HEIGHT: float = 600.0
const MAP_WIDTH: float = 540.0
const DETAIL_WIDTH: float = 300.0
const TITLE_HEIGHT: float = 56.0
const ACTION_HEIGHT: float = 60.0

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
const COLOR_NODE_BG := Color("#1A2736", 0.7)
const COLOR_NODE_BG_SELECTED := Color("#1A2736", 0.9)

# ── Private Variables ─────────────────────────────────────
var _is_open: bool = false
var _dim_rect: ColorRect = null
var _main_panel: PanelContainer = null
var _selected_biome_id: String = ""
var _biome_node_buttons: Dictionary = {}
var _biome_node_ids: Array[String] = []
var _selected_index: int = -1
var _focus_on_map: bool = true

## Detail panel elements
var _detail_name_label: Label = null
var _detail_tier_label: Label = null
var _detail_distance_label: Label = null
var _detail_distance_value: Label = null
var _detail_fuel_cost_label: Label = null
var _detail_fuel_cost_value: Label = null
var _detail_your_fuel_label: Label = null
var _detail_your_fuel_value: Label = null
var _detail_sufficiency_label: Label = null
var _confirm_button: Button = null
var _confirm_disabled_reason: Label = null
var _cancel_button: Button = null
var _detail_prompt_label: Label = null
var _detail_container: ScrollContainer = null

## Ship fuel section elements
var _fuel_tank_level_label: Label = null
var _fuel_inventory_count_label: Label = null
var _load_fuel_button: Button = null
var _fuel_status_label: Label = null

## Current biome node display
var _current_biome_label: Label = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	layer = 2
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = false
	_build_ui()
	_connect_signals()

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		close_panel()
		get_viewport().set_input_as_handled()
		return

	if _focus_on_map:
		if event.is_action_pressed("ui_left"):
			_move_map_focus(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_right"):
			_move_map_focus(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down"):
			# Move focus from map to confirm/cancel buttons
			_focus_on_map = false
			if _confirm_button and not _confirm_button.disabled:
				_confirm_button.grab_focus()
			elif _cancel_button:
				_cancel_button.grab_focus()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			_move_map_focus(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			# Select focused destination and shift focus to confirm button
			if _selected_index >= 0:
				_select_biome(_biome_node_ids[_selected_index])
				_focus_on_map = false
				if _confirm_button and not _confirm_button.disabled:
					_confirm_button.grab_focus()
				elif _cancel_button:
					_cancel_button.grab_focus()
			get_viewport().set_input_as_handled()
	else:
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
			_focus_on_map = true
			_update_map_visuals()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down"):
			# Move between confirm and cancel
			if _cancel_button:
				_cancel_button.grab_focus()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			if _confirm_button and _confirm_button.has_focus() and not _confirm_button.disabled:
				_on_confirm_pressed()
			elif _cancel_button and _cancel_button.has_focus():
				close_panel()
			get_viewport().set_input_as_handled()

# ── Public Methods ────────────────────────────────────────

## Opens the navigation console panel and resets to no-selection state.
func open_panel() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	_selected_biome_id = ""
	_selected_index = -1
	_focus_on_map = true
	_clamp_panel_to_viewport()
	_refresh_biome_nodes()
	_refresh_detail()
	_refresh_fuel_section()
	# Auto-focus first available destination node
	if _biome_node_ids.size() > 0:
		_selected_index = 0
		_update_map_visuals()
	InputManager.set_gameplay_inputs_enabled(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_animate_open()
	Global.debug_log("NavigationConsole: opened")

## Closes the navigation console panel and restores input handling.
func close_panel() -> void:
	if not _is_open:
		return
	_is_open = false
	InputManager.set_gameplay_inputs_enabled(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_animate_close()
	panel_closed.emit()
	Global.debug_log("NavigationConsole: closed")

## Closes the panel for travel without re-enabling gameplay inputs.
## The TravelSequenceManager owns the input state during the transition
## and will call InputManager.set_gameplay_inputs_enabled(true) when the
## travel sequence completes.
func _close_for_travel() -> void:
	if not _is_open:
		return
	_is_open = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_animate_close()
	panel_closed.emit()
	Global.debug_log("NavigationConsole: closed for travel (inputs left disabled)")

## Returns true if the panel is currently open.
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
	outer_vbox.add_theme_constant_override("separation", 0)
	_main_panel.add_child(outer_vbox)

	# Title bar
	_build_title_bar(outer_vbox)
	_add_divider(outer_vbox)

	# Content area: map (left) + detail (right)
	var content_hbox := HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 16)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(content_hbox)

	# Left column: biome map
	var map_column := _build_map_column()
	content_hbox.add_child(map_column)

	# Vertical divider
	var v_divider := VSeparator.new()
	var vdiv_style := StyleBoxFlat.new()
	vdiv_style.bg_color = Color(COLOR_NEUTRAL, 0.3)
	vdiv_style.set_content_margin_all(0)
	v_divider.add_theme_stylebox_override("separator", vdiv_style)
	content_hbox.add_child(v_divider)

	# Right column: destination detail
	_detail_container = _build_detail_column()
	content_hbox.add_child(_detail_container)

	# Action bar (bottom)
	_add_divider(outer_vbox)
	_build_action_bar(outer_vbox)

func _build_title_bar(parent: VBoxContainer) -> void:
	var title_row := HBoxContainer.new()
	title_row.custom_minimum_size = Vector2(0, TITLE_HEIGHT)
	title_row.add_theme_constant_override("separation", 8)
	parent.add_child(title_row)

	var title := Label.new()
	title.text = "NAVIGATION CONSOLE"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(title)

	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(80, 32)
	close_button.add_theme_font_size_override("font_size", 16)
	_style_secondary_button(close_button)
	close_button.pressed.connect(close_panel)
	title_row.add_child(close_button)

func _build_map_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(MAP_WIDTH, 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)

	# Map section header
	var header := Label.new()
	header.text = "BIOME MAP"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	col.add_child(header)

	# Map container with panel background
	var map_panel := PanelContainer.new()
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var map_bg := StyleBoxFlat.new()
	map_bg.bg_color = COLOR_PANEL_BG
	map_bg.set_content_margin_all(20)
	map_bg.set_corner_radius_all(4)
	map_panel.add_theme_stylebox_override("panel", map_bg)
	col.add_child(map_panel)

	var map_vbox := VBoxContainer.new()
	map_vbox.add_theme_constant_override("separation", 16)
	map_panel.add_child(map_vbox)

	# Current location node (displayed at top of map)
	_current_biome_label = Label.new()
	_current_biome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_current_biome_label.add_theme_font_size_override("font_size", 16)
	_current_biome_label.add_theme_color_override("font_color", COLOR_TEAL)

	var current_node_panel := PanelContainer.new()
	current_node_panel.custom_minimum_size = Vector2(200, 40)
	var current_style := StyleBoxFlat.new()
	current_style.bg_color = Color("#1A2736", 0.9)
	current_style.border_color = COLOR_TEAL
	current_style.set_border_width_all(2)
	current_style.set_corner_radius_all(4)
	current_style.set_content_margin_all(8)
	current_node_panel.add_theme_stylebox_override("panel", current_style)
	current_node_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	current_node_panel.add_child(_current_biome_label)
	map_vbox.add_child(current_node_panel)

	# Travel path indicator
	var path_label := Label.new()
	path_label.text = "│"
	path_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	path_label.add_theme_font_size_override("font_size", 16)
	path_label.add_theme_color_override("font_color", Color("#007A63"))
	map_vbox.add_child(path_label)

	# Destination nodes row
	var dest_row := HBoxContainer.new()
	dest_row.add_theme_constant_override("separation", 12)
	dest_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dest_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_vbox.add_child(dest_row)

	# Build biome destination buttons dynamically from BiomeRegistry
	_biome_node_buttons.clear()
	_biome_node_ids.clear()

	for biome_id: String in BiomeRegistry.BIOME_IDS:
		if biome_id == NavigationSystem.current_biome:
			continue
		_biome_node_ids.append(biome_id)
		var biome_button := _build_biome_node_button(biome_id)
		dest_row.add_child(biome_button)
		_biome_node_buttons[biome_id] = biome_button

	return col

func _build_biome_node_button(biome_id: String) -> PanelContainer:
	var biome_data: BiomeData = BiomeRegistry.get_biome(biome_id)
	var display_name: String = biome_data.display_name if biome_data else biome_id

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 80)
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = COLOR_NODE_BG
	normal_style.border_color = Color("#1A2736")
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(4)
	normal_style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", normal_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	# Biome name
	var name_label := Label.new()
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Distance
	var distance: float = BiomeRegistry.get_distance(NavigationSystem.current_biome, biome_id)
	var distance_km: float = distance / 100.0
	var distance_label := Label.new()
	distance_label.text = "%.1f km" % distance_km
	distance_label.add_theme_font_size_override("font_size", 14)
	distance_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(distance_label)

	# Fuel cost
	var fuel_cost: float = NavigationSystem.get_travel_cost(biome_id)
	var fuel_cells: int = ceili(fuel_cost / FuelSystemDefs.FUEL_CELL_UNITS)
	var fuel_label := Label.new()
	fuel_label.text = "%d Fuel Cell(s)" % fuel_cells
	fuel_label.add_theme_font_size_override("font_size", 14)
	fuel_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	fuel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(fuel_label)

	# Make the panel clickable via an invisible button overlay
	var click_button := Button.new()
	click_button.flat = true
	click_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_button.mouse_filter = Control.MOUSE_FILTER_STOP
	click_button.focus_mode = Control.FOCUS_NONE
	click_button.pressed.connect(_on_biome_node_clicked.bind(biome_id))
	panel.add_child(click_button)

	return panel

func _build_detail_column() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(DETAIL_WIDTH, 0)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	scroll.add_child(col)

	# SHIP FUEL section — always visible when panel is open
	var fuel_header := Label.new()
	fuel_header.text = "SHIP FUEL"
	fuel_header.add_theme_font_size_override("font_size", 14)
	fuel_header.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	col.add_child(fuel_header)

	_fuel_tank_level_label = Label.new()
	_fuel_tank_level_label.add_theme_font_size_override("font_size", 20)
	_fuel_tank_level_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	col.add_child(_fuel_tank_level_label)

	_fuel_inventory_count_label = Label.new()
	_fuel_inventory_count_label.add_theme_font_size_override("font_size", 14)
	_fuel_inventory_count_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	col.add_child(_fuel_inventory_count_label)

	_load_fuel_button = Button.new()
	_load_fuel_button.text = "LOAD FUEL CELLS"
	_load_fuel_button.custom_minimum_size = Vector2(200, 40)
	_load_fuel_button.add_theme_font_size_override("font_size", 16)
	_style_teal_button(_load_fuel_button)
	_load_fuel_button.pressed.connect(_on_load_fuel_pressed)
	col.add_child(_load_fuel_button)

	_fuel_status_label = Label.new()
	_fuel_status_label.add_theme_font_size_override("font_size", 14)
	_fuel_status_label.add_theme_color_override("font_color", COLOR_GREEN)
	_fuel_status_label.visible = false
	col.add_child(_fuel_status_label)

	_add_divider(col)

	# Section header
	var header := Label.new()
	header.text = "DESTINATION"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	col.add_child(header)

	_add_divider(col)

	# Empty state prompt
	_detail_prompt_label = Label.new()
	_detail_prompt_label.text = "Select a destination"
	_detail_prompt_label.add_theme_font_size_override("font_size", 16)
	_detail_prompt_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	col.add_child(_detail_prompt_label)

	# Destination name
	_detail_name_label = Label.new()
	_detail_name_label.add_theme_font_size_override("font_size", 24)
	_detail_name_label.add_theme_color_override("font_color", COLOR_TEAL)
	_detail_name_label.visible = false
	col.add_child(_detail_name_label)

	# Tier badge
	_detail_tier_label = Label.new()
	_detail_tier_label.add_theme_font_size_override("font_size", 14)
	_detail_tier_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_detail_tier_label.visible = false
	col.add_child(_detail_tier_label)

	_add_divider(col)

	# Distance row
	_detail_distance_label = Label.new()
	_detail_distance_label.text = "Distance"
	_detail_distance_label.add_theme_font_size_override("font_size", 14)
	_detail_distance_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_detail_distance_label.visible = false
	col.add_child(_detail_distance_label)

	_detail_distance_value = Label.new()
	_detail_distance_value.add_theme_font_size_override("font_size", 22)
	_detail_distance_value.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	_detail_distance_value.visible = false
	col.add_child(_detail_distance_value)

	# Fuel cost row
	_detail_fuel_cost_label = Label.new()
	_detail_fuel_cost_label.text = "Estimated Fuel Cost"
	_detail_fuel_cost_label.add_theme_font_size_override("font_size", 14)
	_detail_fuel_cost_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_detail_fuel_cost_label.visible = false
	col.add_child(_detail_fuel_cost_label)

	_detail_fuel_cost_value = Label.new()
	_detail_fuel_cost_value.add_theme_font_size_override("font_size", 22)
	_detail_fuel_cost_value.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	_detail_fuel_cost_value.visible = false
	col.add_child(_detail_fuel_cost_value)

	# Your fuel row
	_detail_your_fuel_label = Label.new()
	_detail_your_fuel_label.text = "Ship Tank"
	_detail_your_fuel_label.add_theme_font_size_override("font_size", 14)
	_detail_your_fuel_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_detail_your_fuel_label.visible = false
	col.add_child(_detail_your_fuel_label)

	_detail_your_fuel_value = Label.new()
	_detail_your_fuel_value.add_theme_font_size_override("font_size", 22)
	_detail_your_fuel_value.visible = false
	col.add_child(_detail_your_fuel_value)

	# Sufficiency indicator
	_detail_sufficiency_label = Label.new()
	_detail_sufficiency_label.add_theme_font_size_override("font_size", 14)
	_detail_sufficiency_label.visible = false
	col.add_child(_detail_sufficiency_label)

	_add_divider(col)

	# Confirm travel button
	var button_center := CenterContainer.new()
	col.add_child(button_center)

	_confirm_button = Button.new()
	_confirm_button.text = "CONFIRM TRAVEL"
	_confirm_button.custom_minimum_size = Vector2(240, 52)
	_confirm_button.add_theme_font_size_override("font_size", 20)
	_confirm_button.disabled = true
	_style_teal_button(_confirm_button)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	button_center.add_child(_confirm_button)

	# Disabled reason label
	_confirm_disabled_reason = Label.new()
	_confirm_disabled_reason.add_theme_font_size_override("font_size", 14)
	_confirm_disabled_reason.add_theme_color_override("font_color", COLOR_CORAL)
	_confirm_disabled_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_disabled_reason.visible = false
	col.add_child(_confirm_disabled_reason)

	return scroll

func _build_action_bar(parent: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, ACTION_HEIGHT)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 16)
	parent.add_child(bar)

	var instructions := Label.new()
	instructions.text = "[Arrows] Select  [Enter] Confirm  [Esc] Close"
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	bar.add_child(instructions)

	_cancel_button = Button.new()
	_cancel_button.text = "CANCEL"
	_cancel_button.custom_minimum_size = Vector2(120, 40)
	_cancel_button.add_theme_font_size_override("font_size", 20)
	_style_secondary_button(_cancel_button)
	_cancel_button.pressed.connect(close_panel)
	bar.add_child(_cancel_button)

func _connect_signals() -> void:
	FuelSystem.fuel_changed.connect(_on_fuel_changed)

func _clamp_panel_to_viewport() -> void:
	var max_height: float = get_viewport().get_visible_rect().size.y * 0.92
	_main_panel.custom_minimum_size.y = min(PANEL_HEIGHT, max_height)

func _refresh_biome_nodes() -> void:
	# Update current biome display
	var current_data: BiomeData = BiomeRegistry.get_biome(NavigationSystem.current_biome)
	var current_name: String = current_data.display_name if current_data else NavigationSystem.current_biome
	_current_biome_label.text = "◉ %s" % current_name.to_upper()
	_update_map_visuals()

func _update_map_visuals() -> void:
	for i: int in range(_biome_node_ids.size()):
		var biome_id: String = _biome_node_ids[i]
		var panel: PanelContainer = _biome_node_buttons[biome_id]
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
		var name_label: Label = panel.get_child(0).get_child(0) as Label

		var is_focused: bool = _focus_on_map and i == _selected_index
		var is_selected: bool = biome_id == _selected_biome_id

		if is_selected or is_focused:
			style.bg_color = COLOR_NODE_BG_SELECTED
			style.border_color = COLOR_TEAL
			style.set_border_width_all(2)
			if is_selected:
				name_label.add_theme_color_override("font_color", COLOR_TEAL)
			else:
				name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
		else:
			style.bg_color = COLOR_NODE_BG
			style.border_color = Color("#1A2736")
			style.set_border_width_all(1)
			name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)

func _select_biome(biome_id: String) -> void:
	_selected_biome_id = biome_id
	# Update selected_index to match
	for i: int in range(_biome_node_ids.size()):
		if _biome_node_ids[i] == biome_id:
			_selected_index = i
			break
	_update_map_visuals()
	_refresh_detail()
	Global.debug_log("NavigationConsole: selected destination '%s'" % biome_id)

func _refresh_detail() -> void:
	if _selected_biome_id.is_empty():
		# Empty state
		_detail_prompt_label.visible = true
		_detail_name_label.visible = false
		_detail_tier_label.visible = false
		_detail_distance_label.visible = false
		_detail_distance_value.visible = false
		_detail_fuel_cost_label.visible = false
		_detail_fuel_cost_value.visible = false
		_detail_your_fuel_label.visible = false
		_detail_your_fuel_value.visible = false
		_detail_sufficiency_label.visible = false
		_confirm_button.disabled = true
		_confirm_disabled_reason.visible = false
		return

	_detail_prompt_label.visible = false

	var biome_data: BiomeData = BiomeRegistry.get_biome(_selected_biome_id)
	if not biome_data:
		return

	# Name
	_detail_name_label.text = biome_data.display_name
	_detail_name_label.visible = true

	# Tier
	_detail_tier_label.text = "── Tier 1 ──"
	_detail_tier_label.visible = true

	# Distance
	var distance: float = BiomeRegistry.get_distance(NavigationSystem.current_biome, _selected_biome_id)
	var distance_km: float = distance / 100.0
	_detail_distance_label.visible = true
	_detail_distance_value.text = "%.1f km" % distance_km
	_detail_distance_value.visible = true

	# Fuel cost
	var fuel_cost: float = NavigationSystem.get_travel_cost(_selected_biome_id)
	var fuel_cells_needed: int = ceili(fuel_cost / FuelSystemDefs.FUEL_CELL_UNITS)
	_detail_fuel_cost_label.visible = true
	_detail_fuel_cost_value.text = "%d Fuel Cell(s)" % fuel_cells_needed
	_detail_fuel_cost_value.visible = true

	# Your fuel
	var current_fuel: float = FuelSystem.fuel_current
	var your_fuel_cells: int = floori(current_fuel / FuelSystemDefs.FUEL_CELL_UNITS)
	_detail_your_fuel_label.visible = true
	_detail_your_fuel_value.text = "%d Fuel Cell(s)" % your_fuel_cells
	_detail_your_fuel_value.visible = true

	# Sufficiency check
	var can_afford: bool = NavigationSystem.can_travel_to(_selected_biome_id)
	if can_afford:
		_detail_your_fuel_value.add_theme_color_override("font_color", COLOR_GREEN)
		_detail_sufficiency_label.text = "● Sufficient"
		_detail_sufficiency_label.add_theme_color_override("font_color", COLOR_GREEN)
		_confirm_button.disabled = false
		_confirm_disabled_reason.visible = false
	else:
		_detail_your_fuel_value.add_theme_color_override("font_color", COLOR_CORAL)
		_detail_sufficiency_label.text = "⚠ Not enough fuel"
		_detail_sufficiency_label.add_theme_color_override("font_color", COLOR_CORAL)
		_confirm_button.disabled = true
		var deficit: int = fuel_cells_needed - your_fuel_cells
		_confirm_disabled_reason.text = "Need %d more Fuel Cell(s)" % deficit
		_confirm_disabled_reason.visible = true
	_detail_sufficiency_label.visible = true

func _move_map_focus(direction: int) -> void:
	if _biome_node_ids.is_empty():
		return
	var new_index: int = clampi(_selected_index + direction, 0, _biome_node_ids.size() - 1)
	if new_index != _selected_index:
		_selected_index = new_index
		_update_map_visuals()

func _on_biome_node_clicked(biome_id: String) -> void:
	# Mouse click selects destination immediately
	_select_biome(biome_id)

func _on_confirm_pressed() -> void:
	if _selected_biome_id.is_empty():
		Global.debug_log("NavigationConsole: confirm pressed — no destination selected")
		return
	if not NavigationSystem.can_travel_to(_selected_biome_id):
		Global.debug_log("NavigationConsole: confirm pressed — cannot afford travel to '%s'" % _selected_biome_id)
		return

	var destination: String = _selected_biome_id
	Global.debug_log("NavigationConsole: confirming travel to '%s'" % destination)
	travel_confirmed.emit(destination)

	# Close the panel first without re-enabling gameplay inputs — the
	# TravelSequenceManager owns the input state during the transition and
	# will re-enable inputs when the sequence completes.
	_close_for_travel()

	# Initiate travel — the NavigationSystem state machine runs synchronously,
	# emitting travel_completed which triggers TravelSequenceManager's async
	# biome transition (fade out -> swap -> fade in -> re-enable inputs).
	NavigationSystem.initiate_travel(destination)
	Global.debug_log("NavigationConsole: travel initiated to '%s'" % destination)

func _on_fuel_changed(_current: float, _maximum: float) -> void:
	if _is_open:
		_refresh_detail()
		_refresh_fuel_section()

func _refresh_fuel_section() -> void:
	var current_fuel: float = FuelSystem.fuel_current
	var max_fuel: float = FuelSystem.fuel_max
	_fuel_tank_level_label.text = "%d / %d units" % [int(current_fuel), int(max_fuel)]

	var cells_in_inventory: int = PlayerInventory.get_total_count(ResourceDefs.ResourceType.FUEL_CELL)
	_fuel_inventory_count_label.text = "Cells in backpack: %d" % cells_in_inventory

	var tank_is_full: bool = current_fuel >= max_fuel
	_load_fuel_button.disabled = cells_in_inventory == 0 or tank_is_full

func _on_load_fuel_pressed() -> void:
	var cells_available: int = PlayerInventory.get_total_count(ResourceDefs.ResourceType.FUEL_CELL)
	if cells_available == 0:
		return
	var cells_consumed: int = FuelSystem.refuel(cells_available)
	if cells_consumed > 0:
		var units_added: float = cells_consumed * FuelSystemDefs.FUEL_CELL_UNITS
		_fuel_status_label.text = "Loaded %d cell(s) (+%d units)" % [cells_consumed, int(units_added)]
		_fuel_status_label.add_theme_color_override("font_color", COLOR_GREEN)
		_fuel_status_label.visible = true
		Global.debug_log("NavigationConsole: loaded %d fuel cell(s) into ship tank" % cells_consumed)
	else:
		_fuel_status_label.text = "Tank is already full"
		_fuel_status_label.add_theme_color_override("font_color", COLOR_AMBER)
		_fuel_status_label.visible = true

func _style_teal_button(button: Button) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(COLOR_TEAL, 0.2)
	normal_style.border_color = COLOR_TEAL
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(4)
	normal_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", normal_style)

	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(COLOR_TEAL, 0.4)
	button.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color(COLOR_TEAL, 0.05)
	disabled_style.border_color = Color(COLOR_NEUTRAL, 0.4)
	button.add_theme_stylebox_override("disabled", disabled_style)

	var focus_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	focus_style.border_color = COLOR_TEAL
	focus_style.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus_style)

	button.add_theme_color_override("font_color", COLOR_TEAL)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_disabled_color", Color(COLOR_NEUTRAL, 0.4))

func _style_secondary_button(button: Button) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(COLOR_NEUTRAL, 0.2)
	normal_style.border_color = Color("#007A63")
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
