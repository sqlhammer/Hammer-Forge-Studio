## Tech Tree UI panel: displays unlock graph for Fabricator and Automation Hub nodes.
## Opens when the player interacts with the tech tree terminal on the ship's north wall.
class_name TechTreePanel
extends CanvasLayer

# ── Signals ──────────────────────────────────────────────
signal closed

# ── Constants ─────────────────────────────────────────────
const PANEL_WIDTH: float = 960.0
const PANEL_HEIGHT: float = 600.0
const CARD_WIDTH: float = 120.0
const CARD_HEIGHT: float = 100.0
const DETAIL_WIDTH: float = 280.0
const GRAPH_WIDTH: float = 620.0

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
const COLOR_LOCKED_BORDER := Color("#1A2736")

# ── Private Variables ─────────────────────────────────────
var _is_open: bool = false
var _dim_rect: ColorRect = null
var _main_panel: PanelContainer = null
var _focused_index: int = 0
var _node_ids: Array[String] = []
var _node_cards: Array[PanelContainer] = []
var _card_styles: Array[StyleBoxFlat] = []
var _card_labels: Array[Label] = []
var _card_state_labels: Array[Label] = []
var _connector_line: Line2D = null
var _detail_name_label: Label = null
var _detail_desc_label: Label = null
var _detail_cost_label: Label = null
var _detail_have_label: Label = null
var _detail_status_label: Label = null
var _unlock_button: Button = null
var _confirm_overlay: Control = null
var _confirm_name_label: Label = null
var _confirm_cost_label: Label = null
var _confirm_button: Button = null
var _cancel_button: Button = null
var _confirm_visible: bool = false
var _graph_container: Control = null
var _pulse_tween: Tween = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	layer = 2
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = false
	_node_ids = TechTreeDefs.get_all_node_ids()
	_build_ui()
	_connect_signals()

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if _confirm_visible:
		if event.is_action_pressed("ui_cancel"):
			_close_confirm_dialog()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			if _confirm_button.has_focus():
				_on_confirm_pressed()
			elif _cancel_button.has_focus():
				_close_confirm_dialog()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_left"):
			_confirm_button.grab_focus()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_right"):
			_cancel_button.grab_focus()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_focus(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_move_focus(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_unlock_pressed()
		get_viewport().set_input_as_handled()

# ── Public Methods ────────────────────────────────────────

## Opens the tech tree panel.
func open() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	_refresh_all()
	_select_initial_focus()
	InputManager.set_gameplay_inputs_enabled(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_animate_open()
	Global.log("TechTreePanel: opened")

## Closes the tech tree panel.
func close() -> void:
	if not _is_open:
		return
	_is_open = false
	_stop_pulse()
	InputManager.set_gameplay_inputs_enabled(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_animate_close()
	closed.emit()
	Global.log("TechTreePanel: closed")

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
	vbox.add_theme_constant_override("separation", 12)
	_main_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "TECH TREE"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_add_divider(vbox)

	# HBox: graph + detail
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox)

	# Graph area
	_graph_container = Control.new()
	_graph_container.custom_minimum_size = Vector2(GRAPH_WIDTH, 420.0)
	hbox.add_child(_graph_container)

	_build_node_cards()
	_build_connector()

	# Detail panel
	var detail_panel := _build_detail_panel()
	hbox.add_child(detail_panel)

	# Footer row: instructions + close button
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 16)
	vbox.add_child(footer)

	var instructions := Label.new()
	instructions.text = "[Up/Down] Navigate  [Enter] Unlock  [Esc] Close"
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

	# Confirmation dialog (hidden)
	_build_confirm_dialog(dim_layer)

func _build_node_cards() -> void:
	var card_x: float = (GRAPH_WIDTH - CARD_WIDTH) / 2.0
	var card_positions: Array[Vector2] = [
		Vector2(card_x, 40.0),
		Vector2(card_x, 220.0),
	]

	for i: int in range(_node_ids.size()):
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		card.position = card_positions[i]

		var style := StyleBoxFlat.new()
		style.bg_color = COLOR_PANEL_BG
		style.border_color = COLOR_LOCKED_BORDER
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		style.set_content_margin_all(12)
		card.add_theme_stylebox_override("panel", style)
		_graph_container.add_child(card)

		var card_vbox := VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 4)
		card.add_child(card_vbox)

		# Icon placeholder
		var icon_rect := ColorRect.new()
		icon_rect.custom_minimum_size = Vector2(48, 48)
		icon_rect.color = COLOR_TEAL
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_vbox.add_child(icon_rect)

		# Node name
		var name_label := Label.new()
		name_label.text = TechTreeDefs.get_display_name(_node_ids[i])
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_vbox.add_child(name_label)

		# State icon label (padlock, chevron, checkmark)
		var state_label := Label.new()
		state_label.add_theme_font_size_override("font_size", 14)
		state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_vbox.add_child(state_label)

		_node_cards.append(card)
		_card_styles.append(style)
		_card_labels.append(name_label)
		_card_state_labels.append(state_label)

func _build_connector() -> void:
	_connector_line = Line2D.new()
	_connector_line.width = 2.0
	_connector_line.default_color = COLOR_LOCKED_BORDER
	# Connect from bottom of first card to top of second card
	var card_x: float = (GRAPH_WIDTH - CARD_WIDTH) / 2.0
	var center_x: float = card_x + CARD_WIDTH / 2.0
	var top_card_bottom: float = 40.0 + CARD_HEIGHT
	var bottom_card_top: float = 220.0
	_connector_line.add_point(Vector2(center_x, top_card_bottom))
	_connector_line.add_point(Vector2(center_x, bottom_card_top))
	_graph_container.add_child(_connector_line)

func _build_detail_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(DETAIL_WIDTH, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL_BG
	style.border_color = Color(COLOR_NEUTRAL, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Node name
	_detail_name_label = Label.new()
	_detail_name_label.add_theme_font_size_override("font_size", 20)
	_detail_name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	vbox.add_child(_detail_name_label)

	_add_divider(vbox)

	# Description
	_detail_desc_label = Label.new()
	_detail_desc_label.add_theme_font_size_override("font_size", 14)
	_detail_desc_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_detail_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_detail_desc_label)

	# Cost label
	_detail_cost_label = Label.new()
	_detail_cost_label.add_theme_font_size_override("font_size", 16)
	_detail_cost_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	vbox.add_child(_detail_cost_label)

	# "You have" label
	_detail_have_label = Label.new()
	_detail_have_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_detail_have_label)

	# Status label (UNLOCKED / LOCKED)
	_detail_status_label = Label.new()
	_detail_status_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_detail_status_label)

	# Unlock button
	_unlock_button = Button.new()
	_unlock_button.text = "UNLOCK"
	_unlock_button.custom_minimum_size = Vector2(200, 40)
	_unlock_button.add_theme_font_size_override("font_size", 18)
	_style_button(_unlock_button, COLOR_TEAL)
	_unlock_button.pressed.connect(_on_unlock_pressed)
	vbox.add_child(_unlock_button)

	return panel

func _build_confirm_dialog(parent: Control) -> void:
	_confirm_overlay = Control.new()
	_confirm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_overlay.visible = false
	parent.add_child(_confirm_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color("#000000", 0.3)
	_confirm_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_overlay.add_child(center)

	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(360, 180)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SURFACE
	style.border_color = Color(COLOR_NEUTRAL, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(24)
	dialog.add_theme_stylebox_override("panel", style)
	center.add_child(dialog)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	dialog.add_child(vbox)

	_confirm_name_label = Label.new()
	_confirm_name_label.add_theme_font_size_override("font_size", 20)
	_confirm_name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	vbox.add_child(_confirm_name_label)

	_add_divider(vbox)

	_confirm_cost_label = Label.new()
	_confirm_cost_label.add_theme_font_size_override("font_size", 16)
	_confirm_cost_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_confirm_cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_confirm_cost_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 16)
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_row)

	_confirm_button = Button.new()
	_confirm_button.text = "CONFIRM"
	_confirm_button.custom_minimum_size = Vector2(120, 40)
	_confirm_button.add_theme_font_size_override("font_size", 16)
	_style_button(_confirm_button, COLOR_GREEN)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	button_row.add_child(_confirm_button)

	_cancel_button = Button.new()
	_cancel_button.text = "CANCEL"
	_cancel_button.custom_minimum_size = Vector2(120, 40)
	_cancel_button.add_theme_font_size_override("font_size", 16)
	_style_button(_cancel_button, COLOR_NEUTRAL)
	_cancel_button.pressed.connect(_close_confirm_dialog)
	button_row.add_child(_cancel_button)

func _connect_signals() -> void:
	TechTree.node_unlocked.connect(_on_node_unlocked)
	PlayerInventory.item_added.connect(_on_inventory_changed)
	PlayerInventory.item_removed.connect(_on_inventory_changed)

func _refresh_all() -> void:
	for i: int in range(_node_ids.size()):
		_refresh_card(i)
	_refresh_connector()
	_refresh_detail()

func _refresh_card(index: int) -> void:
	var node_id: String = _node_ids[index]
	var style: StyleBoxFlat = _card_styles[index]
	var name_label: Label = _card_labels[index]
	var state_label: Label = _card_state_labels[index]
	var card: PanelContainer = _node_cards[index]

	if TechTree.is_unlocked(node_id):
		# Unlocked state
		style.bg_color = Color(COLOR_GREEN, 0.2)
		style.border_color = COLOR_GREEN if index == _focused_index else Color(COLOR_GREEN, 0.5)
		style.set_border_width_all(2 if index == _focused_index else 1)
		name_label.add_theme_color_override("font_color", COLOR_GREEN)
		state_label.text = "UNLOCKED"
		state_label.add_theme_color_override("font_color", COLOR_GREEN)
		card.modulate = Color.WHITE
	elif TechTree.can_unlock(node_id):
		# Unlockable state
		style.bg_color = COLOR_PANEL_BG
		style.border_color = COLOR_TEAL
		style.set_border_width_all(2)
		name_label.add_theme_color_override("font_color", COLOR_TEAL)
		state_label.text = "UNLOCKABLE"
		state_label.add_theme_color_override("font_color", COLOR_TEAL)
		card.modulate = Color.WHITE
		if index == _focused_index:
			_start_pulse(index)
	else:
		# Locked state
		style.bg_color = Color(COLOR_PANEL_BG, 0.5)
		style.border_color = COLOR_LOCKED_BORDER
		style.set_border_width_all(2 if index == _focused_index else 1)
		name_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		state_label.text = "LOCKED"
		state_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		card.modulate = Color(1, 1, 1, 0.6)

	# Focus highlight
	if index == _focused_index:
		style.set_border_width_all(2)

func _refresh_connector() -> void:
	# Connector color depends on parent/child unlock state
	var parent_unlocked: bool = TechTree.is_unlocked(_node_ids[0])
	var child_unlockable: bool = TechTree.can_unlock(_node_ids[1])

	if parent_unlocked and child_unlockable:
		_connector_line.default_color = COLOR_TEAL
	elif parent_unlocked:
		_connector_line.default_color = Color(COLOR_TEAL, 0.5)
	else:
		_connector_line.default_color = COLOR_LOCKED_BORDER

func _refresh_detail() -> void:
	if _focused_index < 0 or _focused_index >= _node_ids.size():
		return
	var node_id: String = _node_ids[_focused_index]
	var entry: Dictionary = TechTreeDefs.get_node_entry(node_id)
	var display_name: String = TechTreeDefs.get_display_name(node_id)

	_detail_name_label.text = display_name

	# Description from module defs
	var module_entry: Dictionary = ModuleDefs.get_module_entry(node_id.replace("_module", "") if node_id.ends_with("_module") else node_id)
	_detail_desc_label.text = module_entry.get("description", "Advanced ship technology.") as String

	if TechTree.is_unlocked(node_id):
		_detail_cost_label.visible = false
		_detail_have_label.visible = false
		_detail_status_label.text = "UNLOCKED"
		_detail_status_label.add_theme_color_override("font_color", COLOR_GREEN)
		_detail_status_label.visible = true
		_unlock_button.visible = false
	else:
		_detail_status_label.visible = false
		var cost: Dictionary = TechTreeDefs.get_unlock_cost(node_id)
		if not cost.is_empty():
			var resource_type: ResourceDefs.ResourceType = cost.get("resource_type", ResourceDefs.ResourceType.NONE) as ResourceDefs.ResourceType
			var quantity: int = cost.get("quantity", 0) as int
			var resource_name: String = ResourceDefs.get_resource_name(resource_type)
			var available: int = PlayerInventory.get_total_count(resource_type)

			_detail_cost_label.text = "UNLOCK COST: %d %s" % [quantity, resource_name]
			_detail_cost_label.visible = true

			_detail_have_label.text = "You have: %d %s" % [available, resource_name]
			_detail_have_label.visible = true
			if available >= quantity:
				_detail_have_label.add_theme_color_override("font_color", COLOR_GREEN)
			else:
				_detail_have_label.add_theme_color_override("font_color", COLOR_AMBER)
		else:
			_detail_cost_label.visible = false
			_detail_have_label.visible = false

		# Check prerequisites
		var prerequisites: Array[String] = TechTreeDefs.get_prerequisites(node_id)
		var prereqs_met: bool = true
		for prereq_id: String in prerequisites:
			if not TechTree.is_unlocked(prereq_id):
				prereqs_met = false
				break

		if not prereqs_met:
			_detail_status_label.text = "REQUIRES: %s" % TechTreeDefs.get_display_name(prerequisites[0])
			_detail_status_label.add_theme_color_override("font_color", COLOR_AMBER)
			_detail_status_label.visible = true
			_unlock_button.visible = false
		else:
			_unlock_button.visible = true
			_unlock_button.disabled = not TechTree.can_unlock(node_id)

func _move_focus(direction: int) -> void:
	var new_index: int = clampi(_focused_index + direction, 0, _node_ids.size() - 1)
	if new_index != _focused_index:
		_stop_pulse()
		_focused_index = new_index
		_refresh_all()

func _select_initial_focus() -> void:
	_focused_index = 0
	# Prefer the first unlockable node
	for i: int in range(_node_ids.size()):
		if TechTree.can_unlock(_node_ids[i]):
			_focused_index = i
			break

func _start_pulse(index: int) -> void:
	_stop_pulse()
	var card: PanelContainer = _node_cards[index]
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(card, "modulate:a", 0.7, 0.75)
	_pulse_tween.tween_property(card, "modulate:a", 1.0, 0.75)

func _stop_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	for card: PanelContainer in _node_cards:
		card.modulate.a = 1.0

func _open_confirm_dialog() -> void:
	var node_id: String = _node_ids[_focused_index]
	var display_name: String = TechTreeDefs.get_display_name(node_id)
	var cost: Dictionary = TechTreeDefs.get_unlock_cost(node_id)
	var quantity: int = cost.get("quantity", 0) as int
	var resource_type: ResourceDefs.ResourceType = cost.get("resource_type", ResourceDefs.ResourceType.NONE) as ResourceDefs.ResourceType
	var resource_name: String = ResourceDefs.get_resource_name(resource_type)

	_confirm_name_label.text = "Unlock %s?" % display_name
	_confirm_cost_label.text = "This will consume %d %s." % [quantity, resource_name]
	_confirm_overlay.visible = true
	_confirm_visible = true
	# CANCEL focused by default (safe default)
	_cancel_button.grab_focus()

func _close_confirm_dialog() -> void:
	_confirm_overlay.visible = false
	_confirm_visible = false

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

# ── Signal Handlers ──────────────────────────────────────

func _on_unlock_pressed() -> void:
	if _focused_index < 0 or _focused_index >= _node_ids.size():
		return
	var node_id: String = _node_ids[_focused_index]
	if not TechTree.can_unlock(node_id):
		return
	_open_confirm_dialog()

func _on_confirm_pressed() -> void:
	var node_id: String = _node_ids[_focused_index]
	var success: bool = TechTree.unlock_node(node_id)
	_close_confirm_dialog()
	if success:
		_refresh_all()
		Global.log("TechTreePanel: unlocked node '%s'" % node_id)

func _on_node_unlocked(_node_id: String) -> void:
	if _is_open:
		_refresh_all()

func _on_inventory_changed(_resource_type: ResourceDefs.ResourceType, _purity: ResourceDefs.Purity, _quantity: int) -> void:
	if _is_open:
		_refresh_all()
