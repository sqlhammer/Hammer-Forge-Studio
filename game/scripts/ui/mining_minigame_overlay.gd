## HUD overlay for the mining minigame: shows pattern line trace progress as pip indicators.
class_name MiningMinigameOverlay
extends Control

# ── Constants ─────────────────────────────────────────────
const OVERLAY_WIDTH: float = 320.0
const OVERLAY_HEIGHT: float = 52.0
const PIP_WIDTH: float = 40.0
const PIP_HEIGHT: float = 14.0
const PIP_GAP: float = 12.0
const RESULT_HOLD: float = 1.0
const FADE_DURATION: float = 0.3

## Style colors matching UI style guide
const COLOR_PENDING := Color("#1A2736", 0.6)
const COLOR_ACTIVE := Color("#00D4AA")  # Teal
const COLOR_TRACED := Color("#4ADE80")  # Green
const COLOR_MISSED := Color("#FF6B5A")  # Coral
const COLOR_AMBER := Color("#FFB830")
const COLOR_TEXT_PRIMARY := Color("#F1F5F9")

# ── Private Variables ─────────────────────────────────────
var _line_count: int = 0
var _pip_states: Array[int] = []  ## 0=pending, 1=active, 2=traced, 3=missed
var _active_index: int = -1
var _showing_result: bool = false
var _result_success: bool = false
var _result_timer: float = 0.0
var _bonus_quantity: int = 0
var _font: Font = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	# custom_minimum_size, visible, and mouse_filter set in mining_minigame_overlay.tscn (scene-first)
	_font = ThemeDB.fallback_font

func _process(delta: float) -> void:
	if _showing_result:
		_result_timer -= delta
		if _result_timer <= 0.0:
			dismiss()
			return
	queue_redraw()

func _draw() -> void:
	if not visible or _line_count <= 0:
		return

	var center_x: float = OVERLAY_WIDTH / 2.0

	# Header text
	var header_text: String = "TRACE PATTERN"
	var bonus_text: String = "(+50% bonus)"
	if _showing_result:
		if _result_success:
			header_text = "PATTERN COMPLETE"
			bonus_text = "+50% YIELD"
		else:
			header_text = "EXTRACTION COMPLETE"
			bonus_text = ""

	var header_color: Color = COLOR_TRACED if (_showing_result and _result_success) else COLOR_TEXT_PRIMARY
	var header_size: Vector2 = _font.get_string_size(header_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	var bonus_size: Vector2 = _font.get_string_size(bonus_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14) if bonus_text != "" else Vector2.ZERO

	var total_text_width: float = header_size.x + (8.0 + bonus_size.x if bonus_text != "" else 0.0)
	var text_start_x: float = center_x - total_text_width / 2.0

	draw_string(_font, Vector2(text_start_x, 14), header_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, header_color)
	if bonus_text != "":
		var bonus_color: Color = COLOR_TRACED if (_showing_result and _result_success) else COLOR_AMBER
		draw_string(_font, Vector2(text_start_x + header_size.x + 8.0, 14), bonus_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, bonus_color)

	# Pip indicators
	var total_pips_width: float = _line_count * PIP_WIDTH + (_line_count - 1) * PIP_GAP
	var pip_start_x: float = center_x - total_pips_width / 2.0
	var pip_y: float = 26.0

	for i: int in range(_line_count):
		var pip_x: float = pip_start_x + i * (PIP_WIDTH + PIP_GAP)
		var pip_color: Color = _get_pip_color(i)
		draw_rect(Rect2(pip_x, pip_y, PIP_WIDTH, PIP_HEIGHT), pip_color, true)

		# Border for visibility
		var border_color := Color(pip_color, minf(pip_color.a + 0.3, 1.0))
		draw_rect(Rect2(pip_x, pip_y, PIP_WIDTH, PIP_HEIGHT), border_color, false, 1.0)

# ── Public Methods ────────────────────────────────────────

## Shows the minigame overlay with the given number of pattern lines.
func show_minigame(line_count: int) -> void:
	_line_count = line_count
	_pip_states.clear()
	_active_index = -1
	_showing_result = false
	for i: int in range(line_count):
		_pip_states.append(0)
	visible = true
	modulate.a = 1.0

## Marks the pip at the given index as actively being traced.
func mark_line_active(index: int) -> void:
	_active_index = index

## Marks the pip at the given index as successfully traced.
func mark_line_traced(index: int) -> void:
	if index >= 0 and index < _pip_states.size():
		_pip_states[index] = 2

## Shows the result state (success or miss) then auto-dismisses.
func show_result(success: bool, bonus: int) -> void:
	_showing_result = true
	_result_success = success
	_bonus_quantity = bonus
	_result_timer = RESULT_HOLD
	_active_index = -1
	# Mark untraced pips as missed
	for i: int in range(_pip_states.size()):
		if _pip_states[i] != 2:
			_pip_states[i] = 3

## Immediately hides the overlay with a fade.
func dismiss() -> void:
	_showing_result = false
	_line_count = 0
	_active_index = -1
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func() -> void: visible = false)

# ── Private Methods ───────────────────────────────────────

func _get_pip_color(index: int) -> Color:
	if index >= _pip_states.size():
		return COLOR_PENDING
	match _pip_states[index]:
		0:
			if index == _active_index:
				return COLOR_ACTIVE
			return COLOR_PENDING
		2:
			return COLOR_TRACED
		3:
			return COLOR_MISSED
		_:
			return COLOR_PENDING
