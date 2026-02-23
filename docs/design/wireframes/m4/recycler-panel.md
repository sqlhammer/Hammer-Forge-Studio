# Wireframe: Recycler Interaction Panel

**Component:** Recycler Module Interaction UI
**Ticket:** TICKET-0042
**Blocks:** TICKET-0045 (Recycler interaction panel UI)
**Last Updated:** 2026-02-23

---

## Purpose

The Recycler is the first processing module the player installs in the ship. This panel is the interaction UI for converting raw resources (Scrap Metal) into processed materials (Metal). The panel represents the screen built into the front face of the physical Recycler machine (see `recycler-machine.md` for the 3D form factor). The player walks up to the machine, interacts, and this UI opens as a screen-space overlay — narratively, the player is reading the machine's built-in display.

---

## Relationship to Physical Machine

The Recycler machine has a 40cm x 30cm screen embedded in its front face (see `recycler-machine.md`). This panel wireframe defines what appears on that screen. In practice, the panel renders as a full-screen overlay for usability (the physical screen is too small for comfortable UI at standing distance), but the machine's screen brightens to active teal when the panel is open, anchoring the interaction to the physical object.

See `recycler-machine.md` for: machine dimensions, placement in module zone, visual landmarks (input hopper, output tray, status light, screen), and greybox material spec.

---

## Interaction Model

1. Player walks toward the placed Recycler machine inside the ship
2. At 3m: status light and screen glow are visible on the machine
3. At 2m: interact prompt appears ("Press [E] to use Recycler")
4. Player presses interact — machine screen brightens, panel opens as screen-space overlay
5. Player selects input resource from their inventory, starts the job
6. Player can close the panel and return later — the job continues processing (status light on machine pulses amber)
7. When done, machine status light turns green — player reopens the panel and collects the output
8. Close with cancel input (Esc / B button) — machine screen dims back to idle

---

## Screen Region & Anchoring

- **Position:** Centered on screen (full overlay, same layer as inventory)
- **Anchor:** `center`
- **Background dim:** Screen Dim (`#000000` at 50%)

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Panel width** | 480px |
| **Panel height** | 400px |
| **Slot size** | 72x72px |
| **Progress bar width** | 200px |
| **Progress bar height** | 16px (prominent) |

---

## Layout Diagram

```
    ┌──────────────────── Full Screen ─────────────────────────┐
    │                                                           │
    │         ┌──────────────────────────────────────┐          │
    │         │          RECYCLER                    │          │
    │         │  ──────────────────────────────      │          │
    │         │                                      │          │
    │         │                                      │          │
    │         │   ┌────────┐         ┌────────┐      │          │
    │         │   │  INPUT │   ───►  │ OUTPUT │      │          │
    │         │   │        │         │        │      │          │
    │         │   │ [icon] │         │ [icon] │      │          │
    │         │   │  x 10  │         │  x 10  │      │          │
    │         │   └────────┘         └────────┘      │          │
    │         │    Scrap Metal        Metal           │          │
    │         │                                      │          │
    │         │  ──────────────────────────────      │          │
    │         │                                      │          │
    │         │          PROCESSING                  │          │
    │         │   ┌──────────────────────────┐       │          │
    │         │   │████████████░░░░░░░░░░░░░░│       │          │
    │         │   └──────────────────────────┘       │          │
    │         │          47%  •  8s remaining         │          │
    │         │                                      │          │
    │         │  ──────────────────────────────      │          │
    │         │                                      │          │
    │         │   [ START ]          [ COLLECT ]      │          │
    │         │                                      │          │
    │         └──────────────────────────────────────┘          │
    │                                                           │
    └───────────────────────────────────────────────────────────┘

    Screen dim (#000 50%) behind panel
```

---

## Component Specification

### Container Panel

- **Background:** Surface (`#0A0F18` at 95%)
- **Border:** 1px solid Primary Dim (`#007A63`)
- **Border radius:** 8px
- **Padding:** `sp-6` (24px) all sides

### Title

- **Text:** "RECYCLER"
- **Font:** `hud-xl` (32px) Bold
- **Color:** Text Primary (`#F1F5F9`)
- **Divider:** 1px horizontal line, Neutral at 40% opacity, `sp-4` (16px) margin below

### Slot Area

Two slots arranged horizontally with an arrow between them.

#### Input Slot

- **Size:** 72x72px
- **Background (empty):** `#1A2736` at 60% opacity
- **Background (occupied):** `#1A2736` at 80% opacity
- **Border:** 1px solid `#1A2736` (empty) or Primary Dim `#007A63` (occupied)
- **Border radius:** 4px
- **Icon:** 48x48px item icon, centered
- **Stack count:** `hud-xs` (14px) Mono, bottom-right, `sp-1` padding
- **Label below slot:** Item name in `hud-sm` (16px), Text Secondary, centered below the slot

#### Arrow

- **Symbol:** Right-pointing arrow `>>>`
- **Font:** `hud-lg` (24px)
- **Color:** Primary Dim (`#007A63`)
- **Vertically centered** between the two slots
- **Horizontal gap:** `sp-6` (24px) on each side of the arrow

#### Output Slot

- Same dimensions and styling as Input Slot
- **Background when result available:** `#1A2736` at 80% with a subtle Teal border glow (2px, `#00D4AA` at 50% opacity)
- **Label below slot:** Output item name in `hud-sm` (16px), Text Secondary

### Slot Focus (Gamepad)

| Slot | Focus Behavior |
|------|----------------|
| **Input Slot (focused)** | Teal outline (2px) + scale 1.03x. Pressing confirm opens a mini-inventory picker |
| **Output Slot** | Non-focusable until output is available. When available: Teal outline on focus, confirm collects |

### Mini-Inventory Picker (Input Selection)

When the player activates the input slot, a small overlay appears listing recyclable items from their inventory:

```
    ┌──────────────────────────────┐
    │  SELECT INPUT                │
    │  ─────────────────           │
    │  > Scrap Metal     x 47     │
    │    (future items)           │
    │                              │
    │  [Cancel]                    │
    └──────────────────────────────┘
```

- **Width:** 280px
- **Background:** Panel BG (`#0F1923` at 90%)
- **Border:** 1px solid Primary Dim
- **Each row:** Item icon (24x24) + Item name (`hud-md`) + Quantity (`data`)
- **Focused row:** Teal left-border (3px) + Text Highlight color
- **Only shows items that the Recycler can process** (filtered by recipe registry)
- **Cancel:** Back/cancel input closes the picker without selecting

### Progress Section

Shown below the slots, separated by a divider.

#### Section Title

- **Text:** "PROCESSING"
- **Font:** `hud-sm` (16px) Bold
- **Color:** Text Secondary (`#94A3B8`)

#### Progress Bar

- **Width:** 200px (centered in the section)
- **Height:** 16px (prominent, per style guide)
- **Background:** `#1A2736`
- **Fill:** Primary Teal `#00D4AA`
- **Border radius:** 4px
- **Fill animates smoothly** as the job progresses

#### Progress Label

- **Below the bar**, centered
- **Format:** `XX% . Xs remaining`
- **Font:** `data` (18px) Mono
- **Color:** Text Secondary
- **The dot separator** is a middle dot (`\u00B7`), `sp-2` padding on each side

### Action Buttons

Two buttons at the bottom of the panel, separated by a divider above.

#### START Button

- **Text:** "START"
- **Size:** Min 120x48px
- **Style:** Standard button per style guide
- **Position:** Left side of button row
- **States:**
  - **Normal:** Available when input slot has a valid resource and no job is running
  - **Disabled:** Greyed out when no input selected, or a job is already running, or output slot is full
  - **Focused:** Teal outline (2px)

#### COLLECT Button

- **Text:** "COLLECT"
- **Size:** Min 120x48px
- **Style:** Standard button with Positive Green highlight when output is ready
- **Position:** Right side of button row
- **States:**
  - **Normal (ready):** Positive Green border (`#4ADE80`), Text: Positive Green — output is ready to collect
  - **Disabled:** Greyed out when no output is available
  - **Focused:** Teal outline (2px)

---

## Panel States

### Idle (No Job)

```
    Input:    [empty]
    Output:   [empty]
    Progress: Hidden (or shows "No active job" in Text Secondary)
    START:    Disabled (no input selected)
    COLLECT:  Disabled (no output)
```

### Input Selected, Ready to Start

```
    Input:    [Scrap Metal x10]
    Output:   [empty]
    Progress: Hidden
    START:    Enabled (focused by default)
    COLLECT:  Disabled
```

### Processing

```
    Input:    [Scrap Metal x10] (locked — cannot change during processing)
    Output:   [empty, shows ghost icon of expected output at 30% opacity]
    Progress: Visible, filling, "47% . 8s remaining"
    START:    Disabled ("PROCESSING..." text)
    COLLECT:  Disabled
```

### Complete (Output Ready)

```
    Input:    [empty] (consumed)
    Output:   [Metal x10] (teal glow border)
    Progress: 100% filled, "COMPLETE" label in Positive Green
    START:    Disabled (output slot full)
    COLLECT:  Enabled, Positive Green highlight, focused by default
```

---

## Open / Close Behavior

| Event | Animation |
|-------|-----------|
| **Open** (interact input at Recycler) | Screen dim fades in 150ms; panel scales 0.95->1.0 + fades in, 200ms ease-out |
| **Close** (cancel input) | Panel fades out 150ms; screen dim fades out 150ms |
| **First open:** Focus defaults to input slot (if idle) or COLLECT button (if output ready) |

---

## Gamepad Navigation

```
    Focus order:

    [Input Slot] ──► [Output Slot / COLLECT]*
         │
         ▼
    [START]      ──► [COLLECT]

    * Output slot only focusable when output is available
    * Navigation wraps: START <-> COLLECT horizontally
    * Cancel/Back always closes the panel
```

- **D-pad / left stick:** Moves focus between interactive elements
- **Confirm (A / Cross):** Activate focused element (open picker, start job, collect output)
- **Cancel (B / Circle):** Close panel (or close mini-picker if open)

---

## Implementation Notes

- Root: `CanvasLayer` (layer 2 — same as inventory overlay)
- Panel: `PanelContainer` centered, with `VBoxContainer` for vertical layout
- Slot area: `HBoxContainer` with two slot scenes + arrow label between
- Each slot: Custom scene extending `PanelContainer` (reuse inventory slot pattern from M3 if compatible)
- Progress: `ProgressBar` with custom theme, bound to `Recycler.progress_changed` signal
- Buttons: `Button` nodes with custom `StyleBoxFlat` per style guide
- Mini-picker: Separate `PanelContainer` overlay, populated from `Inventory` filtered by `Recycler.get_valid_inputs()`
- Game pause: Set `get_tree().paused = true` when panel opens; panel in `PROCESS_MODE_WHEN_PAUSED`
- The Recycler module processes in real-time (not paused time) — progress continues while panel is closed
- Bind to signals: `Recycler.job_started`, `Recycler.job_progress`, `Recycler.job_completed`
