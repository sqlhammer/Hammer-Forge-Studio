## Unit tests for the DepositRegistry. Verifies registration, unregistration,
## query methods, spatial lookups, and M3 procedural generation.
class_name TestDepositRegistryUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _registry: DepositRegistry = null
var _spy: SignalSpy = null
var _deposits: Array[Deposit] = []


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_registry = DepositRegistry.new()
	add_child(_registry)
	_spy = SignalSpy.new()
	_spy.watch(_registry, "deposit_registered")
	_spy.watch(_registry, "deposit_depleted")
	_deposits.clear()


func after_each() -> void:
	_spy.clear()
	_spy = null
	for deposit: Deposit in _deposits:
		if is_instance_valid(deposit):
			deposit.queue_free()
	_deposits.clear()
	_registry.queue_free()
	_registry = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	add_test("register_deposit_adds_to_registry", _test_register_deposit_adds_to_registry)
	add_test("register_emits_deposit_registered", _test_register_emits_deposit_registered)
	add_test("register_same_deposit_twice_no_duplicate", _test_register_same_deposit_twice_no_duplicate)
	add_test("unregister_removes_deposit", _test_unregister_removes_deposit)
	add_test("get_all_returns_all_registered", _test_get_all_returns_all_registered)
	add_test("get_active_filters_depleted", _test_get_active_filters_depleted)
	add_test("get_depleted_returns_only_depleted", _test_get_depleted_returns_only_depleted)
	add_test("deposit_depleted_signal_forwarded", _test_deposit_depleted_signal_forwarded)
	add_test("get_nearest_active_finds_closest", _test_get_nearest_active_finds_closest)
	add_test("get_nearest_active_skips_depleted", _test_get_nearest_active_skips_depleted)
	add_test("get_nearest_active_empty_returns_null", _test_get_nearest_active_empty_returns_null)
	add_test("get_in_range_finds_within_radius", _test_get_in_range_finds_within_radius)
	add_test("get_in_range_excludes_outside_radius", _test_get_in_range_excludes_outside_radius)
	add_test("generate_m3_deposits_creates_valid_count", _test_generate_m3_deposits_creates_valid_count)
	add_test("generate_m3_deposits_all_scrap_metal", _test_generate_m3_deposits_all_scrap_metal)
	add_test("generate_m3_deposits_auto_registers", _test_generate_m3_deposits_auto_registers)
	add_test("m3_deposit_count_constants_valid", _test_m3_deposit_count_constants_valid)


# ── Helper Methods ────────────────────────────────────────

func _make_deposit(pos: Vector3, quantity: int = 40) -> Deposit:
	var deposit: Deposit = Deposit.new()
	add_child(deposit)
	deposit.setup(
		ResourceDefs.ResourceType.SCRAP_METAL,
		ResourceDefs.Purity.THREE_STAR,
		ResourceDefs.DensityTier.MEDIUM,
		quantity)
	deposit.global_position = pos
	_deposits.append(deposit)
	return deposit


# ── Test Methods ──────────────────────────────────────────

func _test_register_deposit_adds_to_registry() -> void:
	var deposit: Deposit = _make_deposit(Vector3.ZERO)
	_registry.register(deposit)
	assert_equal(_registry.get_all().size(), 1, "Registry should have 1 deposit")


func _test_register_emits_deposit_registered() -> void:
	var deposit: Deposit = _make_deposit(Vector3.ZERO)
	_registry.register(deposit)
	assert_signal_emitted(_spy, "deposit_registered",
		"deposit_registered signal should be emitted")


func _test_register_same_deposit_twice_no_duplicate() -> void:
	var deposit: Deposit = _make_deposit(Vector3.ZERO)
	_registry.register(deposit)
	_registry.register(deposit)
	assert_equal(_registry.get_all().size(), 1,
		"Duplicate registration should not increase count")


func _test_unregister_removes_deposit() -> void:
	var deposit: Deposit = _make_deposit(Vector3.ZERO)
	_registry.register(deposit)
	_registry.unregister(deposit)
	assert_equal(_registry.get_all().size(), 0,
		"Registry should be empty after unregister")


func _test_get_all_returns_all_registered() -> void:
	var dep_a: Deposit = _make_deposit(Vector3(10, 0, 0))
	var dep_b: Deposit = _make_deposit(Vector3(20, 0, 0))
	var dep_c: Deposit = _make_deposit(Vector3(30, 0, 0))
	_registry.register(dep_a)
	_registry.register(dep_b)
	_registry.register(dep_c)
	assert_equal(_registry.get_all().size(), 3,
		"get_all should return all 3 deposits")


func _test_get_active_filters_depleted() -> void:
	var active: Deposit = _make_deposit(Vector3.ZERO, 40)
	var empty: Deposit = _make_deposit(Vector3(10, 0, 0), 5)
	_registry.register(active)
	_registry.register(empty)
	empty.extract(5)
	assert_equal(_registry.get_active().size(), 1,
		"get_active should exclude depleted deposits")


func _test_get_depleted_returns_only_depleted() -> void:
	var active: Deposit = _make_deposit(Vector3.ZERO, 40)
	var empty: Deposit = _make_deposit(Vector3(10, 0, 0), 5)
	_registry.register(active)
	_registry.register(empty)
	empty.extract(5)
	assert_equal(_registry.get_depleted().size(), 1,
		"get_depleted should return only depleted deposits")


func _test_deposit_depleted_signal_forwarded() -> void:
	var deposit: Deposit = _make_deposit(Vector3.ZERO, 10)
	_registry.register(deposit)
	deposit.extract(10)
	assert_signal_emitted(_spy, "deposit_depleted",
		"deposit_depleted should be forwarded from deposit")


func _test_get_nearest_active_finds_closest() -> void:
	var far: Deposit = _make_deposit(Vector3(100, 0, 0))
	var near: Deposit = _make_deposit(Vector3(10, 0, 0))
	_registry.register(far)
	_registry.register(near)
	var nearest: Deposit = _registry.get_nearest_active(Vector3.ZERO)
	assert_equal(nearest, near, "Should return the nearest deposit")


func _test_get_nearest_active_skips_depleted() -> void:
	var near_depleted: Deposit = _make_deposit(Vector3(5, 0, 0), 1)
	var far_active: Deposit = _make_deposit(Vector3(50, 0, 0), 40)
	_registry.register(near_depleted)
	_registry.register(far_active)
	near_depleted.extract(1)
	var nearest: Deposit = _registry.get_nearest_active(Vector3.ZERO)
	assert_equal(nearest, far_active,
		"Should skip depleted and return next closest active")


func _test_get_nearest_active_empty_returns_null() -> void:
	var nearest: Deposit = _registry.get_nearest_active(Vector3.ZERO)
	assert_null(nearest, "Empty registry should return null")


func _test_get_in_range_finds_within_radius() -> void:
	var inside: Deposit = _make_deposit(Vector3(5, 0, 0))
	var outside: Deposit = _make_deposit(Vector3(50, 0, 0))
	_registry.register(inside)
	_registry.register(outside)
	var result: Array[Deposit] = _registry.get_in_range(Vector3.ZERO, 10.0)
	assert_equal(result.size(), 1, "Only deposit within radius should be returned")
	assert_equal(result[0], inside, "Should return the deposit inside range")


func _test_get_in_range_excludes_outside_radius() -> void:
	var deposit: Deposit = _make_deposit(Vector3(100, 0, 0))
	_registry.register(deposit)
	var result: Array[Deposit] = _registry.get_in_range(Vector3.ZERO, 10.0)
	assert_equal(result.size(), 0, "No deposits should be in range")


func _test_generate_m3_deposits_creates_valid_count() -> void:
	var generated: Array[Deposit] = _registry.generate_m3_deposits(Vector3.ZERO, 100.0)
	for deposit: Deposit in generated:
		add_child(deposit)
		_deposits.append(deposit)
	var count: int = generated.size()
	assert_true(count >= DepositRegistry.M3_DEPOSIT_COUNT_MIN,
		"Should generate at least %d deposits" % DepositRegistry.M3_DEPOSIT_COUNT_MIN)
	assert_true(count <= DepositRegistry.M3_DEPOSIT_COUNT_MAX,
		"Should generate at most %d deposits" % DepositRegistry.M3_DEPOSIT_COUNT_MAX)


func _test_generate_m3_deposits_all_scrap_metal() -> void:
	var generated: Array[Deposit] = _registry.generate_m3_deposits(Vector3.ZERO, 100.0)
	for deposit: Deposit in generated:
		add_child(deposit)
		_deposits.append(deposit)
		assert_equal(deposit.resource_type, ResourceDefs.ResourceType.SCRAP_METAL,
			"All M3 deposits should be SCRAP_METAL")


func _test_generate_m3_deposits_auto_registers() -> void:
	var generated: Array[Deposit] = _registry.generate_m3_deposits(Vector3.ZERO, 100.0)
	for deposit: Deposit in generated:
		add_child(deposit)
		_deposits.append(deposit)
	assert_equal(_registry.get_all().size(), generated.size(),
		"All generated deposits should be auto-registered")


func _test_m3_deposit_count_constants_valid() -> void:
	assert_equal(DepositRegistry.M3_DEPOSIT_COUNT_MIN, 8,
		"M3 min deposit count should be 8")
	assert_equal(DepositRegistry.M3_DEPOSIT_COUNT_MAX, 12,
		"M3 max deposit count should be 12")
