# Wireframe: Ship Stats Sidebar (Inventory Addon)

**Component:** Ship Global Variables Sidebar on Inventory Screen
**Ticket:** TICKET-0042
**Blocks:** TICKET-0047 (Inventory UI — ship stats sidebar)
**Last Updated:** 2026-02-23

---

## Purpose

Compact display of the ship's four global variables (Power, Integrity, Heat, Oxygen) appended to the existing inventory screen as a sidebar panel. Allows the player to check ship health without entering the ship. This is an **additive change** to the existing inventory overlay — it does not redesign the inventory.

---

## Visibility Rules

- **Shown:** Whenever the inventory overlay is open (regardless of player location)
- **Position:** Right side of the existing inventory panel
- **The sidebar is read-only** — no interaction, just display

---

## Screen Region & Anchoring

The existing inventory panel is 580px wide, centered on screen. The sidebar attaches to the right edge of the inventory panel.

- **Position:** Right of inventory panel, flush against its right border
- **Anchor:** Follows the inventory panel's center anchor
- **Gap between inventory and sidebar:** 0px (flush/attached — visually a single unified panel)

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Sidebar width** | 180px |
| **Sidebar height** | Matches inventory panel height (480px) |
| **Combined width** | 580px (inventory) + 180px (sidebar) = 760px total |
| **Bar width** | 100px |
| **Bar height** | 8px |
| **Icon size** | 18x18px |

---

## Layout Diagram

```
    ┌──────────────────── Full Screen ─────────────────────────┐
    │                                                           │
    │    ┌──────────────────────────────┬────────────────────┐  │
    │    │         INVENTORY            │   SHIP             │  │
    │    │  ──────────────────────      │   ──────────────   │  │
    │    │                              │                    │  │
    │    │  ┌────┐ ┌────┐ ┌────┐ ┌────┐│   [P] ████░░  72% │  │
    │    │  │ 01 │ │ 02 │ │ 03 │ │ 04 ││                    │  │
    │    │  │x 25│ │    │ │x 12│ │    ││   [I] ██████  90% │  │
    │    │  └────┘ └────┘ └────┘ └────┘│                    │  │
    │    │  ┌────┐                      │   [H] ███░░░  32% │  │
    │    │  │ 05 │  ...                 │                    │  │
    │    │  │x 99│                      │   [O] ██████ 100% │  │
    │    │  └────┘                      │                    │  │
    │    │                              │   ──────────────   │  │
    │    │  ┌────┐ ┌────┐ ┌────┐ ┌────┐│                    │  │
    │    │  │ 06 │ │ 07 │ │ 08 │ │ 09 ││   ALERTS           │  │
    │    │  │    │ │x 50│ │    │ │    ││                    │  │
    │    │  └────┘ └────┘ └────┘ └────┘│   (none)           │  │
    │    │  ┌────┐                      │                    │  │
    │    │  │ 10 │  ...                 │                    │  │
    │    │  └────┘                      │                    │  │
    │    │                              │                    │  │
    │    │  ...                         │                    │  │
    │    │                              │                    │  │
    │    │  ┌─────────────────────────┐ │                    │  │
    │    │  │  Scrap Metal  ★★★☆☆ x25│ │                    │  │
    │    │  └─────────────────────────┘ │                    │  │
    │    │                              │                    │  │
    │    └──────────────────────────────┴────────────────────┘  │
    │                                                           │
    └───────────────────────────────────────────────────────────┘

    Screen dim (#000 50%) behind both panels
```

---

## Component Specification

### Sidebar Container

- **Background:** Surface (`#0A0F18` at 95%) — same as inventory panel
- **Border-left:** 1px solid Primary Dim (`#007A63`) — acts as visual separator from inventory
- **Border (outer):** 1px solid Primary Dim (`#007A63`) — continues inventory's border
- **Border radius:** 0px on left side, 8px on top-right and bottom-right corners
- **Padding:** `sp-3` (12px) all sides

### Title

- **Text:** "SHIP"
- **Font:** `hud-lg` (24px) Bold
- **Color:** Text Primary (`#F1F5F9`)
- **Divider:** 1px horizontal line, Neutral at 40% opacity, `sp-3` (12px) margin below
- **Alignment:** Left-aligned within sidebar

### Variable Rows

Each of the four variables is displayed as a compact row:

```
    [P]  ████████░░░░   72%
    ^    ^               ^
    Icon Bar (100px)    Value
    18px 8px tall       data font 18px
```

- **Vertical gap between rows:** `sp-4` (16px)
- **Layout per row:** `HBoxContainer` — Icon + `sp-1` gap + Bar + `sp-1` gap + Label

### Variable Icons

Same icons as the in-ship HUD (see `ship-globals-hud.md`), scaled to 18x18px:

| Variable | Icon |
|----------|------|
| **Power** | Lightning bolt |
| **Integrity** | Shield |
| **Heat** | Thermometer |
| **Oxygen** | Atom/molecule |

- **Color:** Matches state color (same thresholds as HUD wireframe)

### Progress Bars

- **Width:** 100px
- **Height:** 8px
- **Background:** `#1A2736`
- **Fill colors:** Same state-based colors as the ship globals HUD
- **Border radius:** 2px
- **Heat safe-zone tick marks:** Same as HUD (1px marks at 25% and 75%)

### Value Labels

- **Font:** `data` (18px) Mono
- **Color:** Matches state color
- **Format:** `XX%`
- **Alignment:** Right-aligned

### Alerts Section

Below the four variable rows, a compact alerts section displays critical warnings:

- **Divider:** 1px horizontal line, Neutral at 30% opacity
- **Section title:** "ALERTS" in `hud-xs` (14px) Bold, Text Secondary
- **Alert items:** One line per active alert, `hud-xs` (14px), colored by severity
- **Default state:** "(none)" in Text Secondary when no alerts are active

**Alert examples:**
- `LOW POWER` — Coral `#FF6B5A` (when Power < 20%)
- `HULL CRITICAL` — Coral `#FF6B5A` (when Integrity < 30%)
- `OVERHEATING` — Coral `#FF6B5A` (when Heat > 75%)
- `LOW OXYGEN` — Coral `#FF6B5A` (when Oxygen < 20%)

**Max visible alerts:** 4 (one per variable). No scrolling needed.

---

## Integration with Existing Inventory

The sidebar must integrate cleanly with the existing inventory panel from M3:

| Aspect | Change Required |
|--------|-----------------|
| **Inventory panel width** | Unchanged (580px) |
| **Inventory panel border-right** | Remove border-radius on right side (now flush with sidebar) |
| **Combined centering** | The combined 760px panel is centered on screen instead of the 580px panel alone |
| **Open/close animation** | Sidebar opens with the inventory — same animation, treated as one unit |
| **Gamepad focus** | Sidebar is non-interactive; focus stays within inventory grid. No focus escapes to sidebar |

### Inventory Panel Modifications

The existing inventory panel needs these minor adjustments:
1. Border radius: Change from `8px` all corners to `8px` on left corners only, `0px` on right corners
2. Center offset: Shift left by 90px to maintain visual centering of the combined panel

---

## Gamepad Notes

- Sidebar is display-only — no focusable or interactive elements
- Gamepad focus remains entirely within the inventory grid
- No input mapping changes needed

---

## Implementation Notes

- Sidebar: `PanelContainer` placed inside the inventory overlay's root, positioned to the right of the existing inventory `PanelContainer`
- Use an `HBoxContainer` as the shared root: [Inventory Panel] + [Sidebar Panel]
- Each variable row: `HBoxContainer` with `TextureRect` (icon) + `ProgressBar` (themed) + `Label` (value)
- All four rows inside a `VBoxContainer`
- Bind to the same `ShipState` signals as the in-ship HUD
- Alerts section: `VBoxContainer` below a divider, populated by checking each variable against its warning threshold
- The sidebar should update in real-time even while the inventory is open (variables can change if the game is not fully paused, or to reflect pre-pause state accurately)
