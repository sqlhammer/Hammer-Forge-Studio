## Scanner analysis readout: displays purity, density, and energy cost after analysis.
class_name ScannerReadout
extends PanelContainer

# ── Constants ─────────────────────────────────────────────
const READOUT_WIDTH: float = 260.0
const DISMISS_DISTANCE: float = 5.0
const SLIDE_OFFSET: float = 16.0
const APPEAR_DURATION: float = 0.2
const DISMISS_DURATION: float = 0.3

## Style colors matching UI style guide
const COLOR_BG := Color("#0F1923", 0.85)
const COLOR_BORDER := Color("#007A63")
const COLOR_TEXT_PRIMARY := Color("#F1F5F9")
const COLOR_TEXT_SECONDARY := Color("#94A3B8")
const COLOR_TEAL := Color("#00D4AA")
const COLOR_AMBER := Color("#FFB830")
const COLOR_CORAL := Color("#FF6B5A")
const COLOR_NEUTRAL := Color("#94A3B8")

# ── Private Variables ─────────────────────────────────────
var _current_deposit: Deposit = null
var _player: CharacterBody3D = null
var _is_visible: bool = false
var _font: Font = null
var _font_mono: Font = null

var _header_label: Label = null
var _purity_stars: HBoxContainer = null
var _density_label: Label = null
var _energy_label: Label = null
var _content_container: VBoxContainer = null

# ── Public Methods ────────────────────────────────────────

## Initializes with player reference for distance checks.
func setup(player: CharacterBody3D) -> void:
	_player = player

## Shows the readout for a specific deposit.
func show_readout(deposit: Deposit) -> void:
	_current_deposit = deposit
	_update_readout_data()
	_is_visible = true
	_animate_show()

## Hides the readout.
func hide_readout() -> void:
	_is_visible = false
	_current_deposit = null
	_animate_hide()

## Returns the currently displayed deposit.
func get_current_deposit() -> Deposit:
	return _current_deposit

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_font = ThemeDB.fallback_font
	_font_mono = ThemeDB.fallback_font
	visible = false
	custom_minimum_size = Vector2(READOUT_WIDTH, 0)
	_build_ui()
	_apply_panel_style()

func _process(_delta: float) -> void:
	if not _is_visible or not _current_deposit or not _player:
		return
	# Dismiss if player walks away
	var dist: float = _player.global_position.distance_to(_current_deposit.global_position)
	if dist > DISMISS_DISTANCE:
		hide_readout()
		return
	# Dismiss if deposit depleted
	if _current_deposit.is_depleted():
		hide_readout()

# ── Private Methods ───────────────────────────────────────

func _build_ui() -> void:
	_content_container = VBoxContainer.new()
	_content_container.add_theme_constant_override("separation", 8)
	add_child(_content_container)

	# Header
	_header_label = Label.new()
	_header_label.text = "SCAN RESULTS"
	_header_label.add_theme_font_size_override("font_size", 20)
	_header_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	_content_container.add_child(_header_label)

	# Divider
	var divider := HSeparator.new()
	divider.add_theme_stylebox_override("separator", _create_divider_style())
	_content_container.add_child(divider)

	# Purity row
	var purity_row := HBoxContainer.new()
	purity_row.add_theme_constant_override("separation", 8)
	var purity_label := Label.new()
	purity_label.text = "Purity"
	purity_label.custom_minimum_size.x = 80
	purity_label.add_theme_font_size_override("font_size", 16)
	purity_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	purity_row.add_child(purity_label)
	_purity_stars = HBoxContainer.new()
	_purity_stars.add_theme_constant_override("separation", 4)
	for i: int in range(5):
		var star := Label.new()
		star.text = "★"
		star.add_theme_font_size_override("font_size", 20)
		_purity_stars.add_child(star)
	purity_row.add_child(_purity_stars)
	_content_container.add_child(purity_row)

	# Density row
	var density_row := HBoxContainer.new()
	density_row.add_theme_constant_override("separation", 8)
	var density_title := Label.new()
	density_title.text = "Density"
	density_title.custom_minimum_size.x = 80
	density_title.add_theme_font_size_override("font_size", 16)
	density_title.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	density_row.add_child(density_title)
	_density_label = Label.new()
	_density_label.add_theme_font_size_override("font_size", 20)
	density_row.add_child(_density_label)
	_content_container.add_child(density_row)

	# Energy row
	var energy_row := HBoxContainer.new()
	energy_row.add_theme_constant_override("separation", 8)
	var energy_title := Label.new()
	energy_title.text = "Energy"
	energy_title.custom_minimum_size.x = 80
	energy_title.add_theme_font_size_override("font_size", 16)
	energy_title.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	energy_row.add_child(energy_title)
	_energy_label = Label.new()
	_energy_label.add_theme_font_size_override("font_size", 22)
	energy_row.add_child(_energy_label)
	_content_container.add_child(energy_row)

func _apply_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(COLOR_BG)
	style.border_color = COLOR_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)

func _create_divider_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(COLOR_NEUTRAL, 0.4)
	style.set_content_margin_all(0)
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _update_readout_data() -> void:
	if not _current_deposit:
		return
	var summary: Dictionary = _current_deposit.get_analysis_summary()

	# Update purity stars
	var purity_val: int = _current_deposit.purity as int
	for i: int in range(5):
		var star: Label = _purity_stars.get_child(i) as Label
		if i < purity_val:
			star.add_theme_color_override("font_color", COLOR_AMBER)
		else:
			star.add_theme_color_override("font_color", COLOR_NEUTRAL)

	# Update density
	var density_name: String = summary.get("density_name", "Unknown") as String
	_density_label.text = density_name
	match _current_deposit.density_tier:
		ResourceDefs.DensityTier.LOW:
			_density_label.add_theme_color_override("font_color", COLOR_AMBER)
		ResourceDefs.DensityTier.MEDIUM:
			_density_label.add_theme_color_override("font_color", COLOR_TEAL)
		ResourceDefs.DensityTier.HIGH:
			_density_label.add_theme_color_override("font_color", COLOR_TEAL)

	# Update energy cost
	var energy_cost: float = SuitBattery.estimate_mining_cost(
		_current_deposit.deposit_tier,
		_current_deposit.get_remaining(),
	)
	var battery_percent: float = SuitBattery.get_charge_percent()
	var cost_percent: float = energy_cost / SuitBattery.max_charge * 100.0
	_energy_label.text = "%d%%" % int(cost_percent)
	# Warning if cost > 75% of current battery
	if energy_cost > SuitBattery.get_charge() * 0.75:
		_energy_label.add_theme_color_override("font_color", COLOR_CORAL)
	else:
		_energy_label.add_theme_color_override("font_color", COLOR_AMBER)

func _animate_show() -> void:
	visible = true
	modulate.a = 0.0
	position.x += SLIDE_OFFSET
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, APPEAR_DURATION)
	tween.tween_property(self, "position:x", position.x - SLIDE_OFFSET, APPEAR_DURATION)

func _animate_hide() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, DISMISS_DURATION)
	tween.tween_callback(func() -> void: visible = false)
