"""
Fabricator Module Machine - Blender Generation Script
======================================================
Ship-interior crafting/assembly machine for producing components from materials.
- Wide, low workbench profile (distinct from tall Recycler)
- Flat work surface with articulated press arm above
- Front-facing screen panel, output drawer on right side
- 2.0m (W) x 1.0m (D) x 1.2m (H)
- Target: 1,500-4,000 triangles
- Greybox quality with flat PBR materials (no textures)
- Reference: docs/art/asset-briefs/fabricator.md
"""

import bpy
import math
import sys
import os
from mathutils import Vector, Euler

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ROOT)
from master_control import generate_and_export

# ================================================================
# COLOR PALETTE (consistent with Recycler greybox materials)
# ================================================================
BODY_MAIN = (0.38, 0.38, 0.40, 1.0)          # Slightly blue-grey #616166
PANEL_SEAM = (0.50, 0.50, 0.52, 1.0)         # Lighter grey #808085
BASE_DARK = (0.23, 0.23, 0.23, 1.0)          # Dark grey #3A3A3A
WORK_SURFACE = (0.45, 0.44, 0.42, 1.0)       # Warm grey #736F6B
ARM_METAL = (0.30, 0.30, 0.32, 1.0)          # Dark blue-grey #4D4D52
SCREEN_IDLE = (0.0, 0.48, 0.39, 1.0)         # Teal #007A63
STATUS_IDLE = (0.58, 0.64, 0.72, 1.0)        # Grey #94A3B8
POWER_ON = (0.0, 0.83, 0.67, 1.0)            # Teal #00D4AA
DRAWER_INTERIOR = (0.16, 0.16, 0.16, 1.0)    # Dark #2A2A2A


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


def mat_emissive(name, base_color, emit_color, strength=1.0):
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
        'body':         mat_pbr("Fab_Body", BODY_MAIN, 0.4, 0.7),
        'seam':         mat_pbr("Fab_Seam", PANEL_SEAM, 0.3, 0.8),
        'base':         mat_pbr("Fab_Base", BASE_DARK, 0.2, 0.9),
        'surface':      mat_pbr("Fab_WorkSurface", WORK_SURFACE, 0.5, 0.4),
        'arm':          mat_pbr("Fab_Arm", ARM_METAL, 0.6, 0.5),
        'drawer':       mat_pbr("Fab_Drawer", DRAWER_INTERIOR, 0.1, 0.9),
        'screen':       mat_emissive("Fab_Screen",
                                     (0.0, 0.15, 0.12, 1.0),
                                     SCREEN_IDLE, 0.3),
        'status_light': mat_emissive("Fab_StatusLight",
                                     (0.2, 0.2, 0.2, 1.0),
                                     STATUS_IDLE, 0.3),
        'power_light':  mat_emissive("Fab_PowerLight",
                                     (0.0, 0.2, 0.15, 1.0),
                                     POWER_ON, 0.5),
    }


# ================================================================
# GEOMETRY HELPERS
# ================================================================
# Coordinate convention:
#   X = width (2.0m), left = -X, right = +X
#   Y = depth (1.0m), front = -Y (player faces this), back = +Y
#   Z = height (1.2m), bottom = Z=0, top = Z=1.2
#   Machine center at origin, base at Z=0

def add_box(name, loc, scale, material, bevel_width=None, bevel_segments=2,
            subdiv=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    if bevel_width and bevel_width > 0:
        bev = obj.modifiers.new("Bev", 'BEVEL')
        bev.width = bevel_width
        bev.segments = bevel_segments
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
    if rot:
        obj.rotation_euler = Euler(rot)
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(material)
    return obj


# ================================================================
# FABRICATOR COMPONENT BUILDERS
# ================================================================

def build_base(M):
    """Base platform — wider footprint, dark, heavy."""
    parts = []

    # Main base platform (wider than body for stability)
    # Width: 2.2m, depth: 1.2m, height: 0.08m
    parts.append(add_box(
        "Base_Platform", (0, 0, 0.04), (2.2, 1.2, 0.08),
        M['base'], bevel_width=0.02, bevel_segments=3, subdiv=1
    ))

    # Four feet at corners
    foot_positions = [
        (-0.95, -0.50),
        (0.95, -0.50),
        (-0.95, 0.50),
        (0.95, 0.50),
    ]
    for i, (fx, fy) in enumerate(foot_positions):
        parts.append(add_box(
            f"Foot_{i}", (fx, fy, 0.015), (0.12, 0.12, 0.03),
            M['base'], bevel_width=0.008
        ))

    return parts


def build_cabinet(M):
    """Main cabinet body — lower, wider than Recycler, workbench proportions."""
    parts = []

    # Cabinet body: 2.0m W x 1.0m D x 0.75m H (sits on base at Z=0.08)
    # Center at Z = 0.08 + 0.375 = 0.455
    cabinet_z = 0.08 + 0.375
    parts.append(add_box(
        "Cabinet_Main", (0, 0, cabinet_z), (2.0, 1.0, 0.75),
        M['body'], bevel_width=0.03, bevel_segments=4, subdiv=1
    ))

    # Front lower kick panel — visual break
    parts.append(add_box(
        "Cabinet_KickPanel", (0, -0.48, 0.22), (1.8, 0.06, 0.20),
        M['seam'], bevel_width=0.01, bevel_segments=2
    ))

    # Back panel detail — access plate
    parts.append(add_box(
        "Cabinet_BackPanel", (0, 0.48, 0.40), (1.0, 0.06, 0.50),
        M['seam'], bevel_width=0.015, bevel_segments=2
    ))

    return parts


def build_work_surface(M):
    """Flat work surface on top of cabinet — the defining feature."""
    parts = []

    # Work surface sits on top of cabinet (Z = 0.83)
    surface_z = 0.83

    # Main work surface slab: slightly overhangs cabinet
    parts.append(add_box(
        "WorkSurface", (0, 0, surface_z), (2.1, 1.05, 0.04),
        M['surface'], bevel_width=0.01, bevel_segments=3
    ))

    # Work surface edge trim (front)
    parts.append(add_box(
        "Surface_TrimFront", (0, -0.52, surface_z), (2.08, 0.02, 0.05),
        M['seam'], bevel_width=0.005
    ))

    # Work surface edge trim (sides)
    for i, x_off in enumerate([-1.04, 1.04]):
        parts.append(add_box(
            f"Surface_TrimSide_{i}", (x_off, 0, surface_z), (0.02, 1.03, 0.05),
            M['seam'], bevel_width=0.005
        ))

    # Grid lines etched into work surface (3 lines across)
    for i in range(3):
        x_off = -0.5 + i * 0.5
        parts.append(add_box(
            f"Surface_GridX_{i}", (x_off, 0, surface_z + 0.021), (0.01, 0.8, 0.002),
            M['seam']
        ))

    # Grid lines (2 lines along depth)
    for i in range(2):
        y_off = -0.2 + i * 0.4
        parts.append(add_box(
            f"Surface_GridY_{i}", (0, y_off, surface_z + 0.021), (0.9, 0.01, 0.002),
            M['seam']
        ))

    return parts


def build_press_arm(M):
    """Articulated press arm above the work surface — key distinguishing silhouette."""
    parts = []

    # Arm column (vertical post on back-right of surface)
    column_x = 0.6
    column_y = 0.35
    column_base_z = 0.85
    column_height = 0.30

    parts.append(add_box(
        "Arm_Column", (column_x, column_y, column_base_z + column_height / 2.0),
        (0.10, 0.10, column_height),
        M['arm'], bevel_width=0.015, bevel_segments=3
    ))

    # Arm horizontal beam (extends forward from column top)
    beam_z = column_base_z + column_height
    beam_length = 0.55
    parts.append(add_box(
        "Arm_Beam", (column_x, column_y - beam_length / 2.0, beam_z),
        (0.08, beam_length, 0.06),
        M['arm'], bevel_width=0.01, bevel_segments=2
    ))

    # Press head (at front end of beam — the assembly/press tool)
    head_y = column_y - beam_length + 0.05
    parts.append(add_cylinder(
        "Arm_PressHead", (column_x, head_y, beam_z - 0.04),
        0.06, 0.08, (0, 0, 0), M['arm'], verts=12
    ))

    # Press head nozzle tip
    bpy.ops.mesh.primitive_cone_add(
        radius1=0.04, radius2=0.015, depth=0.06,
        vertices=10, location=(column_x, head_y, beam_z - 0.11)
    )
    nozzle = bpy.context.active_object
    nozzle.name = "Arm_Nozzle"
    nozzle.rotation_euler = Euler((math.radians(180), 0, 0))
    bpy.ops.object.shade_smooth()
    nozzle.data.materials.append(M['arm'])
    parts.append(nozzle)

    # Arm joint collar (at column-beam junction)
    bpy.ops.mesh.primitive_torus_add(
        major_radius=0.06, minor_radius=0.015,
        major_segments=14, minor_segments=6,
        location=(column_x, column_y, beam_z)
    )
    collar = bpy.context.active_object
    collar.name = "Arm_JointCollar"
    bpy.ops.object.shade_smooth()
    collar.data.materials.append(M['seam'])
    parts.append(collar)

    return parts


def build_screen_panel(M):
    """Front-facing screen panel — lower-left of front face."""
    parts = []

    # Screen on lower-left of front face of cabinet
    screen_x = -0.55
    screen_z = 0.55
    screen_y = -0.48

    # Screen recess
    parts.append(add_box(
        "Screen_Recess", (screen_x, screen_y, screen_z), (0.38, 0.04, 0.28),
        M['base']
    ))

    # Screen surface (emissive)
    bpy.ops.mesh.primitive_plane_add(
        size=1,
        location=(screen_x, screen_y + 0.02, screen_z)
    )
    screen = bpy.context.active_object
    screen.name = "Screen_Surface"
    screen.scale = (0.34, 0.24, 1.0)
    screen.rotation_euler = Euler((math.radians(75), 0, 0))
    bpy.ops.object.shade_smooth()
    screen.data.materials.append(M['screen'])
    parts.append(screen)

    # Screen bezel
    parts.append(add_box(
        "Screen_Bezel_Top", (screen_x, screen_y, screen_z + 0.13), (0.36, 0.03, 0.02),
        M['seam']
    ))
    parts.append(add_box(
        "Screen_Bezel_Bot", (screen_x, screen_y, screen_z - 0.13), (0.36, 0.03, 0.02),
        M['seam']
    ))
    parts.append(add_box(
        "Screen_Bezel_L", (screen_x - 0.18, screen_y, screen_z), (0.02, 0.03, 0.24),
        M['seam']
    ))
    parts.append(add_box(
        "Screen_Bezel_R", (screen_x + 0.18, screen_y, screen_z), (0.02, 0.03, 0.24),
        M['seam']
    ))

    return parts


def build_status_indicators(M):
    """Status lights below the screen on front face."""
    parts = []

    indicator_z = 0.35
    indicator_y = -0.51
    indicator_x = -0.55

    # Status light
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.02, segments=10, ring_count=8,
        location=(indicator_x - 0.06, indicator_y, indicator_z)
    )
    status = bpy.context.active_object
    status.name = "Status_Light"
    bpy.ops.object.shade_smooth()
    status.data.materials.append(M['status_light'])
    parts.append(status)

    # Power indicator
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.015, segments=8, ring_count=6,
        location=(indicator_x + 0.06, indicator_y, indicator_z)
    )
    power = bpy.context.active_object
    power.name = "Power_Indicator"
    bpy.ops.object.shade_smooth()
    power.data.materials.append(M['power_light'])
    parts.append(power)

    return parts


def build_output_drawer(M):
    """Output drawer/bin on right side — where finished items collect."""
    parts = []

    # Drawer housing on right face (+X side), mid-height
    drawer_x = 0.98
    drawer_z = 0.45

    # Drawer frame (recessed rectangle)
    parts.append(add_box(
        "Drawer_Frame", (drawer_x, 0, drawer_z), (0.06, 0.50, 0.30),
        M['base'], bevel_width=0.008
    ))

    # Drawer front panel (slightly protruding)
    parts.append(add_box(
        "Drawer_Panel", (drawer_x + 0.02, 0, drawer_z), (0.03, 0.45, 0.25),
        M['seam'], bevel_width=0.01, bevel_segments=2
    ))

    # Drawer handle (horizontal bar)
    parts.append(add_cylinder(
        "Drawer_Handle", (drawer_x + 0.05, 0, drawer_z + 0.08),
        0.012, 0.20, (0, 0, math.radians(90)), M['arm'], verts=8
    ))

    return parts


def build_storage_bins(M):
    """Small storage compartments on left side — input material bins."""
    parts = []

    bin_x = -0.98
    bin_base_z = 0.25

    # Two stacked bin slots
    for i in range(2):
        z_off = bin_base_z + i * 0.22

        # Bin recess
        parts.append(add_box(
            f"Bin_Recess_{i}", (bin_x, 0, z_off), (0.06, 0.40, 0.18),
            M['drawer']
        ))

        # Bin front panel
        parts.append(add_box(
            f"Bin_Panel_{i}", (bin_x - 0.02, 0, z_off), (0.03, 0.36, 0.15),
            M['seam'], bevel_width=0.008
        ))

    return parts


def build_corner_details(M):
    """Corner reinforcements and panel seams for visual detail."""
    parts = []

    cabinet_z = 0.455

    # Four vertical corner strips on the cabinet
    corners = [
        (-0.98, -0.48, "FL"),
        (0.98, -0.48, "FR"),
        (-0.98, 0.48, "BL"),
        (0.98, 0.48, "BR"),
    ]
    for cx, cy, label in corners:
        parts.append(add_box(
            f"Corner_{label}", (cx, cy, cabinet_z), (0.04, 0.04, 0.70),
            M['seam'], bevel_width=0.008, bevel_segments=2
        ))

    # Horizontal seam across front face (divides upper/lower)
    parts.append(add_box(
        "Seam_Front_H", (0, -0.501, cabinet_z), (1.9, 0.01, 0.02),
        M['seam']
    ))

    # Two horizontal reinforcement ribs on front face
    for i, rz in enumerate([0.20, 0.65]):
        parts.append(add_box(
            f"Rib_Front_{i}", (0, -0.501, rz), (1.85, 0.01, 0.02),
            M['seam']
        ))

    # Bolt/fastener circles at front corners
    bolt_positions = [
        (-0.88, -0.51, 0.75),
        (0.88, -0.51, 0.75),
        (-0.88, -0.51, 0.15),
        (0.88, -0.51, 0.15),
    ]
    for i, (bx, by, bz) in enumerate(bolt_positions):
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.018, depth=0.015, vertices=10,
            location=(bx, by, bz)
        )
        bolt = bpy.context.active_object
        bolt.name = f"Bolt_Front_{i}"
        bolt.rotation_euler = Euler((math.radians(90), 0, 0))
        bpy.ops.object.shade_smooth()
        bolt.data.materials.append(M['base'])
        parts.append(bolt)

    return parts


def build_clamps(M):
    """Work surface clamps — small fixtures on the work surface for holding parts."""
    parts = []

    # Two clamp brackets on the work surface
    clamp_positions = [(-0.25, -0.15), (0.25, 0.15)]
    surface_z = 0.85

    for i, (cx, cy) in enumerate(clamp_positions):
        # Clamp base
        parts.append(add_box(
            f"Clamp_Base_{i}", (cx, cy, surface_z + 0.015), (0.08, 0.08, 0.03),
            M['arm'], bevel_width=0.005
        ))

        # Clamp jaw (L-shaped bracket)
        parts.append(add_box(
            f"Clamp_Jaw_{i}", (cx, cy, surface_z + 0.04), (0.06, 0.02, 0.05),
            M['arm'], bevel_width=0.003
        ))

    return parts


# ================================================================
# MAIN BUILD
# ================================================================
def build_fabricator_module():
    M = create_materials()

    build_base(M)
    build_cabinet(M)
    build_work_surface(M)
    build_press_arm(M)
    build_screen_panel(M)
    build_status_indicators(M)
    build_output_drawer(M)
    build_storage_bins(M)
    build_corner_details(M)
    build_clamps(M)


# ================================================================
# ENTRY POINT
# ================================================================
if __name__ == "__main__":
    PROMPT = (
        "Fabricator module machine — a wide, low crafting workbench for a ship interior. "
        "Flat work surface on top with articulated press arm, front-facing screen panel, "
        "output drawer on the right, storage bins on the left. "
        "2.0m wide x 1.0m deep x 1.2m tall. Greybox quality with flat PBR materials. "
        "Assembly station aesthetic, visually distinct from the taller Recycler machine."
    )
    STRATEGY = (
        "Beveled boxes for cabinet body, base, surface, and panel details. Cylinder and cone "
        "for press arm head/nozzle. Torus for arm joint collar. Flat plane for emissive screen. "
        "UV spheres for status/power lights. 9 PBR materials covering body, seams, base, "
        "work surface, arm metal, drawer interior, emissive screen, and indicator lights."
    )
    generate_and_export(
        object_name="mesh_fabricator_module",
        prompt=PROMPT,
        build_fn=build_fabricator_module,
        strategy=STRATEGY,
    )
