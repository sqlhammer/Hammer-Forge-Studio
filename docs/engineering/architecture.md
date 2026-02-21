# System Architecture

**Owner:** systems-programmer
**Status:** Active
**Last Updated:** 2026-02-21

> Living document of all core engine systems. Updated whenever a new autoload or core system is added. Every public API must be documented here.

---

## Autoload Registry

| Autoload Name | Script Path | Purpose |
|---------------|-------------|---------|
| Global | `res://autoloads/Global.gd` | Shared utility functions and debug logging |
| InputManager | `res://autoloads/InputManager.gd` | Centralized input handling and device management |

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

## Architecture Principles

- All cross-system communication goes through signals on the `EventBus` autoload
- Data containers use `Resource` subclasses — not raw `Dictionary`
- State machines use the shared `StateMachine` class from `game/scripts/core/state_machine.gd`
- No system calls methods on another system's autoload directly — use signals

---

## Physics Layer Assignments

See `docs/engineering/physics-layers.md`.
