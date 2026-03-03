## ResourceTypeWheel - Radial wheel UI for selecting a resource type before scanner ping - Owner: gameplay-programmer
## Displays one segment per pingable resource type (sourced dynamically from ResourceDefs).
## Selection via mouse direction (keyboard/mouse) or left stick (gamepad).
## Highlights the segment nearest the input direction; returns selected type on query.
class_name ResourceTypeWheel
extends Control

# ── Signals ──────────────────────────────────────────────
signal type_selected(resource_type: ResourceDefs.ResourceType)

# ── Constants ─────────────────────────────────────────────
const WHEEL_RADIUS: float = 120.0
const INNER_RADIUS: float = 40.0
const ICON_SIZE: float = 32.0
const DEAD_ZONE: float = 0.3

const COLOR_BACKGROUND := Color("#0A0F18", 0.85)
const COLOR_BORDER := Color("#007A63")
const COLOR_HIGHLIGHT := Color("#00D4AA", 0.35)
const COLOR_HIGHLIGHT_BORDER := Color("#00D4AA")
const COLOR_TEXT_PRIMARY := Color("#F1F5F9")
const COLOR_TEXT_SELECTED := Color("#00D4AA")

const ARC_STEPS: int = 32

# ── Private Variables ─────────────────────────────────────
var _segments: Array[Dictionary] = []
var _segment_icons: Array[Texture2D] = []
var _selected_index: int = -1
var _last_used_type: ResourceDefs.ResourceType = ResourceDefs.ResourceType.NONE

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	# visible, mouse_filter, and anchors set in game_hud.tscn (scene-first)
	_build_segments()


func _draw() -> void:
	if not visible or _segments.is_empty():
		return

	var center: Vector2 = size / 2.0
	var segment_count: int = _segments.size()
	var angle_per_segment: float = TAU / segment_count

	# Background circle
	draw_circle(center, WHEEL_RADIUS + 4.0, COLOR_BACKGROUND)
	draw_arc(center, WHEEL_RADIUS + 4.0, 0.0, TAU, 64, COLOR_BORDER, 2.0)

	# Inner circle border
	draw_arc(center, INNER_RADIUS, 0.0, TAU, 64, COLOR_BORDER, 1.0)

	for i: int in range(segment_count):
		# Segments start pointing up (-PI/2) and go clockwise
		var angle_start: float = i * angle_per_segment - PI / 2.0
		var angle_end: float = (i + 1) * angle_per_segment - PI / 2.0
		var angle_mid: float = (angle_start + angle_end) / 2.0

		# Highlight selected segment
		if i == _selected_index:
			_draw_segment_highlight(center, angle_start, angle_end)

		# Segment divider lines
		if segment_count > 1:
			var divider_inner: Vector2 = center + Vector2(cos(angle_start), sin(angle_start)) * INNER_RADIUS
			var divider_outer: Vector2 = center + Vector2(cos(angle_start), sin(angle_start)) * WHEEL_RADIUS
			draw_line(divider_inner, divider_outer, COLOR_BORDER, 1.0)

		# Icon at the midpoint between inner and outer radius
		var icon_distance: float = (INNER_RADIUS + WHEEL_RADIUS) / 2.0
		var icon_center: Vector2 = center + Vector2(cos(angle_mid), sin(angle_mid)) * icon_distance
		if i < _segment_icons.size() and _segment_icons[i] != null:
			var icon_rect := Rect2(
				icon_center - Vector2(ICON_SIZE, ICON_SIZE) / 2.0,
				Vector2(ICON_SIZE, ICON_SIZE)
			)
			draw_texture_rect(_segment_icons[i], icon_rect, false)

		# Resource name label outside the wheel
		var label_distance: float = WHEEL_RADIUS + 20.0
		var label_center: Vector2 = center + Vector2(cos(angle_mid), sin(angle_mid)) * label_distance
		var font: Font = ThemeDB.fallback_font
		var font_size: int = 13
		var segment_name: String = _segments[i].get("name", "") as String
		var text_width: float = font.get_string_size(segment_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var text_pos: Vector2 = label_center - Vector2(text_width / 2.0, -4.0)
		var text_color: Color = COLOR_TEXT_SELECTED if i == _selected_index else COLOR_TEXT_PRIMARY
		draw_string(font, text_pos, segment_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)


# ── Public Methods ────────────────────────────────────────

## Opens the radial wheel and resets the highlight to no segment.
func show_wheel() -> void:
	if _segments.is_empty():
		return
	visible = true
	_selected_index = -1
	queue_redraw()
	Global.debug_log("ResourceTypeWheel: opened with %d segments" % _segments.size())


## Hides the radial wheel.
func hide_wheel() -> void:
	visible = false
	Global.debug_log("ResourceTypeWheel: closed")


## Returns true if the wheel is currently showing.
func is_showing() -> bool:
	return visible


## Updates which segment is highlighted based on an input direction vector.
## The vector does not need to be normalized — magnitude above DEAD_ZONE is sufficient.
func update_selection(direction: Vector2) -> void:
	if direction.length() < DEAD_ZONE:
		return
	if _segments.is_empty():
		return

	var angle: float = direction.angle()
	var segment_count: int = _segments.size()
	var angle_per_segment: float = TAU / segment_count

	# Offset by +PI/2 so that "up" (negative Y) maps to the first segment
	var adjusted_angle: float = angle + PI / 2.0
	if adjusted_angle < 0.0:
		adjusted_angle += TAU
	adjusted_angle = fmod(adjusted_angle, TAU)

	var new_index: int = int(adjusted_angle / angle_per_segment)
	new_index = clampi(new_index, 0, segment_count - 1)

	if new_index != _selected_index:
		_selected_index = new_index
		queue_redraw()


## Returns the currently selected resource type.
## Falls back to last-used type, then first available on first use.
func get_selected_type() -> ResourceDefs.ResourceType:
	if _selected_index >= 0 and _selected_index < _segments.size():
		var selected: ResourceDefs.ResourceType = _segments[_selected_index]["resource_type"] as ResourceDefs.ResourceType
		_last_used_type = selected
		return selected
	# No explicit selection — use last-used or first available
	return get_last_used_type()


## Returns the last-used resource type for quick-tap ping (no wheel shown).
## Defaults to the first available type on first use.
func get_last_used_type() -> ResourceDefs.ResourceType:
	if _last_used_type != ResourceDefs.ResourceType.NONE:
		return _last_used_type
	if not _segments.is_empty():
		var first_type: ResourceDefs.ResourceType = _segments[0]["resource_type"] as ResourceDefs.ResourceType
		_last_used_type = first_type
		return first_type
	return ResourceDefs.ResourceType.NONE


## Returns true if the wheel has any segments to display.
func has_segments() -> bool:
	return not _segments.is_empty()


# ── Private Methods ───────────────────────────────────────

## Builds the segment list by querying ResourceDefs for all raw_material resource types.
func _build_segments() -> void:
	_segments.clear()
	_segment_icons.clear()
	for type_key: int in ResourceDefs.RESOURCE_CATALOG:
		var entry: Dictionary = ResourceDefs.RESOURCE_CATALOG[type_key]
		var category: String = entry.get("category", "") as String
		if category != "raw_material":
			continue
		var resource_type: ResourceDefs.ResourceType = type_key as ResourceDefs.ResourceType
		_segments.append({
			"resource_type": resource_type,
			"name": entry.get("name", "Unknown") as String,
		})
		var icon_path: String = entry.get("icon", "") as String
		if icon_path != "":
			var icon: Texture2D = load(icon_path) as Texture2D
			_segment_icons.append(icon)
		else:
			_segment_icons.append(null)
	Global.debug_log("ResourceTypeWheel: built %d segments from ResourceDefs" % _segments.size())


## Draws the highlighted arc segment for the selected index.
func _draw_segment_highlight(center: Vector2, angle_start: float, angle_end: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var angle_step: float = (angle_end - angle_start) / ARC_STEPS

	# Inner arc (start to end)
	for i: int in range(ARC_STEPS + 1):
		var a: float = angle_start + i * angle_step
		points.append(center + Vector2(cos(a), sin(a)) * INNER_RADIUS)

	# Outer arc (end to start — closing the polygon)
	for i: int in range(ARC_STEPS, -1, -1):
		var a: float = angle_start + i * angle_step
		points.append(center + Vector2(cos(a), sin(a)) * WHEEL_RADIUS)

	draw_colored_polygon(points, COLOR_HIGHLIGHT)
	draw_arc(center, WHEEL_RADIUS, angle_start, angle_end, ARC_STEPS, COLOR_HIGHLIGHT_BORDER, 2.0)
	draw_arc(center, INNER_RADIUS, angle_start, angle_end, ARC_STEPS, COLOR_HIGHLIGHT_BORDER, 1.0)
