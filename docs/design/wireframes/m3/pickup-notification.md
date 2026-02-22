# Wireframe: Resource Pickup Notification

**Component:** HUD Pickup Toast
**Ticket:** TICKET-0019
**Blocks:** TICKET-0027 (HUD — battery bar + notifications)
**Last Updated:** 2026-02-22

---

## Purpose

Brief popup notification that appears when the player collects a resource. Shows the item name and quantity added to inventory. Appears and auto-dismisses without player interaction.

---

## Screen Region & Anchoring

- **Position:** Right side of screen, vertically centered
- **Anchor:** `center_right`
- **Offset from right edge:** 32px (safe area)
- **Vertical position:** Centered, stacking downward for multiple simultaneous pickups

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Toast width** | 260px |
| **Toast height** | 48px |
| **Icon size** | 28x28px |
| **Stack gap** | `sp-2` (8px) between toasts |
| **Max visible toasts** | 3 (oldest dismissed if a 4th arrives) |

---

## Layout Diagram

```
                                          Screen right edge
                                          │
                                          │  32px margin
                                          │◄──►│
                    ┌─────────────────────────┐ │
                    │  [icon]  Scrap Metal  x5 │ │  ← single toast
                    └─────────────────────────┘ │
                                                │

    Multiple pickups stacking:

                    ┌─────────────────────────┐
                    │  [icon]  Scrap Metal  x5 │  ← newest (top)
                    └─────────────────────────┘
                    ┌─────────────────────────┐
                    │  [icon]  Scrap Metal  x3 │  ← older
                    └─────────────────────────┘
                    ┌─────────────────────────┐
                    │  [icon]  Scrap Metal  x8 │  ← oldest (bottom)
                    └─────────────────────────┘

    Single toast detail:

    ┌────────────────────────────────────────┐
    │ sp-2 │ [Icon] │ sp-2 │ Name     │ Qty │ sp-2
    │  8px │ 28x28  │  8px │          │     │  8px
    └────────────────────────────────────────┘
                                 48px tall
                     260px wide
```

---

## Component Specification

### Toast Container

- **Background:** Panel BG (`#0F1923` at 85%)
- **Border:** None
- **Left accent border:** 3px solid Positive Green (`#4ADE80`)
- **Border radius:** 4px
- **Padding:** `sp-2` (8px) all sides

### Item Icon

- **Size:** 28x28px
- **Source:** Item's inventory icon (from resource data definition)
- **Fallback:** Generic cube icon if no item icon exists
- **Position:** Left side, vertically centered

### Item Name

- **Font:** `hud-md` (20px) Medium
- **Color:** Text Primary (`#F1F5F9`)
- **Position:** After icon, left-aligned
- **Truncation:** Ellipsis if name exceeds available width

### Quantity

- **Font:** `data` (18px) Mono
- **Color:** Positive Green (`#4ADE80`)
- **Format:** `xN` (e.g., `x5`, `x12`, `x100`)
- **Position:** Right-aligned within the toast

---

## Appear / Dismiss Behavior

| Event | Animation |
|-------|-----------|
| **Item collected** | Toast slides in from right (24px travel) + fades in, 150ms ease-out |
| **Auto-dismiss** | After 3 seconds, toast fades out over 300ms |
| **New toast while at max (3)** | Oldest toast immediately begins fade-out (150ms); new toast slides in at top of stack |
| **Stack reflow** | When a toast is dismissed, remaining toasts slide up to close the gap, 200ms ease-out |

### Aggregation Rule

If the same item type is collected multiple times within 1 second and a toast for that item is already visible, **update the existing toast's quantity** instead of creating a new toast. The quantity animates (old → new) with a brief scale-up pulse (1.1x, 100ms) on the quantity text. The toast's dismiss timer resets to 3 seconds.

---

## States

| State | Visual |
|-------|--------|
| **Single pickup** | One toast, auto-dismiss after 3s |
| **Rapid pickups (same item)** | Existing toast quantity updates with pulse; timer resets |
| **Rapid pickups (different items)** | Multiple toasts stack; max 3 visible |
| **Inventory full** | Toast appears with Accent Coral left border and text: "Inventory Full" — no quantity. Dismiss after 3s |

---

## Gamepad Notes

- Display-only; no direct interaction
- Right-side placement avoids conflict with center crosshair and left-side battery bar
- 20px item name + 18px quantity readable at TV distance

---

## Implementation Notes

- Use a `VBoxContainer` anchored to center-right for the toast stack
- Each toast is an instanced scene: `HBoxContainer` with `TextureRect` (icon) + `Label` (name) + `Label` (quantity)
- Toast lifecycle managed by a notification manager (autoload or HUD child): receives `item_collected` signals, creates/updates toasts
- Aggregation logic: maintain a `Dictionary` mapping item_id → active toast node; if key exists and toast is still visible, update quantity instead of creating new
- Use `Tween` for all animations (slide, fade, pulse)
- Toast scene should be generic enough to support future notification types (swap left-border color and content)
