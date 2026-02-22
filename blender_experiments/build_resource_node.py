"""
Resource Node (Scrap Metal Deposit) - Blender Generation Script
===============================================================
Alien debris with embedded extractable metal.
- Weathered Serev architecture rubble with exposed metal veins
- Partially buried / embedded in ground
- ~2m wide, ~1.5m tall
- Target: 1,500-4,000 triangles
"""

import bpy
import bmesh
import math
import random
import sys
import os
from mathutils import Vector, Euler

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ROOT)
from master_control import generate_and_export

# Seed for reproducibility
random.seed(42)

# ================================================================
# COLOR PALETTE
# ================================================================
ROCK_BASE = (0.18, 0.16, 0.13, 1.0)           # Weathered alien stone
ROCK_DARK = (0.08, 0.07, 0.06, 1.0)           # Deep crevice shadow
DEBRIS_SYNTH = (0.22, 0.20, 0.18, 1.0)        # Cracked synthetic material
METAL_SCRAP = (0.50, 0.52, 0.55, 1.0)         # Exposed scrap metal (bright)
METAL_OXIDIZED = (0.35, 0.25, 0.15, 1.0)      # Oxidized / rusted edges
METAL_VEIN = (0.60, 0.62, 0.65, 1.0)          # Clean metal vein
GROUND_DIRT = (0.12, 0.10, 0.08, 1.0)         # Ground plane


# ================================================================
# MATERIAL FACTORY
# ================================================================
def mat_pbr(name, color, metallic=0.0, roughness=0.5):
    m = bpy.data.materials.new(name)
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return m


def create_materials():
    return {
        'rock':         mat_pbr("Node_Rock", ROCK_BASE, 0.05, 0.85),
        'rock_dark':    mat_pbr("Node_RockDark", ROCK_DARK, 0.05, 0.90),
        'debris':       mat_pbr("Node_Debris", DEBRIS_SYNTH, 0.15, 0.75),
        'metal':        mat_pbr("Node_Metal", METAL_SCRAP, 0.88, 0.25),
        'metal_oxide':  mat_pbr("Node_MetalOxide", METAL_OXIDIZED, 0.55, 0.60),
        'metal_vein':   mat_pbr("Node_MetalVein", METAL_VEIN, 0.92, 0.15),
        'ground':       mat_pbr("Node_Ground", GROUND_DIRT, 0.0, 0.95),
    }


# ================================================================
# GEOMETRY HELPERS
# ================================================================
def deformed_sphere(name, loc, radius, material, seed_offset=0,
                    segments=16, deform_strength=0.3):
    """Create an irregular rock-like shape from a UV sphere with
    vertex noise displacement."""
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=radius, segments=segments,
        ring_count=segments // 2, location=loc
    )
    obj = bpy.context.active_object
    obj.name = name

    # Deform vertices for organic rock feel
    bpy.ops.object.mode_set(mode='EDIT')
    bm = bmesh.from_edit_mesh(obj.data)
    rng = random.Random(seed_offset + 7)
    for v in bm.verts:
        # Radial displacement based on vertex position hash
        noise = rng.uniform(-deform_strength, deform_strength)
        v.co += v.normal * noise * radius
    bmesh.update_edit_mesh(obj.data)
    bpy.ops.object.mode_set(mode='OBJECT')

    bpy.ops.object.shade_smooth()
    obj.data.materials.append(material)
    return obj


def beveled_box(name, loc, scale, rot, material, bevel=None, subdiv=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    obj.rotation_euler = Euler(rot)
    bw = bevel if bevel else min(scale) * 0.2
    bev = obj.modifiers.new("Bev", 'BEVEL')
    bev.width = bw
    bev.segments = 2
    if subdiv > 0:
        sub = obj.modifiers.new("Sub", 'SUBSURF')
        sub.levels = subdiv
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(material)
    return obj


# ================================================================
# NODE COMPONENT BUILDERS
# ================================================================
def build_rock_base(M):
    """Main rock/rubble formation - the alien debris mass."""
    parts = []

    # Large central rock mass
    parts.append(deformed_sphere(
        "Rock_Main", (0, 0, 0.35), 0.7, M['rock'],
        seed_offset=1, segments=20, deform_strength=0.25
    ))
    # Flatten bottom to sit on ground
    rock = parts[-1]
    rock.scale = (1.0, 0.9, 0.75)

    # Secondary rock chunk (offset, tilted)
    parts.append(deformed_sphere(
        "Rock_Secondary", (0.55, 0.25, 0.15), 0.4, M['rock_dark'],
        seed_offset=2, segments=14, deform_strength=0.30
    ))
    parts[-1].rotation_euler = Euler((0.3, -0.2, 0.5))

    # Small rubble chunks scattered around base
    rubble_positions = [
        (-0.6, -0.3, 0.05, 0.15),
        (-0.35, 0.55, 0.08, 0.12),
        (0.7, -0.4, 0.06, 0.10),
        (0.2, -0.6, 0.04, 0.08),
        (-0.5, 0.1, 0.03, 0.09),
    ]
    for i, (x, y, z, r) in enumerate(rubble_positions):
        parts.append(deformed_sphere(
            f"Rubble_{i}", (x, y, z), r, M['debris'],
            seed_offset=10 + i, segments=10, deform_strength=0.35
        ))

    return parts


def build_debris_slabs(M):
    """Flat broken slabs of alien synthetic material."""
    parts = []

    # Large broken slab (tilted, partially buried)
    parts.append(beveled_box(
        "Slab_Large", (-0.3, -0.2, 0.25), (0.5, 0.35, 0.06),
        (0.4, 0.15, -0.3), M['debris'], bevel=0.015
    ))

    # Medium slab fragment
    parts.append(beveled_box(
        "Slab_Medium", (0.4, 0.35, 0.5), (0.3, 0.2, 0.04),
        (-0.2, 0.5, 0.1), M['debris'], bevel=0.01
    ))

    # Small fragment
    parts.append(beveled_box(
        "Slab_Small", (0.15, -0.5, 0.1), (0.15, 0.12, 0.03),
        (0.6, -0.3, 0.8), M['rock_dark'], bevel=0.008
    ))

    return parts


def build_metal_deposits(M):
    """Exposed scrap metal veins and fragments - the extractable resource."""
    parts = []

    # Primary metal vein - bright, eye-catching, embedded in main rock
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.15, -0.1, 0.55))
    vein = bpy.context.active_object
    vein.name = "Metal_Vein_Primary"
    vein.scale = (0.25, 0.08, 0.35)
    vein.rotation_euler = Euler((0.2, -0.15, 0.3))
    bev = vein.modifiers.new("Bev", 'BEVEL')
    bev.width = 0.02
    bev.segments = 2
    bpy.ops.object.shade_smooth()
    vein.data.materials.append(M['metal_vein'])
    parts.append(vein)

    # Secondary metal fragment - partially exposed
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.25, 0.2, 0.40))
    frag = bpy.context.active_object
    frag.name = "Metal_Frag_Secondary"
    frag.scale = (0.12, 0.15, 0.20)
    frag.rotation_euler = Euler((-0.3, 0.4, -0.2))
    bev2 = frag.modifiers.new("Bev", 'BEVEL')
    bev2.width = 0.015
    bev2.segments = 2
    bpy.ops.object.shade_smooth()
    frag.data.materials.append(M['metal'])
    parts.append(frag)

    # Small metal glints (scattered fragments visible in rubble)
    glint_positions = [
        (0.45, -0.15, 0.30, 0.05),
        (-0.15, -0.35, 0.18, 0.04),
        (0.30, 0.40, 0.25, 0.06),
    ]
    for i, (x, y, z, s) in enumerate(glint_positions):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, z))
        glint = bpy.context.active_object
        glint.name = f"Metal_Glint_{i}"
        glint.scale = (s, s * 0.6, s * 1.2)
        glint.rotation_euler = Euler((
            random.uniform(-0.5, 0.5),
            random.uniform(-0.5, 0.5),
            random.uniform(-0.5, 0.5)
        ))
        bev3 = glint.modifiers.new("Bev", 'BEVEL')
        bev3.width = s * 0.15
        bev3.segments = 1
        bpy.ops.object.shade_smooth()
        glint.data.materials.append(M['metal'])
        parts.append(glint)

    # Oxidized metal rim where deposit meets rock
    bpy.ops.mesh.primitive_torus_add(
        major_radius=0.22, minor_radius=0.025,
        location=(0.10, -0.05, 0.48)
    )
    oxide_rim = bpy.context.active_object
    oxide_rim.name = "Metal_OxideRim"
    oxide_rim.rotation_euler = Euler((0.3, -0.1, 0.2))
    oxide_rim.scale = (1.0, 0.6, 0.5)
    bpy.ops.object.shade_smooth()
    oxide_rim.data.materials.append(M['metal_oxide'])
    parts.append(oxide_rim)

    return parts


def build_ground_blend(M):
    """Ground plane integration - makes the node look partially buried."""
    parts = []

    # Ground disc around the base
    bpy.ops.mesh.primitive_cylinder_add(
        radius=1.2, depth=0.05, vertices=24,
        location=(0, 0, -0.02)
    )
    ground = bpy.context.active_object
    ground.name = "Ground_Base"
    bpy.ops.object.shade_smooth()
    ground.data.materials.append(M['ground'])
    parts.append(ground)

    # Dirt mounding at base (low irregular torus)
    bpy.ops.mesh.primitive_torus_add(
        major_radius=0.75, minor_radius=0.12,
        location=(0, 0, 0.02)
    )
    mound = bpy.context.active_object
    mound.name = "Dirt_Mound"
    mound.scale = (1.0, 1.0, 0.4)

    # Deform for organic feel
    bpy.ops.object.mode_set(mode='EDIT')
    bm = bmesh.from_edit_mesh(mound.data)
    rng = random.Random(99)
    for v in bm.verts:
        v.co.z += rng.uniform(-0.03, 0.05)
        v.co.x += rng.uniform(-0.04, 0.04)
        v.co.y += rng.uniform(-0.04, 0.04)
    bmesh.update_edit_mesh(mound.data)
    bpy.ops.object.mode_set(mode='OBJECT')

    bpy.ops.object.shade_smooth()
    mound.data.materials.append(M['ground'])
    parts.append(mound)

    return parts


# ================================================================
# MAIN BUILD
# ================================================================
def build_resource_node():
    M = create_materials()

    build_ground_blend(M)
    build_rock_base(M)
    build_debris_slabs(M)
    build_metal_deposits(M)


# ================================================================
# ENTRY POINT
# ================================================================
if __name__ == "__main__":
    PROMPT = (
        "Scrap metal resource deposit embedded in alien architecture rubble. "
        "Weathered rock/debris mass with bright metal veins exposed. "
        "Partially buried, ~2m wide. Oxidized edges, muted earth tones "
        "with reflective metal contrast. Stylized sci-fi."
    )
    STRATEGY = (
        "Deformed UV spheres for organic rock shapes, beveled cubes for debris slabs "
        "and metal deposits. Vertex noise displacement for natural irregularity. "
        "7 PBR materials: matte rock, synthetic debris, bright metallic veins, "
        "oxidized metal transition, ground dirt. Seeded random for reproducibility."
    )
    generate_and_export(
        object_name="mesh_resource_node_scrap",
        prompt=PROMPT,
        build_fn=build_resource_node,
        strategy=STRATEGY,
    )
