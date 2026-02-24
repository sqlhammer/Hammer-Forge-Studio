# Input System Design

**Owner:** game-designer
**Status:** Draft
**Last Updated:** 2026-02-24
**References:** GDD (`docs/design/gdd.md`), Coding Standards (`docs/engineering/coding-standards.md`)

---

## Overview

The input system is the primary interface between the player and the game world. It must support **both keyboard and gamepad with equal priority**, enabling seamless switching between input devices and smooth transitions between gameplay contexts (first-person surface exploration vs. third-person ship navigation).

**Core Design Principle:** Input is *context-aware*. The same physical button triggers different in-game actions depending on the current view mode and activity state. The system must route input correctly while prioritizing responsive feedback and avoiding input conflicts.

---

## Input Contexts

The game operates in two primary **input contexts**, each with a distinct control scheme and camera model.

### Context 1: First-Person Surface Exploration

**Purpose:** The player character walks on the alien surface, scans for resources, and interacts with the environment.

**Camera Model:** First-person ego perspective (player's eye level). Camera position follows the character's head. Vertical head-bob is optional polish.

**Active Controls:**

| Action | Keyboard | Gamepad | Type | Notes |
|--------|----------|---------|------|-------|
| Move Forward | W | Left Stick ↑ | Analog | Proportional; gamepad supports partial movement |
| Move Backward | S | Left Stick ↓ | Analog | Proportional; walking backward is slower than forward |
| Strafe Left | A | Left Stick ← | Analog | Proportional |
| Strafe Right | D | Left Stick → | Analog | Proportional |
| Camera Look Horizontal | Mouse X-axis | Right Stick ← / → | Analog | Free-look; wraps horizontally at screen edges |
| Camera Look Vertical | Mouse Y-axis | Right Stick ↑ / ↓ | Analog | Free-look; clamped to ±85° pitch (prevent upside-down) |
| Jump | Space | South Button (A) | Digital | Not in v1; reserved for future platforming |
| Interact / Use | E | West Button (X) | Digital | Pickup items, start mining, open doors |
| Scan / Open Scanner | Q | Left Bumper | Digital | Activate mineral scanner overlay |
| Use Tool/Weapon (Equipped) | Left Mouse Click | Right Trigger | Digital | Mine with pickaxe, place structure, etc. |
| Switch View Mode | Tab | Menu / Start | Digital | Toggle to third-person ship view |
| Pause / Menu | Esc | Select / Back | Digital | Open game menu |

**Dead Zone Handling (Gamepad):**
- Left Stick: 0.15 dead zone (ignore small drifts; typical for movement)
- Right Stick: 0.10 dead zone (tighter for aiming/camera, if aiming is added)
- Triggers: 0.05 dead zone

**Camera Inversion Option:**
- Y-axis inversion available in settings (gamepad right stick look up/down)
- Keyboard mouse always follows standard convention (up = up)

---

### Context 2: Third-Person Ship Navigation

**Purpose:** The player views their atmospheric ship from an external orbital perspective, navigates it across the world map, and manages ship systems.

**Camera Model:** Orbital camera circling a target (the ship or player). The camera position is defined in **spherical coordinates** (distance, yaw angle, pitch angle) relative to the ship's/player's center.

**Active Controls:**

| Action | Keyboard | Gamepad | Type | Notes |
|--------|----------|---------|------|-------|
| Ship Pitch (Up/Down) | W / S | Right Stick ↑ / ↓ | Analog | Rotate ship forward/backward in world space |
| Ship Roll (Left/Right) | A / D | Right Stick ← / → | Analog | Rotate ship left/right; controls orbital pitch |
| Camera Orbit Yaw | Mouse X-axis | Left Stick ← / → | Analog | Rotate camera around ship; no wrapping |
| Camera Orbit Pitch | Mouse Y-axis | Left Stick ↑ / ↓ | Analog | Raise/lower camera angle; clamped to ±80° |
| Zoom Camera In | Mouse Wheel ↑ / Numpad + | LB / LT | Digital/Analog | Decrease orbital distance (minimum 5 units from ship center) |
| Zoom Camera Out | Mouse Wheel ↓ / Numpad - | RB / RT | Digital/Analog | Increase orbital distance (maximum 50 units) |
| Ship Accelerate Forward | Space | Right Trigger | Digital | Increase ship velocity toward current heading |
| Ship Emergency Stop | X | South Button (A) | Digital | Instantly stop all ship movement (high power cost) |
| Exit Ship View / Land | Tab | Menu / Start | Digital | Toggle back to first-person surface view |
| Pause / Menu | Esc | Select / Back | Digital | Open game menu |

**Camera Behavior:**
- Default orbital distance: 15 units
- Default orbital position: 45° yaw, 30° pitch (viewing ship from front-right, above)
- Camera follows ship smoothly; damping factor of 0.15 (fast but not snappy)
- Camera does **not** auto-rotate to face the ship if the ship rotates — player must manually adjust

**Dead Zone Handling (Gamepad):**
- Left Stick: 0.15 dead zone
- Right Stick: 0.15 dead zone
- Triggers: 0.05 dead zone

---

## View Mode Switching

**Trigger:** Player presses **Tab** (keyboard) or **Menu / Start button** (gamepad).

**Behavior:**
1. Current view deactivates (freeze character in first-person; freeze ship in third-person)
2. Camera smoothly transitions over **0.5 seconds** to the new view
3. Control scheme switches immediately after transition
4. Both controllers remain loaded in memory but only one is active at any time

**Edge Cases:**
- **Switching while moving:** Current velocity is preserved (character keeps walking momentum; ship keeps velocity)
- **Switching mid-action:** If the player is mid-use (mining, building), the action completes in the context it started; view switch is queued after action completes
- **Rapid switching:** Input is debounced (0.3 second cooldown on Tab / Menu button to prevent accidental double-toggle)

---

## Input Device Switching

**Requirement:** The player may seamlessly switch between keyboard/mouse and gamepad input without opening the menu or changing any settings.

**Activation:**
- **Gamepad → Keyboard/Mouse:** Press any keyboard key or move the mouse
- **Keyboard/Mouse → Gamepad:** Press any button on the gamepad or move any gamepad analog stick beyond its dead zone

**Behavior:**
- The active input device switches immediately upon detection
- No confirmation dialog or menu navigation required
- The control scheme updates instantly to match the active device (e.g., if switching from gamepad to keyboard in first-person, camera controls default to mouse look)
- UI prompts and on-screen button hints update to reflect the active device (e.g., "Press X [Gamepad]" vs. "Press E [Keyboard]")
- Both input devices remain active in the background; only the "primary" device is used for input routing at any given time

**Implementation Notes:**
- InputManager must continuously monitor for device activity on both keyboard/mouse and gamepad
- Activity is debounced (0.1 second window) to prevent false-positive rapid switching
- Mouse movement alone (without clicking) counts as activity for switching away from gamepad
- Switching does not reset game state, pause the game, or interrupt ongoing actions

---

## Input Routing Architecture

**Centralized InputManager Autoload** handles all input and distributes it to active controllers.

```
Player Input (Keyboard / Gamepad)
    ↓
InputManager (autoload)
    ├─→ PlayerFirstPerson controller (if active)
    ├─→ PlayerThirdPerson controller (if active)
    └─→ UI System (if menu open)
```

**Key Rules:**
1. Only **one controller is active** at any time (first-person XOR third-person)
2. InputManager queries the active controller to consume input; input is not duplicated
3. Menu input (Pause, Esc, etc.) is **always processed**, even if a controller is active
4. InputManager provides query methods, **not events**: controllers call `InputManager.is_action_pressed("move_forward")` as needed

**Implementation Note:** Controllers never call `Input.is_action_pressed()` directly. All input queries route through InputManager to enable input remapping and testing.

---

## Gamepad Support Requirements

Per the GDD, gamepad is a **first-class input device**. It must not feel like an afterthought or tacked-on feature.

**Standards:**
- **All actions must be rebindable**, including gamepad button layouts
- **Analog triggers** (LT, RT) are **pressure-sensitive** — they are not binary but analog [0.0 — 1.0]
- **Dual Stick Layout:**
  - Left Stick = Movement/Camera primary (context-dependent)
  - Right Stick = Camera/Rotation secondary (context-dependent)
- **Button Mapping** follows Xbox layout (South, West, North, East buttons; LB, RB, LT, RT; Menu, Select)
- **Gamepad feedback** (vibration) is optional for v1 but reserved for future (mining vibration, ship damage feedback)

**Sensitivity Tuning:**
- Stick sensitivity configurable per axis (separate X and Y for both sticks)
- Mouse sensitivity configurable (separate X and Y)
- Separate "aim sensitivity" multiplier (if aiming is added in future)

---

## Aim Assist (Gamepad)

**Applies To:** First-Person Surface Exploration context when player is using ranged tools or weapons.

**Requirement:** When a player is using a gamepad to aim a ranged tool or weapon, a mild aim assist automatically snaps the cursor toward nearby targets if they are within a small detection range. This compensates for the reduced precision of analog stick aiming compared to mouse input.

**Behavior:**
- **Activation:** Aim assist is active whenever the player is aiming a ranged tool/weapon on gamepad
- **Snap Distance:** Targets within a small snap radius (TBD: ~50-100 pixels on screen) are eligible
- **Snap Strength:** The snap is mild and gradual, not instantaneous; the cursor smoothly transitions toward the target rather than jumping
- **Target Priority:** If multiple targets are in range, the reticle snaps to the closest one (by distance from current aim point)
- **Keyboard/Mouse:** Aim assist is **disabled** when using keyboard and mouse; mouse users get full manual control

**Implementation Considerations:**
- Should not feel like "auto-aim" or remove player agency; it's a precision aid, not an aimbot
- Must respect dead zones; very small stick inputs should not trigger snapping
- Works in tandem with camera sensitivity settings (separate aim sensitivity may apply)

---

## Edge Cases and Constraints

### Input Conflicts
- **Never block either input device:** The most recently active device (keyboard/mouse or gamepad) has priority for input routing. Whichever device detects activity first becomes the active input device.
- **Never accept conflicting inputs simultaneously:** If player holds W and also presses Right Stick ↑ (both move forward in first-person), only one forward velocity is applied

### Mode Switching Conflicts
- **Switching while mid-interaction:** Player must finish action before view switches (e.g., can't switch views while mining; mining completes, then view switches)
- **Rapid input spam:** Tab/Menu button has 0.3 second cooldown to prevent accidental toggling

### Gamepad-Only Edge Cases
- **Stick drift:** Dead zone (0.15) absorbs minor drifts; larger drifts are treated as intended input
- **Trigger pressure:** Analog triggers are read as [0.0 — 1.0] values; threshold for "pressed" is 0.5

### Pause State (Two-Tier Model)

The game uses a **two-tier model** for menu interactions, distinguishing between in-world menus and abstract system menus.

**Tier 1 — In-World Menus (no game pause):**
Applies to: inventory, machine interaction panels (Fabricator, Recycler, Module Placement), drone programming UI, ship management, tech tree.

When one of these menus opens:
- Gameplay inputs are suppressed via `InputManager.set_gameplay_inputs_enabled(false)` — the player cannot walk, scan, mine, or interact with the world
- Game time continues; all automated systems run (drones travel, Recycler jobs progress, Fabricator jobs progress, ship globals tick)
- Mouse mode switches to `MOUSE_MODE_VISIBLE` for menu interaction
- Controllers remain loaded but receive no gameplay input

When the menu closes:
- `InputManager.set_gameplay_inputs_enabled(true)` restores player control
- Mouse mode returns to `MOUSE_MODE_CAPTURED`
- Game resumes from the same context — no state reset

**`set_gameplay_inputs_enabled(bool)` API:** This method will be added to InputManager in TICKET-0077. It gates all gameplay action queries (movement, interaction, scanning, mining) without affecting UI or abstract menu input.

**Tier 2 — Abstract System Menus (valid game pause):**
Applies to: save game, key bindings, system/graphics settings, quit confirmation.

`get_tree().paused = true` is appropriate here. These menus have no diegetic relationship to the game world and players expect time to freeze while adjusting settings.

---

## Open Questions

- [ ] Should mouse look have a "toggle lock" option (hold Right-click to look, release to freeze)?
- [ ] Do we support mouse-only ship navigation (no gamepad), or is gamepad mandatory for third-person?
- [ ] Should we implement acceleration/deceleration curves for stick movement, or instant full-speed?
- [ ] Will we support 360-degree head-bob in first-person, or just vertical bob?
- [ ] Should gamepad vibration be enabled for mining/damage feedback in v1 or deferred to v2?

---

## Implementation Guidance

**For Systems Programmer (InputManager):**
- Implement InputManager as a persistent autoload following coding standards
- Provide query methods: `is_action_pressed()`, `get_action_strength()`, `get_analog_input()`
- Support input remapping by updating Godot project settings dynamically
- Handle gamepad dead zones in InputManager, not in controllers

**For Gameplay Programmer (Controllers):**
- Do not call `Input.is_action_pressed()` directly; route through InputManager
- Respect the "context-aware" principle: only respond to inputs appropriate for your context
- Implement smooth camera movement with damping; avoid instant snapping
- Handle view switching by disabling your controller when another context becomes active

---
