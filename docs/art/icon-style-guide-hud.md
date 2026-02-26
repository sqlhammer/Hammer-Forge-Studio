# HUD / Functional Icon Style Guide

**Owner:** ui-ux-designer
**Ticket:** TICKET-0091
**Date:** 2026-02-25
**Status:** Active

> Authoritative visual specification for all HUD and functional icons in *The Inheritance*. HUD icons communicate state and action — not object identity. They appear across the first-person HUD, third-person HUD, Ship Globals status panel, Ship Stats Sidebar, tech tree node cards, and notification toasts. All icon generation experiments (TICKET-0092–0094) must meet this specification for their HUD icon outputs. This document supersedes the single-line icon entry in `docs/design/ui-style-guide.md` for HUD/functional icons.

---

## Aesthetic Direction

HUD icons in *The Inheritance* are **functional glyphs** — immediately legible communicative symbols that feel like the readouts of a researcher's instrument panel. At their smallest size (16×16px inline), only the most essential form survives. The aesthetic is purposeful, calibrated, and scientific: closer to the indicator lights and dials of field equipment than to polished consumer product iconography.

HUD icons differ from item icons fundamentally: **item icons are object portraits; HUD icons are signals.** A battery icon communicates charge level, not the physical appearance of the battery. A lock icon communicates a gated state, not an accurate padlock. Legibility at 16px outweighs visual richness at every trade-off point.

**These icons are NOT:**
- Object portraits — HUD icons do not show realistic objects; they represent the *concept* of the state or action
- Decorative — no flourishes, extra strokes, or detail that adds visual interest but reduces legibility at 16px
- Fixed-color — most HUD icons must inherit their color from the parent node; hardcoded SVG colors break the runtime state-based color system

**Visual References:**

| Reference | What to Take From It |
|-----------|---------------------|
| *Outer Wilds* — transmitter and instrument readout icons | Minimal, line-based, scientific instrument feel; icons read as drawn on paper rather than designed in Illustrator; every mark is purposeful |
| *Alien: Isolation* — motion tracker and station HUD glyphs | Functional readout style: recognizable symbol with zero decorative excess; the icons feel like they belong on actual manufactured equipment, not a game UI |
| *Dead Cells* — status effect icons | Extreme legibility at small sizes through geometric reduction; pure line symbols with clear positive/negative shape distinction; zero interior fill detail |

---

## Size & Grid

HUD icons must be legible across three display sizes. The **design master is 32×32px** — design at 32px, then verify legibility at 16px before finalizing. An icon that passes the 16px legibility test will always read correctly at 24px and 32px.

| Size Token | Display Size | Usage |
|-----------|-------------|-------|
| `icon-sm` | 16×16px | Inline HUD text labels: scanner readout, compass tick markers, tech tree state indicators, notification badge |
| `icon-md` | 24×24px | Standard HUD status indicators: drone indicator, suit battery, mining active, scan ping |
| `icon-lg` | 32×32px | Prominent ship status icons in Ship Stats Sidebar; large HUD elements |

### Canvas & Safe Area

All HUD icons use a **24×24 unit grid** (`viewBox="0 0 24 24"`), consistent with item icons.

- **Active design area:** 20×20 units (2-unit inset from each canvas edge)
- **Stroke-to-gap minimum:** At 16px display, any gap between strokes must be at least 2 units on the 24-unit canvas. Gaps narrower than 2 units merge into visual noise at small sizes.
- **No width/height attributes** on the `<svg>` element — use `viewBox="0 0 24 24"` only.

**16px legibility check (required before submission):** Render or screenshot the SVG at exactly 16×16px display size. Confirm the primary symbol concept is identifiable without any label. Confirm no two stroke paths merge into a solid blob. Simplify if either test fails.

---

## Color Usage

### Default: Inherit Parent Color

HUD icons use `stroke="currentColor"` on all paths. The icon inherits whatever color the parent `CanvasItem` or `TextureRect` applies via the `modulate` property — typically Text Primary (`#F1F5F9`). **Do not hardcode any color value in the SVG file itself.**

This inheritance rule enables GDScript to drive all color changes without per-icon overrides.

### State-Based Color Overrides

State colors are applied at **runtime in GDScript via `modulate`**, not in the SVG. The table below defines which icons accept state-based color and what each state uses:

| Icon | Normal | Warning | Critical | Good / Active | Idle / Fixed |
|------|--------|---------|----------|---------------|--------------|
| `icon_hud_battery` | Teal `#00D4AA` | Amber `#FFB830` | Coral `#FF6B5A` | — | — |
| `icon_hud_power` | Teal `#00D4AA` | — | Coral `#FF6B5A` | — | — |
| `icon_hud_integrity` | Green `#4ADE80` | — | Coral `#FF6B5A` | — | — |
| `icon_hud_heat` | Teal `#00D4AA` | Amber `#FFB830` | Coral `#FF6B5A` | — | — |
| `icon_hud_oxygen` | Teal `#00D4AA` | Amber `#FFB830` | Coral `#FF6B5A` | — | — |
| `icon_hud_drone` | — | — | — | Teal `#00D4AA` | Neutral `#94A3B8` |
| `icon_hud_notification_info` | — | — | — | — | Green `#4ADE80` (fixed) |
| `icon_hud_notification_warning` | — | — | — | — | Amber `#FFB830` (fixed) |
| `icon_hud_notification_critical` | — | — | — | — | Coral `#FF6B5A` (fixed) |
| `icon_hud_lock` | — | — | — | — | Neutral `#94A3B8` (fixed) |
| `icon_hud_unlock_chevron` | — | — | — | — | Amber `#FFB830` (fixed) |
| `icon_hud_unlock_check` | — | — | — | — | Green `#4ADE80` (fixed) |
| All others | Inherits | — | — | — | — |

Icons listed as "fixed" have a color set once at scene load. Notification badge icons are three separate assets with their own fixed colors — they are not one icon tinted at runtime.

### Accessibility: Color Is Never the Only Signal

Per the UI style guide accessibility rule, state must always be conveyed by at least two signals. In practice:
- Ship status icons: color paired with progress bar fill level
- Tech tree state icons: color paired with distinct icon shape (lock vs. chevron vs. checkmark)
- Notification badges: color paired with distinct icon symbol (info "i" vs. warning "!" vs. critical "!")

---

## Contrast Requirements

> Added by TICKET-0104 — post-integration QA identified readability failures against in-game panel backgrounds.

### Known Background Colors

HUD icons appear on the following in-game surfaces (hex values from `docs/design/ui-style-guide.md`):

| Surface | Hex | Opacity | Usage |
|---------|-----|---------|-------|
| Panel Background | `#0F1923` | 85% | HUD overlay panels, suit status bar, Ship Stats Sidebar, notification toasts |
| Panel Background Light | `#1A2736` | 90% | Nested HUD elements, active state backgrounds |
| Surface (Full-screen Overlay) | `#0A0F18` | 95% | Tech tree panel, drone programming panel |

The effective darkest background is **`#0A0F18`** (Surface Deep Navy). All contrast thresholds are measured against this value.

### Minimum Contrast Threshold

The icon's rendered stroke color must achieve a **minimum contrast ratio of 4.5:1** against `#0A0F18`. At 16×16px (the smallest HUD display size), reduced pixel count makes readability acutely sensitive to contrast — 4.5:1 is the minimum viable threshold.

All state-based colors from the Color Usage table above meet this threshold **except**:
- `#94A3B8` (Neutral Slate): ~5:1 — borderline pass; use only for locked/idle states where reduced salience is intentional
- `#007A63` (Deep Teal): ~2.8:1 — **fails**; do not use as a HUD icon stroke or modulate color
- `#000000` (Black / unset currentColor): 1:1 — **fails**; do not allow as an icon color

### Stroke Color Rule (Critical Fix)

**Do not use `stroke="currentColor"` in HUD icon SVG files.** In Godot's SVG renderer, `currentColor` resolves to **black (`#000000`)** when no CSS `color` is set by the parent — producing near-zero contrast against dark panel backgrounds.

**Required base stroke color:** Replace `stroke="currentColor"` on the `<svg>` root element with `stroke="#FFFFFF"` (white).

Use `#FFFFFF` — not `#F1F5F9` — for HUD icons. Godot's `modulate` tints icons by multiplying each color channel:
- `modulate = Color("#00D4AA")` on **white stroke** → teal stroke ✅
- `modulate = Color("#00D4AA")` on **`#F1F5F9` stroke** → desaturated, bluish-teal (incorrect hue) ❌
- `modulate = Color("#00D4AA")` on **black stroke** → black (invisible) ❌

White is the only base color that allows GDScript `modulate` to produce the exact intended hue for every state.

**Fill paths** that currently use `fill="currentColor"` (`icon_hud_star_filled`, `icon_hud_compass_ping`, and any thermometer-bulb fill) must also change to `fill="#FFFFFF"` in the SVG so that `modulate` controls the fill color correctly at runtime.

### Outline Rule

HUD icons are stroke-only by specification — no fill-based outline rule applies in normal usage.

If a future revision adds a background or drop-shadow to a HUD icon (e.g., for accessibility improvement at very small sizes), the background element must use `fill="#0A0F18"` at 80%+ opacity as a backing plate, and must not reduce the icon stroke's effective contrast ratio below 4.5:1.

### Approved Modulate Colors (Runtime Stroke Palette)

HUD icon SVG files use `stroke="#FFFFFF"`. The effective display color is set at runtime via GDScript `modulate`. The 4 approved `modulate` values that meet the contrast threshold:

1. **`#F1F5F9`** — Text Primary; default/inherit state for icons without explicit state colors (~17:1)
2. **`#00D4AA`** — Primary Teal; Normal/Active state for battery, power, heat, oxygen, drone (~9:1)
3. **`#FFB830`** — Amber; Warning state and fixed colors for unlock_chevron, notification_warning (~9:1)
4. **`#FF6B5A`** — Coral; Critical state and fixed color for notification_critical (~5.5:1)

Additional approved modulate colors from the state table: `#4ADE80` (Green, ~7:1) for integrity/unlock_check/notification_info; `#94A3B8` (Neutral, ~5:1) for drone idle and lock. Do not use any color outside this set or the state table in Color Usage above.

---

## Style Constraints

### Stroke Specification

- `stroke-width="2"` on the 24-unit canvas
- `stroke-linecap="round"` — all open line ends are rounded
- `stroke-linejoin="round"` — all path corners are rounded
- `fill="none"` — **HUD icons are stroke-only; no interior fill shapes**
- `stroke="currentColor"` — inherits from parent at runtime

HUD icons must be pure line icons. No interior fills, no semi-transparent fill layers, no background shapes. The stroke IS the icon. (The sole exception is `icon_hud_star_filled` — see **Icon List** below.)

### Symbol vs. Pictographic Approach

| Approach | When to Use |
|----------|-------------|
| **Abstract symbol** | State indicators, navigation markers, action triggers (compass ticks, scan ping arcs, notification badge symbols) |
| **Recognizable pictograph** | Status items where the real-world object communicates the concept at a glance: battery → lightning bolt, shield → integrity, thermometer → heat, atom → oxygen |

Default to the simplest symbol that communicates the concept. A lightning bolt for power is more legible at 16px than any circuit board or plug representation.

### Complexity Ceiling

At 16×16px, the icon's primary form must be identifiable with zero surrounding context. This enforces a strict detail budget:

- **Maximum stroke paths:** 3–5 paths for standard 16px HUD icons; up to 7–8 paths for design-master 32px icons (battery bolt, compass ping, drone)
- **Minimum gap between any two strokes:** 2 units on the 24-unit canvas (~1px at 24px display; scales to ~1.3px at 32px display)
- **No text or numeric labels** — the icon must communicate without glyphs at any size

---

## Output Format

| Property | Value |
|----------|-------|
| **Primary format** | SVG |
| **viewBox** | `0 0 24 24` |
| **Stroke width** | `stroke-width="2"` |
| **Linecap** | `stroke-linecap="round"` |
| **Linejoin** | `stroke-linejoin="round"` |
| **Fill** | `fill="none"` (all HUD icons stroke-only; exception: `icon_hud_star_filled`) |
| **Color** | `stroke="currentColor"` |
| **Width / Height attributes** | Omit from `<svg>` element |
| **Raster export (PNG fallback)** | Minimum 72×72px PNG with alpha (@3x of 24px baseline display) |
| **Naming convention** | `icon_hud_[name].svg` |

### Required File Names (full set — 20 icons)

```
icon_hud_battery.svg
icon_hud_scanner.svg
icon_hud_battery_micro.svg
icon_hud_star_filled.svg
icon_hud_star_empty.svg
icon_hud_compass_center.svg
icon_hud_compass_ping.svg
icon_hud_power.svg
icon_hud_integrity.svg
icon_hud_heat.svg
icon_hud_oxygen.svg
icon_hud_notification_info.svg
icon_hud_notification_warning.svg
icon_hud_notification_critical.svg
icon_hud_lock.svg
icon_hud_unlock_chevron.svg
icon_hud_unlock_check.svg
icon_hud_mining_active.svg
icon_hud_scan_ping.svg
icon_hud_drone.svg
```

---

## Icon List Coverage

All 20 HUD/functional icons from the audit (TICKET-0086) are covered by this guide. The uniform style specification (stroke-only, `currentColor`, 24-unit canvas, `stroke-width="2"`) applies to all of them. Recommended symbol shapes per icon:

| Icon | Recommended Shape / Symbol | Notes |
|------|--------------------------|----|
| `icon_hud_battery` | Lightning bolt — 3–4 angled line segments forming a downward zig-zag | Standard power/energy symbol; readable at 16px |
| `icon_hud_scanner` | Diamond (rotated square) — 4 lines forming a ◆ shape | Matches existing text glyph placeholder |
| `icon_hud_battery_micro` | Simplified lightning bolt — 2–3 segments, fewer points than the full battery icon | Inline-only; must work at 16px |
| `icon_hud_star_filled` | 5-pointed star with `fill="currentColor"` | **Exception:** this icon uses fill to communicate "selected/earned." Apply `fill="currentColor"` to the star path. Only HUD icon with fill. |
| `icon_hud_star_empty` | 5-pointed star, stroke only, `fill="none"` | Pair with star_filled to show purity rating |
| `icon_hud_compass_center` | Vertical tick mark — single short line segment or narrow downward caret | Minimal; must not overwhelm the compass bar |
| `icon_hud_compass_ping` | Downward-pointing filled triangle or inverted caret — 3-line triangle | Can use `fill="currentColor"` (solid triangle is more legible than outlined at 10px) |
| `icon_hud_power` | Lightning bolt, consistent with `icon_hud_battery` — may be rotated 15° | Matches Ship Globals HUD letter-P placeholder convention |
| `icon_hud_integrity` | Shield outline — arc top + straight sides + V-bottom; no interior detail | Standard shield silhouette; 4–5 path segments |
| `icon_hud_heat` | Thermometer — vertical line with filled bulb at base; 2–3 horizontal tick marks on the side | Bulb can use `fill="currentColor"` for visual clarity |
| `icon_hud_oxygen` | Atom symbol — circle with 2 orbital ellipse arcs crossing it, or simple O-with-subscript-2 abstraction | 3 paths: circle + 2 elliptical arcs |
| `icon_hud_notification_info` | Lowercase "i" in a circle — standard informational badge | Circle stroke + single dot + vertical bar |
| `icon_hud_notification_warning` | Exclamation mark in an upward-pointing triangle — standard warning | Triangle stroke + "!" inside (dot + bar) |
| `icon_hud_notification_critical` | Exclamation mark in an octagon or thick circle — standard error/critical | Distinct from warning triangle; octagon or circle differentiator |
| `icon_hud_lock` | Padlock — shackle arch (semicircle) + rectangular body; 3–4 paths | No keyhole — too small at 16px |
| `icon_hud_unlock_chevron` | Upward-pointing chevron "^" — two-line angular caret | Not a full arrow; just the caret shape |
| `icon_hud_unlock_check` | Checkmark "✓" — two-line angular check; left-down stroke + longer right-up stroke | Keep the angle steep enough to read at 16px |
| `icon_hud_mining_active` | Drill bit or pick — diagonal tool shape with small rotation indicator arc | Abstract; does not need to match `icon_item_hand_drill` exactly |
| `icon_hud_scan_ping` | Expanding arc set — 2–3 concentric arcs of increasing radius, open on one side (radar sweep feel) | 2–3 path elements; rightmost arc largest |
| `icon_hud_drone` | Quadcopter silhouette — small central circle + 4 short rotor lines at 45°/135°/225°/315° | Or abstracted as X-shape with corner nodes; must read at 24px |

**Note on `icon_hud_star_filled`:** This is the only HUD icon that uses `fill="currentColor"`. A filled star communicates "earned/selected" state vs. the empty star's "unearned" state — the fill is semantically required. All other HUD icons remain stroke-only.

**Note on `icon_hud_compass_ping`:** A solid (filled) triangle is recommended for the compass ping at its 10×8px display size. At that size, a stroke-only triangle outline may collapse. Use `fill="currentColor"` on the triangle path.

---

## Godot Integration Notes

### Dynamic Tinting at Runtime

All HUD icons are tinted via GDScript `modulate` on the `TextureRect` or parent `CanvasItem`. Because the SVG uses `currentColor`, `modulate` tints both stroke and any fill uniformly. Example pattern:

```gdscript
func _update_status_icon_color(icon_rect: TextureRect, value: float, max_value: float) -> void:
    var ratio := value / max_value
    if ratio > 0.5:
        icon_rect.modulate = Color("#00D4AA")  # Teal — normal
    elif ratio > 0.25:
        icon_rect.modulate = Color("#FFB830")  # Amber — warning
    else:
        icon_rect.modulate = Color("#FF6B5A")  # Coral — critical
```

Do not set colors in the SVG file itself. All color control must flow through GDScript `modulate`.

### Import Settings (SVG)

| Setting | Value |
|---------|-------|
| Scale | `2.0` |
| Compress | Lossless |
| Mipmaps | On (required for 16px inline display) |
| Color space | sRGB |
| Filter | Linear (not Nearest — these are not pixel-art icons) |

### Battery Bar Integration Note

`battery_bar.gd` currently draws the battery icon procedurally via `_draw_battery_icon()` on a `CanvasItem`. When the production SVG is available, replace the procedural draw with a `TextureRect` node in the scene:

```gdscript
# Replace _draw_battery_icon() with SVG texture load
@onready var _icon_rect: TextureRect = $BatteryIconRect
var _battery_icon := preload("res://assets/icons/hud/icon_hud_battery.svg")

func _ready() -> void:
    _icon_rect.texture = _battery_icon
    # Remove _draw() override and _draw_battery_icon() call from this script
```

This requires a GDScript change and scene edit — it is not a drop-in asset replacement. The `_draw()` call must be removed and a `TextureRect` child node added in the scene.

### Tech Tree State Icons Note

`tech_tree_panel.gd` currently renders state icons as Label text (`🔒`, text chevrons, checkmarks). When production SVG assets are available, replace each Label with a `TextureRect` loaded from the corresponding `icon_hud_lock.svg`, `icon_hud_unlock_chevron.svg`, or `icon_hud_unlock_check.svg` asset, and set `modulate` to the appropriate fixed color at scene load.

---

## Source Path

Final approved icons are committed to: `game/assets/icons/hud/`
