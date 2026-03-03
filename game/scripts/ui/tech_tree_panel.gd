## Tech Tree UI panel: displays unlock graph for Fabricator and Automation Hub nodes.
## Opens when the player interacts with the tech tree terminal on the ship's north wall.
class_name TechTreePanel
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
const COLOR_DIM := Color("#000000", 0.5)
const COLOR_PANEL_BG := Color("#0F1923", 0.85)
const COLOR_LOCKED_BORDER := Color("#1A2736")

# ── Private Variables ─────────────────────────────────────
var _is_open: bool = false
var _focused_index: int = 0
var _node_ids: Array[String] = []
var _node_cards: Array[PanelContainer] = []
var _card_styles: Array[StyleBoxFlat] = []
var _card_labels: Array[Label] = []
var _card_state_labels: Array[Label] = []
var _card_state_icons: Array[TextureRect] = []
var _confirm_visible: bool = false
var _pulse_tween: Tween = null
var _lock_tex: Texture2D = null
var _unlock_check_tex: Texture2D = null
var _unlock_chevron_tex: Texture2D = null

# ── Onready Variables ─────────────────────────────────────
@onready var _dim_rect: ColorRect = %DimRect
@onready var _main_panel: PanelContainer = %MainPanel
@onready var _graph_container: Control = %GraphContainer
@onready var _connector_line: Line2D = %ConnectorLine
@onready var _card_0: PanelContainer = %Card0
@onready var _card_1: PanelContainer = %Card1
@onready var _card_icon_0: TextureRect = %CardIcon0
@onready var _card_icon_1: TextureRect = %CardIcon1
@onready var _card_name_0: Label = %CardName0
@onready var _card_name_1: Label = %CardName1
@onready var _state_icon_0: TextureRect = %StateIcon0
@onready var _state_icon_1: TextureRect = %StateIcon1
@onready var _state_label_0: Label = %StateLabel0
@onready var _state_label_1: Label = %StateLabel1
@onready var _detail_panel: PanelContainer = %DetailPanel
@onready var _detail_name_label: Label = %DetailNameLabel
@onready var _detail_desc_label: Label = %DetailDescLabel
@onready var _detail_cost_label: Label = %DetailCostLabel
@onready var _detail_have_label: Label = %DetailHaveLabel
@onready var _detail_status_label: Label = %DetailStatusLabel
@onready var _unlock_button: Button = %UnlockButton
@onready var _close_button: Button = %CloseButton
@onready var _confirm_overlay: Control = %ConfirmOverlay
@onready var _confirm_dialog: PanelContainer = %ConfirmDialog
@onready var _confirm_name_label: Label = %ConfirmNameLabel
@onready var _confirm_cost_label: Label = %ConfirmCostLabel
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton
@onready var _title_divider: HSeparator = %TitleDivider
@onready var _detail_divider: HSeparator = %DetailDivider
@onready var _confirm_divider: HSeparator = %ConfirmDivider

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_node_ids = TechTreeDefs.get_all_node_ids()
	_lock_tex = load("res://assets/icons/hud/icon_hud_lock.svg") as Texture2D
	_unlock_check_tex = load("res://assets/icons/hud/icon_hud_unlock_check.svg") as Texture2D
	_unlock_chevron_tex = load("res://assets/icons/hud/icon_hud_unlock_chevron.svg") as Texture2D
	_populate_card_arrays()
	_populate_card_data()
	_apply_styles()
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
	Global.debug_log("TechTreePanel: opened")

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
	Global.debug_log("TechTreePanel: closed")

## Returns true if the panel is open.
func is_open() -> bool:
	return _is_open

## Returns the currently focused node index.
func get_focused_node_index() -> int:
	return _focused_index

## Selects a tech tree node by index, matching keyboard navigation behavior.
func select_node_by_index(index: int) -> void:
	if index < 0 or index >= _node_ids.size():
		return
	_stop_pulse()
	_focused_index = index
	_refresh_all()

# ── Private Methods ───────────────────────────────────────

func _populate_card_arrays() -> void:
	_node_cards = [_card_0, _card_1]
	_card_labels = [_card_name_0, _card_name_1]
	_card_state_labels = [_state_label_0, _state_label_1]
	_card_state_icons = [_state_icon_0, _state_icon_1]

func _populate_card_data() -> void:
	var card_icons: Array[TextureRect] = [_card_icon_0, _card_icon_1]
	for i: int in range(_node_ids.size()):
		var node_icon_path: String = TechTreeDefs.get_icon_path(_node_ids[i])
		if not node_icon_path.is_empty():
			card_icons[i].texture = load(node_icon_path) as Texture2D
		_card_labels[i].text = TechTreeDefs.get_display_name(_node_ids[i])
	# Ensure card descendants pass mouse events through to the card
	_set_descendants_mouse_ignore(_card_0)
	_card_0.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_descendants_mouse_ignore(_card_1)
	_card_1.mouse_filter = Control.MOUSE_FILTER_STOP

func _apply_styles() -> void:
	# Main panel style
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_SURFACE
	panel_style.border_color = COLOR_BORDER
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(24)
	_main_panel.add_theme_stylebox_override("panel", panel_style)

	# Card styles (stored for dynamic updates in _refresh_card)
	for card: PanelContainer in _node_cards:
		var style := StyleBoxFlat.new()
		style.bg_color = COLOR_PANEL_BG
		style.border_color = COLOR_LOCKED_BORDER
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		style.set_content_margin_all(12)
		card.add_theme_stylebox_override("panel", style)
		_card_styles.append(style)

	# Detail panel style
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = COLOR_PANEL_BG
	detail_style.border_color = Color(COLOR_NEUTRAL, 0.3)
	detail_style.set_border_width_all(1)
	detail_style.set_corner_radius_all(6)
	detail_style.set_content_margin_all(16)
	_detail_panel.add_theme_stylebox_override("panel", detail_style)

	# Confirm dialog style
	var confirm_style := StyleBoxFlat.new()
	confirm_style.bg_color = COLOR_SURFACE
	confirm_style.border_color = Color(COLOR_NEUTRAL, 0.4)
	confirm_style.set_border_width_all(1)
	confirm_style.set_corner_radius_all(8)
	confirm_style.set_content_margin_all(24)
	_confirm_dialog.add_theme_stylebox_override("panel", confirm_style)

	# Divider styles
	var div_style := StyleBoxFlat.new()
	div_style.bg_color = Color(COLOR_NEUTRAL, 0.4)
	div_style.set_content_margin_all(0)
	_title_divider.add_theme_stylebox_override("separator", div_style)
	_detail_divider.add_theme_stylebox_override("separator", div_style)
	_confirm_divider.add_theme_stylebox_override("separator", div_style)

	# Button styles
	_style_button(_unlock_button, COLOR_TEAL)
	_style_button(_confirm_button, COLOR_GREEN)
	_style_button(_cancel_button, COLOR_NEUTRAL)
	_style_close_button(_close_button)

func _connect_signals() -> void:
	TechTree.node_unlocked.connect(_on_node_unlocked)
	PlayerInventory.item_added.connect(_on_inventory_changed)
	PlayerInventory.item_removed.connect(_on_inventory_changed)
	_unlock_button.pressed.connect(_on_unlock_pressed)
	_close_button.pressed.connect(close)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_cancel_button.pressed.connect(_close_confirm_dialog)
	for i: int in range(_node_cards.size()):
		_node_cards[i].mouse_entered.connect(_on_card_mouse_entered.bind(i))
		_node_cards[i].gui_input.connect(_on_card_gui_input.bind(i))

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
	var state_icon: TextureRect = _card_state_icons[index]
	var card: PanelContainer = _node_cards[index]

	if TechTree.is_unlocked(node_id):
		# Unlocked state
		style.bg_color = Color(COLOR_GREEN, 0.2)
		style.border_color = COLOR_GREEN if index == _focused_index else Color(COLOR_GREEN, 0.5)
		style.set_border_width_all(2 if index == _focused_index else 1)
		name_label.add_theme_color_override("font_color", COLOR_GREEN)
		state_label.text = "UNLOCKED"
		state_label.add_theme_color_override("font_color", COLOR_GREEN)
		state_icon.texture = _unlock_check_tex
		state_icon.modulate = COLOR_GREEN
		card.modulate = Color.WHITE
	elif TechTree.can_unlock(node_id):
		# Unlockable state
		style.bg_color = COLOR_PANEL_BG
		style.border_color = COLOR_TEAL
		style.set_border_width_all(2)
		name_label.add_theme_color_override("font_color", COLOR_TEAL)
		state_label.text = "UNLOCKABLE"
		state_label.add_theme_color_override("font_color", COLOR_TEAL)
		state_icon.texture = _unlock_chevron_tex
		state_icon.modulate = COLOR_TEAL
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
		state_icon.texture = _lock_tex
		state_icon.modulate = COLOR_TEXT_SECONDARY
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

func _on_card_mouse_entered(index: int) -> void:
	if not _is_open or _confirm_visible:
		return
	select_node_by_index(index)

func _on_card_gui_input(event: InputEvent, index: int) -> void:
	if not _is_open or _confirm_visible:
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null:
		return
	if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		select_node_by_index(index)

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
		Global.debug_log("TechTreePanel: unlocked node '%s'" % node_id)

func _on_node_unlocked(_node_id: String) -> void:
	if _is_open:
		_refresh_all()

func _on_inventory_changed(_resource_type: ResourceDefs.ResourceType, _purity: ResourceDefs.Purity, _quantity: int) -> void:
	if _is_open:
		_refresh_all()
