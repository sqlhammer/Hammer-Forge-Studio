## Unit tests for the Root Game startup configuration — covers Global startup params,
## MainMenu scene behavior, and DebugLauncher post-TICKET-0233 refactor (Global state
## setters, begin-wealthy Global.starting_inventory toggle, removed methods).
## Ticket: TICKET-0235
class_name TestGameStartupUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────

var _original_starting_biome: String = ""
var _original_starting_inventory: Dictionary = {}
var _debug_launcher: DebugLauncher = null
var _main_menu: MainMenu = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_original_starting_biome = Global.starting_biome
	_original_starting_inventory = Global.starting_inventory.duplicate()
	PlayerInventory.clear_all()


func after_each() -> void:
	Global.starting_biome = _original_starting_biome
	Global.starting_inventory = _original_starting_inventory
	PlayerInventory.clear_all()
	if is_instance_valid(_debug_launcher):
		_debug_launcher.queue_free()
	_debug_launcher = null
	if is_instance_valid(_main_menu):
		_main_menu.queue_free()
	_main_menu = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Global startup params
	add_test("global_starting_biome_default", _test_global_starting_biome_default)
	add_test("global_starting_inventory_default", _test_global_starting_inventory_default)
	add_test("global_starting_biome_accepts_assignment", _test_global_starting_biome_accepts_assignment)
	add_test("global_starting_inventory_accepts_assignment", _test_global_starting_inventory_accepts_assignment)
	add_test("global_starting_biome_retains_multiple_assignments", _test_global_starting_biome_retains_multiple_assignments)
	add_test("global_starting_inventory_retains_multiple_entries", _test_global_starting_inventory_retains_multiple_entries)

	# MainMenu
	add_test("main_menu_instantiates_without_error", _test_main_menu_instantiates_without_error)
	add_test("main_menu_has_play_button_node", _test_main_menu_has_play_button_node)
	add_test("main_menu_has_play_pressed_signal", _test_main_menu_has_play_pressed_signal)
	add_test("main_menu_game_world_scene_constant_correct", _test_main_menu_game_world_scene_constant_correct)

	# DebugLauncher post-refactor
	add_test("debug_launcher_get_biome_entries_all_biomes", _test_debug_launcher_get_biome_entries_all_biomes)
	add_test("debug_launcher_sets_starting_biome_on_ready", _test_debug_launcher_sets_starting_biome_on_ready)
	add_test("debug_launcher_starting_biome_is_valid_biome_id", _test_debug_launcher_starting_biome_is_valid_biome_id)
	add_test("debug_launcher_begin_wealthy_on_populates_inventory", _test_debug_launcher_begin_wealthy_on_populates_inventory)
	add_test("debug_launcher_begin_wealthy_off_clears_inventory", _test_debug_launcher_begin_wealthy_off_clears_inventory)
	add_test("debug_launcher_begin_wealthy_on_skips_none_resource", _test_debug_launcher_begin_wealthy_on_skips_none_resource)
	add_test("debug_launcher_begin_wealthy_on_covers_all_catalog_resources", _test_debug_launcher_begin_wealthy_on_covers_all_catalog_resources)
	add_test("debug_launcher_does_not_have_grant_wealthy_resources", _test_debug_launcher_does_not_have_grant_wealthy_resources)
	add_test("debug_launcher_does_not_have_launch_method", _test_debug_launcher_does_not_have_launch_method)
	add_test("debug_launcher_does_not_have_build_debug_world", _test_debug_launcher_does_not_have_build_debug_world)


# ── Test Methods: Global startup params ──────────────────

func _test_global_starting_biome_default() -> void:
	Global.starting_biome = "shattered_flats"
	assert_equal(Global.starting_biome, "shattered_flats",
		"Global.starting_biome should default to 'shattered_flats'")


func _test_global_starting_inventory_default() -> void:
	Global.starting_inventory = {}
	assert_true(Global.starting_inventory.is_empty(),
		"Global.starting_inventory should default to an empty dictionary")


func _test_global_starting_biome_accepts_assignment() -> void:
	Global.starting_biome = "rock_warrens"
	assert_equal(Global.starting_biome, "rock_warrens",
		"Global.starting_biome should accept and retain 'rock_warrens'")


func _test_global_starting_inventory_accepts_assignment() -> void:
	var test_inv: Dictionary = {ResourceDefs.ResourceType.METAL: 10}
	Global.starting_inventory = test_inv
	assert_equal(Global.starting_inventory.size(), 1,
		"Global.starting_inventory should retain one entry after assignment")
	assert_equal(Global.starting_inventory.get(ResourceDefs.ResourceType.METAL, 0) as int, 10,
		"Global.starting_inventory should retain METAL quantity of 10")


func _test_global_starting_biome_retains_multiple_assignments() -> void:
	Global.starting_biome = "debris_field"
	assert_equal(Global.starting_biome, "debris_field",
		"Global.starting_biome should retain 'debris_field' assignment")
	Global.starting_biome = "shattered_flats"
	assert_equal(Global.starting_biome, "shattered_flats",
		"Global.starting_biome should update to new value 'shattered_flats'")


func _test_global_starting_inventory_retains_multiple_entries() -> void:
	Global.starting_inventory = {
		ResourceDefs.ResourceType.SCRAP_METAL: 100,
		ResourceDefs.ResourceType.CRYONITE: 50,
	}
	assert_equal(Global.starting_inventory.size(), 2,
		"Global.starting_inventory should retain two entries")
	assert_equal(Global.starting_inventory.get(ResourceDefs.ResourceType.SCRAP_METAL, 0) as int, 100,
		"Global.starting_inventory should retain SCRAP_METAL quantity of 100")
	assert_equal(Global.starting_inventory.get(ResourceDefs.ResourceType.CRYONITE, 0) as int, 50,
		"Global.starting_inventory should retain CRYONITE quantity of 50")


# ── Test Methods: MainMenu ────────────────────────────────

func _test_main_menu_instantiates_without_error() -> void:
	_main_menu = MainMenu.new()
	add_child(_main_menu)
	assert_not_null(_main_menu, "MainMenu should instantiate and add to scene tree without error")


func _test_main_menu_has_play_button_node() -> void:
	_main_menu = MainMenu.new()
	add_child(_main_menu)
	var play_button: Node = _main_menu.get_node_or_null(
		"CenterContainer/MenuLayout/PlayButton"
	)
	assert_not_null(play_button,
		"MainMenu should have a node named 'PlayButton' after _ready()")


func _test_main_menu_has_play_pressed_signal() -> void:
	_main_menu = MainMenu.new()
	add_child(_main_menu)
	assert_true(_main_menu.has_signal("play_pressed"),
		"MainMenu should declare a play_pressed signal")


func _test_main_menu_game_world_scene_constant_correct() -> void:
	assert_equal(MainMenu.GAME_WORLD_SCENE, "res://scenes/gameplay/game_world.tscn",
		"MainMenu.GAME_WORLD_SCENE should point to res://scenes/gameplay/game_world.tscn")


# ── Test Methods: DebugLauncher post-refactor ─────────────

func _test_debug_launcher_get_biome_entries_all_biomes() -> void:
	var entries: Array[Dictionary] = DebugLauncher.get_biome_entries()
	assert_equal(entries.size(), BiomeRegistry.BIOME_IDS.size(),
		"get_biome_entries() should return one entry per biome registered in BiomeRegistry")


func _test_debug_launcher_sets_starting_biome_on_ready() -> void:
	_debug_launcher = DebugLauncher.new()
	add_child(_debug_launcher)
	# After _ready(), the biome selector is populated and Global.starting_biome is set
	assert_false(Global.starting_biome == "",
		"DebugLauncher should set Global.starting_biome to a non-empty string on _ready()")


func _test_debug_launcher_starting_biome_is_valid_biome_id() -> void:
	_debug_launcher = DebugLauncher.new()
	add_child(_debug_launcher)
	assert_true(BiomeRegistry.is_valid_biome(Global.starting_biome),
		"DebugLauncher should set Global.starting_biome to a valid BiomeRegistry ID on _ready()")


func _test_debug_launcher_begin_wealthy_on_populates_inventory() -> void:
	_debug_launcher = DebugLauncher.new()
	add_child(_debug_launcher)
	Global.starting_inventory = {}
	_debug_launcher._on_begin_wealthy_toggled(true)
	assert_false(Global.starting_inventory.is_empty(),
		"Global.starting_inventory should be non-empty after begin-wealthy toggled ON")


func _test_debug_launcher_begin_wealthy_off_clears_inventory() -> void:
	_debug_launcher = DebugLauncher.new()
	add_child(_debug_launcher)
	_debug_launcher._on_begin_wealthy_toggled(true)
	_debug_launcher._on_begin_wealthy_toggled(false)
	assert_true(Global.starting_inventory.is_empty(),
		"Global.starting_inventory should be {} after begin-wealthy toggled OFF")


func _test_debug_launcher_begin_wealthy_on_skips_none_resource() -> void:
	_debug_launcher = DebugLauncher.new()
	add_child(_debug_launcher)
	_debug_launcher._on_begin_wealthy_toggled(true)
	assert_false(Global.starting_inventory.has(ResourceDefs.ResourceType.NONE),
		"Global.starting_inventory should not contain NONE resource type")


func _test_debug_launcher_begin_wealthy_on_covers_all_catalog_resources() -> void:
	_debug_launcher = DebugLauncher.new()
	add_child(_debug_launcher)
	_debug_launcher._on_begin_wealthy_toggled(true)
	for resource_key: int in ResourceDefs.RESOURCE_CATALOG:
		var resource_type: ResourceDefs.ResourceType = resource_key as ResourceDefs.ResourceType
		if resource_type == ResourceDefs.ResourceType.NONE:
			continue
		assert_true(Global.starting_inventory.has(resource_type),
			"Global.starting_inventory should include resource '%s' when begin-wealthy is ON"
				% ResourceDefs.get_resource_name(resource_type))


func _test_debug_launcher_does_not_have_grant_wealthy_resources() -> void:
	_debug_launcher = DebugLauncher.new()
	add_child(_debug_launcher)
	assert_false(_debug_launcher.has_method("grant_wealthy_resources"),
		"DebugLauncher should no longer have grant_wealthy_resources() — removed in TICKET-0233")


func _test_debug_launcher_does_not_have_launch_method() -> void:
	_debug_launcher = DebugLauncher.new()
	add_child(_debug_launcher)
	assert_false(_debug_launcher.has_method("_launch"),
		"DebugLauncher should no longer have _launch() — removed in TICKET-0233")


func _test_debug_launcher_does_not_have_build_debug_world() -> void:
	_debug_launcher = DebugLauncher.new()
	add_child(_debug_launcher)
	assert_false(_debug_launcher.has_method("_build_debug_world"),
		"DebugLauncher should no longer have _build_debug_world() — removed in TICKET-0233")
