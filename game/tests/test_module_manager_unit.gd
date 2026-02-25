## Unit tests for the ModuleManager system. Verifies module install/remove lifecycle,
## resource cost validation, power capacity checks, signal emissions, and query methods.
## Uses ShipState and PlayerInventory autoloads (reset between tests).
class_name TestModuleManagerUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _manager: ModuleManagerType = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	# Reset autoload state
	ShipState.reset()
	PlayerInventory.clear_all()
	TechTree.reset()

	_manager = ModuleManagerType.new()
	add_child(_manager)
	_spy = SignalSpy.new()
	_spy.watch(_manager, "module_installed")
	_spy.watch(_manager, "module_removed")
	_spy.watch(_manager, "install_failed")


func after_each() -> void:
	_spy.clear()
	_spy = null
	_manager.queue_free()
	_manager = null
	# Clean up autoloads
	ShipState.reset()
	PlayerInventory.clear_all()
	TechTree.reset()


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Initial state
	add_test("initial_installed_count_is_zero", _test_initial_installed_count_is_zero)
	add_test("initial_is_installed_returns_false", _test_initial_is_installed_returns_false)
	# Install success
	add_test("install_recycler_with_resources_succeeds", _test_install_recycler_with_resources_succeeds)
	add_test("install_emits_module_installed", _test_install_emits_module_installed)
	add_test("install_deducts_resources_from_inventory", _test_install_deducts_resources_from_inventory)
	add_test("install_with_mixed_purities_succeeds", _test_install_with_mixed_purities_succeeds)
	add_test("install_consumes_lowest_purity_first", _test_install_consumes_lowest_purity_first)
	add_test("install_registers_power_draw", _test_install_registers_power_draw)
	add_test("installed_module_appears_in_query", _test_installed_module_appears_in_query)
	# Install failure modes
	add_test("install_unknown_module_fails", _test_install_unknown_module_fails)
	add_test("install_already_installed_fails", _test_install_already_installed_fails)
	add_test("install_insufficient_resources_fails", _test_install_insufficient_resources_fails)
	add_test("install_power_overload_fails", _test_install_power_overload_fails)
	add_test("install_failure_emits_install_failed", _test_install_failure_emits_install_failed)
	add_test("install_failure_does_not_deduct_resources", _test_install_failure_does_not_deduct_resources)
	add_test("install_tech_tree_locked_fails", _test_install_tech_tree_locked_fails)
	add_test("install_with_tech_tree_unlocked_succeeds", _test_install_with_tech_tree_unlocked_succeeds)
	# Remove
	add_test("remove_installed_module_succeeds", _test_remove_installed_module_succeeds)
	add_test("remove_emits_module_removed", _test_remove_emits_module_removed)
	add_test("remove_deregisters_power_draw", _test_remove_deregisters_power_draw)
	add_test("remove_not_installed_fails", _test_remove_not_installed_fails)
	add_test("remove_does_not_refund_resources", _test_remove_does_not_refund_resources)
	# Query methods
	add_test("get_installed_module_ids_returns_correct_list", _test_get_installed_module_ids_returns_correct_list)
	add_test("get_module_data_returns_install_data", _test_get_module_data_returns_install_data)
	add_test("get_module_data_not_installed_returns_empty", _test_get_module_data_not_installed_returns_empty)


# ── Helpers ───────────────────────────────────────────────

## Seeds PlayerInventory with enough Scrap Metal to install the recycler (matches ModuleDefs cost).
func _seed_recycler_resources() -> void:
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 2)


# ── Test Methods ──────────────────────────────────────────

# -- Initial state --

func _test_initial_installed_count_is_zero() -> void:
	assert_equal(_manager.get_installed_count(), 0, "No modules should be installed initially")


func _test_initial_is_installed_returns_false() -> void:
	assert_false(_manager.is_installed("recycler"),
		"Recycler should not be installed initially")


# -- Install success --

func _test_install_recycler_with_resources_succeeds() -> void:
	_seed_recycler_resources()
	var result: bool = _manager.install_module("recycler")
	assert_true(result, "Install should succeed with sufficient resources and power")
	assert_true(_manager.is_installed("recycler"), "Recycler should be installed after success")


func _test_install_emits_module_installed() -> void:
	_seed_recycler_resources()
	_manager.install_module("recycler")
	assert_signal_emitted(_spy, "module_installed", "module_installed should emit on success")
	var args: Array = _spy.get_emission_args("module_installed", 0)
	assert_equal(args[0], "recycler", "Signal should report 'recycler' as module_id")


func _test_install_deducts_resources_from_inventory() -> void:
	_seed_recycler_resources()
	_manager.install_module("recycler")
	var remaining: int = PlayerInventory.get_count(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR)
	assert_equal(remaining, 0, "Install should deduct all Scrap Metal from inventory")


func _test_install_with_mixed_purities_succeeds() -> void:
	# 1 @ 1-star + 1 @ 3-star = 2 total (need 2)
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 1)
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 1)
	var result: bool = _manager.install_module("recycler")
	assert_true(result, "Install should succeed with mixed-purity resources totaling 2")
	assert_true(_manager.is_installed("recycler"), "Recycler should be installed")


func _test_install_consumes_lowest_purity_first() -> void:
	# 2 @ 1-star + 2 @ 3-star = 4 total (need 2)
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 2)
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR, 2)
	_manager.install_module("recycler")
	# Should consume all 2 @ 1-star, leaving 3-star untouched
	var one_star: int = PlayerInventory.get_count(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR)
	var three_star: int = PlayerInventory.get_count(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.THREE_STAR)
	assert_equal(one_star, 0, "All 1-star should be consumed first")
	assert_equal(three_star, 2, "3-star should remain untouched")


func _test_install_registers_power_draw() -> void:
	_seed_recycler_resources()
	_manager.install_module("recycler")
	var draw: float = ShipState.get_total_module_draw()
	assert_equal(draw, 10.0, "Recycler install should register 10.0 power draw")


func _test_installed_module_appears_in_query() -> void:
	_seed_recycler_resources()
	_manager.install_module("recycler")
	assert_equal(_manager.get_installed_count(), 1, "Installed count should be 1")
	var ids: Array[String] = _manager.get_installed_module_ids()
	assert_true(ids.has("recycler"), "Installed IDs should include 'recycler'")


# -- Install failure modes --

func _test_install_unknown_module_fails() -> void:
	var result: bool = _manager.install_module("nonexistent_module")
	assert_false(result, "Install of unknown module should fail")
	assert_equal(_manager.get_installed_count(), 0, "No modules should be installed")


func _test_install_already_installed_fails() -> void:
	_seed_recycler_resources()
	_manager.install_module("recycler")
	_spy.clear()
	var result: bool = _manager.install_module("recycler")
	assert_false(result, "Installing already-installed module should fail")
	assert_signal_emitted(_spy, "install_failed", "install_failed should emit")
	var args: Array = _spy.get_emission_args("install_failed", 0)
	assert_equal(args[1], "ALREADY_INSTALLED", "Reason should be ALREADY_INSTALLED")


func _test_install_insufficient_resources_fails() -> void:
	# Add only 1 Scrap Metal — need 2
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR, 1)
	var result: bool = _manager.install_module("recycler")
	assert_false(result, "Install should fail with insufficient resources")
	assert_signal_emitted(_spy, "install_failed", "install_failed should emit")
	var args: Array = _spy.get_emission_args("install_failed", 0)
	assert_equal(args[1], "INSUFFICIENT_RESOURCES", "Reason should be INSUFFICIENT_RESOURCES")


func _test_install_power_overload_fails() -> void:
	_seed_recycler_resources()
	# Saturate power capacity: baseline is 30, register 25 draw
	ShipState.register_module_draw(25.0)
	var result: bool = _manager.install_module("recycler")
	assert_false(result, "Install should fail when power would be overloaded (25+10>30)")
	assert_signal_emitted(_spy, "install_failed", "install_failed should emit")
	var args: Array = _spy.get_emission_args("install_failed", 0)
	assert_equal(args[1], "POWER_OVERLOAD", "Reason should be POWER_OVERLOAD")


func _test_install_failure_emits_install_failed() -> void:
	# No resources — should fail with INSUFFICIENT_RESOURCES
	var result: bool = _manager.install_module("recycler")
	assert_false(result, "Install with no resources should fail")
	assert_signal_emitted(_spy, "install_failed", "install_failed should emit on failure")


func _test_install_failure_does_not_deduct_resources() -> void:
	# Add resources, but block on power
	_seed_recycler_resources()
	ShipState.register_module_draw(25.0)
	_manager.install_module("recycler")
	# Resources should not be deducted since power check fails first
	var remaining: int = PlayerInventory.get_count(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR)
	assert_equal(remaining, 2, "Resources should not be deducted on power failure")


func _test_install_tech_tree_locked_fails() -> void:
	# Fabricator requires "fabricator_module" tech tree node — not unlocked after TechTree.reset()
	PlayerInventory.add_item(ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 2)
	var result: bool = _manager.install_module("fabricator")
	assert_false(result, "Install should fail when tech tree gate is not unlocked")
	assert_signal_emitted(_spy, "install_failed", "install_failed should emit")
	var args: Array = _spy.get_emission_args("install_failed", 0)
	assert_equal(args[1], "TECH_TREE_LOCKED", "Reason should be TECH_TREE_LOCKED")


func _test_install_with_tech_tree_unlocked_succeeds() -> void:
	# Unlock the fabricator_module gate (costs 1 Metal), then install fabricator (costs 2 Metal)
	PlayerInventory.add_item(ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 3)
	TechTree.unlock_node("fabricator_module")
	var result: bool = _manager.install_module("fabricator")
	assert_true(result, "Install should succeed when tech tree gate is unlocked and resources met")
	assert_true(_manager.is_installed("fabricator"), "Fabricator should be installed")


# -- Remove --

func _test_remove_installed_module_succeeds() -> void:
	_seed_recycler_resources()
	_manager.install_module("recycler")
	var result: bool = _manager.remove_module("recycler")
	assert_true(result, "Remove should succeed for installed module")
	assert_false(_manager.is_installed("recycler"), "Module should no longer be installed")


func _test_remove_emits_module_removed() -> void:
	_seed_recycler_resources()
	_manager.install_module("recycler")
	_spy.clear()
	_manager.remove_module("recycler")
	assert_signal_emitted(_spy, "module_removed", "module_removed should emit")
	var args: Array = _spy.get_emission_args("module_removed", 0)
	assert_equal(args[0], "recycler", "Signal should report 'recycler'")


func _test_remove_deregisters_power_draw() -> void:
	_seed_recycler_resources()
	_manager.install_module("recycler")
	_manager.remove_module("recycler")
	assert_equal(ShipState.get_total_module_draw(), 0.0,
		"Power draw should be 0 after removing module")


func _test_remove_not_installed_fails() -> void:
	var result: bool = _manager.remove_module("recycler")
	assert_false(result, "Remove should fail for non-installed module")


func _test_remove_does_not_refund_resources() -> void:
	_seed_recycler_resources()
	_manager.install_module("recycler")
	_manager.remove_module("recycler")
	var remaining: int = PlayerInventory.get_count(
		ResourceDefs.ResourceType.SCRAP_METAL, ResourceDefs.Purity.ONE_STAR)
	assert_equal(remaining, 0, "Remove should not refund resources (M4 design)")


# -- Query methods --

func _test_get_installed_module_ids_returns_correct_list() -> void:
	assert_equal(_manager.get_installed_module_ids().size(), 0,
		"Empty list before any installs")
	_seed_recycler_resources()
	_manager.install_module("recycler")
	var ids: Array[String] = _manager.get_installed_module_ids()
	assert_equal(ids.size(), 1, "Should have 1 ID after install")
	assert_equal(ids[0], "recycler", "First ID should be 'recycler'")


func _test_get_module_data_returns_install_data() -> void:
	_seed_recycler_resources()
	_manager.install_module("recycler")
	var data: Dictionary = _manager.get_module_data("recycler")
	assert_false(data.is_empty(), "Module data should not be empty for installed module")
	assert_true(data.has("power_draw"), "Module data should contain power_draw")
	assert_equal(data.get("power_draw"), 10.0, "power_draw should be 10.0")


func _test_get_module_data_not_installed_returns_empty() -> void:
	var data: Dictionary = _manager.get_module_data("recycler")
	assert_true(data.is_empty(), "Module data should be empty for non-installed module")
