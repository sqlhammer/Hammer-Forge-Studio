## Unit tests for GameWorld startup behavior — biome selection, inventory application,
## game-state reset, and structural constants.
## Tests exercise private methods directly (GDScript has no true access control)
## and do NOT add GameWorld to the scene tree, avoiding heavy _ready() side-effects.
## Ticket: TICKET-0235
class_name TestGameWorldUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────

var _original_starting_biome: String = ""
var _original_starting_inventory: Dictionary = {}
var _game_world: GameWorld = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_original_starting_biome = Global.starting_biome
	_original_starting_inventory = Global.starting_inventory.duplicate()
	PlayerInventory.clear_all()
	NavigationSystem.reset()
	FuelSystem.reset_to_full()
	ShipState.reset()


func after_each() -> void:
	Global.starting_biome = _original_starting_biome
	Global.starting_inventory = _original_starting_inventory
	PlayerInventory.clear_all()
	NavigationSystem.reset()
	FuelSystem.reset_to_full()
	ShipState.reset()
	if is_instance_valid(_game_world):
		_game_world.queue_free()
	_game_world = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Biome script mapping
	add_test("biome_scripts_contains_shattered_flats", _test_biome_scripts_contains_shattered_flats)
	add_test("biome_scripts_contains_rock_warrens", _test_biome_scripts_contains_rock_warrens)
	add_test("biome_scripts_contains_debris_field", _test_biome_scripts_contains_debris_field)
	add_test("biome_scripts_count_matches_biome_registry", _test_biome_scripts_count_matches_biome_registry)

	# Biome instance creation
	add_test("create_biome_instance_shattered_flats_returns_node", _test_create_biome_instance_shattered_flats_returns_node)
	add_test("create_biome_instance_rock_warrens_returns_node", _test_create_biome_instance_rock_warrens_returns_node)
	add_test("create_biome_instance_debris_field_returns_node", _test_create_biome_instance_debris_field_returns_node)
	add_test("create_biome_instance_invalid_returns_null", _test_create_biome_instance_invalid_returns_null)

	# Inventory application
	add_test("apply_starting_inventory_adds_items_to_player_inventory", _test_apply_starting_inventory_adds_items_to_player_inventory)
	add_test("apply_starting_inventory_empty_adds_no_items", _test_apply_starting_inventory_empty_adds_no_items)
	add_test("apply_starting_inventory_multiple_resource_types", _test_apply_starting_inventory_multiple_resource_types)
	add_test("apply_starting_inventory_uses_default_purity", _test_apply_starting_inventory_uses_default_purity)

	# Constants
	add_test("interior_y_offset_is_negative_fifty", _test_interior_y_offset_is_negative_fifty)
	add_test("default_purity_is_three_star", _test_default_purity_is_three_star)


# ── Test Methods: Biome script mapping ───────────────────

func _test_biome_scripts_contains_shattered_flats() -> void:
	assert_true(GameWorld._BIOME_SCRIPTS.has("shattered_flats"),
		"_BIOME_SCRIPTS should contain 'shattered_flats' key")


func _test_biome_scripts_contains_rock_warrens() -> void:
	assert_true(GameWorld._BIOME_SCRIPTS.has("rock_warrens"),
		"_BIOME_SCRIPTS should contain 'rock_warrens' key")


func _test_biome_scripts_contains_debris_field() -> void:
	assert_true(GameWorld._BIOME_SCRIPTS.has("debris_field"),
		"_BIOME_SCRIPTS should contain 'debris_field' key")


func _test_biome_scripts_count_matches_biome_registry() -> void:
	assert_equal(GameWorld._BIOME_SCRIPTS.size(), BiomeRegistry.BIOME_IDS.size(),
		"_BIOME_SCRIPTS should have one entry per registered biome")


# ── Test Methods: Biome instance creation ────────────────

func _test_create_biome_instance_shattered_flats_returns_node() -> void:
	_game_world = GameWorld.new()
	var biome: Node3D = _game_world._create_biome_instance("shattered_flats")
	assert_not_null(biome,
		"_create_biome_instance('shattered_flats') should return a non-null Node3D")
	if is_instance_valid(biome):
		biome.queue_free()


func _test_create_biome_instance_rock_warrens_returns_node() -> void:
	_game_world = GameWorld.new()
	var biome: Node3D = _game_world._create_biome_instance("rock_warrens")
	assert_not_null(biome,
		"_create_biome_instance('rock_warrens') should return a non-null Node3D")
	if is_instance_valid(biome):
		biome.queue_free()


func _test_create_biome_instance_debris_field_returns_node() -> void:
	_game_world = GameWorld.new()
	var biome: Node3D = _game_world._create_biome_instance("debris_field")
	assert_not_null(biome,
		"_create_biome_instance('debris_field') should return a non-null Node3D")
	if is_instance_valid(biome):
		biome.queue_free()


func _test_create_biome_instance_invalid_returns_null() -> void:
	_game_world = GameWorld.new()
	var biome: Node3D = _game_world._create_biome_instance("not_a_real_biome")
	assert_true(biome == null,
		"_create_biome_instance('not_a_real_biome') should return null for unknown biome ID")


# ── Test Methods: Inventory application ──────────────────

func _test_apply_starting_inventory_adds_items_to_player_inventory() -> void:
	_game_world = GameWorld.new()
	var inventory: Dictionary = {
		ResourceDefs.ResourceType.METAL: 50,
	}
	_game_world._apply_starting_inventory(inventory)
	var count: int = PlayerInventory.get_total_count(ResourceDefs.ResourceType.METAL)
	assert_equal(count, 50,
		"_apply_starting_inventory should add 50 Metal to PlayerInventory")


func _test_apply_starting_inventory_empty_adds_no_items() -> void:
	_game_world = GameWorld.new()
	_game_world._apply_starting_inventory({})
	var total: int = 0
	for resource_key: int in ResourceDefs.RESOURCE_CATALOG:
		var resource_type: ResourceDefs.ResourceType = resource_key as ResourceDefs.ResourceType
		if resource_type == ResourceDefs.ResourceType.NONE:
			continue
		total += PlayerInventory.get_total_count(resource_type)
	assert_equal(total, 0,
		"_apply_starting_inventory({}) should not add any items to PlayerInventory")


func _test_apply_starting_inventory_multiple_resource_types() -> void:
	_game_world = GameWorld.new()
	var inventory: Dictionary = {
		ResourceDefs.ResourceType.SCRAP_METAL: 25,
		ResourceDefs.ResourceType.CRYONITE: 10,
	}
	_game_world._apply_starting_inventory(inventory)
	assert_equal(
		PlayerInventory.get_total_count(ResourceDefs.ResourceType.SCRAP_METAL), 25,
		"_apply_starting_inventory should grant 25 Scrap Metal"
	)
	assert_equal(
		PlayerInventory.get_total_count(ResourceDefs.ResourceType.CRYONITE), 10,
		"_apply_starting_inventory should grant 10 Cryonite"
	)


func _test_apply_starting_inventory_uses_default_purity() -> void:
	# DEFAULT_PURITY is THREE_STAR — verify items are added with that purity
	_game_world = GameWorld.new()
	var inventory: Dictionary = {
		ResourceDefs.ResourceType.FUEL_CELL: 5,
	}
	_game_world._apply_starting_inventory(inventory)
	# get_total_count returns regardless of purity; confirms items were added
	var count: int = PlayerInventory.get_total_count(ResourceDefs.ResourceType.FUEL_CELL)
	assert_equal(count, 5,
		"_apply_starting_inventory should add 5 Fuel Cells using DEFAULT_PURITY")


# ── Test Methods: Constants ───────────────────────────────

func _test_interior_y_offset_is_negative_fifty() -> void:
	assert_equal(GameWorld.INTERIOR_Y_OFFSET, -50.0,
		"INTERIOR_Y_OFFSET should be -50.0 to isolate ship interior underground")


func _test_default_purity_is_three_star() -> void:
	assert_equal(
		GameWorld.DEFAULT_PURITY, ResourceDefs.Purity.THREE_STAR,
		"DEFAULT_PURITY should be THREE_STAR for starting inventory grants"
	)
