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
var _icons: Array[TextureRect] = []
var _labels: Array[Label] = []
var _values: Array[float] = [100.0, 100.0, 50.0, 100.0]
var _alert_labels: Array[Label] = []
var _current_alert_keys: Array[String] = []

# ── Onready Variables ─────────────────────────────────────
@onready var _divider: HSeparator = %Divider
@onready var _alert_divider: HSeparator = %AlertDivider
@onready var _alerts_container: VBoxContainer = %AlertsContainer
@onready var _power_icon: TextureRect = %PowerIcon
@onready var _power_bar: ProgressBar = %PowerBar
@onready var _power_label: Label = %PowerLabel
@onready var _integrity_icon: TextureRect = %IntegrityIcon
@onready var _integrity_bar: ProgressBar = %IntegrityBar
@onready var _integrity_label: Label = %IntegrityLabel
@onready var _heat_icon: TextureRect = %HeatIcon
@onready var _heat_bar: ProgressBar = %HeatBar
@onready var _heat_label: Label = %HeatLabel
@onready var _oxygen_icon: TextureRect = %OxygenIcon
@onready var _oxygen_bar: ProgressBar = %OxygenBar
@onready var _oxygen_label: Label = %OxygenLabel

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_bars = [_power_bar, _integrity_bar, _heat_bar, _oxygen_bar]
	_icons = [_power_icon, _integrity_icon, _heat_icon, _oxygen_icon]
	_labels = [_power_label, _integrity_label, _heat_label, _oxygen_label]
	_apply_panel_style()
	_apply_divider_styles()
	_apply_bar_styles()
	_connect_signals()
	_refresh_all()

# ── Public Methods ────────────────────────────────────────

## Refreshes all values from ShipState.
func refresh() -> void:
	_refresh_all()

# ── Private Methods ───────────────────────────────────────

func _apply_panel_style() -> void:
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

func _apply_divider_styles() -> void:
	var div_style := StyleBoxFlat.new()
	div_style.bg_color = Color(COLOR_NEUTRAL, 0.4)
	div_style.set_content_margin_all(0)
	_divider.add_theme_stylebox_override("separator", div_style)

	var alert_div_style := StyleBoxFlat.new()
	alert_div_style.bg_color = Color(COLOR_NEUTRAL, 0.3)
	alert_div_style.set_content_margin_all(0)
	_alert_divider.add_theme_stylebox_override("separator", alert_div_style)

func _apply_bar_styles() -> void:
	for bar: ProgressBar in _bars:
		var bar_bg := StyleBoxFlat.new()
		bar_bg.bg_color = COLOR_BAR_BG
		bar_bg.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("background", bar_bg)
		var bar_fill := StyleBoxFlat.new()
		bar_fill.bg_color = COLOR_TEAL
		bar_fill.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("fill", bar_fill)

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
	_icons[index].modulate = color

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
			Global.debug_log("ShipStatsSidebar: alerts cleared")
		else:
			var joined: String = ", ".join(new_alerts)
			Global.debug_log("ShipStatsSidebar: active alerts — %s" % joined)
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
