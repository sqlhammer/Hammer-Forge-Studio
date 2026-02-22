"""
Hand Drill - Blender Generation Script
=======================================
Stylized sci-fi handheld extraction tool.
- Chunky, oversized proportions (Outer Wilds / Hades aesthetic)
- Worn metal housing, rubber grip, glowing charge indicator
- ~30cm long, ~15cm wide, ~20cm tall
- Target: 2,000-5,000 triangles
"""

import bpy
import bmesh
import math
import sys
import os
from mathutils import Vector, Euler

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ROOT)
from master_control import generate_and_export

# ================================================================
# COLOR PALETTE
# ================================================================
HOUSING_METAL = (0.28, 0.30, 0.33, 1.0)       # Worn brushed metal
HOUSING_DARK = (0.12, 0.13, 0.15, 1.0)         # Dark metal accents
GRIP_RUBBER = (0.06, 0.06, 0.07, 1.0)          # Black rubber grip
GRIP_ACCENT = (0.55, 0.35, 0.08, 1.0)          # Orange-brown accent
ENERGY_GLOW = (0.15, 0.75, 0.95, 1.0)          # Cyan energy conduit
EXHAUST_DARK = (0.05, 0.05, 0.06, 1.0)         # Dark exhaust/barrel
BIT_METAL = (0.45, 0.47, 0.50, 1.0)            # Bright drill bit metal
INDICATOR_GREEN = (0.1, 0.85, 0.3, 1.0)        # Charge indicator


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


def mat_emissive(name, base_color, emit_color, strength=5.0):
    m = bpy.data.materials.new(name)
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = base_color
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = 0.3
    bsdf.inputs["Emission Color"].default_value = emit_color
    bsdf.inputs["Emission Strength"].default_value = strength
    return m


def create_materials():
    return {
        'housing':      mat_pbr("Drill_Housing", HOUSING_METAL, 0.85, 0.35),
        'housing_dark': mat_pbr("Drill_Housing_Dark", HOUSING_DARK, 0.75, 0.45),
        'grip':         mat_pbr("Drill_Grip", GRIP_RUBBER, 0.0, 0.92),
        'grip_accent':  mat_pbr("Drill_Grip_Accent", GRIP_ACCENT, 0.1, 0.7),
        'energy':       mat_emissive("Drill_Energy", (0.02, 0.08, 0.12, 1.0),
                                     ENERGY_GLOW, 6.0),
        'exhaust':      mat_pbr("Drill_Exhaust", EXHAUST_DARK, 0.6, 0.55),
        'bit':          mat_pbr("Drill_Bit", BIT_METAL, 0.92, 0.15),
        'indicator':    mat_emissive("Drill_Indicator", (0.02, 0.1, 0.04, 1.0),
                                     INDICATOR_GREEN, 4.0),
    }


# ================================================================
# GEOMETRY HELPERS
# ================================================================
def _align_z_to(direction):
    d = direction.normalized()
    z = Vector((0, 0, 1))
    if d.cross(z).length < 1e-6:
        return Euler((0, 0, 0)) if d.z > 0 else Euler((math.pi, 0, 0))
    return z.rotation_difference(d).to_euler()


def add_beveled_cube(name, loc, scale, rot, material, bevel_width=None, subdiv=1):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    obj.rotation_euler = Euler(rot)
    bw = bevel_width if bevel_width else min(scale) * 0.25
    bev = obj.modifiers.new("Bev", 'BEVEL')
    bev.width = bw
    bev.segments = 3
    if subdiv > 0:
        sub = obj.modifiers.new("Sub", 'SUBSURF')
        sub.levels = subdiv
        sub.render_levels = subdiv + 1
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(material)
    return obj


def add_cylinder(name, loc, radius, depth, rot, material, verts=16):
    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius, depth=depth, vertices=verts, location=loc
    )
    obj = bpy.context.active_object
    obj.name = name
    obj.rotation_euler = Euler(rot)
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(material)
    return obj


# ================================================================
# DRILL BUILDERS
# ================================================================
def build_main_body(M):
    """Main housing - chunky rectangular body with rounded edges."""
    parts = []

    # Core body block - slightly tapered front to back
    parts.append(add_beveled_cube(
        "Body_Main", (0, 0, 0), (0.055, 0.10, 0.045),
        (0, 0, 0), M['housing'], bevel_width=0.008
    ))

    # Top housing ridge (visual detail)
    parts.append(add_beveled_cube(
        "Body_TopRidge", (0, 0.01, 0.038), (0.030, 0.07, 0.008),
        (0, 0, 0), M['housing_dark'], bevel_width=0.003
    ))

    # Side panel left
    parts.append(add_beveled_cube(
        "Body_PanelL", (-0.048, 0.005, 0), (0.006, 0.075, 0.032),
        (0, 0, 0), M['housing_dark'], bevel_width=0.002
    ))

    # Side panel right
    parts.append(add_beveled_cube(
        "Body_PanelR", (0.048, 0.005, 0), (0.006, 0.075, 0.032),
        (0, 0, 0), M['housing_dark'], bevel_width=0.002
    ))

    return parts


def build_barrel(M):
    """Front barrel / extraction nozzle."""
    parts = []

    # Main barrel cylinder - points forward (-Y)
    barrel_rot = (math.radians(90), 0, 0)

    parts.append(add_cylinder(
        "Barrel_Outer", (0, -0.13, 0.005), 0.028, 0.08,
        barrel_rot, M['housing'], 20
    ))

    # Inner barrel (darker, slightly smaller)
    parts.append(add_cylinder(
        "Barrel_Inner", (0, -0.15, 0.005), 0.020, 0.05,
        barrel_rot, M['exhaust'], 16
    ))

    # Barrel collar ring
    bpy.ops.mesh.primitive_torus_add(
        major_radius=0.032, minor_radius=0.006,
        location=(0, -0.095, 0.005)
    )
    collar = bpy.context.active_object
    collar.name = "Barrel_Collar"
    collar.rotation_euler = Euler(barrel_rot)
    bpy.ops.object.shade_smooth()
    collar.data.materials.append(M['housing_dark'])
    parts.append(collar)

    # Drill bit tip - cone
    bpy.ops.mesh.primitive_cone_add(
        radius1=0.016, radius2=0.003, depth=0.04,
        vertices=12, location=(0, -0.19, 0.005)
    )
    tip = bpy.context.active_object
    tip.name = "Drill_Bit_Tip"
    tip.rotation_euler = Euler(barrel_rot)
    bpy.ops.object.shade_smooth()
    tip.data.materials.append(M['bit'])
    parts.append(tip)

    # Spiral flutes on bit (simplified with torus segments)
    for i in range(3):
        angle = i * math.radians(120)
        offset_x = math.cos(angle) * 0.012
        offset_z = math.sin(angle) * 0.012 + 0.005
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.003, depth=0.035, vertices=6,
            location=(offset_x, -0.175, offset_z)
        )
        flute = bpy.context.active_object
        flute.name = f"Bit_Flute_{i}"
        flute.rotation_euler = Euler(barrel_rot)
        bpy.ops.object.shade_smooth()
        flute.data.materials.append(M['bit'])
        parts.append(flute)

    return parts


def build_grip(M):
    """Handle / grip section angled down from body."""
    parts = []

    # Main grip - angled cylinder
    grip_angle = math.radians(15)  # Slight forward angle
    grip_center = (0, 0.03, -0.065)

    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.022, depth=0.09, vertices=16,
        location=grip_center
    )
    grip = bpy.context.active_object
    grip.name = "Grip_Main"
    grip.rotation_euler = Euler((grip_angle, 0, 0))
    bpy.ops.object.shade_smooth()
    grip.data.materials.append(M['grip'])
    parts.append(grip)

    # Grip texture rings (rubber ridges)
    for i in range(5):
        z_off = -0.04 + i * 0.016
        bpy.ops.mesh.primitive_torus_add(
            major_radius=0.023, minor_radius=0.003,
            location=(0, 0.03 + math.sin(grip_angle) * z_off, -0.065 + z_off)
        )
        ridge = bpy.context.active_object
        ridge.name = f"Grip_Ridge_{i}"
        ridge.rotation_euler = Euler((grip_angle, 0, 0))
        bpy.ops.object.shade_smooth()
        ridge.data.materials.append(M['grip_accent'])
        parts.append(ridge)

    # Grip base / pommel
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.026, segments=12, ring_count=8,
        location=(0, 0.04, -0.112)
    )
    pommel = bpy.context.active_object
    pommel.name = "Grip_Pommel"
    pommel.scale = (1.0, 0.8, 0.7)
    bpy.ops.object.shade_smooth()
    pommel.data.materials.append(M['housing_dark'])
    parts.append(pommel)

    return parts


def build_energy_conduit(M):
    """Glowing energy channel running along the top of the body."""
    parts = []

    # Energy strip on top, running front to back
    parts.append(add_beveled_cube(
        "Energy_Strip", (0, -0.01, 0.046), (0.012, 0.065, 0.004),
        (0, 0, 0), M['energy'], bevel_width=0.002, subdiv=0
    ))

    # Energy node (bulge at center)
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.010, segments=12, ring_count=8,
        location=(0, 0.0, 0.048)
    )
    node = bpy.context.active_object
    node.name = "Energy_Node"
    bpy.ops.object.shade_smooth()
    node.data.materials.append(M['energy'])
    parts.append(node)

    # Charge indicator lights (3 small dots on the side)
    for i in range(3):
        y_off = -0.03 + i * 0.025
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.004, segments=8, ring_count=6,
            location=(0.052, y_off, 0.015)
        )
        light = bpy.context.active_object
        light.name = f"Indicator_{i}"
        bpy.ops.object.shade_smooth()
        light.data.materials.append(M['indicator'])
        parts.append(light)

    return parts


def build_exhaust_vents(M):
    """Rear exhaust / heat vents."""
    parts = []

    for i in range(3):
        x_off = -0.025 + i * 0.025
        bpy.ops.mesh.primitive_cube_add(
            size=1, location=(x_off, 0.095, 0.01)
        )
        vent = bpy.context.active_object
        vent.name = f"Exhaust_Vent_{i}"
        vent.scale = (0.008, 0.012, 0.025)
        bpy.ops.object.shade_smooth()
        vent.data.materials.append(M['exhaust'])
        parts.append(vent)

    return parts


# ================================================================
# MAIN BUILD
# ================================================================
def build_hand_drill():
    M = create_materials()

    build_main_body(M)
    build_barrel(M)
    build_grip(M)
    build_energy_conduit(M)
    build_exhaust_vents(M)


# ================================================================
# ENTRY POINT
# ================================================================
if __name__ == "__main__":
    PROMPT = (
        "Handheld sci-fi extraction drill. Chunky, stylized proportions (Outer Wilds aesthetic). "
        "Worn metal housing with rubber grip, glowing cyan energy conduit on top, "
        "drill bit tip at front. Charge indicator lights on side. ~30cm long."
    )
    STRATEGY = (
        "Beveled cube main body, cylinder barrel with cone drill bit tip, "
        "angled cylinder grip with torus ridges. Emissive material for energy conduit "
        "and charge indicators. 8 PBR materials covering metal, rubber, and glow zones."
    )
    generate_and_export(
        object_name="mesh_hand_drill",
        prompt=PROMPT,
        build_fn=build_hand_drill,
        strategy=STRATEGY,
    )
