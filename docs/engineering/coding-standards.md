# GDScript Coding Standards

**Owner:** systems-programmer
**Status:** Active
**Last Updated:** 2026-02-21
**Sources:** Hammer Forge Studio standards + [Godot GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)

> All GDScript produced by any agent must follow these standards. Systems Programmer enforces via code review. The official Godot style guide applies as a baseline; the rules below take precedence wherever they differ.

---

## File and Node Naming

- **Script files:** `snake_case.gd` (e.g., `player_controller.gd`)
- **Class names:** `PascalCase` using `class_name` — always use `class_name` unless it hides or shadows another class, never `extends "res://..."` string paths
- **Node names in scene:** `PascalCase` — always descriptive (e.g., `SaveButton`, `PlayerSprite`) — generic names like `Button1` or `Node2D` are never acceptable
- **Scene files:** `snake_case.tscn` matching the root node's class name
- **Abbreviations:** avoid in favor of fully qualified words (e.g., `PlayerController` not `PlyrCtrl`, `HealthComponent` not `HpComp`)

---

## Variable Naming

- **Variables and functions:** `snake_case`
- **Constants:** `SCREAMING_SNAKE_CASE`
- **Signals:** `past_tense_snake_case` (e.g., `player_jumped`, `enemy_died`)
- **Private members:** prefix with `_` (e.g., `_current_state`)
- **Strong typing required:** all variables must declare their type — `var speed: float = 5.0`, never `var speed = 5.0`
- **All method/function signatures must use typed parameters**
- **Void functions must be explicitly labeled** `-> void`

---

## Script Structure Order

Every script must follow this section order:

```gdscript
## Plain-language comment describing the purpose of this class.
class_name ClassName
extends ParentClass

# ── Signals ──────────────────────────────────────────────
signal example_signal

# ── Constants ─────────────────────────────────────────────
const MAX_SPEED: float = 10.0

# ── Exported Variables ────────────────────────────────────
@export var speed: float = 5.0

# ── Private Variables ─────────────────────────────────────
var _current_state: String = ""

# ── Onready Variables ─────────────────────────────────────
@onready var _sprite: Sprite2D = $Sprite2D

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
    pass

func _process(delta: float) -> void:
    pass

# ── Public Methods ────────────────────────────────────────
## Plain-language comment describing what this method does.
func do_thing() -> void:
    pass

# ── Private Methods ───────────────────────────────────────
func _helper() -> void:
    pass
```

---

## Documentation and Comments

- Every script must begin with a `##` docstring comment (above `class_name`) describing the purpose of the class in plain language
- Every public method must have a `##` docstring comment immediately above it
- Every complex or non-obvious logic block must have an inline `#` comment explaining **why**, not what
- All classes, scripts, and methods are decorated with plain-language comments — code should be readable without mental translation

---

## Project Structure

### Required Autoloads

| Autoload Name | Purpose |
|---------------|---------|
| `SceneHandler` | Every project must have a `SceneHandler` autoload accessible to all scenes; responsible for scene loading and transitions |
| `Global` | Generic helper functions and global variables shared across the project |

- The starting node of every project is named **`Game`** and uses the generic `Node` type
- On `_ready()`, the `Game` script calls a method in `SceneHandler` to load the opening scene
- Purpose-specific configuration files (`.tres` resources or `.cfg`) are used to keep game configuration abstracted away from scene code — do not hardcode tunable values in scripts

### Scene Design

- **Break scenes into independently runnable and testable units** — each scene should be playable in isolation where possible
- Minimize coupling and direct dependencies between scenes
- Export configuration variables where it improves editor usability and in-scene testing
- Use `Marker2D` and `Marker3D` node types for spawn points and important positions — never use raw `Vector2`/`Vector3` constants for locations
- Use `AnimationPlayer` for animations — never cycle frames in code

---

## Communication Between Nodes

- **Prefer signals over direct method calls** between nodes — minimize cross-node method coupling
- Use the `EventBus` autoload for cross-system events that span unrelated scenes or autoloads
- Use `@export` with type hints for all designer-tunable values
- Never call `Input.is_action_pressed()` directly — route through the `InputManager` autoload

---

## Godot Editor Compliance

**All code must compile and run without errors in the Godot Editor. The Studio Head must be able to open the project and execute scenes without encountering unaddressed errors or warnings.**

- **No Godot Editor errors are acceptable.** All editor-reported errors must be resolved before a ticket is marked DONE.
- **All compiler warnings must be resolved.** Warning suppression using `@warning_ignore()` is **not permitted** without explicit Studio Head approval. Agents must fix the underlying issue, not suppress the warning.
- **Scripts must have zero syntax errors** when opened in the Godot editor
- **Debug builds must run without errors.** If errors appear during play-testing, they must be fixed before moving to the next ticket.
- **Type checking must pass.** All variables and function signatures must be properly typed to pass Godot's type checker.

This rule applies to all agents. Systems Programmer enforces this during code review. Any requested suppression must be escalated to the Studio Head for approval before being applied.


---

## Debugging

- Write debug print statements for any useful events or actions
- All debug output must go through a method on an autoload (e.g., `Global.log(message)`) that only prints when `OS.is_debug_build()` is `true`
- Never leave bare `print()` statements in production code — use the debug logging method or `push_warning()` / `push_error()` for intentional diagnostic output

---

## Method and Expression Standards

- **Prefer `match` over chained `if/elif`** for state switching
- **Use `await` or `signals`** for async operations — never use manual timers for control flow
- **Complex expressions must be resolved into a local variable first:** any method parameter that involves concatenation or math with more than two components must be assigned to a named local variable before being passed into the method

```gdscript
# Wrong
move_and_collide(Vector2(base_speed * sprint_multiplier * delta, gravity * delta))

# Correct
var horizontal_velocity: float = base_speed * sprint_multiplier * delta
var vertical_velocity: float = gravity * delta
move_and_collide(Vector2(horizontal_velocity, vertical_velocity))
```

---

## Patterns to Use

- Signals for cross-node communication
- `EventBus` autoload for cross-system events
- `@export` with type hints for all designer-tunable values
- `class_name` for inheritance — never `extends "res://..."` string paths
- `Marker2D` / `Marker3D` for spawn and reference points
- `AnimationPlayer` for all animations
- Named local variables for multi-component expressions before passing to methods

---

## Patterns to Avoid

- `get_node()` with magic strings beyond direct children — use `@onready` instead
- Untyped function parameters (`x` — always `x: int`)
- Generic, non-descriptive node or variable names (`Button1`, `node`, `temp`)
- Abbreviations in any identifier
- Calling `Input.is_action_pressed()` directly — use `InputManager` autoload
- Creating autoloads without Systems Programmer approval
- Bare `print()` statements — use `Global.log()` or `push_warning()` / `push_error()`
- Frame cycling in code — use `AnimationPlayer`
- `extends "res://..."` string-path inheritance — use `class_name` instead
- Multi-component expressions passed directly as method arguments
- **Leaving Godot Editor errors or unaddressed warnings in code** — see "Godot Editor Compliance" section

---

## Physics Layers

Physics layer assignments are defined in `docs/engineering/physics-layers.md`. Never use raw integers for collision masks — use the named layer constants.

---

## Testability

- Optimize all code for readability and ease of troubleshooting
- Structure scenes so they can be run and tested independently
- Minimize coupling between scenes; export configuration variables to make in-editor testing practical
- Write debug log calls for all meaningful events and state transitions
