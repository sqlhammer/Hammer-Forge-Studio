# Wireframe: Scanner Phase 2 Analysis Readout

**Component:** Scanner Analysis HUD Overlay
**Ticket:** TICKET-0019
**Blocks:** TICKET-0025 (Scanner Phase 2 — analyze deposit)
**Last Updated:** 2026-02-22

---

## Purpose

Displays the results of a Phase 2 scanner analysis on a deposit. Shows purity rating (1-5 stars), quantity density (Low/Med/High), and energy cost to fully mine. Appears after the player completes a hold-to-analyze action on a deposit.

---

## Screen Region & Anchoring

- **Position:** Center-right of screen, offset toward the analyzed deposit
- **Anchor:** `center_right`
- **Offset from right edge:** 80px
- **Vertically centered** with slight upward bias (-40px from center) to avoid obscuring the crosshair area

### Why center-right?

The player must be looking directly at the deposit to analyze it (close range, first-person). The readout appears to the right of the player's view to avoid covering the deposit itself. The data panel "floats" beside the object being analyzed.

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Panel width** | 260px |
| **Panel height** | ~160px (content-driven) |
| **Star icon size** | 20x20px |

---

## Layout Diagram

```
                                Screen center-right area
                                │
                    ┌───────────────────────────┐
                    │  ◆ SCAN RESULTS           │  ← header
                    │  ─────────────────────     │
                    │                            │
                    │  Purity    ★★★★☆           │  ← star rating
                    │  Density   Medium          │  ← text label
                    │  Energy    34%             │  ← battery cost
                    │                            │
                    └───────────────────────────┘

    Detailed layout:

    ┌──────────────────────────────────────┐
    │  sp-3 padding                        │
    │  ┌─────────────────────────────────┐ │
    │  │ ◆  SCAN RESULTS                 │ │  ← hud-md bold, Text Primary
    │  │ ────────────────────────────     │ │  ← 1px divider, Neutral
    │  │                                  │ │
    │  │ Purity     ★ ★ ★ ★ ☆            │ │  ← label: hud-sm, Secondary
    │  │                                  │ │     stars: 20px, Amber filled
    │  │ Density    Medium                │ │  ← label: hud-sm, Secondary
    │  │                                  │ │     value: hud-md, Text Primary
    │  │ Energy     34%  ⚡               │ │  ← label: hud-sm, Secondary
    │  │                                  │ │     value: data-lg, Amber
    │  └─────────────────────────────────┘ │     icon: 16px battery micro-icon
    │  sp-3 padding                        │
    └──────────────────────────────────────┘
```

---

## Component Specification

### Panel

- **Background:** Panel BG (`#0F1923` at 85%)
- **Border:** 1px solid Primary Dim (`#007A63`)
- **Border radius:** 4px
- **Padding:** `sp-3` (12px) all sides

### Header Row

- **Icon:** Small diamond `◆` or scanner icon, 16px, Primary Teal
- **Text:** "SCAN RESULTS" — `hud-md` (20px) Bold, Text Primary
- **Divider:** 1px horizontal line, Neutral (`#94A3B8`) at 40% opacity, `sp-2` (8px) margin below

### Data Rows

Each row is a label-value pair arranged in a two-column layout:

| Element | Style |
|---------|-------|
| **Label** (left column) | `hud-sm` (16px) Regular, Text Secondary. Fixed width: 80px |
| **Value** (right column) | Varies by row (see below) |
| **Row gap** | `sp-3` (12px) between rows |

### Purity Row

- **Label:** "Purity"
- **Value:** 5 star icons in a row
  - Filled stars: Amber (`#FFB830`), 20x20px
  - Empty stars: Neutral (`#94A3B8`) at 40% opacity, 20x20px
  - Gap between stars: `sp-1` (4px)
  - Example: 4-star purity → ★★★★☆

### Density Row

- **Label:** "Density"
- **Value:** Text label — `hud-md` (20px) Medium, Text Primary
- **Possible values:** "Low", "Medium", "High"
- **Color override:** "Low" uses Text Secondary, "Medium" uses Text Primary, "High" uses Primary Teal

### Energy Row

- **Label:** "Energy"
- **Value:** Percentage of battery required — `data-lg` (22px) Mono Medium, Amber (`#FFB830`)
- **Suffix:** Small battery icon (16px) inline after the percentage, same color
- **Format:** `XX%` (e.g., `34%`, `78%`, `12%`)
- **Color override:** If energy cost > 75% of current battery, value turns Accent Coral (`#FF6B5A`) as a warning

---

## Appear / Dismiss Behavior

| Event | Animation |
|-------|-----------|
| **Scan completes** | Panel slides in from right (16px travel) + fades in, 200ms ease-out |
| **Player walks away** (>5m from deposit) | Panel fades out, 300ms |
| **Player starts mining** the deposit | Panel fades out, 200ms (mining progress replaces it) |
| **Player pings again** (new Phase 1) | Panel fades out, 200ms |

The readout persists until the player leaves the deposit area or takes a new action. It does not auto-dismiss on a timer.

---

## States

| State | Behavior |
|-------|----------|
| **Scanning in progress** | Readout NOT visible — see mining progress wireframe for the hold-to-scan indicator |
| **Scan complete** | Readout appears with full data |
| **Insufficient energy warning** | Energy row value turns coral; no additional elements |
| **Deposit already analyzed** | Re-approaching a previously scanned deposit shows the readout immediately (no re-scan needed) |

---

## Gamepad Notes

- Readout is display-only during analysis; no direct interaction
- Font sizes validated for TV viewing distance (20px labels, 22px data values)
- The panel position (center-right) avoids the gamepad cursor area and leaves the deposit visible on-screen

---

## Implementation Notes

- Use a `PanelContainer` with a `VBoxContainer` for the data rows
- Each row: `HBoxContainer` with `Label` (fixed min-width) + value widget
- Star rating: custom `HBoxContainer` with 5 `TextureRect` nodes, toggling between filled/empty textures
- Bind to scanner system's `analysis_completed` signal; populate data from the deposit's scanned properties
- Energy warning threshold: compare deposit energy cost against current battery level (read from battery system)
- Position the panel via code relative to the screen center, not world-space — it's a HUD overlay, not a 3D label
