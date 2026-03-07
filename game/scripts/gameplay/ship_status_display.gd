## Diegetic ship status display: renders one ship global variable (Power, Integrity, Heat,
## or Oxygen) as a wall-mounted 3D panel using SubViewport for full UI rendering.
class_name ShipStatusDisplay
extends Node3D

# ── Constants ─────────────────────────────────────────────

## Colors matching HUD style guide exactly
const COLOR_TEAL := Color("#00D4AA")
const COLOR_AMBER := Color("#FFB830")
const COLOR_CORAL := Color("#FF6B5A")
const COLOR_ICE_BLUE := Color("#60A5FA")

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
var _current_value: float = 0.0
var _is_critical: bool = false
var _pulse_timer: float = 0.0

# ── Onready Variables ─────────────────────────────────────
@onready var _viewport: SubViewport = $DisplayViewport
@onready var _name_label: Label = $DisplayViewport/NameLabel
@onready var _value_label: Label = $DisplayViewport/ValueLabel
@onready var _bar: ProgressBar = $DisplayViewport/StatusBar
@onready var _screen_mesh: MeshInstance3D = $ScreenMesh

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_name_label.text = variable_name
	_wire_viewport_texture()
	_connect_ship_state()
	_refresh_value()
	Global.debug_log("ShipStatusDisplay: initialized for %s" % variable_name)

func _process(delta: float) -> void:
	if _is_critical:
		_pulse_timer += delta * PULSE_SPEED
		_update_colors()

# ── Private Methods ───────────────────────────────────────

## Wires the SubViewport texture to the screen mesh material for 3D rendering.
## Duplicates the material so each instance has its own ViewportTexture binding.
func _wire_viewport_texture() -> void:
	var viewport_texture: ViewportTexture = _viewport.get_texture()
	var mat: StandardMaterial3D = _screen_mesh.material_override.duplicate() as StandardMaterial3D
	mat.albedo_texture = viewport_texture
	mat.emission_texture = viewport_texture
	_screen_mesh.material_override = mat

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

	var existing: StyleBox = _bar.get_theme_stylebox("fill")
	if existing == null:
		var new_style: StyleBoxFlat = StyleBoxFlat.new()
		new_style.bg_color = color
		_bar.add_theme_stylebox_override("fill", new_style)
	else:
		var fill_style: StyleBoxFlat = existing.duplicate() as StyleBoxFlat
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
