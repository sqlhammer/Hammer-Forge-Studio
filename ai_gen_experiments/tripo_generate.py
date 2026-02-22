"""
Tripo3D API Integration — AI Mesh Generation Pipeline
======================================================
TICKET-0010: Generates game assets via Tripo3D's REST API.

Usage:
  export TRIPO_API_KEY="your-api-key-here"
  python tripo_generate.py

Or generate a single asset:
  python tripo_generate.py --asset hand_drill

Requirements:
  pip install requests
"""

import os
import sys
import time
import json
import requests
from pathlib import Path

# ================================================================
# CONFIGURATION
# ================================================================
API_BASE = "https://api.tripo3d.ai/v2/openapi"
API_KEY = os.environ.get("TRIPO_API_KEY", "")
OUTPUT_DIR = Path(__file__).parent / "poc_output"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

POLL_INTERVAL = 5  # seconds between status checks
MAX_WAIT = 300     # max seconds to wait for a task


# ================================================================
# ASSET DEFINITIONS — matched to TICKET-0008 briefs
# ================================================================
ASSETS = {
    "hand_drill": {
        "output_name": "mesh_hand_drill",
        "prompt": (
            "A handheld sci-fi extraction drill tool, stylized chunky proportions. "
            "Worn brushed metal housing with rubber grip handle, glowing cyan energy "
            "conduit running along the top, drill bit tip at the front. "
            "Three small green charge indicator lights on the side panel. "
            "Exhaust vents at the rear. Size of a large cordless drill but slightly "
            "oversized for sci-fi readability. Outer Wilds art style, utilitarian "
            "research equipment aesthetic. Not a weapon."
        ),
        "negative_prompt": "realistic, photorealistic, weapon, gun, military, tiny, miniature",
    },
    "player_character": {
        "output_name": "mesh_player_character",
        "prompt": (
            "Full-body humanoid character wearing a bulky environmental research suit. "
            "T-pose or A-pose. Rounded helmet with dark opaque visor. Deep blue fabric "
            "suit with gunmetal gray armor plates at shoulders, chest, and knees. "
            "Tall boots nearly to the knees. Equipment backpack on the back. "
            "Belt with tool attachment points. ~1.8m tall human proportions, slightly "
            "stylized and chunky. Outer Wilds / Hades inspired art style. "
            "Field researcher, not a soldier."
        ),
        "negative_prompt": "realistic, photorealistic, military, soldier, weapon, skinny, anime",
    },
    "ship_exterior": {
        "output_name": "mesh_ship_exterior",
        "prompt": (
            "Atmospheric research vessel, a mobile base that can fly. Chunky utilitarian "
            "sci-fi design like Outer Wilds spaceship. Asymmetric hull with cargo pod on "
            "one side. Dual main engines at the rear with visible thruster nozzles. "
            "Cockpit windshield at the front. Communication antenna dish on top. "
            "Three-point landing gear deployed. Riveted metal plating with orange accent "
            "stripes. Panel seams and hatches visible on hull. Size of a small cargo plane. "
            "Not sleek or military — cobbled together, utilitarian, has personality."
        ),
        "negative_prompt": "realistic, photorealistic, military, fighter jet, sleek, symmetrical, starship",
    },
    "resource_node": {
        "output_name": "mesh_resource_node_scrap",
        "prompt": (
            "A pile of alien architecture rubble with exposed scrap metal deposits. "
            "Weathered rock and cracked synthetic debris forming an irregular mound "
            "about 2 meters wide. Bright metallic veins and fragments visible embedded "
            "in the dark rock, clearly readable as extractable resources. "
            "Oxidized rust-colored edges where metal meets rock. Partially buried in "
            "ground. Muted earth tones with reflective metal contrast. "
            "Stylized sci-fi prop, mineable resource node for a game."
        ),
        "negative_prompt": "realistic, photorealistic, crystal, gem, glowing, floating, clean",
    },
}


# ================================================================
# API HELPERS
# ================================================================
def _headers():
    return {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}",
    }


def create_text_to_3d_task(prompt, negative_prompt=""):
    """Submit a text-to-3D generation task."""
    payload = {
        "type": "text_to_model",
        "prompt": prompt,
    }
    if negative_prompt:
        payload["negative_prompt"] = negative_prompt

    resp = requests.post(
        f"{API_BASE}/task",
        headers=_headers(),
        json=payload,
    )
    resp.raise_for_status()
    data = resp.json()
    if data.get("code") != 0:
        raise RuntimeError(f"API error: {data}")
    return data["data"]["task_id"]


def poll_task(task_id):
    """Poll until task completes or fails."""
    start = time.time()
    while time.time() - start < MAX_WAIT:
        resp = requests.get(
            f"{API_BASE}/task/{task_id}",
            headers=_headers(),
        )
        resp.raise_for_status()
        data = resp.json()["data"]
        status = data.get("status", "unknown")

        if status == "success":
            return data
        elif status in ("failed", "cancelled", "unknown"):
            raise RuntimeError(f"Task {task_id} ended with status: {status}")

        progress = data.get("progress", 0)
        print(f"  Status: {status} ({progress}%)")
        time.sleep(POLL_INTERVAL)

    raise TimeoutError(f"Task {task_id} timed out after {MAX_WAIT}s")


def download_glb(task_id, output_path):
    """Download the GLB output for a completed task."""
    # Request GLB download URL
    payload = {
        "task_id": task_id,
        "type": "glb",
    }
    resp = requests.post(
        f"{API_BASE}/task/{task_id}/download",
        headers=_headers(),
        json=payload,
    )
    resp.raise_for_status()
    data = resp.json()

    # The response contains the model data or a download URL
    if "data" in data and "model" in data["data"]:
        model_url = data["data"]["model"]["url"]
    elif "data" in data and "url" in data["data"]:
        model_url = data["data"]["url"]
    else:
        # Try direct output from task result
        raise RuntimeError(f"Unexpected download response: {data}")

    # Download the actual file
    model_resp = requests.get(model_url)
    model_resp.raise_for_status()
    with open(output_path, "wb") as f:
        f.write(model_resp.content)
    print(f"  Saved: {output_path} ({len(model_resp.content)} bytes)")


def generate_asset(asset_key):
    """Generate a single asset end-to-end."""
    asset = ASSETS[asset_key]
    print(f"\n{'='*50}")
    print(f"Generating: {asset['output_name']}")
    print(f"{'='*50}")

    start = time.time()

    # Step 1: Create task
    print("  Submitting generation task...")
    task_id = create_text_to_3d_task(
        prompt=asset["prompt"],
        negative_prompt=asset.get("negative_prompt", ""),
    )
    print(f"  Task ID: {task_id}")

    # Step 2: Poll for completion
    print("  Waiting for generation...")
    result = poll_task(task_id)

    # Step 3: Download GLB
    output_path = OUTPUT_DIR / f"{asset['output_name']}.glb"
    print("  Downloading GLB...")
    download_glb(task_id, str(output_path))

    elapsed = time.time() - start
    print(f"  Completed in {elapsed:.1f}s")

    return {
        "name": asset["output_name"],
        "task_id": task_id,
        "time": elapsed,
        "path": str(output_path),
    }


# ================================================================
# MAIN
# ================================================================
def main():
    if not API_KEY:
        print("ERROR: TRIPO_API_KEY environment variable not set.")
        print("Get an API key at https://www.tripo3d.ai/")
        print("Then: export TRIPO_API_KEY='your-key-here'")
        sys.exit(1)

    # Parse arguments
    if "--asset" in sys.argv:
        idx = sys.argv.index("--asset") + 1
        if idx < len(sys.argv):
            asset_key = sys.argv[idx]
            if asset_key not in ASSETS:
                print(f"Unknown asset: {asset_key}")
                print(f"Available: {', '.join(ASSETS.keys())}")
                sys.exit(1)
            results = [generate_asset(asset_key)]
        else:
            print("--asset requires an asset name")
            sys.exit(1)
    else:
        # Generate all assets
        results = []
        for key in ASSETS:
            try:
                results.append(generate_asset(key))
            except Exception as e:
                print(f"  FAILED: {e}")
                results.append({"name": ASSETS[key]["output_name"], "error": str(e)})

    # Summary
    print(f"\n{'='*50}")
    print("RESULTS SUMMARY")
    print(f"{'='*50}")
    for r in results:
        if "error" in r:
            print(f"  {r['name']}: FAILED - {r['error']}")
        else:
            print(f"  {r['name']}: OK ({r['time']:.1f}s) -> {r['path']}")


if __name__ == "__main__":
    main()
