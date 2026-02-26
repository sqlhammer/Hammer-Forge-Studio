# Icon Needs Audit

**Owner:** ui-ux-designer
**Status:** Active
**Last Updated:** 2026-02-25
**Ticket:** TICKET-0086

> Authoritative production manifest for all icons required in *The Inheritance*. This document is the input to icon generation experiments (TICKET-0092–0094). Every icon slot in the game — from wireframes, live scripts, and the GDD — is enumerated here. Do not begin icon production without referencing this list.

---

## Summary

| Category | Total Icons |
|----------|-------------|
| Item Icons (48×48px primary) | 9 |
| HUD / Functional Icons (16–32px) | 20 |
| **Total** | **29** |

---

## Item Icons

Represent physical game objects. Primary display size: **48×48px** (inventory slots, tech tree node cards, machine panels). Secondary display size: **32×32px** (compact recipe list rows in Fabricator panel).

All item icon slots in live Godot scripts currently use `ColorRect` placeholders (teal fill). No texture assets exist yet — all are **placeholder**.

| Icon Name | Description | UI Location(s) | Primary Size | Secondary Size | Placeholder Status |
|-----------|-------------|----------------|-------------|----------------|-------------------|
| `icon_item_scrap_metal` | Raw salvaged metal fragments | Inventory grid, Recycler input slot, Pickup toast, Tech tree node card | 48×48px | 32×32px (Recycler/Fabricator recipe list) | None |
| `icon_item_metal` | Refined metal ingot | Inventory grid, Recycler output slot, Fabricator input slot, Pickup toast | 48×48px | 32×32px | None |
| `icon_item_spare_battery` | Portable power cell consumable | Inventory grid, Fabricator output slot, Pickup toast | 48×48px | 28×28px (Pickup toast) | None |
| `icon_item_head_lamp` | Head-mounted light source (equipment) | Inventory grid, Pickup toast | 48×48px | 28×28px | None |
| `icon_item_hand_drill` | Tier 1 mining tool (equipment) | Inventory grid, Pickup toast | 48×48px | 28×28px | None |
| `icon_item_resource_node` | Generic resource deposit (fallback/unknown type) | Pickup toast fallback, any untyped deposit reference | 48×48px | 28×28px | None |
| `icon_item_module_recycler` | Recycler ship module | Tech tree node card, Fabricator output slot (if craftable) | 48×48px | 32×32px | None |
| `icon_item_module_fabricator` | Fabricator ship module | Tech tree node card | 48×48px | 32×32px | None |
| `icon_item_module_automation_hub` | Automation Hub ship module | Tech tree node card | 48×48px | 32×32px | None |

### Item Icon — Scene Audit Notes

- `inventory_screen.gd`: `_slot_icons` array — each slot holds a 48×48px `ColorRect` placeholder. Will be replaced with item-specific `TextureRect` when assets are available.
- `pickup_notification.gd`: 28×28px `ColorRect` (teal) placeholder per notification.
- `recycler_panel.gd`: `_input_slot_icon` and `_output_slot_icon` — 40×40px `ColorRect` placeholders (not 48×48 as in wireframe; **size mismatch flagged** — see Flags section).
- `fabricator_panel.gd`: Input (40×40px) and output (40×40px) slot `ColorRect` placeholders, plus 32×32px placeholders in the recipe list rows. **Same 40 vs 48 mismatch flagged.**
- `tech_tree_panel.gd`: 48×48px `ColorRect` per node card — matches wireframe spec exactly.
- `resource_defs.gd`: `RESOURCE_CATALOG` has an `"icon": ""` field (empty string) for each resource type. Three current types: `SCRAP_METAL`, `METAL`, `SPARE_BATTERY`. No icon path assigned yet.

---

## HUD / Functional Icons

Communicate state and action, not object identity. Must be readable at **16×16px** (inline HUD) through **32×32px** (prominent status panels). Inherits parent text color by default; some icons use fixed state-based color overrides.

| Icon Name | Description | UI Location(s) | Sizes Required | State Colors | Placeholder Status |
|-----------|-------------|----------------|---------------|-------------|-------------------|
| `icon_hud_battery` | Suit battery / lightning bolt | Bottom-left battery bar (HUD) | 24×24px | Green ≥100% → Teal >50% → Amber 26–50% (#FFB830, WARNING_THRESHOLD=0.50) → Coral ≤25% (#FF6B5A, CRITICAL_THRESHOLD=0.25) | Loaded as SVG texture via `battery_bar.gd`; tint applied via `draw_texture_rect` |
| `icon_hud_scanner` | Scanner active indicator (diamond ◆) | Scanner readout panel header | 16×16px | Inherits text color | Text glyph placeholder |
| `icon_hud_battery_micro` | Inline battery/energy indicator (⚡) | Scanner readout — energy row | 16×16px | Inherits text color | Text glyph placeholder |
| `icon_hud_star_filled` | Filled purity star | Scanner readout, inventory detail | 20×20px (readout), 16×16px (compact) | Amber (#FFB830) | Text/shape placeholder |
| `icon_hud_star_empty` | Empty purity star | Scanner readout, inventory detail | 20×20px (readout), 16×16px (compact) | Neutral (#94A3B8) | Text/shape placeholder |
| `icon_hud_compass_center` | Center tick / heading marker | Top-center compass strip | 8×6px | Teal (#00D4AA) | Drawn procedurally |
| `icon_hud_compass_ping` | Deposit ping / directional marker triangle | Compass strip (along bar) | 10×8px | Teal (mineral), Amber (special) | Drawn procedurally |
| `icon_hud_power` | Ship power (lightning bolt, 15° rotation) | Ship Globals HUD bottom-right, Ship Stats Sidebar (inventory) | 20×20px (HUD), 18×18px (sidebar) | Teal → Coral (critical) | `ColorRect` with letter "P" placeholder |
| `icon_hud_integrity` | Ship integrity (shield outline) | Ship Globals HUD, Ship Stats Sidebar | 20×20px (HUD), 18×18px (sidebar) | Green (good) → Coral (critical) | `ColorRect` with letter "I" placeholder |
| `icon_hud_heat` | Ship heat (thermometer) | Ship Globals HUD, Ship Stats Sidebar | 20×20px (HUD), 18×18px (sidebar) | Teal → Amber (high) → Coral (critical) | `ColorRect` with letter "H" placeholder |
| `icon_hud_oxygen` | Ship oxygen (atom / molecule) | Ship Globals HUD, Ship Stats Sidebar | 20×20px (HUD), 18×18px (sidebar) | Teal → Amber (low) → Coral (critical) | `ColorRect` with letter "O" placeholder |
| `icon_hud_notification_info` | Notification badge — informational | Notification toast left border marker | 16×16px | Green (#4ADE80) | No texture; left-border color only |
| `icon_hud_notification_warning` | Notification badge — warning | Notification toast left border marker | 16×16px | Amber (#FFB830) | No texture; left-border color only |
| `icon_hud_notification_critical` | Notification badge — critical/error | Notification toast left border marker | 16×16px | Coral (#FF6B5A) | No texture; left-border color only |
| `icon_hud_lock` | Tech tree node locked (padlock) | Tech tree node card — bottom-right state indicator | 16×16px | Neutral (#94A3B8) | Text label placeholder ("🔒" or text) |
| `icon_hud_unlock_chevron` | Tech tree node unlockable (upward chevron) | Tech tree node card — bottom-right state indicator | 16×16px | Teal (#00D4AA) | Text label placeholder |
| `icon_hud_unlock_check` | Tech tree node unlocked (checkmark) | Tech tree node card — bottom-right state indicator | 16×16px | Green (#4ADE80) | Text label placeholder |
| `icon_hud_mining_active` | Mining drill active / in-progress indicator | HUD mining progress area; mining minigame overlay | 16–24px | Teal (active) | No dedicated texture — bar + label only |
| `icon_hud_scan_ping` | Scan pulse / ping burst | First-person HUD scan action indicator | 16–24px | Teal | No dedicated texture |
| `icon_hud_drone` | Drone active / Automation Hub indicator | Third-person HUD; Drone Programming UI | 24×24px | Teal (active) → Neutral (idle) | No texture |

### HUD Icon — Scene Audit Notes

- `battery_bar.gd`: Icon drawn procedurally via `_draw_battery_icon()` on a `CanvasItem`. This will need to be replaced with a loaded texture when the production asset exists, or the draw logic adapted to render an SVG.
- `ship_globals_hud.gd` and `ship_stats_sidebar.gd`: All four ship status icons (Power, Integrity, Heat, Oxygen) are `ColorRect` nodes with a letter label overlay — pure placeholder, no shape information.
- `tech_tree_panel.gd`: State icons (padlock, chevron, checkmark) are rendered as Label text — no `TextureRect` yet.
- Notification toasts: Icon type is currently conveyed only through left-border color. No icon `TextureRect` node exists in `pickup_notification.gd` for notification type differentiation.
- Compass, scanner, and scan ping icons are all text-glyph or procedurally drawn — no existing texture slots.

---

## Icons Found in Scenes Not Covered by Existing Wireframes

The following icon requirements were discovered from live script inspection that are not explicitly called out in any existing wireframe document:

| Icon | Location | Notes |
|------|----------|-------|
| Notification type badge (info/warning/critical) | `pickup_notification.gd` | Wireframes show left-border color only; no icon glyph specified in any wireframe. Adding badge icon would improve accessibility (color-blind safety). Flag for design decision. |
| Scan ping icon | HUD (scanner action) | The `battery_bar.gd` scan reference and style guide mention a scan ping, but no wireframe specifies a discrete icon. Current implementation has no slot. |
| Mining active icon | Mining progress bar / minigame overlay | `minigame-overlay.md` uses a text checkmark for success, no dedicated mining-active glyph icon defined. |

---

## Flags & Issues

| Flag | Severity | Description |
|------|----------|-------------|
| Slot size mismatch | Low | `recycler_panel.gd` and `fabricator_panel.gd` use 40×40px icon placeholders; wireframes spec 48×48px. Reconcile before TextureRect integration. |
| Notification icon gap | Design decision | No icon glyph for notification type in any wireframe — only left-border color conveys type. Consider adding a small type icon for accessibility. |
| Scan ping icon undefined | Design decision | Style guide and ticket mention scan ping icon; no wireframe spec exists. Needs wireframe or explicit size/style decision. |
| Mining active icon undefined | Design decision | No discrete glyph for mining-in-progress state beyond the bar fill. Determine whether an icon is needed. |
| Battery bar procedural draw | Implementation note | `battery_bar.gd` draws the battery icon via GDScript `_draw()`. Integration of a texture asset will require code change, not just asset drop-in. |

---

## Sources Consulted

| Source | Notes |
|--------|-------|
| `docs/design/wireframes/m3/` | battery-bar, compass, hud-layout-overview, inventory, mining-progress, pickup-notification, scanner-readout |
| `docs/design/wireframes/m4/` | recycler-machine, recycler-panel, ship-globals-hud, ship-interior-layout, ship-stats-sidebar |
| `docs/design/wireframes/m5/` | drone-programming, fabricator-panel, m5-wireframe-index, minigame-overlay, tech-tree, third-person-hud |
| `docs/design/ui-style-guide.md` | Icon Style section, Color Palette, Component Standards |
| `docs/design/gdd.md` | No icon-specific content found |
| `game/scripts/ui/battery_bar.gd` | Procedural battery icon draw, ICON_SIZE constant |
| `game/scripts/ui/inventory_screen.gd` | 48×48px slot placeholders |
| `game/scripts/ui/pickup_notification.gd` | 28×28px item icon placeholder |
| `game/scripts/ui/recycler_panel.gd` | 40×40px input/output slot placeholders |
| `game/scripts/ui/fabricator_panel.gd` | 40×40px slot + 32×32px recipe list placeholders |
| `game/scripts/ui/tech_tree_panel.gd` | 48×48px module icon + 16×16px state icon placeholders |
| `game/scripts/ui/ship_globals_hud.gd` | 20×20px ship status icon placeholders |
| `game/scripts/ui/ship_stats_sidebar.gd` | 18×18px ship status icon placeholders |
| `game/scripts/data/resource_defs.gd` | Item types: SCRAP_METAL, METAL, SPARE_BATTERY; `"icon": ""` field present but empty |
| `game/scripts/data/module_defs.gd` | Module types: Recycler, Fabricator, Automation Hub |
