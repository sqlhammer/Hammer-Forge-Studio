"""
Decimate AI-Generated Assets for Game Use
==========================================
TICKET-0016: Process Tripo3D AI output through Blender decimation
to meet polygon budgets defined in docs/art/tech-specs.md.

Usage:
  blender --background --python blender_experiments/decimate_ai_assets.py

Input:  game/poc_ai_gen/*.glb (AI-generated, 100K-285K vertices)
Output: game/assets/meshes/*/*.glb (decimated to budget)
"""

import bpy
import os
import sys
import time
from pathlib import Path

# Project root — resolve relative to this script
PROJECT_ROOT = Path(__file__).resolve().parent.parent
INPUT_DIR = PROJECT_ROOT / "game" / "poc_ai_gen"
OUTPUT_BASE = PROJECT_ROOT / "game" / "assets" / "meshes"

# Asset definitions: input filename -> (output subdir, output filename, target triangles)
# Target tris set to middle of budget range from tech-specs.md
ASSETS = {
    "mesh_hand_drill.glb": {
        "output_dir": "tools",
        "output_name": "mesh_hand_drill.glb",
        "target_tris": 4000,    # budget: 2,000-5,000
        "budget_max": 5000,
    },
    "mesh_player_character.glb": {
        "output_dir": "characters",
        "output_name": "mesh_player_character.glb",
        "target_tris": 8000,    # budget: 5,000-10,000
        "budget_max": 10000,
    },
    "mesh_ship_exterior.glb": {
        "output_dir": "vehicles",
        "output_name": "mesh_ship_exterior.glb",
        "target_tris": 12000,   # budget: 8,000-15,000
        "budget_max": 15000,
    },
    "mesh_resource_node_scrap.glb": {
        "output_dir": "props",
        "output_name": "mesh_resource_node_scrap.glb",
        "target_tris": 3000,    # budget: 1,500-4,000
        "budget_max": 4000,
    },
}


def clear_scene():
    """Remove all objects from the scene."""
    bpy.ops.wm.read_factory_settings(use_empty=True)


def count_tris():
    """Count total triangles across all mesh objects."""
    total = 0
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            # Use evaluated mesh to account for modifiers
            depsgraph = bpy.context.evaluated_depsgraph_get()
            obj_eval = obj.evaluated_get(depsgraph)
            mesh = obj_eval.to_mesh()
            mesh.calc_loop_triangles()
            total += len(mesh.loop_triangles)
            obj_eval.to_mesh_clear()
    return total


def decimate_asset(input_path, output_path, target_tris, budget_max):
    """Import GLB, decimate to target triangle count, export."""
    clear_scene()

    # Import
    print(f"  Importing: {input_path}")
    bpy.ops.import_scene.gltf(filepath=str(input_path))

    # Count initial triangles
    initial_tris = count_tris()
    print(f"  Initial triangles: {initial_tris}")

    if initial_tris <= budget_max:
        print(f"  Already within budget ({budget_max}), skipping decimation")
    else:
        # Calculate decimation ratio
        ratio = target_tris / initial_tris
        ratio = max(0.001, min(ratio, 1.0))  # clamp
        print(f"  Decimation ratio: {ratio:.4f} (target: {target_tris} tris)")

        # Apply decimate modifier to all meshes
        for obj in bpy.data.objects:
            if obj.type == 'MESH':
                bpy.context.view_layer.objects.active = obj
                obj.select_set(True)

                mod = obj.modifiers.new(name="Decimate", type='DECIMATE')
                mod.decimate_type = 'COLLAPSE'
                mod.ratio = ratio
                mod.use_collapse_triangulate = True

                bpy.ops.object.modifier_apply(modifier="Decimate")
                obj.select_set(False)

        final_tris = count_tris()
        print(f"  Final triangles: {final_tris} (budget max: {budget_max})")

        # If still over budget, do a second pass with tighter ratio
        if final_tris > budget_max:
            second_ratio = budget_max / final_tris * 0.9  # 10% safety margin
            print(f"  Still over budget, second pass ratio: {second_ratio:.4f}")
            for obj in bpy.data.objects:
                if obj.type == 'MESH':
                    bpy.context.view_layer.objects.active = obj
                    obj.select_set(True)
                    mod = obj.modifiers.new(name="Decimate2", type='DECIMATE')
                    mod.decimate_type = 'COLLAPSE'
                    mod.ratio = second_ratio
                    mod.use_collapse_triangulate = True
                    bpy.ops.object.modifier_apply(modifier="Decimate2")
                    obj.select_set(False)
            final_tris = count_tris()
            print(f"  After second pass: {final_tris} tris")

    # Ensure output directory exists
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Export GLB
    print(f"  Exporting: {output_path}")
    bpy.ops.export_scene.gltf(
        filepath=str(output_path),
        export_format='GLB',
        export_apply=True,
        export_image_format='AUTO',
        export_texcoords=True,
        export_normals=True,
        export_materials='EXPORT',
    )

    file_size = output_path.stat().st_size
    final_tris = count_tris()
    print(f"  Done: {final_tris} tris, {file_size / 1024:.0f} KB")

    return {
        "initial_tris": initial_tris,
        "final_tris": final_tris,
        "file_size": file_size,
    }


def main():
    print("=" * 60)
    print("TICKET-0016: Decimate AI Assets for Hybrid Pipeline")
    print("=" * 60)

    results = {}
    start = time.time()

    for filename, config in ASSETS.items():
        input_path = INPUT_DIR / filename
        output_path = OUTPUT_BASE / config["output_dir"] / config["output_name"]

        if not input_path.exists():
            print(f"\n  SKIP: {input_path} not found")
            results[filename] = {"error": "file not found"}
            continue

        print(f"\n{'='*50}")
        print(f"Processing: {filename}")
        print(f"  Target: {config['target_tris']} tris (max: {config['budget_max']})")
        print(f"{'='*50}")

        try:
            results[filename] = decimate_asset(
                input_path, output_path,
                config["target_tris"], config["budget_max"]
            )
        except Exception as e:
            print(f"  ERROR: {e}")
            results[filename] = {"error": str(e)}

    elapsed = time.time() - start

    # Summary
    print(f"\n{'='*60}")
    print("RESULTS SUMMARY")
    print(f"{'='*60}")
    for filename, result in results.items():
        if "error" in result:
            print(f"  {filename}: FAILED — {result['error']}")
        else:
            budget = ASSETS[filename]["budget_max"]
            status = "OK" if result["final_tris"] <= budget else "OVER BUDGET"
            print(f"  {filename}: {result['initial_tris']} → {result['final_tris']} tris "
                  f"({result['file_size'] / 1024:.0f} KB) [{status}]")
    print(f"\nTotal time: {elapsed:.1f}s")


if __name__ == "__main__":
    main()
