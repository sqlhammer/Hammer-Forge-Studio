## Mining progress bar HUD: shows extraction progress centered below crosshair.
class_name MiningProgress
extends Control

# ── Constants ─────────────────────────────────────────────
const BAR_WIDTH: float = 240.0
const BAR_HEIGHT: float = 12.0
const TOTAL_HEIGHT: float = 40.0
const HOLD_DURATION: float = 0.5
const FADE_DURATION: float = 0.3

## Style colors matching UI style guide
const COLOR_TEAL := Color("#00D4AA")
const COLOR_GREEN := Color("#4ADE80")
const COLOR_CORAL := Color("#FF6B5A")
const COLOR_BAR_BG := Color("#1A2736", 0.8)
const COLOR_TEXT_PRIMARY := Color("#F1F5F9")

# ── Private Variables ─────────────────────────────────────
var _progress: float = 0.0
var _status_text: String = "EXTRACTING"
var _status_color: Color = COLOR_TEAL
var _bar_color: Color = COLOR_TEAL
var _is_active: bool = false
var _completion_timer: float = 0.0
var _is_completing: bool = false
var _font: Font = null

# ── Public Methods ────────────────────────────────────────

## Shows the mining progress bar with optional custom label.
func show_progress(label: String = "EXTRACTING", color: Color = COLOR_TEAL) -> void:
	_is_active = true
	_is_completing = false
	_status_text = label
	_status_color = color
	_bar_color = color
	_progress = 0.0
	visible = true
	modulate.a = 1.0

## Updates the progress value (0.0 to 1.0).
func update_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)

## Shows completion state then fades.
func show_complete() -> void:
	_status_text = "COMPLETE"
	_status_color = COLOR_GREEN
	_bar_color = COLOR_GREEN
	_progress = 1.0
	_is_completing = true
	_completion_timer = HOLD_DURATION

## Shows failure state then fades.
func show_failed(reason: String) -> void:
	_status_text = reason
	_status_color = COLOR_CORAL
	_bar_color = COLOR_CORAL
	_is_completing = true
	_completion_timer = HOLD_DURATION * 2.0

## Hides the progress bar immediately via fade.
func hide_progress() -> void:
	_is_active = false
	_is_completing = false
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func() -> void: visible = false)

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	custom_minimum_size = Vector2(BAR_WIDTH, TOTAL_HEIGHT)
	_font = ThemeDB.fallback_font
	visible = false

func _process(delta: float) -> void:
	if _is_completing:
		_completion_timer -= delta
		if _completion_timer <= 0.0:
			hide_progress()
			return
	queue_redraw()

func _draw() -> void:
	if not visible:
		return

	var center_x: float = BAR_WIDTH / 2.0

	# Draw status label
	var text_size: Vector2 = _font.get_string_size(_status_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	draw_string(
		_font,
		Vector2(center_x - text_size.x / 2.0, 14),
		_status_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		_status_color,
	)

	# Draw progress bar background
	var bar_y: float = 22.0
	draw_rect(Rect2(0, bar_y, BAR_WIDTH, BAR_HEIGHT), COLOR_BAR_BG, true)

	# Draw progress bar fill
	var fill_width: float = BAR_WIDTH * _progress
	if fill_width > 0:
		draw_rect(Rect2(0, bar_y, fill_width, BAR_HEIGHT), _bar_color, true)

		# Glow on leading edge
		var glow_color := Color(_bar_color, 0.5)
		var glow_x: float = maxf(fill_width - 4, 0)
		draw_rect(Rect2(glow_x, bar_y, minf(4, fill_width), BAR_HEIGHT), glow_color, true)
