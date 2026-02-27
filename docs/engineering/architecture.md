# System Architecture

**Owner:** systems-programmer
**Status:** Active
**Last Updated:** 2026-02-27

> Living document of all core engine systems. Updated whenever a new autoload or core system is added. Every public API must be documented here.

---

## Autoload Registry

| Autoload Name | Script Path | Purpose |
|---------------|-------------|---------|
| Global | `res://autoloads/Global.gd` | Shared utility functions and debug logging |
| InputManager | `res://autoloads/InputManager.gd` | Centralized input handling and device management |
| AgentLogger | `res://autoloads/AgentLogger.gd` | Structured JSONL logging for AI agent consumption |
| PlayerInventory | `res://scripts/systems/inventory.gd` | Player item inventory: add, remove, query, serialize |
| DepositRegistry | `res://scripts/systems/deposit_registry.gd` | World deposit tracking, query, and procedural generation |
| ShipState | `res://scripts/systems/ship_state.gd` | Ship mode state (ground/orbit), module slot management |
| FuelSystem | `res://scripts/systems/fuel_system.gd` | Ship fuel tank, consumption, refuel, and travel feasibility |
| NavigationSystem | `res://scripts/systems/navigation_system.gd` | Biome registry, travel state machine, fuel cost, biome_changed signal |
| ResourceRespawnSystem | `res://scripts/systems/resource_respawn_system.gd` | Per-biome surface deposit respawn tracking on biome transitions |

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

### ResourceRespawnSystem

**Purpose:** Tracks per-biome surface deposit depletion state and manages the respawn cycle on biome transitions. When the player departs a biome, all surface deposits that depleted while the player was there are queued for respawn. When the player returns to a previously-visited biome, queued deposits are restored to full stock (data layer only — physical scene resets are handled by biome scene tickets TICKET-0170–0172). Deep nodes (`infinite: true`) are explicitly excluded from all respawn logic.

**Script:** `res://scripts/systems/resource_respawn_system.gd`

**Signals:**
- `respawn_queued(biome_id: String)` — Emitted when the player departs a biome that has depleted surface deposits. Passes the departed biome's ID.
- `respawn_applied(biome_id: String)` — Emitted when the player returns to a previously-visited biome with pending respawns. Biome scene tickets listen to this to restore physical deposit visibility.

**Public API:**
```gdscript
# Report a surface deposit as depleted (called by deposit/biome scripts)
# Pass infinite=true to identify deep nodes — they are silently excluded.
func report_depleted(deposit_id: String, biome_id: String, infinite: bool = false) -> void

# Query pending respawns for a biome (called by biome scene tickets on load)
func get_pending_respawns(biome_id: String) -> Array

# Check if the player has never departed a biome before
func is_first_visit(biome_id: String) -> bool

# Confirm respawn was applied to the scene (clears the pending queue)
func mark_respawns_applied(biome_id: String) -> void

# Reset all state (new-game init and test teardown)
func reset() -> void
```

**Respawn Cycle:**
1. Player is in Biome A. Surface deposits deplete → call `report_depleted(id, "biome_a")`.
2. Player travels to Biome B → `biome_changed("biome_b")` fires.
3. System moves all active depletions for Biome A into `_pending_respawns["biome_a"]` and emits `respawn_queued("biome_a")`.
4. Player returns to Biome A → `biome_changed("biome_a")` fires.
5. System detects Biome A has been previously departed and has pending respawns → emits `respawn_applied("biome_a")`.
6. Biome A scene loads → calls `get_pending_respawns("biome_a")` to get deposit IDs, restores visibility, then calls `mark_respawns_applied("biome_a")`.

**Dependencies:** NavigationSystem (listens to `biome_changed` signal), Global (debug logging)

**Design Notes:**
- First visit to any biome never triggers respawn (guard: `_departed_biomes` dict).
- `_previous_biome` is tracked internally because `NavigationSystem.current_biome` is already updated when `biome_changed` fires.
- The system only tracks string deposit IDs — it does not hold references to Deposit node objects (those are owned by biome scenes).

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

## Core Utility Classes

### PhysicsLayers

**Location:** `game/scripts/core/physics_layers.gd`

**Purpose:** Centralized, named physics layer bit-mask constants for the entire project. Eliminates duplicated local constant definitions across scripts.

**Public API:**
```gdscript
PhysicsLayers.PLAYER        # int — 1 << 0 (layer 1)
PhysicsLayers.ENEMY         # int — 1 << 1 (layer 2)
PhysicsLayers.ENVIRONMENT   # int — 1 << 2 (layer 3)
PhysicsLayers.INTERACTABLE  # int — 1 << 3 (layer 4)
PhysicsLayers.PROJECTILE    # int — 1 << 4 (layer 5)
```

**Usage:**
```gdscript
collision_layer = PhysicsLayers.ENVIRONMENT
collision_mask = PhysicsLayers.PLAYER | PhysicsLayers.INTERACTABLE
```

**Dependencies:** None — plain class_name script with constants, no Godot base class required.

**Design Notes:**
- Do not use raw integers for collision layers anywhere in the codebase
- Do not add local layer constant copies to individual scripts — always reference `PhysicsLayers`
- Layer values must not be changed without updating `docs/engineering/physics-layers.md` and reviewing all usages

---

## Architecture Principles

- All cross-system communication goes through signals on the `EventBus` autoload
- Data containers use `Resource` subclasses — not raw `Dictionary`
- State machines use the shared `StateMachine` class from `game/scripts/core/state_machine.gd`
- No system calls methods on another system's autoload directly — use signals

---

## Physics Layer Assignments

See `docs/engineering/physics-layers.md`.
