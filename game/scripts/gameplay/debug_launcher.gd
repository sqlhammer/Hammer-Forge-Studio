## DebugLauncher - Editor-only debug scene for biome selection and begin-wealthy testing - Owner: gameplay-programmer
## Provides a simple 2D menu to select a biome, toggle begin-wealthy mode, and
## launch into the main menu. Sets Global.starting_biome and Global.starting_inventory
## so downstream scenes (MainMenu → GameWorld) read startup configuration.
## Ticket: TICKET-0233
class_name DebugLauncher
extends Control


# ── Private Variables ─────────────────────────────────────

var _biome_selector: OptionButton = null
var _begin_wealthy_check: CheckBox = null
var _launch_button: Button = null


# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_build_ui()
	_populate_biome_selector()
	_apply_biome_selection()
	Global.log("DebugLauncher: ready")


# ── Public Methods ────────────────────────────────────────

## Returns a list of biome entries from BiomeRegistry, each containing id and display_name.
static func get_biome_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for biome_id: String in BiomeRegistry.BIOME_IDS:
		var biome_data: BiomeData = BiomeRegistry.get_biome(biome_id)
		if biome_data != null:
			entries.append({
				"id": biome_data.id,
				"display_name": biome_data.display_name,
			})
	return entries


# ── Private Methods: UI Construction ─────────────────────

## Builds the debug launcher UI programmatically.
func _build_ui() -> void:
	# Full-screen dark background
	var background: ColorRect = ColorRect.new()
	background.name = "Background"
	background.color = Color("#1a1a2e")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# Center container for menu
	var center: CenterContainer = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Vertical layout
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "MenuBox"
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	# Title
	var title: Label = Label.new()
	title.name = "TitleLabel"
	title.text = "DEBUG LAUNCHER"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("#F1F5F9"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Separator
	var separator: HSeparator = HSeparator.new()
	vbox.add_child(separator)

	# Biome selector label
	var biome_label: Label = Label.new()
	biome_label.name = "BiomeLabel"
	biome_label.text = "Select Biome:"
	biome_label.add_theme_font_size_override("font_size", 18)
	biome_label.add_theme_color_override("font_color", Color("#94A3B8"))
	vbox.add_child(biome_label)

	# Biome selector dropdown
	_biome_selector = OptionButton.new()
	_biome_selector.name = "BiomeSelector"
	_biome_selector.custom_minimum_size = Vector2(300, 40)
	_biome_selector.item_selected.connect(_on_biome_selected)
	vbox.add_child(_biome_selector)

	# Begin Wealthy checkbox
	_begin_wealthy_check = CheckBox.new()
	_begin_wealthy_check.name = "BeginWealthyCheck"
	_begin_wealthy_check.text = "Begin Wealthy (1× full stack, all resources)"
	_begin_wealthy_check.add_theme_font_size_override("font_size", 16)
	_begin_wealthy_check.add_theme_color_override("font_color", Color("#F1F5F9"))
	_begin_wealthy_check.toggled.connect(_on_begin_wealthy_toggled)
	vbox.add_child(_begin_wealthy_check)

	# Launch button
	_launch_button = Button.new()
	_launch_button.name = "LaunchButton"
	_launch_button.text = "LAUNCH"
	_launch_button.custom_minimum_size = Vector2(300, 50)
	_launch_button.add_theme_font_size_override("font_size", 20)
	_launch_button.pressed.connect(_on_launch_pressed)
	vbox.add_child(_launch_button)


## Populates the biome selector dropdown from BiomeRegistry.
func _populate_biome_selector() -> void:
	var entries: Array[Dictionary] = get_biome_entries()
	for entry: Dictionary in entries:
		_biome_selector.add_item(entry["display_name"] as String)
		var item_index: int = _biome_selector.item_count - 1
		_biome_selector.set_item_metadata(item_index, entry["id"])
	if entries.size() > 0:
		_biome_selector.selected = 0


# ── Private Methods: Event Handlers ──────────────────────

## Updates Global.starting_biome when the biome dropdown selection changes.
func _on_biome_selected(_index: int) -> void:
	_apply_biome_selection()


## Reads the current biome selector value and writes it to Global.starting_biome.
func _apply_biome_selection() -> void:
	var selected_idx: int = _biome_selector.selected
	if selected_idx < 0:
		return
	var biome_id: String = _biome_selector.get_item_metadata(selected_idx) as String
	Global.starting_biome = biome_id
	Global.log("DebugLauncher: starting_biome set to '%s'" % biome_id)


## Updates Global.starting_inventory when the begin-wealthy checkbox is toggled.
func _on_begin_wealthy_toggled(toggled_on: bool) -> void:
	if toggled_on:
		var inventory: Dictionary = {}
		for resource_key: int in ResourceDefs.RESOURCE_CATALOG:
			var resource_type: ResourceDefs.ResourceType = resource_key as ResourceDefs.ResourceType
			if resource_type == ResourceDefs.ResourceType.NONE:
				continue
			inventory[resource_type] = ResourceDefs.get_stack_size(resource_type)
		Global.starting_inventory = inventory
		Global.log("DebugLauncher: begin-wealthy ON — starting_inventory populated")
	else:
		Global.starting_inventory = {}
		Global.log("DebugLauncher: begin-wealthy OFF — starting_inventory cleared")


## Transitions to the main menu scene. Game root handles scene lifecycle.
func _on_launch_pressed() -> void:
	Global.log("DebugLauncher: launching — transitioning to MainMenu")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
