# Wireframe: Compass

**Component:** HUD Compass Bar
**Ticket:** TICKET-0019
**Blocks:** TICKET-0024 (Scanner Phase 1 — ping and compass)
**Last Updated:** 2026-02-22

---

## Purpose

Horizontal compass bar showing cardinal directions and scanner ping markers with distance readouts. Always visible during first-person gameplay. Primary navigation tool after Phase 1 ping.

---

## Screen Region & Anchoring

- **Position:** Top-center of screen
- **Anchor:** `center_top`
- **Offset from top edge:** 32px (safe area margin)
- **Centered horizontally**

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Bar width** | 600px |
| **Bar height** | 32px |
| **Total element height** (including markers) | 56px |

---

## Layout Diagram

```
                    Screen top edge (32px safe margin)
                    |
    ┌───────────────────────────────────────────────────────┐
    │  W         NW         N         NE         E          │  ← 32px tall bar
    └───────────────────────────────────────────────────────┘
                       ▲                    ▲
                       │                    │
                    Center                Ping
                    Tick                  Marker

    Bar detail (zoomed):
    ┌──────────────────────────────────────────────────────────────┐
    │  ·  ·  W  ·  ·  ·  · NW ·  ·  ·  ·  N  ·  ·  ·  · NE ·  ·│
    └──────────────────────────────────────────────────────────────┘
                              |
                           ▼ (center tick mark, 8px below bar)

    Ping marker (when active):
    ┌──────────────────────────────────────────────────────────────┐
    │  ·  ·  W  ·  ·  ·  · NW ·  ·  ·  ·  N  ·  ·  ▼  · NE ·  ·│
    └──────────────────────────────────────────────────────────────┘
                                              │
                                            47m    ← distance readout
```

---

## Component Specification

### Compass Bar

- **Background:** Panel BG (`#0F1923` at 70% opacity) — slightly more transparent than standard panels for minimal visual weight
- **Border:** None (borderless for minimal HUD feel)
- **Border radius:** 4px
- **The bar shows a ~120-degree horizontal slice** of the full 360-degree compass, scrolling as the player rotates

### Cardinal Labels

- **Font:** `hud-sm` (16px) Regular
- **Color:** Text Secondary (`#94A3B8`) for intercardinals (NE, NW, SE, SW)
- **Color:** Text Primary (`#F1F5F9`) for cardinals (N, S, E, W)
- **N is always bold** (`hud-sm` Medium) for quick orientation
- **Spacing:** Cardinals at 90-degree intervals; intercardinals at 45-degree intervals
- **Minor ticks:** Small 4px vertical lines at 15-degree intervals, color Neutral at 40% opacity

### Center Indicator

- **Style:** Small downward-pointing triangle, 8px wide, 6px tall
- **Color:** Text Primary (`#F1F5F9`)
- **Position:** Centered below the compass bar, 2px gap
- **Purpose:** Shows the player's exact facing direction

### Ping Markers

- **Style:** Downward-pointing triangle, 10px wide, 8px tall
- **Color:** Primary Teal (`#00D4AA`)
- **Position:** Along the compass bar at the bearing of the detected deposit
- **Appear animation:** Fade-in over 150ms when a new ping result registers
- **Fade behavior:** Markers persist for 60 seconds (gameplay tunable), then fade out over 2 seconds
- **Nearest marker:** Brighter (100% opacity); other markers at 70% opacity
- **Max simultaneous markers:** 10 (design tested; beyond 10, oldest markers are culled)

### Distance Readout

- **Visibility:** Shown below a ping marker **only when the player's facing direction is within ~15 degrees of the marker's bearing** (i.e., roughly looking at it)
- **Font:** `data` (18px) Mono
- **Color:** Primary Teal (`#00D4AA`)
- **Format:** `XXm` (e.g., `47m`, `132m`) — integer meters, no decimals
- **Position:** Centered below the ping marker triangle, 2px gap
- **Max one distance readout visible at a time** — if multiple markers are near center, show only the nearest marker's distance

---

## States

| State | Behavior |
|-------|----------|
| **No pings active** | Compass bar visible with cardinal labels and center tick only. Clean, minimal |
| **Pings active** | Teal markers appear at bearings. Distance readout appears when facing a marker |
| **Markers fading** | Markers gradually reduce opacity from 100%→0% over final 2 seconds of their lifetime |
| **All markers expired** | Returns to "no pings active" state |

---

## Gamepad Notes

- Compass is display-only; no direct interaction
- Must be readable at TV viewing distance — cardinal labels at 16px minimum is validated for 3m/10ft at 1080p
- Distance readout at 18px mono ensures numerical legibility at distance

---

## Implementation Notes

- Use a `Control` node with a `SubViewport` or `_draw()` override for the scrolling compass strip
- Cardinal positions are calculated from the player camera's Y-rotation
- Ping marker positions are calculated as bearing offsets from the player's current facing
- Store ping data in an array managed by the scanner system; compass reads from it each frame
- Compass does NOT manage ping lifecycle — the scanner system creates/expires pings; compass only displays
