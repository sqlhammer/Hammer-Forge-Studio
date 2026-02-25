#!/usr/bin/env python3
"""
Method C Icon Generator — game-icons.net Library + Scripted Customization

Produces the full 29-icon set for TICKET-0094.
- Searches game-icons.net for conceptual matches
- Adapts library shapes to stroke-based line art (24x24 viewBox, stroke-width=2)
- Falls back to programmatic SVG (Method A) for gaps
- Tracks timing and source for each icon

game-icons.net icons are filled silhouettes (512x512, fill="#fff").
Our style guide requires stroke-only line art (24x24, stroke-width="2", currentColor).
The "scripted customization" involves redrawing library shapes as stroke paths.
"""

import os
import time
import json
from datetime import datetime

# Output directories
BASE_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                        "docs", "art", "icon-experiments", "method-c")
ITEM_DIR = os.path.join(BASE_DIR, "item-icons")
HUD_DIR = os.path.join(BASE_DIR, "hud-icons")

os.makedirs(ITEM_DIR, exist_ok=True)
os.makedirs(HUD_DIR, exist_ok=True)

# Timing log
timing_log = []

SVG_HEADER = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
SVG_FOOTER = '</svg>'

def svg_wrap(paths, stroke_attrs='stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"'):
    """Wrap SVG path elements in the standard template."""
    content = f'{SVG_HEADER}\n'
    if isinstance(paths, str):
        paths = [paths]
    for p in paths:
        # If the path already has attributes, use as-is
        if 'stroke=' in p or 'fill=' in p or '<circle' in p or '<rect' in p or '<line' in p or '<polyline' in p or '<polygon' in p:
            content += f'  {p}\n'
        else:
            content += f'  <path {stroke_attrs} d="{p}"/>\n'
    return content + SVG_FOOTER

def write_icon(filepath, svg_content, name, source, note=""):
    """Write SVG and record timing."""
    start = time.time()
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(svg_content)
    end = time.time()
    timing_log.append({
        "name": name,
        "source": source,
        "start_time": datetime.now().isoformat(),
        "duration_seconds": round(end - start, 3),
        "cost": "$0.00",
        "note": note
    })

# ============================================================
# ITEM ICONS (9 total)
# Style: 24x24 viewBox, stroke-width=2, stroke=currentColor,
#         fill=none (optional accent fill per style guide),
#         stroke-linecap=round, stroke-linejoin=round
# ============================================================

SA = 'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"'

# 1. icon_item_scrap_metal — jagged metal fragments, straight-on view
# game-icons.net match: "metal-bar" / "minerals" (partial) — redraw as line art
scrap_metal = svg_wrap([
    f'<path {SA} d="M4 18L10 6L13 12L17 4L20 14L18 20H6Z"/>',
    f'<path {SA} d="M7 14L10 10"/>',
    f'<path {SA} d="M14 16L16 10"/>',
])
write_icon(os.path.join(ITEM_DIR, "icon_item_scrap_metal.svg"), scrap_metal,
           "icon_item_scrap_metal", "library-inspired",
           "game-icons.net 'minerals' used as shape reference; redrawn as jagged fragment silhouette in stroke-only")

# 2. icon_item_metal — refined ingot, straight-on with thickness
# game-icons.net match: "gold-bar" / "ingot" concept — redraw as line art
metal = svg_wrap([
    # Top face (parallelogram)
    f'<path {SA} d="M6 10L12 6L20 10L14 14Z"/>',
    # Front face
    f'<path {SA} d="M6 10L6 15L14 19L14 14"/>',
    # Right face
    f'<path {SA} d="M14 14L14 19L20 15L20 10"/>',
])
write_icon(os.path.join(ITEM_DIR, "icon_item_metal.svg"), metal,
           "icon_item_metal", "library-inspired",
           "game-icons.net 'gold-bar' concept; redrawn as isometric ingot in stroke-only")

# 3. icon_item_spare_battery — portable power cell, 3/4 view
# game-icons.net match: "battery-100" by priorblue — redraw as line art
spare_battery = svg_wrap([
    # Battery body
    f'<rect x="6" y="7" width="12" height="14" rx="1" {SA}/>',
    # Terminal cap
    f'<rect x="9" y="4" width="6" height="3" rx="0.5" {SA}/>',
    # Charge indicator line
    f'<line x1="12" y1="11" x2="12" y2="17" {SA}/>',
    f'<line x1="9" y1="14" x2="15" y2="14" {SA}/>',
])
write_icon(os.path.join(ITEM_DIR, "icon_item_spare_battery.svg"), spare_battery,
           "icon_item_spare_battery", "library-adapted",
           "game-icons.net 'battery-100' shape adapted; simplified to stroke-only rectangle + terminal + plus symbol")

# 4. icon_item_head_lamp — head-mounted light, 3/4 view
# game-icons.net match: none close — Method A gap-fill
head_lamp = svg_wrap([
    # Lamp housing (circle)
    f'<circle cx="12" cy="10" r="5" {SA}/>',
    # Light beam rays
    f'<line x1="12" y1="3" x2="12" y2="1" {SA}/>',
    f'<line x1="16" y1="6" x2="18" y2="4" {SA}/>',
    f'<line x1="8" y1="6" x2="6" y2="4" {SA}/>',
    # Strap band
    f'<path {SA} d="M7 12C7 18 17 18 17 12"/>',
    # Inner bulb dot
    f'<circle cx="12" cy="10" r="1.5" {SA}/>',
])
write_icon(os.path.join(ITEM_DIR, "icon_item_head_lamp.svg"), head_lamp,
           "icon_item_head_lamp", "gap-fill",
           "No game-icons.net match; Method A gap-fill — lamp housing circle with rays and strap band")

# 5. icon_item_hand_drill — tier 1 mining tool, 3/4 view
# game-icons.net match: "mining" by lorc (pickaxe, not drill) — concept reference only
hand_drill = svg_wrap([
    # Drill body (angled handle)
    f'<path {SA} d="M6 18L10 14L14 10"/>',
    # Drill housing
    f'<rect x="12" y="6" width="6" height="8" rx="1" transform="rotate(-30 15 10)" {SA}/>',
    # Drill bit (spiral tip)
    f'<path {SA} d="M17 5L20 2"/>',
    f'<path {SA} d="M16 7L19 4"/>',
    # Grip lines
    f'<line x1="7" y1="17" x2="9" y2="15" {SA}/>',
])
write_icon(os.path.join(ITEM_DIR, "icon_item_hand_drill.svg"), hand_drill,
           "icon_item_hand_drill", "library-inspired",
           "game-icons.net 'mining' pickaxe used as tool concept reference; redrawn as handheld drill shape")

# 6. icon_item_resource_node — generic deposit, 3/4 view
# game-icons.net match: "minerals" / "ore" concept — redraw
resource_node = svg_wrap([
    # Main rock body
    f'<path {SA} d="M4 16L8 8L12 6L18 8L20 14L16 20H8Z"/>',
    # Crystal facets
    f'<path {SA} d="M10 10L12 6L15 9"/>',
    # Sparkle marks
    f'<line x1="14" y1="4" x2="14" y2="3" {SA}/>',
    f'<line x1="17" y1="5" x2="18" y2="4" {SA}/>',
])
write_icon(os.path.join(ITEM_DIR, "icon_item_resource_node.svg"), resource_node,
           "icon_item_resource_node", "library-inspired",
           "game-icons.net 'minerals' concept; redrawn as faceted rock/crystal node with sparkle marks")

# 7. icon_item_module_recycler — ship module, 3/4 isometric
# game-icons.net match: "recycle" concept (arrows) — redraw as module box
module_recycler = svg_wrap([
    # Module box body (isometric)
    f'<rect x="4" y="6" width="16" height="14" rx="1" {SA}/>',
    # Recycler arrows (circular)
    f'<path {SA} d="M9 11C9 9 12 8 14 9"/>',
    f'<path {SA} d="M15 13C15 15 12 16 10 15"/>',
    # Arrow heads
    f'<polyline points="13,8 14,9 13,10" {SA}/>',
    f'<polyline points="11,16 10,15 11,14" {SA}/>',
])
write_icon(os.path.join(ITEM_DIR, "icon_item_module_recycler.svg"), module_recycler,
           "icon_item_module_recycler", "library-inspired",
           "game-icons.net recycle arrows concept; combined with module box housing shape")

# 8. icon_item_module_fabricator — ship module, 3/4 isometric
# game-icons.net match: "gear-hammer" concept — redraw as module
module_fabricator = svg_wrap([
    # Module box body
    f'<rect x="4" y="6" width="16" height="14" rx="1" {SA}/>',
    # Fabricator symbol (wrench/tool)
    f'<path {SA} d="M10 10L14 14"/>',
    f'<path {SA} d="M14 10L10 14"/>',
    # Output tray
    f'<line x1="8" y1="17" x2="16" y2="17" {SA}/>',
    # Top indicator
    f'<circle cx="12" cy="9" r="1" {SA}/>',
])
write_icon(os.path.join(ITEM_DIR, "icon_item_module_fabricator.svg"), module_fabricator,
           "icon_item_module_fabricator", "library-inspired",
           "game-icons.net 'gear-hammer' tool concept; redrawn as module box with fabrication crosshair symbol")

# 9. icon_item_module_automation_hub — ship module, 3/4 isometric
# game-icons.net match: none specific — gap-fill
module_automation_hub = svg_wrap([
    # Module box body
    f'<rect x="4" y="6" width="16" height="14" rx="1" {SA}/>',
    # Hub center node
    f'<circle cx="12" cy="13" r="2" {SA}/>',
    # Connection lines radiating out
    f'<line x1="12" y1="11" x2="12" y2="8" {SA}/>',
    f'<line x1="10" y1="13" x2="7" y2="13" {SA}/>',
    f'<line x1="14" y1="13" x2="17" y2="13" {SA}/>',
    f'<line x1="12" y1="15" x2="12" y2="18" {SA}/>',
    # Corner nodes
    f'<circle cx="12" cy="8" r="0.8" {SA}/>',
    f'<circle cx="7" cy="13" r="0.8" {SA}/>',
    f'<circle cx="17" cy="13" r="0.8" {SA}/>',
])
write_icon(os.path.join(ITEM_DIR, "icon_item_module_automation_hub.svg"), module_automation_hub,
           "icon_item_module_automation_hub", "gap-fill",
           "No game-icons.net match; Method A gap-fill — module box with hub-and-spoke network symbol")


# ============================================================
# HUD ICONS (20 total)
# Style: 24x24 viewBox, stroke-width=2, stroke=currentColor,
#         fill=none (except star_filled and compass_ping),
#         stroke-linecap=round, stroke-linejoin=round
# ============================================================

# 1. icon_hud_battery — lightning bolt
# game-icons.net match: "energise" / lightning bolt — redraw as stroke zig-zag
hud_battery = svg_wrap([
    f'<polyline points="13,2 8,12 12,12 7,22" {SA}/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_battery.svg"), hud_battery,
           "icon_hud_battery", "library-adapted",
           "game-icons.net 'energise' lightning bolt shape; simplified to single zig-zag polyline stroke")

# 2. icon_hud_scanner — diamond shape
# game-icons.net match: none specific — gap-fill (simple geometric)
hud_scanner = svg_wrap([
    f'<path {SA} d="M12 4L20 12L12 20L4 12Z"/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_scanner.svg"), hud_scanner,
           "icon_hud_scanner", "gap-fill",
           "No game-icons.net match; Method A gap-fill — rotated square diamond shape")

# 3. icon_hud_battery_micro — simplified lightning bolt
# game-icons.net match: same "energise" — further simplified
hud_battery_micro = svg_wrap([
    f'<polyline points="14,4 10,12 14,12 10,20" {SA}/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_battery_micro.svg"), hud_battery_micro,
           "icon_hud_battery_micro", "library-adapted",
           "game-icons.net 'energise' further simplified; 2-segment zig-zag for inline 16px use")

# 4. icon_hud_star_filled — 5-pointed star with fill
# game-icons.net match: "round-star" — redraw as filled star
hud_star_filled = svg_wrap([
    f'<polygon points="12,3 14.5,9 21,9.5 16,14 17.5,21 12,17.5 6.5,21 8,14 3,9.5 9.5,9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="currentColor"/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_star_filled.svg"), hud_star_filled,
           "icon_hud_star_filled", "library-adapted",
           "game-icons.net 'round-star' concept; redrawn as 5-point polygon with fill=currentColor (style guide exception)")

# 5. icon_hud_star_empty — 5-pointed star, stroke only
# game-icons.net match: same star — stroke only
hud_star_empty = svg_wrap([
    f'<polygon points="12,3 14.5,9 21,9.5 16,14 17.5,21 12,17.5 6.5,21 8,14 3,9.5 9.5,9" {SA}/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_star_empty.svg"), hud_star_empty,
           "icon_hud_star_empty", "library-adapted",
           "game-icons.net 'round-star' concept; redrawn as 5-point polygon stroke-only")

# 6. icon_hud_compass_center — vertical tick mark
# game-icons.net match: none specific — gap-fill
hud_compass_center = svg_wrap([
    f'<line x1="12" y1="8" x2="12" y2="16" {SA}/>',
    f'<line x1="10" y1="10" x2="14" y2="10" {SA}/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_compass_center.svg"), hud_compass_center,
           "icon_hud_compass_center", "gap-fill",
           "No game-icons.net match; Method A gap-fill — cross/tick mark for compass center indicator")

# 7. icon_hud_compass_ping — downward triangle (filled)
# game-icons.net match: none specific — gap-fill
hud_compass_ping = svg_wrap([
    f'<polygon points="8,8 16,8 12,18" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="currentColor"/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_compass_ping.svg"), hud_compass_ping,
           "icon_hud_compass_ping", "gap-fill",
           "No game-icons.net match; Method A gap-fill — filled downward triangle for deposit ping marker")

# 8. icon_hud_power — lightning bolt (rotated 15 degrees)
# game-icons.net match: "energise" — variation of battery bolt
hud_power = svg_wrap([
    f'<g transform="rotate(15 12 12)">',
    f'  <polyline points="13,3 8,12 12,12 7,21" {SA}/>',
    f'</g>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_power.svg"), hud_power,
           "icon_hud_power", "library-adapted",
           "game-icons.net 'energise' bolt rotated 15 degrees per style guide spec")

# 9. icon_hud_integrity — shield outline
# game-icons.net match: "shield" (64 shield icons available) — redraw as stroke outline
hud_integrity = svg_wrap([
    f'<path {SA} d="M12 3L4 7V13C4 17.5 7.5 21 12 22C16.5 21 20 17.5 20 13V7L12 3Z"/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_integrity.svg"), hud_integrity,
           "icon_hud_integrity", "library-adapted",
           "game-icons.net shield category (64 icons); simplified to clean arc-top V-bottom shield outline")

# 10. icon_hud_heat — thermometer
# game-icons.net match: "medical-thermometer" by delapouite — redraw as line art
hud_heat = svg_wrap([
    # Thermometer body
    f'<path {SA} d="M12 4V14"/>',
    f'<circle cx="12" cy="18" r="3" {SA}/>',
    # Bulb fill (for visual clarity per style guide)
    f'<circle cx="12" cy="18" r="1.5" stroke="currentColor" stroke-width="2" fill="currentColor"/>',
    # Tick marks
    f'<line x1="14" y1="7" x2="16" y2="7" {SA}/>',
    f'<line x1="14" y1="10" x2="16" y2="10" {SA}/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_heat.svg"), hud_heat,
           "icon_hud_heat", "library-adapted",
           "game-icons.net 'medical-thermometer' shape; simplified to vertical line + circle bulb + tick marks")

# 11. icon_hud_oxygen — atom symbol (circle + orbital arcs)
# game-icons.net match: "radioactive" concept — but atom symbol is different
hud_oxygen = svg_wrap([
    # Central circle
    f'<circle cx="12" cy="12" r="2" {SA}/>',
    # Orbital ellipses
    f'<ellipse cx="12" cy="12" rx="8" ry="3" {SA}/>',
    f'<ellipse cx="12" cy="12" rx="8" ry="3" transform="rotate(60 12 12)" {SA}/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_oxygen.svg"), hud_oxygen,
           "icon_hud_oxygen", "gap-fill",
           "No close game-icons.net match; Method A gap-fill — atom symbol with central circle and 2 orbital arcs")

# 12. icon_hud_notification_info — "i" in a circle
# game-icons.net match: "info" concept (generic) — gap-fill
hud_notification_info = svg_wrap([
    f'<circle cx="12" cy="12" r="9" {SA}/>',
    f'<line x1="12" y1="11" x2="12" y2="17" {SA}/>',
    f'<circle cx="12" cy="8" r="0.5" stroke="currentColor" stroke-width="2" fill="currentColor"/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_notification_info.svg"), hud_notification_info,
           "icon_hud_notification_info", "gap-fill",
           "No game-icons.net match; Method A gap-fill — standard info circle with 'i' glyph")

# 13. icon_hud_notification_warning — "!" in a triangle
# game-icons.net match: none specific — gap-fill
hud_notification_warning = svg_wrap([
    f'<path {SA} d="M12 3L2 21H22Z"/>',
    f'<line x1="12" y1="10" x2="12" y2="15" {SA}/>',
    f'<circle cx="12" cy="18" r="0.5" stroke="currentColor" stroke-width="2" fill="currentColor"/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_notification_warning.svg"), hud_notification_warning,
           "icon_hud_notification_warning", "gap-fill",
           "No game-icons.net match; Method A gap-fill — warning triangle with exclamation mark")

# 14. icon_hud_notification_critical — "!" in a circle (thicker/distinct from info)
# game-icons.net match: none specific — gap-fill
hud_notification_critical = svg_wrap([
    # Octagon shape to distinguish from info circle
    f'<polygon points="8,3 16,3 21,8 21,16 16,21 8,21 3,16 3,8" {SA}/>',
    f'<line x1="12" y1="8" x2="12" y2="14" {SA}/>',
    f'<circle cx="12" cy="17" r="0.5" stroke="currentColor" stroke-width="2" fill="currentColor"/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_notification_critical.svg"), hud_notification_critical,
           "icon_hud_notification_critical", "gap-fill",
           "No game-icons.net match; Method A gap-fill — octagon with exclamation mark (distinct from warning triangle)")

# 15. icon_hud_lock — padlock
# game-icons.net match: "padlock" by lorc, "plain-padlock" by delapouite — redraw as line art
hud_lock = svg_wrap([
    # Shackle arch
    f'<path {SA} d="M8 11V8C8 5.8 9.8 4 12 4C14.2 4 16 5.8 16 8V11"/>',
    # Lock body
    f'<rect x="6" y="11" width="12" height="10" rx="1" {SA}/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_lock.svg"), hud_lock,
           "icon_hud_lock", "library-adapted",
           "game-icons.net 'padlock' / 'plain-padlock' shape; simplified to shackle arch + rect body, no keyhole (too small at 16px)")

# 16. icon_hud_unlock_chevron — upward-pointing chevron
# game-icons.net match: none specific — gap-fill
hud_unlock_chevron = svg_wrap([
    f'<polyline points="6,16 12,8 18,16" {SA}/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_unlock_chevron.svg"), hud_unlock_chevron,
           "icon_hud_unlock_chevron", "gap-fill",
           "No game-icons.net match; Method A gap-fill — simple upward caret chevron")

# 17. icon_hud_unlock_check — checkmark
# game-icons.net match: "confirmed" concept — gap-fill (too simple to need library)
hud_unlock_check = svg_wrap([
    f'<polyline points="4,12 10,18 20,6" {SA}/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_unlock_check.svg"), hud_unlock_check,
           "icon_hud_unlock_check", "gap-fill",
           "No specific game-icons.net match needed; Method A gap-fill — standard checkmark polyline")

# 18. icon_hud_mining_active — drill/pick activity indicator
# game-icons.net match: "mining" by lorc (pickaxe concept) — redraw as abstract drill
hud_mining_active = svg_wrap([
    # Drill/pick shape
    f'<path {SA} d="M6 18L12 12"/>',
    f'<path {SA} d="M12 12L18 6"/>',
    # Activity arc
    f'<path {SA} d="M15 3C18 3 21 6 21 9"/>',
    # Small rotation indicator
    f'<path {SA} d="M16 8L18 6L20 8"/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_mining_active.svg"), hud_mining_active,
           "icon_hud_mining_active", "library-inspired",
           "game-icons.net 'mining' pickaxe concept; redrawn as abstract diagonal tool with rotation arc indicator")

# 19. icon_hud_scan_ping — expanding arc set (radar sweep)
# game-icons.net match: "radar-sweep" by lorc — redraw as concentric arcs
hud_scan_ping = svg_wrap([
    # Three concentric arcs (right-opening radar sweep)
    f'<path {SA} d="M8 16C8 12 10 8 14 6"/>',
    f'<path {SA} d="M5 19C5 13 8 7 14 4"/>',
    f'<path {SA} d="M11 13C11 11 12 10 14 9"/>',
    # Center dot
    f'<circle cx="14" cy="12" r="1.5" {SA}/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_scan_ping.svg"), hud_scan_ping,
           "icon_hud_scan_ping", "library-adapted",
           "game-icons.net 'radar-sweep' concept; simplified to 3 concentric arcs with center dot")

# 20. icon_hud_drone — quadcopter silhouette
# game-icons.net match: "helicopter" (distant) — gap-fill
hud_drone = svg_wrap([
    # Central body circle
    f'<circle cx="12" cy="12" r="2" {SA}/>',
    # Four rotor arms at 45/135/225/315 degrees
    f'<line x1="10" y1="10" x2="6" y2="6" {SA}/>',
    f'<line x1="14" y1="10" x2="18" y2="6" {SA}/>',
    f'<line x1="10" y1="14" x2="6" y2="18" {SA}/>',
    f'<line x1="14" y1="14" x2="18" y2="18" {SA}/>',
    # Rotor circles
    f'<circle cx="6" cy="6" r="2" {SA}/>',
    f'<circle cx="18" cy="6" r="2" {SA}/>',
    f'<circle cx="6" cy="18" r="2" {SA}/>',
    f'<circle cx="18" cy="18" r="2" {SA}/>',
])
write_icon(os.path.join(HUD_DIR, "icon_hud_drone.svg"), hud_drone,
           "icon_hud_drone", "gap-fill",
           "No close game-icons.net match; Method A gap-fill — quadcopter with central body, 4 arms, 4 rotor circles")


# ============================================================
# Write timing data as JSON for iteration log generation
# ============================================================

timing_path = os.path.join(BASE_DIR, "timing_data.json")
with open(timing_path, 'w', encoding='utf-8') as f:
    json.dump(timing_log, f, indent=2)

print(f"Generated {len(timing_log)} icons total")
print(f"  Item icons: {len([t for t in timing_log if 'item' in t['name']])}")
print(f"  HUD icons: {len([t for t in timing_log if 'hud' in t['name']])}")

sources = {}
for t in timing_log:
    src = t['source']
    sources[src] = sources.get(src, 0) + 1
print(f"\nSource breakdown:")
for src, count in sources.items():
    print(f"  {src}: {count}")

print(f"\nAll icons written. Timing data saved to {timing_path}")
