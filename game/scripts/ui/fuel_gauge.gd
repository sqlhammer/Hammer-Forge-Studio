## Fuel gauge HUD: always-visible ship fuel level display with state-driven colors.
## Connects to FuelSystem signals (fuel_changed, fuel_low, fuel_empty) for real-time updates.
## Four visual states: full (green), normal (teal), low (amber pulse), empty (coral flash).
## Owner: gameplay-programmer — Ticket: TICKET-0169
class_name FuelGauge
extends Control

# ── Constants ─────────────────────────────────────────────
const BAR_WIDTH: float = 160.0
const BAR_HEIGHT: float = 10.0
const ICON_SIZE: float = 24.0
const TOTAL_WIDTH: float = 200.0
const TOTAL_HEIGHT: float = 48.0
const LOW_THRESHOLD: float = FuelSystemDefs.LOW_FUEL_THRESHOLD_PERCENT
const PULSE_SPEED: float = 4.2  # ~1.5s loop (2*PI / 1.5)
const FLASH_INTERVAL: float = 0.5
const FLASH_DURATION: float = 3.0

## Style colors matching UI style guide (identical to battery bar palette)
const COLOR_FULL := Color("#4ADE80")
const COLOR_NORMAL := Color("#00D4AA")
const COLOR_LOW := Color("#FFB830")
const COLOR_EMPTY := Color("#FF6B5A")
const COLOR_BAR_BG := Color("#1A2736")

# ── Private Variables ─────────────────────────────────────
var _fuel_percent: float = 1.0
var _is_low: bool = false
var _is_empty: bool = false
var _pulse_timer: float = 0.0
var _flash_timer: float = 0.0
var _flash_elapsed: float = 0.0
var _flash_visible: bool = true
var _font_mono: Font = null
var _bar_rect := Rect2(0, 0, 0, 0)
var _icon_texture: Texture2D = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	custom_minimum_size = Vector2(TOTAL_WIDTH, TOTAL_HEIGHT)
	_font_mono = ThemeDB.fallback_font
	_icon_texture = load("res://assets/icons/item/icon_item_fuel_cell.svg") as Texture2D
	FuelSystem.fuel_changed.connect(_on_fuel_changed)
	FuelSystem.fuel_low.connect(_on_fuel_low)
	FuelSystem.fuel_empty.connect(_on_fuel_empty)
	# Initialize from current fuel state
	_fuel_percent = FuelSystem.fuel_current / FuelSystem.fuel_max if FuelSystem.fuel_max > 0.0 else 0.0

func _process(delta: float) -> void:
	_pulse_timer += delta * PULSE_SPEED

	if _is_empty:
		_flash_elapsed += delta
		_flash_timer += delta
		if _flash_timer >= FLASH_INTERVAL:
			_flash_timer = 0.0
			_flash_visible = not _flash_visible
		# After flash duration, hold at 50% opacity
		if _flash_elapsed >= FLASH_DURATION:
			_flash_visible = true

	queue_redraw()

func _draw() -> void:
	var x_offset: float = 0.0
	var y_center: float = TOTAL_HEIGHT / 2.0

	var state_color: Color = _get_state_color()

	# Draw fuel icon
	if _icon_texture:
		var icon_rect := Rect2(x_offset, y_center - ICON_SIZE / 2.0, ICON_SIZE, ICON_SIZE)
		draw_texture_rect(_icon_texture, icon_rect, false, state_color)
	x_offset += ICON_SIZE + 8.0

	# Draw progress bar background
	_bar_rect = Rect2(x_offset, y_center - BAR_HEIGHT / 2.0, BAR_WIDTH, BAR_HEIGHT)
	draw_rect(_bar_rect, COLOR_BAR_BG, true)

	# Draw progress bar fill
	var fill_width: float = BAR_WIDTH * _fuel_percent
	if fill_width > 0 and (_flash_visible or not _is_empty):
		var fill_rect := Rect2(_bar_rect.position.x, _bar_rect.position.y, fill_width, BAR_HEIGHT)
		draw_rect(fill_rect, state_color, true)

	x_offset += BAR_WIDTH + 8.0

	# Draw percentage text
	var percent_text: String = get_percent_text()
	draw_string(
		_font_mono,
		Vector2(x_offset, y_center + 6),
		percent_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		state_color,
	)

# ── Public Methods ────────────────────────────────────────

## Updates the fuel display from external caller. Computes percentage internally.
func set_fuel_level(current: float, maximum: float) -> void:
	_on_fuel_changed(current, maximum)

## Returns the formatted percentage text for the current fuel level.
func get_percent_text() -> String:
	return "%d%%" % int(_fuel_percent * 100)

# ── Private Methods ───────────────────────────────────────

func _get_state_color() -> Color:
	if _is_empty or _fuel_percent <= 0.0:
		# Empty state — solid coral (flash handled in _draw fill visibility)
		if _is_empty and _flash_elapsed >= FLASH_DURATION:
			return Color(COLOR_EMPTY, 0.5)
		return COLOR_EMPTY
	elif _fuel_percent >= 1.0:
		return COLOR_FULL
	elif _is_low or _fuel_percent <= LOW_THRESHOLD:
		# Low state — pulse opacity between 70% and 100% over 1.5s
		var pulse_alpha: float = 0.7 + 0.3 * (sin(_pulse_timer) * 0.5 + 0.5)
		return Color(COLOR_LOW, pulse_alpha)
	else:
		return COLOR_NORMAL

func _on_fuel_changed(current: float, maximum: float) -> void:
	if maximum > 0.0:
		_fuel_percent = current / maximum
	else:
		_fuel_percent = 0.0
	# Clear state flags when fuel rises above thresholds
	if current > 0.0:
		_is_empty = false
		_flash_timer = 0.0
		_flash_elapsed = 0.0
		_flash_visible = true
	if _fuel_percent > LOW_THRESHOLD:
		_is_low = false
	Global.log("FuelGauge: updated to %.0f%%" % (_fuel_percent * 100.0))

func _on_fuel_low() -> void:
	_is_low = true
	Global.log("FuelGauge: LOW FUEL warning active")

func _on_fuel_empty() -> void:
	_is_empty = true
	_flash_timer = 0.0
	_flash_elapsed = 0.0
	_flash_visible = true
	Global.log("FuelGauge: FUEL EMPTY — flash animation started")
