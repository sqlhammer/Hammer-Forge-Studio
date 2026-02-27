# UI/UX Style Guide

**Owner:** ui-ux-designer
**Status:** Active
**Last Updated:** 2026-02-27

> The visual and interaction standard for all game UI. All UI scenes must comply with this guide before submission.

---

## Design Philosophy

Minimal, functional, sci-fi. The HUD exists to serve the player's situational awareness, not to decorate the screen. Every element earns its pixel space. When in doubt, show less.

**Aesthetic references:** Outer Wilds (warm instrumentation feel, handmade science tools) crossed with Hades (bold readability, high contrast against busy backgrounds). The UI should feel like a researcher's instrument panel — purposeful, legible, slightly worn.

**Gamepad-first:** All UI must be fully functional with a controller and legible at TV viewing distance (3m / 10ft from a 1080p display). Touch targets, font sizes, and spacing are set for this constraint.

---

## Color Palette

All colors are defined as hex values. Godot `Color` equivalents use `Color("hex")`.

### Core Colors

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| **Primary** | Teal | `#00D4AA` | Active UI elements, selected states, compass markers, progress fills |
| **Primary Dim** | Deep Teal | `#007A63` | Inactive/unfocused primary elements, secondary borders |
| **Secondary** | Amber | `#FFB830` | Warnings, important data callouts, star ratings, energy cost |
| **Accent** | Coral | `#FF6B5A` | Critical states, errors, low battery, urgent notifications |
| **Positive** | Green | `#4ADE80` | Full battery, successful actions, pickup confirmations |
| **Neutral** | Slate | `#94A3B8` | Disabled elements, placeholder text, dividers |

### Background & Surface Colors

| Role | Name | Hex + Alpha | Usage |
|------|------|-------------|-------|
| **Panel BG** | Dark Slate | `#0F1923` at 85% opacity | HUD panels, inventory background, modal overlays |
| **Panel BG Light** | Slate Blue | `#1A2736` at 90% opacity | Nested panels, hover highlight areas |
| **Surface** | Deep Navy | `#0A0F18` at 95% opacity | Full-screen overlays — two categories: (1) in-world non-pause overlays (inventory, Recycler, Fabricator, Tech Tree, Drone Programming — game time continues, inputs suppressed via InputManager); (2) true pause overlays (save game, keybindings, system settings — separate category, not to be conflated with in-world panels) |
| **Screen Dim** | Black | `#000000` at 50% opacity | Background dim behind overlay screens |

### Text Colors

| Role | Hex | Usage |
|------|-----|-------|
| **Text Primary** | `#F1F5F9` | Body text, labels, item names |
| **Text Secondary** | `#94A3B8` | Descriptions, secondary info, timestamps |
| **Text Highlight** | `#00D4AA` | Selected items, active labels, link-style callouts |
| **Text Warning** | `#FFB830` | Warning messages, energy cost values |
| **Text Critical** | `#FF6B5A` | Error states, critical battery, danger text |

---

## Typography

### Font Families

| Role | Font | Fallback | Notes |
|------|------|----------|-------|
| **HUD** | Godot default (Noto Sans) | System sans-serif | Clean, high legibility at distance |
| **Data / Readout** | Noto Sans Mono (or JetBrains Mono) | System monospace | Scanner output, numerical values, stack counts |
| **Headings** | Noto Sans Bold | System sans-serif bold | Panel titles, section headers |

> Note: Final font selection pending asset licensing review. All fonts must support Latin Extended for localization. Use Godot's built-in Noto Sans until custom fonts are approved.

### Size Scale

Base unit: **16px** at 1920x1080. All sizes scale proportionally with resolution.

| Token | Size (px) | Weight | Usage |
|-------|-----------|--------|-------|
| `hud-xs` | 14 | Regular | Tertiary labels, stack sub-counts |
| `hud-sm` | 16 | Regular | Standard HUD text, descriptions |
| `hud-md` | 20 | Medium | Item names, compass labels, readout values |
| `hud-lg` | 24 | Bold | Panel titles, notification headlines |
| `hud-xl` | 32 | Bold | Large overlay titles (inventory header) |
| `data` | 18 | Mono Regular | Numerical readouts, percentages, distances |
| `data-lg` | 22 | Mono Medium | Highlighted numerical values, energy cost |

### Line Height

- Body text: 1.4x font size
- HUD labels: 1.2x font size (tighter for compact panels)
- Data readouts: 1.0x font size (single-line, no wrapping)

---

## Spacing System

Base unit: **4px**. All spacing uses multiples of the base unit.

| Token | Value | Usage |
|-------|-------|-------|
| `sp-1` | 4px | Minimum gap, icon-to-text inline spacing |
| `sp-2` | 8px | Tight padding (compact HUD elements) |
| `sp-3` | 12px | Standard inner padding for panels |
| `sp-4` | 16px | Standard gap between sibling elements |
| `sp-5` | 20px | Section separation within a panel |
| `sp-6` | 24px | Panel outer margin, major section gaps |
| `sp-8` | 32px | Screen-edge safe margin (minimum) |

### Screen-Edge Safe Area

All HUD elements must maintain a minimum **32px (sp-8)** margin from any screen edge. This accounts for TV overscan and ensures nothing is clipped on console displays.

---

## Interaction States

All interactive UI elements must visually communicate their current state. States are conveyed through color, opacity, and scale — never through color alone (accessibility).

| State | Visual Treatment |
|-------|-----------------|
| **Normal** | Base color at 100% opacity |
| **Focused** | Teal (`#00D4AA`) 2px outline + slight scale up (1.02x). Focus is always visible — no invisible focus states |
| **Hovered** | Background lightens to Panel BG Light; text shifts to Text Highlight. Mouse-only — gamepad uses Focused |
| **Pressed** | Scale down (0.97x) + brightness boost (+10%). Quick 50ms transition |
| **Disabled** | 40% opacity, Neutral color (`#94A3B8`). No interaction feedback. Cursor/focus skips disabled elements |
| **Selected** | Teal left-border (3px) or teal background fill at 20% opacity. Persistent until deselected |

### Transitions

- State changes: **100ms** ease-out
- Panel open/close: **200ms** ease-out
- Notification appear: **150ms** slide-in from right
- Notification dismiss: **300ms** fade-out

---

## Component Standards

### Panel

The standard container for grouped UI content.

- Background: Panel BG (`#0F1923` at 85%)
- Border: 1px solid `#1A2736`
- Border radius: 4px
- Inner padding: `sp-3` (12px)
- Optional title bar: `hud-lg` bold, bottom-border 1px `#1A2736`

### Button

- Min size: 48x48px (gamepad/touch target)
- Padding: `sp-2` vertical, `sp-4` horizontal
- Font: `hud-md` medium
- Background: Panel BG Light
- Border: 1px solid Primary Dim
- Border radius: 4px
- Focus: Teal outline (2px)

### Progress Bar

Used for battery, mining progress, and any timed fill.

- Height: 8px (compact / HUD) or 16px (prominent / mining)
- Background: `#1A2736`
- Fill: Primary Teal (default), state-dependent color override
- Border radius: 2px (half height for compact, 4px for prominent)
- No border

### Star Rating (Purity)

- 5 stars displayed, filled stars colored Amber (`#FFB830`), empty stars Neutral (`#94A3B8`)
- Star size: 16x16px (compact readout) or 24x24px (detail view)
- Gap between stars: `sp-1` (4px)

### Tooltip / Info Popup

- Background: Panel BG at 90% opacity
- Border: 1px solid Primary Dim
- Padding: `sp-2`
- Font: `hud-sm`
- Max width: 280px
- Appears after 400ms hover (mouse) or on [Info] button press (gamepad)
- Arrow/caret pointing toward source element

### Notification Toast

- Width: 300px
- Background: Panel BG at 90%
- Left border: 3px colored by type (Positive = green, Warning = amber, Critical = coral)
- Padding: `sp-3`
- Auto-dismiss: 3 seconds (configurable per notification type)
- Stacks vertically (max 3 visible, oldest dismissed first)

### Resource Gauge (Battery / Fuel)

The canonical pattern for any persistent "resource meter" shown in the HUD. Used by the suit battery bar and the ship fuel gauge.

**Structure:** `[Icon 24×24px] [sp-2] [Progress Bar 160×10px] [sp-2] [Label ~40px]`

- **Container:** `HBoxContainer`, anchored per-element position (see individual wireframes for anchor)
- **Icon:** HUD line icon, 24×24px, color matches current state
- **Bar:** 160px wide, 10px tall. Background `#1A2736`, fill color = current state color, 2px border radius, no border
- **Label:** `data` (18px) Mono, integer percentage format (`XX%`), color matches current state

**States (shared across all resource gauges):**

| State | Condition | Color | Special Behavior |
|-------|-----------|-------|-----------------|
| **Full** | 100% | Positive Green `#4ADE80` | Static |
| **Normal** | 26%–99% | Primary Teal `#00D4AA` | Fill decreases as resource drains |
| **Warning** | 1%–25% | Amber `#FFB830` | Slow pulse (opacity 70%→100%, 1.5s loop) |
| **Empty** | 0% | Accent Coral `#FF6B5A` | No fill; icon flashes 0.5s on/off for 3s, then holds 50% opacity |

**Triple-encoding rule:** State must be communicated by color + fill level + animated pulse — never color alone. Required for color-blind accessibility and TV viewing distance legibility.

**Adding a new resource gauge:** Follow this pattern. Define per-element anchor position in the individual HUD wireframe. Do not introduce a new visual language for resource meters without Studio Head approval.

### Biome Node Map

Used by the navigation console modal. An abstract node graph representing the travel network between biomes.

**Purpose:** Spatial navigation UI for selecting a travel destination. Not a geographic map — a logical graph of travel connections.

**Node types:**

| Node Type | Border | Background | Opacity | Notes |
|-----------|--------|------------|---------|-------|
| **Current location** | 2px solid Teal `#00D4AA` | Panel BG Light `#1A2736` at 90% | 100% | `◉` indicator icon; not focusable |
| **Available destination** | 1px solid `#1A2736` (normal) / 2px solid Teal (focused/selected) | `#1A2736` at 70% | 100% | Focusable; shows name + distance + fuel cost |
| **Locked destination** | 1px dashed Neutral `#94A3B8` | `#1A2736` at 40% | 40% | Lock icon; not focusable |

**Path lines:** 1px solid Primary Dim `#007A63` connecting parent nodes to child destination nodes.

**Information per node:** Name (`hud-sm` 16px), distance (`▶ X.X km`, `hud-xs` 14px), estimated fuel cost (`⛽ N cells`, `hud-xs` 14px).

**Layout:** Fixed manual positioning within a `Control` container — not auto-layout. Biome graph topology is defined per milestone based on the registered biome count.

---

## Icon Style

Icon design is split into two categories with separate authoritative specifications:

- **Item icons** (inventory slots, tech tree node cards, machine panels): see [`docs/art/icon-style-guide-items.md`](../art/icon-style-guide-items.md)
- **HUD/functional icons** (suit battery, compass, status indicators, notifications, tech tree state): see [`docs/art/icon-style-guide-hud.md`](../art/icon-style-guide-hud.md)

### Size Grid Summary

| Category | Sizes |
|----------|-------|
| Item icons | 48×48px (primary), 32×32px (secondary), 28×28px (compact) |
| HUD/functional icons | 16×16px (inline), 24×24px (standard), 32×32px (large/prominent) |

### Format & Generation

- **Format:** SVG (primary); PNG with alpha at minimum 256px (item) / 72px (HUD) as fallback
- **Generation method:** Method A — Programmatic SVG (Python direct XML construction). See [`docs/art/icon-poc-report.md`](../art/icon-poc-report.md) for full pipeline documentation and evaluation results.
- **Naming convention:** `icon_item_[name].svg` for item icons; `icon_hud_[name].svg` for HUD icons

### Shared Rules

- HUD icons: stroke-based (`stroke="currentColor"`, `fill="none"`), 2px stroke weight, rounded caps/joins — color inherited via Godot `modulate` on `TextureRect`
- Item icons: 2px stroke weight, rounded caps/joins, isometric/3-quarter view perspective
- Never convey state through color alone — pair with shape or label (see Accessibility section)
- **Contrast requirements** (approved stroke/fill palette and minimum luminance threshold against in-game panel backgrounds) are defined in each category's style guide — see the **Contrast Requirements** section of `icon-style-guide-items.md` and `icon-style-guide-hud.md`

---

## Accessibility

### Contrast Ratios

All text must meet **WCAG AA** minimum contrast:
- Normal text (< 24px): 4.5:1 against background
- Large text (>= 24px): 3:1 against background
- UI components and graphical objects: 3:1 against adjacent colors

Verified combinations:
- Text Primary (`#F1F5F9`) on Panel BG (`#0F1923`): ~15:1 (passes AAA)
- Text Secondary (`#94A3B8`) on Panel BG (`#0F1923`): ~6.5:1 (passes AA)
- Primary Teal (`#00D4AA`) on Panel BG (`#0F1923`): ~8:1 (passes AA)
- Amber (`#FFB830`) on Panel BG (`#0F1923`): ~8.5:1 (passes AA)

### Minimum Touch/Focus Targets

- All interactive elements: minimum **48x48px** hit area
- Gamepad focus navigation: logical grid/list order, no diagonal-only targets
- Focus must be visible at all times during gamepad navigation

### Text Size Minimums

- Minimum readable text: **14px** (`hud-xs`) — used sparingly for tertiary info
- Standard minimum: **16px** (`hud-sm`) — default body text
- Critical gameplay info (battery %, distance): **18px** (`data`) minimum

### Color-Blind Safety

- Never convey meaning through color alone — always pair with icon, shape, or text label
- Battery states use both color AND fill level
- Star ratings use filled/empty shape distinction, not just color
- Notifications use left-border color AND icon type

---

## Resolution Targets

| Setting | Value |
|---------|-------|
| **Target resolution** | 1920x1080 (1080p) |
| **Minimum supported** | 1280x720 (720p) |
| **Maximum tested** | 3840x2160 (4K) |
| **Aspect ratio** | 16:9 primary; 21:9 ultrawide supported (HUD anchored, no stretch) |
| **UI scale mode** | Godot `canvas_items` stretch mode, `expand` aspect |
| **DPI scaling** | All measurements in this guide are at 1080p baseline; Godot's built-in scaling handles higher/lower resolutions |

### Safe Area

- **All edges:** 32px minimum margin at 1080p
- **TV overscan compensation:** Godot's safe area API respected; no critical info in outer 5% of screen

---

## Godot Implementation Notes

- Use `Theme` resources for consistent styling across scenes
- Define all colors as `Theme` color constants, not hardcoded per-node
- Use `StyleBoxFlat` for panels and buttons (border radius, background color, border)
- HUD elements use `CanvasLayer` (layer 1) — always rendered above 3D world
- Overlay screens (inventory) use `CanvasLayer` (layer 2) — above HUD
- All UI text through Godot `Label` or `RichTextLabel` with theme-defined fonts
- Animation: use `Tween` for state transitions, not `AnimationPlayer` (simpler, more flexible for UI)
