## DebugLauncher - Editor-only debug scene for biome selection and begin-wealthy testing - Owner: gameplay-programmer
## Provides a simple 2D menu to select a biome, toggle begin-wealthy mode, and
## launch directly into gameplay. Not linked from any in-game menu.
## Ticket: TICKET-0180
class_name DebugLauncher
extends Control


# ── Constants ─────────────────────────────────────────────

## Quantity of each resource to grant in begin-wealthy mode.
const BEGIN_WEALTHY_QUANTITY: int = 200

## Default purity for begin-wealthy resource grants.
const DEFAULT_PURITY: ResourceDefs.Purity = ResourceDefs.Purity.THREE_STAR

## Ship interior Y offset — matches TestWorld convention.
const INTERIOR_Y_OFFSET: float = -50.0

## Biome ID to script mapping for instantiation.
const _BIOME_SCRIPTS: Dictionary = {
	"shattered_flats": preload("res://scripts/gameplay/shattered_flats_biome.gd"),
	"rock_warrens": preload("res://scripts/gameplay/rock_warrens_biome.gd"),
	"debris_field": preload("res://scripts/gameplay/debris_field_biome.gd"),
}


# ── Private Variables ─────────────────────────────────────

var _biome_selector: OptionButton = null
var _begin_wealthy_check: CheckBox = null
var _launch_button: Button = null
var _status_label: Label = null


# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_build_ui()
	_populate_biome_selector()
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


## Grants BEGIN_WEALTHY_QUANTITY of every registered resource to PlayerInventory.
## Iterates RESOURCE_CATALOG dynamically so newly added resources are included
## automatically. Returns a dictionary mapping ResourceType to quantity granted.
static func grant_wealthy_resources() -> Dictionary:
	var grants: Dictionary = {}
	for resource_key: int in ResourceDefs.RESOURCE_CATALOG:
		var resource_type: ResourceDefs.ResourceType = resource_key as ResourceDefs.ResourceType
		if resource_type == ResourceDefs.ResourceType.NONE:
			continue
		var leftover: int = PlayerInventory.add_item(
			resource_type, DEFAULT_PURITY, BEGIN_WEALTHY_QUANTITY
		)
		var granted: int = BEGIN_WEALTHY_QUANTITY - leftover
		grants[resource_type] = granted
		var resource_name: String = ResourceDefs.get_resource_name(resource_type)
		Global.log("DebugLauncher: granted %d/%d %s" % [
			granted, BEGIN_WEALTHY_QUANTITY, resource_name
		])
	return grants


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
	vbox.add_child(_biome_selector)

	# Begin Wealthy checkbox
	_begin_wealthy_check = CheckBox.new()
	_begin_wealthy_check.name = "BeginWealthyCheck"
	_begin_wealthy_check.text = "Begin Wealthy (200x all resources)"
	_begin_wealthy_check.add_theme_font_size_override("font_size", 16)
	_begin_wealthy_check.add_theme_color_override("font_color", Color("#F1F5F9"))
	vbox.add_child(_begin_wealthy_check)

	# Launch button
	_launch_button = Button.new()
	_launch_button.name = "LaunchButton"
	_launch_button.text = "LAUNCH"
	_launch_button.custom_minimum_size = Vector2(300, 50)
	_launch_button.add_theme_font_size_override("font_size", 20)
	_launch_button.pressed.connect(_on_launch_pressed)
	vbox.add_child(_launch_button)

	# Status label for error messages
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color("#FF6B5A"))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_status_label)


## Populates the biome selector dropdown from BiomeRegistry.
func _populate_biome_selector() -> void:
	var entries: Array[Dictionary] = get_biome_entries()
	for entry: Dictionary in entries:
		_biome_selector.add_item(entry["display_name"] as String)
		var item_index: int = _biome_selector.item_count - 1
		_biome_selector.set_item_metadata(item_index, entry["id"])
	if entries.size() > 0:
		_biome_selector.selected = 0


# ── Private Methods: Launch Logic ────────────────────────

## Handles the launch button press.
func _on_launch_pressed() -> void:
	var selected_idx: int = _biome_selector.selected
	if selected_idx < 0:
		_status_label.text = "No biome selected."
		return
	var biome_id: String = _biome_selector.get_item_metadata(selected_idx) as String
	var begin_wealthy: bool = _begin_wealthy_check.button_pressed
	_launch(biome_id, begin_wealthy)


## Resets game state, grants resources if wealthy, and switches to the biome world.
func _launch(biome_id: String, begin_wealthy: bool) -> void:
	_status_label.text = "Launching %s..." % biome_id
	_launch_button.disabled = true

	# Reset game state
	PlayerInventory.clear_all()
	NavigationSystem.reset()
	FuelSystem.reset_to_full()
	ShipState.reset()
	NavigationSystem.current_biome = biome_id

	# Grant resources if begin wealthy
	if begin_wealthy:
		grant_wealthy_resources()

	# Build the 3D world structure (player and ship at origin; positions set after scene is live)
	var world: Node3D = _build_debug_world(biome_id)
	if world == null:
		_status_label.text = "Failed to create world for '%s'." % biome_id
		_launch_button.disabled = false
		return

	# Add world to the scene tree BEFORE positioning player/ship or calling _setup_gameplay().
	# This allows biome _ready() callbacks to fire (e.g. ShatteredFlatsBiome.generate()) and
	# initializes @onready variables on the player (including Camera3D).
	var old_scene: Node = get_tree().current_scene
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	old_scene.queue_free()

	# With all _ready() callbacks complete, biomes are fully generated and spawn positions accurate.
	var biome: Node3D = world.get_node("Biome") as Node3D
	var spawns: Dictionary = _get_spawn_positions(biome)
	var player_pos: Vector3 = spawns["player"] as Vector3
	var ship_pos: Vector3 = spawns["ship"] as Vector3

	# Position ship
	var ship: Node3D = world.get_node_or_null("Ship") as Node3D
	if ship != null:
		ship.position = ship_pos

	# Position player and set up gameplay systems (camera is now initialized via @onready)
	var player: Node3D = world.get_node_or_null("Player") as Node3D
	if player != null:
		player.position = player_pos
		_setup_gameplay(world, player)

	# [DEBUG] label overlay for begin-wealthy sessions
	if begin_wealthy:
		_add_debug_overlay(world)

	# Capture mouse for first-person gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	Global.log("DebugLauncher: launched biome '%s' (wealthy=%s)" % [
		biome_id, str(begin_wealthy)
	])


# ── Private Methods: World Construction ──────────────────

## Builds a minimal 3D world with the selected biome, player, and ship at origin.
## Player and ship positions are set by _launch() after the scene enters the tree,
## ensuring biome _ready() callbacks complete and @onready variables are initialized.
func _build_debug_world(biome_id: String) -> Node3D:
	var world: Node3D = Node3D.new()
	world.name = "DebugWorld"

	# Environment lighting
	_add_environment(world)

	# Biome
	var biome: Node3D = _create_biome_instance(biome_id)
	if biome == null:
		push_error("DebugLauncher: failed to create biome '%s'" % biome_id)
		world.queue_free()
		return null
	biome.name = "Biome"
	world.add_child(biome)

	# Initialize biomes that require explicit generation before entering the scene tree.
	# ShatteredFlatsBiome auto-generates in _ready() once the scene is live.
	_initialize_biome(biome)

	# Ship exterior — positioned at origin; final position set by _launch() after scene is live
	var ship_scene: PackedScene = load("res://scenes/objects/ship_exterior.tscn") as PackedScene
	if ship_scene:
		var ship: Node3D = ship_scene.instantiate()
		ship.name = "Ship"
		world.add_child(ship)

	# Player — positioned at origin; final position set by _launch() after scene is live
	var player_scene: PackedScene = load("res://player/player.tscn") as PackedScene
	if player_scene:
		var player: Node3D = player_scene.instantiate()
		player.name = "Player"
		world.add_child(player)

	return world


## Creates a biome Node3D instance from the biome ID using the script mapping.
func _create_biome_instance(biome_id: String) -> Node3D:
	var script: GDScript = _BIOME_SCRIPTS.get(biome_id) as GDScript
	if script == null:
		push_error("DebugLauncher: no script mapping for biome '%s'" % biome_id)
		return null
	var biome: Node3D = Node3D.new()
	biome.set_script(script)
	return biome


## Handles biome-specific initialization after the node is added to the tree.
## ShatteredFlatsBiome auto-generates in _ready(). RockWarrensBiome requires a
## manual generate() call. DebrisFieldBiome generates terrain in _init() but
## needs build_scene() for visual nodes.
func _initialize_biome(biome: Node3D) -> void:
	if biome is RockWarrensBiome:
		biome.generate()
	elif biome is DebrisFieldBiome:
		biome.build_scene()


## Retrieves player and ship spawn positions from a biome using duck-typing
## to handle API differences between biome classes.
func _get_spawn_positions(biome: Node3D) -> Dictionary:
	var player_pos: Vector3 = Vector3.ZERO
	var ship_pos: Vector3 = Vector3.ZERO

	# ShatteredFlatsBiome and RockWarrensBiome use get_*_spawn_position()
	# DebrisFieldBiome uses get_*_spawn_point()
	if biome.has_method("get_player_spawn_position"):
		player_pos = biome.get_player_spawn_position()
	elif biome.has_method("get_player_spawn_point"):
		player_pos = biome.get_player_spawn_point()

	if biome.has_method("get_ship_spawn_position"):
		ship_pos = biome.get_ship_spawn_position()
	elif biome.has_method("get_ship_spawn_point"):
		ship_pos = biome.get_ship_spawn_point()

	return {"player": player_pos, "ship": ship_pos}


## Adds environment lighting to the world (sky, ambient, directional light).
func _add_environment(world: Node3D) -> void:
	var env: WorldEnvironment = WorldEnvironment.new()
	env.name = "WorldEnvironment"
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#1a1a2e")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#404060")
	environment.ambient_light_energy = 0.4
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = environment
	world.add_child(env)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_color = Color("#ffe0c0")
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	world.add_child(sun)


## Sets up scanner and mining systems for the player.
func _setup_gameplay(world: Node3D, player: Node3D) -> void:
	var first_person: CharacterBody3D = player.get_node("FirstPersonController") as CharacterBody3D
	if first_person == null:
		push_error("DebugLauncher: player has no FirstPersonController")
		return

	var camera: Camera3D = null
	if first_person.has_method("get_camera"):
		camera = first_person.get_camera()
	if camera == null:
		push_error("DebugLauncher: player has no camera")
		return

	# Set player collision layers
	first_person.collision_layer = PhysicsLayers.PLAYER
	first_person.collision_mask = PhysicsLayers.ENVIRONMENT | PhysicsLayers.INTERACTABLE

	# Scanner
	var scanner: Scanner = Scanner.new()
	scanner.name = "Scanner"
	scanner.setup(camera, first_person)
	world.add_child(scanner)

	# Mining
	var mining: Mining = Mining.new()
	mining.name = "Mining"
	mining.setup(camera, first_person, scanner)
	world.add_child(mining)

	# HUD
	var hud_scene: PackedScene = preload("res://scenes/ui/game_hud.tscn")
	var hud: GameHUD = hud_scene.instantiate() as GameHUD
	hud.name = "HUD"
	world.add_child(hud)
	hud.setup(camera, first_person, scanner, mining)

	# Ship boarding — create enter zone + ship interior so the player can board in debug sessions.
	# TestWorld is never used by the debug launcher, so boarding must be wired here (TICKET-0208).
	_setup_ship_boarding(world, first_person, hud)


## Creates a ShipEnterZone on the ship and a ShipInterior underground so the player
## can board the ship in a debug-launched session (mirrors TestWorld._setup_ship_interior).
## The zone is a child of the ship node so it follows the ship automatically.
func _setup_ship_boarding(world: Node3D, first_person: CharacterBody3D, hud: GameHUD) -> void:
	var ship: Node3D = world.get_node_or_null("Ship") as Node3D
	if ship == null:
		push_error("DebugLauncher: no Ship node found — cannot set up boarding zone")
		return

	# Full-hull boarding zone sized to match the ship bounding box (~1–2 m clearance).
	# Parented to the ship so it follows ship position automatically (no repositioning needed).
	var enter_zone := ShipEnterZone.new()
	enter_zone.name = "ShipEnterZone"
	enter_zone.collision_layer = 0
	enter_zone.collision_mask = PhysicsLayers.PLAYER
	var enter_col := CollisionShape3D.new()
	var enter_shape := BoxShape3D.new()
	enter_shape.size = Vector3(28.0, 14.0, 50.0)
	enter_col.shape = enter_shape
	enter_col.position = Vector3(0.0, 4.5, 0.0)
	enter_zone.add_child(enter_col)
	ship.add_child(enter_zone)
	enter_zone.add_to_group("interaction_prompt_source")

	# Ship interior placed underground to isolate it from the exterior world.
	var interior_scene: PackedScene = load("res://scenes/gameplay/ship_interior.tscn") as PackedScene
	if interior_scene == null:
		push_error("DebugLauncher: could not load ship_interior.tscn — boarding zone created but boarding will fail")
		return
	var ship_interior: ShipInterior = interior_scene.instantiate() as ShipInterior
	ship_interior.name = "ShipInterior"
	ship_interior.position = Vector3(0.0, INTERIOR_Y_OFFSET, 0.0)
	world.add_child(ship_interior)
	ship_interior.setup_viewport_world(world.get_viewport().world_3d, Vector3(0.0, 8.0, -23.0))
	ship_interior.setup(first_person)
	# Exterior exit position is ship world position + hull Z-edge offset.
	ship_interior.set_exterior_position(ship.position + Vector3(0.0, 0.0, 24.0))

	# Boarding handler processes E-press input for enter/exit while DebugLauncher is not active.
	var handler := DebugShipBoardingHandler.new()
	handler.name = "ShipBoardingHandler"
	world.add_child(handler)
	handler.setup(ship_interior, first_person, enter_zone, hud, hud.get_navigation_console())

	Global.log("DebugLauncher: ship boarding zone and interior ready")


## Adds a [DEBUG] label overlay visible during begin-wealthy sessions.
func _add_debug_overlay(world: Node3D) -> void:
	var overlay: CanvasLayer = CanvasLayer.new()
	overlay.name = "DebugOverlay"
	overlay.layer = 10

	var label: Label = Label.new()
	label.name = "DebugLabel"
	label.text = "[DEBUG]"
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.RED)
	label.position = Vector2(16, 16)
	overlay.add_child(label)

	world.add_child(overlay)
