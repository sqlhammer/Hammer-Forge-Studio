## MainMenu - Root game main menu with Play button for launching GameWorld - Owner: gameplay-programmer
## Minimal first-pass menu: dark background, centered Play button, scene transition.
## UI is built programmatically in _ready() consistent with DebugLauncher pattern.
## Ticket: TICKET-0231
class_name MainMenu
extends Control


# ── Signals ──────────────────────────────────────────────

signal play_pressed


# ── Constants ─────────────────────────────────────────────

## Background color matching game aesthetic.
const BACKGROUND_COLOR: Color = Color("#1a1a2e")

## Button size per wireframe spec.
const BUTTON_MIN_SIZE: Vector2 = Vector2(200, 60)

## Logo zone reserved size (empty in M9).
const LOGO_ZONE_SIZE: Vector2 = Vector2(400, 120)

## Spacer height between zones.
const SPACER_HEIGHT: float = 48.0

## Footer zone reserved height (empty in M9).
const FOOTER_ZONE_HEIGHT: float = 40.0

## Font size for Play button text.
const BUTTON_FONT_SIZE: int = 24

## Button style colors — Normal state.
const NORMAL_BG_COLOR: Color = Color("#1A2736")
const NORMAL_BORDER_COLOR: Color = Color("#007A63")

## Button style colors — Hover state.
const HOVER_BG_COLOR: Color = Color("#243447")
const HOVER_BORDER_COLOR: Color = Color("#00D4AA")

## Button style colors — Pressed state.
const PRESSED_BG_COLOR: Color = Color("#0F1923")
const PRESSED_BORDER_COLOR: Color = Color("#00D4AA")

## Button style colors — Focused state (gamepad).
const FOCUSED_BORDER_COLOR: Color = Color("#00D4AA")

## Text colors.
const TEXT_PRIMARY_COLOR: Color = Color("#F1F5F9")
const TEXT_HIGHLIGHT_COLOR: Color = Color("#00D4AA")

## Border radius for button corners.
const BORDER_RADIUS: int = 4

## Scene path for GameWorld.
const GAME_WORLD_SCENE: String = "res://scenes/gameplay/game_world.tscn"


# ── Private Variables ─────────────────────────────────────

var _play_button: Button = null


# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	Global.log("MainMenu: ready")


# ── Private Methods: UI Construction ─────────────────────

## Builds the main menu UI programmatically per wireframe spec.
func _build_ui() -> void:
	# Full-screen dark background
	var background: ColorRect = ColorRect.new()
	background.name = "Background"
	background.color = BACKGROUND_COLOR
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# Center container fills viewport, centers its child
	var center: CenterContainer = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Vertical layout for menu elements
	var menu_layout: VBoxContainer = VBoxContainer.new()
	menu_layout.name = "MenuLayout"
	menu_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(menu_layout)

	# Logo zone — reserved for future title logo
	var logo_zone: Control = Control.new()
	logo_zone.name = "LogoZone"
	logo_zone.custom_minimum_size = LOGO_ZONE_SIZE
	menu_layout.add_child(logo_zone)

	# Spacer between logo zone and button
	var spacer_one: Control = Control.new()
	spacer_one.name = "Spacer1"
	spacer_one.custom_minimum_size = Vector2(0, SPACER_HEIGHT)
	menu_layout.add_child(spacer_one)

	# Play button
	_play_button = Button.new()
	_play_button.name = "PlayButton"
	_play_button.text = "Play"
	_play_button.custom_minimum_size = BUTTON_MIN_SIZE
	_play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_button_styles(_play_button)
	_play_button.pressed.connect(_on_play_pressed)
	menu_layout.add_child(_play_button)

	# Spacer between button and footer zone
	var spacer_two: Control = Control.new()
	spacer_two.name = "Spacer2"
	spacer_two.custom_minimum_size = Vector2(0, SPACER_HEIGHT)
	menu_layout.add_child(spacer_two)

	# Footer zone — reserved for future settings/credits/quit
	var footer_zone: Control = Control.new()
	footer_zone.name = "FooterZone"
	footer_zone.custom_minimum_size = Vector2(0, FOOTER_ZONE_HEIGHT)
	menu_layout.add_child(footer_zone)

	# Grab focus for gamepad support
	_play_button.grab_focus()


## Applies StyleBoxFlat theme overrides for all button states per wireframe spec.
func _apply_button_styles(button: Button) -> void:
	# Font size
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)

	# Normal state
	var normal_style: StyleBoxFlat = _create_style_box(
		NORMAL_BG_COLOR, NORMAL_BORDER_COLOR, 1
	)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_color_override("font_color", TEXT_PRIMARY_COLOR)

	# Hover state
	var hover_style: StyleBoxFlat = _create_style_box(
		HOVER_BG_COLOR, HOVER_BORDER_COLOR, 1
	)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_color_override("font_hover_color", TEXT_HIGHLIGHT_COLOR)

	# Pressed state
	var pressed_style: StyleBoxFlat = _create_style_box(
		PRESSED_BG_COLOR, PRESSED_BORDER_COLOR, 2
	)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_pressed_color", TEXT_PRIMARY_COLOR)

	# Focused state (gamepad navigation)
	var focus_style: StyleBoxFlat = _create_style_box(
		NORMAL_BG_COLOR, FOCUSED_BORDER_COLOR, 2
	)
	button.add_theme_stylebox_override("focus", focus_style)
	button.add_theme_color_override("font_focus_color", TEXT_PRIMARY_COLOR)


## Creates a StyleBoxFlat with the given colors, border width, and standard border radius.
func _create_style_box(
	bg_color: Color, border_color: Color, border_width: int
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = BORDER_RADIUS
	style.corner_radius_top_right = BORDER_RADIUS
	style.corner_radius_bottom_left = BORDER_RADIUS
	style.corner_radius_bottom_right = BORDER_RADIUS
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style


# ── Private Methods: Signal Handlers ────────────────────

## Handles the Play button press — logs and transitions to GameWorld.
func _on_play_pressed() -> void:
	Global.log("MainMenu: Play pressed — transitioning to GameWorld")
	play_pressed.emit()
	get_tree().change_scene_to_file(GAME_WORLD_SCENE)
