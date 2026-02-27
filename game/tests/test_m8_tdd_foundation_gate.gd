## TDD Foundation phase gate regression suite for M8. Validates that the test
## infrastructure scaffolding is correctly established before any M8 feature
## code is written.
##
## Checks:
##   - All M8 system scaffold files exist in res://tests/
##   - M7 baseline file count is maintained (no accidental deletions)
##   - No duplicate class names in test directory
##   - Regression template file exists
##
## This suite runs as part of the standard test runner (test_ prefix).
## Ticket: TICKET-0132
class_name TestM8TddFoundationGate
extends M8PhaseGateRegressionTemplate


# ── Override Points ───────────────────────────────────────

func _get_phase_name() -> String:
	return "TDD Foundation"


func _get_expected_m8_test_count() -> int:
	# TDD Foundation phase: scaffolding only, no feature tests yet
	return 0


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# Inherit base regression checks
	super.register_tests()

	# TDD Foundation-specific checks
	add_test("regression_template_file_exists", _test_regression_template_file_exists)
	add_test("m8_scaffold_count_is_eight", _test_m8_scaffold_count_is_eight)


# ── Test Methods ──────────────────────────────────────────

func _test_regression_template_file_exists() -> void:
	var template_exists: bool = FileAccess.file_exists(
		"res://tests/m8_phase_gate_regression_template.gd")
	assert_true(template_exists,
		"Regression template should exist at res://tests/m8_phase_gate_regression_template.gd")


func _test_m8_scaffold_count_is_eight() -> void:
	assert_equal(_discovered_m8_suites.size(), 8,
		"Should have exactly 8 M8 system scaffold files")
