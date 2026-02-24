# Wireframe: Fabricator Interaction Panel

**Component:** Fabricator Module Interaction UI
**Ticket:** TICKET-0065
**Blocks:** TICKET-0069 (Fabricator interaction panel UI implementation)
**Last Updated:** 2026-02-24

---

## Purpose

The Fabricator is the second installable ship module, producing craftable items (Spare Battery, Head Lamp) from raw materials. This panel is the interaction UI for selecting a recipe, queuing a job, monitoring progress, and collecting output. It extends the Recycler panel pattern from M4 — the design language is intentionally consistent to minimize player learning overhead.

**Key differences from the Recycler panel:**
- Multiple recipes available (recipe selection row added above input/output slots)
- Fixed input/output per recipe — no inventory picker for input (recipe defines what goes in)
- Job queue: player can view the active job and one pending slot (M5 scope — one active, no queue management)

---

## Relationship to Physical Machine

The Fabricator machine has a built-in display screen (see `docs/design/wireframes/m5/` — cross-reference the Fabricator 3D asset spec from TICKET-0067). The panel renders as a full-screen overlay when the player interacts at close range, narratively reading the machine's built-in display. The machine screen glows active Teal when the panel is open.

---

## Interaction Model

1. Player walks toward the placed Fabricator inside the ship
2. At 2m: interact prompt appears ("Press [E] to use Fabricator")
3. Player presses interact — panel opens as screen-space overlay
4. Player selects a recipe using the recipe selector
5. Input slot auto-populates from inventory (if resources available)
6. Player confirms and starts the job
7. Player can close panel and return when done — job continues in background
8. When done, status light on machine turns Green — player reopens and collects output
9. Close with Cancel/Back

---

## Screen Region & Anchoring

- **Position:** Centered on screen (full overlay, same layer as Recycler panel)
- **Anchor:** `center`
- **Background dim:** Screen Dim (`#000000` at 50%)
- **CanvasLayer:** Layer 2

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Panel width** | 520px |
| **Panel height** | 500px |
| **Recipe row height** | 48px |
| **Slot size** | 72x72px |
| **Progress bar width** | 220px |
| **Progress bar height** | 16px (prominent) |

---

## Layout Diagram

```
    ┌──────────────────────── Full Screen ─────────────────────────────┐
    │                                                                   │
    │       ┌──────────────────────────────────────────────────┐        │
    │       │  FABRICATOR                                      │        │
    │       │  ──────────────────────────────────────────      │        │
    │       │                                                  │        │
    │       │  RECIPE                                          │        │
    │       │  ┌────────────────────────────────────────────┐  │        │
    │       │  │  ◄  [ Spare Battery ]  ►                   │  │        │
    │       │  └────────────────────────────────────────────┘  │        │
    │       │                                                  │        │
    │       │  ──────────────────────────────────────────      │        │
    │       │                                                  │        │
    │       │   ┌────────┐         ┌────────┐                  │        │
    │       │   │  INPUT │   ───►  │ OUTPUT │                  │        │
    │       │   │        │         │        │                  │        │
    │       │   │ [icon] │         │ [icon] │                  │        │
    │       │   │  x 2   │         │  x 1   │                  │        │
    │       │   └────────┘         └────────┘                  │        │
    │       │    Metal x2           Spare Battery               │        │
    │       │                                                  │        │
    │       │   Have: 87 Metal  ◄── resource check label       │        │
    │       │                                                  │        │
    │       │  ──────────────────────────────────────────      │        │
    │       │                                                  │        │
    │       │       PROCESSING                                 │        │
    │       │  ┌────────────────────────────────────────────┐  │        │
    │       │  │███████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░│  │        │
    │       │  └────────────────────────────────────────────┘  │        │
    │       │        62%  ·  5s remaining                      │        │
    │       │                                                  │        │
    │       │  ──────────────────────────────────────────      │        │
    │       │                                                  │        │
    │       │   [ START ]               [ COLLECT ]            │        │
    │       │                                                  │        │
    │       └──────────────────────────────────────────────────┘        │
    │                                                                   │
    └───────────────────────────────────────────────────────────────────┘

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

- **Text:** "FABRICATOR"
- **Font:** `hud-xl` (32px) Bold
- **Color:** Text Primary (`#F1F5F9`)
- **Divider:** 1px horizontal line, Neutral at 40% opacity, `sp-4` margin below

---

### Recipe Selector

A horizontally scrollable (or paginated) selector for the available recipes. M5 has two recipes: Spare Battery and Head Lamp.

```
    ◄  [ Recipe Name ]  ►

    Left/Right arrows navigate recipes
    Center shows the currently selected recipe name
```

- **Layout:** `HBoxContainer` — left arrow button + recipe label (centered) + right arrow button
- **Arrow buttons:** 48x48px (minimum gamepad target), label `hud-lg` (24px) `<` / `>`
- **Recipe label:** `hud-md` (20px) Bold, Text Highlight (`#00D4AA`), centered
- **Background:** Panel BG Light (`#1A2736` at 90%), border radius 4px
- **Focus:** Left or right arrow button focused; D-pad left/right switches recipe
- **When only one recipe available:** Arrows disabled (40% opacity)

---

### Slot Area

Two slots arranged horizontally with an arrow between them. Identical spec to Recycler panel slots — reuse the slot scene.

#### Input Slot

- **Size:** 72x72px
- **Background (empty/no resources):** `#1A2736` at 60% opacity
- **Background (stocked):** `#1A2736` at 80% opacity
- **Border (stocked):** Primary Dim `#007A63`
- **Border (insufficient):** Coral `#FF6B5A` — signals player doesn't have enough resources
- **Icon:** 48x48px item icon, centered
- **Stack count:** `hud-xs` (14px) Mono, bottom-right
- **Label below slot:** Input item name + quantity required (e.g., "Metal x2"), `hud-sm` (16px) Text Secondary

Input slot is **display-only** (no picker) — the recipe defines what goes in. The panel reads from inventory automatically to populate the slot. If inventory has insufficient resources, the slot shows the resource icon at 40% opacity with a Coral border.

#### Arrow

- Identical to Recycler panel arrow spec
- `>>>` symbol, `hud-lg` (24px), Primary Dim `#007A63`, vertically centered

#### Output Slot

- Identical spec to Recycler panel output slot
- Label below: Output item name + quantity (e.g., "Spare Battery x1"), `hud-sm` Text Secondary

---

### Resource Availability Row

A single line below the slot area showing inventory quantities for the required input material.

```
    Have: [Y] [Resource]  ◄── color-coded
```

- **Font:** `data` (18px) Mono
- **Color:** Positive Green (`#4ADE80`) if Y ≥ required; Amber (`#FFB830`) if Y < required
- **Alignment:** Left-aligned, `sp-3` from slot area

---

### Progress Section

Identical spec to Recycler panel progress section.

- **Section title:** "PROCESSING", `hud-sm` Bold, Text Secondary
- **Progress bar:** 220px wide, 16px tall, Primary Teal fill, `#1A2736` background, 4px border radius
- **Progress label:** `XX% · Xs remaining`, `data` (18px) Mono, Text Secondary, centered

---

### Action Buttons

Identical spec to Recycler panel action buttons.

#### START Button

- **Text:** "START"
- **Size:** Min 120x48px
- **Normal:** Available when input slot has sufficient resources and no job running
- **Disabled:** When insufficient resources, or job already running, or output slot full
- **Focused:** Teal outline (2px)

#### COLLECT Button

- **Text:** "COLLECT"
- **Size:** Min 120x48px
- **Ready state:** Positive Green border + text
- **Disabled:** Greyed out when no output available
- **Focused:** Teal outline (2px)

---

## Panel States

### Idle — Recipe Selected, Sufficient Resources

```
    Recipe:   [Spare Battery]
    Input:    [Metal x2] (stocked, standard border)
    Output:   [empty]
    Have:     87 Metal  (Green)
    Progress: Hidden
    START:    Enabled
    COLLECT:  Disabled
```

### Idle — Insufficient Resources

```
    Recipe:   [Spare Battery]
    Input:    [Metal icon, 40% opacity] (Coral border)
    Output:   [empty]
    Have:     1 Metal  (Amber) — need 2
    Progress: Hidden
    START:    Disabled
    COLLECT:  Disabled
```

### Processing

```
    Recipe:   [Spare Battery] (locked during processing)
    Input:    [Metal x2] (consumed display — shows cost)
    Output:   [ghost icon at 30% opacity — expected output]
    Have:     [updated inventory count]
    Progress: Visible, filling
    START:    Disabled ("PROCESSING...")
    COLLECT:  Disabled
```

### Complete

```
    Recipe:   [Spare Battery] (unlocked)
    Input:    [empty]
    Output:   [Spare Battery x1] (Teal glow border)
    Progress: 100%, "COMPLETE" in Positive Green
    START:    Disabled (output slot full)
    COLLECT:  Enabled, Positive Green highlight, focused by default
```

---

## Open / Close Behavior

Identical to Recycler panel: 150ms screen dim + 200ms panel scale-in on open; 150ms fade on close.

---

## Gamepad Navigation

```
    Focus order:

    [Recipe ◄]  [Recipe ►]
         │
         ▼
    [START]  ──►  [COLLECT]

    Cancel/Back always closes panel
    Recipe arrows focusable with D-pad up/back from slots
```

---

## Implementation Notes

- Reuse Recycler slot scene (`game/scenes/ui/`) — identical visual spec
- Recipe selector: `HBoxContainer` with two `Button` nodes + `Label`; driven by `Fabricator.get_recipes()` list
- Input slot: Display-only; read `Fabricator.get_selected_recipe().input` for item + quantity; check inventory to set availability state
- Progress bar: Bind to `Fabricator.job_progress` signal
- Recipe change: Emit `recipe_changed(recipe_id)` signal for gameplay-programmer; update slot display reactively
- Game pause: Same as Recycler — `get_tree().paused = true` when open

---

## Exported Properties (for Gameplay Programmer)

| Property / Signal | Type | Purpose |
|-------------------|------|---------|
| `@export var fabricator: Fabricator` | Node ref | Data source for recipes, job state, output |
| `@export var inventory: Inventory` | Node ref | For reading available material quantities |
| `signal start_requested(recipe_id: String)` | Signal | Emitted when player presses START |
| `signal collect_requested()` | Signal | Emitted when player presses COLLECT |
| `func refresh_display()` | Method | Force-refresh all slot/button states |
