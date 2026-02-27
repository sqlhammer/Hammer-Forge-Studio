## Unit tests for mouse interaction support across menus. Verifies slot selection,
## recipe selection, tech tree node selection, and no-op on out-of-range indices.
## Tests exercise the public select/get methods that mouse click handlers call.
class_name TestMouseInteractionUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _inventory_screen: InventoryScreen = null
var _fabricator_panel: FabricatorPanel = null
var _tech_tree_panel: TechTreePanel = null
var _module_placement_ui: ModulePlacementUI = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_inventory_screen = InventoryScreen.new()
	add_child(_inventory_screen)
	_fabricator_panel = FabricatorPanel.new()
	add_child(_fabricator_panel)
	_tech_tree_panel = TechTreePanel.new()
	add_child(_tech_tree_panel)
	_module_placement_ui = ModulePlacementUI.new()
	add_child(_module_placement_ui)


func after_each() -> void:
	if _inventory_screen and _inventory_screen.is_open():
		_inventory_screen.close_inventory()
	if _fabricator_panel and _fabricator_panel.is_open():
		_fabricator_panel.close()
	if _tech_tree_panel and _tech_tree_panel.is_open():
		_tech_tree_panel.close()
	if _module_placement_ui and _module_placement_ui.is_open():
		_module_placement_ui.close()
	if _inventory_screen:
		_inventory_screen.queue_free()
		_inventory_screen = null
	if _fabricator_panel:
		_fabricator_panel.queue_free()
		_fabricator_panel = null
	if _tech_tree_panel:
		_tech_tree_panel.queue_free()
		_tech_tree_panel = null
	if _module_placement_ui:
		_module_placement_ui.queue_free()
		_module_placement_ui = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Inventory slot selection
	add_test("inventory_select_slot_changes_focus", _test_inventory_select_slot_changes_focus)
	add_test("inventory_select_slot_boundary_last", _test_inventory_select_slot_boundary_last)
	add_test("inventory_select_slot_negative_noop", _test_inventory_select_slot_negative_noop)
	add_test("inventory_select_slot_overflow_noop", _test_inventory_select_slot_overflow_noop)
	add_test("inventory_select_empty_slot_no_error", _test_inventory_select_empty_slot_no_error)
	# Fabricator recipe selection
	add_test("fabricator_select_recipe_changes_selection", _test_fabricator_select_recipe_changes_selection)
	add_test("fabricator_select_recipe_negative_noop", _test_fabricator_select_recipe_negative_noop)
	add_test("fabricator_select_recipe_overflow_noop", _test_fabricator_select_recipe_overflow_noop)
	# Tech tree node selection
	add_test("tech_tree_select_node_changes_focus", _test_tech_tree_select_node_changes_focus)
	add_test("tech_tree_select_node_negative_noop", _test_tech_tree_select_node_negative_noop)
	add_test("tech_tree_select_node_overflow_noop", _test_tech_tree_select_node_overflow_noop)
	# Module placement selection
	add_test("module_select_changes_selection", _test_module_select_changes_selection)
	add_test("module_select_negative_noop", _test_module_select_negative_noop)


# ── Test Methods: Inventory ──────────────────────────────

func _test_inventory_select_slot_changes_focus() -> void:
	_inventory_screen.open_inventory()
	_inventory_screen.select_slot(5)
	assert_equal(_inventory_screen.get_focused_slot(), 5,
		"Selecting slot 5 should update focused slot to 5")


func _test_inventory_select_slot_boundary_last() -> void:
	_inventory_screen.open_inventory()
	var last_slot: int = Inventory.MAX_SLOTS - 1
	_inventory_screen.select_slot(last_slot)
	assert_equal(_inventory_screen.get_focused_slot(), last_slot,
		"Selecting the last slot should update focus to last index")


func _test_inventory_select_slot_negative_noop() -> void:
	_inventory_screen.open_inventory()
	var initial: int = _inventory_screen.get_focused_slot()
	_inventory_screen.select_slot(-1)
	assert_equal(_inventory_screen.get_focused_slot(), initial,
		"Selecting slot -1 should not change focus")


func _test_inventory_select_slot_overflow_noop() -> void:
	_inventory_screen.open_inventory()
	var initial: int = _inventory_screen.get_focused_slot()
	_inventory_screen.select_slot(999)
	assert_equal(_inventory_screen.get_focused_slot(), initial,
		"Selecting slot 999 should not change focus")


func _test_inventory_select_empty_slot_no_error() -> void:
	_inventory_screen.open_inventory()
	# Slot 14 is empty in a fresh inventory — selecting it should work without error
	_inventory_screen.select_slot(14)
	assert_equal(_inventory_screen.get_focused_slot(), 14,
		"Selecting an empty slot should still update focus")


# ── Test Methods: Fabricator ─────────────────────────────

func _test_fabricator_select_recipe_changes_selection() -> void:
	_fabricator_panel.open()
	# Panel auto-selects index 0 on open; select index 1
	_fabricator_panel.select_recipe_by_index(1)
	assert_equal(_fabricator_panel.get_selected_recipe_index(), 1,
		"Selecting recipe index 1 should update selection")


func _test_fabricator_select_recipe_negative_noop() -> void:
	_fabricator_panel.open()
	var initial: int = _fabricator_panel.get_selected_recipe_index()
	_fabricator_panel.select_recipe_by_index(-1)
	assert_equal(_fabricator_panel.get_selected_recipe_index(), initial,
		"Selecting recipe -1 should not change selection")


func _test_fabricator_select_recipe_overflow_noop() -> void:
	_fabricator_panel.open()
	var initial: int = _fabricator_panel.get_selected_recipe_index()
	_fabricator_panel.select_recipe_by_index(999)
	assert_equal(_fabricator_panel.get_selected_recipe_index(), initial,
		"Selecting recipe 999 should not change selection")


# ── Test Methods: Tech Tree ──────────────────────────────

func _test_tech_tree_select_node_changes_focus() -> void:
	_tech_tree_panel.open()
	_tech_tree_panel.select_node_by_index(1)
	assert_equal(_tech_tree_panel.get_focused_node_index(), 1,
		"Selecting node index 1 should update focus")


func _test_tech_tree_select_node_negative_noop() -> void:
	_tech_tree_panel.open()
	var initial: int = _tech_tree_panel.get_focused_node_index()
	_tech_tree_panel.select_node_by_index(-1)
	assert_equal(_tech_tree_panel.get_focused_node_index(), initial,
		"Selecting node -1 should not change focus")


func _test_tech_tree_select_node_overflow_noop() -> void:
	_tech_tree_panel.open()
	var initial: int = _tech_tree_panel.get_focused_node_index()
	_tech_tree_panel.select_node_by_index(999)
	assert_equal(_tech_tree_panel.get_focused_node_index(), initial,
		"Selecting node 999 should not change focus")


# ── Test Methods: Module Placement ───────────────────────

func _test_module_select_changes_selection() -> void:
	_module_placement_ui.open(0)
	_module_placement_ui.select_module_by_index(0)
	assert_equal(_module_placement_ui.get_selected_module_index(), 0,
		"Selecting module index 0 should update selection")


func _test_module_select_negative_noop() -> void:
	_module_placement_ui.open(0)
	var initial: int = _module_placement_ui.get_selected_module_index()
	_module_placement_ui.select_module_by_index(-1)
	assert_equal(_module_placement_ui.get_selected_module_index(), initial,
		"Selecting module -1 should not change selection")
