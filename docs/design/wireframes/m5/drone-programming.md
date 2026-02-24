# Wireframe: Drone Programming UI

**Component:** Automation Hub — Drone Programming Interface
**Ticket:** TICKET-0065
**Blocks:** TICKET-0072 (Automation Hub + drone system)
**Last Updated:** 2026-02-24
**Reference:** `docs/design/systems/meaningful-mining.md` — Automation: Mining Drones section

---

## Purpose

The Drone Programming UI lets the player configure and monitor automated mining programs. The player defines targeting criteria against their pool of personally analyzed deposits. This is a strategic planning screen — not a micromanagement tool. The design goal is giving players enough control to feel like the drone is an extension of their scanner knowledge, without requiring per-deposit manual assignment.

**Key design constraint (from GDD):** A drone cannot be assigned to a deposit the player has not personally analyzed via Phase 2 scan. The UI enforces this — the analyzed deposit pool is the player's only target source.

---

## Interaction Model

1. Player interacts with the Automation Hub module in the ship
2. Drone Programming screen opens as a full-screen overlay; game time continues, player movement and action inputs are suppressed via InputManager, active drones continue operating
3. Player reviews the current program (or creates one if none exists)
4. Player adjusts filter criteria: deposit type, minimum purity, tool tier, extraction radius, priority
5. Player activates the program — drones deploy and begin operating
6. Player can return to this screen at any time to view drone status or update criteria
7. Close with Cancel/Back

---

## Screen Region & Anchoring

- **Position:** Full-screen overlay (centered)
- **Background dim:** Screen Dim (`#000000` at 50%)
- **CanvasLayer:** Layer 2

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Outer panel width** | 900px |
| **Outer panel height** | 620px |
| **Left column (config) width** | 520px |
| **Right column (status) width** | 340px |
| **Column gap** | `sp-6` (24px) |
| **Filter row height** | 56px |

---

## Layout Diagram

```
    ┌─────────────────────────────── Full Screen ──────────────────────────────────┐
    │                                                                               │
    │  ┌─────────────────────────────────────────────────────────────────────┐     │
    │  │  DRONE PROGRAM                                      [X] Close       │     │
    │  │  ─────────────────────────────────────────────────────────          │     │
    │  │                                                                     │     │
    │  │  ┌──── PROGRAM CONFIG (520px) ────┐  ┌──── DRONE STATUS (340px) ──┐│     │
    │  │  │                               │  │                            ││     │
    │  │  │  TARGET: DEPOSIT TYPE         │  │  ACTIVE DRONES             ││     │
    │  │  │  ┌───────────────────────────┐│  │  ───────────────────        ││     │
    │  │  │  │  ▼  Scrap Metal (Tier 1) ││  │                            ││     │
    │  │  │  └───────────────────────────┘│  │  ● Drone 1  Traveling     ││     │
    │  │  │                               │  │    Target: Deposit A-7    ││     │
    │  │  │  MIN PURITY                   │  │    ETA: 48s               ││     │
    │  │  │  ┌──  ★ ★ ★ ☆ ☆  ──────────┐│  │                            ││     │
    │  │  │  │  ◄  3 Stars min  ►       ││  │  ● Drone 2  Extracting    ││     │
    │  │  │  └───────────────────────────┘│  │    Target: Deposit B-2    ││     │
    │  │  │                               │  │    Yield: ~12 Metal       ││     │
    │  │  │  TOOL TIER                    │  │                            ││     │
    │  │  │  ┌───────────────────────────┐│  │  Analyzed Deposits: 14    ││     │
    │  │  │  │  ▼  Tier 1 — Hand Drill  ││  │  Matching Program: 8      ││     │
    │  │  │  └───────────────────────────┘│  │                            ││     │
    │  │  │                               │  │  ───────────────────        ││     │
    │  │  │  EXTRACTION RADIUS            │  │                            ││     │
    │  │  │  ┌──  ◄──────●────────── ───┐│  │  [ DEACTIVATE DRONES ]    ││     │
    │  │  │  │  250m radius             ││  │                            ││     │
    │  │  │  └───────────────────────────┘│  └────────────────────────────┘│     │
    │  │  │                               │                                 │     │
    │  │  │  PRIORITY                     │                                 │     │
    │  │  │  ┌───────────────────────────┐│                                 │     │
    │  │  │  │  ▼  Highest Purity First ││                                 │     │
    │  │  │  └───────────────────────────┘│                                 │     │
    │  │  │                               │                                 │     │
    │  │  │  [ ACTIVATE DRONES ]          │                                 │     │
    │  │  └───────────────────────────────┘                                 │     │
    │  │                                                                     │     │
    │  └─────────────────────────────────────────────────────────────────────┘     │
    │                                                                               │
    └───────────────────────────────────────────────────────────────────────────────┘
```

---

## Left Column: Program Configuration

The configuration column presents the five program parameters as a vertical list of labeled filter rows. Each row is independently focusable.

### General Filter Row Spec

- **Row height:** 56px (48px control + `sp-2` padding above)
- **Label:** `hud-sm` (16px) Bold, Text Secondary, above the control
- **Control background:** Panel BG Light (`#1A2736` at 90%)
- **Control border:** 1px solid Primary Dim `#007A63`
- **Control border radius:** 4px
- **Focused control:** Teal outline (2px), scale 1.02x

---

### 1. Target: Deposit Type

A dropdown/selector showing available resource types from the player's analyzed deposit pool.

- **Control:** Left/right arrow selector (same pattern as Fabricator recipe selector)
- **Options:** All resource types the player has analyzed at least one deposit of
- **Display:** Resource type name + Tier badge (e.g., "Scrap Metal · Tier 1")
- **Font:** `hud-md` (20px), Text Highlight
- **Empty state:** "No analyzed deposits yet" in Text Secondary, selector disabled

---

### 2. Minimum Purity

A star rating selector showing 1–5 stars. Player sets the minimum acceptable purity for drone targeting.

```
    MIN PURITY
    ◄  ★ ★ ★ ☆ ☆  ►    3 Stars minimum
```

- **Star display:** Same as Star Rating component in style guide — Amber filled, Neutral empty
- **Star size:** 24x24px (detail view scale)
- **"X Stars minimum" label:** `data` (18px) Mono, Text Secondary, right of stars
- **Left/right arrows:** Navigate min purity 1–5; 48x48px buttons
- **Selection meaning:** Only deposits with purity ≥ this value will be targeted

---

### 3. Tool Tier

Dropdown showing available tool tiers. Only tiers the player has unlocked appear as selectable.

- **Control:** Left/right arrow selector
- **Options:** "Tier 1 — Hand Drill", "Tier 2 — Pneumatic Drill" (if unlocked), etc.
- **Locked options:** Shown greyed out (40% opacity) with "(Locked)" suffix — player sees what exists but cannot select
- **Font:** `hud-md` (20px), Text Highlight for current selection

---

### 4. Extraction Radius

A horizontal slider defining how far from the ship drones will travel.

```
    EXTRACTION RADIUS
    ◄──────────●────────────►    250m
```

- **Slider width:** 400px
- **Track height:** 8px (compact bar spec)
- **Track background:** `#1A2736`
- **Fill (left of thumb):** Primary Teal `#00D4AA`
- **Thumb:** 20x20px circle, Teal fill, white border 2px
- **Min value:** 50m | **Max value:** 500m | **Step:** 25m
- **Current value label:** `data` (18px) Mono, Text Primary, right of slider
- **Gamepad:** D-pad left/right adjusts value by 25m per input; hold for continuous scroll

---

### 5. Priority Order

Dropdown defining which matching deposit the drones prefer when multiple valid targets exist.

- **Control:** Left/right arrow selector
- **Options:**
  - "Highest Purity First" (default)
  - "Nearest First"
  - "Highest Density First"
- **Font:** `hud-md` (20px), Text Highlight

---

### ACTIVATE DRONES Button

- **Text:** "ACTIVATE DRONES"
- **Size:** Full column width × 48px
- **Background:** Teal (`#00D4AA` at 20%) when enabled, greyed when no matching deposits
- **Border:** 1px solid Primary Teal when enabled
- **Focused:** Teal outline (2px)
- **Disabled state:** When matching deposit count is 0 (no analyzed deposits match the filter criteria)
- **Tooltip:** If disabled — "No analyzed deposits match your filter. Adjust criteria or go scan more deposits." in 280px Tooltip spec

---

## Right Column: Drone Status

### Header

- **Text:** "ACTIVE DRONES"
- **Font:** `hud-sm` (16px) Bold, Text Secondary
- **Divider:** 1px Neutral at 30%, `sp-2` below

### Drone Status Card (per active drone)

```
    ● Drone N  [State]
      Target: [Deposit ID]
      [State-specific detail]
```

- **Card background:** Panel BG `#0F1923` at 85%
- **Card border radius:** 4px
- **Card padding:** `sp-3` (12px)
- **Card gap:** `sp-2` (8px)

**State indicator (●):**
- Traveling: Amber `#FFB830`
- Extracting: Primary Teal `#00D4AA`
- Returning: Positive Green `#4ADE80`
- Idle: Neutral `#94A3B8`

**Drone N label:** `hud-sm` (16px) Bold, Text Primary
**State text:** `hud-xs` (14px) Text Secondary, right-aligned
**Detail lines:** `hud-xs` (14px) Text Secondary

### Analyzed Pool Stats

```
    Analyzed Deposits: 14
    Matching Program: 8
```

- **Font:** `hud-xs` (14px) Text Secondary
- **"Matching Program" count:** Teal if > 0, Amber if 0

### DEACTIVATE DRONES Button

- **Text:** "DEACTIVATE DRONES"
- **Size:** Full right-column width × 48px
- **Style:** Coral border (`#FF6B5A`) when focused — destructive action cue
- **Shown:** Only when drones are active
- **Gamepad focus:** Placed at bottom of right column

---

## Panel States

### No Active Program / No Analyzed Deposits

- All filter controls show empty/default state
- "No analyzed deposits yet" placeholder in deposit type selector
- ACTIVATE DRONES button disabled
- Drone status column shows: "No active drones. Activate a program to deploy drones."

### Program Configured, Inactive

- All filter controls show current values
- Matching count shows ≥ 1
- ACTIVATE DRONES button enabled
- Drone status column: "No active drones."

### Program Active

- Filter controls are locked (40% opacity, no interaction) — program is running
- ACTIVATE DRONES button replaced by "Program Running..." label
- Drone status column shows live drone cards
- DEACTIVATE DRONES button visible

---

## Open / Close Behavior

- **Open:** Screen dim 150ms fade + panel scale 0.95→1.0 + fade, 200ms ease-out
- **Close:** 150ms fade out
- **Focus on open:** First filter control (Deposit Type selector)

---

## Gamepad Navigation

```
    Left column (top to bottom):
    [Deposit Type] → [Min Purity] → [Tool Tier] → [Radius slider] → [Priority] → [ACTIVATE]

    Right column:
    [Drone 1 card] → [Drone 2 card] → [Pool stats] → [DEACTIVATE]

    D-pad left/right: switch between left and right column
    D-pad up/down: navigate rows within each column
    D-pad left/right (within selector/slider): adjust value
    Cancel/Back: close screen
```

---

## Implementation Notes

- Root: `CanvasLayer` layer 2
- Layout: `HBoxContainer` containing two `VBoxContainer` columns with `sp-6` gap
- Filter rows: Each is a reusable `Control` scene with label + control widget
- Dropdown selectors: Implemented as left/right arrow button pairs (same pattern as Fabricator recipe selector)
- Slider: `HSlider` node with custom theme (Teal thumb/fill per style guide)
- Drone status cards: Dynamically instantiated; bind to `DroneSystem.drone_state_changed(drone_id, state)` signal
- Pool stats: Bind to `DroneSystem.analyzed_pool_updated()` + recalculate matching count based on current filter values
- Input handling: On open, call InputManager to suppress gameplay inputs and set `MOUSE_MODE_VISIBLE`; on close, restore gameplay inputs and set `MOUSE_MODE_CAPTURED`. UI navigation handled within the panel via `set_input_as_handled()`. No `get_tree().paused`, no `PROCESS_MODE_WHEN_PAUSED`. Active drones continue operating while the UI is open — drone status cards update live.

---

## Exported Properties (for Gameplay Programmer)

| Property / Signal | Type | Purpose |
|-------------------|------|---------|
| `@export var drone_system: AutomationHub` | Node ref | Data source for program state and drone status |
| `signal activate_requested(program: DroneProgram)` | Signal | Emitted when ACTIVATE DRONES pressed; carries current filter values |
| `signal deactivate_requested()` | Signal | Emitted when DEACTIVATE DRONES pressed |
| `func refresh_status()` | Method | Force-refresh drone status cards |
