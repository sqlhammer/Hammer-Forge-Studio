## Ship stats sidebar: compact Power/Integrity/Heat/Oxygen display for the inventory screen.
## Read-only, signal-driven via ShipState. Includes an alerts section for critical warnings.
class_name ShipStatsSidebar
extends PanelContainer

# ── Constants ─────────────────────────────────────────────
const SIDEBAR_WIDTH: float = 180.0
const BAR_WIDTH: float = 100.0
const BAR_HEIGHT: float = 8.0
const ICON_SIZE: float = 18.0

## Colors per style guide
const COLOR_SURFACE := Color("#0A0F18", 0.95)
const COLOR_BORDER := Color("#007A63")
const COLOR_BAR_BG := Color("#1A2736")
const COLOR_TEAL := Color("#00D4AA")
const COLOR_AMBER := Color("#FFB830")
const COLOR_CORAL := Color("#FF6B5A")
const COLOR_ICE_BLUE := Color("#60A5FA")
const COLOR_TEXT_PRIMARY := Color("#F1F5F9")
const COLOR_TEXT_SECONDARY := Color("#94A3B8")
const COLOR_NEUTRAL := Color("#94A3B8")

## State thresholds (matches ShipGlobalsHUD)
const POWER_LOW: float = 49.0
const POWER_CRITICAL: float = 19.0
const INTEGRITY_DAMAGED: float = 74.0
const INTEGRITY_CRITICAL: float = 29.0
const HEAT_COLD: float = 24.0
const HEAT_HOT: float = 76.0
const OXYGEN_LOW: float = 49.0
const OXYGEN_CRITICAL: float = 19.0

# ── Private Variables ─────────────────────────────────────
var _bars: Array[ProgressBar] = []
var _icons: Array[ColorRect] = []
var _labels: Array[Label] = []
var _values: Array[float] = [100.0, 100.0, 50.0, 100.0]
var _alerts_container: VBoxContainer = null
var _alert_labels: Array[Label] = []
var _current_alert_keys: Array[String] = []

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	_connect_signals()
	_refresh_all()

# ── Public Methods ────────────────────────────────────────

## Refreshes all values from ShipState.
func refresh() -> void:
	_refresh_all()

# ── Private Methods ───────────────────────────────────────

func _build_ui() -> void:
	custom_minimum_size = Vector2(SIDEBAR_WIDTH, 0)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_SURFACE
	panel_style.border_color = COLOR_BORDER
	panel_style.set_border_width_all(1)
	panel_style.border_width_left = 1
	panel_style.set_corner_radius_all(0)
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "SHIP"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	vbox.add_child(title)

	# Divider
	var divider := HSeparator.new()
	var div_style := StyleBoxFlat.new()
	div_style.bg_color = Color(COLOR_NEUTRAL, 0.4)
	div_style.set_content_margin_all(0)
	divider.add_theme_stylebox_override("separator", div_style)
	vbox.add_child(divider)

	# Variable rows
	var var_names: Array[String] = ["P", "I", "H", "O"]
	for i: int in range(4):
		var row := _create_variable_row(var_names[i], i)
		vbox.add_child(row)

	# Alerts divider
	var alert_divider := HSeparator.new()
	var alert_div_style := StyleBoxFlat.new()
	alert_div_style.bg_color = Color(COLOR_NEUTRAL, 0.3)
	alert_div_style.set_content_margin_all(0)
	alert_divider.add_theme_stylebox_override("separator", alert_div_style)
	vbox.add_child(alert_divider)

	# Alerts section
	var alerts_title := Label.new()
	alerts_title.text = "ALERTS"
	alerts_title.add_theme_font_size_override("font_size", 14)
	alerts_title.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	vbox.add_child(alerts_title)

	_alerts_container = VBoxContainer.new()
	_alerts_container.add_theme_constant_override("separation", 4)
	_alerts_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_alerts_container)

	# Default "no alerts" label
	var none_label := Label.new()
	none_label.text = "(none)"
	none_label.add_theme_font_size_override("font_size", 14)
	none_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_alerts_container.add_child(none_label)

func _create_variable_row(icon_text: String, index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Icon
	var icon_container := Control.new()
	icon_container.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_container)

	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.color = COLOR_TEAL
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.add_child(icon)
	_icons.append(icon)

	var icon_label := Label.new()
	icon_label.text = icon_text
	icon_label.add_theme_font_size_override("font_size", 11)
	icon_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.add_child(icon_label)

	# Progress bar
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bar.max_value = 100.0
	bar.value = _values[index]
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = COLOR_BAR_BG
	bar_bg.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = COLOR_TEAL
	bar_fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", bar_fill)

	row.add_child(bar)
	_bars.append(bar)

	# Value label
	var label := Label.new()
	label.custom_minimum_size = Vector2(36, 0)
	label.text = "%d%%" % int(_values[index])
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", COLOR_TEAL)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	_labels.append(label)

	return row

func _connect_signals() -> void:
	ShipState.power_changed.connect(_on_power_changed)
	ShipState.integrity_changed.connect(_on_integrity_changed)
	ShipState.heat_changed.connect(_on_heat_changed)
	ShipState.oxygen_changed.connect(_on_oxygen_changed)

func _refresh_all() -> void:
	_values[0] = ShipState.get_power()
	_values[1] = ShipState.get_integrity()
	_values[2] = ShipState.get_heat()
	_values[3] = ShipState.get_oxygen()
	for i: int in range(4):
		_bars[i].value = _values[i]
		_labels[i].text = "%d%%" % int(_values[i])
	_update_colors()
	_update_alerts()

func _update_colors() -> void:
	# Power
	_apply_color(0, _get_power_color(_values[0]))
	# Integrity
	_apply_color(1, _get_integrity_color(_values[1]))
	# Heat
	_apply_color(2, _get_heat_color(_values[2]))
	# Oxygen
	_apply_color(3, _get_oxygen_color(_values[3]))

func _apply_color(index: int, color: Color) -> void:
	var fill_style: StyleBoxFlat = _bars[index].get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	fill_style.bg_color = color
	_bars[index].add_theme_stylebox_override("fill", fill_style)
	_labels[index].add_theme_color_override("font_color", color)
	_icons[index].color = color

func _get_power_color(value: float) -> Color:
	if value <= POWER_CRITICAL:
		return COLOR_CORAL
	elif value <= POWER_LOW:
		return COLOR_AMBER
	return COLOR_TEAL

func _get_integrity_color(value: float) -> Color:
	if value <= INTEGRITY_CRITICAL:
		return COLOR_CORAL
	elif value <= INTEGRITY_DAMAGED:
		return COLOR_AMBER
	return COLOR_TEAL

func _get_heat_color(value: float) -> Color:
	if value <= HEAT_COLD:
		return COLOR_ICE_BLUE
	elif value >= HEAT_HOT:
		return COLOR_CORAL
	return COLOR_TEAL

func _get_oxygen_color(value: float) -> Color:
	if value <= OXYGEN_CRITICAL:
		return COLOR_CORAL
	elif value <= OXYGEN_LOW:
		return COLOR_AMBER
	return COLOR_TEAL

func _update_alerts() -> void:
	# Clear existing alerts
	for child: Node in _alerts_container.get_children():
		child.queue_free()

	var new_alerts: Array[String] = []

	if _values[0] <= POWER_CRITICAL:
		_add_alert("LOW POWER")
		new_alerts.append("LOW POWER")
	if _values[1] <= INTEGRITY_CRITICAL:
		_add_alert("HULL CRITICAL")
		new_alerts.append("HULL CRITICAL")
	if _values[2] >= HEAT_HOT:
		_add_alert("OVERHEATING")
		new_alerts.append("OVERHEATING")
	if _values[3] <= OXYGEN_CRITICAL:
		_add_alert("LOW OXYGEN")
		new_alerts.append("LOW OXYGEN")

	if new_alerts.is_empty():
		var none_label := Label.new()
		none_label.text = "(none)"
		none_label.add_theme_font_size_override("font_size", 14)
		none_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		_alerts_container.add_child(none_label)

	# Log alert changes
	if new_alerts != _current_alert_keys:
		if new_alerts.is_empty():
			Global.log("ShipStatsSidebar: alerts cleared")
		else:
			var joined: String = ", ".join(new_alerts)
			Global.log("ShipStatsSidebar: active alerts — %s" % joined)
		_current_alert_keys = new_alerts

func _add_alert(text: String) -> void:
	var alert := Label.new()
	alert.text = text
	alert.add_theme_font_size_override("font_size", 14)
	alert.add_theme_color_override("font_color", COLOR_CORAL)
	_alerts_container.add_child(alert)

# ── Signal Handlers ──────────────────────────────────────

func _on_power_changed(current: float, _maximum: float) -> void:
	_values[0] = current
	_bars[0].value = current
	_labels[0].text = "%d%%" % int(current)
	_update_colors()
	_update_alerts()

func _on_integrity_changed(current: float, _maximum: float) -> void:
	_values[1] = current
	_bars[1].value = current
	_labels[1].text = "%d%%" % int(current)
	_update_colors()
	_update_alerts()

func _on_heat_changed(current: float, _maximum: float) -> void:
	_values[2] = current
	_bars[2].value = current
	_labels[2].text = "%d%%" % int(current)
	_update_colors()
	_update_alerts()

func _on_oxygen_changed(current: float, _maximum: float) -> void:
	_values[3] = current
	_bars[3].value = current
	_labels[3].text = "%d%%" % int(current)
	_update_colors()
	_update_alerts()
