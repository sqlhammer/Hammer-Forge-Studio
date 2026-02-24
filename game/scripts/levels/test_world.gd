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
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Global.log("TestWorld: initialization complete")

func _process(delta: float) -> void:
	_update_recharge(delta)
	_update_ship_interact()

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

	# Ship mesh
	var ship_scene: Resource = load("res://assets/meshes/vehicles/mesh_ship_exterior.glb")
	if ship_scene and ship_scene is PackedScene:
		var ship_mesh: Node3D = (ship_scene as PackedScene).instantiate()
		ship_mesh.name = "ShipMesh"
		ship_mesh.scale = Vector3(4, 4, 4)
		ship_mesh.position.y = 1.1
		ship.add_child(ship_mesh)

	# Ship collision (approximate with a box)
	var ship_body := StaticBody3D.new()
	ship_body.name = "ShipBody"
	ship_body.collision_layer = LAYER_ENVIRONMENT
	ship_body.collision_mask = 0
	var ship_col := CollisionShape3D.new()
	var ship_shape := BoxShape3D.new()
	ship_shape.size = Vector3(3.5, 2.2, 4.0)
	ship_col.shape = ship_shape
	ship_col.position.y = 1.1
	ship_body.add_child(ship_col)
	ship.add_child(ship_body)

	# Recharge zone (larger area around ship)
	_recharge_zone = Area3D.new()
	_recharge_zone.name = "RechargeZone"
	_recharge_zone.collision_layer = 0
	_recharge_zone.collision_mask = LAYER_PLAYER
	var recharge_col := CollisionShape3D.new()
	var recharge_shape := BoxShape3D.new()
	recharge_shape.size = Vector3(8.0, 5.0, 10.0)
	recharge_col.shape = recharge_shape
	recharge_col.position.y = 1.5
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
	_player.position = Vector3(0, 0.9, 8)  # Spawn near ship, Y=0.9 to rest capsule on ground
	add_child(_player)

	# Get first-person controller and camera
	_first_person = _player.get_node("FirstPersonController") as CharacterBody3D
	if _first_person and _first_person.has_method("get_camera"):
		_camera = _first_person.get_camera()

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

	# Set the exterior exit position to just outside the ship ramp
	_ship_interior.set_exterior_position(Vector3(0, 0.9, 6))

	# Connect ship interior signals
	_ship_interior.player_entered_ship.connect(_on_player_entered_ship)
	_ship_interior.player_exited_ship.connect(_on_player_exited_ship)

	# Create an enter-ship interaction zone near the ship exterior
	_ship_enter_zone = Area3D.new()
	_ship_enter_zone.name = "ShipEnterZone"
	_ship_enter_zone.collision_layer = 0
	_ship_enter_zone.collision_mask = LAYER_PLAYER
	var enter_col := CollisionShape3D.new()
	var enter_shape := BoxShape3D.new()
	enter_shape.size = Vector3(3.0, 3.0, 2.0)
	enter_col.shape = enter_shape
	enter_col.position = Vector3(0, 1.5, 4.5)
	_ship_enter_zone.add_child(enter_col)
	add_child(_ship_enter_zone)

	_ship_enter_zone.body_entered.connect(_on_ship_enter_zone_entered)
	_ship_enter_zone.body_exited.connect(_on_ship_enter_zone_exited)
	Global.log("TestWorld: ship interior ready")

func _update_ship_interact() -> void:
	if _transitioning or not _ship_interior:
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

func _begin_enter_ship() -> void:
	_transitioning = true
	await _ship_interior.enter_ship(_first_person)
	_transitioning = false

func _begin_exit_ship() -> void:
	_transitioning = true
	await _ship_interior.exit_ship()
	_transitioning = false

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
