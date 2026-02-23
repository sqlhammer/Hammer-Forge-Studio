## Compass bar HUD: shows cardinal directions and ping markers with distance readout.
class_name CompassBar
extends Control

# ── Constants ─────────────────────────────────────────────
const COMPASS_WIDTH: float = 600.0
const COMPASS_HEIGHT: float = 32.0
const MARKER_PERSIST_TIME: float = 60.0
const MARKER_FADE_TIME: float = 2.0
const DISTANCE_CONE_DEG: float = 45.0
const MAX_MARKERS: int = 10

## Style colors matching UI style guide
const COLOR_BG := Color("#0F1923", 0.7)
const COLOR_TEXT_PRIMARY := Color("#F1F5F9")
const COLOR_TEXT_SECONDARY := Color("#94A3B8")
const COLOR_TEAL := Color("#00D4AA")
const COLOR_NEUTRAL := Color("#94A3B8", 0.4)

## Cardinal directions with their degree headings
const CARDINALS: Dictionary = {
	0.0: "N", 45.0: "NE", 90.0: "E", 135.0: "SE",
	180.0: "S", 225.0: "SW", 270.0: "W", 315.0: "NW",
}

# ── Private Variables ─────────────────────────────────────
var _camera: Camera3D = null
var _player: CharacterBody3D = null
var _ping_markers: Array[Dictionary] = []  # { "deposit": Deposit, "time_added": float }
var _font: Font = null
var _font_mono: Font = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	custom_minimum_size = Vector2(COMPASS_WIDTH, 56)
	_font = ThemeDB.fallback_font
	_font_mono = ThemeDB.fallback_font

func _process(_delta: float) -> void:
	_clean_expired_markers()
	queue_redraw()

func _draw() -> void:
	if not _camera:
		return

	var player_yaw: float = _get_player_yaw_degrees()

	# Draw background
	var bg_rect := Rect2(0, 0, COMPASS_WIDTH, COMPASS_HEIGHT)
	draw_rect(bg_rect, COLOR_BG, true)

	# Draw cardinal labels and tick marks
	_draw_cardinals(player_yaw)

	# Draw center indicator
	var center_x: float = COMPASS_WIDTH / 2.0
	var indicator_points: PackedVector2Array = PackedVector2Array([
		Vector2(center_x - 4, COMPASS_HEIGHT + 2),
		Vector2(center_x + 4, COMPASS_HEIGHT + 2),
		Vector2(center_x, COMPASS_HEIGHT + 8),
	])
	draw_colored_polygon(indicator_points, COLOR_TEXT_PRIMARY)

	# Draw ping markers
	_draw_ping_markers(player_yaw)

# ── Public Methods ────────────────────────────────────────

## Initializes the compass with camera reference.
func setup(camera: Camera3D, player: CharacterBody3D) -> void:
	_camera = camera
	_player = player

## Adds ping markers for detected deposits.
func add_ping_markers(deposits: Array[Deposit]) -> void:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	for deposit: Deposit in deposits:
		# Skip if already tracked
		var already_tracked: bool = false
		for marker: Dictionary in _ping_markers:
			if marker.get("deposit") == deposit:
				already_tracked = true
				break
		if not already_tracked and _ping_markers.size() < MAX_MARKERS:
			Global.log("CompassBar: added ping marker — total markers: %d" % (_ping_markers.size() + 1))
			_ping_markers.append({
				"deposit": deposit,
				"time_added": current_time,
			})

## Removes a marker for a specific deposit (e.g., when depleted).
func remove_marker(deposit: Deposit) -> void:
	for i: int in range(_ping_markers.size() - 1, -1, -1):
		if _ping_markers[i].get("deposit") == deposit:
			_ping_markers.remove_at(i)
			break

# ── Private Methods ───────────────────────────────────────

func _get_player_yaw_degrees() -> float:
	if not _camera:
		return 0.0
	# Get the player body's Y rotation (yaw)
	var forward: Vector3 = -_camera.global_transform.basis.z
	var yaw_rad: float = atan2(forward.x, forward.z)
	var yaw_deg: float = rad_to_deg(yaw_rad)
	# Normalize to 0-360
	if yaw_deg < 0:
		yaw_deg += 360.0
	return yaw_deg

func _bearing_to_screen_x(bearing: float, player_yaw: float) -> float:
	# Calculate the angular difference between bearing and player yaw
	var diff: float = bearing - player_yaw
	# Normalize to -180 to 180
	while diff > 180.0:
		diff -= 360.0
	while diff < -180.0:
		diff += 360.0
	# Map to compass width: center = player_yaw, edges = +/-90 degrees
	var fov_half: float = 90.0
	var screen_x: float = (COMPASS_WIDTH / 2.0) + (diff / fov_half) * (COMPASS_WIDTH / 2.0)
	return screen_x

func _draw_cardinals(player_yaw: float) -> void:
	for degree: float in CARDINALS:
		var label: String = CARDINALS[degree]
		var screen_x: float = _bearing_to_screen_x(degree, player_yaw)

		# Only draw if visible on compass
		if screen_x < -20 or screen_x > COMPASS_WIDTH + 20:
			continue

		var is_major: bool = label.length() == 1  # N, S, E, W
		var color: Color = COLOR_TEXT_PRIMARY if is_major else COLOR_TEXT_SECONDARY
		var font_size: int = 14

		var text_width: float = _font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
		draw_string(_font, Vector2(screen_x - text_width / 2.0, 22), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

	# Draw minor tick marks at 15-degree intervals
	for deg: int in range(0, 360, 15):
		var deg_f: float = float(deg)
		if CARDINALS.has(deg_f):
			continue
		var screen_x: float = _bearing_to_screen_x(deg_f, player_yaw)
		if screen_x < 0 or screen_x > COMPASS_WIDTH:
			continue
		draw_line(Vector2(screen_x, 12), Vector2(screen_x, 20), COLOR_NEUTRAL, 1.0)

func _draw_ping_markers(player_yaw: float) -> void:
	if not _player:
		return

	var current_time: float = Time.get_ticks_msec() / 1000.0
	var player_pos: Vector3 = _player.global_position
	var nearest_deposit: Deposit = null
	var nearest_dist: float = INF

	# Find nearest pinged deposit
	for marker: Dictionary in _ping_markers:
		var deposit: Deposit = marker.get("deposit") as Deposit
		if not deposit or deposit.is_depleted():
			continue
		var dist: float = player_pos.distance_to(deposit.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_deposit = deposit

	for marker: Dictionary in _ping_markers:
		var deposit: Deposit = marker.get("deposit") as Deposit
		if not deposit or deposit.is_depleted():
			continue

		# Calculate bearing to deposit
		var to_deposit: Vector3 = deposit.global_position - player_pos
		var bearing: float = rad_to_deg(atan2(to_deposit.x, to_deposit.z))
		if bearing < 0:
			bearing += 360.0

		var screen_x: float = _bearing_to_screen_x(bearing, player_yaw)
		if screen_x < -10 or screen_x > COMPASS_WIDTH + 10:
			continue

		# Calculate opacity (nearest = 100%, others = 70%)
		var alpha: float = 1.0 if deposit == nearest_deposit else 0.7
		var marker_color := Color(COLOR_TEAL, alpha)

		# Draw marker triangle (pointing down from top of compass)
		var tri_points: PackedVector2Array = PackedVector2Array([
			Vector2(screen_x - 5, 0),
			Vector2(screen_x + 5, 0),
			Vector2(screen_x, 8),
		])
		draw_colored_polygon(tri_points, marker_color)

		# Show distance if facing within cone
		var angle_diff: float = absf(bearing - player_yaw)
		if angle_diff > 180.0:
			angle_diff = 360.0 - angle_diff
		if angle_diff <= DISTANCE_CONE_DEG / 2.0:
			var dist: float = player_pos.distance_to(deposit.global_position)
			var dist_text: String = "%dm" % int(dist)
			var text_size: Vector2 = _font_mono.get_string_size(dist_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18)
			draw_string(
				_font_mono,
				Vector2(screen_x - text_size.x / 2.0, COMPASS_HEIGHT + 22),
				dist_text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				18,
				COLOR_TEAL,
			)

func _clean_expired_markers() -> void:
	# Remove markers for depleted deposits
	for i: int in range(_ping_markers.size() - 1, -1, -1):
		var deposit: Deposit = _ping_markers[i].get("deposit") as Deposit
		if not deposit or not is_instance_valid(deposit) or deposit.is_depleted():
			_ping_markers.remove_at(i)
