# Wireframe: Tech Tree UI

**Component:** Tech Tree — Node Graph and Unlock Flow
**Ticket:** TICKET-0065
**Blocks:** TICKET-0068 (Tech tree UI implementation)
**Last Updated:** 2026-02-24

---

## Purpose

The tech tree is the player's strategic planning interface. It communicates what is currently available, what is locked, what is unlockable now, and what the unlock path forward looks like. The M5 scope is a minimal two-node tree: **Fabricator** (root) and **Automation Hub** (requires Fabricator). The design must be extensible — future milestones will add nodes.

---

## Interaction Model

1. Player opens the tech tree from the ship's command interface (interact prompt at terminal)
2. Full-screen overlay opens
3. Player navigates nodes with D-pad / left stick; each node is a focusable element
4. On a focusable unlockable node: resource cost is shown in the node detail panel
5. Player presses Confirm to attempt unlock — a confirmation dialog appears
6. On confirm: resources are consumed, node transitions to Unlocked state
7. Close with Cancel/Back — game resumes

---

## Screen Region & Anchoring

- **Position:** Full-screen overlay (centered)
- **Background dim:** Screen Dim (`#000000` at 50%)
- **CanvasLayer:** Layer 2 (above HUD)
- **Input handling:** On open, call InputManager to suppress gameplay inputs and set `MOUSE_MODE_VISIBLE`; on close, restore gameplay inputs and set `MOUSE_MODE_CAPTURED`. UI navigation handled within the overlay via `set_input_as_handled()`. No `get_tree().paused`, no `PROCESS_MODE_WHEN_PAUSED`. Game time continues while the tech tree is open.

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Overlay panel width** | 960px |
| **Overlay panel height** | 600px |
| **Node card size** | 120x100px |
| **Node connector line width** | 2px |
| **Detail panel width** | 280px |
| **Detail panel height** | 200px |

---

## Layout Diagram

```
    ┌──────────────────────────────── Full Screen ─────────────────────────────────┐
    │                                                                               │
    │  ┌──────────────────────────────────────────────────────────────────────┐    │
    │  │  TECH TREE                                         [X] Close         │    │
    │  │  ──────────────────────────────────────────────────────────────      │    │
    │  │                                                                      │    │
    │  │   ┌───────────────── Graph Area (680px) ───────────────────┐         │    │
    │  │   │                                                         │         │    │
    │  │   │          ┌──────────────────┐                           │         │    │
    │  │   │          │  [Fab icon]      │                           │         │    │
    │  │   │          │  FABRICATOR      │                           │         │    │
    │  │   │          │  [UNLOCKABLE]    │                           │         │    │
    │  │   │          │  100 Metal       │                           │         │    │
    │  │   │          └────────┬─────────┘                           │         │    │
    │  │   │                   │                                     │         │    │
    │  │   │                   │  (connector line)                   │         │    │
    │  │   │                   │                                     │         │    │
    │  │   │          ┌────────▼─────────┐                           │         │    │
    │  │   │          │  [Hub icon]      │                           │         │    │
    │  │   │          │  AUTOMATION HUB  │                           │         │    │
    │  │   │          │  [LOCKED]        │                           │         │    │
    │  │   │          │  Req: Fabricator │                           │         │    │
    │  │   │          └──────────────────┘                           │         │    │
    │  │   │                                                         │         │    │
    │  │   └─────────────────────────────────────────────────────────┘         │    │
    │  │                                                                      │    │
    │  │   ┌──────────── Detail Panel (280px) ───────────────────────┐        │    │
    │  │   │  FABRICATOR                                             │        │    │
    │  │   │  ──────────────────────────────────                     │        │    │
    │  │   │  Crafts components and ship modules.                    │        │    │
    │  │   │                                                         │        │    │
    │  │   │  UNLOCK COST: 100 Metal                                 │        │    │
    │  │   │  You have: 87 Metal   ◄── warn: not enough (Amber)      │        │    │
    │  │   │                                                         │        │    │
    │  │   │  [ UNLOCK (100 Metal) ]   ← disabled if insufficient   │        │    │
    │  │   └─────────────────────────────────────────────────────────┘        │    │
    │  │                                                                      │    │
    │  └──────────────────────────────────────────────────────────────────────┘    │
    │                                                                               │
    └───────────────────────────────────────────────────────────────────────────────┘

    Screen dim (#000 50%) behind panel
```

---

## Node States

Each node card communicates one of four visual states:

| State | Description | Visual Treatment |
|-------|-------------|------------------|
| **Locked** | Prerequisite not yet unlocked | Dimmed to 40% opacity; icon greyscale; label in Text Secondary; border: `#1A2736`; no focus |
| **Unlockable** | Prerequisites met; player may unlock now | Full opacity; Teal border (`#00D4AA` 2px); label in Text Highlight; pulsing teal glow on border (1.5s cycle) |
| **Focused** | Gamepad cursor is on this node | Teal outline 2px + scale 1.04x (same as standard Focused state) |
| **Unlocked** | Player has already unlocked | Full opacity; Positive Green fill background (20% opacity); icon tinted Green; label in Positive Green; lock icon replaced with checkmark |

### Color-blind Safety

All states are distinguished by shape/icon as well as color:
- Locked: padlock icon overlay (bottom-right of node card, 16px)
- Unlockable: upward-pointing chevron indicator (bottom-right, 16px, Teal)
- Unlocked: checkmark icon (bottom-right, 16px, Green)

---

## Node Card Specification

```
    ┌──────────────────────────┐
    │   [Module icon 48x48]    │
    │                          │
    │   NODE NAME              │
    │   [State label]          │
    │                     [⚙]  │  ← state icon (16x16) bottom-right
    └──────────────────────────┘
```

- **Size:** 120x100px
- **Background (locked):** Panel BG `#0F1923` at 50%
- **Background (unlockable):** Panel BG `#0F1923` at 85%
- **Background (unlocked):** Panel BG `#0F1923` at 85% with Positive Green `#4ADE80` at 20% tint
- **Border radius:** 6px
- **Padding:** `sp-3` (12px)
- **Module icon:** 48x48px, centered top
- **Node name:** `hud-sm` (16px) Bold, below icon, `sp-2` gap
- **State label:** `hud-xs` (14px), Text Secondary (Locked/Unlocked) or Text Highlight (Unlockable)

---

## Connector Lines

Lines connecting parent nodes to child nodes in the dependency graph.

- **Width:** 2px solid
- **Color:** `#1A2736` (default — both ends locked or unlocked)
- **Color when parent unlocked + child unlockable:** Teal gradient from parent to child (`#00D4AA` → `#007A63`)
- **Style:** Straight vertical or angled line; arrow cap (▼) at the child end
- **Arrow cap:** 8x8px filled triangle, same color as line

---

## Detail Panel Specification

Shown to the right of the graph area (or below on narrow layouts). Updates to reflect the currently focused node.

### When Locked Node Focused

```
    NODE NAME
    ──────────────────────────────
    [Description text]

    REQUIRES: [Parent node name]
    (parent node state indicator)
```

- Description: `hud-sm` (16px), Text Secondary
- "REQUIRES" label: `hud-xs` (14px) Bold, Text Secondary
- Parent name: `hud-sm`, Text Warning (Amber) to signal blocker

### When Unlockable Node Focused

```
    NODE NAME
    ──────────────────────────────
    [Description text]

    UNLOCK COST: [X] [Resource]
    You have: [Y] [Resource]   ← Green if Y≥X, Amber if Y<X

    [ UNLOCK ([X] [Resource]) ]  ← Button: enabled/disabled
```

- Cost row: `data` (18px) Mono
- "You have" row: same font; Green (`#4ADE80`) if sufficient, Amber (`#FFB830`) if not
- Button: disabled with 40% opacity when player lacks resources; enabled with Teal outline

### When Unlocked Node Focused

```
    NODE NAME  ✓
    ──────────────────────────────
    [Description text]

    UNLOCKED
    [Module is installed / available for placement]
```

- "UNLOCKED" label: `hud-md` (20px) Bold, Positive Green

---

## Confirmation Dialog

Appears as a small modal on top of the tech tree overlay when player presses Confirm on a valid Unlock button.

```
    ┌────────────────────────────────────────┐
    │  Unlock FABRICATOR?                    │
    │  ────────────────────────              │
    │  This will consume 100 Metal.          │
    │                                        │
    │  [ CONFIRM ]       [ CANCEL ]          │
    └────────────────────────────────────────┘
```

- **Width:** 360px
- **Background:** Surface `#0A0F18` at 95%
- **Border:** 1px solid Primary Dim
- **Border radius:** 8px
- **CONFIRM button:** Positive Green border (`#4ADE80`) when focused
- **CANCEL button:** Standard button; focused by default on dialog open
- **Gamepad navigation:** Focus starts on CANCEL (safe default); D-pad left to CONFIRM

---

## Open / Close Behavior

| Event | Animation |
|-------|-----------|
| **Open** (interact at terminal) | Screen dim fades in 150ms; panel scales 0.95→1.0 + fades in, 200ms ease-out |
| **Close** (Cancel/Back) | Panel fades out 150ms; screen dim fades out 150ms |

---

## Gamepad Navigation

```
    Focus order in graph:

    [FABRICATOR node] ──▼── [AUTOMATION HUB node]

    Tab / right stick button: toggle focus between graph and detail panel
    D-pad up/down: navigate nodes in graph
    Confirm (A/Cross): activate Unlock button in detail panel
    Cancel (B/Circle): close tech tree (or cancel confirmation dialog)
```

- Focus starts on the first unlockable node; falls back to first node if all are locked
- Locked nodes are focusable (so player can read descriptions) but Unlock button is absent
- Unlocked nodes are focusable; Unlock button replaced by "Already Unlocked" label

---

## Implementation Notes

- Root: `CanvasLayer` layer 2 — same as other full-screen overlays
- Layout: `HBoxContainer` with graph area (`Control` or `GraphEdit`-lite) + detail panel (`VBoxContainer`)
- Node cards: Custom `PanelContainer` scenes, one instance per tech tree node; state driven by `TechTree` data layer
- Connectors: Drawn via `Line2D` nodes or `_draw()` override in the graph container
- Detail panel updates: Connect to focused node signal; update label/button content reactively
- Unlock button: Export `unlock_requested(node_id)` signal for gameplay-programmer to wire to `TechTree.unlock_node()`
- Confirmation dialog: Separate `PanelContainer` overlay within the same CanvasLayer; show/hide on demand
- Bind to: `TechTree.node_state_changed(node_id, state)` — update node card visuals accordingly
- Extensibility: Node card and connector are separate scenes; adding future nodes requires only adding entries to the data layer and instantiating additional node card scenes

---

## Exported Properties (for Gameplay Programmer)

| Property / Signal | Type | Purpose |
|-------------------|------|---------|
| `@export var tech_tree: TechTree` | Resource | Data source for all node states and costs |
| `signal unlock_requested(node_id: String)` | Signal | Emitted when player confirms unlock |
| `func refresh_display()` | Method | Call after any state change to force visual update |
