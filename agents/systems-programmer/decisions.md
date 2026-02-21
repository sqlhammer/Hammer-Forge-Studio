# Systems Programmer Decision Log

---

## [2026-02-21] [TICKET-0002] InputManager Autoload Implementation

**Context:** M1 milestone required a centralized input system supporting keyboard and gamepad with dead zone normalization, input device detection, and context-aware input routing per the design spec (TICKET-0001).

**Decision:** Implemented InputManager as a persistent autoload singleton with centralized input routing, dynamic action setup, and input device auto-detection with debounce.

**Key Architectural Choices:**

1. **Query-Based API, not Events:** Controllers call `is_action_pressed()` rather than listening to signals. This is simpler to reason about and lower-latency than event-driven routing.

2. **Input Device Auto-Detection:** InputManager continuously monitors keyboard/mouse and gamepad activity, switching the active device automatically with 0.1s debounce. No menu or confirmation required.

3. **Dynamic Action Registration:** Input actions are created at runtime if they don't exist, rather than being hardcoded in project.godot. This keeps the InputManager self-contained and testable.

4. **Normalized Dead Zones:** Dead zones applied in InputManager, not in controllers. Movement uses 0.15, camera uses 0.10, triggers use 0.05 per design spec.

5. **Global Autoload Dependency:** Created a separate Global utility autoload for debug logging (used by InputManager and other systems). This follows the pattern of having a shared logging interface.

6. **Trigger Normalization:** Gamepad triggers return [-1, 1] from Godot; InputManager normalizes to [0, 1] for intuitive usage.

**Alternatives Considered:**

1. **Event-based input routing** — Rejected because polling is simpler for controllers that need continuous input state (movement, camera)

2. **Input actions defined in project.godot** — Rejected because dynamic registration keeps InputManager self-contained and doesn't require manual editor configuration

3. **Hard-coded button mapping** — Rejected because InputManager supports future input remapping via `InputMap` dynamically

**Rationale:**

- Query-based API matches Godot's design philosophy (see `Input.is_action_pressed()`)
- Auto-detection feels seamless to the player; no forced menu navigation needed
- Dynamic action registration keeps the system testable standalone
- Dead zone tuning matches the design spec exactly
- Global autoload provides a shared logging interface for the entire project

**Implementation Details:**

- `get_analog_input(stick: String) -> Vector2` returns [-1, 1] with dead zone applied
- `get_trigger_input(trigger: String) -> float` returns [0, 1] (normalized from gamepad's [-1, 1])
- 18 input actions configured: 12 first-person (move, camera, interact, scan, use, switch, pause, jump) + 6 third-person (ship controls)
- `input_device_changed` signal emitted when device switches (for UI updates)
- Sensitivity tuning exported via `@export` (mouse_sensitivity_x/y, gamepad_sensitivity_x/y, invert_gamepad_look_y)

**Unresolved Questions:**

- Should InputManager support custom input remapping profiles (e.g., left-handed mode)?
- Should we add input buffering for action queuing (e.g., buffer jump input for 1 frame)?

See `docs/engineering/architecture.md` for full API documentation.

---

## [2026-02-21] [TICKET-0003] First-Person Controller Code Review

**Context:** Gameplay Programmer submitted PlayerFirstPerson.gd for code review. Script implements character movement, camera control, and gravity per design spec.

**Decision:** ✅ APPROVED for production. Script meets all coding standards and architecture requirements.

**Review Findings:**
- Strong type annotations throughout: COMPLIANT
- Docstrings on all public methods: COMPLIANT
- Proper section ordering (constants → exported → private → onready → built-in → public → private): CORRECT
- All input routed through InputManager (no direct Input API calls): CORRECT
- Method naming (snake_case) and class naming (PascalCase): CORRECT
- No dead code or unused variables: CLEAN
- Frame-rate independent movement (delta scaling): CORRECT
- Pitch clamping prevents upside-down camera: GOOD
- Warning ignore annotation appropriate for autoload type checking: ACCEPTABLE

**Rationale:**
- Code is clean, readable, and maintainable
- Physics implementation (CharacterBody3D) is appropriate
- Input handling design shows good separation of concerns
- Ready for integration into TICKET-0005

---

## [2026-02-21] [TICKET-0004] Third-Person Controller Code Review

**Context:** Gameplay Programmer submitted PlayerThirdPerson.gd for code review. Script implements orbital camera system using spherical coordinates per design spec.

**Decision:** ✅ APPROVED for production. Minor warnings are non-blocking; core functionality and standards compliance are excellent.

**Review Findings:**
- Strong type annotations throughout: COMPLIANT
- Docstrings on all public methods: COMPLIANT
- Proper section ordering: CORRECT
- All input routed through InputManager: CORRECT
- Method naming and class naming: CORRECT
- Spherical coordinate math (sin/cos orbital calculations): CORRECT
- Smooth damping via lerp interpolation: GOOD
- Framerate-independent input scaling: CORRECT
- Public API design (set_orbit_center, get_camera_position, reset_orbit): GOOD

**Minor Non-Blocking Issues:**
- Parameter "position" shadows Node3D.position property in set_orbit_center()
  - Severity: LOW (no runtime impact; suggestion: rename to target_pos in future refinement)
- Parameter "delta" unused in _apply_orbit_damping()
  - Severity: LOW (suggestion: rename to _delta to suppress compiler warning in future)

**Rationale:**
- Orbital camera implementation is mathematically sound
- Zoom constraints (MIN: 5, MAX: 50) are reasonable
- Error handling on _ready() is appropriate
- Warning ignore annotations properly suppress autoload type checking warnings
- Ready for integration into TICKET-0005
