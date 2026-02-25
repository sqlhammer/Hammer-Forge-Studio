#!/usr/bin/env python3
"""
TICKET-0092: Experiment A - Programmatic SVG (direct XML construction)

Generates all 29 icons for The Inheritance:
  - 9 item icons (48x48px primary, 24x24 viewBox)
  - 20 HUD/functional icons (16-32px, 24x24 viewBox)

Style guide specs:
  - viewBox="0 0 24 24", stroke-width="2", stroke-linecap="round",
    stroke-linejoin="round", fill="none", stroke="currentColor"
  - Safe area: 2-unit margin (content within 2-22 on each axis)
  - Item icons: 8-12 paths max, optional accent fill
  - HUD icons: 3-8 paths max, stroke-only (exceptions noted)
"""

import os
import time
import math
import json
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
ITEM_DIR = os.path.join(PROJECT_DIR, "docs", "art", "icon-experiments", "method-a", "item-icons")
HUD_DIR = os.path.join(PROJECT_DIR, "docs", "art", "icon-experiments", "method-a", "hud-icons")

SVG_OPEN = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
SVG_CLOSE = '</svg>'


def make_svg(inner):
    """Wrap inner SVG elements in the standard document."""
    return f"{SVG_OPEN}\n{inner}\n{SVG_CLOSE}\n"


def star_points(cx, cy, outer_r, inner_r, n=5):
    """Calculate 5-pointed star vertex coordinates."""
    pts = []
    for i in range(n * 2):
        angle = math.radians(-90 + i * 360 / (n * 2))
        r = outer_r if i % 2 == 0 else inner_r
        x = cx + r * math.cos(angle)
        y = cy + r * math.sin(angle)
        pts.append(f"{x:.1f},{y:.1f}")
    return pts


# ---------------------------------------------------------------------------
# ITEM ICONS (9)
# ---------------------------------------------------------------------------

def icon_item_scrap_metal():
    """Raw salvaged metal fragments - two overlapping angular shards."""
    return make_svg(
        '  <path d="M 5 10 L 9 5 L 15 7 L 13 14 L 7 15 Z" fill="#0A0F18" fill-opacity="0.15" stroke="none"/>\n'
        '  <path d="M 5 10 L 9 5 L 15 7 L 13 14 L 7 15 Z"/>\n'
        '  <path d="M 11 11 L 16 8 L 20 11 L 18 17 L 13 18 Z"/>\n'
        '  <line x1="5" y1="10" x2="5" y2="12"/>\n'
        '  <line x1="7" y1="15" x2="7" y2="17"/>\n'
        '  <line x1="13" y1="18" x2="13" y2="20"/>'
    )


def icon_item_metal():
    """Refined metal ingot - isometric box with three visible faces."""
    return make_svg(
        '  <path d="M 4 10 L 12 6 L 20 10 L 12 14 Z" fill="#0A0F18" fill-opacity="0.15" stroke="none"/>\n'
        '  <path d="M 4 10 L 12 6 L 20 10 L 12 14 Z"/>\n'
        '  <path d="M 4 10 L 4 15 L 12 19 L 12 14"/>\n'
        '  <path d="M 12 14 L 12 19 L 20 15 L 20 10"/>'
    )


def icon_item_spare_battery():
    """Portable power cell - rectangular body with terminal and bolt."""
    return make_svg(
        '  <rect x="7" y="6" width="10" height="14" rx="1" fill="#00D4AA" fill-opacity="0.12" stroke="none"/>\n'
        '  <rect x="7" y="6" width="10" height="14" rx="1"/>\n'
        '  <rect x="9" y="3" width="6" height="3" rx="0.5"/>\n'
        '  <polyline points="13,10 11,13 13,13 11,16"/>'
    )


def icon_item_head_lamp():
    """Head-mounted light - reflector housing, band, lens, beam lines."""
    return make_svg(
        '  <path d="M 6 11 Q 6 5 12 5 Q 18 5 18 11"/>\n'
        '  <line x1="6" y1="11" x2="6" y2="15"/>\n'
        '  <line x1="18" y1="11" x2="18" y2="15"/>\n'
        '  <path d="M 6 15 Q 6 21 12 21 Q 18 21 18 15"/>\n'
        '  <circle cx="12" cy="10" r="2.5"/>\n'
        '  <line x1="12" y1="5" x2="12" y2="3"/>\n'
        '  <line x1="8" y1="6" x2="7" y2="4"/>\n'
        '  <line x1="16" y1="6" x2="17" y2="4"/>'
    )


def icon_item_hand_drill():
    """Tier 1 mining tool - drill body with handle and pointed bit."""
    return make_svg(
        '  <path d="M 7 8 L 7 16 L 10 16 L 10 8 Z"/>\n'
        '  <path d="M 10 10 L 17 10 L 17 14 L 10 14 Z"/>\n'
        '  <path d="M 17 11 L 21 12 L 17 13"/>\n'
        '  <line x1="7" y1="18" x2="7" y2="20"/>\n'
        '  <line x1="10" y1="18" x2="10" y2="20"/>\n'
        '  <line x1="13" y1="11" x2="13" y2="13"/>\n'
        '  <line x1="15" y1="11" x2="15" y2="13"/>'
    )


def icon_item_resource_node():
    """Generic resource deposit - angular crystalline cluster."""
    return make_svg(
        '  <path d="M 8 20 L 4 13 L 8 6 L 12 4 L 16 8 Z" fill="#0A0F18" fill-opacity="0.15" stroke="none"/>\n'
        '  <path d="M 8 20 L 4 13 L 8 6 L 12 4 L 16 8 Z"/>\n'
        '  <path d="M 10 20 L 16 8 L 20 12 L 18 20 Z"/>\n'
        '  <line x1="12" y1="4" x2="14" y2="10"/>\n'
        '  <line x1="8" y1="6" x2="10" y2="12"/>'
    )


def _isometric_module(detail_lines):
    """Base isometric box for ship modules with custom detail on front face."""
    base = (
        '  <path d="M 4 9 L 12 5 L 20 9 L 12 13 Z" fill="#007A63" fill-opacity="0.18" stroke="none"/>\n'
        '  <path d="M 4 9 L 12 5 L 20 9 L 12 13 Z"/>\n'
        '  <path d="M 4 9 L 4 15 L 12 19 L 12 13"/>\n'
        '  <path d="M 12 13 L 12 19 L 20 15 L 20 9"/>\n'
    )
    return make_svg(base + detail_lines)


def icon_item_module_recycler():
    """Recycler module - isometric box with circular arrow symbol."""
    detail = (
        '  <path d="M 6 11 Q 6 17 10 17" stroke-width="1.5"/>\n'
        '  <polyline points="9,15.5 10,17 8.5,17.5" stroke-width="1.5"/>'
    )
    return _isometric_module(detail)


def icon_item_module_fabricator():
    """Fabricator module - isometric box with gear symbol."""
    detail = (
        '  <circle cx="8" cy="14" r="2" stroke-width="1.5"/>\n'
        '  <line x1="8" y1="11.5" x2="8" y2="12" stroke-width="1.5"/>\n'
        '  <line x1="8" y1="16" x2="8" y2="16.5" stroke-width="1.5"/>\n'
        '  <line x1="5.5" y1="14" x2="6" y2="14" stroke-width="1.5"/>\n'
        '  <line x1="10" y1="14" x2="10.5" y2="14" stroke-width="1.5"/>'
    )
    return _isometric_module(detail)


def icon_item_module_automation_hub():
    """Automation Hub module - isometric box with hub-spoke network."""
    detail = (
        '  <circle cx="8" cy="14" r="1.5" stroke-width="1.5"/>\n'
        '  <line x1="6.5" y1="12.5" x2="5" y2="11" stroke-width="1.5"/>\n'
        '  <line x1="9.5" y1="12.5" x2="11" y2="11" stroke-width="1.5"/>\n'
        '  <line x1="8" y1="15.5" x2="8" y2="17" stroke-width="1.5"/>\n'
        '  <circle cx="5" cy="11" r="0.7" stroke-width="1.5"/>\n'
        '  <circle cx="11" cy="11" r="0.7" stroke-width="1.5"/>\n'
        '  <circle cx="8" cy="17" r="0.7" stroke-width="1.5"/>'
    )
    return _isometric_module(detail)


# ---------------------------------------------------------------------------
# HUD / FUNCTIONAL ICONS (20)
# ---------------------------------------------------------------------------

def icon_hud_battery():
    """Lightning bolt - 3-4 angled segments."""
    return make_svg(
        '  <polyline points="14,3 9,12 13,12 8,21"/>'
    )


def icon_hud_scanner():
    """Diamond (rotated square)."""
    return make_svg(
        '  <path d="M 12 3 L 21 12 L 12 21 L 3 12 Z"/>'
    )


def icon_hud_battery_micro():
    """Simplified lightning bolt - 2-3 segments, compact."""
    return make_svg(
        '  <polyline points="14,5 10,12 14,12 10,19"/>'
    )


def icon_hud_star_filled():
    """5-pointed star with fill (exception: uses fill="currentColor")."""
    pts = star_points(12, 12, 9, 4)
    d = "M " + " L ".join(pts) + " Z"
    return make_svg(
        f'  <path d="{d}" fill="currentColor"/>'
    )


def icon_hud_star_empty():
    """5-pointed star, stroke only."""
    pts = star_points(12, 12, 9, 4)
    d = "M " + " L ".join(pts) + " Z"
    return make_svg(
        f'  <path d="{d}"/>'
    )


def icon_hud_compass_center():
    """Vertical tick / downward caret."""
    return make_svg(
        '  <line x1="12" y1="8" x2="12" y2="16"/>\n'
        '  <polyline points="9,13 12,16 15,13"/>'
    )


def icon_hud_compass_ping():
    """Downward-pointing filled triangle."""
    return make_svg(
        '  <path d="M 12 18 L 7 8 L 17 8 Z" fill="currentColor"/>'
    )


def icon_hud_power():
    """Lightning bolt, consistent with battery, rotated ~15 degrees."""
    return make_svg(
        '  <polyline points="15,3 9,11 13,12 7,21"/>'
    )


def icon_hud_integrity():
    """Shield outline - arc top, straight sides, V-bottom."""
    return make_svg(
        '  <path d="M 4 9 Q 4 4 12 3 Q 20 4 20 9 L 20 13 Q 20 18 12 21 Q 4 18 4 13 Z"/>'
    )


def icon_hud_heat():
    """Thermometer - vertical stem with bulb and tick marks."""
    return make_svg(
        '  <line x1="12" y1="4" x2="12" y2="15"/>\n'
        '  <circle cx="12" cy="18" r="3" fill="currentColor"/>\n'
        '  <line x1="14" y1="7" x2="16" y2="7"/>\n'
        '  <line x1="14" y1="10" x2="16" y2="10"/>\n'
        '  <line x1="14" y1="13" x2="16" y2="13"/>'
    )


def icon_hud_oxygen():
    """Atom symbol - center circle with two orbital arcs."""
    return make_svg(
        '  <circle cx="12" cy="12" r="3"/>\n'
        '  <ellipse cx="12" cy="12" rx="9" ry="4" transform="rotate(30 12 12)"/>\n'
        '  <ellipse cx="12" cy="12" rx="9" ry="4" transform="rotate(-30 12 12)"/>'
    )


def icon_hud_notification_info():
    """Lowercase "i" in a circle."""
    return make_svg(
        '  <circle cx="12" cy="12" r="9"/>\n'
        '  <line x1="12" y1="11" x2="12" y2="17"/>\n'
        '  <circle cx="12" cy="8" r="0.5" fill="currentColor" stroke="none"/>'
    )


def icon_hud_notification_warning():
    """Exclamation mark in triangle."""
    return make_svg(
        '  <path d="M 12 3 L 22 20 L 2 20 Z"/>\n'
        '  <line x1="12" y1="10" x2="12" y2="14"/>\n'
        '  <circle cx="12" cy="17" r="0.5" fill="currentColor" stroke="none"/>'
    )


def icon_hud_notification_critical():
    """Exclamation mark in octagon."""
    # Regular octagon centered at 12,12
    r = 10
    pts = []
    for i in range(8):
        angle = math.radians(-90 + i * 45 + 22.5)
        x = 12 + r * math.cos(angle)
        y = 12 + r * math.sin(angle)
        pts.append(f"{x:.1f} {y:.1f}")
    d = "M " + " L ".join(pts) + " Z"
    return make_svg(
        f'  <path d="{d}"/>\n'
        '  <line x1="12" y1="8" x2="12" y2="13"/>\n'
        '  <circle cx="12" cy="16" r="0.5" fill="currentColor" stroke="none"/>'
    )


def icon_hud_lock():
    """Padlock - shackle arch and rectangular body."""
    return make_svg(
        '  <rect x="5" y="11" width="14" height="10" rx="1"/>\n'
        '  <path d="M 8 11 L 8 8 Q 8 3 12 3 Q 16 3 16 8 L 16 11"/>'
    )


def icon_hud_unlock_chevron():
    """Upward-pointing chevron caret."""
    return make_svg(
        '  <polyline points="6,16 12,8 18,16"/>'
    )


def icon_hud_unlock_check():
    """Checkmark - two angled line segments."""
    return make_svg(
        '  <polyline points="4,13 9,18 20,6"/>'
    )


def icon_hud_mining_active():
    """Drill/pickaxe shape - diagonal tool with rotation arc."""
    return make_svg(
        '  <line x1="6" y1="18" x2="14" y2="6"/>\n'
        '  <polyline points="12,6 14,6 14,8"/>\n'
        '  <path d="M 16,4 A 4,4 0 0,1 20,8"/>\n'
        '  <line x1="14" y1="6" x2="18" y2="4"/>'
    )


def icon_hud_scan_ping():
    """Expanding arc set - 2-3 concentric arcs (radar sweep)."""
    return make_svg(
        '  <path d="M 5 12 A 7 7 0 0 1 12 5"/>\n'
        '  <path d="M 7 16 A 9 9 0 0 1 16 7"/>\n'
        '  <path d="M 3 18 A 14 14 0 0 1 18 3"/>\n'
        '  <circle cx="4" cy="19" r="1" fill="currentColor"/>'
    )


def icon_hud_drone():
    """Quadcopter silhouette - central body with 4 rotor arms."""
    return make_svg(
        '  <circle cx="12" cy="12" r="2"/>\n'
        '  <line x1="10" y1="10" x2="6" y2="6"/>\n'
        '  <line x1="14" y1="10" x2="18" y2="6"/>\n'
        '  <line x1="10" y1="14" x2="6" y2="18"/>\n'
        '  <line x1="14" y1="14" x2="18" y2="18"/>\n'
        '  <circle cx="6" cy="6" r="2.5" stroke-width="1.5"/>\n'
        '  <circle cx="18" cy="6" r="2.5" stroke-width="1.5"/>\n'
        '  <circle cx="6" cy="18" r="2.5" stroke-width="1.5"/>\n'
        '  <circle cx="18" cy="18" r="2.5" stroke-width="1.5"/>'
    )


# ---------------------------------------------------------------------------
# ICON REGISTRY
# ---------------------------------------------------------------------------

ITEM_ICONS = {
    "icon_item_scrap_metal": icon_item_scrap_metal,
    "icon_item_metal": icon_item_metal,
    "icon_item_spare_battery": icon_item_spare_battery,
    "icon_item_head_lamp": icon_item_head_lamp,
    "icon_item_hand_drill": icon_item_hand_drill,
    "icon_item_resource_node": icon_item_resource_node,
    "icon_item_module_recycler": icon_item_module_recycler,
    "icon_item_module_fabricator": icon_item_module_fabricator,
    "icon_item_module_automation_hub": icon_item_module_automation_hub,
}

HUD_ICONS = {
    "icon_hud_battery": icon_hud_battery,
    "icon_hud_scanner": icon_hud_scanner,
    "icon_hud_battery_micro": icon_hud_battery_micro,
    "icon_hud_star_filled": icon_hud_star_filled,
    "icon_hud_star_empty": icon_hud_star_empty,
    "icon_hud_compass_center": icon_hud_compass_center,
    "icon_hud_compass_ping": icon_hud_compass_ping,
    "icon_hud_power": icon_hud_power,
    "icon_hud_integrity": icon_hud_integrity,
    "icon_hud_heat": icon_hud_heat,
    "icon_hud_oxygen": icon_hud_oxygen,
    "icon_hud_notification_info": icon_hud_notification_info,
    "icon_hud_notification_warning": icon_hud_notification_warning,
    "icon_hud_notification_critical": icon_hud_notification_critical,
    "icon_hud_lock": icon_hud_lock,
    "icon_hud_unlock_chevron": icon_hud_unlock_chevron,
    "icon_hud_unlock_check": icon_hud_unlock_check,
    "icon_hud_mining_active": icon_hud_mining_active,
    "icon_hud_scan_ping": icon_hud_scan_ping,
    "icon_hud_drone": icon_hud_drone,
}


# ---------------------------------------------------------------------------
# GENERATION
# ---------------------------------------------------------------------------

def main():
    os.makedirs(ITEM_DIR, exist_ok=True)
    os.makedirs(HUD_DIR, exist_ok=True)

    timing_records = []
    total_start = time.time()

    # Generate item icons
    for name, fn in ITEM_ICONS.items():
        t0 = time.time()
        svg_content = fn()
        t1 = time.time()
        filepath = os.path.join(ITEM_DIR, f"{name}.svg")
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(svg_content)
        duration_ms = (t1 - t0) * 1000
        timing_records.append({
            "name": name,
            "category": "item",
            "duration_ms": round(duration_ms, 2),
            "cost": 0.00,
            "file": filepath,
        })
        print(f"  [item] {name}.svg  ({duration_ms:.1f}ms)")

    # Generate HUD icons
    for name, fn in HUD_ICONS.items():
        t0 = time.time()
        svg_content = fn()
        t1 = time.time()
        filepath = os.path.join(HUD_DIR, f"{name}.svg")
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(svg_content)
        duration_ms = (t1 - t0) * 1000
        timing_records.append({
            "name": name,
            "category": "hud",
            "duration_ms": round(duration_ms, 2),
            "cost": 0.00,
            "file": filepath,
        })
        print(f"  [hud]  {name}.svg  ({duration_ms:.1f}ms)")

    total_end = time.time()
    total_duration_s = total_end - total_start

    # Write timing data as JSON for iteration log generation
    timing_output = {
        "experiment": "Method A - Programmatic SVG",
        "generated_at": datetime.now().isoformat(),
        "total_icons": len(timing_records),
        "total_duration_s": round(total_duration_s, 3),
        "total_cost_usd": 0.00,
        "icons": timing_records,
    }
    timing_path = os.path.join(PROJECT_DIR, "docs", "art", "icon-experiments", "method-a", "timing.json")
    with open(timing_path, "w", encoding="utf-8") as f:
        json.dump(timing_output, f, indent=2)

    print(f"\nDone. {len(timing_records)} icons generated in {total_duration_s:.3f}s")
    print(f"Timing data: {timing_path}")


if __name__ == "__main__":
    main()
