## Data container for a single test execution result.
class_name TestResult
extends Resource

# ── Constants ─────────────────────────────────────────────
enum Status { PASSED, FAILED, SKIPPED, ERROR }

# ── Public Variables ──────────────────────────────────────
var test_name: String = ""
var suite_name: String = ""
var status: Status = Status.PASSED
var message: String = ""
var expected_value: String = ""
var actual_value: String = ""
var execution_time_milliseconds: float = 0.0
var stack_info: String = ""
