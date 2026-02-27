## Unit tests for the Deep Resource Node system. Verifies infinite-yield flag behavior,
## slow drill rate mechanics, data layer integrity, and integration with the existing
## deposit and mining systems.
##
## Coverage target: 75% (per docs/studio/tdd-process-m8.md — biome travel mechanics)
## Ticket: TICKET-0160
class_name TestDeepResourceNodeUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _deposit: Deposit = null
var _program: DroneProgram = null
var _spy: SignalSpy = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_deposit = Deposit.new()
	_deposit.resource_type = ResourceDefs.ResourceType.SCRAP_METAL
	_deposit.purity = ResourceDefs.Purity.THREE_STAR
	_deposit.density_tier = ResourceDefs.DensityTier.MEDIUM
	_deposit.deposit_tier = ResourceDefs.DepositTier.TIER_1
	_deposit.total_quantity = 40
	_deposit.infinite = true
	_deposit.yield_rate = 0.1
	_deposit.drone_accessible = true
	add_child(_deposit)

	_program = DroneProgram.new()
	_program.target_resource_type = ResourceDefs.ResourceType.SCRAP_METAL
	_program.minimum_purity = ResourceDefs.Purity.ONE_STAR
	_program.tool_tier_assignment = ResourceDefs.DepositTier.TIER_1
	_program.extraction_radius = 100.0
	_program.priority_order = 0

	_spy = SignalSpy.new()
	_spy.watch(_deposit, "depleted")
	_spy.watch(_deposit, "quantity_changed")


func after_each() -> void:
	_spy.clear()
	_spy = null
	if is_instance_valid(_deposit):
		_deposit.queue_free()
	_deposit = null
	_program = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Data layer (initial state, flags)
	add_test("deep_node_has_infinite_true", _test_deep_node_has_infinite_true)
	add_test("deep_node_has_yield_rate_below_surface_baseline", _test_deep_node_has_yield_rate_below_surface_baseline)
	add_test("surface_node_default_yield_rate_is_one", _test_surface_node_default_yield_rate_is_one)
	add_test("deep_node_has_drone_accessible_true", _test_deep_node_has_drone_accessible_true)

	# Infinite-yield behavior (never depletes, consistent output)
	add_test("infinite_flag_prevents_depletion", _test_infinite_flag_prevents_depletion)
	add_test("infinite_extract_does_not_reduce_stock", _test_infinite_extract_does_not_reduce_stock)
	add_test("infinite_extract_returns_full_requested_quantity", _test_infinite_extract_returns_full_requested_quantity)
	add_test("infinite_extract_returns_correct_resource_type", _test_infinite_extract_returns_correct_resource_type)
	add_test("infinite_never_emits_depleted_signal", _test_infinite_never_emits_depleted_signal)
	add_test("infinite_does_not_emit_quantity_changed", _test_infinite_does_not_emit_quantity_changed)
	add_test("infinite_remains_not_depleted_after_many_extractions", _test_infinite_remains_not_depleted_after_many_extractions)
	add_test("infinite_extract_zero_returns_empty", _test_infinite_extract_zero_returns_empty)
	add_test("infinite_extract_negative_returns_empty", _test_infinite_extract_negative_returns_empty)

	# Serialization round-trip
	add_test("serialize_includes_infinite_flag", _test_serialize_includes_infinite_flag)
	add_test("serialize_includes_yield_rate", _test_serialize_includes_yield_rate)
	add_test("serialize_includes_drone_accessible", _test_serialize_includes_drone_accessible)
	add_test("deserialize_restores_infinite_flag", _test_deserialize_restores_infinite_flag)
	add_test("deserialize_restores_yield_rate", _test_deserialize_restores_yield_rate)
	add_test("deserialize_restores_drone_accessible", _test_deserialize_restores_drone_accessible)
	add_test("deserialize_defaults_infinite_to_false", _test_deserialize_defaults_infinite_to_false)
	add_test("deserialize_defaults_yield_rate_to_one", _test_deserialize_defaults_yield_rate_to_one)
	add_test("deserialize_defaults_drone_accessible_to_true", _test_deserialize_defaults_drone_accessible_to_true)

	# Drone integration (drone accessibility flag, program acceptance)
	add_test("drone_program_accepts_analyzed_deep_node", _test_drone_program_accepts_analyzed_deep_node)
	add_test("drone_program_rejects_non_drone_accessible_deposit", _test_drone_program_rejects_non_drone_accessible_deposit)
	add_test("drone_accessible_default_true_on_new_deposit", _test_drone_accessible_default_true_on_new_deposit)

	# Respawn skip — infinite nodes must remain distinguishable for TICKET-0161
	add_test("infinite_flag_readable_for_respawn_skip", _test_infinite_flag_readable_for_respawn_skip)
	add_test("surface_node_infinite_false_by_default", _test_surface_node_infinite_false_by_default)


# ── Test Methods ──────────────────────────────────────────

# -- Data layer --

func _test_deep_node_has_infinite_true() -> void:
	assert_true(_deposit.infinite,
		"Deep resource node must have infinite = true")


func _test_deep_node_has_yield_rate_below_surface_baseline() -> void:
	assert_true(_deposit.yield_rate < 1.0,
		"Deep node yield_rate must be less than surface baseline (1.0); got %f" % _deposit.yield_rate)


func _test_surface_node_default_yield_rate_is_one() -> void:
	var surface: Deposit = Deposit.new()
	add_child(surface)
	assert_equal(surface.yield_rate, 1.0,
		"Surface deposit default yield_rate should be 1.0")
	surface.queue_free()


func _test_deep_node_has_drone_accessible_true() -> void:
	assert_true(_deposit.drone_accessible,
		"Deep resource node must have drone_accessible = true")


# -- Infinite-yield behavior --

func _test_infinite_flag_prevents_depletion() -> void:
	_deposit.extract(1000)
	assert_false(_deposit.is_depleted(),
		"Infinite deposit must not be depleted after extraction")


func _test_infinite_extract_does_not_reduce_stock() -> void:
	var before: int = _deposit.get_remaining()
	_deposit.extract(10)
	assert_equal(_deposit.get_remaining(), before,
		"Infinite deposit stock must not decrease on extract")


func _test_infinite_extract_returns_full_requested_quantity() -> void:
	var result: Dictionary = _deposit.extract(25)
	assert_equal(result.get("quantity", 0) as int, 25,
		"Infinite deposit extract must return the full requested quantity")


func _test_infinite_extract_returns_correct_resource_type() -> void:
	var result: Dictionary = _deposit.extract(1)
	assert_equal(result.get("resource_type"), ResourceDefs.ResourceType.SCRAP_METAL,
		"Infinite extract must return the correct resource_type")
	assert_equal(result.get("purity"), ResourceDefs.Purity.THREE_STAR,
		"Infinite extract must return the correct purity")


func _test_infinite_never_emits_depleted_signal() -> void:
	_deposit.extract(9999)
	assert_false(_spy.was_emitted("depleted"),
		"Infinite deposit must never emit the depleted signal")


func _test_infinite_does_not_emit_quantity_changed() -> void:
	_deposit.extract(10)
	assert_false(_spy.was_emitted("quantity_changed"),
		"Infinite deposit must not emit quantity_changed (stock is unchanged)")


func _test_infinite_remains_not_depleted_after_many_extractions() -> void:
	for i: int in range(100):
		_deposit.extract(10)
	assert_false(_deposit.is_depleted(),
		"Infinite deposit must never deplete after repeated extractions")


func _test_infinite_extract_zero_returns_empty() -> void:
	var result: Dictionary = _deposit.extract(0)
	assert_true(result.is_empty(),
		"Extracting 0 from infinite deposit must return empty dict")


func _test_infinite_extract_negative_returns_empty() -> void:
	var result: Dictionary = _deposit.extract(-5)
	assert_true(result.is_empty(),
		"Extracting negative amount from infinite deposit must return empty dict")


# -- Serialization round-trip --

func _test_serialize_includes_infinite_flag() -> void:
	var data: Dictionary = _deposit.serialize()
	assert_true(data.has("infinite"),
		"Serialized deposit must include 'infinite' key")
	assert_true(data.get("infinite") as bool,
		"Serialized 'infinite' must be true for deep node")


func _test_serialize_includes_yield_rate() -> void:
	var data: Dictionary = _deposit.serialize()
	assert_true(data.has("yield_rate"),
		"Serialized deposit must include 'yield_rate' key")
	assert_equal(data.get("yield_rate") as float, 0.1,
		"Serialized yield_rate must match set value")


func _test_serialize_includes_drone_accessible() -> void:
	var data: Dictionary = _deposit.serialize()
	assert_true(data.has("drone_accessible"),
		"Serialized deposit must include 'drone_accessible' key")
	assert_true(data.get("drone_accessible") as bool,
		"Serialized drone_accessible must be true")


func _test_deserialize_restores_infinite_flag() -> void:
	var data: Dictionary = _deposit.serialize()
	var restored: Deposit = Deposit.new()
	add_child(restored)
	restored.deserialize(data)
	assert_true(restored.infinite,
		"Deserialized deposit must restore infinite = true")
	restored.queue_free()


func _test_deserialize_restores_yield_rate() -> void:
	var data: Dictionary = _deposit.serialize()
	var restored: Deposit = Deposit.new()
	add_child(restored)
	restored.deserialize(data)
	assert_equal(restored.yield_rate, 0.1,
		"Deserialized deposit must restore yield_rate = 0.1")
	restored.queue_free()


func _test_deserialize_restores_drone_accessible() -> void:
	_deposit.drone_accessible = false
	var data: Dictionary = _deposit.serialize()
	var restored: Deposit = Deposit.new()
	add_child(restored)
	restored.deserialize(data)
	assert_false(restored.drone_accessible,
		"Deserialized deposit must restore drone_accessible = false")
	restored.queue_free()


func _test_deserialize_defaults_infinite_to_false() -> void:
	var data: Dictionary = {"resource_type": ResourceDefs.ResourceType.SCRAP_METAL}
	var d: Deposit = Deposit.new()
	add_child(d)
	d.deserialize(data)
	assert_false(d.infinite,
		"Missing 'infinite' key in data must default to false")
	d.queue_free()


func _test_deserialize_defaults_yield_rate_to_one() -> void:
	var data: Dictionary = {"resource_type": ResourceDefs.ResourceType.SCRAP_METAL}
	var d: Deposit = Deposit.new()
	add_child(d)
	d.deserialize(data)
	assert_equal(d.yield_rate, 1.0,
		"Missing 'yield_rate' key in data must default to 1.0")
	d.queue_free()


func _test_deserialize_defaults_drone_accessible_to_true() -> void:
	var data: Dictionary = {"resource_type": ResourceDefs.ResourceType.SCRAP_METAL}
	var d: Deposit = Deposit.new()
	add_child(d)
	d.deserialize(data)
	assert_true(d.drone_accessible,
		"Missing 'drone_accessible' key in data must default to true")
	d.queue_free()


# -- Drone integration --

func _test_drone_program_accepts_analyzed_deep_node() -> void:
	_deposit.ping()
	_deposit.mark_analyzed()
	assert_true(_program.accepts_deposit(_deposit),
		"DroneProgram must accept an analyzed deep node with drone_accessible = true")


func _test_drone_program_rejects_non_drone_accessible_deposit() -> void:
	var d: Deposit = Deposit.new()
	d.setup(ResourceDefs.ResourceType.SCRAP_METAL,
		ResourceDefs.Purity.THREE_STAR, ResourceDefs.DensityTier.MEDIUM, 40)
	d.drone_accessible = false
	add_child(d)
	d.ping()
	d.mark_analyzed()
	assert_false(_program.accepts_deposit(d),
		"DroneProgram must reject a deposit with drone_accessible = false")
	d.queue_free()


func _test_drone_accessible_default_true_on_new_deposit() -> void:
	var d: Deposit = Deposit.new()
	add_child(d)
	assert_true(d.drone_accessible,
		"New deposits must default to drone_accessible = true")
	d.queue_free()


# -- Respawn skip --

func _test_infinite_flag_readable_for_respawn_skip() -> void:
	# TICKET-0161 respawn logic must be able to read deposit.infinite to skip infinite nodes.
	assert_true(_deposit.infinite,
		"deposit.infinite must be readable (used by TICKET-0161 respawn skip logic)")


func _test_surface_node_infinite_false_by_default() -> void:
	var surface: Deposit = Deposit.new()
	add_child(surface)
	assert_false(surface.infinite,
		"Surface deposits must have infinite = false so respawn logic includes them")
	surface.queue_free()
