# System Architecture

**Owner:** systems-programmer
**Status:** Active
**Last Updated:** 2026-02-22

> Living document of all core engine systems. Updated whenever a new autoload or core system is added. Every public API must be documented here.

---

## Autoload Registry

| Autoload Name | Script Path | Purpose |
|---------------|-------------|---------|
| Global | `res://autoloads/Global.gd` | Shared utility functions and debug logging |
| InputManager | `res://autoloads/InputManager.gd` | Centralized input handling and device management |
| AgentLogger | `res://autoloads/AgentLogger.gd` | Structured JSONL logging for AI agent consumption |

---

## Core Systems

### Global

**Purpose:** Shared utility functions and debug logging accessible from any script.

**Public API:**
```gdscript
func log(message: String) -> void
```
Logs a message if running in a debug build. Use for debug output, performance metrics, and error diagnostics.

**Dependencies:** None

**Notes:** All autoloads should use `Global.log()` instead of `print()` to keep debug output controlled and grouped.

---

### InputManager

**Purpose:** Centralized input handling that normalizes keyboard and gamepad input, manages input devices, and provides a unified query interface for controllers.

**Public API:**
```gdscript
# Query input state
func is_action_pressed(action: String) -> bool
func get_action_strength(action: String) -> float
func get_analog_input(stick: String) -> Vector2  # "left" or "right"; returns [-1, 1]
func get_trigger_input(trigger: String) -> float  # "left" or "right"; returns [0, 1]

# Device information
func get_current_input_device() -> String  # "keyboard" or "gamepad"
func is_gamepad_connected() -> bool
func get_mouse_delta() -> Vector2
```

**Exported Properties:**
- `mouse_sensitivity_x: float` (default 1.0)
- `mouse_sensitivity_y: float` (default 1.0)
- `gamepad_sensitivity_x: float` (default 1.0)
- `gamepad_sensitivity_y: float` (default 1.0)
- `invert_gamepad_look_y: bool` (default false)

**Signals:**
- `input_device_changed(device: String)` — Emitted when the active input device switches (keyboard ↔ gamepad)

**Input Actions (Configured at Runtime):**

| Action | First-Person | Third-Person | Keyboard | Gamepad |
|--------|--------------|--------------|----------|---------|
| move_forward | ✓ | ✓ | W | Left Stick ↑ |
| move_backward | ✓ | ✓ | S | Left Stick ↓ |
| move_left | ✓ | ✓ | A | Left Stick ← |
| move_right | ✓ | ✓ | D | Left Stick → |
| interact | ✓ | — | E | West Button |
| scan | ✓ | — | Q | Left Bumper |
| use_tool | ✓ | — | Left Click | Right Trigger |
| camera_look_horizontal | ✓ | — | Mouse X | Right Stick ← / → |
| camera_look_vertical | ✓ | — | Mouse Y | Right Stick ↑ / ↓ |
| ship_accelerate | — | ✓ | Space | Right Trigger |
| ship_emergency_stop | — | ✓ | X | South Button |
| switch_view | ✓ | ✓ | Tab | Menu / Start |
| pause | ✓ | ✓ | Esc | Select / Back |
| jump | ✓ | — | Space | South Button |

**Dead Zone Configuration:**
- Movement stick: 0.15
- Camera stick: 0.10
- Triggers: 0.05

**Device Auto-Detection:**
InputManager automatically detects and switches between keyboard/mouse and gamepad input based on activity. Switch debounce: 0.1 seconds. No user confirmation required.

**Dependencies:** Global (for logging)

**Design Notes:**
- Controllers query InputManager; they never call `Input` directly
- Both devices remain active; the most recently used device is primary
- Input actions are created dynamically at `_ready()` if they don't exist
- Analog sticks return normalized values with dead zones applied
- Gamepad triggers are normalized from [-1, 1] to [0, 1] for intuitive usage

---

### AgentLogger

**Purpose:** Structured logging system that writes JSONL files for consumption by AI agents. Each log entry contains trace context, module info, agent-actionable advice, and tags. Separate from `Global.log()` — produces machine-readable output while `Global.log()` produces human-readable console output.

**Public API:**
```gdscript
# Log levels
enum LogLevel { DEBUG, INFO, WARNING, ERROR, FATAL, LOGIC_ERROR }

# Core logging
func log_entry(level: LogLevel, module: String, function_name: String,
    message: String, context: Dictionary = {}, agent_advice: String = "",
    tags: Array[String] = []) -> void

# Convenience methods
func log_error(module: String, function_name: String, message: String,
    context: Dictionary = {}, advice: String = "") -> void
func log_warning(module: String, function_name: String, message: String,
    context: Dictionary = {}, advice: String = "") -> void
func log_logic_error(module: String, function_name: String, message: String,
    context: Dictionary = {}, advice: String = "") -> void

# Test framework bridge
func log_test_result(suite_name: String, test_name: String,
    passed: bool, details: String = "") -> void

# Control
func flush() -> void
func get_session_id() -> String
func set_minimum_level(level: LogLevel) -> void
func set_enabled(enabled: bool) -> void
func get_entry_count() -> int
```

**Signals:**
- `log_flushed(entry_count: int)` — Emitted after buffered entries are written to disk

**JSONL Schema (one object per line):**
```json
{
  "trace_id": "uuid-v4",
  "timestamp": "ISO 8601",
  "session_id": "uuid-v4",
  "level": "ERROR",
  "module": "PlayerFirstPerson",
  "function": "apply_gravity",
  "message": "Human-readable description",
  "context": { "key": "value" },
  "agent_advice": "Actionable guidance for AI agents",
  "tags": ["physics", "player"],
  "stack_trace": "res://path/to/script.gd:142"
}
```

**File Output:**
- Path: `user://logs/agent_log_YYYY-MM-DD_HH-MM-SS.jsonl`
- Windows: `%APPDATA%\Godot\app_userdata\core\logs\`
- Buffer: 50 entries or 10 seconds, whichever comes first
- Rotation: Keeps last 10 session files, removes oldest automatically

**Dependencies:** Global (for bootstrap logging only)

**Design Notes:**
- Buffer flushes on `NOTIFICATION_WM_CLOSE_REQUEST` to prevent data loss
- Godot types (Vector2, Vector3, etc.) auto-serialized to strings for JSON safety
- `stack_trace` only populated in debug builds (`get_stack()` returns empty in release)
- Level filtering via `set_minimum_level()` — entries below threshold exit immediately with zero allocation

---

## Hammer Forge Tests (Unit Testing Framework)

**Location:** `res://addons/hammer_forge_tests/`

**Purpose:** Deterministic unit testing framework for GDScript logic. Provides a base class, assertion methods, and a runner that outputs results to console and JSON reports.

**Key Classes:**
- `TestSuite` (extends Node) — Base class for test suites. Self-registers into `"unit_tests"` group.
- `TestRunner` (extends Node) — Discovers and executes suites from `res://tests/`
- `TestResult` (extends Resource) — Data container for individual test results
- `SignalSpy` (extends RefCounted) — Records signal emissions for assertion
- `TestDouble` (extends RefCounted) — Manual stub/mock for method call verification

**Writing Tests:**
```gdscript
class_name TestMyFeature
extends TestSuite

func register_tests() -> void:
    add_test("descriptive_name", _test_descriptive_name)

func _test_descriptive_name() -> void:
    assert_true(some_condition, "Failure message")
```

**Running Tests:**
- Editor: Open `res://addons/hammer_forge_tests/test_runner.tscn`, press F6
- Headless: `godot --headless --path game addons/hammer_forge_tests/test_runner.tscn`
- Filter: `-- --suite=input_manager`

**Output:**
- Console: Pass/fail per test via `Global.log()`
- JSON report: `user://test_reports/test_report_<timestamp>.json`
- AgentLogger bridge: Test results also written to JSONL with tags `["test", "automated"]`

---

## Architecture Principles

- All cross-system communication goes through signals on the `EventBus` autoload
- Data containers use `Resource` subclasses — not raw `Dictionary`
- State machines use the shared `StateMachine` class from `game/scripts/core/state_machine.gd`
- No system calls methods on another system's autoload directly — use signals

---

## Physics Layer Assignments

See `docs/engineering/physics-layers.md`.
