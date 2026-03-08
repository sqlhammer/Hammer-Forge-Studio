## Base class for all unit test suites. Extend this class, override register_tests(),
## and call add_test() to register each test method by name and Callable.
## Provides assertion methods, setup/teardown hooks, and pass/fail tracking.
class_name TestSuite
extends Node

# ── Signals ──────────────────────────────────────────────
signal test_completed(result: TestResult)
signal suite_completed(suite_name: String, results: Array[TestResult])

# ── Private Variables ─────────────────────────────────────
var _registered_tests: Array[Dictionary] = []
var _results: Array[TestResult] = []
var _current_test_result: TestResult = null
var _pass_count: int = 0
var _fail_count: int = 0
var _skip_count: int = 0


# ── Built-in Virtual Methods ──────────────────────────────
func _init() -> void:
	add_to_group("unit_tests")


# ── Public Methods ────────────────────────────────────────

## Override in subclasses to register test methods via add_test().
func register_tests() -> void:
	pass


## Registers a named test with its Callable. Call this from register_tests().
func add_test(test_name: String, test_callable: Callable) -> void:
	_registered_tests.append({
		"name": test_name,
		"callable": test_callable
	})


## Override to perform one-time setup before all tests in the suite run.
func before_all() -> void:
	pass


## Override to perform one-time teardown after all tests in the suite complete.
func after_all() -> void:
	pass


## Override to perform setup before each individual test method.
func before_each() -> void:
	pass


## Override to perform teardown after each individual test method.
func after_each() -> void:
	pass


## Runs all registered test methods. Called by TestRunner.
func run_all_tests() -> Array[TestResult]:
	_results.clear()
	_pass_count = 0
	_fail_count = 0
	_skip_count = 0
	_registered_tests.clear()

	register_tests()
	before_all()

	for test_entry: Dictionary in _registered_tests:
		var test_name: String = test_entry["name"]
		var test_callable: Callable = test_entry["callable"]
		await _run_single_test(test_name, test_callable)

	after_all()
	suite_completed.emit(get_suite_name(), _results)
	return _results


## Returns the suite name derived from the script filename.
func get_suite_name() -> String:
	var script_instance: Script = get_script()
	if script_instance != null:
		var path: String = script_instance.resource_path
		return path.get_file().get_basename()
	return "UnknownSuite"


## Returns the count of passed tests.
func get_pass_count() -> int:
	return _pass_count


## Returns the count of failed tests.
func get_fail_count() -> int:
	return _fail_count


## Returns the count of skipped tests.
func get_skip_count() -> int:
	return _skip_count


# ── Assertion Methods ─────────────────────────────────────

## Asserts that actual equals expected.
func assert_equal(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		var fail_message: String = "Expected '%s' but got '%s'" % [str(expected), str(actual)]
		if message != "":
			fail_message = "%s: %s" % [message, fail_message]
		_record_failure(fail_message, str(expected), str(actual))


## Asserts that the condition is true.
func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		var fail_message: String = "Expected true but got false"
		if message != "":
			fail_message = "%s: %s" % [message, fail_message]
		_record_failure(fail_message, "true", "false")


## Asserts that the condition is false.
func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		var fail_message: String = "Expected false but got true"
		if message != "":
			fail_message = "%s: %s" % [message, fail_message]
		_record_failure(fail_message, "false", "true")


## Asserts that the value is null.
func assert_null(value: Variant, message: String = "") -> void:
	if value != null:
		var fail_message: String = "Expected null but got '%s'" % str(value)
		if message != "":
			fail_message = "%s: %s" % [message, fail_message]
		_record_failure(fail_message, "null", str(value))


## Asserts that the value is not null.
func assert_not_null(value: Variant, message: String = "") -> void:
	if value == null:
		var fail_message: String = "Expected non-null value but got null"
		if message != "":
			fail_message = "%s: %s" % [message, fail_message]
		_record_failure(fail_message, "non-null", "null")


## Asserts that a signal was emitted on the given spy.
func assert_signal_emitted(spy: SignalSpy, signal_name: String, message: String = "") -> void:
	if not spy.was_emitted(signal_name):
		var fail_message: String = "Expected signal '%s' to be emitted" % signal_name
		if message != "":
			fail_message = "%s: %s" % [message, fail_message]
		_record_failure(fail_message, "signal emitted", "signal not emitted")


## Asserts that a value is within an inclusive range.
func assert_in_range(value: float, minimum: float, maximum: float, message: String = "") -> void:
	if value < minimum or value > maximum:
		var fail_message: String = "Expected value in range [%s, %s] but got %s" % [
			str(minimum), str(maximum), str(value)]
		if message != "":
			fail_message = "%s: %s" % [message, fail_message]
		_record_failure(fail_message, "[%s, %s]" % [str(minimum), str(maximum)], str(value))


## Marks the current test as skipped with an optional reason.
func skip_test(reason: String = "") -> void:
	if _current_test_result != null:
		_current_test_result.status = TestResult.Status.SKIPPED
		_current_test_result.message = reason


# ── Private Methods ───────────────────────────────────────

func _run_single_test(test_name: String, test_callable: Callable) -> void:
	_current_test_result = TestResult.new()
	_current_test_result.suite_name = get_suite_name()
	_current_test_result.test_name = test_name

	var start_time: float = Time.get_ticks_msec()
	await before_each()
	await test_callable.call()
	after_each()
	var elapsed: float = Time.get_ticks_msec() - start_time
	_current_test_result.execution_time_milliseconds = elapsed

	match _current_test_result.status:
		TestResult.Status.PASSED:
			_pass_count += 1
		TestResult.Status.FAILED:
			_fail_count += 1
		TestResult.Status.SKIPPED:
			_skip_count += 1

	_results.append(_current_test_result)
	test_completed.emit(_current_test_result)


func _record_failure(message: String, expected: String, actual: String) -> void:
	if _current_test_result == null:
		return
	_current_test_result.status = TestResult.Status.FAILED
	_current_test_result.message = message
	_current_test_result.expected_value = expected
	_current_test_result.actual_value = actual
	# Capture call stack info for debugging (only available in debug builds)
	var stack: Array[Dictionary] = get_stack()
	if stack.size() > 2:
		var caller: Dictionary = stack[2]
		_current_test_result.stack_info = "%s:%s" % [
			caller.get("source", ""), caller.get("line", "")]
