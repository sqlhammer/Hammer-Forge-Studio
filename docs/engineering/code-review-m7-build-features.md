# Code Review: M7 Build & Features Phase

**Reviewer:** systems-programmer
**Review Ticket:** TICKET-0129
**Date:** 2026-02-26
**Milestone:** M7 — Ship Interior + Scene Architecture Overhaul
**Phase Reviewed:** Build & Features

---

## Scope

Scripts and scenes reviewed:

| Ticket | Script / Scene | Author |
|--------|---------------|--------|
| TICKET-0126 | `game/scripts/gameplay/ship_interior.gd` | gameplay-programmer |
| TICKET-0127 | `game/scripts/gameplay/ship_status_display.gd` | gameplay-programmer |
| TICKET-0128 | `ship_interior.gd` (`_build_viewport_window()`) | gameplay-programmer |
| TICKET-0120 | `game/scripts/ui/interaction_prompt_hud.gd` | gameplay-programmer |
| TICKET-0120 | `game/scripts/gameplay/ship_enter_zone.gd` | gameplay-programmer |
| TICKET-0120 | `game/scripts/systems/deposit.gd` (addition only) | gameplay-programmer |
| TICKET-0122 | `game/scripts/ui/battery_bar.gd` | systems-programmer |
| TICKET-0122 | `game/tests/test_battery_bar_unit.gd` | systems-programmer |

---

## Overall Assessment: APPROVED WITH MINOR NOTES

No critical or blocking violations found. All M7 Build & Features scripts are well-structured, correctly typed, use `Global.log()` throughout, follow signal patterns, and pass the public-method docstring requirement. Two minor findings are documented below. One follow-up TASK ticket is recommended.

---

## Findings

### FINDING-01 — Minor — Physics Layer Constants Duplicated Across Scripts

**Severity:** Minor
**Files:** `ship_interior.gd` (lines 43–45), `interaction_prompt_hud.gd` (line 13)
**Standard:** `docs/engineering/physics-layers.md` — "Canonical collision layer definitions. Never use raw integers in collision mask code — reference these layer names."

**Detail:**
Both `ship_interior.gd` and `interaction_prompt_hud.gd` define their own local copies of physics layer constants:

- `ship_interior.gd`: `LAYER_PLAYER`, `LAYER_ENVIRONMENT`, `LAYER_INTERACTABLE`
- `interaction_prompt_hud.gd`: `LAYER_INTERACTABLE`

The `docs/engineering/physics-layers.md` document is still in "Draft" status and acknowledges that centralized named constants are not yet defined. The local constants use correct bit-shift values matching the physics-layers document, and they ARE named constants (not raw integers). However, duplication creates a maintenance risk if layer assignments change.

**Recommendation:** Create a follow-up TASK ticket (assigned to systems-programmer) to define a central `PhysicsLayers` class or autoload constant resource containing all layer bit-masks, then update all scripts to reference it. This aligns with the `docs/engineering/physics-layers.md` note: "To be replaced with named constants once defined in a core constants resource."

**Status:** No immediate code change required; follow-up TASK ticket created (see below).

---

### FINDING-02 — Minor Style — Type Inference Operator in `battery_bar.gd`

**Severity:** Minor (style preference)
**File:** `game/scripts/ui/battery_bar.gd`, line 32
**Standard:** "Strong typing required: all variables must declare their type — `var speed: float = 5.0`, never `var speed = 5.0`"

**Detail:**
```gdscript
var _bar_rect := Rect2(0, 0, 0, 0)
```

Uses `:=` (type inference) rather than an explicit type annotation `var _bar_rect: Rect2 = Rect2(0, 0, 0, 0)`. In GDScript 4, `:=` does produce a fully typed variable inferred from the right-hand side, so there is no loss of type safety. The coding standard's prohibited pattern is `var x = 5.0` (untyped `=`), not `:=`. This is a style preference, not a strict violation.

**Recommendation:** Prefer explicit annotation in future scripts. No change required for this ticket.

---

## Review by Focus Area

### 1. Scene Architecture Compliance

- `ship_interior.gd` uses programmatic scene construction (geometry, lighting, markers built in `_ready()` and builder methods). The coding standard states "Prefer adding nodes directly in scene (.tscn) files over programmatic creation in scripts" — this is a preference, not a hard requirement. For a greybox implementation with iterative dimensions, scripted construction is a reasonable trade-off. **Accepted for M7 greybox scope.**
- `ship_status_display.gd` likewise builds its SubViewport UI programmatically. Same rationale applies. **Accepted.**
- All root node types are correct (`Node3D`, `CanvasLayer`, `Area3D`).
- `ship_status_display.tscn` and `interaction_prompt_hud.tscn` both exist as scene files with scripts attached.

### 2. Ship Interior Structure

- Node naming follows `PascalCase` conventions throughout (`MachineRoomFloor`, `CockpitWallWest`, `ViewportWindow`, etc.). ✓
- Zone markers named `ZoneMarker_%d` and `PlacementZone_%d` use dynamic index formatting — acceptable for procedural construction.
- `StatusDisplayArea` and `ViewportArea` Marker3D nodes are present as required by TICKET-0126. ✓
- No orphaned nodes identified.

### 3. Signal Connections

- `ship_status_display.gd` connects to `ShipState.power_changed`, `integrity_changed`, `heat_changed`, `oxygen_changed` via `_connect_ship_state()` using a `match` block — clean implementation. ✓
- `interaction_prompt_hud.gd` does not connect to signals from deposit or ship zones; instead it polls via raycast and group iteration in `_process()`. This is a deliberate architectural choice documented in the handoff notes. Acceptable.
- `ship_enter_zone.gd` (`ShipEnterZone`) uses duck-typing via the `interaction_prompt_source` group — no signal connections needed; the HUD polls it. ✓
- Exit zone signal connections in `ship_interior.gd`: `body_entered` and `body_exited` connected to `_on_exit_zone_entered` / `_on_exit_zone_exited`. Clean. ✓
- No orphaned connections identified.

### 4. Performance

- `ship_status_display.gd` creates a new `StyleBoxFlat` (via `.duplicate()`) every frame in `_update_colors()` when `_is_critical` is true, because the fill stylebox override requires a fresh duplicate to avoid shared-resource mutation. This is a minor inefficiency. For 4 display instances in a greybox context it is not a concern. **Note for future optimization if frame budget tightens.**
- `interaction_prompt_hud.gd` performs a full raycast every `_process()` frame — acceptable for the scene scale.
- Only one SubViewport is added per `ShipStatusDisplay` instance (4 total for the cockpit). This is consistent with the TICKET-0127 spec and within acceptable overhead for greybox.
- No duplicate resource loading identified.
- `ship_interior.gd` re-creates materials programmatically in `_ready()` — these are one-time costs at scene load. Acceptable.

### 5. Coding Standards Compliance

| Check | Result |
|-------|--------|
| `##` docstring on every script | ✓ All scripts |
| `##` docstring on every public method | ✓ All public methods |
| `snake_case` file names | ✓ |
| `PascalCase` class names | ✓ |
| Typed variables (no untyped `=`) | ✓ (`:=` in battery_bar.gd is type-safe) |
| Typed method signatures | ✓ |
| `match` over `if/elif` chains | ✓ (ship_status_display.gd, battery_bar.gd) |
| `Global.log()` instead of bare `print()` | ✓ All scripts |
| No `Input.is_action_pressed()` direct calls | ✓ |
| Signals for cross-node events | ✓ |
| `Marker3D` for spawn/reference points | ✓ |
| No unresolved Godot editor errors reported | ✓ (per ticket handoff notes) |

### 6. Test Coverage (TICKET-0122)

- `test_battery_bar_unit.gd` contains 12 unit tests covering all 4 color tiers (full, normal, warning, critical) plus edge cases (depleted, zero charge, boundary thresholds). ✓
- Tests bypass `_ready()` by not adding to tree, setting internal state directly. This is a valid isolation pattern for pure-logic unit tests. ✓
- Test class follows `TestSuite` extension pattern. ✓
- All test method names are descriptive. ✓

---

## Follow-Up Tickets

### Recommended: TASK — Centralize physics layer constants

Create a `PhysicsLayers` class (e.g., `game/scripts/core/physics_layers.gd`) that defines all layer bit-masks as named constants. Update all scripts currently defining local layer constants to reference the central class. This resolves FINDING-01 and fulfills the intent of `docs/engineering/physics-layers.md`.

**Priority:** P3 (low urgency; no runtime risk with current duplicated constants)
**Owner:** systems-programmer
**Dependency:** None

---

## Conclusion

The M7 Build & Features phase implementation is well-executed and ready to proceed to QA. All acceptance criteria for TICKET-0129 are met. No blocking issues found.
