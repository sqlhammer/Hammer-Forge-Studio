# GDScript Coding Standards

**Owner:** systems-programmer
**Status:** Draft
**Last Updated:** —

> All GDScript produced by any agent must follow these standards. Systems Programmer enforces via code review.

---

## File and Node Naming

- **Script files:** `snake_case.gd` (e.g., `player_controller.gd`)
- **Class names:** `PascalCase` using `class_name` (e.g., `class_name PlayerController`)
- **Node names in scene:** `PascalCase` (e.g., `PlayerSprite`, `CollisionShape`)
- **Scene files:** `snake_case.tscn` matching the root node's class name

---

## Variable Naming

- **Variables and functions:** `snake_case`
- **Constants:** `SCREAMING_SNAKE_CASE`
- **Signals:** `past_tense_snake_case` (e.g., `player_jumped`, `enemy_died`)
- **Private members:** prefix with `_` (e.g., `_current_state`)
- **No untyped variables:** always declare type (e.g., `var speed: float = 5.0`)

---

## Script Structure Order

Every script must follow this section order:

```gdscript
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
func do_thing() -> void:
    pass

# ── Private Methods ───────────────────────────────────────
func _helper() -> void:
    pass
```

---

## Documentation

- Every `class_name` script must have a one-line comment below the `extends` declaration describing its purpose
- Every public function (`func` without `_` prefix) must have a docstring comment above it
- Complex logic blocks must have an inline comment explaining the why, not the what

---

## Patterns to Use

- Use signals for cross-node communication — never call methods on sibling nodes directly
- Use `EventBus` autoload for cross-system events
- Use `@export` with type hints for all designer-tunable values
- Prefer `match` over chained `if/elif` for state switching
- Use `await` for async operations — never use manual timers for control flow

---

## Patterns to Avoid

- `get_node()` with magic strings beyond direct children — use `@onready` instead
- `var x` without a type — always type your variables
- Calling `Input.is_action_pressed()` directly — use `InputManager` autoload
- Creating autoloads without Systems Programmer approval
- `print()` statements left in production code — use `push_warning()` or `push_error()` for intentional logs

---

## Physics Layers

Physics layer assignments are defined in `docs/engineering/physics-layers.md`. Never use raw integers for collision masks — use the named layer constants.
