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

## Physics layers
const LAYER_PLAYER: int = 1 << 0  # Layer 1
const LAYER_ENVIRONMENT: int = 1 << 2  # Layer 3
const LAYER_INTERACTABLE: int = 1 << 3  # Layer 4

# ── Private Variables ─────────────────────────────────────
var _player: Node3D = null
var _first_person: CharacterBody3D = null
var _camera: Camera3D = null
var _scanner: Scanner = null
var _mining: Mining = null
var _hud: GameHUD = null
var _inventory_screen: InventoryScreen = null
var _recharge_zone: Area3D = null
var _deposit_container: Node3D = null
var _ship_interior: Node3D = null
var _ship_enter_zone: Area3D = null
var _player_near_ship_entrance: bool = false
var _transitioning: bool = false
var _module_placement_ui: ModulePlacementUI = null
var _recycler_panel: RecyclerPanel = null
var _head_lamp_light: SpotLight3D = null
var _third_person: PlayerThirdPerson = null
var _player_manager: PlayerManager = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	Global.log("TestWorld: initializing")
	_build_environment()
	_build_ground()
	_build_boundaries()
	_build_ship()
	_spawn_player()
	_generate_deposits()
	_setup_gameplay_systems()
	_setup_ship_interior()
	_setup_hud()
	_setup_ship_ui()
	_setup_head_lamp()
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

func _build_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	ground.collision_layer = LAYER_ENVIRONMENT
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

	add_child(ground)

func _build_boundaries() -> void:
	var boundaries := Node3D.new()
	boundaries.name = "Boundaries"
	add_child(boundaries)

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
		wall.collision_layer = LAYER_ENVIRONMENT
		wall.collision_mask = 0
		wall.position = offsets[i]

		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = sizes[i]
		col.shape = shape
		wall.add_child(col)

		boundaries.add_child(wall)

func _build_ship() -> void:
	var ship := Node3D.new()
	ship.name = "Ship"
	ship.position = Vector3.ZERO
	add_child(ship)

	# Ship mesh (3× native scale per TICKET-0081 — no in-engine scale override)
	var ship_scene: Resource = load("res://assets/meshes/vehicles/mesh_ship_exterior.glb")
	if ship_scene and ship_scene is PackedScene:
		var ship_mesh: Node3D = (ship_scene as PackedScene).instantiate()
		ship_mesh.name = "ShipMesh"
		ship_mesh.position.y = 3.3
		ship.add_child(ship_mesh)

	# Ship collision (approximate with a box matching 3× hull)
	var ship_body := StaticBody3D.new()
	ship_body.name = "ShipBody"
	ship_body.collision_layer = LAYER_ENVIRONMENT
	ship_body.collision_mask = 0
	var ship_col := CollisionShape3D.new()
	var ship_shape := BoxShape3D.new()
	ship_shape.size = Vector3(21.0, 12.0, 42.0)
	ship_col.shape = ship_shape
	ship_col.position.y = 6.0
	ship_body.add_child(ship_col)
	ship.add_child(ship_body)

	# Recharge zone (larger area around ship entrance)
	_recharge_zone = Area3D.new()
	_recharge_zone.name = "RechargeZone"
	_recharge_zone.collision_layer = 0
	_recharge_zone.collision_mask = LAYER_PLAYER
	var recharge_col := CollisionShape3D.new()
	var recharge_shape := BoxShape3D.new()
	recharge_shape.size = Vector3(24.0, 15.0, 30.0)
	recharge_col.shape = recharge_shape
	recharge_col.position.y = 4.5
	_recharge_zone.add_child(recharge_col)
	ship.add_child(_recharge_zone)

	_recharge_zone.body_entered.connect(_on_recharge_zone_entered)
	_recharge_zone.body_exited.connect(_on_recharge_zone_exited)

func _spawn_player() -> void:
	var player_scene: PackedScene = load("res://player/player.tscn") as PackedScene
	if not player_scene:
		push_error("TestWorld: Could not load player scene!")
		return
	_player = player_scene.instantiate()
	_player.name = "Player"
	_player.position = Vector3(0, 0.9, 24)  # Spawn near ship entrance (3× hull), Y=0.9 to rest capsule on ground
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
		_first_person.collision_layer = LAYER_PLAYER
		_first_person.collision_mask = LAYER_ENVIRONMENT | LAYER_INTERACTABLE

func _generate_deposits() -> void:
	_deposit_container = Node3D.new()
	_deposit_container.name = "Deposits"
	add_child(_deposit_container)

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
		body.collision_layer = LAYER_INTERACTABLE
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
	# Main HUD
	_hud = GameHUD.new()
	_hud.name = "HUD"
	add_child(_hud)
	if _camera and _first_person and _scanner and _mining:
		_hud.setup(_camera, _first_person, _scanner, _mining)

	# Inventory screen (separate CanvasLayer)
	_inventory_screen = InventoryScreen.new()
	_inventory_screen.name = "InventoryScreen"
	add_child(_inventory_screen)

func _update_recharge(delta: float) -> void:
	if SuitBattery.is_recharging():
		SuitBattery.process_recharge(delta)

func _on_recharge_zone_entered(body: Node3D) -> void:
	if body == _first_person:
		Global.log("TestWorld: player entered recharge zone")
		SuitBattery.start_recharge()

func _on_recharge_zone_exited(body: Node3D) -> void:
	if body == _first_person:
		Global.log("TestWorld: player exited recharge zone")
		SuitBattery.stop_recharge()

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

	if _first_person:
		_ship_interior.setup(_first_person)

	# Set the exterior exit position to just outside the ship ramp (scaled for 3× hull)
	_ship_interior.set_exterior_position(Vector3(0, 0.9, 18))

	# Connect ship interior signals
	_ship_interior.player_entered_ship.connect(_on_player_entered_ship)
	_ship_interior.player_exited_ship.connect(_on_player_exited_ship)

	# Create an enter-ship interaction zone that straddles the hull edge (3× hull Z-edge = 21)
	# Zone must extend outside the hull so the player can reach it without clipping through
	_ship_enter_zone = Area3D.new()
	_ship_enter_zone.name = "ShipEnterZone"
	_ship_enter_zone.collision_layer = 0
	_ship_enter_zone.collision_mask = LAYER_PLAYER
	var enter_col := CollisionShape3D.new()
	var enter_shape := BoxShape3D.new()
	enter_shape.size = Vector3(12.0, 6.0, 10.0)
	enter_col.shape = enter_shape
	enter_col.position = Vector3(0, 3.0, 23.0)
	_ship_enter_zone.add_child(enter_col)
	add_child(_ship_enter_zone)

	_ship_enter_zone.body_entered.connect(_on_ship_enter_zone_entered)
	_ship_enter_zone.body_exited.connect(_on_ship_enter_zone_exited)
	Global.log("TestWorld: ship interior ready")

func _update_ship_interact() -> void:
	if _transitioning or not _ship_interior:
		return

	# Don't process interact while a UI panel is open
	if _module_placement_ui and _module_placement_ui.is_open():
		return
	if _recycler_panel and _recycler_panel.is_open():
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

	# Interact with placement zones when inside ship
	if _ship_interior.is_player_inside():
		if InputManager.is_action_just_pressed("interact"):
			var zone_index: int = _ship_interior.get_nearby_zone_index()
			if zone_index >= 0:
				if _ship_interior.is_zone_occupied(zone_index):
					_recycler_panel.open()
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
	# Module placement UI
	_module_placement_ui = ModulePlacementUI.new()
	_module_placement_ui.name = "ModulePlacementUI"
	add_child(_module_placement_ui)
	_module_placement_ui.module_installed.connect(_on_module_installed)

	# Recycler interaction panel
	_recycler_panel = RecyclerPanel.new()
	_recycler_panel.name = "RecyclerPanel"
	add_child(_recycler_panel)

	# Restore any modules already installed (e.g., from autoload state after scene reload)
	_restore_installed_modules()
	Global.log("TestWorld: ship UI ready")

func _restore_installed_modules() -> void:
	var installed_ids: Array[String] = ModuleManager.get_installed_module_ids()
	for module_id: String in installed_ids:
		var zone_index: int = _ship_interior.get_first_empty_zone()
		if zone_index >= 0:
			_place_module_visual(module_id, zone_index)

func _on_module_installed(module_id: String, zone_index: int) -> void:
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
			_add_interaction_area(mesh_node, Vector3(2.0, 1.2, 1.0))
			_ship_interior.place_module_in_zone(zone_index, mesh_node)
			Global.log("TestWorld: placed fabricator mesh in zone %d" % zone_index)
		else:
			_place_module_fallback("FabricatorModule", Vector3(2.0, 1.2, 1.0), zone_index)

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

func _on_player_exited_ship() -> void:
	Global.log("TestWorld: player exited ship — deactivating ship HUD")
	if _hud:
		_hud.show_ship_globals(false)
	# Close any open ship UI panels
	if _recycler_panel and _recycler_panel.is_open():
		_recycler_panel.close()
	if _module_placement_ui and _module_placement_ui.is_open():
		_module_placement_ui.close()

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
		_hud.set_crosshair_visible(mode == "first_person")
