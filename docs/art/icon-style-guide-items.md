# Item Icon Style Guide

**Owner:** ui-ux-designer
**Ticket:** TICKET-0090
**Date:** 2026-02-25
**Status:** Active

> Authoritative visual specification for all item icons in *The Inheritance*. Item icons represent physical game objects and appear in inventory slots, tech tree node cards, machine interaction panels (Recycler, Fabricator), and pickup notifications. All icon generation experiments (TICKET-0092–0094) must meet this specification for their item icon outputs. This document supersedes the single-line icon entry in `docs/design/ui-style-guide.md` for item icons.

---

## Aesthetic Direction

Item icons in *The Inheritance* are **stylized line-art portraits of physical objects** — rendered with the precision of engineering diagrams and the warmth of hand-drawn field notes. Each icon reads at a glance as a recognizable object with a clear material identity (salvaged metal, refined ingot, worn equipment, ship-scale machinery), not as an abstract symbol. The feel should evoke a researcher cataloging tools in a worn field journal: functional, specific, slightly imperfect.

**These icons are NOT:**
- Photorealistic renders — no gradients, no ambient occlusion bakes, no lighting simulations
- Flat cartoon icons — no bubbly outlines, no pastel fills, no generic "UI pack" energy
- Generic stock icons — every icon must be recognizable as a specific object from *The Inheritance*'s world and not interchangeable with icons from another game

**Visual References:**

| Reference | What to Take From It |
|-----------|---------------------|
| *Outer Wilds* — inventory and equipment UI | Warm line weight, a slight imprecision that reads as handmade; materials are suggested through geometric detail rather than texture maps; each icon feels authored |
| *Hades* — item card icons | Strong silhouettes that read instantly at small sizes; bold, confident strokes; flat fill areas add visual weight without photorealism or gradients |
| *Dead Cells* — inventory item icons | Crisp linework, clear material differentiation (metal vs. organic vs. energy), economical detail — every line serves the silhouette; nothing decorative is present |

---

## Size & Grid

**Primary display size:** 48×48px (inventory slots, tech tree node cards)
**Secondary display size:** 32×32px (Fabricator/Recycler machine panel recipe list rows)
**Compact display size:** 28×28px (pickup notification toasts)

### Canvas & Safe Area

All icons are designed on a **24×24 unit grid** (`viewBox="0 0 24 24"`). Icon content must stay within an **inner safe area of 20×20 units** (2-unit margin on all sides). No stroke path may touch or cross the canvas edge.

- Stroke weight: `stroke-width="2"` (one-twelfth of the canvas width — scales proportionally with display size)
- Total canvas: 24×24 units
- Active design area: 20×20 units (2-unit inset from each edge)

**Scale rendering:** Godot scales the SVG from the 24-unit canvas to the target display size. Do not set `width` or `height` attributes on the `<svg>` element — use `viewBox="0 0 24 24"` only.

---

## Color Usage

Item icons use a **two-layer color system**: a stroke layer and an optional flat fill layer.

### Stroke Color

`stroke="currentColor"` — the stroke inherits the parent node's rendered text color at runtime. In standard inventory and panel contexts this is Text Primary (`#F1F5F9`). This allows the icon to automatically respond to disabled states (Neutral color `#94A3B8` at 40% opacity) without any per-icon GDScript override.

### Fill Color (Optional)

Item icons may use one **accent fill** to communicate material identity. One fill per icon, flat and uniform — no gradients, no opacity variation within the fill shape. If no fill is used, set `fill="none"` on all paths.

Allowed fill palette — these fills are intentionally subtle, adding visual weight without competing with the stroke layer:

| Material Category | Recommended Fill | Hex + Alpha |
|------------------|----------------|-------------|
| Metal / refined material | Very dark navy | `#0A0F18` at 15% opacity |
| Energy / power cell | Teal (very low) | `#00D4AA` at 12% opacity |
| Worn handheld equipment | No fill (stroke only) | — |
| Ship module (tech-scale) | Deep teal (very low) | `#007A63` at 18% opacity |

Do not use Amber, Coral, or Green as item icon fill colors. Those hues are reserved for HUD state communication and would create false urgency on static inventory icons.

### Background

**Transparent background.** No containing circle, rounded rect, or border shape behind the icon content. The icon floats on the inventory slot's background surface, which is defined separately in the UI scene. The icon asset itself has no background.

---

## Contrast Requirements

> Added by TICKET-0104 — post-integration QA identified readability failures against in-game panel backgrounds.

### Known Background Colors

Item icons appear on the following in-game surfaces (hex values from `docs/design/ui-style-guide.md`):

| Surface | Hex | Opacity | Usage |
|---------|-----|---------|-------|
| Panel Background | `#0F1923` | 85% | Inventory screen background, machine interaction panels (Recycler, Fabricator), tech tree node cards |
| Panel Background Light | `#1A2736` | 90% | Individual inventory slot backgrounds, nested panels |
| Surface (Full-screen Overlay) | `#0A0F18` | 95% | Full-screen overlays (inventory, tech tree) |

The effective darkest background is **`#0A0F18`** (Surface Deep Navy). All contrast thresholds below are measured against this value — meeting the threshold here guarantees readability on all lighter panel surfaces.

### Minimum Contrast Threshold

The icon's primary stroke color must achieve a **minimum contrast ratio of 4.5:1** against `#0A0F18`. Contrast ratios for reference colors:

| Color | Hex | Contrast vs `#0A0F18` | Status |
|-------|-----|----------------------|--------|
| Text Primary | `#F1F5F9` | ~17:1 | ✅ Approved |
| Primary Teal | `#00D4AA` | ~9:1 | ✅ Approved |
| Amber | `#FFB830` | ~9:1 | ✅ Approved |
| Positive Green | `#4ADE80` | ~7:1 | ✅ Approved |
| Neutral Slate | `#94A3B8` | ~5:1 | ⚠️ Borderline — use sparingly |
| Deep Teal | `#007A63` | ~2.8:1 | ❌ Fails — do not use as stroke |
| Black | `#000000` | 1:1 | ❌ Fails — do not use as stroke |

### Stroke Color Rule (Critical Fix)

**Do not use `stroke="currentColor"` in item icon SVG files.** In Godot's SVG renderer, `currentColor` resolves to **black (`#000000`)** when no CSS `color` is set by the parent — producing near-zero contrast against the game's dark panel backgrounds.

**Required stroke color:** Replace `stroke="currentColor"` on the `<svg>` root element with `stroke="#F1F5F9"` (Text Primary). Set this value directly in the SVG file.

`#F1F5F9` gives item icons their intended light appearance in inventory slots, machine panels, and tech tree node cards without requiring per-scene GDScript color overrides.

### Outline Rule

The accent fill colors defined in the Color Usage section (`#0A0F18` at 15% opacity, `#00D4AA` at 12%, `#007A63` at 18%) are too low-opacity to carry the visual weight of the icon — the **stroke is the primary contrast surface**. The stroke color change to `#F1F5F9` is the primary fix.

If any path omits a visible stroke (e.g., a fill-only decorative shape is added in a future revision), that path must include `stroke="#F1F5F9"` at `stroke-width="2"` to remain readable against dark panel backgrounds.

### Approved Stroke Colors

Use one of these 4 approved hex values as the stroke color for item icon SVG root elements:

1. **`#F1F5F9`** — Text Primary; use for all production item icons in neutral state (default)
2. **`#00D4AA`** — Primary Teal; permitted if the specific item has a teal/energy identity
3. **`#FFB830`** — Amber; permitted for items with a warning or energy-cost identity; use sparingly
4. **`#4ADE80`** — Positive Green; permitted for items with a complete or beneficial identity; use sparingly

Default to **`#F1F5F9`** for all production item icons unless a specific palette color is semantically required by the item's role.

---

## Style Constraints

### Stroke
- `stroke-width="2"` on the 24-unit canvas
- `stroke-linecap="round"` — all open line ends are rounded
- `stroke-linejoin="round"` — all path corners are rounded
- `fill="none"` by default; optional flat accent fill per **Color Usage** section above
- `stroke="currentColor"` on all paths

### Perspective & Viewpoint

- **3D objects** (hand drill, ship modules, resource node): **slight isometric or 3/4 perspective** — approximately 30° elevation, 45° rotation. The object reads as three-dimensional through visible top/front/side faces drawn as separate closed stroked paths. Do not draw these objects straight-on (flat front projection loses depth that makes the icon recognizable).
- **Flat/sheet objects** (scrap metal fragments, refined metal ingot): **straight-on view** with edge detail — a parallel stroke offset 1 unit below/behind the primary shape suggests material thickness without requiring full 3D perspective.
- **Small consumables** (spare battery, head lamp): **3/4 view** — enough rotation to show both the top face and front face, communicating object form.

### Level of Detail

Icons must be readable at 48×48px on screen (the SVG rendered from the 24-unit canvas). Maximum detail budget per icon: **8–12 distinct stroke paths or path segments**. More than 12 creates visual noise at small sizes. Priority order:

1. **Correct silhouette** — must be instantly recognizable as the specific object
2. **Key functional detail** — the drill bit on the hand drill; the coil symbol on a battery; the angled edge of a metal sheet
3. **Material zone separation** — a secondary stroke line separating top face from front face on isometric objects

Omit: rivets, text/logos, fine hatching, surface texture simulation, and any detail that becomes invisible below 48px.

### Consistency Across the Set

All 9 item icons in the same experiment must share identical stroke-width, linecap, linejoin, and canvas conventions. An icon that uses `stroke-width="1.5"` cannot coexist with icons using `stroke-width="2"`. Perspective convention must also be uniform — do not mix straight-on and 3/4 views within the same category of object.

---

## Output Format

| Property | Value |
|----------|-------|
| **Primary format** | SVG |
| **viewBox** | `0 0 24 24` |
| **Stroke width** | `stroke-width="2"` |
| **Linecap** | `stroke-linecap="round"` |
| **Linejoin** | `stroke-linejoin="round"` |
| **Default fill** | `fill="none"` (or flat accent fill per Color Usage) |
| **Stroke color** | `stroke="currentColor"` |
| **Width / Height attributes** | Omit from `<svg>` element — use viewBox only |
| **Raster export (PNG fallback)** | 256×256px PNG with alpha channel, exported from SVG at 256px rasterization |
| **Naming convention** | `icon_item_[name].svg` |

### Required File Names (full set)

```
icon_item_scrap_metal.svg
icon_item_metal.svg
icon_item_spare_battery.svg
icon_item_head_lamp.svg
icon_item_hand_drill.svg
icon_item_resource_node.svg
icon_item_module_recycler.svg
icon_item_module_fabricator.svg
icon_item_module_automation_hub.svg
```

---

## Godot Integration Notes

### Texture Resource Type

**SVG files:** Godot 4 automatically imports `.svg` files as `CompressedTexture2D` via the SVG importer. Assign the `.svg` resource directly to a `TextureRect.texture` property. The `SVGTexture` path scales cleanly to all three display sizes (48px, 32px, 28px) from a single file.

**PNG fallback:** Load as `ImageTexture`. Godot applies mipmaps at import time, allowing downscaling to 28px notification slots without aliasing.

### Import Settings (SVG)

In the Godot import panel for each `.svg` icon:

| Setting | Value |
|---------|-------|
| Scale | `2.0` (ensures adequate pixel density at 48px display) |
| Compress | Lossless |
| Mipmaps | On (required for clean rendering at 28×28px notification size) |
| Color space | sRGB |
| Filter | Linear |

### Scene Reference Pattern

```gdscript
# In inventory slot script — set item icon texture at runtime
var icon_texture: CompressedTexture2D = load("res://assets/icons/items/icon_item_hand_drill.svg")
$IconRect.texture = icon_texture
```

### Slot Size Reconciliation Note

The icon audit (TICKET-0086) flagged a mismatch: `recycler_panel.gd` and `fabricator_panel.gd` use 40×40px `ColorRect` placeholders, while wireframes specify 48×48px. The SVG format scales cleanly to either size — produce icons at the 48×48px (24-unit canvas) spec and let Godot's importer scale. The slot size mismatch is a separate code-level fix and does not affect icon asset design.

### Atlas (Deferred)

For M6, treat each icon as an independent `.svg` file. If runtime profiling in QA reveals that loading many separate SVG resources is costly, an `AtlasTexture` sprite sheet approach may be adopted in a future milestone. Do not pre-atlas.

---

## Source Path

Final approved icons are committed to: `game/assets/icons/items/`
