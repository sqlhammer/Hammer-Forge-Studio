# Wireframe: Inventory Screen

**Component:** Inventory Overlay (Non-Pause Overlay)
**Ticket:** TICKET-0019
**Blocks:** TICKET-0028 (Inventory UI)
**Last Updated:** 2026-02-22

---

## Purpose

Full-screen overlay displaying the player's 15-slot inventory grid. Shows item icons, names, and stack counts. Opened/closed via toggle input. Game time continues while open; player movement and action inputs are suppressed via InputManager.

---

## Screen Region & Anchoring

- **Position:** Centered on screen (full overlay)
- **Anchor:** `center`
- **Background dim:** Screen Dim (`#000000` at 50%) behind the panel

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Overlay panel width** | 580px |
| **Overlay panel height** | 480px |
| **Slot size** | 80x80px |
| **Slot gap** | `sp-3` (12px) |
| **Grid layout** | 5 columns x 3 rows = 15 slots |
| **Grid total** | (80x5 + 12x4) = 448px wide, (80x3 + 12x2) = 264px tall |

---

## Layout Diagram

```
    ┌──────────────── Full Screen ────────────────────┐
    │                                                  │
    │         ┌────────────────────────────────┐       │
    │         │         INVENTORY              │       │
    │         │  ──────────────────────────     │       │
    │         │                                │       │
    │         │  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐  │
    │         │  │ 01 │ │ 02 │ │ 03 │ │ 04 │ │ 05 │  │
    │         │  │x 25│ │    │ │x 12│ │    │ │x 99│  │
    │         │  └────┘ └────┘ └────┘ └────┘ └────┘  │
    │         │                                │       │
    │         │  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐  │
    │         │  │ 06 │ │ 07 │ │ 08 │ │ 09 │ │ 10 │  │
    │         │  │    │ │x 50│ │    │ │    │ │    │  │
    │         │  └────┘ └────┘ └────┘ └────┘ └────┘  │
    │         │                                │       │
    │         │  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐  │
    │         │  │ 11 │ │ 12 │ │ 13 │ │ 14 │ │ 15 │  │
    │         │  │    │ │    │ │    │ │x  3│ │    │  │
    │         │  └────┘ └────┘ └────┘ └────┘ └────┘  │
    │         │                                │       │
    │         │  ┌─────────────────────────────┐│      │
    │         │  │  Item detail area            ││      │
    │         │  │  Scrap Metal  ★★★☆☆  x25    ││      │
    │         │  └─────────────────────────────┘│      │
    │         │                                │       │
    │         └────────────────────────────────┘       │
    │                                                  │
    └──────────────────────────────────────────────────┘

    Screen dim (#000 50%) behind the panel
```

---

## Component Specification

### Background Dim

- **Full screen** `ColorRect`, `#000000` at 50% opacity
- **Purpose:** Separates the inventory overlay from the game world visually
- **Click/input on dim area:** Does nothing (inventory stays open until toggled)

### Inventory Panel

- **Background:** Surface (`#0A0F18` at 95%)
- **Border:** 1px solid Primary Dim (`#007A63`)
- **Border radius:** 8px
- **Padding:** `sp-6` (24px) all sides

### Title

- **Text:** "INVENTORY"
- **Font:** `hud-xl` (32px) Bold
- **Color:** Text Primary (`#F1F5F9`)
- **Position:** Top-left of panel content area
- **Divider:** 1px horizontal line, Neutral at 40% opacity, `sp-4` (16px) margin below

### Slot Grid

- **Layout:** 5 columns x 3 rows
- **Slot size:** 80x80px each
- **Gap:** `sp-3` (12px) between slots
- **Grid centered horizontally** within the panel

### Individual Slot

```
    ┌──────────────────┐
    │                  │
    │     [Item Icon]  │   48x48px icon, centered
    │                  │
    │            x 25  │   stack count, bottom-right
    └──────────────────┘
         80x80px
```

- **Background (empty slot):** `#1A2736` at 60% opacity
- **Background (occupied slot):** `#1A2736` at 80% opacity
- **Border:** 1px solid `#1A2736`
- **Border radius:** 4px
- **Item icon:** 48x48px, centered in slot
- **Stack count:** `hud-xs` (14px) Mono, Text Primary, bottom-right corner with `sp-1` (4px) padding from edges
- **Stack count visibility:** Only shown if stack > 1
- **Max stack:** 100 per slot (display as `x100`)

### Slot States

| State | Visual |
|-------|--------|
| **Empty** | Darker background, no icon, no count |
| **Occupied** | Item icon + stack count visible |
| **Focused** (gamepad cursor) | Teal outline (2px) + slight scale-up (1.03x). Focus highlight is always visible |
| **Selected** | Teal background fill at 15% opacity + teal border (2px) |

### Item Detail Area

Displayed below the grid when a slot is focused/selected:

- **Width:** Matches grid width (448px)
- **Height:** ~56px
- **Background:** Panel BG Light (`#1A2736` at 80%)
- **Border radius:** 4px
- **Padding:** `sp-3` (12px)
- **Layout:** Single row: Item Name + Purity Stars + Quantity

```
    ┌───────────────────────────────────────────────┐
    │  Scrap Metal          ★★★☆☆          x 25    │
    │  ↑ hud-md, Primary    ↑ 16px stars   ↑ data  │
    └───────────────────────────────────────────────┘
```

| Element | Style |
|---------|-------|
| **Item name** | `hud-md` (20px) Medium, Text Primary. Left-aligned |
| **Purity stars** | 5 stars at 16x16px, Amber filled / Neutral empty. Centered |
| **Quantity** | `data` (18px) Mono, Text Secondary. Right-aligned. Format: `x NN` |

- **Empty slot focused:** Detail area shows "Empty Slot" in Text Secondary, no stars or quantity

---

## Open / Close Behavior

| Event | Animation |
|-------|-----------|
| **Open** (toggle input) | Screen dim fades in 150ms; panel scales from 0.95→1.0 + fades in, 200ms ease-out |
| **Close** (toggle input or back/cancel) | Panel fades out 150ms; screen dim fades out 150ms |
| **First open:** Gamepad focus defaults to slot 1 (top-left) |

### Input Mapping

- **Open/close toggle:** Mapped in InputManager (e.g., Tab on keyboard, Select/Back on gamepad)
- **Navigate slots:** D-pad or left stick (gamepad), arrow keys (keyboard)
- **Navigation wraps:** Moving right from column 5 wraps to column 1 of the same row; moving down from row 3 wraps to row 1 of the same column
- **Close shortcut:** Back/Cancel button (B on Xbox, Circle on PS) always closes inventory

---

## Gamepad Navigation

```
    Focus navigation (D-pad):

    [01] → [02] → [03] → [04] → [05] ─┐
     ↕      ↕      ↕      ↕      ↕     │ (wraps)
    [06] → [07] → [08] → [09] → [10] ─┤
     ↕      ↕      ↕      ↕      ↕     │
    [11] → [12] → [13] → [14] → [15] ─┘

    - D-pad moves focus one slot in the pressed direction
    - Left stick: same behavior (cardinal only, no diagonal slot jump)
    - Focus wraps at grid edges
    - Detail area updates instantly on focus change (no delay)
```

---

## States

| State | Behavior |
|-------|----------|
| **Inventory empty** | All 15 slots show empty state. Detail area shows "No items" |
| **Inventory partially filled** | Occupied slots show items; empty slots show dark background |
| **Inventory full (15/15)** | All slots occupied. No special visual — fullness is communicated via pickup notification toast ("Inventory Full") |

---

## Implementation Notes

- Use `CanvasLayer` (layer 2 — above HUD) for the overlay
- Panel: `PanelContainer` centered on screen with `GridContainer` (5 columns) for slots
- Each slot: custom scene extending `PanelContainer` with `TextureRect` (icon) + `Label` (count)
- Detail area: `HBoxContainer` below the grid, bound to the currently focused slot's data
- Gamepad focus: Use Godot's built-in `focus_neighbor_*` properties on each slot, configured to wrap at edges
- Bind to inventory system's `inventory_changed` signal to update slot display
- The inventory screen does NOT handle item movement, splitting, or dropping in M3 — it is read-only display. Interaction features are deferred
- Input handling: On open, call InputManager to suppress gameplay inputs and set `MOUSE_MODE_VISIBLE`; on close, restore gameplay inputs and set `MOUSE_MODE_CAPTURED`. UI navigation (ui_up/down/left/right, ui_accept, ui_cancel) handled within the panel via `set_input_as_handled()`. No `get_tree().paused`, no `PROCESS_MODE_WHEN_PAUSED`. Game time continues while the inventory is open.
