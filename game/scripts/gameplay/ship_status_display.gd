## Diegetic ship status display: renders one ship global variable (Power, Integrity, Heat,
## or Oxygen) as a wall-mounted 3D panel using SubViewport for full UI rendering.
class_name ShipStatusDisplay
extends Node3D

# ── Constants ─────────────────────────────────────────────
const DISPLAY_WIDTH: float = 0.5
const DISPLAY_HEIGHT: float = 0.25
const VIEWPORT_WIDTH: int = 256
const VIEWPORT_HEIGHT: int = 128

## Colors matching HUD style guide exactly
const COLOR_PANEL_BG := Color("#0F1923")
const COLOR_BAR_BG := Color("#1A2736")
const COLOR_TEAL := Color("#00D4AA")
const COLOR_AMBER := Color("#FFB830")
const COLOR_CORAL := Color("#FF6B5A")
const COLOR_ICE_BLUE := Color("#60A5FA")
const COLOR_TEXT_SECONDARY := Color("#94A3B8")
const COLOR_FRAME := Color("#333333")

## State thresholds matching HUD exactly
const POWER_LOW: float = 49.0
const POWER_CRITICAL: float = 19.0
const INTEGRITY_DAMAGED: float = 74.0
const INTEGRITY_CRITICAL: float = 29.0
const HEAT_COLD: float = 24.0
const HEAT_HOT: float = 76.0
const OXYGEN_LOW: float = 49.0
const OXYGEN_CRITICAL: float = 19.0

const PULSE_SPEED: float = 4.2

# ── Exported Variables ────────────────────────────────────
@export var variable_name: String = "POWER"
@export var variable_type: String = "power"

# ── Private Variables ─────────────────────────────────────
var _viewport: SubViewport = null
var _value_label: Label = null
var _bar: ProgressBar = null
var _current_value: float = 0.0
var _is_critical: bool = false
var _pulse_timer: float = 0.0

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_build_display()
	_connect_ship_state()
	_refresh_value()
	Global.debug_log("ShipStatusDisplay: initialized for %s" % variable_name)

func _process(delta: float) -> void:
	if _is_critical:
		_pulse_timer += delta * PULSE_SPEED
		_update_colors()

# ── Private Methods ───────────────────────────────────────

func _build_display() -> void:
	_build_frame()
	_build_viewport_ui()
	_build_screen_mesh()

func _build_frame() -> void:
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = COLOR_FRAME
	frame_mat.roughness = 0.8

	var frame := MeshInstance3D.new()
	frame.name = "Frame"
	var box := BoxMesh.new()
	var frame_width: float = DISPLAY_WIDTH + 0.02
	var frame_height: float = DISPLAY_HEIGHT + 0.02
	box.size = Vector3(frame_width, frame_height, 0.015)
	frame.mesh = box
	frame.material_override = frame_mat
	frame.position = Vector3(0.0, 0.0, -0.008)
	add_child(frame)

func _build_viewport_ui() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "DisplayViewport"
	_viewport.size = Vector2i(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	# Dark background panel
	var bg := Panel.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COLOR_PANEL_BG
	bg.add_theme_stylebox_override("panel", bg_style)
	_viewport.add_child(bg)

	# Variable name label at top-left
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = variable_name
	name_label.position = Vector2(12, 8)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_viewport.add_child(name_label)

	# Percentage value at top-right
	_value_label = Label.new()
	_value_label.name = "ValueLabel"
	_value_label.text = "100%"
	_value_label.position = Vector2(128, 4)
	_value_label.size = Vector2(116, 40)
	_value_label.add_theme_font_size_override("font_size", 32)
	_value_label.add_theme_color_override("font_color", COLOR_TEAL)
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_viewport.add_child(_value_label)

	# Color-coded progress bar across the lower area
	_bar = ProgressBar.new()
	_bar.name = "StatusBar"
	_bar.position = Vector2(12, 60)
	_bar.custom_minimum_size = Vector2(232, 18)
	_bar.size = Vector2(232, 18)
	_bar.max_value = 100.0
	_bar.value = 100.0
	_bar.show_percentage = false

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = COLOR_BAR_BG
	bar_bg.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = COLOR_TEAL
	bar_fill.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("fill", bar_fill)

	_viewport.add_child(_bar)

func _build_screen_mesh() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "ScreenMesh"
	var quad := QuadMesh.new()
	quad.size = Vector2(DISPLAY_WIDTH, DISPLAY_HEIGHT)
	mesh_instance.mesh = quad

	# Emissive unshaded material using SubViewport texture for readability in any lighting
	var viewport_texture: ViewportTexture = _viewport.get_texture()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = viewport_texture
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_texture = viewport_texture
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = mat

	add_child(mesh_instance)

func _connect_ship_state() -> void:
	match variable_type:
		"power":
			ShipState.power_changed.connect(_on_value_changed)
		"integrity":
			ShipState.integrity_changed.connect(_on_value_changed)
		"heat":
			ShipState.heat_changed.connect(_on_value_changed)
		"oxygen":
			ShipState.oxygen_changed.connect(_on_value_changed)

func _refresh_value() -> void:
	match variable_type:
		"power":
			_current_value = ShipState.get_power()
		"integrity":
			_current_value = ShipState.get_integrity()
		"heat":
			_current_value = ShipState.get_heat()
		"oxygen":
			_current_value = ShipState.get_oxygen()
	_update_display()

func _update_display() -> void:
	if not _bar or not _value_label:
		return
	_bar.value = _current_value
	_value_label.text = "%d%%" % int(_current_value)
	_update_colors()

func _update_colors() -> void:
	var color: Color = _get_status_color()
	_value_label.add_theme_color_override("font_color", color)

	var fill_style: StyleBoxFlat = _bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	fill_style.bg_color = color
	_bar.add_theme_stylebox_override("fill", fill_style)

func _get_status_color() -> Color:
	match variable_type:
		"power":
			return _get_power_color()
		"integrity":
			return _get_integrity_color()
		"heat":
			return _get_heat_color()
		"oxygen":
			return _get_oxygen_color()
	return COLOR_TEAL

func _get_power_color() -> Color:
	if _current_value <= POWER_CRITICAL:
		_is_critical = true
		return _pulse_color(COLOR_CORAL)
	elif _current_value <= POWER_LOW:
		_is_critical = false
		return COLOR_AMBER
	_is_critical = false
	return COLOR_TEAL

func _get_integrity_color() -> Color:
	if _current_value <= INTEGRITY_CRITICAL:
		_is_critical = true
		return _pulse_color(COLOR_CORAL)
	elif _current_value <= INTEGRITY_DAMAGED:
		_is_critical = false
		return COLOR_AMBER
	_is_critical = false
	return COLOR_TEAL

func _get_heat_color() -> Color:
	if _current_value <= HEAT_COLD:
		_is_critical = false
		return COLOR_ICE_BLUE
	elif _current_value >= HEAT_HOT:
		_is_critical = true
		return _pulse_color(COLOR_CORAL)
	_is_critical = false
	return COLOR_TEAL

func _get_oxygen_color() -> Color:
	if _current_value <= OXYGEN_CRITICAL:
		_is_critical = true
		return _pulse_color(COLOR_CORAL)
	elif _current_value <= OXYGEN_LOW:
		_is_critical = false
		return COLOR_AMBER
	_is_critical = false
	return COLOR_TEAL

func _pulse_color(base_color: Color) -> Color:
	var pulse_alpha: float = 0.7 + 0.3 * (sin(_pulse_timer) * 0.5 + 0.5)
	return Color(base_color, pulse_alpha)

# ── Signal Handlers ──────────────────────────────────────

func _on_value_changed(current: float, _maximum: float) -> void:
	_current_value = current
	_update_display()
