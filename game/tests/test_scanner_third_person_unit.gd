## Unit tests for Scanner third-person targeting mode. Verifies that set_view_mode
## switches targeting behavior between raycast (first-person) and proximity (third-person).
## Tests the scanner's view mode state and deposit targeting logic.
class_name TestScannerThirdPersonUnit
extends TestSuite


# ── Private Variables ─────────────────────────────────────
var _scanner: Scanner = null


# ── Setup / Teardown ──────────────────────────────────────

func before_each() -> void:
	_scanner = Scanner.new()
	add_child(_scanner)


func after_each() -> void:
	if is_instance_valid(_scanner):
		_scanner.queue_free()
	_scanner = null


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	# View mode state
	add_test("default_view_mode_is_first_person", _test_default_view_mode_is_first_person)
	add_test("set_view_mode_to_third_person", _test_set_view_mode_to_third_person)
	add_test("set_view_mode_back_to_first_person", _test_set_view_mode_back_to_first_person)
	# Targeting behavior (null camera/player — verifies code path selection)
	add_test("get_aimed_deposit_returns_null_without_camera", _test_get_aimed_deposit_returns_null_without_camera)
	add_test("third_person_targeting_returns_null_without_player", _test_third_person_targeting_returns_null_without_player)
	# Analysis state
	add_test("initial_not_analyzing", _test_initial_not_analyzing)
	add_test("initial_progress_zero", _test_initial_progress_zero)
	add_test("analysis_target_null_initially", _test_analysis_target_null_initially)


# ── Test Methods ──────────────────────────────────────────

# -- View mode state --

func _test_default_view_mode_is_first_person() -> void:
	assert_equal(_scanner._view_mode, "first_person", "Default view mode should be first_person")


func _test_set_view_mode_to_third_person() -> void:
	_scanner.set_view_mode("third_person")
	assert_equal(_scanner._view_mode, "third_person", "View mode should be third_person after set")


func _test_set_view_mode_back_to_first_person() -> void:
	_scanner.set_view_mode("third_person")
	_scanner.set_view_mode("first_person")
	assert_equal(_scanner._view_mode, "first_person", "View mode should be first_person after switch back")


# -- Targeting behavior --

func _test_get_aimed_deposit_returns_null_without_camera() -> void:
	# No camera set up — should return null gracefully
	var deposit: Deposit = _scanner.get_aimed_deposit()
	assert_null(deposit, "Should return null without camera setup")


func _test_third_person_targeting_returns_null_without_player() -> void:
	_scanner.set_view_mode("third_person")
	var deposit: Deposit = _scanner.get_aimed_deposit()
	assert_null(deposit, "Third-person targeting should return null without player")


# -- Analysis state --

func _test_initial_not_analyzing() -> void:
	assert_false(_scanner.is_analyzing(), "Should not be analyzing initially")


func _test_initial_progress_zero() -> void:
	assert_equal(_scanner.get_analysis_progress(), 0.0, "Analysis progress should be 0.0 initially")


func _test_analysis_target_null_initially() -> void:
	assert_null(_scanner.get_analysis_target(), "Analysis target should be null initially")
