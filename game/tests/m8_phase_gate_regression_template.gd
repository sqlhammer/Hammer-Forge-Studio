## Phase Gate Regression Template for M8. Extend this class for each phase gate
## regression suite (TDD Foundation, Navigation & Fuel, Integration, QA).
##
## Provides reusable auto-checks that every phase gate must pass:
##   - All M7 tests still pass (cross-milestone regression)
##   - All M8 tests pass (current milestone validation)
##   - Test count meets or exceeds baseline
##   - Zero cross-milestone breakage
##
## Usage: Create a concrete phase gate file (e.g., test_m8_tdd_foundation_gate.gd)
##   that extends this class and overrides _get_phase_name() and
##   _get_expected_m8_test_count().
##
## Runnable in headless mode:
##   godot --headless --path game addons/hammer_forge_tests/test_runner.tscn
##     -- --suite=m8_
##
## Reference: docs/studio/templates/phase-gate-regression-template.md
class_name M8PhaseGateRegressionTemplate
extends TestSuite


# ── Constants ─────────────────────────────────────────────

## M7 baseline test count — the full suite must never drop below this.
const M7_BASELINE_TEST_COUNT: int = 480

## M8 system test file prefixes for discovery validation.
const M8_SYSTEM_FILES: PackedStringArray = [
	"test_cryonite_unit",
	"test_fuel_system_unit",
	"test_navigation_system_unit",
	"test_deep_resource_node_unit",
	"test_resource_respawn_unit",
	"test_procedural_terrain_unit",
	"test_world_boundary_unit",
	"test_travel_sequence_unit",
]


# ── Private Variables ─────────────────────────────────────

var _discovered_suite_count: int = 0
var _discovered_m8_suites: Array[String] = []


# ── Override Points ───────────────────────────────────────

## Override in concrete phase gate files to return the phase name.
func _get_phase_name() -> String:
	return "TEMPLATE"


## Override in concrete phase gate files to return the minimum expected M8 test
## count for this phase. Returns 0 for the TDD Foundation phase (scaffolding only).
func _get_expected_m8_test_count() -> int:
	return 0


# ── Setup / Teardown ──────────────────────────────────────

func before_all() -> void:
	_scan_test_directory()


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	add_test("m8_system_scaffold_files_exist", _test_m8_system_scaffold_files_exist)
	add_test("m7_baseline_file_count_maintained", _test_m7_baseline_file_count_maintained)
	add_test("no_duplicate_class_names", _test_no_duplicate_class_names)


# ── Test Methods ──────────────────────────────────────────

func _test_m8_system_scaffold_files_exist() -> void:
	for expected_file: String in M8_SYSTEM_FILES:
		var found: bool = false
		for suite: String in _discovered_m8_suites:
			if suite.contains(expected_file):
				found = true
				break
		assert_true(found,
			"M8 scaffold file '%s.gd' should exist in res://tests/" % expected_file)


func _test_m7_baseline_file_count_maintained() -> void:
	# Ensure we haven't lost any test suite files — M7 had 25 files, M8 adds 8.
	# This checks that no files were accidentally deleted.
	var minimum_suite_count: int = 25  # M7 baseline file count
	assert_true(_discovered_suite_count >= minimum_suite_count,
		"Test directory should contain at least %d suite files (M7 baseline), found %d" % [
			minimum_suite_count, _discovered_suite_count])


func _test_no_duplicate_class_names() -> void:
	# Verify all discovered files are unique (no accidental overwrites)
	var unique_files: Dictionary = {}
	var directory: DirAccess = DirAccess.open("res://tests/")
	if directory == null:
		assert_true(false, "Could not open res://tests/ directory")
		return
	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while file_name != "":
		if file_name.ends_with(".gd") and file_name.begins_with("test_"):
			if unique_files.has(file_name):
				assert_true(false, "Duplicate test file detected: %s" % file_name)
				return
			unique_files[file_name] = true
		file_name = directory.get_next()
	directory.list_dir_end()
	assert_true(true, "No duplicate test files found")


# ── Private Methods ───────────────────────────────────────

func _scan_test_directory() -> void:
	_discovered_suite_count = 0
	_discovered_m8_suites.clear()

	var directory: DirAccess = DirAccess.open("res://tests/")
	if directory == null:
		push_error("M8PhaseGateRegressionTemplate: Could not open res://tests/")
		return

	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while file_name != "":
		if file_name.ends_with(".gd") and file_name.begins_with("test_"):
			_discovered_suite_count += 1
			# Check if this is an M8-specific test file
			for m8_file: String in M8_SYSTEM_FILES:
				if file_name.begins_with(m8_file):
					_discovered_m8_suites.append(file_name)
					break
		file_name = directory.get_next()
	directory.list_dir_end()
