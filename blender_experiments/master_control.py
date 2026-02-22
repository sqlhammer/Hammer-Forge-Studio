"""
Master Control Script for Blender 3D Generation Engine.
Handles geometry generation, export, logging, and self-correction.
"""

import bpy
import os
import sys
import traceback
from datetime import datetime
from pathlib import Path

# === CONFIGURATION ===
ROOT_DIR = Path(__file__).parent.resolve()
LOG_FILE = ROOT_DIR / "experiment_log.md"


def clear_scene():
    """Remove all objects, meshes, materials, etc. from the scene."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

    # Purge orphan data
    for block_type in [bpy.data.meshes, bpy.data.materials, bpy.data.textures,
                       bpy.data.images, bpy.data.curves, bpy.data.cameras,
                       bpy.data.lights]:
        for block in block_type:
            if block.users == 0:
                block_type.remove(block)


def ensure_output_dir(object_name: str) -> Path:
    """Create and return the output directory for a given object."""
    sanitized = object_name.replace(" ", "_").lower()
    output_dir = ROOT_DIR / sanitized
    output_dir.mkdir(parents=True, exist_ok=True)
    return output_dir


def export_blend(output_dir: Path, object_name: str) -> str:
    """Export scene as .blend file."""
    sanitized = object_name.replace(" ", "_").lower()
    filepath = str(output_dir / f"{sanitized}.blend")
    bpy.ops.wm.save_as_mainfile(filepath=filepath)
    return filepath


def export_obj(output_dir: Path, object_name: str) -> str:
    """Export scene as .obj file."""
    sanitized = object_name.replace(" ", "_").lower()
    filepath = str(output_dir / f"{sanitized}.obj")
    bpy.ops.wm.obj_export(filepath=filepath)
    return filepath


def export_glb(output_dir: Path, object_name: str) -> str:
    """Export scene as .glb file (bonus format for Godot compatibility)."""
    sanitized = object_name.replace(" ", "_").lower()
    filepath = str(output_dir / f"{sanitized}.glb")
    bpy.ops.export_scene.gltf(filepath=filepath, export_format='GLB')
    return filepath


def log_entry(object_name: str, prompt: str, files: list[str],
              strategy: str, challenges: str = "None"):
    """Append a log entry to experiment_log.md."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    file_list = ", ".join(f"`{f}`" for f in files)
    entry = f"""
### [{timestamp}] - Object: {object_name}
- **Original Prompt:** "{prompt}"
- **Output Files:** {file_list}
- **Technical Strategy:** {strategy}
- **Challenges/Fixes:** {challenges}

---
"""
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(entry)


def generate_and_export(object_name: str, prompt: str,
                        build_fn, strategy: str,
                        max_retries: int = 3):
    """
    Main entry point: clear scene, run build function, export, and log.

    Args:
        object_name: Name for the object and output folder.
        prompt: The original user description.
        build_fn: A callable that creates geometry in the scene.
        strategy: Description of the technical approach.
        max_retries: Number of retries on failure.
    """
    output_dir = ensure_output_dir(object_name)
    challenges = []

    for attempt in range(1, max_retries + 1):
        try:
            clear_scene()
            build_fn()

            # Export all formats
            blend_path = export_blend(output_dir, object_name)
            obj_path = export_obj(output_dir, object_name)
            glb_path = export_glb(output_dir, object_name)

            files = [blend_path, obj_path, glb_path]

            challenge_text = " | ".join(challenges) if challenges else "None"
            log_entry(object_name, prompt, files, strategy, challenge_text)

            print(f"\n=== SUCCESS: {object_name} ===")
            print(f"  Blend: {blend_path}")
            print(f"  OBJ:   {obj_path}")
            print(f"  GLB:   {glb_path}")
            return files

        except Exception as e:
            tb = traceback.format_exc()
            challenges.append(f"Attempt {attempt}: {type(e).__name__}: {e}")
            print(f"\n--- Attempt {attempt}/{max_retries} failed ---")
            print(tb)

            if attempt == max_retries:
                log_entry(object_name, prompt, [], strategy,
                          " | ".join(challenges))
                print(f"\n=== FAILED after {max_retries} attempts ===")
                raise

    return []


# === GEOMETRY BUILDERS ===
# Add builder functions below. Each should create geometry in the current scene.

def build_test_cube():
    """Simple test: create a cube with subdivision surface."""
    bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 0))
    cube = bpy.context.active_object
    cube.name = "TestCube"

    # Add subdivision surface modifier
    mod = cube.modifiers.new(name="Subdiv", type='SUBSURF')
    mod.levels = 2
    mod.render_levels = 3

    # Add a basic material
    mat = bpy.data.materials.new(name="TestMaterial")
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.8, 0.2, 0.2, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.3
    bsdf.inputs["Roughness"].default_value = 0.4
    cube.data.materials.append(mat)


# === CLI ENTRY POINT ===
if __name__ == "__main__":
    # When run directly, execute a test to verify the pipeline
    if len(sys.argv) > 1 and sys.argv[-1] == "--test":
        generate_and_export(
            object_name="test_cube",
            prompt="A simple red subdivided cube for pipeline verification.",
            build_fn=build_test_cube,
            strategy="Primitive cube with Subdivision Surface modifier (level 2) and Principled BSDF material."
        )
    else:
        print("Master Control Script loaded. Use generate_and_export() to create objects.")
        print("Run with --test flag for pipeline verification.")
