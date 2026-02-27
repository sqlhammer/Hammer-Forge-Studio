# Wireframe: Navigation Console Modal

**Component:** Navigation Console — Full-Screen Modal
**Ticket:** TICKET-0165
**Blocks:** TICKET-0167 (Navigation console UI — modal screen, biome selection, fuel cost, confirm travel)
**Last Updated:** 2026-02-27

---

## Purpose

The navigation console is the player's interface for biome-to-biome ship travel. When the player interacts with the navigation console mesh in the cockpit (placed in M7), this modal opens showing an abstract biome map and a detail panel for the selected destination. Travel is initiated from this screen after confirming fuel sufficiency.

**Key design goals:**
- Biome map is the hero element — large, legible, immediately scannable
- Selected destination detail answers three questions: where am I going, how far, do I have enough fuel
- Confirm Travel is clearly gated — disabled with explicit reason when fuel is insufficient
- Consistent visual language with existing machine panels (Recycler, Fabricator) — full-screen overlay, Surface background, screen dim

---

## Relationship to Physical Console

The navigation console is a physical 2m × 0.8m mesh in the cockpit (X=0, Z=−11.5 per M7 wireframe). The player interacts with it from 2m range. The modal renders as a full-screen overlay narratively reading the console's built-in display — consistent with the Recycler and Fabricator machine panel pattern.

---

## Interaction Model

1. Player walks toward cockpit navigation console
2. At 2m: interact prompt appears ("Press [E] to use Navigation Console")
3. Player presses interact — modal opens with biome map
4. Player navigates biome node graph (D-pad / keyboard / mouse) to select destination
5. Right detail panel updates reactively with destination info
6. Player presses CONFIRM TRAVEL — travel sequence begins (TICKET-0168)
7. Close with Cancel/Back at any time

---

## Screen Region & Anchoring

- **Position:** Centered on screen (full overlay)
- **Anchor:** `center`
- **Background dim:** Screen Dim (`#000000` at 50%)
- **CanvasLayer:** Layer 2
- **Interaction model:** Non-pause — game time continues, player inputs suppressed via InputManager. Consistent with all existing machine panels.

---

## Dimensions (at 1080p)

| Property | Value |
|----------|-------|
| **Total panel width** | 900px |
| **Total panel height** | 600px |
| **Left zone — Biome Map** | 540px wide × 520px tall (inside panel content area) |
| **Right zone — Destination Detail** | 300px wide × 520px tall |
| **Column divider** | 1px solid `#1A2736`, `sp-4` margin each side |
| **Panel background** | Surface `#0A0F18` at 95% |
| **Title bar height** | 56px (title text + bottom divider) |
| **Action bar height** | 60px (buttons + top border) |
| **Biome node size — current** | 80×40px |
| **Biome node size — destination** | 72×36px |
| **Biome node size — locked** | 72×36px, 40% opacity |

---

## Layout Diagram

```
    ┌─────────────────────────────────── Full Screen ────────────────────────────────────┐
    │    Screen Dim (#000 50%)                                                            │
    │                                                                                     │
    │   ┌──────────────────────────────────────────────────────────────────────────────┐  │
    │   │  NAVIGATION CONSOLE                                            [⊠ CLOSE]     │  │
    │   │  ──────────────────────────────────────────────────────────────────────────  │  │
    │   │                                                                              │  │
    │   │  ┌──── BIOME MAP (540px) ─────────────────────────────────┐│┌─ DETAIL (300px)┐│ │
    │   │  │                                                         │││                ││ │
    │   │  │   CURRENT LOCATION                                      │││  [no selection]││ │
    │   │  │   ╔══════════════════════╗                              │││                ││ │
    │   │  │   ║  ◉ OVERGROWN SUBURBS ║  (highlighted, teal border)  │││  Select a      ││ │
    │   │  │   ╚══════════════════════╝                              │││  destination → ││ │
    │   │  │           │              │              │               │││                ││ │
    │   │  │    [─────]│[────────────]│[─────────────]│              │││                ││ │
    │   │  │           ▼              ▼               ▼              │││                ││ │
    │   │  │   ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │││                ││ │
    │   │  │   │  SHATTERED   │ │    ROCK      │ │   DEBRIS     │   │││                ││ │
    │   │  │   │    FLATS     │ │   WARRENS    │ │    FIELD     │   │││                ││ │
    │   │  │   │  ▶ 8.3 km   │ │  ▶ 12.5 km  │ │  ▶ 6.1 km   │   │││                ││ │
    │   │  │   │  ⛽ 1 cell  │ │  ⛽ 2 cells │ │  ⛽ 1 cell  │   │││                ││ │
    │   │  │   └──────────────┘ └──────────────┘ └──────────────┘   │││                ││ │
    │   │  │                                                         │││                ││ │
    │   │  │   [future biomes would appear as locked ◌ nodes here]   │││                ││ │
    │   │  │                                                         │││                ││ │
    │   │  └─────────────────────────────────────────────────────────┘│└────────────────┘│ │
    │   │  ──────────────────────────────────────────────────────────────────────────────  │
    │   │                               [ CANCEL ]                                        │
    │   └──────────────────────────────────────────────────────────────────────────────────┘
    │                                                                                     │
    └─────────────────────────────────────────────────────────────────────────────────────┘

    === SELECTED STATE (Shattered Flats selected) ===

    │  ┌──── BIOME MAP ─────────────────────────────────────────────┐│┌─ DETAIL ──────────┐│
    │  │                                                             │││                    ││
    │  │   ╔══════════════════════╗                                  │││  Shattered Flats   ││
    │  │   ║  ◉ OVERGROWN SUBURBS ║                                  │││  ── Tier 1 ──      ││
    │  │   ╚══════════════════════╝                                  │││                    ││
    │  │           │                                                 │││  Distance          ││
    │  │           ▼                                                 │││  8.3 km            ││
    │  │  ┌══════════════╗  ┌──────────────┐  ┌──────────────┐      │││                    ││
    │  │  ║  SHATTERED   ║  │    ROCK      │  │   DEBRIS     │      │││  Est. Fuel Cost    ││
    │  │  ║    FLATS     ║  │   WARRENS    │  │    FIELD     │      │││  ⛽ 1 Fuel Cell    ││
    │  │  ║ (selected)   ║  │  ▶ 12.5 km  │  │  ▶ 6.1 km   │      │││                    ││
    │  │  ╚══════════════╝  └──────────────┘  └──────────────┘      │││  Your Fuel         ││
    │  │                                                             │││  ⛽ 3 Fuel Cells   ││
    │  └─────────────────────────────────────────────────────────────┘││  (● sufficient)    ││
    │                                                                  ││                    ││
    │                                                                  ││ [ CONFIRM TRAVEL ] ││
    │                                                                  │└────────────────────┘│

    ◉ = current location indicator   ● = available   ◌ = locked
    ══ = focused/selected node border (2px teal outline)   ── = default node border
```

---

## Panel Title Bar

- **Text:** "NAVIGATION CONSOLE"
- **Font:** `hud-xl` (32px) Bold
- **Color:** Text Primary (`#F1F5F9`)
- **[⊠ CLOSE] button:** Top-right, `hud-sm` (16px), Text Secondary — same as cancel; gamepad back triggers this
- **Divider:** 1px horizontal line, Neutral at 40% opacity, `sp-4` margin below

---

## Left Zone: Biome Map

An abstract node graph representing the travel network. Designed for greybox legibility — no geographic accuracy required. Nodes are connected by travel path lines.

### Map Container

- **Background:** Panel BG (`#0F1923` at 85%)
- **Padding:** `sp-5` (20px) all sides
- **Section label:** "BIOME MAP" in `hud-xs` (14px) Bold, Text Secondary, top-left of zone

### Biome Node — Current Location

Renders as the graph root (centered horizontally, top third of map area).

```
    ╔══════════════════════╗
    ║  ◉ [BIOME NAME]      ║   ← teal-bordered box
    ╚══════════════════════╝
```

- **Size:** 80px wide × 40px tall minimum
- **Background:** Panel BG Light `#1A2736` at 90%
- **Border:** 2px solid Primary Teal `#00D4AA`
- **Border radius:** 4px
- **Icon:** `◉` (filled circle, 12px) in Teal — "you are here" indicator
- **Label:** Biome name, `hud-sm` (16px) Bold, Text Highlight `#00D4AA`
- **Not focusable** — current location is informational only

### Travel Path Lines

Lines connecting current location node to destination nodes.

- **Style:** 1px solid, Primary Dim `#007A63`
- **Direction:** Vertical line from current location node downward, then branches horizontally to each destination

### Biome Node — Available Destination

```
    ┌──────────────┐
    │  BIOME NAME  │
    │  ▶ X.X km   │
    │  ⛽ N cells  │
    └──────────────┘
```

- **Size:** 72px wide × 36px tall minimum (auto-sizes to content)
- **Background:** `#1A2736` at 70%
- **Border:** 1px solid `#1A2736`
- **Border radius:** 4px
- **Top line:** Biome name, `hud-sm` (16px), Text Primary `#F1F5F9`
- **Distance line:** `▶ X.X km`, `hud-xs` (14px), Text Secondary `#94A3B8`
- **Fuel cost line:** `⛽ N Fuel Cell(s)`, `hud-xs` (14px), Text Secondary
- **Padding:** `sp-2` (8px) all sides

#### Node States

| State | Background | Border | Text | Notes |
|-------|------------|--------|------|-------|
| **Normal** | `#1A2736` at 70% | `#1A2736` 1px | Text Primary | Default appearance |
| **Focused** | Panel BG Light `#1A2736` at 90% | Teal `#00D4AA` 2px | Text Primary | Gamepad cursor on node |
| **Selected** | Panel BG Light `#1A2736` at 90% | Teal `#00D4AA` 2px | Text Highlight `#00D4AA` | Destination selected; detail panel showing |

### Biome Node — Locked Destination

Future-tier biomes not accessible in M8. Included in the graph to show the travel network extends beyond current access.

```
    ┌──────────────┐
    │  🔒 [NAME]   │   40% opacity
    │  (locked)    │
    └──────────────┘
```

- **Opacity:** 40%
- **Border:** 1px dashed, Neutral `#94A3B8`
- **Lock icon:** `🔒` or lock SVG HUD icon, 16×16px, Neutral
- **Label:** Biome name in Text Secondary; "(requires upgrade)" below in `hud-xs` Text Secondary
- **Not focusable** — D-pad navigation skips locked nodes

### Map Navigation (Gamepad)

- D-pad left/right — move focus between destination nodes on the same row
- D-pad down — move focus from current location down to first available destination
- D-pad up — move focus back to detail panel (or back to current location context)
- Confirm (A) — select focused destination; updates detail panel; also shifts focus to detail panel's CONFIRM TRAVEL button
- Cancel (B) — close modal

---

## Right Zone: Destination Detail Panel

Updates reactively when a biome node is selected. Shows three key data points and the primary action.

### Empty State (on panel open, no destination selected)

```
    ┌────────────────────────────────┐
    │  DESTINATION                   │
    │  ─────────────────────────     │
    │                                │
    │  Select a destination ←        │
    │  (pointing toward map)         │
    │                                │
    └────────────────────────────────┘
```

- **Prompt:** "Select a destination ←", `hud-sm` (16px), Text Secondary `#94A3B8`
- **CONFIRM TRAVEL:** Disabled
- **CANCEL:** Enabled

### Populated State (destination selected)

```
    ┌────────────────────────────────┐
    │  DESTINATION                   │
    │  ─────────────────────────     │
    │                                │
    │  Shattered Flats               │  ← hud-lg (24px) Bold, Teal
    │  ── Tier 1 ──                  │  ← tier badge, hud-xs, Secondary
    │                                │
    │  ──────────────────────        │
    │                                │
    │  Distance                      │  ← hud-xs (14px), Secondary
    │  8.3 km                        │  ← data-lg (22px) Mono, Primary
    │                                │
    │  Estimated Fuel Cost           │  ← hud-xs (14px), Secondary
    │  ⛽  1 Fuel Cell               │  ← data-lg (22px) Mono, icon + value
    │                                │
    │  Your Fuel                     │  ← hud-xs (14px), Secondary
    │  ⛽  3 Fuel Cells              │  ← data-lg (22px) Mono, Green if sufficient
    │  ● Sufficient                  │  ← hud-xs (14px), Positive Green
    │                                │
    │  ──────────────────────        │
    │                                │
    │  ┌──────────────────────────┐  │
    │  │   CONFIRM TRAVEL  →      │  │  ← hud-md (20px) Bold
    │  └──────────────────────────┘  │
    │                                │
    └────────────────────────────────┘
```

### Detail Panel Spec

- **Container background:** Surface `#0A0F18` at 95%
- **Padding:** `sp-5` (20px) horizontal, `sp-4` (16px) vertical
- **Section label "DESTINATION":** `hud-xs` (14px) Bold, Text Secondary — top of zone

#### Destination Name

- **Font:** `hud-lg` (24px) Bold
- **Color:** Text Highlight `#00D4AA`
- **Tier badge:** `── Tier N ──`, `hud-xs` (14px), Text Secondary; below name with `sp-1` gap

#### Data Rows

Three data rows, each with:
- **Label:** `hud-xs` (14px), Text Secondary `#94A3B8`
- **Value:** `data-lg` (22px) Mono Medium

| Row | Label | Value Format | Value Color |
|-----|-------|-------------|-------------|
| **Distance** | "Distance" | `X.X km` | Text Primary `#F1F5F9` |
| **Fuel Cost** | "Estimated Fuel Cost" | `⛽ N Fuel Cell(s)` | Text Warning `#FFB830` (or Text Primary if sufficient) |
| **Your Fuel** | "Your Fuel" | `⛽ N Fuel Cell(s)` | Positive Green `#4ADE80` if ≥ cost; Accent Coral `#FF6B5A` if insufficient |

- **Sufficiency indicator:** Below "Your Fuel" value, `hud-xs` (14px):
  - Sufficient: `● Sufficient` in Positive Green `#4ADE80`
  - Insufficient: `⚠ Not enough fuel` in Accent Coral `#FF6B5A`

#### CONFIRM TRAVEL Button

- **Text:** "CONFIRM TRAVEL →"
- **Size:** Minimum 240px × 52px (wider than standard button to accommodate text)
- **Font:** `hud-md` (20px) Bold
- **Enabled state:** Primary Teal border (2px) + teal background fill at 20% opacity; text in Teal
- **Disabled state:** 40% opacity, Neutral `#94A3B8` border, text in Neutral; no interaction feedback
  - **Disabled reason label:** `hud-xs` (14px) Coral below button — "Need X more Fuel Cell(s)" when insufficient fuel
- **Focused:** Teal outline (2px), scale 1.02x
- **Pressed:** Scale 0.97x, brightness +10%

---

## Fuel Insufficient State

When the selected destination costs more fuel than available:

```
    Your Fuel                     ← hud-xs, Secondary
    ⛽  0 Fuel Cells              ← data-lg Mono, Coral (FF6B5A)
    ⚠ Not enough fuel            ← hud-xs (14px) Coral

    ┌──────────────────────────┐
    │   CONFIRM TRAVEL  →      │  ← 40% opacity, Neutral
    └──────────────────────────┘
      Need 1 more Fuel Cell      ← hud-xs (14px) Coral, centered below button
```

The disabled CONFIRM TRAVEL button provides a clear reason inline — no tooltip or separate explanation needed.

---

## Action Bar (Bottom of Panel)

```
    ─────────────────────────────────────────────────────────────────
                              [ CANCEL ]
```

- **CANCEL button:**
  - **Text:** "CANCEL"
  - **Font:** `hud-md` (20px)
  - **Style:** Standard button spec (Panel BG Light background, Primary Dim border)
  - **Position:** Centered in bottom action bar, above modal bottom edge
  - **Padding:** `sp-4` (16px) vertical from divider

---

## Panel States

### On Open (no destination selected)

```
Map:    All destination nodes at normal state; first available node auto-focused
Detail: "Select a destination ←" prompt; CONFIRM TRAVEL disabled
Action: CANCEL enabled, focused if no map node is focused yet
```

### Destination Focused (cursor on node, not yet confirmed)

```
Map:    Focused node has teal 2px border; detail panel NOT yet updated
Detail: Empty state OR previous selection persists
Note:   Detail panel updates ONLY on Confirm (A) press or D-pad-right to detail column
```

### Destination Selected (node confirmed)

```
Map:    Selected node has teal border + Text Highlight name; detail panel updated
Detail: Shows name, distance, fuel cost, your fuel, sufficiency indicator
        CONFIRM TRAVEL: Enabled (sufficient fuel) or Disabled with reason (insufficient)
```

### Insufficient Fuel Selected

```
Map:    Selected node still shows; no visual change on map side
Detail: Coral "Your Fuel" + "⚠ Not enough fuel" + disabled CONFIRM TRAVEL + reason label
Focus:  Returns to CANCEL button (no valid action available)
```

---

## Open / Close Behavior

| Event | Animation |
|-------|-----------|
| **Open** | Screen dim fades in 150ms; panel scales 0.95→1.0 + fades in, 200ms ease-out |
| **Focus on open** | First available destination node auto-focused (or CANCEL if all locked) |
| **Close (Cancel / [⊠])** | Panel fades out 150ms; screen dim fades out 150ms |
| **Confirm Travel** | Panel fades out 150ms; travel sequence begins (TICKET-0168) |

---

## Gamepad Navigation

```
    Biome map (left zone):
    D-pad left/right ──► move focus between destination nodes (same row)
    D-pad up/down    ──► navigate between rows (current location → destination row → action bar)
    Confirm (A)      ──► select destination AND shift focus to detail panel (CONFIRM TRAVEL button)
    D-pad right      ──► shift focus to detail panel without selecting
    Cancel (B)       ──► close modal

    Detail panel (right zone):
    D-pad up/down    ──► navigate CONFIRM TRAVEL ↔ CANCEL
    D-pad left       ──► shift focus back to biome map
    Confirm (A)      ──► press focused button (CONFIRM TRAVEL or CANCEL)
    Cancel (B)       ──► close modal

    Focus order summary:
    [Map Node] ←──► [CONFIRM TRAVEL] ──► [CANCEL]
                          ↑
                   Cancel always closes
```

- Mouse support: hover highlights nodes; click selects and confirms destination simultaneously
- Mouse on CONFIRM TRAVEL: click initiates travel if enabled

---

## Implementation Notes

- **Root:** `CanvasLayer` layer 2
- **Panel structure:** `VBoxContainer` (title bar + `HBoxContainer` (map zone + detail zone) + action bar)
- **Map zone:** `PanelContainer` wrapping a `Control` with manual node positioning for the biome graph. Node graph layout is fixed (not auto-layout) since biome count is small and fixed in M8. Implement each biome node as a `Button` scene with name/distance/cost labels
- **Detail zone:** `VBoxContainer` — destination name + tier + data rows + button row
- **Map node focus:** Use Godot's built-in `focus_neighbor_*` properties to define explicit D-pad navigation between nodes (left/right/up/down)
- **Reactive update:** Map nodes emit `biome_selected(biome_id: String)` signal; detail panel binds to this and calls `show_destination(biome_id)` to update display
- **Fuel check:** Detail panel reads FuelSystem directly to determine sufficiency; re-evaluates on `FuelSystem.fuel_changed` signal while panel is open
- **Input handling:** On open, call `InputManager` to suppress gameplay inputs and set `MOUSE_MODE_VISIBLE`; on close, restore gameplay inputs and set `MOUSE_MODE_CAPTURED`. No `get_tree().paused`. Game time continues while panel is open
- **CanvasLayer layer 2** — above HUD (layer 1); consistent with all machine panel overlays

---

## Exported Properties (for Gameplay Programmer — TICKET-0167)

| Property / Signal | Type | Purpose |
|-------------------|------|---------|
| `@export var navigation_system: NavigationSystem` | Node ref | Data source for biome registry, distances, and travel state |
| `@export var fuel_system: FuelSystem` | Node ref | Data source for current fuel level and fuel cost calculations |
| `signal travel_confirmed(destination_biome_id: String)` | Signal | Emitted when player presses CONFIRM TRAVEL with a valid destination |
| `signal panel_closed()` | Signal | Emitted when panel is dismissed without initiating travel |
| `func open_panel()` | Method | Shows panel, resets to no-selection state, sets up focus |
| `func close_panel()` | Method | Hides panel, restores input handling |
