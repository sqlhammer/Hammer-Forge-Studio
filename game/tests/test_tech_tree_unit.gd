## Unit tests for the TechTree autoload. Verifies node unlock lifecycle, prerequisite
## validation, resource cost deduction, reset behavior, and signal emissions.
## Uses TechTree, PlayerInventory, and ShipState autoloads (reset between tests).
class_name TestTechTreeUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	TechTree.reset()
	PlayerInventory.clear_all()
	ShipState.reset()
	if ModuleManager.is_installed("recycler"):
		ModuleManager.remove_module("recycler")
	if ModuleManager.is_installed("fabricator"):
		ModuleManager.remove_module("fabricator")
	if ModuleManager.is_installed("automation_hub"):
		ModuleManager.remove_module("automation_hub")
	_spy = SignalSpy.new()
	_spy.watch(TechTree, "node_unlocked")


func after_each() -> void:
	_spy.clear()
	_spy = null
	TechTree.reset()
	PlayerInventory.clear_all()
	ShipState.reset()


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Catalog integrity
	add_test("catalog_has_fabricator_module", _test_catalog_has_fabricator_module)
	add_test("catalog_has_automation_hub", _test_catalog_has_automation_hub)
	add_test("fabricator_has_no_prerequisites", _test_fabricator_has_no_prerequisites)
	add_test("automation_hub_requires_fabricator", _test_automation_hub_requires_fabricator)
	# Initial state
	add_test("initial_state_no_unlocks", _test_initial_state_no_unlocks)
	add_test("is_unlocked_returns_false_initially", _test_is_unlocked_returns_false_initially)
	add_test("can_unlock_false_without_resources", _test_can_unlock_false_without_resources)
	# Unlock success
	add_test("unlock_fabricator_succeeds_with_resources", _test_unlock_fabricator_succeeds_with_resources)
	add_test("unlock_deducts_resources", _test_unlock_deducts_resources)
	add_test("unlock_emits_node_unlocked", _test_unlock_emits_node_unlocked)
	add_test("is_unlocked_returns_true_after_unlock", _test_is_unlocked_returns_true_after_unlock)
	# Unlock failure modes
	add_test("unlock_fails_unknown_node", _test_unlock_fails_unknown_node)
	add_test("unlock_fails_already_unlocked", _test_unlock_fails_already_unlocked)
	add_test("unlock_fails_insufficient_resources", _test_unlock_fails_insufficient_resources)
	add_test("unlock_fails_missing_prerequisite", _test_unlock_fails_missing_prerequisite)
	# Prerequisite chain
	add_test("automation_hub_unlockable_after_fabricator", _test_automation_hub_unlockable_after_fabricator)
	# can_unlock
	add_test("can_unlock_true_with_resources_and_prereqs", _test_can_unlock_true_with_resources_and_prereqs)
	# get_available_nodes
	add_test("get_available_nodes_returns_fabricator_initially", _test_get_available_nodes_returns_fabricator_initially)
	add_test("get_available_nodes_returns_automation_hub_after_fabricator", _test_get_available_nodes_returns_automation_hub_after_fabricator)
	# Reset
	add_test("reset_clears_all_unlocks", _test_reset_clears_all_unlocks)


# ── Helpers ───────────────────────────────────────────────

func _seed_metal(quantity: int) -> void:
	PlayerInventory.add_item(ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, quantity)


func _unlock_fabricator() -> void:
	_seed_metal(1)
	TechTree.unlock_node("fabricator_module")


# ── Test Methods ──────────────────────────────────────────

# -- Catalog integrity --

func _test_catalog_has_fabricator_module() -> void:
	var entry: Dictionary = TechTreeDefs.get_node_entry("fabricator_module")
	assert_false(entry.is_empty(), "Catalog should contain fabricator_module")
	assert_equal(entry.get("display_name"), "Fabricator", "Display name should be Fabricator")


func _test_catalog_has_automation_hub() -> void:
	var entry: Dictionary = TechTreeDefs.get_node_entry("automation_hub")
	assert_false(entry.is_empty(), "Catalog should contain automation_hub")
	assert_equal(entry.get("display_name"), "Automation Hub", "Display name should be Automation Hub")


func _test_fabricator_has_no_prerequisites() -> void:
	var prereqs: Array[String] = TechTreeDefs.get_prerequisites("fabricator_module")
	assert_equal(prereqs.size(), 0, "Fabricator should have no prerequisites")


func _test_automation_hub_requires_fabricator() -> void:
	var prereqs: Array[String] = TechTreeDefs.get_prerequisites("automation_hub")
	assert_equal(prereqs.size(), 1, "Automation Hub should have 1 prerequisite")
	assert_equal(prereqs[0], "fabricator_module", "Automation Hub prerequisite should be fabricator_module")


# -- Initial state --

func _test_initial_state_no_unlocks() -> void:
	assert_false(TechTree.is_unlocked("fabricator_module"), "fabricator_module should not be unlocked initially")
	assert_false(TechTree.is_unlocked("automation_hub"), "automation_hub should not be unlocked initially")


func _test_is_unlocked_returns_false_initially() -> void:
	assert_false(TechTree.is_unlocked("nonexistent_node"), "Nonexistent node should not be unlocked")


func _test_can_unlock_false_without_resources() -> void:
	assert_false(TechTree.can_unlock("fabricator_module"), "Should not be able to unlock without resources")


# -- Unlock success --

func _test_unlock_fabricator_succeeds_with_resources() -> void:
	_seed_metal(1)
	var result: bool = TechTree.unlock_node("fabricator_module")
	assert_true(result, "Unlock should succeed with sufficient resources")


func _test_unlock_deducts_resources() -> void:
	_seed_metal(3)
	TechTree.unlock_node("fabricator_module")
	var remaining: int = PlayerInventory.get_total_count(ResourceDefs.ResourceType.METAL)
	assert_equal(remaining, 2, "Should deduct 1 Metal, leaving 2")


func _test_unlock_emits_node_unlocked() -> void:
	_seed_metal(1)
	TechTree.unlock_node("fabricator_module")
	assert_signal_emitted(_spy, "node_unlocked", "node_unlocked should be emitted on unlock")
	var args: Array = _spy.get_emission_args("node_unlocked", 0)
	assert_equal(args[0], "fabricator_module", "Signal should carry the node ID")


func _test_is_unlocked_returns_true_after_unlock() -> void:
	_unlock_fabricator()
	assert_true(TechTree.is_unlocked("fabricator_module"), "is_unlocked should return true after unlock")


# -- Unlock failure modes --

func _test_unlock_fails_unknown_node() -> void:
	var result: bool = TechTree.unlock_node("nonexistent_node")
	assert_false(result, "Unlock should fail for unknown node")


func _test_unlock_fails_already_unlocked() -> void:
	_unlock_fabricator()
	_spy.clear()
	_seed_metal(1)
	var result: bool = TechTree.unlock_node("fabricator_module")
	assert_false(result, "Unlock should fail when node is already unlocked")


func _test_unlock_fails_insufficient_resources() -> void:
	# Cost is 1 Metal — seed 0 so player has nothing
	var result: bool = TechTree.unlock_node("fabricator_module")
	assert_false(result, "Unlock should fail with insufficient resources")
	assert_false(TechTree.is_unlocked("fabricator_module"), "Node should remain locked")


func _test_unlock_fails_missing_prerequisite() -> void:
	_seed_metal(2)
	var result: bool = TechTree.unlock_node("automation_hub")
	assert_false(result, "Automation Hub unlock should fail without fabricator_module unlocked")


# -- Prerequisite chain --

func _test_automation_hub_unlockable_after_fabricator() -> void:
	_unlock_fabricator()
	_seed_metal(2)
	var result: bool = TechTree.unlock_node("automation_hub")
	assert_true(result, "Automation Hub should unlock after fabricator_module is unlocked")
	assert_true(TechTree.is_unlocked("automation_hub"), "automation_hub should be unlocked")


# -- can_unlock --

func _test_can_unlock_true_with_resources_and_prereqs() -> void:
	_seed_metal(1)
	assert_true(TechTree.can_unlock("fabricator_module"), "can_unlock should return true with sufficient resources")


# -- get_available_nodes --

func _test_get_available_nodes_returns_fabricator_initially() -> void:
	_seed_metal(1)
	var available: Array[String] = TechTree.get_available_nodes()
	assert_true(available.has("fabricator_module"), "Available nodes should include fabricator_module")
	assert_false(available.has("automation_hub"), "Available nodes should not include automation_hub")


func _test_get_available_nodes_returns_automation_hub_after_fabricator() -> void:
	_unlock_fabricator()
	_seed_metal(2)
	var available: Array[String] = TechTree.get_available_nodes()
	assert_true(available.has("automation_hub"), "Available nodes should include automation_hub after fabricator unlock")
	assert_false(available.has("fabricator_module"), "fabricator_module should not appear (already unlocked)")


# -- Reset --

func _test_reset_clears_all_unlocks() -> void:
	_unlock_fabricator()
	TechTree.reset()
	assert_false(TechTree.is_unlocked("fabricator_module"), "Reset should clear all unlocks")
