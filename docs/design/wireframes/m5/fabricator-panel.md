# Wireframe: Fabricator Interaction Panel

**Component:** Fabricator Module Interaction UI
**Ticket:** TICKET-0065
**Blocks:** TICKET-0069 (Fabricator interaction panel UI implementation)
**Last Updated:** 2026-02-24

---

## Purpose

The Fabricator is the second installable ship module, producing craftable items (Spare Battery, Head Lamp) from raw materials. This panel is the interaction UI for browsing available recipes, starting a job, monitoring progress, and collecting output.

**Layout approach — split-screen:** The panel is divided into two columns. The right column is a scrollable recipe list. The left column is the job detail view showing the currently selected recipe's input/output, progress, and action buttons. This design scales to dozens of recipes without any UI surgery.

**Key differences from the Recycler panel:**
- Split-screen: recipe list (right) + job detail (left), vs Recycler's single-column layout
- No recipe selector widget — recipe selection happens in the list, not the detail view
- Fixed input/output per recipe — no inventory picker (recipe defines what goes in)

---

## Relationship to Physical Machine

The Fabricator machine has a built-in display screen. The panel renders as a full-screen overlay when the player interacts at close range, narratively reading the machine's built-in display. The machine screen glows active Teal when the panel is open.

---

## Interaction Model

1. Player walks toward the placed Fabricator inside the ship
2. At 2m: interact prompt appears ("Press [E] to use Fabricator")
3. Player presses interact — panel opens, focus starts in the recipe list
4. Player navigates the recipe list (D-pad up/down); left detail panel updates live
5. Player presses Confirm or D-pad left to shift focus to the detail panel
6. Player presses START — job begins; recipe list locks during processing
7. Player can close panel and return when done — job continues in background
8. When done, machine status light turns Green; player reopens and presses COLLECT
9. Close with Cancel/Back at any time

---

## Screen Region & Anchoring

- **Position:** Centered on screen (full overlay)
- **Anchor:** `center`
- **Background dim:** Screen Dim (`#000000` at 50%)
- **CanvasLayer:** Layer 2

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Total panel width** | 860px |
| **Total panel height** | 560px |
| **Left column width (detail)** | 480px |
| **Right column width (recipe list)** | 340px |
| **Column divider** | 1px solid `#1A2736`, `sp-4` margin each side |
| **Slot size** | 72x72px |
| **Progress bar width** | 340px |
| **Progress bar height** | 16px (prominent) |
| **Recipe list row height** | 56px |

---

## Layout Diagram

```
    ┌─────────────────────────────────── Full Screen ────────────────────────────────────┐
    │                                                                                     │
    │  ┌──────────────────────────────────────────────────────────────────────────────┐   │
    │  │  FABRICATOR                                                                  │   │
    │  │  ────────────────────────────────────────────────────────────────────────    │   │
    │  │                                                                              │   │
    │  │  ┌──── JOB DETAIL (480px) ─────────────────┐ │ ┌──── RECIPES (340px) ─────┐ │   │
    │  │  │                                          │ │ │                          │ │   │
    │  │  │  Spare Battery                           │ │ │  COMPONENTS              │ │   │
    │  │  │  ↑ selected recipe label (hud-lg, teal)  │ │ │  ──────────────────      │ │   │
    │  │  │                                          │ │ │  ▶ [i] Spare Battery ●   │ │   │
    │  │  │  ──────────────────────────────────────  │ │ │    [i] Head Lamp     ●   │ │   │
    │  │  │                                          │ │ │                          │ │   │
    │  │  │   ┌────────┐         ┌────────┐          │ │ │  EQUIPMENT               │ │   │
    │  │  │   │ INPUT  │   ───►  │ OUTPUT │          │ │ │  ──────────────────      │ │   │
    │  │  │   │        │         │        │          │ │ │    [i] (future)      ◌   │ │   │
    │  │  │   │ [icon] │         │ [icon] │          │ │ │                          │ │   │
    │  │  │   │  x 2   │         │  x 1   │          │ │ │                          │ │   │
    │  │  │   └────────┘         └────────┘          │ │ │                          │ │   │
    │  │  │    Metal x2           Spare Battery       │ │ │                          │ │   │
    │  │  │                                          │ │ │                          │ │   │
    │  │  │   Have: 87 Metal  ← Green if sufficient  │ │ │                          │ │   │
    │  │  │                                          │ │ │                          │ │   │
    │  │  │  ──────────────────────────────────────  │ │ └──────────────────────────┘ │   │
    │  │  │                                          │ │                              │   │
    │  │  │  PROCESSING                              │ │                              │   │
    │  │  │  ┌──────────────────────────────────┐   │ │                              │   │
    │  │  │  │███████████████░░░░░░░░░░░░░░░░░░░│   │ │                              │   │
    │  │  │  └──────────────────────────────────┘   │ │                              │   │
    │  │  │       62%  ·  5s remaining               │ │                              │   │
    │  │  │                                          │ │                              │   │
    │  │  │  ──────────────────────────────────────  │ │                              │   │
    │  │  │                                          │ │                              │   │
    │  │  │   [ START ]           [ COLLECT ]        │ │                              │   │
    │  │  │                                          │ │                              │   │
    │  │  └──────────────────────────────────────────┘ │                              │   │
    │  │                                                                              │   │
    │  └──────────────────────────────────────────────────────────────────────────────┘   │
    │                                                                                     │
    └─────────────────────────────────────────────────────────────────────────────────────┘

    Screen dim (#000 50%) behind panel
    ● = craftable (Green dot)   ◌ = insufficient resources (Amber dot)
```

---

## Left Column: Job Detail

### Container Panel

- **Background:** Surface (`#0A0F18` at 95%)
- **Padding:** `sp-6` (24px) all sides

### Title (Panel-level)

- **Text:** "FABRICATOR"
- **Font:** `hud-xl` (32px) Bold
- **Color:** Text Primary (`#F1F5F9`)
- **Divider:** 1px horizontal line, Neutral at 40% opacity, `sp-4` margin below
- Spans the full panel width (above both columns)

### Selected Recipe Label

Replaces the recipe selector widget. This is a display label only — recipe selection happens in the right column.

- **Text:** Currently selected recipe name (e.g., "Spare Battery")
- **Font:** `hud-lg` (24px) Bold
- **Color:** Text Highlight (`#00D4AA`)
- **Alignment:** Left-aligned
- **Empty state:** "Select a recipe →" in Text Secondary (`#94A3B8`), pointing toward recipe list

---

### Slot Area

Two slots arranged horizontally with an arrow between them. Identical spec to Recycler panel slots — reuse the slot scene.

#### Input Slot

- **Size:** 72x72px
- **Background (no resources):** `#1A2736` at 60% opacity
- **Background (stocked):** `#1A2736` at 80% opacity
- **Border (stocked):** Primary Dim `#007A63`
- **Border (insufficient):** Coral `#FF6B5A`
- **Icon:** 48x48px item icon, centered
- **Stack count:** `hud-xs` (14px) Mono, bottom-right
- **Label below slot:** Input item name + quantity required (e.g., "Metal x2"), `hud-sm` (16px) Text Secondary

Input slot is **display-only** — recipe defines what goes in. Panel reads inventory to set state.

#### Arrow

- `>>>` symbol, `hud-lg` (24px), Primary Dim `#007A63`, vertically centered

#### Output Slot

- Identical spec to Recycler panel output slot
- Label below: Output item name + quantity, `hud-sm` Text Secondary

---

### Resource Availability Row

```
    Have: [Y] [Resource]
```

- **Font:** `data` (18px) Mono
- **Color:** Positive Green (`#4ADE80`) if Y ≥ required; Amber (`#FFB830`) if insufficient
- **Alignment:** Left-aligned, `sp-3` below slot area

---

### Progress Section

- **Section title:** "PROCESSING", `hud-sm` (16px) Bold, Text Secondary
- **Progress bar:** 340px wide (full column), 16px tall, Teal fill, `#1A2736` background, 4px border radius
- **Progress label:** `XX% · Xs remaining`, `data` (18px) Mono, Text Secondary, centered below bar
- **Hidden** when no job is running

---

### Action Buttons

#### START Button

- **Text:** "START"
- **Size:** Min 120x48px
- **Enabled:** Input slot stocked with sufficient resources and no active job
- **Disabled:** Insufficient resources, job running, or output slot full
- **Focused:** Teal outline (2px)

#### COLLECT Button

- **Text:** "COLLECT"
- **Size:** Min 120x48px
- **Ready state:** Positive Green border + text; focused by default when output ready
- **Disabled:** No output available
- **Focused:** Teal outline (2px)

---

## Right Column: Recipe List

A vertically scrollable list of all unlocked recipes, organized by category. Selecting a row updates the left detail panel reactively.

### Recipe List Container

- **Background:** Panel BG (`#0F1923` at 85%)
- **Border-left:** 1px solid `#1A2736` (the column divider)
- **Padding:** `sp-3` (12px) horizontal, `sp-2` (8px) vertical

### Category Header

Groups recipes by type. M5 has two categories: **COMPONENTS** (Spare Battery) and **EQUIPMENT** (Head Lamp).

- **Text:** Category name in ALL CAPS
- **Font:** `hud-xs` (14px) Bold
- **Color:** Text Secondary (`#94A3B8`)
- **Divider:** 1px solid `#1A2736` below, `sp-1` (4px) padding
- **Not focusable** — D-pad navigation skips headers

### Recipe Row

One row per unlocked recipe.

```
    ▶ [icon]  Recipe Name              ●
       Input cost secondary info
```

- **Height:** 56px
- **Layout:** `HBoxContainer` — selection indicator (8px) + icon (32px) + `sp-2` + text block (flex) + affordability dot (16px)

#### Selection Indicator

- **Size:** 4px × 40px vertical bar, left edge of row
- **Color:** Primary Teal `#00D4AA` when this row is selected; transparent otherwise
- **Replaces** the teal left-border focus pattern from the style guide component standards

#### Recipe Icon

- **Size:** 32x32px
- **Style:** Item icon, same asset used in the output slot

#### Text Block (`VBoxContainer`)

- **Top line:** Recipe name, `hud-md` (20px), Text Primary
- **Bottom line:** Input cost summary, `hud-xs` (14px), Text Secondary — e.g., "2 Metal"
- **Line height:** 1.2x

#### Affordability Dot

A 12px circle indicating at a glance whether the player can craft this recipe.

| State | Color | Meaning |
|-------|-------|---------|
| Filled Green ● | `#4ADE80` | Sufficient resources in inventory |
| Filled Amber ● | `#FFB830` | Insufficient resources |
| Empty ◌ | `#94A3B8` at 40% | No recipe data (placeholder; should not appear in normal play) |

Color-blind safety: the dot pairs with the affordability color in the detail panel's "Have:" row — two separate affordability signals reinforce each other.

#### Row States

| State | Background | Name Color | Indicator |
|-------|------------|------------|-----------|
| **Normal** | Transparent | Text Primary | None |
| **Focused** | Panel BG Light `#1A2736` at 60% | Text Primary | Teal left bar |
| **Selected** | Panel BG Light `#1A2736` at 80% | Text Highlight `#00D4AA` | Teal left bar (persistent) |
| **Locked during job** | 40% opacity | Text Secondary | — |

"Focused" = gamepad cursor is on the row. "Selected" = this recipe's details are shown in the left panel. A row can be Selected without being Focused (e.g., player has moved focus to the action buttons).

### Scroll Behavior

- Vertical scroll only
- Scroll bar: 4px right-edge, `#1A2736` track, `#00D4AA` thumb — visible when list overflows
- D-pad up/down scrolls through rows; list auto-scrolls to keep focused row visible
- Keyboard: arrow keys, Page Up/Down supported

---

## Panel States

### No Recipe Selected (on open)

```
    Left:  "Select a recipe →" label; slots empty; START and COLLECT disabled
    Right: Recipe list, no row selected; first unlockable row auto-focused
```

### Recipe Selected, Sufficient Resources

```
    Left:  Recipe name (Teal); slots stocked; Have: X (Green); START enabled
    Right: Selected row highlighted (Teal bar + Text Highlight)
```

### Recipe Selected, Insufficient Resources

```
    Left:  Recipe name (Teal); input slot Coral border; Have: X (Amber); START disabled
    Right: Selected row highlighted; affordability dot Amber
```

### Processing

```
    Left:  Recipe label locked; slots locked; progress bar filling; START disabled
    Right: Recipe list at 40% opacity (locked — cannot change recipe during processing)
```

### Complete

```
    Left:  Output slot with Teal glow; progress "COMPLETE" Green; COLLECT enabled, focused
    Right: Recipe list still locked
```

---

## Open / Close Behavior

- **Open:** Screen dim fades in 150ms; panel scales 0.95→1.0 + fades in, 200ms ease-out
- **Focus on open:** First row of recipe list (auto-selects first craftable recipe if any; falls back to first row)
- **Close (Cancel/Back):** Panel fades out 150ms; screen dim fades out 150ms

---

## Gamepad Navigation

```
    Right column (recipe list):
    D-pad up/down ──► navigate recipe rows
    Confirm (A)   ──► select recipe AND shift focus to left detail panel (START button)
    D-pad left    ──► shift focus to left detail panel without confirming

    Left column (detail):
    D-pad up/down ──► navigate START → COLLECT
    D-pad right   ──► shift focus back to recipe list
    Cancel (B)    ──► close panel (from either column)

    Focus order summary:
    [Recipe List] ←──► [START] ──► [COLLECT]
                              ↑
                        Cancel always closes
```

- Focus starts in the recipe list on open
- During processing: recipe list is non-focusable; focus stays in left column on COLLECT
- COLLECT becomes focused automatically when output is ready (same as Recycler panel)

---

## Implementation Notes

- Root: `CanvasLayer` layer 2
- Panel structure: `VBoxContainer` (title + divider + `HBoxContainer` (left column + right column))
- Left column: `VBoxContainer` — recipe label + slot area + resource row + progress + buttons
- Right column: `VBoxContainer` — scrollable `ItemList` or custom `VBoxContainer` of recipe row scenes; `ScrollContainer` wrapper
- Recipe rows: One `Control` scene per recipe, instantiated from `Fabricator.get_unlocked_recipes()`; reactive to `Fabricator.recipe_unlocked(recipe_id)` signal
- Recipe selection: Emitting `recipe_selected(recipe_id)` from the list scene; left column binds to this signal and updates all display elements
- Slot states: same binding pattern as Recycler panel — read inventory at panel open and on `Inventory.item_changed` signal
- List lock during processing: Set `mouse_filter = MOUSE_FILTER_IGNORE` and `focus_mode = FOCUS_NONE` on each row node; restore on job complete
- Reuse Recycler slot scene — identical visual spec
- Input handling: On open, call InputManager to suppress gameplay inputs and set `MOUSE_MODE_VISIBLE`; on close, restore gameplay inputs and set `MOUSE_MODE_CAPTURED`. UI navigation handled within the panel via `set_input_as_handled()`. No `get_tree().paused`, no `PROCESS_MODE_WHEN_PAUSED`. Game time continues while the panel is open.

---

## Exported Properties (for Gameplay Programmer)

| Property / Signal | Type | Purpose |
|-------------------|------|---------|
| `@export var fabricator: Fabricator` | Node ref | Data source for recipes, job state, output |
| `@export var inventory: Inventory` | Node ref | For reading available material quantities |
| `signal start_requested(recipe_id: String)` | Signal | Emitted when player presses START |
| `signal collect_requested()` | Signal | Emitted when player presses COLLECT |
| `func refresh_display()` | Method | Force-refresh all slot/button/list states |
