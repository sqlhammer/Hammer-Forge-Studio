## Ship globals HUD: displays Power, Integrity, Heat, Oxygen bars when inside the ship.
## Positioned bottom-right, signal-driven via ShipState. Slides in/out on ship enter/exit.
class_name ShipGlobalsHUD
extends Control

# ── Constants ─────────────────────────────────────────────
const PANEL_WIDTH: float = 220.0
const PANEL_HEIGHT: float = 180.0
const BAR_WIDTH: float = 120.0
const BAR_HEIGHT: float = 8.0
const ICON_SIZE: float = 20.0
const LABEL_WIDTH: float = 40.0
const ROW_HEIGHT: float = 20.0
const MARGIN: float = 32.0

## Colors per style guide
const COLOR_PANEL_BG := Color("#0F1923", 0.85)
const COLOR_PANEL_BORDER := Color("#1A2736")
const COLOR_BAR_BG := Color("#1A2736")
const COLOR_TEAL := Color("#00D4AA")
const COLOR_AMBER := Color("#FFB830")
const COLOR_CORAL := Color("#FF6B5A")
const COLOR_ICE_BLUE := Color("#60A5FA")
const COLOR_TEXT_PRIMARY := Color("#F1F5F9")
const COLOR_TEXT_SECONDARY := Color("#94A3B8")
const COLOR_NEUTRAL := Color("#94A3B8")

## State thresholds
const POWER_LOW: float = 49.0
const POWER_CRITICAL: float = 19.0
const INTEGRITY_DAMAGED: float = 74.0
const INTEGRITY_CRITICAL: float = 29.0
const HEAT_COLD: float = 24.0
const HEAT_HOT: float = 76.0
const OXYGEN_LOW: float = 49.0
const OXYGEN_CRITICAL: float = 19.0

const PULSE_SPEED: float = 4.2  # ~1.5s loop

const SLIDE_IN_DURATION: float = 0.2
const SLIDE_OUT_DURATION: float = 0.15

# ── Private Variables ─────────────────────────────────────
var _bars: Array[ProgressBar] = []
var _icons: Array[ColorRect] = []
var _labels: Array[Label] = []
var _values: Array[float] = [100.0, 100.0, 50.0, 100.0]
var _is_visible: bool = false
var _panel: PanelContainer = null
var _pulse_timer: float = 0.0
var _critical_states: Array[bool] = [false, false, false, false]

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	_connect_signals()
	# Start hidden off-screen to the right
	_panel.position.x = PANEL_WIDTH + MARGIN
	visible = true
	_panel.modulate.a = 0.0

func _process(delta: float) -> void:
	if not _is_visible:
		return
	_pulse_timer += delta * PULSE_SPEED
	_update_bar_colors()

# ── Public Methods ────────────────────────────────────────

## Shows or hides the ship globals display with slide animation.
func set_ship_visible(show: bool) -> void:
	if show == _is_visible:
		return
	_is_visible = show
	Global.log("ShipGlobalsHUD: %s" % ("showing" if show else "hiding"))
	if show:
		_refresh_all_values()
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(_panel, "position:x", 0.0, SLIDE_IN_DURATION).set_ease(Tween.EASE_OUT)
		tween.tween_property(_panel, "modulate:a", 1.0, SLIDE_IN_DURATION)
	else:
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		var offscreen_x: float = PANEL_WIDTH + MARGIN
		tween.tween_property(_panel, "position:x", offscreen_x, SLIDE_OUT_DURATION).set_ease(Tween.EASE_IN)
		tween.tween_property(_panel, "modulate:a", 0.0, SLIDE_OUT_DURATION)

# ── Private Methods ───────────────────────────────────────

func _build_ui() -> void:
	custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)

	_panel = PanelContainer.new()
	_panel.name = "ShipStatusPanel"
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_PANEL_BG
	panel_style.border_color = COLOR_PANEL_BORDER
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", panel_style)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "SHIP STATUS"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	vbox.add_child(title)

	# Divider
	var divider := HSeparator.new()
	var div_style := StyleBoxFlat.new()
	div_style.bg_color = Color(COLOR_NEUTRAL, 0.3)
	div_style.set_content_margin_all(0)
	divider.add_theme_stylebox_override("separator", div_style)
	vbox.add_child(divider)

	# Four variable rows: Power, Integrity, Heat, Oxygen
	var var_names: Array[String] = ["P", "I", "H", "O"]
	for i: int in range(4):
		var row := _create_variable_row(var_names[i], i)
		vbox.add_child(row)

func _create_variable_row(icon_text: String, index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Icon placeholder (colored rect with letter)
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
	icon_label.add_theme_font_size_override("font_size", 12)
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
	label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
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

func _refresh_all_values() -> void:
	_values[0] = ShipState.get_power()
	_values[1] = ShipState.get_integrity()
	_values[2] = ShipState.get_heat()
	_values[3] = ShipState.get_oxygen()
	for i: int in range(4):
		_bars[i].value = _values[i]
		_labels[i].text = "%d%%" % int(_values[i])
	_update_bar_colors()

func _update_bar_colors() -> void:
	# Power
	var power_color: Color = _get_power_color(_values[0])
	_apply_bar_color(0, power_color)

	# Integrity
	var integrity_color: Color = _get_integrity_color(_values[1])
	_apply_bar_color(1, integrity_color)

	# Heat
	var heat_color: Color = _get_heat_color(_values[2])
	_apply_bar_color(2, heat_color)

	# Oxygen
	var oxygen_color: Color = _get_oxygen_color(_values[3])
	_apply_bar_color(3, oxygen_color)

func _apply_bar_color(index: int, color: Color) -> void:
	var fill_style: StyleBoxFlat = _bars[index].get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	fill_style.bg_color = color
	_bars[index].add_theme_stylebox_override("fill", fill_style)
	_labels[index].add_theme_color_override("font_color", color)
	_icons[index].color = color

func _get_power_color(value: float) -> Color:
	if value <= POWER_CRITICAL:
		_critical_states[0] = true
		return _pulse_color(COLOR_CORAL)
	elif value <= POWER_LOW:
		_critical_states[0] = false
		return COLOR_AMBER
	else:
		_critical_states[0] = false
		return COLOR_TEAL

func _get_integrity_color(value: float) -> Color:
	if value <= INTEGRITY_CRITICAL:
		_critical_states[1] = true
		return _pulse_color(COLOR_CORAL)
	elif value <= INTEGRITY_DAMAGED:
		_critical_states[1] = false
		return COLOR_AMBER
	else:
		_critical_states[1] = false
		return COLOR_TEAL

func _get_heat_color(value: float) -> Color:
	if value <= HEAT_COLD:
		_critical_states[2] = false
		return COLOR_ICE_BLUE
	elif value >= HEAT_HOT:
		_critical_states[2] = true
		return _pulse_color(COLOR_CORAL)
	else:
		_critical_states[2] = false
		return COLOR_TEAL

func _get_oxygen_color(value: float) -> Color:
	if value <= OXYGEN_CRITICAL:
		_critical_states[3] = true
		return _pulse_color(COLOR_CORAL)
	elif value <= OXYGEN_LOW:
		_critical_states[3] = false
		return COLOR_AMBER
	else:
		_critical_states[3] = false
		return COLOR_TEAL

func _pulse_color(base_color: Color) -> Color:
	var pulse_alpha: float = 0.7 + 0.3 * (sin(_pulse_timer) * 0.5 + 0.5)
	return Color(base_color, pulse_alpha)

# ── Signal Handlers ──────────────────────────────────────

func _on_power_changed(current: float, _maximum: float) -> void:
	var was_critical: bool = _values[0] <= POWER_CRITICAL
	_values[0] = current
	var is_critical: bool = current <= POWER_CRITICAL
	if is_critical and not was_critical:
		Global.log("ShipGlobalsHUD: power entered critical state (%.0f%%)" % current)
	elif not is_critical and was_critical:
		Global.log("ShipGlobalsHUD: power exited critical state (%.0f%%)" % current)
	if _is_visible:
		_bars[0].value = current
		_labels[0].text = "%d%%" % int(current)

func _on_integrity_changed(current: float, _maximum: float) -> void:
	var was_critical: bool = _values[1] <= INTEGRITY_CRITICAL
	_values[1] = current
	var is_critical: bool = current <= INTEGRITY_CRITICAL
	if is_critical and not was_critical:
		Global.log("ShipGlobalsHUD: integrity entered critical state (%.0f%%)" % current)
	elif not is_critical and was_critical:
		Global.log("ShipGlobalsHUD: integrity exited critical state (%.0f%%)" % current)
	if _is_visible:
		_bars[1].value = current
		_labels[1].text = "%d%%" % int(current)

func _on_heat_changed(current: float, _maximum: float) -> void:
	var was_critical: bool = _values[2] >= HEAT_HOT
	_values[2] = current
	var is_critical: bool = current >= HEAT_HOT
	if is_critical and not was_critical:
		Global.log("ShipGlobalsHUD: heat entered critical state (%.0f%%)" % current)
	elif not is_critical and was_critical:
		Global.log("ShipGlobalsHUD: heat exited critical state (%.0f%%)" % current)
	if _is_visible:
		_bars[2].value = current
		_labels[2].text = "%d%%" % int(current)

func _on_oxygen_changed(current: float, _maximum: float) -> void:
	var was_critical: bool = _values[3] <= OXYGEN_CRITICAL
	_values[3] = current
	var is_critical: bool = current <= OXYGEN_CRITICAL
	if is_critical and not was_critical:
		Global.log("ShipGlobalsHUD: oxygen entered critical state (%.0f%%)" % current)
	elif not is_critical and was_critical:
		Global.log("ShipGlobalsHUD: oxygen exited critical state (%.0f%%)" % current)
	if _is_visible:
		_bars[3].value = current
		_labels[3].text = "%d%%" % int(current)
