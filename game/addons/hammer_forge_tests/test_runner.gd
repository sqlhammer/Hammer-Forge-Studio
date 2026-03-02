## Discovers and executes all TestSuite instances. Can run from the editor
## as a scene or headless via command line. Outputs results to console and
## writes a JSON report file. Returns non-zero exit code on failure for CI.
class_name TestRunner
extends Node

# ── Constants ─────────────────────────────────────────────
const TEST_DIRECTORY: String = "res://tests/"
const REPORT_OUTPUT_PATH: String = "user://test_reports/"

# ── Signals ──────────────────────────────────────────────
signal all_suites_completed(total_passed: int, total_failed: int, total_skipped: int)

# ── Private Variables ─────────────────────────────────────
var _total_passed: int = 0
var _total_failed: int = 0
var _total_skipped: int = 0
var _all_results: Array[TestResult] = []
var _suite_filter: String = ""
var _is_headless: bool = false


# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	_is_headless = DisplayServer.get_name() == "headless"
	_parse_command_line_args()
	await run_all_suites()


# ── Public Methods ────────────────────────────────────────

## Discovers and runs all test suites found in the test directory.
func run_all_suites() -> void:
	_total_passed = 0
	_total_failed = 0
	_total_skipped = 0
	_all_results.clear()

	_print_header()

	var suite_scripts: Array[String] = _discover_suite_scripts()
	for script_path: String in suite_scripts:
		await _run_suite_from_path(script_path)

	_print_summary()
	_write_json_report()
	_bridge_to_agent_logger()

	all_suites_completed.emit(_total_passed, _total_failed, _total_skipped)

	if _is_headless:
		var exit_code: int = 0 if _total_failed == 0 else 1
		get_tree().quit(exit_code)


# ── Private Methods ───────────────────────────────────────

func _parse_command_line_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for arg: String in args:
		if arg.begins_with("--suite="):
			_suite_filter = arg.trim_prefix("--suite=")


func _discover_suite_scripts() -> Array[String]:
	var scripts: Array[String] = []
	var directory: DirAccess = DirAccess.open(TEST_DIRECTORY)
	if directory == null:
		push_error("TestRunner: Could not open test directory '%s'" % TEST_DIRECTORY)
		return scripts
	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while file_name != "":
		if file_name.ends_with(".gd") and file_name.begins_with("test_"):
			if _suite_filter == "" or file_name.contains(_suite_filter):
				var full_path: String = TEST_DIRECTORY + file_name
				scripts.append(full_path)
		file_name = directory.get_next()
	directory.list_dir_end()
	scripts.sort()
	return scripts


func _run_suite_from_path(script_path: String) -> void:
	var script: Script = load(script_path)
	if script == null:
		push_error("TestRunner: Failed to load script '%s'" % script_path)
		return
	var suite_instance: TestSuite = script.new() as TestSuite
	if suite_instance == null:
		push_error("TestRunner: Script '%s' does not extend TestSuite" % script_path)
		return

	# Add to scene tree so Node lifecycle methods and groups work
	add_child(suite_instance)
	var results: Array[TestResult] = await suite_instance.run_all_tests()

	for result: TestResult in results:
		_all_results.append(result)

	var suite_passed: int = suite_instance.get_pass_count()
	var suite_failed: int = suite_instance.get_fail_count()
	var suite_skipped: int = suite_instance.get_skip_count()
	_total_passed += suite_passed
	_total_failed += suite_failed
	_total_skipped += suite_skipped

	# Print suite header with summary, then only FAIL/SKIP details
	_print_suite_header(suite_instance.get_suite_name(), suite_passed, suite_failed, suite_skipped)
	for result: TestResult in results:
		if result.status != TestResult.Status.PASSED:
			_print_test_result(result)

	remove_child(suite_instance)
	suite_instance.queue_free()


func _print_header() -> void:
	Global.debug_log("==============================================")
	Global.debug_log("  Hammer Forge Tests")
	Global.debug_log("==============================================")


func _print_suite_header(suite_name: String, passed: int, failed: int, skipped: int) -> void:
	var total: int = passed + failed + skipped
	Global.debug_log("--- Suite: %s --- %d/%d passed" % [suite_name, passed, total])


func _print_test_result(result: TestResult) -> void:
	match result.status:
		TestResult.Status.PASSED:
			Global.debug_log("  PASS: %s (%.1fms)" % [
				result.test_name, result.execution_time_milliseconds])
		TestResult.Status.FAILED:
			Global.debug_log("  FAIL: %s -- %s" % [result.test_name, result.message])
			if result.stack_info != "":
				Global.debug_log("        at %s" % result.stack_info)
		TestResult.Status.SKIPPED:
			Global.debug_log("  SKIP: %s -- %s" % [result.test_name, result.message])


func _print_summary() -> void:
	var total: int = _total_passed + _total_failed + _total_skipped
	Global.debug_log("==============================================")
	Global.debug_log("  Results: %d passed, %d failed, %d skipped (of %d)" % [
		_total_passed, _total_failed, _total_skipped, total])
	if _total_failed > 0:
		Global.debug_log("  STATUS: FAILED")
	else:
		Global.debug_log("  STATUS: ALL PASSED")
	Global.debug_log("==============================================")


func _write_json_report() -> void:
	var global_report_path: String = ProjectSettings.globalize_path(REPORT_OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(global_report_path)

	var timestamp: String = Time.get_datetime_string_from_system(true, true)
	var safe_timestamp: String = timestamp.replace(":", "-").replace("T", "_")
	var report_path: String = REPORT_OUTPUT_PATH + "test_report_%s.json" % safe_timestamp

	var report: Dictionary = {
		"timestamp": timestamp,
		"total_tests": _total_passed + _total_failed + _total_skipped,
		"passed": _total_passed,
		"failed": _total_failed,
		"skipped": _total_skipped,
		"results": []
	}
	for result: TestResult in _all_results:
		var entry: Dictionary = {
			"suite": result.suite_name,
			"test": result.test_name,
			"status": _status_to_string(result.status),
			"message": result.message,
			"expected": result.expected_value,
			"actual": result.actual_value,
			"time_ms": result.execution_time_milliseconds,
			"stack": result.stack_info
		}
		report["results"].append(entry)

	var json_string: String = JSON.stringify(report, "  ")
	var file: FileAccess = FileAccess.open(report_path, FileAccess.WRITE)
	if file != null:
		file.store_string(json_string)
		file.close()
		Global.debug_log("Report written to: %s" % report_path)
	else:
		push_error("TestRunner: Failed to write report to '%s'" % report_path)


func _bridge_to_agent_logger() -> void:
	var agent_logger: Node = get_node_or_null("/root/AgentLogger")
	if agent_logger == null or not agent_logger.has_method("log_test_result"):
		return
	for result: TestResult in _all_results:
		agent_logger.call("log_test_result",
			result.suite_name,
			result.test_name,
			result.status == TestResult.Status.PASSED,
			result.message)
	# Force flush so test results are written before process exits
	if agent_logger.has_method("flush"):
		agent_logger.call("flush")


func _status_to_string(status: TestResult.Status) -> String:
	match status:
		TestResult.Status.PASSED:
			return "PASSED"
		TestResult.Status.FAILED:
			return "FAILED"
		TestResult.Status.SKIPPED:
			return "SKIPPED"
		TestResult.Status.ERROR:
			return "ERROR"
	return "UNKNOWN"
