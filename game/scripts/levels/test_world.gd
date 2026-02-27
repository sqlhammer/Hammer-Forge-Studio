## M4 greybox test world: bounded play area with ship interior, deposits, and all gameplay systems.
class_name TestWorld
extends Node3D

# ── Constants ─────────────────────────────────────────────
const WORLD_SIZE: float = 100.0
const WALL_HEIGHT: float = 8.0
const DEPOSIT_SPREAD: float = 60.0
const DEPOSIT_VISUAL_SCALE := Vector3(3.2, 3.2, 3.2)
const DEPOSIT_COLLISION_RADIUS: float = 1.5

## Ship interior is placed underground to isolate it from the exterior world.
const INTERIOR_Y_OFFSET: float = -50.0

# ── Private Variables ─────────────────────────────────────
var _player: Node3D = null
var _first_person: CharacterBody3D = null
var _camera: Camera3D = null
var _scanner: Scanner = null
var _mining: Mining = null
var _hud: GameHUD = null
var _inventory_screen: InventoryScreen = null
var _ship_exterior: ShipExterior = null
var _deposit_container: Node3D = null
var _ship_interior: Node3D = null
var _ship_enter_zone: ShipEnterZone = null
var _player_near_ship_entrance: bool = false
var _transitioning: bool = false
var _module_placement_ui: ModulePlacementUI = null
var _recycler_panel: RecyclerPanel = null
var _tech_tree_panel: TechTreePanel = null
var _fabricator_panel: FabricatorPanel = null
var _automation_hub_panel: AutomationHubPanel = null
var _navigation_console: NavigationConsole = null
var _head_lamp_light: SpotLight3D = null
var _third_person: PlayerThirdPerson = null
var _player_manager: PlayerManager = null
var _drone_manager: DroneManager = null
var _zone_module_ids: Dictionary = {}
var _biome_content: Node3D = null
var _travel_manager: TravelSequenceManager = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	Global.log("TestWorld: initializing")
	_build_environment()
	_build_biome_content()
	_build_ship()
	_spawn_player()
	_setup_gameplay_systems()
	_setup_ship_interior()
	_setup_hud()
	_setup_ship_ui()
	_setup_head_lamp()
	_setup_drone_manager()
	_setup_travel_sequence()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Global.log("TestWorld: initialization complete")

func _process(delta: float) -> void:
	_update_recharge(delta)
	_update_ship_interact()
	_update_use_item()
	_update_head_lamp_toggle()

func _input(event: InputEvent) -> void:
	# Toggle mouse capture with Escape
	if event.is_action_pressed("pause"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ── Private Methods ───────────────────────────────────────

func _build_environment() -> void:
	# Sky and ambient lighting
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#1a1a2e")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#404060")
	environment.ambient_light_energy = 0.4
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = environment
	add_child(env)

	# Directional light (sun)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_color = Color("#ffe0c0")
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)

func _build_biome_content() -> void:
	# Container for biome-specific content (ground, boundaries, deposits).
	# TravelSequenceManager swaps this container's children on biome travel.
	_biome_content = Node3D.new()
	_biome_content.name = "BiomeContent"
	add_child(_biome_content)
	_build_ground()
	_build_boundaries()
	_generate_deposits()
	Global.log("TestWorld: biome content built (starter biome)")

func _build_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	ground.collision_layer = PhysicsLayers.ENVIRONMENT
	ground.collision_mask = 0

	# Visual mesh
	var mesh_inst := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(WORLD_SIZE * 2, WORLD_SIZE * 2)
	mesh_inst.mesh = plane_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#3a3a4a")
	material.roughness = 0.9
	mesh_inst.material_override = material
	ground.add_child(mesh_inst)

	# Collision
	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(WORLD_SIZE * 2, 0.1, WORLD_SIZE * 2)
	col_shape.shape = box_shape
	col_shape.position.y = -0.05
	ground.add_child(col_shape)

	_biome_content.add_child(ground)

func _build_boundaries() -> void:
	var boundaries := Node3D.new()
	boundaries.name = "Boundaries"
	_biome_content.add_child(boundaries)

	# Four invisible walls
	var offsets: Array[Vector3] = [
		Vector3(WORLD_SIZE, WALL_HEIGHT / 2.0, 0),
		Vector3(-WORLD_SIZE, WALL_HEIGHT / 2.0, 0),
		Vector3(0, WALL_HEIGHT / 2.0, WORLD_SIZE),
		Vector3(0, WALL_HEIGHT / 2.0, -WORLD_SIZE),
	]
	var sizes: Array[Vector3] = [
		Vector3(0.5, WALL_HEIGHT, WORLD_SIZE * 2),
		Vector3(0.5, WALL_HEIGHT, WORLD_SIZE * 2),
		Vector3(WORLD_SIZE * 2, WALL_HEIGHT, 0.5),
		Vector3(WORLD_SIZE * 2, WALL_HEIGHT, 0.5),
	]

	for i: int in range(4):
		var wall := StaticBody3D.new()
		wall.name = "Wall_%d" % i
		wall.collision_layer = PhysicsLayers.ENVIRONMENT
		wall.collision_mask = 0
		wall.position = offsets[i]

		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = sizes[i]
		col.shape = shape
		wall.add_child(col)

		boundaries.add_child(wall)

func _build_ship() -> void:
	var ship_scene: PackedScene = load("res://scenes/objects/ship_exterior.tscn") as PackedScene
	if not ship_scene:
		push_error("TestWorld: Could not load ship exterior scene!")
		return
	_ship_exterior = ship_scene.instantiate() as ShipExterior
	_ship_exterior.name = "Ship"
	_ship_exterior.position = Vector3.ZERO
	add_child(_ship_exterior)

	_ship_exterior.recharge_zone_entered.connect(_on_recharge_zone_entered)
	_ship_exterior.recharge_zone_exited.connect(_on_recharge_zone_exited)

func _spawn_player() -> void:
	var player_scene: PackedScene = load("res://player/player.tscn") as PackedScene
	if not player_scene:
		push_error("TestWorld: Could not load player scene!")
		return
	_player = player_scene.instantiate()
	_player.name = "Player"
	_player.position = Vector3(0, 0.0, 24)  # Spawn near ship entrance (3× hull), capsule bottom at local Y=0
	add_child(_player)

	# Get controllers and camera
	_first_person = _player.get_node("FirstPersonController") as CharacterBody3D
	_third_person = _player.get_node("ThirdPersonController") as PlayerThirdPerson
	if _first_person and _first_person.has_method("get_camera"):
		_camera = _first_person.get_camera()

	# Connect view mode switching
	_player_manager = _player as PlayerManager
	if _player_manager:
		_player_manager.view_mode_changed.connect(_on_view_mode_changed)

	# Set player collision layer
	if _first_person:
		_first_person.collision_layer = PhysicsLayers.PLAYER
		_first_person.collision_mask = PhysicsLayers.ENVIRONMENT | PhysicsLayers.INTERACTABLE

func _generate_deposits() -> void:
	_deposit_container = Node3D.new()
	_deposit_container.name = "Deposits"
	_biome_content.add_child(_deposit_container)

	var deposits: Array[Deposit] = DepositRegistry.generate_m3_deposits(Vector3.ZERO, DEPOSIT_SPREAD)
	var scrap_mesh_scene: Resource = load("res://assets/meshes/props/mesh_resource_node_scrap.glb")

	for deposit: Deposit in deposits:
		# Ensure deposit is on the ground
		deposit.position.y = 0.0
		_deposit_container.add_child(deposit)
		deposit.depleted.connect(func() -> void:
			DepositRegistry.unregister(deposit)
			deposit.queue_free()
		)

		# Add visual mesh
		if scrap_mesh_scene and scrap_mesh_scene is PackedScene:
			var mesh_instance: Node3D = (scrap_mesh_scene as PackedScene).instantiate()
			mesh_instance.name = "Mesh"
			mesh_instance.scale = DEPOSIT_VISUAL_SCALE
			mesh_instance.position.y = 0.9
			deposit.add_child(mesh_instance)
		else:
			# Fallback: colored box
			var fallback := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(1.0, 1.0, 1.0)
			fallback.mesh = box
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color("#D4AA00")
			fallback.material_override = mat
			deposit.add_child(fallback)

		# Add collision body for raycast detection
		var body := StaticBody3D.new()
		body.name = "InteractBody"
		body.collision_layer = PhysicsLayers.INTERACTABLE
		body.collision_mask = 0
		var col := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = DEPOSIT_COLLISION_RADIUS
		col.shape = sphere
		col.position.y = 0.9
		body.add_child(col)
		deposit.add_child(body)

func _setup_gameplay_systems() -> void:
	if not _camera or not _first_person:
		push_error("TestWorld: Camera or player not available for gameplay systems!")
		return

	# Scanner
	_scanner = Scanner.new()
	_scanner.name = "Scanner"
	_scanner.setup(_camera, _first_person)
	add_child(_scanner)

	# Mining
	_mining = Mining.new()
	_mining.name = "Mining"
	_mining.setup(_camera, _first_person, _scanner)
	add_child(_mining)

func _setup_hud() -> void:
	# Main HUD (includes all UI panels and HUD elements as instanced subscenes)
	var hud_scene: PackedScene = preload("res://scenes/ui/game_hud.tscn")
	_hud = hud_scene.instantiate() as GameHUD
	_hud.name = "HUD"
	add_child(_hud)
	if _camera and _first_person and _scanner and _mining:
		_hud.setup(_camera, _first_person, _scanner, _mining)

	# Get panel references from the HUD
	_inventory_screen = _hud.get_inventory_screen()
	_module_placement_ui = _hud.get_module_placement_ui()
	_recycler_panel = _hud.get_recycler_panel()
	_tech_tree_panel = _hud.get_tech_tree_panel()
	_fabricator_panel = _hud.get_fabricator_panel()
	_automation_hub_panel = _hud.get_automation_hub_panel()
	_navigation_console = _hud.get_navigation_console()

func _update_recharge(delta: float) -> void:
	if _ship_exterior and _first_person:
		var in_zone: bool = _ship_exterior.is_body_in_recharge_zone(_first_person)
		if in_zone and not SuitBattery.is_recharging() and SuitBattery.get_charge_percent() < 1.0:
			Global.log("TestWorld: player entered recharge zone")
			SuitBattery.start_recharge()
		elif not in_zone and SuitBattery.is_recharging():
			Global.log("TestWorld: player exited recharge zone")
			SuitBattery.stop_recharge()
	if SuitBattery.is_recharging():
		SuitBattery.process_recharge(delta)

func _on_recharge_zone_entered(body: Node3D) -> void:
	if body == _first_person:
		Global.log("TestWorld: recharge zone signal — entered")

func _on_recharge_zone_exited(body: Node3D) -> void:
	if body == _first_person:
		Global.log("TestWorld: recharge zone signal — exited")

func _setup_ship_interior() -> void:
	# Load and instance ship interior scene underground
	var interior_scene: PackedScene = load("res://scenes/gameplay/ship_interior.tscn") as PackedScene
	if not interior_scene:
		push_error("TestWorld: Could not load ship interior scene!")
		return
	_ship_interior = interior_scene.instantiate()
	_ship_interior.name = "ShipInterior"
	_ship_interior.position = Vector3(0, INTERIOR_Y_OFFSET, 0)
	add_child(_ship_interior)

	# Position the cockpit viewport camera at the ship exterior front, looking forward
	var viewport_camera_pos := Vector3(0.0, 8.0, -23.0)
	_ship_interior.setup_viewport_world(get_viewport().world_3d, viewport_camera_pos)

	if _first_person:
		_ship_interior.setup(_first_person)

	# Set the exterior exit position outside the ship hull (3× hull Z-edge = 21, exit beyond it)
	_ship_interior.set_exterior_position(Vector3(0, 0.0, 24))

	# Connect ship interior signals
	_ship_interior.player_entered_ship.connect(_on_player_entered_ship)
	_ship_interior.player_exited_ship.connect(_on_player_exited_ship)

	# Create a boarding zone that wraps the full ship hull so the player can board from any side.
	# BoxShape3D is sized slightly larger than the ship's bounding box (~1–2 m clearance all around):
	#   ship hull ≈ 26 m wide × 46 m long × 11 m tall (24× scaled mesh, center at Y=6.5).
	#   boarding box: 28 m wide × 50 m long × 14 m tall, centered at local (0, 4.5, 0).
	# Replaces the former single-point entrance trigger (TICKET-0206).
	_ship_enter_zone = ShipEnterZone.new()
	_ship_enter_zone.name = "ShipEnterZone"
	_ship_enter_zone.collision_layer = 0
	_ship_enter_zone.collision_mask = PhysicsLayers.PLAYER
	var enter_col := CollisionShape3D.new()
	var enter_shape := BoxShape3D.new()
	enter_shape.size = Vector3(28.0, 14.0, 50.0)
	enter_col.shape = enter_shape
	enter_col.position = Vector3(0.0, 4.5, 0.0)
	_ship_enter_zone.add_child(enter_col)
	add_child(_ship_enter_zone)

	_ship_enter_zone.body_entered.connect(_on_ship_enter_zone_entered)
	_ship_enter_zone.body_exited.connect(_on_ship_enter_zone_exited)
	_ship_enter_zone.add_to_group("interaction_prompt_source")
	Global.log("TestWorld: ship interior ready")

func _update_ship_interact() -> void:
	if _transitioning or not _ship_interior:
		return
	if _travel_manager and _travel_manager.is_transitioning():
		return

	# Don't process interact while a UI panel is open
	if _module_placement_ui and _module_placement_ui.is_open():
		return
	if _recycler_panel and _recycler_panel.is_open():
		return
	if _tech_tree_panel and _tech_tree_panel.is_open():
		return
	if _fabricator_panel and _fabricator_panel.is_open():
		return
	if _automation_hub_panel and _automation_hub_panel.is_open():
		return
	if _navigation_console and _navigation_console.is_open():
		return
	if _inventory_screen and _inventory_screen.is_open():
		return

	# Enter ship from exterior
	if _player_near_ship_entrance and not _ship_interior.is_player_inside():
		if InputManager.is_action_just_pressed("interact"):
			_begin_enter_ship()
			return

	# Exit ship from interior exit zone
	if _ship_interior.is_player_inside() and _ship_interior.is_player_in_exit_zone():
		if InputManager.is_action_just_pressed("interact"):
			_begin_exit_ship()
			return

	# Interact with ship interior objects when inside
	if _ship_interior.is_player_inside():
		if InputManager.is_action_just_pressed("interact"):
			# Check cockpit navigation console
			if _ship_interior.is_player_near_cockpit_console():
				if _navigation_console:
					_navigation_console.open_panel()
				return
			# Check terminal
			if _ship_interior.is_player_near_terminal():
				_tech_tree_panel.open()
				return
			# Check placement zones
			var zone_index: int = _ship_interior.get_nearby_zone_index()
			if zone_index >= 0:
				if _ship_interior.is_zone_occupied(zone_index):
					_open_module_panel(zone_index)
				else:
					_module_placement_ui.open(zone_index)

func _begin_enter_ship() -> void:
	_transitioning = true
	await _ship_interior.enter_ship(_first_person)
	_transitioning = false

func _begin_exit_ship() -> void:
	_transitioning = true
	await _ship_interior.exit_ship()
	_transitioning = false

func _update_use_item() -> void:
	if not InputManager.is_action_just_pressed("use_item"):
		return
	# Spare Battery cannot be used inside the ship (suit auto-recharges there)
	if _ship_interior and _ship_interior.is_player_inside():
		return
	# Don't use while transitioning
	if _transitioning:
		return
	# Check if suit battery is already full
	if SuitBattery.get_charge_percent() >= 1.0:
		if _hud:
			_hud.show_notification("Battery already full", Color("#94A3B8"))
		return
	# Attempt to use a Spare Battery from inventory
	var success: bool = SpareBattery.use()
	if success:
		if _hud:
			_hud.show_notification("Battery Recharged!", Color("#00D4AA"))
	else:
		if _hud:
			_hud.show_notification("No Spare Batteries", Color("#FF6B5A"))

func _setup_head_lamp() -> void:
	if not _camera:
		return
	# Create a SpotLight3D parented to the camera for head-lamp illumination
	_head_lamp_light = SpotLight3D.new()
	_head_lamp_light.name = "HeadLampLight"
	_head_lamp_light.light_color = Color("#FFFBE6")
	_head_lamp_light.light_energy = 3.0
	_head_lamp_light.spot_range = 30.0
	_head_lamp_light.spot_angle = 35.0
	_head_lamp_light.spot_attenuation = 0.8
	_head_lamp_light.shadow_enabled = true
	_head_lamp_light.visible = false
	_camera.add_child(_head_lamp_light)
	# Connect to HeadLamp signals
	HeadLamp.head_lamp_toggled.connect(_on_head_lamp_toggled)
	# Restore visual state if lamp was already equipped and active
	if HeadLamp.is_equipped() and HeadLamp.is_active():
		_head_lamp_light.visible = true
	Global.log("TestWorld: head lamp visual ready")

func _update_head_lamp_toggle() -> void:
	if not InputManager.is_action_just_pressed("toggle_head_lamp"):
		return
	HeadLamp.toggle()

func _on_head_lamp_toggled(active: bool) -> void:
	if _head_lamp_light:
		_head_lamp_light.visible = active

func _setup_ship_ui() -> void:
	# Panels are instanced in game_hud.tscn; connect signals and configure
	_module_placement_ui.module_installed.connect(_on_module_installed)

	_automation_hub_panel.setup(Vector3.ZERO)  # Ship position for deposit distance calculations
	_automation_hub_panel.drone_deployed.connect(_on_drone_deployed)
	_automation_hub_panel.drones_recalled.connect(_on_drones_recalled)

	# Restore any modules already installed (e.g., from autoload state after scene reload)
	_restore_installed_modules()
	Global.log("TestWorld: ship UI ready")

func _restore_installed_modules() -> void:
	var installed_ids: Array[String] = ModuleManager.get_installed_module_ids()
	for module_id: String in installed_ids:
		var zone_index: int = _ship_interior.get_first_empty_zone()
		if zone_index >= 0:
			_zone_module_ids[zone_index] = module_id
			_place_module_visual(module_id, zone_index)

func _on_module_installed(module_id: String, zone_index: int) -> void:
	_zone_module_ids[zone_index] = module_id
	_place_module_visual(module_id, zone_index)

func _place_module_visual(module_id: String, zone_index: int) -> void:
	if module_id == "recycler":
		var recycler_scene: Resource = load("res://assets/meshes/machines/mesh_recycler_module.glb")
		if recycler_scene and recycler_scene is PackedScene:
			var mesh_node: Node3D = (recycler_scene as PackedScene).instantiate()
			mesh_node.name = "RecyclerModule"
			_ship_interior.place_module_in_zone(zone_index, mesh_node)
			Global.log("TestWorld: placed recycler mesh in zone %d" % zone_index)
		else:
			_place_module_fallback("RecyclerModule", Vector3(1.8, 1.4, 1.2), zone_index)
	elif module_id == "fabricator":
		var fabricator_scene: Resource = load("res://assets/meshes/machines/mesh_fabricator_module.glb")
		if fabricator_scene and fabricator_scene is PackedScene:
			var mesh_node: Node3D = (fabricator_scene as PackedScene).instantiate()
			mesh_node.name = "FabricatorModule"
			_add_interaction_area(mesh_node, Vector3(2.0, 1.2, 1.2))
			_ship_interior.place_module_in_zone(zone_index, mesh_node)
			Global.log("TestWorld: placed fabricator mesh in zone %d" % zone_index)
		else:
			_place_module_fallback("FabricatorModule", Vector3(2.0, 1.2, 1.2), zone_index)
	elif module_id == "automation_hub":
		var hub_scene: Resource = load("res://assets/meshes/machines/mesh_automation_hub_module.glb")
		if hub_scene and hub_scene is PackedScene:
			var mesh_node: Node3D = (hub_scene as PackedScene).instantiate()
			mesh_node.name = "AutomationHubModule"
			_add_interaction_area(mesh_node, Vector3(2.2, 1.4, 1.2))
			_ship_interior.place_module_in_zone(zone_index, mesh_node)
			Global.log("TestWorld: placed automation hub mesh in zone %d" % zone_index)
		else:
			_place_module_fallback("AutomationHubModule", Vector3(2.2, 1.4, 1.2), zone_index)

func _place_module_fallback(module_name: String, size: Vector3, zone_index: int) -> void:
	var fallback := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	fallback.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#666666")
	fallback.material_override = mat
	fallback.name = module_name
	fallback.position.y = size.y / 2.0
	_ship_interior.place_module_in_zone(zone_index, fallback)
	Global.log("TestWorld: placed %s fallback mesh in zone %d" % [module_name, zone_index])

func _open_module_panel(zone_index: int) -> void:
	var module_id: String = _zone_module_ids.get(zone_index, "") as String
	match module_id:
		"recycler":
			_recycler_panel.open()
		"fabricator":
			_fabricator_panel.open()
		"automation_hub":
			_automation_hub_panel.open()
		_:
			Global.log("TestWorld: no panel for module '%s' at zone %d" % [module_id, zone_index])

func _setup_drone_manager() -> void:
	_drone_manager = DroneManager.new()
	_drone_manager.name = "DroneManager"
	add_child(_drone_manager)
	_drone_manager.setup(Vector3.ZERO)
	Global.log("TestWorld: drone manager ready")

func _setup_travel_sequence() -> void:
	_travel_manager = TravelSequenceManager.new()
	_travel_manager.name = "TravelSequenceManager"
	add_child(_travel_manager)
	_travel_manager.setup(_player, _ship_exterior, _biome_content)
	_travel_manager.travel_sequence_started.connect(_on_travel_sequence_started)
	_travel_manager.travel_sequence_completed.connect(_on_travel_sequence_completed)
	Global.log("TestWorld: travel sequence manager ready")

func _on_travel_sequence_started(destination_id: String) -> void:
	_transitioning = true
	Global.log("TestWorld: travel sequence started → '%s'" % destination_id)

func _on_travel_sequence_completed(destination_id: String) -> void:
	_transitioning = false
	# Reposition the full-hull boarding zone to follow the ship after biome travel.
	# Offset (0, 4.5, 0) centers the BoxShape3D on the ship's bounding box at its new location.
	# ship_pos.y + 4.5 tracks terrain height correctly for all biomes (TICKET-0206).
	if _ship_enter_zone and _ship_exterior:
		var ship_pos: Vector3 = _ship_exterior.position
		var enter_col: CollisionShape3D = _ship_enter_zone.get_child(0) as CollisionShape3D
		if enter_col:
			enter_col.position = Vector3(ship_pos.x, ship_pos.y + 4.5, ship_pos.z)
	# Update ship interior exterior marker to match new ship position
	if _ship_interior and _ship_exterior:
		var exit_offset: Vector3 = Vector3(0.0, 0.0, 24.0)
		_ship_interior.set_exterior_position(_ship_exterior.position + exit_offset)
	Global.log("TestWorld: travel sequence completed → '%s'" % destination_id)

func _on_drone_deployed(drone_id: int, program: DroneProgram) -> void:
	if _drone_manager:
		_drone_manager.spawn_drone(drone_id, program)

func _on_drones_recalled() -> void:
	if _drone_manager:
		_drone_manager.recall_all_drones()

func _add_interaction_area(parent: Node3D, size: Vector3) -> void:
	var area := Area3D.new()
	area.name = "InteractionArea"
	area.collision_layer = 1 << 3
	area.collision_mask = 1 << 0
	var col := CollisionShape3D.new()
	col.name = "InteractionShape"
	var shape := BoxShape3D.new()
	shape.size = size + Vector3(0.5, 0.5, 0.5)
	col.shape = shape
	col.position = Vector3(0, size.y / 2.0, 0)
	area.add_child(col)
	parent.add_child(area)

func _on_ship_enter_zone_entered(body: Node3D) -> void:
	if body == _first_person:
		_player_near_ship_entrance = true
		Global.log("TestWorld: player near ship entrance")

func _on_ship_enter_zone_exited(body: Node3D) -> void:
	if body == _first_person:
		_player_near_ship_entrance = false

func _on_player_entered_ship() -> void:
	Global.log("TestWorld: player entered ship — activating ship HUD")
	if _hud:
		_hud.show_ship_globals(true)
	if _ship_enter_zone:
		_ship_enter_zone.set_prompt_enabled(false)

func _on_player_exited_ship() -> void:
	Global.log("TestWorld: player exited ship — deactivating ship HUD")
	if _ship_enter_zone:
		_ship_enter_zone.set_prompt_enabled(true)
	if _hud:
		_hud.show_ship_globals(false)
	# Close any open ship UI panels
	if _recycler_panel and _recycler_panel.is_open():
		_recycler_panel.close()
	if _module_placement_ui and _module_placement_ui.is_open():
		_module_placement_ui.close()
	if _tech_tree_panel and _tech_tree_panel.is_open():
		_tech_tree_panel.close()
	if _fabricator_panel and _fabricator_panel.is_open():
		_fabricator_panel.close()
	if _automation_hub_panel and _automation_hub_panel.is_open():
		_automation_hub_panel.close()
	if _navigation_console and _navigation_console.is_open():
		_navigation_console.close_panel()

func _on_view_mode_changed(mode: String) -> void:
	Global.log("TestWorld: view mode changed to %s" % mode)
	var new_camera: Camera3D = null
	if mode == "third_person" and _third_person:
		new_camera = _third_person.get_camera()
	elif _first_person and _first_person.has_method("get_camera"):
		new_camera = _first_person.get_camera()
	if new_camera:
		_camera = new_camera
		if _scanner:
			_scanner.set_camera(new_camera)
			_scanner.set_view_mode(mode)
		if _mining:
			_mining.set_camera(new_camera)
		if _hud:
			var prompt_hud: InteractionPromptHUD = _hud.get_interaction_prompt_hud()
			if prompt_hud:
				prompt_hud.set_camera(new_camera)
	if _hud:
		_hud.set_crosshair_visible(mode == "first_person")
