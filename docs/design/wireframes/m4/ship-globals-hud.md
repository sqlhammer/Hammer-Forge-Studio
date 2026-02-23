# Wireframe: Ship Globals HUD

**Component:** Ship Global Variable Indicators (In-Ship HUD)
**Ticket:** TICKET-0042
**Blocks:** TICKET-0046 (HUD — ship globals display)
**Last Updated:** 2026-02-23

---

## Purpose

Displays the ship's four global variables (Power, Integrity, Heat, Oxygen) when the player is inside the ship. These indicators are the player's primary awareness of ship health. They must be visible at a glance without competing with the existing suit battery bar (bottom-left) or compass (top-center).

---

## Visibility Rules

- **Shown:** When the player is inside the ship interior
- **Hidden:** When the player is outside the ship (field exploration)
- **Co-exists with:** Compass (top-center), Battery Bar (bottom-left) — both remain visible inside the ship
- **Does NOT replace** the battery bar — suit battery and ship power are distinct systems

---

## Screen Region & Anchoring

- **Position:** Bottom-right of screen
- **Anchor:** `bottom_right`
- **Offset from right edge:** 32px (safe area)
- **Offset from bottom edge:** 32px (safe area)

**Rationale:** Bottom-left is occupied by battery bar. Top-center is occupied by compass. Bottom-right is the largest unused HUD region and provides natural visual balance opposite the battery bar.

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Total width** | 220px |
| **Total height** | ~180px (4 bars stacked with gaps) |
| **Individual bar width** | 120px |
| **Individual bar height** | 8px (compact) |
| **Icon size** | 20x20px |
| **Label width** | ~40px |

---

## Layout Diagram

```
    Screen bottom-right corner (32px margins)

    ┌──────────────────────────────────────┐
    │  SHIP STATUS                         │
    │  ──────────────────────              │
    │                                      │
    │  [P]  ████████████░░░░░░░░   72%     │
    │  [I]  ██████████████████░░   90%     │
    │  [H]  ██████░░░░░░░░░░░░░   32%     │
    │  [O]  ████████████████████  100%     │
    │                                      │
    └──────────────────────────────────────┘

    Detailed breakdown (single row):

    [P]       ████████████░░░░░░░░     72%
     ^        ^                         ^
     Icon     Fill bar (120px)         Value
     20x20px  8px tall, state-colored  data font

    Horizontal layout per row:
    [Icon 20px] [sp-2 gap] [Bar 120px] [sp-2 gap] [Label ~40px]

    Vertical stacking:
    [Title 24px]
    [sp-3 divider gap]
    [Row: Power]     38px
    [sp-2 gap]
    [Row: Integrity] 38px
    [sp-2 gap]
    [Row: Heat]      38px
    [sp-2 gap]
    [Row: Oxygen]    38px
```

---

## Component Specification

### Container Panel

- **Background:** Panel BG (`#0F1923` at 85%)
- **Border:** 1px solid `#1A2736`
- **Border radius:** 4px
- **Padding:** `sp-3` (12px)

### Title

- **Text:** "SHIP STATUS"
- **Font:** `hud-sm` (16px) Bold
- **Color:** Text Secondary (`#94A3B8`)
- **Divider:** 1px horizontal line, Neutral at 30% opacity, `sp-2` (8px) margin below

### Variable Icons

Each variable uses a distinct icon for color-blind accessibility:

| Variable | Icon | Description |
|----------|------|-------------|
| **Power** | `[P]` Lightning bolt (rotated 15deg from battery icon for distinction) | Electrical output |
| **Integrity** | `[I]` Shield outline | Structural health |
| **Heat** | `[H]` Thermometer | Internal temperature |
| **Oxygen** | `[O]` Circle with dot (atom/molecule symbol) | Atmospheric viability |

- **Size:** 20x20px
- **Color:** Matches the bar fill color (state-dependent)
- **Style:** Line icons, 2px stroke, rounded caps (per style guide)

### Progress Bars

- **Width:** 120px
- **Height:** 8px (compact per style guide)
- **Background (empty):** `#1A2736`
- **Fill direction:** Left-to-right
- **Border radius:** 2px
- **No border**

### Value Labels

- **Font:** `data` (18px) Mono
- **Color:** Matches bar fill color (state-dependent)
- **Format:** Integer percentage `XX%` — no decimals
- **Alignment:** Right-aligned

---

## Variable-Specific Color States

### Power

| State | Condition | Fill Color | Notes |
|-------|-----------|------------|-------|
| **Healthy** | 50%–100% | Primary Teal `#00D4AA` | Normal operation |
| **Low** | 20%–49% | Amber `#FFB830` | Modules straining |
| **Critical** | 0%–19% | Coral `#FF6B5A` | Non-essential modules shutting down; slow pulse (1.5s) |

### Integrity

| State | Condition | Fill Color | Notes |
|-------|-----------|------------|-------|
| **Healthy** | 75%–100% | Primary Teal `#00D4AA` | Hull in good shape |
| **Damaged** | 30%–74% | Amber `#FFB830` | Noticeable damage |
| **Critical** | 0%–29% | Coral `#FF6B5A` | Near destruction; slow pulse (1.5s) |

### Heat

Heat is a dual-range indicator — both extremes are dangerous.

| State | Condition | Fill Color | Notes |
|-------|-----------|------------|-------|
| **Safe** | 25%–75% | Primary Teal `#00D4AA` | Comfortable range |
| **Cold** | 0%–24% | Ice Blue `#60A5FA` | Cold biome exposure; modules malfunction |
| **Hot** | 76%–100% | Coral `#FF6B5A` | Overheating; modules malfunction |

**Special behavior:** The heat bar fills from the left edge at 0% (freezing) to right edge at 100% (overheating). A subtle tick mark at the 25% and 75% positions indicates the safe zone boundaries.

### Oxygen

| State | Condition | Fill Color | Notes |
|-------|-----------|------------|-------|
| **Healthy** | 50%–100% | Primary Teal `#00D4AA` | Breathable |
| **Low** | 20%–49% | Amber `#FFB830` | Degraded atmosphere |
| **Critical** | 0%–19% | Coral `#FF6B5A` | Countdown to health damage; slow pulse (1.5s) |

---

## Show/Hide Animation

| Event | Animation |
|-------|-----------|
| **Enter ship** | Panel slides in from right edge, 200ms ease-out, 50ms delay after transition |
| **Exit ship** | Panel slides out to right edge, 150ms ease-in |

---

## Conflict Zone Check

| Element | Position | Conflict with Ship Globals? |
|---------|----------|-----------------------------|
| Battery Bar | Bottom-left | No — opposite corner |
| Compass | Top-center | No — different edge |
| Mining Progress | Center | No — different region |
| Scanner Readout | Center-right | No — scanner not active inside ship |
| Pickup Notifications | Right-stacking | Possible if player picks up items inside ship. Resolution: notifications stack above the ship status panel with `sp-4` (16px) gap |

---

## Gamepad Notes

- Ship globals HUD is display-only; no direct interaction
- Icon + bar + percentage triple-encoding for accessibility (color-blind safe)
- 8px bar height + 18px label is validated for TV distance readability
- Critical pulse animation provides non-color motion cue

---

## Implementation Notes

- Root: `PanelContainer` anchored bottom-right inside the existing HUD `CanvasLayer` (layer 1)
- Each variable row: `HBoxContainer` with `TextureRect` (icon) + `ProgressBar` (themed) + `Label` (value)
- All four rows inside a `VBoxContainer` with `sp-2` separation
- Bind to `ShipState` autoload signals: `power_changed`, `integrity_changed`, `heat_changed`, `oxygen_changed`
- Critical pulse: `Tween` cycling opacity 70%->100% over 1.5s, created on entering critical state, killed on exit
- Heat tick marks: Two thin (1px) vertical lines at 25% and 75% positions overlaid on the bar background using `ColorRect` nodes
- Show/hide controlled by a signal from the ship entry/exit system (e.g., `player_entered_ship` / `player_exited_ship`)
