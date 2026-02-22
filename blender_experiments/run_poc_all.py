"""
PoC Runner — Generate all 4 target assets for TICKET-0009
==========================================================
Run with: blender --background --python run_poc_all.py

Produces:
  poc_output/mesh_hand_drill.glb
  poc_output/mesh_player_character.glb
  poc_output/mesh_ship_exterior.glb
  poc_output/mesh_resource_node_scrap.glb
"""

import sys
import os
import time

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ROOT)

from master_control import generate_and_export, ROOT_DIR

# Override output directory to poc_output/
POC_DIR = ROOT_DIR / "poc_output"
POC_DIR.mkdir(parents=True, exist_ok=True)

# Monkey-patch ensure_output_dir to always use poc_output
import master_control
_original_ensure = master_control.ensure_output_dir
def _poc_output_dir(object_name: str):
    return POC_DIR
master_control.ensure_output_dir = _poc_output_dir


# ================================================================
# IMPORT BUILDERS
# ================================================================
from build_hand_drill import build_hand_drill
from build_player_character import build_player_character
from build_ship_exterior import build_ship_exterior
from build_resource_node import build_resource_node


# ================================================================
# ASSET DEFINITIONS
# ================================================================
ASSETS = [
    {
        "name": "mesh_hand_drill",
        "prompt": "Handheld sci-fi extraction drill, stylized chunky proportions.",
        "build_fn": build_hand_drill,
        "strategy": "Beveled primitives with 8 PBR materials.",
    },
    {
        "name": "mesh_player_character",
        "prompt": "Full-body humanoid in environmental research suit, T-pose, ~1.8m.",
        "build_fn": build_player_character,
        "strategy": "Multi-segment primitives with BMesh visor cutout, 10 PBR materials.",
    },
    {
        "name": "mesh_ship_exterior",
        "prompt": "Atmospheric research vessel, utilitarian sci-fi, ~15m long.",
        "build_fn": build_ship_exterior,
        "strategy": "Beveled box hull sections with engine cylinders, 8 PBR materials.",
    },
    {
        "name": "mesh_resource_node_scrap",
        "prompt": "Scrap metal deposit in alien debris, ~2m wide.",
        "build_fn": build_resource_node,
        "strategy": "Deformed spheres + beveled cubes, seeded random, 7 PBR materials.",
    },
]


# ================================================================
# MAIN
# ================================================================
def main():
    print("\n" + "=" * 60)
    print("  TICKET-0009: Blender Python PoC — All 4 Assets")
    print("=" * 60)

    results = {}
    total_start = time.time()

    for asset in ASSETS:
        print(f"\n--- Generating: {asset['name']} ---")
        start = time.time()
        try:
            files = generate_and_export(
                object_name=asset["name"],
                prompt=asset["prompt"],
                build_fn=asset["build_fn"],
                strategy=asset["strategy"],
            )
            elapsed = time.time() - start
            results[asset["name"]] = {
                "status": "SUCCESS",
                "time": elapsed,
                "files": files,
            }
            print(f"  Completed in {elapsed:.1f}s")
        except Exception as e:
            elapsed = time.time() - start
            results[asset["name"]] = {
                "status": "FAILED",
                "time": elapsed,
                "error": str(e),
            }
            print(f"  FAILED after {elapsed:.1f}s: {e}")

    total_elapsed = time.time() - total_start

    # Summary
    print("\n" + "=" * 60)
    print("  RESULTS SUMMARY")
    print("=" * 60)
    for name, result in results.items():
        status = result["status"]
        t = result["time"]
        print(f"  {name}: {status} ({t:.1f}s)")
    print(f"\n  Total time: {total_elapsed:.1f}s")
    print("=" * 60)


if __name__ == "__main__":
    main()
