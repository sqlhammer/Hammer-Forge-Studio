## World object representing an inventory item dropped on the ground.
## Provides interaction prompt for pickup and self-handles pickup when the player
## presses interact while nearby. Uses Area3D so raycasts (scanner, mining) pass through.
## Owner: gameplay-programmer
class_name DroppedItem
extends Area3D

# ── Signals ──────────────────────────────────────────────
signal item_picked_up(resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int)

# ── Constants ─────────────────────────────────────────────
const DETECTION_RADIUS: float = 1.5
const MESH_SCALE: float = 0.3
const MESH_Y_OFFSET: float = 0.3
const BOB_AMPLITUDE: float = 0.08
const BOB_SPEED: float = 2.0
const SPIN_SPEED: float = 1.5

## Resource type to mesh color mapping
const RESOURCE_COLORS: Dictionary = {
	ResourceDefs.ResourceType.SCRAP_METAL: Color("#808080"),
	ResourceDefs.ResourceType.METAL: Color("#C0C0C0"),
	ResourceDefs.ResourceType.SPARE_BATTERY: Color("#00AA00"),
	ResourceDefs.ResourceType.CRYONITE: Color("#00CCFF"),
	ResourceDefs.ResourceType.FUEL_CELL: Color("#FFB830"),
}

# ── Private Variables ─────────────────────────────────────
var _resource_type: ResourceDefs.ResourceType = ResourceDefs.ResourceType.NONE
var _purity: ResourceDefs.Purity = ResourceDefs.Purity.ONE_STAR
var _quantity: int = 0
var _mesh_instance: MeshInstance3D = null
var _bob_timer: float = 0.0
var _player_inside: bool = false

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	add_to_group("interaction_prompt_source")
	add_to_group("interactable")
	# Area3D detects player proximity only — no collision layer so raycasts pass through
	collision_layer = 0
	collision_mask = PhysicsLayers.PLAYER
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_collision_shape()
	_build_visual_mesh()
	Global.log("DroppedItem: spawned %s x%d" % [ResourceDefs.get_resource_name(_resource_type), _quantity])


func _process(delta: float) -> void:
	# Animate the floating mesh
	_bob_timer += delta
	if _mesh_instance:
		var bob_offset: float = sin(_bob_timer * BOB_SPEED) * BOB_AMPLITUDE
		_mesh_instance.position.y = MESH_Y_OFFSET + bob_offset
		_mesh_instance.rotation.y += SPIN_SPEED * delta

	# Handle pickup when player is nearby and presses interact
	if _player_inside and InputManager.is_action_just_pressed("interact"):
		_try_pickup()

# ── Public Methods ────────────────────────────────────────

## Configures the dropped item with resource data. Must be called before adding to tree.
func setup(resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int) -> void:
	_resource_type = resource_type
	_purity = purity
	_quantity = quantity


## Returns the interaction prompt for the HUD system (duck-typed interface).
func get_interaction_prompt() -> Dictionary:
	if _quantity <= 0:
		return {}
	var resource_name: String = ResourceDefs.get_resource_name(_resource_type)
	var label: String = "Pick up %s" % resource_name
	var key_label: String = _get_interact_key_label()
	return {
		"key": key_label,
		"label": label,
		"hold": false,
	}


## Returns the resource type of this dropped item.
func get_resource_type() -> ResourceDefs.ResourceType:
	return _resource_type


## Returns the purity of this dropped item.
func get_purity() -> ResourceDefs.Purity:
	return _purity


## Returns the quantity of this dropped item.
func get_quantity() -> int:
	return _quantity

# ── Private Methods ───────────────────────────────────────

## Attempts to pick up the item and add it to the player's inventory.
func _try_pickup() -> void:
	var remainder: int = PlayerInventory.add_item(_resource_type, _purity, _quantity)
	if remainder == _quantity:
		# Nothing was added — inventory is full
		Global.log("DroppedItem: pickup failed — inventory full for %s" % ResourceDefs.get_resource_name(_resource_type))
		return
	var picked_up: int = _quantity - remainder
	Global.log("DroppedItem: picked up %s x%d" % [ResourceDefs.get_resource_name(_resource_type), picked_up])
	item_picked_up.emit(_resource_type, _purity, picked_up)
	if remainder > 0:
		# Partial pickup — update quantity
		_quantity = remainder
	else:
		queue_free()


## Creates the collision shape for player proximity detection.
func _build_collision_shape() -> void:
	var col_shape := CollisionShape3D.new()
	col_shape.name = "DetectionShape"
	var sphere := SphereShape3D.new()
	sphere.radius = DETECTION_RADIUS
	col_shape.shape = sphere
	add_child(col_shape)


## Creates the visual mesh representation of the dropped item.
func _build_visual_mesh() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "ItemMesh"
	var box := BoxMesh.new()
	box.size = Vector3(MESH_SCALE, MESH_SCALE, MESH_SCALE)
	_mesh_instance.mesh = box
	_mesh_instance.position.y = MESH_Y_OFFSET

	# Apply resource-type-specific color
	var material := StandardMaterial3D.new()
	var color: Color = RESOURCE_COLORS.get(_resource_type, Color.WHITE)
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.3
	_mesh_instance.material_override = material
	add_child(_mesh_instance)


## Resolves the current key label for the "interact" action from the InputMap.
func _get_interact_key_label() -> String:
	var events: Array[InputEvent] = InputMap.action_get_events("interact")
	for event: InputEvent in events:
		if event is InputEventKey:
			var key_event: InputEventKey = event as InputEventKey
			return OS.get_keycode_string(key_event.keycode)
	return "E"


func _on_body_entered(body: Node3D) -> void:
	if body.collision_layer & PhysicsLayers.PLAYER:
		_player_inside = true
		Global.log("DroppedItem: player entered pickup range")


func _on_body_exited(body: Node3D) -> void:
	if body.collision_layer & PhysicsLayers.PLAYER:
		_player_inside = false
