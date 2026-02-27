# Wireframe: Fuel Gauge HUD

**Component:** Ship Fuel Level Indicator (Persistent HUD)
**Ticket:** TICKET-0165
**Blocks:** TICKET-0169 (Fuel consumption HUD — low-fuel warning, tank gauge display)
**Last Updated:** 2026-02-27

---

## Purpose

Always-visible ship fuel indicator showing current fuel tank level as a percentage fill. Communicates three distinct visual states: normal, warning (low fuel), and empty (no fuel). Positioned at bottom-center to avoid conflict with the suit battery bar (bottom-left) and ship globals panel (bottom-right).

The fuel gauge uses identical visual language to the suit battery bar — same icon-bar-label structure, same state-transition color palette, same animation conventions. Players familiar with the battery bar will immediately understand fuel.

---

## Relationship to Other HUD Elements

| Element | Position | Conflict? |
|---------|----------|-----------|
| Suit Battery Bar | Bottom-left | No — different corner |
| Compass Bar | Top-center | No — different edge |
| Ship Globals Panel | Bottom-right | No — different corner; ship globals only visible inside ship |
| Mining Progress | Center (below crosshair) | No — different region |
| Scanner Readout | Center-right | No — different region |
| Interaction Prompt HUD | Bottom (center/right) | Monitor at layout validation — fuel gauge at bottom-center should not overlap interaction prompt labels which appear above the crosshair area |

---

## Screen Region & Anchoring

- **Position:** Bottom-center of screen
- **Anchor:** `bottom_center`
- **Horizontal:** Centered on screen (X = 960px at 1080p)
- **Offset from bottom edge:** 32px (safe area)

**Rationale:** Bottom-left is occupied by the suit battery bar. Bottom-right is occupied by the ship globals panel (in-ship). Bottom-center is unused and provides natural spatial separation: suit resource (left) | navigation resource (center) | ship systems (right).

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Total width** | 200px |
| **Total height** | 48px (icon + bar + label row) |
| **Bar width** | 160px |
| **Bar height** | 10px |
| **Icon size** | 24x24px |

Matches the suit battery bar dimensions exactly — consistent visual weight in the HUD.

---

## Layout Diagram

```
    Screen bottom-center (32px bottom margin, horizontally centered)

    ┌──────────────────────────────────────┐
    │  ⛽  ████████████████░░░░░░   72%    │
    │  icon   progress bar         label   │
    └──────────────────────────────────────┘

    Detailed breakdown:

    ⛽        ████████████████░░░░░░░░    72%
    ↑         ↑                            ↑
    Fuel      Fill (teal)  Empty (dark)    Percentage
    Icon                                   readout
    24x24px   160px wide, 10px tall        data font

    Horizontal layout (left to right):
    [Icon 24px] [sp-2 gap 8px] [Bar 160px] [sp-2 gap 8px] [Label ~40px]

    Updated M8 HUD layout:

    ┌──────────────────────────────────────────────────────────────────────────────┐
    │  ┌─────────────────────────────────────────┐                                 │
    │  │           COMPASS BAR (top-center)      │                                 │
    │  └─────────────────────────────────────────┘                                 │
    │                                                                              │
    │                              +  (crosshair)                                  │
    │                                                                              │
    │  ┌──────────────────────┐   ┌────────────────────┐   ┌──────────────────┐    │
    │  │ ⚡ ████████░░ 72%    │   │ ⛽ ███████░░ 65%  │   │  SHIP STATUS     │    │
    │  └──────────────────────┘   └────────────────────┘   │  (in-ship only)  │    │
    │  battery bar (bottom-left)    fuel gauge (center)     └──────────────────┘    │
    └──────────────────────────────────────────────────────────────────────────────┘
```

---

## Component Specification

### Fuel Icon

- **Style:** Hexagonal fuel cell line icon, 24x24px (matches the Fuel Cell item icon shape; see HUD icon style guide)
- **Color:** Changes with fuel state (see States table below)
- **Position:** Left-aligned, vertically centered with bar

### Progress Bar

- **Width:** 160px
- **Height:** 10px
- **Background (empty portion):** `#1A2736`
- **Fill:** Left-to-right fill representing current fuel level percentage
- **Fill color:** Changes with fuel state (see States table)
- **Border radius:** 2px
- **No border**
- **Fill transitions smoothly** as fuel is consumed or replenished

### Percentage Label

- **Font:** `data` (18px) Mono
- **Color:** Same as icon color (state-dependent)
- **Format:** `XX%` — integer, no decimals (e.g., `100%`, `65%`, `22%`, `0%`)
- **Position:** Right of bar, vertically centered

---

## States

| State | Condition | Icon Color | Fill Color | Label Color | Special Behavior |
|-------|-----------|------------|------------|-------------|------------------|
| **Full** | 100% charge | Positive Green `#4ADE80` | Positive Green `#4ADE80` | Positive Green `#4ADE80` | Static — no animation |
| **Normal** | 26%–99% | Primary Teal `#00D4AA` | Primary Teal `#00D4AA` | Primary Teal `#00D4AA` | Fill decreases as fuel is consumed |
| **Low** | 1%–25% | Amber `#FFB830` | Amber `#FFB830` | Amber `#FFB830` | Slow pulse animation (opacity 70%→100% over 1.5s, repeating). Consistent with battery bar amber warning pattern (M7 TICKET-0122) |
| **Empty** | 0% fuel | Coral `#FF6B5A` | — (no fill) | Coral `#FF6B5A` | Icon flashes (0.5s on, 0.5s off) for 3 seconds, then holds at 50% opacity. Identical to battery Empty state behavior |

### State Transitions

- Normal → Low: Color shifts teal to amber over 300ms when crossing the 25% threshold
- Low → Empty: Flash animation triggers immediately on reaching 0%
- Empty → Normal (refueling at ship): Fill animates upward; color returns to teal when crossing 26%

---

## Visibility Rules

- **Always visible** during gameplay (HUD Layer 1) — fuel is a persistent navigation resource
- **Not hidden** when entering/exiting the ship — fuel level is always relevant
- Excluded from HUD suppression contexts where full overlay panels are open (Fabricator, Recycler, navigation console, etc.) — consistent with all other HUD elements

---

## Refueling Visual

When the player refuels at the ship (adding Fuel Cells to the tank):

- Fill bar animates upward at the refuel rate
- A subtle **shimmer/sweep highlight** (lighter teal, 30% opacity) travels left-to-right across the filled portion on a 1-second loop — indicates active refueling (identical to battery recharge shimmer)
- Percentage label ticks upward in real-time

---

## Gamepad Notes

- Fuel gauge is display-only; no direct interaction
- Icon + bar + percentage triple-encoding ensures readability without relying on color alone
- 10px bar height + 18px label font validated for TV viewing distance at 1080p
- Critical low-fuel is communicated by amber pulse (motion cue) + amber color + label value — all three independent signals

---

## Implementation Notes

- Use an `HBoxContainer` with `TextureRect` (icon) + `ProgressBar` (custom themed) + `Label` (percentage)
- Root: anchor to `bottom_center` inside the existing HUD `CanvasLayer` (layer 1)
- Bind to the fuel system's `fuel_changed(new_level: float, max_level: float)` signal
- Low-fuel threshold (25%) should be a constant defined in the fuel system, not hardcoded in UI
- Pulse and flash animations via `Tween` — create tween on state entry, kill on state exit
- Recharge shimmer: `ShaderMaterial` or `TextureRect` overlay with horizontal offset animation (identical implementation to battery bar shimmer)
- Reuse the battery bar `ProgressBar` theme — no separate theme resource needed; state colors applied via `theme_override_colors`

---

## Exported Properties (for Gameplay Programmer — TICKET-0169)

| Property / Signal | Type | Purpose |
|-------------------|------|---------|
| `@export var fuel_system: FuelSystem` | Node ref | Data source for current fuel level and max capacity |
| `func set_fuel_level(current: float, maximum: float)` | Method | Called by fuel system to update display; internally computes percentage |
