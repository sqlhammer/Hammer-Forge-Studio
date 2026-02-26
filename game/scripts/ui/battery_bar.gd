## Battery bar HUD: always-visible suit battery display with state-driven colors.
class_name BatteryBar
extends Control

# ── Constants ─────────────────────────────────────────────
const BAR_WIDTH: float = 160.0
const BAR_HEIGHT: float = 10.0
const ICON_SIZE: float = 24.0
const TOTAL_WIDTH: float = 200.0
const TOTAL_HEIGHT: float = 48.0
const CRITICAL_THRESHOLD: float = 0.25
const PULSE_SPEED: float = 4.2  # ~1.5s loop (2*PI / 1.5)

## Style colors matching UI style guide
const COLOR_FULL := Color("#4ADE80")
const COLOR_NORMAL := Color("#00D4AA")
const COLOR_CRITICAL := Color("#FF6B5A")
const COLOR_BAR_BG := Color("#1A2736")
const COLOR_RECHARGE_SHIMMER := Color("#00D4AA", 0.3)

# ── Private Variables ─────────────────────────────────────
var _charge_percent: float = 1.0
var _is_depleted: bool = false
var _is_recharging: bool = false
var _pulse_timer: float = 0.0
var _flash_timer: float = 0.0
var _flash_visible: bool = true
var _shimmer_offset: float = 0.0
var _font_mono: Font = null
var _bar_rect := Rect2(0, 0, 0, 0)
var _icon_texture: Texture2D = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	custom_minimum_size = Vector2(TOTAL_WIDTH, TOTAL_HEIGHT)
	_font_mono = ThemeDB.fallback_font
	_icon_texture = load("res://assets/icons/hud/icon_hud_battery.svg") as Texture2D
	SuitBattery.charge_changed.connect(_on_charge_changed)
	SuitBattery.battery_depleted.connect(_on_battery_depleted)
	SuitBattery.battery_recharged.connect(_on_battery_recharged)
	_charge_percent = SuitBattery.get_charge_percent()

func _process(delta: float) -> void:
	_pulse_timer += delta * PULSE_SPEED
	_is_recharging = SuitBattery.is_recharging()

	if _is_depleted:
		_flash_timer += delta
		if _flash_timer >= 0.5:
			_flash_timer = 0.0
			_flash_visible = not _flash_visible

	if _is_recharging:
		_shimmer_offset += delta
		if _shimmer_offset > 1.0:
			_shimmer_offset -= 1.0

	queue_redraw()

func _draw() -> void:
	var x_offset: float = 0.0
	var y_center: float = TOTAL_HEIGHT / 2.0

	# Determine state color
	var state_color: Color = _get_state_color()

	# Draw battery icon
	if _icon_texture:
		var icon_rect := Rect2(x_offset, y_center - ICON_SIZE / 2.0, ICON_SIZE, ICON_SIZE)
		draw_texture_rect(_icon_texture, icon_rect, false, state_color)
	x_offset += ICON_SIZE + 8.0

	# Draw progress bar background
	_bar_rect = Rect2(x_offset, y_center - BAR_HEIGHT / 2.0, BAR_WIDTH, BAR_HEIGHT)
	draw_rect(_bar_rect, COLOR_BAR_BG, true)

	# Draw progress bar fill
	var fill_width: float = BAR_WIDTH * _charge_percent
	if fill_width > 0 and (_flash_visible or not _is_depleted):
		var fill_rect := Rect2(_bar_rect.position.x, _bar_rect.position.y, fill_width, BAR_HEIGHT)
		draw_rect(fill_rect, state_color, true)

	# Draw recharge shimmer
	if _is_recharging and fill_width > 0:
		var shimmer_x: float = _bar_rect.position.x + _shimmer_offset * fill_width
		var shimmer_rect := Rect2(shimmer_x - 10, _bar_rect.position.y, 20, BAR_HEIGHT)
		shimmer_rect = shimmer_rect.intersection(_bar_rect)
		if shimmer_rect.has_area():
			draw_rect(shimmer_rect, COLOR_RECHARGE_SHIMMER, true)

	x_offset += BAR_WIDTH + 8.0

	# Draw percentage text
	var percent_text: String = "%d%%" % int(_charge_percent * 100)
	draw_string(
		_font_mono,
		Vector2(x_offset, y_center + 6),
		percent_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		state_color,
	)

# ── Private Methods ───────────────────────────────────────

func _get_state_color() -> Color:
	if _charge_percent >= 1.0:
		return COLOR_FULL
	elif _charge_percent <= 0.0 or _is_depleted:
		return COLOR_CRITICAL
	elif _charge_percent <= CRITICAL_THRESHOLD:
		# Pulse between 70% and 100% opacity
		var pulse_alpha: float = 0.7 + 0.3 * (sin(_pulse_timer) * 0.5 + 0.5)
		return Color(COLOR_CRITICAL, pulse_alpha)
	else:
		return COLOR_NORMAL

func _on_charge_changed(current: float, maximum: float) -> void:
	if maximum > 0.0:
		_charge_percent = current / maximum
	else:
		_charge_percent = 0.0
	_is_depleted = current <= 0.0
	if not _is_depleted:
		_flash_visible = true
		_flash_timer = 0.0

func _on_battery_depleted() -> void:
	_is_depleted = true
	_flash_timer = 0.0
	_flash_visible = true

func _on_battery_recharged() -> void:
	_is_depleted = false
	_flash_visible = true
