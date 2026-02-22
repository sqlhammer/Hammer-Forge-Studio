# Wireframe: Battery Bar

**Component:** HUD Battery Indicator
**Ticket:** TICKET-0019
**Blocks:** TICKET-0027 (HUD — battery bar + notifications)
**Last Updated:** 2026-02-22

---

## Purpose

Always-visible suit energy indicator. Shows current battery charge as a percentage fill. Communicates four distinct visual states: full, draining (normal use), critical (low charge), and empty (depleted).

---

## Screen Region & Anchoring

- **Position:** Bottom-left of screen
- **Anchor:** `bottom_left`
- **Offset from left edge:** 32px (safe area)
- **Offset from bottom edge:** 32px (safe area)

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Total width** | 200px |
| **Total height** | 48px (icon + bar + label) |
| **Bar width** | 160px |
| **Bar height** | 10px |
| **Icon size** | 24x24px |

---

## Layout Diagram

```
    Screen bottom-left corner (32px margins)

    ┌──────────────────────────────────────┐
    │  ⚡  ████████████████░░░░░░   72%    │
    │  icon   progress bar         label   │
    └──────────────────────────────────────┘

    Detailed breakdown:

    ⚡        ████████████████░░░░░░░░    72%
    ↑         ↑                            ↑
    Battery   Fill (teal)  Empty (dark)    Percentage
    Icon                                   readout
    24x24px   160px wide, 10px tall        data font

    Horizontal layout (left to right):
    [Icon 24px] [sp-2 gap 8px] [Bar 160px] [sp-2 gap 8px] [Label ~40px]
```

---

## Component Specification

### Battery Icon

- **Style:** Lightning bolt line icon, 24x24px
- **Color:** Changes with battery state (see States table below)
- **Position:** Left-aligned, vertically centered with bar

### Progress Bar

- **Width:** 160px
- **Height:** 10px
- **Background (empty portion):** `#1A2736`
- **Fill:** Left-to-right fill representing current charge percentage
- **Fill color:** Changes with battery state (see States table)
- **Border radius:** 2px
- **No border**
- **Fill transitions smoothly** as battery drains (no jumps)

### Percentage Label

- **Font:** `data` (18px) Mono
- **Color:** Same as icon color (state-dependent)
- **Format:** `XX%` — integer, no decimals (e.g., `100%`, `72%`, `15%`, `0%`)
- **Position:** Right of bar, vertically centered

---

## States

| State | Condition | Icon Color | Fill Color | Label Color | Special Behavior |
|-------|-----------|------------|------------|-------------|------------------|
| **Full** | 100% charge | Positive Green `#4ADE80` | Positive Green `#4ADE80` | Positive Green `#4ADE80` | Static — no animation |
| **Normal** | 26%–99% | Primary Teal `#00D4AA` | Primary Teal `#00D4AA` | Primary Teal `#00D4AA` | Fill decreases smoothly as battery drains |
| **Critical** | 1%–25% | Accent Coral `#FF6B5A` | Accent Coral `#FF6B5A` | Accent Coral `#FF6B5A` | Slow pulse animation (opacity 70%→100% over 1.5s, repeating) |
| **Empty** | 0% charge | Accent Coral `#FF6B5A` | — (no fill) | Accent Coral `#FF6B5A` | Icon flashes (0.5s on, 0.5s off) for 3 seconds, then holds at 50% opacity |

### State Transitions

- Normal → Critical: Color shifts from teal to coral over 300ms when crossing the 25% threshold
- Critical → Empty: Flash animation triggers immediately on reaching 0%
- Empty → Normal (recharging at ship): Fill animates upward; color returns to teal when crossing 26%

---

## Recharging Visual

When the player is at a ship recharge point and battery is refilling:

- Fill bar animates upward at the recharge rate
- A subtle **shimmer/sweep highlight** (lighter teal, 30% opacity) travels left-to-right across the filled portion on a 1-second loop — indicates active recharging
- Percentage label ticks upward in real-time

---

## Gamepad Notes

- Battery bar is display-only; no direct interaction
- Icon + bar + percentage triple-encoding ensures readability without relying on color alone
- 10px bar height + 18px label font validated for TV viewing distance

---

## Implementation Notes

- Use an `HBoxContainer` with `TextureRect` (icon) + `ProgressBar` (custom themed) + `Label` (percentage)
- Bind to the suit battery system's `charge_changed` signal
- Critical threshold (25%) should be a constant defined in the battery system, not hardcoded in UI
- Pulse and flash animations via `Tween` — create the tween on state entry, kill on state exit
- Recharge shimmer: use a `ShaderMaterial` on the ProgressBar fill with a scrolling highlight UV, or a simple `TextureRect` overlay with horizontal offset animation
