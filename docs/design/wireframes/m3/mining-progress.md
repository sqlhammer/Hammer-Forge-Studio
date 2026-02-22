# Wireframe: Mining Progress Indicator

**Component:** HUD Mining Progress Bar
**Ticket:** TICKET-0019
**Blocks:** TICKET-0026 (Mining interaction)
**Last Updated:** 2026-02-22

---

## Purpose

Shows extraction progress during hold-to-mine interaction. Appears when the player begins mining a deposit and fills over the extraction duration. Communicates active mining state and time remaining.

---

## Screen Region & Anchoring

- **Position:** Center of screen, slightly below crosshair
- **Anchor:** `center`
- **Offset from center:** +60px downward (below crosshair, above bottom HUD elements)

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Bar width** | 240px |
| **Bar height** | 12px |
| **Total element height** | ~40px (label + bar) |

---

## Layout Diagram

```
                        Screen center
                            │
                            +  ← crosshair (not part of this component)
                            │
                          60px gap
                            │
                     ┌─────────────┐
                     │  EXTRACTING  │  ← status label
                     │  ███████░░░  │  ← progress bar
                     └─────────────┘

    Detailed layout:

                      EXTRACTING
               ┌────────────────────────┐
               │████████████░░░░░░░░░░░░│   12px tall
               └────────────────────────┘
                      240px wide

    Centered horizontally on screen
```

---

## Component Specification

### Status Label

- **Text:** "EXTRACTING" during active mining
- **Font:** `hud-sm` (16px) Medium
- **Color:** Primary Teal (`#00D4AA`)
- **Position:** Centered above the progress bar, `sp-1` (4px) gap
- **Letter spacing:** +1px (subtle spread for readability)

### Progress Bar

- **Width:** 240px
- **Height:** 12px
- **Background (empty portion):** `#1A2736` at 80% opacity
- **Fill:** Left-to-right, Primary Teal (`#00D4AA`)
- **Fill glow:** Subtle teal glow (2px blur) on the fill's leading edge — gives a "laser cutting" feel
- **Border radius:** 3px
- **No border**
- **Fill rate:** Linear, proportional to extraction time remaining

---

## States

| State | Visual |
|-------|--------|
| **Mining active** | Label reads "EXTRACTING", bar fills left-to-right at extraction rate |
| **Mining complete** | Bar reaches 100%, label changes to "COMPLETE" in Positive Green (`#4ADE80`), holds for 0.5s, then component fades out (300ms) |
| **Mining interrupted** (player releases input) | Bar freezes, then the entire component fades out over 300ms. Progress is lost (hold-to-extract requires continuous hold) |
| **Battery depleted during mining** | Bar freezes, label changes to "NO CHARGE" in Accent Coral (`#FF6B5A`), holds 1s, then fades out |

---

## Appear / Dismiss Behavior

| Event | Animation |
|-------|-----------|
| **Mining begins** (player starts holding extract input) | Fade-in 150ms; bar starts at 0% |
| **Mining completes** | "COMPLETE" label, hold 0.5s, fade-out 300ms |
| **Mining interrupted** | Immediate freeze, fade-out 300ms |
| **Battery runs out** | "NO CHARGE" label, hold 1s, fade-out 300ms |

---

## Gamepad Notes

- Display-only; no direct interaction
- Centered position ensures visibility regardless of TV size
- 12px bar + 16px label readable at TV viewing distance
- Player holds the mining input button continuously; visual confirms input is being registered

---

## Implementation Notes

- Use a `VBoxContainer` (centered) with `Label` + themed `ProgressBar`
- Bind to mining system's `extraction_started`, `extraction_progress`, `extraction_completed`, `extraction_interrupted` signals
- Fill glow: either a `ShaderMaterial` with an emission edge, or a simple `ColorRect` overlay at the fill's leading edge with a teal `Light2D` or glow texture
- The component should be a reusable scene — same visual can potentially be used for Phase 2 scan-in-progress (different label text: "ANALYZING")
- Progress rate is driven by the mining system (depends on deposit size and tool tier); UI only reads the normalized 0.0–1.0 progress value
