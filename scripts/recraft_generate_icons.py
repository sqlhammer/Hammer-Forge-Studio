#!/usr/bin/env python3
"""
TICKET-0093: Experiment B — Recraft.ai API icon generation
Generates all 29 icons (9 item + 20 HUD) using the Recraft v3 API.
Tracks timing and cost for the iteration log.
"""

import json
import os
import re
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime, timezone
from xml.etree import ElementTree as ET

API_BASE = "https://external.api.recraft.ai/v1"
API_KEY = os.environ.get("RECRAFT_AI_API_KEY", "")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BASE_DIR)
ITEM_DIR = os.path.join(PROJECT_ROOT, "docs", "art", "icon-experiments", "method-b", "item-icons")
HUD_DIR = os.path.join(PROJECT_ROOT, "docs", "art", "icon-experiments", "method-b", "hud-icons")
LOG_FILE = os.path.join(PROJECT_ROOT, "docs", "art", "icon-experiments", "method-b", "iteration-log.md")

os.makedirs(ITEM_DIR, exist_ok=True)
os.makedirs(HUD_DIR, exist_ok=True)

# --- Icon definitions with tailored prompts ---

ITEM_ICONS = [
    {
        "filename": "icon_item_scrap_metal.svg",
        "prompt": "minimalist line art icon of jagged scrap metal fragments, torn metal pieces stacked at slight angle showing thickness, 3/4 isometric view, single continuous stroke weight, white lines on transparent background, sci-fi industrial style, no text, no background shape",
    },
    {
        "filename": "icon_item_metal.svg",
        "prompt": "minimalist line art icon of a refined metal ingot bar, rectangular block shown in 3/4 isometric perspective revealing top and side faces, clean geometric edges, single stroke weight, white lines on transparent background, sci-fi industrial style, no text",
    },
    {
        "filename": "icon_item_spare_battery.svg",
        "prompt": "minimalist line art icon of a portable power cell battery, cylindrical or rectangular battery with terminal contacts on top, 3/4 view showing depth, single stroke weight, white lines on transparent background, sci-fi style, no text",
    },
    {
        "filename": "icon_item_head_lamp.svg",
        "prompt": "minimalist line art icon of a head-mounted lamp headlamp, circular lens with strap band, 3/4 view, single stroke weight, white lines on transparent background, sci-fi explorer equipment style, no text",
    },
    {
        "filename": "icon_item_hand_drill.svg",
        "prompt": "minimalist line art icon of a handheld mining drill tool, pistol-grip drill with spiral drill bit, slight isometric 3/4 view, single stroke weight, white lines on transparent background, sci-fi mining equipment style, no text",
    },
    {
        "filename": "icon_item_resource_node.svg",
        "prompt": "minimalist line art icon of a mineral crystal resource deposit node, geometric crystal cluster emerging from rock base, slight isometric view, single stroke weight, white lines on transparent background, sci-fi geology style, no text",
    },
    {
        "filename": "icon_item_module_recycler.svg",
        "prompt": "minimalist line art icon of a ship recycler processing module, boxy industrial machine with input hopper and circular recycling arrows symbol, slight isometric 3/4 view, single stroke weight, white lines on transparent background, sci-fi machinery style, no text",
    },
    {
        "filename": "icon_item_module_fabricator.svg",
        "prompt": "minimalist line art icon of a ship fabricator manufacturing module, boxy industrial machine with robotic arm or nozzle, slight isometric 3/4 view, single stroke weight, white lines on transparent background, sci-fi machinery style, no text",
    },
    {
        "filename": "icon_item_module_automation_hub.svg",
        "prompt": "minimalist line art icon of a ship automation hub control module, boxy industrial machine with antenna array and signal waves, slight isometric 3/4 view, single stroke weight, white lines on transparent background, sci-fi machinery style, no text",
    },
]

HUD_ICONS = [
    {
        "filename": "icon_hud_battery.svg",
        "prompt": "minimalist line art icon of a lightning bolt symbol, simple zigzag bolt shape pointing downward, 3-4 angled line segments, monoline stroke, white on transparent background, functional glyph style, no text, no circle border",
    },
    {
        "filename": "icon_hud_scanner.svg",
        "prompt": "minimalist line art icon of a diamond shape rotated square, simple 4-sided diamond outline, monoline stroke, white on transparent background, functional glyph HUD style, no text, no extra decoration",
    },
    {
        "filename": "icon_hud_battery_micro.svg",
        "prompt": "minimalist line art icon of a tiny simplified lightning bolt, 2-3 line segments forming small zigzag, very simple monoline stroke, white on transparent background, minimal HUD glyph, no text",
    },
    {
        "filename": "icon_hud_star_filled.svg",
        "prompt": "minimalist icon of a solid filled 5-pointed star, clean geometric star shape completely filled in white, on transparent background, simple clean shape, no text, no border",
    },
    {
        "filename": "icon_hud_star_empty.svg",
        "prompt": "minimalist line art icon of a 5-pointed star outline, star shape stroke only not filled, monoline stroke, white on transparent background, clean geometric, no text",
    },
    {
        "filename": "icon_hud_compass_center.svg",
        "prompt": "minimalist line art icon of a vertical tick mark, single short vertical line or narrow downward caret chevron, monoline stroke, white on transparent background, compass heading marker style, no text, extremely simple",
    },
    {
        "filename": "icon_hud_compass_ping.svg",
        "prompt": "minimalist icon of a downward-pointing filled triangle, small solid white triangle pointing down, simple geometric shape on transparent background, compass directional marker, no text, no border",
    },
    {
        "filename": "icon_hud_power.svg",
        "prompt": "minimalist line art icon of a lightning bolt for power indicator, simple zigzag bolt rotated 15 degrees, monoline stroke, white on transparent background, HUD power status glyph, no text, no circle",
    },
    {
        "filename": "icon_hud_integrity.svg",
        "prompt": "minimalist line art icon of a shield outline, simple shield silhouette with arc top and V-shaped bottom, stroke only no fill, monoline, white on transparent background, HUD integrity status glyph, no text",
    },
    {
        "filename": "icon_hud_heat.svg",
        "prompt": "minimalist line art icon of a thermometer, vertical line with round bulb at base and 2-3 horizontal tick marks on side, monoline stroke, white on transparent background, HUD temperature indicator glyph, no text",
    },
    {
        "filename": "icon_hud_oxygen.svg",
        "prompt": "minimalist line art icon of an atom symbol, central circle with 2 orbital ellipse arcs crossing around it, monoline stroke, white on transparent background, HUD oxygen indicator glyph, no text",
    },
    {
        "filename": "icon_hud_notification_info.svg",
        "prompt": "minimalist line art icon of an information symbol, lowercase letter i inside a circle, circle outline with dot and vertical bar inside, monoline stroke, white on transparent background, notification badge glyph, no text except the i symbol",
    },
    {
        "filename": "icon_hud_notification_warning.svg",
        "prompt": "minimalist line art icon of a warning triangle with exclamation mark, triangle outline with exclamation point inside, monoline stroke, white on transparent background, warning notification badge glyph",
    },
    {
        "filename": "icon_hud_notification_critical.svg",
        "prompt": "minimalist line art icon of an error or critical alert symbol, exclamation mark inside an octagon or thick circle outline, monoline stroke, white on transparent background, critical notification badge glyph",
    },
    {
        "filename": "icon_hud_lock.svg",
        "prompt": "minimalist line art icon of a padlock, semicircle shackle arch on top of rectangular body, simple lock shape, no keyhole, monoline stroke, white on transparent background, tech tree locked state glyph, no text",
    },
    {
        "filename": "icon_hud_unlock_chevron.svg",
        "prompt": "minimalist line art icon of an upward pointing chevron caret, two angled lines meeting at top forming a V shape pointing up, monoline stroke, white on transparent background, extremely simple, no text, no circle",
    },
    {
        "filename": "icon_hud_unlock_check.svg",
        "prompt": "minimalist line art icon of a checkmark, two lines forming a check tick mark, left short stroke going down and right longer stroke going up, monoline stroke, white on transparent background, simple confirmation glyph, no text, no circle",
    },
    {
        "filename": "icon_hud_mining_active.svg",
        "prompt": "minimalist line art icon of a mining pickaxe or drill bit with small rotation arc indicator, diagonal tool shape suggesting active mining, monoline stroke, white on transparent background, HUD activity indicator glyph, no text",
    },
    {
        "filename": "icon_hud_scan_ping.svg",
        "prompt": "minimalist line art icon of radar scan pulse, 2-3 concentric arcs expanding outward from a point, open on one side like a radar sweep, monoline stroke, white on transparent background, scan ping HUD glyph, no text",
    },
    {
        "filename": "icon_hud_drone.svg",
        "prompt": "minimalist line art icon of a quadcopter drone seen from above, small central circle with 4 short rotor lines extending at diagonal angles, X-shape with corner nodes, monoline stroke, white on transparent background, drone indicator HUD glyph, no text",
    },
]


def generate_icon(prompt: str) -> dict:
    """Call Recraft API via curl and return response dict with URL and metadata."""
    import subprocess
    payload = json.dumps({
        "prompt": prompt,
        "model": "recraftv3",
        "style": "vector_illustration",
        "substyle": "line_art",
        "size": "1024x1024",
        "response_format": "url",
    })

    result = subprocess.run(
        [
            "curl", "-s", "-w", "\n%{http_code}",
            f"{API_BASE}/images/generations",
            "-H", f"Authorization: Bearer {API_KEY}",
            "-H", "Content-Type: application/json",
            "-d", payload,
        ],
        capture_output=True, text=True, timeout=120,
    )

    output = result.stdout.strip()
    lines = output.rsplit("\n", 1)
    body = lines[0] if len(lines) > 1 else output
    http_code = int(lines[1]) if len(lines) > 1 else 0

    if http_code != 200:
        raise RuntimeError(f"HTTP {http_code}: {body}")

    return json.loads(body)


def download_svg(url: str) -> str:
    """Download SVG content from URL via curl."""
    import subprocess
    result = subprocess.run(
        ["curl", "-s", url],
        capture_output=True, text=True, timeout=60,
    )
    if result.returncode != 0:
        raise RuntimeError(f"curl download failed: {result.stderr}")
    return result.stdout


def postprocess_svg(raw_svg: str) -> str:
    """
    Post-process Recraft SVG to better match style guide:
    - Change viewBox to 0 0 24 24
    - Remove width/height attributes
    - Remove background rectangle (first large filled path)
    - Attempt to normalize colors for currentColor compatibility
    """
    # Parse the SVG
    ET.register_namespace("", "http://www.w3.org/2000/svg")
    root = ET.fromstring(raw_svg)
    ns = {"svg": "http://www.w3.org/2000/svg"}

    # Get original viewBox dimensions for coordinate scaling
    original_vb = root.get("viewBox", "0 0 2048 2048")
    vb_parts = original_vb.split()
    orig_w = float(vb_parts[2]) if len(vb_parts) >= 3 else 2048
    orig_h = float(vb_parts[3]) if len(vb_parts) >= 4 else 2048

    # Update viewBox to 24x24
    root.set("viewBox", "0 0 24 24")

    # Remove width, height, style, preserveAspectRatio
    for attr in ["width", "height", "style", "preserveAspectRatio", "version"]:
        if attr in root.attrib:
            del root.attrib[attr]

    # Add xmlns if missing
    root.set("xmlns", "http://www.w3.org/2000/svg")

    # Process paths
    paths = root.findall(".//path", ns) or root.findall("path")
    if not paths:
        paths = list(root.iter())
        paths = [p for p in paths if p.tag.endswith("path") or p.tag == "path"]

    # Remove background rect (first path that covers the full canvas)
    if paths:
        first_path = paths[0]
        d_attr = first_path.get("d", "")
        fill = first_path.get("fill", "")
        # Check if it's a full-canvas background rectangle
        if ("M 0 0" in d_attr or "M0 0" in d_attr) and ("254,254,254" in fill or "255,255,255" in fill or "white" in fill.lower()):
            parent = root
            for p in root.iter():
                if first_path in list(p):
                    parent = p
                    break
            parent.remove(first_path)
            paths = paths[1:]

    # Normalize colors: black fills → currentColor, white fills → currentColor
    for path in paths:
        fill = path.get("fill", "")
        stroke = path.get("stroke", "")

        # Convert black-ish fills to currentColor
        if "rgb(0,0,0)" in fill or "rgb(0, 0, 0)" in fill or fill == "#000000" or fill == "black":
            path.set("fill", "currentColor")
        # Convert white-ish fills to currentColor (for inverted icons)
        elif "rgb(254,254,254)" in fill or "rgb(255,255,255)" in fill or fill == "#ffffff" or fill == "white":
            path.set("fill", "currentColor")

        # Remove transform if it's just translate(0,0)
        transform = path.get("transform", "")
        if transform == "translate(0,0)":
            del path.attrib["transform"]

    # Scale all path coordinates from original viewBox to 24x24
    scale_x = 24.0 / orig_w
    scale_y = 24.0 / orig_h

    # Add a group transform to handle the scaling
    # Wrap all children in a <g> with scale transform
    children = list(root)
    if children and scale_x != 1.0:
        g = ET.SubElement(root, "g")
        g.set("transform", f"scale({scale_x:.6f},{scale_y:.6f})")
        for child in children:
            root.remove(child)
            g.append(child)

    # Serialize
    svg_str = ET.tostring(root, encoding="unicode")

    # Clean up namespace prefixes
    svg_str = svg_str.replace("ns0:", "").replace(":ns0", "")

    return svg_str


def run_experiment():
    """Run the full experiment, generating all icons and tracking metrics."""
    if not API_KEY:
        print("ERROR: RECRAFT_AI_API_KEY not set")
        sys.exit(1)

    all_results = []
    total_cost_credits = 0
    experiment_start = time.time()
    experiment_start_ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    # Check initial credit balance
    try:
        req = urllib.request.Request(
            f"{API_BASE}/users/me",
            headers={"Authorization": f"Bearer {API_KEY}"},
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            user_info = json.loads(resp.read().decode("utf-8"))
            initial_credits = user_info.get("credits", "unknown")
            print(f"Initial credit balance: {initial_credits}")
    except Exception as e:
        initial_credits = "unknown"
        print(f"Could not check credits: {e}")

    # Generate item icons
    print("\n=== GENERATING ITEM ICONS (9) ===\n")
    for i, icon in enumerate(ITEM_ICONS):
        icon_start = time.time()
        icon_start_ts = datetime.now(timezone.utc).strftime("%H:%M:%S")
        filename = icon["filename"]
        output_path = os.path.join(ITEM_DIR, filename)

        print(f"[{i+1}/9] Generating {filename}...", end=" ", flush=True)

        result = {
            "filename": filename,
            "category": "item",
            "start_time": icon_start_ts,
            "end_time": "",
            "duration_s": 0,
            "credits_used": 0,
            "notes": "",
            "success": False,
        }

        try:
            resp = generate_icon(icon["prompt"])
            credits_after = resp.get("credits", 0)
            url = resp["data"][0]["url"]

            raw_svg = download_svg(url)
            processed_svg = postprocess_svg(raw_svg)

            with open(output_path, "w", encoding="utf-8") as f:
                f.write(processed_svg)

            icon_end = time.time()
            result["end_time"] = datetime.now(timezone.utc).strftime("%H:%M:%S")
            result["duration_s"] = round(icon_end - icon_start, 1)
            result["credits_used"] = credits_after
            result["success"] = True
            result["notes"] = "Generated and post-processed successfully"
            print(f"OK ({result['duration_s']}s, credits remaining: {credits_after})")

        except Exception as e:
            icon_end = time.time()
            result["end_time"] = datetime.now(timezone.utc).strftime("%H:%M:%S")
            result["duration_s"] = round(icon_end - icon_start, 1)
            result["notes"] = f"ERROR: {str(e)}"
            print(f"FAILED: {e}")

        all_results.append(result)
        # Brief pause between API calls to avoid rate limiting
        time.sleep(1)

    # Generate HUD icons
    print("\n=== GENERATING HUD ICONS (20) ===\n")
    for i, icon in enumerate(HUD_ICONS):
        icon_start = time.time()
        icon_start_ts = datetime.now(timezone.utc).strftime("%H:%M:%S")
        filename = icon["filename"]
        output_path = os.path.join(HUD_DIR, filename)

        print(f"[{i+1}/20] Generating {filename}...", end=" ", flush=True)

        result = {
            "filename": filename,
            "category": "hud",
            "start_time": icon_start_ts,
            "end_time": "",
            "duration_s": 0,
            "credits_used": 0,
            "notes": "",
            "success": False,
        }

        try:
            resp = generate_icon(icon["prompt"])
            credits_after = resp.get("credits", 0)
            url = resp["data"][0]["url"]

            raw_svg = download_svg(url)
            processed_svg = postprocess_svg(raw_svg)

            with open(output_path, "w", encoding="utf-8") as f:
                f.write(processed_svg)

            icon_end = time.time()
            result["end_time"] = datetime.now(timezone.utc).strftime("%H:%M:%S")
            result["duration_s"] = round(icon_end - icon_start, 1)
            result["credits_used"] = credits_after
            result["success"] = True
            result["notes"] = "Generated and post-processed successfully"
            print(f"OK ({result['duration_s']}s, credits remaining: {credits_after})")

        except Exception as e:
            icon_end = time.time()
            result["end_time"] = datetime.now(timezone.utc).strftime("%H:%M:%S")
            result["duration_s"] = round(icon_end - icon_start, 1)
            result["notes"] = f"ERROR: {str(e)}"
            print(f"FAILED: {e}")

        all_results.append(result)
        time.sleep(1)

    # Check final credit balance
    try:
        req = urllib.request.Request(
            f"{API_BASE}/users/me",
            headers={"Authorization": f"Bearer {API_KEY}"},
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            user_info = json.loads(resp.read().decode("utf-8"))
            final_credits = user_info.get("credits", "unknown")
    except Exception:
        final_credits = "unknown"

    experiment_end = time.time()
    total_wall_clock = round(experiment_end - experiment_start, 1)

    # Calculate totals
    successful = [r for r in all_results if r["success"]]
    failed = [r for r in all_results if not r["success"]]
    item_results = [r for r in all_results if r["category"] == "item"]
    hud_results = [r for r in all_results if r["category"] == "hud"]

    # Write results JSON for later use
    results_json = {
        "experiment_start": experiment_start_ts,
        "initial_credits": initial_credits,
        "final_credits": final_credits,
        "total_wall_clock_s": total_wall_clock,
        "total_icons": len(all_results),
        "successful": len(successful),
        "failed": len(failed),
        "results": all_results,
    }

    results_path = os.path.join(PROJECT_ROOT, "docs", "art", "icon-experiments", "method-b", "results.json")
    with open(results_path, "w", encoding="utf-8") as f:
        json.dump(results_json, f, indent=2)

    print(f"\n=== EXPERIMENT COMPLETE ===")
    print(f"Total time: {total_wall_clock}s")
    print(f"Successful: {len(successful)}/29")
    print(f"Failed: {len(failed)}/29")
    print(f"Initial credits: {initial_credits}")
    print(f"Final credits: {final_credits}")
    print(f"Results saved to: {results_path}")


if __name__ == "__main__":
    run_experiment()
