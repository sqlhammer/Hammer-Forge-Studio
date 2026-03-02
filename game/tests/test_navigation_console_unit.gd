## Unit tests for the NavigationConsole modal panel. Verifies open/close
## behavior, destination selection, confirm button state, fuel sufficiency
## gating, and travel initiation on confirm.
##
## Coverage target: 85% (per docs/studio/tdd-process-m8.md)
## Ticket: TICKET-0167
class_name TestNavigationConsoleUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────

var _console: NavigationConsole = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	NavigationSystem.reset()
	FuelSystem.reset_to_full()
	PlayerInventory.clear_all()
	ShipState.reset()
	_console = NavigationConsole.new()
	add_child(_console)
	# Wait one frame for _ready to complete
	await get_tree().process_frame
	_spy = SignalSpy.new()
	_spy.watch(_console, "travel_confirmed")
	_spy.watch(_console, "panel_closed")
	_spy.watch(NavigationSystem, "travel_completed")
	_spy.watch(NavigationSystem, "travel_blocked")


func after_each() -> void:
	if _console and _console.is_open():
		_console.close_panel()
	if _console:
		_console.queue_free()
		_console = null
	NavigationSystem.reset()
	FuelSystem.reset_to_full()
	PlayerInventory.clear_all()
	ShipState.reset()
	if _spy:
		_spy.clear()
	_spy = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Open / close behavior
	add_test("console_starts_closed", _test_console_starts_closed)
	add_test("console_opens_successfully", _test_console_opens_successfully)
	add_test("console_closes_successfully", _test_console_closes_successfully)
	add_test("console_emits_panel_closed_on_close", _test_console_emits_panel_closed_on_close)
	add_test("console_double_open_is_noop", _test_console_double_open_is_noop)
	add_test("console_double_close_is_noop", _test_console_double_close_is_noop)

	# Destination selection
	add_test("console_no_selection_on_open", _test_console_no_selection_on_open)
	add_test("console_confirm_disabled_when_no_selection", _test_console_confirm_disabled_when_no_selection)

	# Fuel sufficiency gating
	add_test("console_confirm_disabled_when_fuel_empty", _test_console_confirm_disabled_when_fuel_empty)
	add_test("console_confirm_enabled_when_fuel_sufficient", _test_console_confirm_enabled_when_fuel_sufficient)

	# Travel initiation
	add_test("console_travel_confirmed_signal_on_confirm", _test_console_travel_confirmed_signal_on_confirm)
	add_test("console_closes_after_confirm", _test_console_closes_after_confirm)
	add_test("console_travel_initiated_on_confirm", _test_console_travel_initiated_on_confirm)

	# Biome node display
	add_test("console_shows_destination_biomes", _test_console_shows_destination_biomes)
	add_test("console_excludes_current_biome_from_destinations", _test_console_excludes_current_biome_from_destinations)


# ── Helpers ───────────────────────────────────────────────

## Drains FuelSystem to zero so any weighted travel attempt will be blocked.
func _drain_fuel_to_zero() -> void:
	FuelSystem.consume_fuel(FuelSystem.fuel_max)


## Simulates selecting a biome in the console by calling internal select method.
func _select_destination(biome_id: String) -> void:
	# Access the internal select method via the public test helper pattern
	_console._select_biome(biome_id)


# ── Test Methods ──────────────────────────────────────────

# -- Open / close --

func _test_console_starts_closed() -> void:
	assert_false(_console.is_open(),
		"NavigationConsole should start in closed state")


func _test_console_opens_successfully() -> void:
	_console.open_panel()
	assert_true(_console.is_open(),
		"NavigationConsole should be open after open_panel()")


func _test_console_closes_successfully() -> void:
	_console.open_panel()
	_console.close_panel()
	assert_false(_console.is_open(),
		"NavigationConsole should be closed after close_panel()")


func _test_console_emits_panel_closed_on_close() -> void:
	_console.open_panel()
	_console.close_panel()
	assert_signal_emitted(_spy, "panel_closed",
		"panel_closed signal should fire on close_panel()")


func _test_console_double_open_is_noop() -> void:
	_console.open_panel()
	_console.open_panel()
	assert_true(_console.is_open(),
		"Double open should not cause errors — panel stays open")


func _test_console_double_close_is_noop() -> void:
	_console.open_panel()
	_console.close_panel()
	_console.close_panel()
	assert_false(_console.is_open(),
		"Double close should not cause errors — panel stays closed")


# -- Destination selection --

func _test_console_no_selection_on_open() -> void:
	_console.open_panel()
	assert_equal(_console._selected_biome_id, "",
		"No biome should be selected when panel first opens")


func _test_console_confirm_disabled_when_no_selection() -> void:
	_console.open_panel()
	assert_true(_console._confirm_button.disabled,
		"Confirm button should be disabled when no destination is selected")


# -- Fuel sufficiency --

func _test_console_confirm_disabled_when_fuel_empty() -> void:
	# Add inventory items so travel cost is non-zero
	PlayerInventory.add_item(
		ResourceDefs.ResourceType.METAL, ResourceDefs.Purity.ONE_STAR, 50)
	_drain_fuel_to_zero()
	_console.open_panel()
	_select_destination("rock_warrens")
	assert_true(_console._confirm_button.disabled,
		"Confirm button should be disabled when fuel is insufficient")


func _test_console_confirm_enabled_when_fuel_sufficient() -> void:
	# Full tank with base ship weight — cost is affordable
	_console.open_panel()
	_select_destination("rock_warrens")
	assert_false(_console._confirm_button.disabled,
		"Confirm button should be enabled when fuel is sufficient")


# -- Travel initiation --

func _test_console_travel_confirmed_signal_on_confirm() -> void:
	_console.open_panel()
	_select_destination("rock_warrens")
	_console._on_confirm_pressed()
	assert_signal_emitted(_spy, "travel_confirmed",
		"travel_confirmed signal should fire when confirm is pressed")


func _test_console_closes_after_confirm() -> void:
	_console.open_panel()
	_select_destination("rock_warrens")
	_console._on_confirm_pressed()
	assert_false(_console.is_open(),
		"Panel should close after confirming travel")


func _test_console_travel_initiated_on_confirm() -> void:
	_console.open_panel()
	_select_destination("rock_warrens")
	_console._on_confirm_pressed()
	assert_signal_emitted(_spy, "travel_completed",
		"NavigationSystem.travel_completed should fire after confirm")
	assert_equal(NavigationSystem.current_biome, "rock_warrens",
		"Current biome should update to rock_warrens after travel")


# -- Biome node display --

func _test_console_shows_destination_biomes() -> void:
	_console.open_panel()
	# Current biome is shattered_flats, so destinations should include rock_warrens and debris_field
	assert_true(_console._biome_node_ids.has("rock_warrens"),
		"Destination nodes should include rock_warrens")
	assert_true(_console._biome_node_ids.has("debris_field"),
		"Destination nodes should include debris_field")


func _test_console_excludes_current_biome_from_destinations() -> void:
	_console.open_panel()
	assert_false(_console._biome_node_ids.has("shattered_flats"),
		"Current biome should not appear in destination nodes")
