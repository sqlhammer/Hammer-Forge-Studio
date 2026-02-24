# Wireframe: Mining Minigame Overlay

**Component:** Mining Minigame — Line Tracing Overlay
**Ticket:** TICKET-0065
**Blocks:** TICKET-0070 (Mining minigame — line tracing for yield bonus)
**Last Updated:** 2026-02-24
**Reference:** `docs/design/systems/meaningful-mining.md` — Mining Minigame: Line Tracing section

---

## Purpose

After Phase 2 Analysis reveals the mining pattern on a deposit, the player may attempt the minigame while manually extracting. The player traces lit lines that appear on the deposit geometry within the normal mining interaction (hold to extract). Success yields +50% base bonus. Failure forfeits the bonus; the standard extraction proceeds uninterrupted.

This overlay must work within the existing first-person HUD without obscuring critical information (compass, battery bar). The minigame is never forced — it is an opt-in skill layer.

---

## Trigger and Lifecycle

1. Phase 2 Analysis completes: mining pattern lines illuminate on deposit geometry (3D world space, not HUD)
2. Player holds extract input — mining begins, mining progress bar shows as normal
3. The minigame overlay appears immediately after scan is complete (if a pattern was revealed)
4. Player traces each line by moving their crosshair over the lit segment (while still holding extract)
5. Each traced line turns Green (confirmed); an untraced line turns Red when the extraction completes
6. On extraction complete:
   - All lines traced → **Success**: yield bonus applied, success toast shown
   - Any lines untraced → **Miss**: base yield only, no penalty notification
7. Overlay dismisses 1 second after extraction completes

---

## Screen Region & Anchoring

The overlay is a **supplemental HUD layer** (Layer 1) positioned at the bottom-center of the screen, directly above the mining progress bar. It does not dim the screen or block gameplay.

- **Position:** Bottom-center, above mining progress bar
- **Anchor:** `center_bottom`
- **Offset from bottom edge:** 96px (progress bar is at 32px bottom; overlay sits 64px above it)
- **Z-order:** Layer 1 (same as existing HUD elements, rendered above the mining progress bar)

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Overlay panel width** | 320px |
| **Overlay panel height** | 80px |
| **Line indicator count** | 1–4 indicators (matches pattern complexity) |
| **Line indicator size** | 40x16px each |
| **Inter-indicator gap** | `sp-3` (12px) |

---

## Layout Diagram — Overlay Panel

```
    ┌──────────────────────── Full Screen (1920x1080) ─────────────────────────┐
    │                                                                           │
    │                                                                           │
    │                           [ crosshair + ]                                │
    │                        (deposit geometry with lit mining lines)           │
    │                                                                           │
    │                                                                           │
    │                                                                           │
    │                   ┌─────────────────────────────────────┐                │
    │                   │  TRACE PATTERN  (+50% bonus)        │                │
    │                   │  [▬] [▬] [░] [░]                    │                │
    │                   └─────────────────────────────────────┘                │
    │                   ↑ minigame overlay, bottom-center                      │
    │                   ↑ above mining progress bar                            │
    │                                                                           │
    │                   ┌─────────────────────────────────────┐                │
    │                   │█████████████████░░░░░░░░░░░░░░░░░░░░│                │
    │                   └─────────────────────────────────────┘                │
    │                   ↑ mining progress bar (unchanged from M3)              │
    │                                                                           │
    │  ⚡ ████████░░░░ 72%                                                      │
    │  ↑ battery bar (bottom-left, unchanged)                                  │
    └───────────────────────────────────────────────────────────────────────────┘
```

---

## Overlay Panel Component Specification

### Container Panel

- **Background:** Panel BG (`#0F1923` at 80% opacity)
- **Border:** 1px solid Primary Dim (`#007A63`)
- **Border radius:** 4px
- **Padding:** `sp-3` (12px)

### Header Row

```
    TRACE PATTERN    (+50% bonus)
```

- **"TRACE PATTERN":** `hud-sm` (16px) Bold, Text Primary (`#F1F5F9`)
- **"(+50% bonus)":** `hud-xs` (14px), Amber (`#FFB830`), `sp-2` left gap
- **Layout:** `HBoxContainer`

### Line Indicator Row

A horizontal row of indicator pips — one per pattern line (1–4 total). Each pip represents one line segment in the 3D pattern.

```
    [▬] [▬] [░] [░]
     ↑   ↑   ↑   ↑
    done done pending pending
    (Green) (Green) (Teal) (dim)
```

- **Pip size:** 40x16px
- **Pip background (pending):** `#1A2736` at 60% — faint, waiting for trace
- **Pip background (active/in-range):** Primary Teal `#00D4AA` — player's crosshair is on this line segment
- **Pip background (traced/done):** Positive Green `#4ADE80` — segment confirmed traced
- **Pip background (missed):** Coral `#FF6B5A` — segment not traced before extraction completed
- **Pip border radius:** 2px
- **Layout:** `HBoxContainer`, `sp-3` gap between pips

---

## World-Space Line Rendering

The lit lines on the 3D deposit geometry are rendered in world space, not HUD space. This spec covers only the HUD overlay. For line rendering:

- Lines appear as a Teal-lit overlay on the deposit mesh surface at extraction start
- Player traces a line by keeping their crosshair centered on the lit segment while holding extract
- A line is "traced" when the crosshair dwell-time on the segment exceeds the trace threshold (implementation detail for gameplay-programmer)
- Traced lines shift from Teal to Green in world space as they are confirmed

---

## Success State

Shown 0.2 seconds after extraction completes if all lines are traced.

```
    ┌─────────────────────────────────────────┐
    │  ✓ PATTERN COMPLETE  +50% YIELD         │
    │  [▬] [▬] [▬] [▬]   ← all Green         │
    └─────────────────────────────────────────┘
```

- **"✓ PATTERN COMPLETE":** `hud-sm` (16px) Bold, Positive Green (`#4ADE80`)
- **"+50% YIELD":** `data` (18px) Mono, Positive Green
- All pips turn Green simultaneously on success

---

## Miss State

Shown 0.2 seconds after extraction completes if any lines are untraced. No negative framing — just neutral acknowledgment.

```
    ┌─────────────────────────────────────────┐
    │  EXTRACTION COMPLETE                    │
    │  [▬] [▬] [░] [░]   ← mixed Green/Red   │
    └─────────────────────────────────────────┘
```

- **"EXTRACTION COMPLETE":** `hud-sm` (16px) Bold, Text Primary
- No "failed" or negative language — the miss is neutral
- Untraced pips: Coral `#FF6B5A`
- Traced pips: Positive Green `#4ADE80`

---

## Dismiss Behavior

- Overlay auto-dismisses 1 second after extraction completes (success or miss)
- Dismiss animation: fade out, 300ms
- If player moves away from deposit mid-extraction: extraction cancels normally (M3 behavior); overlay dismisses immediately with 150ms fade

---

## Conflict Zone Check

| Element | Position | Conflict with Minigame Overlay? |
|---------|----------|---------------------------------|
| Mining Progress Bar | Bottom-center, 32px from bottom | No — overlay sits 64px above progress bar |
| Battery Bar | Bottom-left | No — different corner |
| Compass | Top-center | No — different edge |
| Scanner Readout | Center-right | No — scanner dismisses when mining starts |
| Pickup Notifications | Center-right stacking | No — different horizontal region |

---

## Gamepad Notes

- No direct gamepad interaction — minigame is performed by aiming (right stick / mouse) while holding extract
- The overlay is purely informational for the gamepad player
- Line tracing input: crosshair aim — already mapped in existing input system, no new bindings required

---

## Accessibility

- All pip states distinguished by color AND fill level (full pip vs empty pip)
- Success state adds a checkmark icon (✓) — not color alone
- Miss state does not use red language or failure messaging — neutral "EXTRACTION COMPLETE" copy

---

## Implementation Notes

- Root: `Control` node inside existing HUD `CanvasLayer` (Layer 1)
- Anchor: `center_bottom`, positioned above mining progress bar
- Show: triggered by `MiningInteraction.minigame_started(line_count: int)` signal
- Line count: `line_count` drives pip instantiation at runtime (1–4 `ColorRect` nodes in `HBoxContainer`)
- Pip state update: `MiningInteraction.line_traced(line_index: int)` signal → update pip at that index to traced state
- Dismiss: `MiningInteraction.extraction_completed(success: bool)` signal → show result state → 1s `Tween` fade-out
- World-space line rendering is handled by **gameplay-programmer** in the extraction system; this overlay only reads the signals

---

## Exported Properties (for Gameplay Programmer)

| Property / Signal | Type | Purpose |
|-------------------|------|---------|
| `func show_minigame(line_count: int)` | Method | Initialize and show overlay with N pips |
| `func mark_line_traced(index: int)` | Method | Set pip at index to traced (Green) state |
| `func show_result(success: bool)` | Method | Show success or miss result state |
| `func dismiss()` | Method | Immediately hide overlay (e.g., extraction cancelled) |
