"""
Recycler Module Machine - Blender Generation Script
=====================================================
Ship-interior processing machine for converting scrap metal to metal.
- Chunky, utilitarian processing unit (Outer Wilds tool station aesthetic)
- Input hopper (left), output tray (right), front-facing screen panel
- 1.8m (W) x 1.2m (D) x 1.4m (H)
- Target: 1,500-4,000 triangles
- Greybox quality with flat PBR materials (no textures)
- Reference: docs/design/wireframes/m4/recycler-machine.md
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
# COLOR PALETTE (from wireframe greybox material spec)
# ================================================================
BODY_MAIN = (0.35, 0.35, 0.35, 1.0)          # Medium grey #5A5A5A
PANEL_SEAM = (0.48, 0.48, 0.48, 1.0)         # Lighter grey #7A7A7A
BASE_DARK = (0.23, 0.23, 0.23, 1.0)          # Dark grey #3A3A3A
HOPPER_INTERIOR = (0.16, 0.16, 0.16, 1.0)    # Dark #2A2A2A
SCREEN_IDLE = (0.0, 0.48, 0.39, 1.0)         # Teal #007A63
STATUS_IDLE = (0.58, 0.64, 0.72, 1.0)        # Grey #94A3B8
POWER_ON = (0.0, 0.83, 0.67, 1.0)            # Teal #00D4AA


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
        'body':         mat_pbr("Recycler_Body", BODY_MAIN, 0.4, 0.7),
        'seam':         mat_pbr("Recycler_Seam", PANEL_SEAM, 0.3, 0.8),
        'base':         mat_pbr("Recycler_Base", BASE_DARK, 0.2, 0.9),
        'hopper':       mat_pbr("Recycler_Hopper", HOPPER_INTERIOR, 0.1, 0.9),
        'screen':       mat_emissive("Recycler_Screen",
                                     (0.0, 0.15, 0.12, 1.0),
                                     SCREEN_IDLE, 0.3),
        'status_light': mat_emissive("Recycler_StatusLight",
                                     (0.2, 0.2, 0.2, 1.0),
                                     STATUS_IDLE, 0.3),
        'power_light':  mat_emissive("Recycler_PowerLight",
                                     (0.0, 0.2, 0.15, 1.0),
                                     POWER_ON, 0.5),
    }


# ================================================================
# GEOMETRY HELPERS
# ================================================================
# Coordinate convention:
#   X = width (1.8m), left = -X, right = +X
#   Y = depth (1.2m), front = -Y (player faces this), back = +Y
#   Z = height (1.4m), bottom = Z=0, top = Z=1.4
#   Machine body center at (0, 0, 0.75) — base at Z=0, body from Z=0.1

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
# RECYCLER COMPONENT BUILDERS
# ================================================================

def build_base(M):
    """Base/feet — slightly wider footprint, dark, heavy."""
    parts = []

    # Main base platform (10cm overhang per side)
    # Width: 2.0m, depth: 1.4m, height: 0.1m
    parts.append(add_box(
        "Base_Platform", (0, 0, 0.05), (2.0, 1.4, 0.1),
        M['base'], bevel_width=0.02, bevel_segments=3, subdiv=1
    ))

    # Four feet at corners (subtle detail)
    foot_positions = [
        (-0.8, -0.55),
        (0.8, -0.55),
        (-0.8, 0.55),
        (0.8, 0.55),
    ]
    for i, (fx, fy) in enumerate(foot_positions):
        parts.append(add_box(
            f"Foot_{i}", (fx, fy, 0.02), (0.15, 0.15, 0.04),
            M['base'], bevel_width=0.01
        ))

    return parts


def build_main_body(M):
    """Main body — rounded-edge rectangular box, the primary mass."""
    parts = []

    # Core body: 1.8m W x 1.2m D x 1.2m H (sits on base at Z=0.1)
    # Center at Z = 0.1 + 0.6 = 0.7
    body_z = 0.1 + 0.6
    parts.append(add_box(
        "Body_Main", (0, 0, body_z), (1.8, 1.2, 1.2),
        M['body'], bevel_width=0.04, bevel_segments=5, subdiv=1
    ))

    # Upper body cap — slightly inset panel on top
    parts.append(add_box(
        "Body_TopCap", (0, 0, 1.28), (1.6, 1.0, 0.04),
        M['seam'], bevel_width=0.02, bevel_segments=2
    ))

    # Front lower panel — visual break on front face lower section
    parts.append(add_box(
        "Body_FrontLower", (0, -0.58, 0.35), (1.5, 0.06, 0.40),
        M['seam'], bevel_width=0.015, bevel_segments=2
    ))

    # Back panel detail — access hatch suggestion
    parts.append(add_box(
        "Body_BackPanel", (0, 0.58, 0.7), (0.8, 0.06, 0.6),
        M['seam'], bevel_width=0.02, bevel_segments=2
    ))

    # Left side upper panel (above hopper area)
    parts.append(add_box(
        "Body_LeftUpper", (-0.86, 0.3, 1.05), (0.08, 0.4, 0.3),
        M['seam'], bevel_width=0.01
    ))

    # Right side lower panel (above tray area)
    parts.append(add_box(
        "Body_RightLower", (0.86, -0.2, 0.65), (0.08, 0.5, 0.3),
        M['seam'], bevel_width=0.01
    ))

    return parts


def build_panel_seams(M):
    """Panel line seams — subtle edge geometry dividing body into visual panels."""
    parts = []

    body_z = 0.7  # Center of main body

    # Horizontal seam across front face (divides upper/lower)
    parts.append(add_box(
        "Seam_Front_H", (0, -0.601, body_z), (1.7, 0.01, 0.02),
        M['seam']
    ))

    # Vertical seam on front face (left of center)
    parts.append(add_box(
        "Seam_Front_VL", (-0.4, -0.601, body_z), (0.02, 0.01, 1.1),
        M['seam']
    ))

    # Vertical seam on front face (right of center)
    parts.append(add_box(
        "Seam_Front_VR", (0.4, -0.601, body_z), (0.02, 0.01, 1.1),
        M['seam']
    ))

    # Horizontal seam across back face
    parts.append(add_box(
        "Seam_Back_H", (0, 0.601, body_z), (1.7, 0.01, 0.02),
        M['seam']
    ))

    # Horizontal seam on left side
    parts.append(add_box(
        "Seam_Left_H", (-0.901, 0, body_z + 0.1), (0.01, 1.1, 0.02),
        M['seam']
    ))

    # Horizontal seam on right side
    parts.append(add_box(
        "Seam_Right_H", (0.901, 0, body_z - 0.1), (0.01, 1.1, 0.02),
        M['seam']
    ))

    return parts


def build_screen_panel(M):
    """Front-facing screen panel — recessed rectangle, angled ~15deg toward player."""
    parts = []

    # Screen position: upper-center of front face
    # 40cm wide x 30cm tall, center around Z=0.95 (upper body area)
    screen_z = 0.95
    screen_y = -0.58  # Slightly recessed from front face (-0.6)

    # Screen recess (darker border)
    parts.append(add_box(
        "Screen_Recess", (0, screen_y, screen_z), (0.44, 0.04, 0.34),
        M['base']
    ))

    # Screen surface (emissive)
    # Angled 15 degrees toward player (tilted forward at top)
    bpy.ops.mesh.primitive_plane_add(
        size=1,
        location=(0, screen_y + 0.02, screen_z)
    )
    screen = bpy.context.active_object
    screen.name = "Screen_Surface"
    screen.scale = (0.40, 0.30, 1.0)
    screen.rotation_euler = Euler((math.radians(75), 0, 0))
    bpy.ops.object.shade_smooth()
    screen.data.materials.append(M['screen'])
    parts.append(screen)

    # Screen bezel frame (thin raised border)
    # Top edge
    parts.append(add_box(
        "Screen_Bezel_Top", (0, screen_y, screen_z + 0.16), (0.42, 0.03, 0.02),
        M['seam']
    ))
    # Bottom edge
    parts.append(add_box(
        "Screen_Bezel_Bot", (0, screen_y, screen_z - 0.16), (0.42, 0.03, 0.02),
        M['seam']
    ))
    # Left edge
    parts.append(add_box(
        "Screen_Bezel_L", (-0.21, screen_y, screen_z), (0.02, 0.03, 0.30),
        M['seam']
    ))
    # Right edge
    parts.append(add_box(
        "Screen_Bezel_R", (0.21, screen_y, screen_z), (0.02, 0.03, 0.30),
        M['seam']
    ))

    return parts


def build_status_indicators(M):
    """Status light and power indicator — small spheres below the screen."""
    parts = []

    indicator_z = 0.72  # Below screen
    indicator_y = -0.61  # On front face

    # Status light (left, ~5cm diameter)
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.025, segments=10, ring_count=8,
        location=(-0.08, indicator_y, indicator_z)
    )
    status = bpy.context.active_object
    status.name = "Status_Light"
    bpy.ops.object.shade_smooth()
    status.data.materials.append(M['status_light'])
    parts.append(status)

    # Power indicator (right, ~3cm diameter)
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.015, segments=8, ring_count=6,
        location=(0.08, indicator_y, indicator_z)
    )
    power = bpy.context.active_object
    power.name = "Power_Indicator"
    bpy.ops.object.shade_smooth()
    power.data.materials.append(M['power_light'])
    parts.append(power)

    return parts


def build_input_hopper(M):
    """Input hopper on left side — truncated pyramid/funnel, upper half."""
    parts = []

    # Hopper is on the left face (-X side), upper portion
    # Opening ~40cm x 40cm, narrowing to ~20cm
    hopper_x = -0.85  # Slightly protruding from left face (-0.9)
    hopper_z = 0.95    # Upper body area

    # Outer hopper shell (beveled box representing the funnel housing)
    parts.append(add_box(
        "Hopper_Shell", (hopper_x - 0.08, 0, hopper_z),
        (0.22, 0.42, 0.42),
        M['body'], bevel_width=0.02, bevel_segments=3
    ))

    # Inner hopper opening (darker, recessed)
    # Cone shape for funnel feel — higher vertex count for smoother look
    bpy.ops.mesh.primitive_cone_add(
        radius1=0.18, radius2=0.10, depth=0.18,
        vertices=12, location=(hopper_x - 0.05, 0, hopper_z)
    )
    funnel = bpy.context.active_object
    funnel.name = "Hopper_Funnel"
    funnel.rotation_euler = Euler((0, math.radians(-90), 0))
    bpy.ops.object.shade_smooth()
    funnel.data.materials.append(M['hopper'])
    parts.append(funnel)

    # Hopper lip (ring around the opening)
    bpy.ops.mesh.primitive_torus_add(
        major_radius=0.19, minor_radius=0.02,
        major_segments=20, minor_segments=8,
        location=(hopper_x - 0.18, 0, hopper_z)
    )
    lip = bpy.context.active_object
    lip.name = "Hopper_Lip"
    lip.rotation_euler = Euler((0, math.radians(90), 0))
    bpy.ops.object.shade_smooth()
    lip.data.materials.append(M['seam'])
    parts.append(lip)

    # Hopper guide rails (two vertical bars flanking the opening)
    for i, y_off in enumerate([-0.17, 0.17]):
        parts.append(add_box(
            f"Hopper_Rail_{i}", (hopper_x - 0.12, y_off, hopper_z),
            (0.03, 0.03, 0.38),
            M['seam'], bevel_width=0.005, bevel_segments=2
        ))

    return parts


def build_output_tray(M):
    """Output tray on right side — shelf protruding ~15cm, lower half."""
    parts = []

    # Tray on right face (+X side), lower portion
    tray_x = 0.90 + 0.075  # Protruding from right face
    tray_z = 0.45           # Lower body area

    # Tray shelf (flat box protruding)
    # 40cm wide (along Y), 15cm deep (along X), ~5cm tall
    parts.append(add_box(
        "Tray_Shelf", (tray_x, 0, tray_z), (0.15, 0.40, 0.05),
        M['body'], bevel_width=0.008
    ))

    # Tray raised edges (3 sides — front, back, outer)
    # Front edge
    parts.append(add_box(
        "Tray_Edge_Front", (tray_x, -0.19, tray_z + 0.02),
        (0.14, 0.02, 0.04), M['seam']
    ))
    # Back edge
    parts.append(add_box(
        "Tray_Edge_Back", (tray_x, 0.19, tray_z + 0.02),
        (0.14, 0.02, 0.04), M['seam']
    ))
    # Outer edge
    parts.append(add_box(
        "Tray_Edge_Outer", (tray_x + 0.065, 0, tray_z + 0.02),
        (0.02, 0.40, 0.04), M['seam']
    ))

    return parts


def build_corner_reinforcements(M):
    """Corner reinforcement strips — structural detail on vertical edges."""
    parts = []

    # Four vertical corner strips on the body
    corners = [
        (-0.88, -0.58, "FL"),
        (0.88, -0.58, "FR"),
        (-0.88, 0.58, "BL"),
        (0.88, 0.58, "BR"),
    ]
    body_z = 0.7
    for cx, cy, label in corners:
        parts.append(add_box(
            f"Corner_{label}", (cx, cy, body_z), (0.06, 0.06, 1.15),
            M['seam'], bevel_width=0.01, bevel_segments=3
        ))

    # Two horizontal reinforcement ribs on left side (around hopper)
    for i, rz in enumerate([0.72, 1.18]):
        parts.append(add_box(
            f"Rib_Left_{i}", (-0.91, 0, rz), (0.03, 1.1, 0.04),
            M['seam'], bevel_width=0.005, bevel_segments=2
        ))

    # Two horizontal reinforcement ribs on right side (around tray)
    for i, rz in enumerate([0.35, 0.58]):
        parts.append(add_box(
            f"Rib_Right_{i}", (0.91, 0, rz), (0.03, 1.1, 0.04),
            M['seam'], bevel_width=0.005, bevel_segments=2
        ))

    # Bolt/fastener circles at each corner (front face only — visible to player)
    bolt_positions = [
        (-0.78, -0.61, 1.20),
        (0.78, -0.61, 1.20),
        (-0.78, -0.61, 0.20),
        (0.78, -0.61, 0.20),
    ]
    for i, (bx, by, bz) in enumerate(bolt_positions):
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.02, depth=0.02, vertices=10,
            location=(bx, by, bz)
        )
        bolt = bpy.context.active_object
        bolt.name = f"Bolt_Front_{i}"
        bolt.rotation_euler = Euler((math.radians(90), 0, 0))
        bpy.ops.object.shade_smooth()
        bolt.data.materials.append(M['base'])
        parts.append(bolt)

    # Processing chamber inlet pipe (cylinder on back, connects hopper to interior)
    parts.append(add_cylinder(
        "Pipe_Internal", (0, 0.55, 0.95), 0.08, 0.20,
        (math.radians(90), 0, 0), M['base'], verts=12
    ))

    # Pipe collar ring
    bpy.ops.mesh.primitive_torus_add(
        major_radius=0.10, minor_radius=0.02,
        major_segments=14, minor_segments=6,
        location=(0, 0.60, 0.95)
    )
    collar = bpy.context.active_object
    collar.name = "Pipe_Collar"
    collar.rotation_euler = Euler((math.radians(90), 0, 0))
    bpy.ops.object.shade_smooth()
    collar.data.materials.append(M['seam'])
    parts.append(collar)

    return parts


def build_exhaust_vents(M):
    """Exhaust vents on top surface."""
    parts = []

    vent_z = 1.31  # Just on top surface (body top = 1.3)

    # Vent housing (raised box on top)
    parts.append(add_box(
        "Vent_Housing", (0, 0.25, vent_z + 0.02), (0.6, 0.35, 0.06),
        M['base'], bevel_width=0.01, bevel_segments=2
    ))

    # 4 parallel vent slits inside the housing
    for i in range(4):
        x_off = -0.22 + i * 0.15
        parts.append(add_box(
            f"Vent_Slit_{i}", (x_off, 0.25, vent_z + 0.04), (0.08, 0.25, 0.02),
            M['hopper']
        ))

    # Vent grate bars across each slit
    for i in range(4):
        x_off = -0.22 + i * 0.15
        for j in range(3):
            y_off = 0.15 + j * 0.10
            parts.append(add_box(
                f"Vent_Bar_{i}_{j}", (x_off, y_off, vent_z + 0.05),
                (0.07, 0.01, 0.01), M['seam']
            ))

    return parts


# ================================================================
# MAIN BUILD
# ================================================================
def build_recycler_module():
    M = create_materials()

    build_base(M)
    build_main_body(M)
    build_panel_seams(M)
    build_corner_reinforcements(M)
    build_screen_panel(M)
    build_status_indicators(M)
    build_input_hopper(M)
    build_output_tray(M)
    build_exhaust_vents(M)


# ================================================================
# ENTRY POINT
# ================================================================
if __name__ == "__main__":
    PROMPT = (
        "Recycler module machine — a chunky, utilitarian processing unit for a ship interior. "
        "Input hopper on the left, output tray on the right, front-facing screen panel. "
        "1.8m wide x 1.2m deep x 1.4m tall. Greybox quality with flat PBR materials. "
        "Industrial, cobbled-together aesthetic (Outer Wilds tool station reference)."
    )
    STRATEGY = (
        "Beveled boxes for main body, base, and panel seams. Cone for hopper funnel, "
        "torus for hopper lip. Flat plane for emissive screen surface. UV spheres for "
        "status/power indicator lights. 7 PBR materials covering body, seams, base, "
        "hopper interior, emissive screen, and indicator lights."
    )
    generate_and_export(
        object_name="mesh_recycler_module",
        prompt=PROMPT,
        build_fn=build_recycler_module,
        strategy=STRATEGY,
    )
