# Game Designer Decision Log

---

## [2026-02-21] [TICKET-0001] Input System Architecture

**Context:** M1 milestone requires a unified input system supporting both keyboard and gamepad across first-person surface exploration and third-person ship navigation. Input routing, context-switching, and gamepad normalization must be defined before implementation begins.

**Decision:** Created a centralized InputManager architecture with two distinct input contexts (first-person vs. third-person), context-aware input routing, and equal priority for keyboard and gamepad input.

**Key Design Choices:**
1. **Dual analog stick layout:** Left stick for movement/camera primary; right stick for camera/rotation secondary (swapped per context)
2. **Context-aware input:** Same physical button does different things depending on view mode (Tab toggles views; buttons map differently in each context)
3. **Centralized InputManager autoload:** Controllers query InputManager, never direct Input API (enables remapping and testing)
4. **Gamepad as first-class citizen:** Sensitivity tuning, dead zone handling, button remapping all built-in per GDD requirement
5. **0.3 second debounce on view switching:** Prevents accidental double-toggles from rapid Tab/Menu presses
6. **Proportional movement:** Analog sticks support partial movement; not binary

**Alternatives considered:**
1. Separate input managers for each context — rejected because it would duplicate code and make global remapping harder
2. Event-based input routing (signals) instead of queries — rejected because polls are simpler to reason about and lower-latency
3. Mouse-only first-person camera — rejected because GDD mandates gamepad parity; analog stick look must be equally viable
4. Instant view switching without damping — rejected because smooth transitions feel more polished and reduce player disorientation

**Rationale:**
- The centralized InputManager ensures consistent behavior across contexts and makes future features (input remapping, accessibility profiles) straightforward to add
- Context-aware routing keeps each controller focused on its own input, reducing coupling and making them independently testable
- Gamepad parity aligns with the GDD's "first-class citizen" mandate and supports the console post-launch goal
- The debounce on view switching is a quality-of-life feature that prevents frustration from accidental toggling
- Proportional movement is essential for smooth, responsive gameplay on both keyboard and gamepad

**Open Questions for Review:**
- Mouse look toggle option (hold Right-click to enable)?
- Acceleration curves for analog stick movement?
- Gamepad vibration feedback in v1 or deferred to v2?

See `docs/design/systems/input-system.md` for full specification.
