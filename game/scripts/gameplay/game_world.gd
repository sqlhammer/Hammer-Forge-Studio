## GameWorld - Main gameplay scene that builds the 3D world from Global startup params - Owner: gameplay-programmer
## Reads Global.starting_biome and Global.starting_inventory on _ready() to configure
## biome selection, inventory grants, environment lighting, and all gameplay systems.
## Replaces the world-building logic previously embedded in DebugLauncher.
class_name GameWorld
extends Node3D


# ── Constants ─────────────────────────────────────────────

## Ship interior Y offset — underground isolation from exterior world.
const INTERIOR_Y_OFFSET: float = -50.0

## Default purity for starting inventory resource grants.
const DEFAULT_PURITY: ResourceDefs.Purity = ResourceDefs.Purity.THREE_STAR

## Biome ID to script mapping for instantiation.
const _BIOME_SCRIPTS: Dictionary = {
	"shattered_flats": preload("res://scripts/gameplay/shattered_flats_biome.gd"),
	"rock_warrens": preload("res://scripts/gameplay/rock_warrens_biome.gd"),
	"debris_field": preload("res://scripts/gameplay/debris_field_biome.gd"),
}


# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	# Reset all game state to a clean baseline before building the world
	PlayerInventory.clear_all()
	NavigationSystem.reset()
	FuelSystem.reset_to_full()
	ShipState.reset()

	var biome_id: String = Global.starting_biome
	NavigationSystem.current_biome = biome_id
	Global.debug_log("GameWorld: building world with biome '%s'" % biome_id)

	# Apply starting inventory if non-empty
	var starting_inv: Dictionary = Global.starting_inventory
	if not starting_inv.is_empty():
		_apply_starting_inventory(starting_inv)

	# Build world structure
	_add_environment()
	var biome: Node3D = _build_biome(biome_id)
	if biome == null:
		push_error("GameWorld: failed to create biome '%s' — aborting world build" % biome_id)
		return

	_add_ship()
	_add_player()

	# Defer positioning and gameplay setup until all _ready() callbacks have fired
	_position_entities_and_setup.call_deferred(biome)

	Global.debug_log("GameWorld: scene ready")


# ── Private Methods: World Construction ──────────────────

## Applies starting inventory grants from a dictionary of ResourceType → quantity.
func _apply_starting_inventory(inventory: Dictionary) -> void:
	for resource_key: int in inventory:
		var resource_type: ResourceDefs.ResourceType = resource_key as ResourceDefs.ResourceType
		var quantity: int = inventory[resource_key] as int
		PlayerInventory.add_item(resource_type, DEFAULT_PURITY, quantity)
		var resource_name: String = ResourceDefs.get_resource_name(resource_type)
		Global.debug_log("GameWorld: granted %d %s" % [quantity, resource_name])
	Global.debug_log("GameWorld: starting inventory applied")


## Adds environment lighting (sky, ambient, directional light) to this world.
func _add_environment() -> void:
	var env: WorldEnvironment = WorldEnvironment.new()
	env.name = "WorldEnvironment"
	env.environment = preload("res://environments/default_environment.tres")
	add_child(env)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_color = Color("#ffe0c0")
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.6
	sun.light_angular_distance = 1.5
	add_child(sun)


## Builds the biome container and instantiates the selected biome.
func _build_biome(biome_id: String) -> Node3D:
	var biome_container: Node3D = Node3D.new()
	biome_container.name = "BiomeContent"
	add_child(biome_container)

	var biome: Node3D = _create_biome_instance(biome_id)
	if biome == null:
		push_error("GameWorld: no biome created for '%s'" % biome_id)
		return null
	biome.name = "Biome"
	biome_container.add_child(biome)

	# Initialize biomes that require explicit generation before entering the scene tree.
	# ShatteredFlatsBiome auto-generates in _ready() once the scene is live.
	_initialize_biome(biome)

	Global.debug_log("GameWorld: biome '%s' loaded" % biome_id)
	return biome


## Creates a biome Node3D instance from the biome ID using the script mapping.
func _create_biome_instance(biome_id: String) -> Node3D:
	var script: GDScript = _BIOME_SCRIPTS.get(biome_id) as GDScript
	if script == null:
		push_error("GameWorld: no script mapping for biome '%s'" % biome_id)
		return null
	var biome: Node3D = Node3D.new()
	biome.set_script(script)
	return biome


## Handles biome-specific initialization. RockWarrensBiome requires manual generate().
## DebrisFieldBiome needs build_scene() for visual nodes. ShatteredFlatsBiome auto-generates.
func _initialize_biome(biome: Node3D) -> void:
	if biome is RockWarrensBiome:
		biome.generate()
	elif biome is DebrisFieldBiome:
		biome.build_scene()


## Adds the ship exterior to the world at origin (positioned later).
func _add_ship() -> void:
	var ship_scene: PackedScene = load("res://scenes/objects/ship_exterior.tscn") as PackedScene
	if ship_scene:
		var ship: Node3D = ship_scene.instantiate()
		ship.name = "Ship"
		add_child(ship)


## Adds the player to the world at origin (positioned later).
func _add_player() -> void:
	var player_scene: PackedScene = load("res://player/player.tscn") as PackedScene
	if player_scene:
		var player: Node3D = player_scene.instantiate()
		player.name = "Player"
		add_child(player)


## Deferred callback — runs after all _ready() callbacks are complete so biomes
## are fully generated and spawn positions are accurate.
func _position_entities_and_setup(biome: Node3D) -> void:
	var spawns: Dictionary = _get_spawn_positions(biome)
	var player_pos: Vector3 = spawns["player"] as Vector3
	var ship_pos: Vector3 = spawns["ship"] as Vector3

	# Position ship
	var ship: Node3D = get_node_or_null("Ship") as Node3D
	if ship != null:
		ship.position = ship_pos

	# Position player and set up gameplay systems
	var player: Node3D = get_node_or_null("Player") as Node3D
	if player != null:
		player.position = player_pos
		_setup_gameplay(player)

	# Debug overlay for sessions with debug features active
	var has_debug_features: bool = not Global.starting_inventory.is_empty() or Global.debug_speed_multiplier != 1.0
	if has_debug_features:
		_add_debug_overlay()

	# Capture mouse for first-person gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	Global.debug_log("GameWorld: entities positioned, gameplay systems active")


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


# ── Private Methods: Gameplay Setup ──────────────────────

## Sets up scanner, mining, HUD, ship boarding, travel, and item drop systems.
func _setup_gameplay(player: Node3D) -> void:
	var first_person: CharacterBody3D = player.get_node("FirstPersonController") as CharacterBody3D
	if first_person == null:
		push_error("GameWorld: player has no FirstPersonController")
		return

	var camera: Camera3D = null
	if first_person.has_method("get_camera"):
		camera = first_person.get_camera()
	if camera == null:
		push_error("GameWorld: player has no camera")
		return

	# Apply debug speed multiplier if set in DebugLauncher (debug builds only)
	if OS.is_debug_build() and Global.debug_speed_multiplier != 1.0:
		first_person.debug_speed_multiplier = Global.debug_speed_multiplier
		Global.debug_log("GameWorld: debug_speed_multiplier set to %.1f" % Global.debug_speed_multiplier)

	# Set player collision layers
	first_person.collision_layer = PhysicsLayers.PLAYER
	first_person.collision_mask = PhysicsLayers.ENVIRONMENT | PhysicsLayers.INTERACTABLE

	# Scanner
	var scanner: Scanner = Scanner.new()
	scanner.name = "Scanner"
	scanner.setup(camera, first_person)
	add_child(scanner)

	# Mining
	var mining: Mining = Mining.new()
	mining.name = "Mining"
	mining.setup(camera, first_person, scanner)
	add_child(mining)

	# HUD
	var hud_scene: PackedScene = preload("res://scenes/ui/game_hud.tscn")
	var hud: GameHUD = hud_scene.instantiate() as GameHUD
	hud.name = "HUD"
	add_child(hud)
	hud.setup(camera, first_person, scanner, mining)

	# Wire scanner to the persistent ResourceTypeWheel in the HUD
	var resource_wheel: ResourceTypeWheel = hud.get_resource_wheel()
	scanner.set_resource_wheel(resource_wheel)

	# Ship boarding
	_setup_ship_boarding(first_person, hud)

	# Travel sequence
	_setup_travel_sequence(player)

	# Item drop
	_setup_item_drop(first_person, hud)


## Creates a ShipEnterZone on the ship and a ShipInterior underground so the player
## can board the ship. The zone is parented to the ship so it follows automatically.
func _setup_ship_boarding(first_person: CharacterBody3D, hud: GameHUD) -> void:
	var ship: Node3D = get_node_or_null("Ship") as Node3D
	if ship == null:
		push_error("GameWorld: no Ship node found — cannot set up boarding zone")
		return

	# Full-hull boarding zone sized to match the ship bounding box
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

	# Ship interior placed underground to isolate from exterior world
	var interior_scene: PackedScene = load("res://scenes/gameplay/ship_interior.tscn") as PackedScene
	if interior_scene == null:
		push_error("GameWorld: could not load ship_interior.tscn — boarding will fail")
		return
	var ship_interior: ShipInterior = interior_scene.instantiate() as ShipInterior
	ship_interior.name = "ShipInterior"
	ship_interior.position = Vector3(0.0, INTERIOR_Y_OFFSET, 0.0)
	add_child(ship_interior)
	ship_interior.setup_viewport_world(get_viewport().world_3d, Vector3(0.0, 8.0, -23.0))
	ship_interior.setup(first_person)
	# Exterior exit position is ship world position + hull Z-edge offset
	ship_interior.set_exterior_position(ship.position + Vector3(0.0, 0.0, 24.0))

	# Boarding handler processes E-press input for enter/exit
	var camera: Camera3D = null
	if first_person.has_method("get_camera"):
		camera = first_person.get_camera()
	var handler := DebugShipBoardingHandler.new()
	handler.name = "ShipBoardingHandler"
	add_child(handler)
	handler.setup(ship_interior, first_person, enter_zone, hud, hud.get_navigation_console(), camera, ship)

	Global.debug_log("GameWorld: ship boarding zone and interior ready")


## Creates a TravelSequenceManager so NavigationSystem.travel_completed triggers
## the full biome transition (fade out, swap, fade in).
func _setup_travel_sequence(player: Node3D) -> void:
	var ship: ShipExterior = get_node_or_null("Ship") as ShipExterior
	var biome_container: Node3D = get_node_or_null("BiomeContent") as Node3D
	var ship_interior: ShipInterior = get_node_or_null("ShipInterior") as ShipInterior
	if ship == null or biome_container == null:
		push_error("GameWorld: cannot set up travel sequence — missing Ship or BiomeContent")
		return

	var travel_manager: TravelSequenceManager = TravelSequenceManager.new()
	travel_manager.name = "TravelSequenceManager"
	add_child(travel_manager)
	travel_manager.setup(player, ship, biome_container, ship_interior)

	# Update ship interior positions after biome swap
	travel_manager.travel_sequence_completed.connect(
		func(destination_id: String) -> void:
			if ship_interior and ship:
				var exit_offset: Vector3 = Vector3(0.0, 0.0, 24.0)
				ship_interior.set_exterior_position(ship.position + exit_offset)
				var viewport_camera_pos: Vector3 = ship.position + Vector3(0.0, 8.0, -23.0)
				ship_interior.setup_viewport_world(get_viewport().world_3d, viewport_camera_pos)
			Global.debug_log("GameWorld: travel sequence completed → '%s'" % destination_id)
	)
	Global.debug_log("GameWorld: travel sequence manager ready")


## Connects the inventory screen's drop signal to spawn a DroppedItem at the player's feet.
## Dropped items are parented to BiomeContent so they are cleared on biome travel.
func _setup_item_drop(first_person: CharacterBody3D, hud: GameHUD) -> void:
	var inventory_screen: InventoryScreen = hud.get_inventory_screen()
	if inventory_screen == null:
		push_warning("GameWorld: no inventory screen found — item drop disabled")
		return
	inventory_screen.item_drop_requested.connect(
		func(resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int) -> void:
			var biome_container: Node3D = get_node_or_null("BiomeContent") as Node3D
			# Fall back to world root if no biome container exists
			var parent_node: Node3D = biome_container if biome_container else self
			var item := DroppedItem.new()
			item.setup(resource_type, purity, quantity)
			item.name = "DroppedItem_%s" % ResourceDefs.get_resource_name(resource_type).replace(" ", "")
			# Place item 1.5m in front of the player at ground level
			var forward_dir: Vector3 = -first_person.global_transform.basis.z
			forward_dir.y = 0.0
			if forward_dir.length_squared() > 0.001:
				forward_dir = forward_dir.normalized()
			else:
				forward_dir = Vector3.FORWARD
			var drop_offset: Vector3 = forward_dir * 1.5
			var drop_position: Vector3 = first_person.global_position + drop_offset
			drop_position.y = first_person.global_position.y
			item.position = drop_position
			parent_node.add_child(item)
			Global.debug_log("GameWorld: dropped item spawned at %s" % str(drop_position))
	)
	Global.debug_log("GameWorld: item drop handler ready")


## Adds a [DEBUG] label overlay visible during sessions with modified starting inventory.
func _add_debug_overlay() -> void:
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

	add_child(overlay)
