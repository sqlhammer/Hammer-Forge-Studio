"""
Automation Hub Module Machine - Blender Generation Script
==========================================================
Ship-interior drone command/control station for managing mining drones.
- Console desk profile with angled main display (distinct from Recycler & Fabricator)
- Antenna array on top (key silhouette differentiator)
- Drone status LED panel on right side
- 2.2m (W) x 1.2m (D) x 1.4m (H)
- Target: 1,500-4,000 triangles
- Greybox quality with flat PBR materials (no textures)
- Reference: docs/art/asset-briefs/automation-hub.md
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
# COLOR PALETTE (consistent with Recycler/Fabricator greybox materials)
# ================================================================
BODY_MAIN = (0.33, 0.34, 0.37, 1.0)          # Cool dark grey #545760
PANEL_SEAM = (0.48, 0.48, 0.50, 1.0)         # Lighter grey #7A7A80
BASE_DARK = (0.23, 0.23, 0.23, 1.0)          # Dark grey #3A3A3A
CONSOLE_TOP = (0.28, 0.29, 0.32, 1.0)        # Dark blue-grey #474A52
ANTENNA_METAL = (0.42, 0.42, 0.44, 1.0)      # Medium grey #6B6B70
SCREEN_IDLE = (0.0, 0.48, 0.39, 1.0)         # Teal #007A63
STATUS_IDLE = (0.58, 0.64, 0.72, 1.0)        # Grey #94A3B8
POWER_ON = (0.0, 0.83, 0.67, 1.0)            # Teal #00D4AA
DRONE_AMBER = (0.85, 0.55, 0.0, 1.0)         # Amber #D98C00
VENT_INTERIOR = (0.12, 0.12, 0.12, 1.0)      # Near-black #1F1F1F


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
        'body':         mat_pbr("Hub_Body", BODY_MAIN, 0.4, 0.7),
        'seam':         mat_pbr("Hub_Seam", PANEL_SEAM, 0.3, 0.8),
        'base':         mat_pbr("Hub_Base", BASE_DARK, 0.2, 0.9),
        'console':      mat_pbr("Hub_Console", CONSOLE_TOP, 0.5, 0.6),
        'antenna':      mat_pbr("Hub_Antenna", ANTENNA_METAL, 0.6, 0.4),
        'vent':         mat_pbr("Hub_Vent", VENT_INTERIOR, 0.1, 0.9),
        'screen':       mat_emissive("Hub_Screen",
                                     (0.0, 0.15, 0.12, 1.0),
                                     SCREEN_IDLE, 0.4),
        'status_light': mat_emissive("Hub_StatusLight",
                                     (0.2, 0.2, 0.2, 1.0),
                                     STATUS_IDLE, 0.3),
        'power_light':  mat_emissive("Hub_PowerLight",
                                     (0.0, 0.2, 0.15, 1.0),
                                     POWER_ON, 0.5),
        'drone_light':  mat_emissive("Hub_DroneLight",
                                     (0.25, 0.15, 0.0, 1.0),
                                     DRONE_AMBER, 0.4),
    }


# ================================================================
# GEOMETRY HELPERS
# ================================================================
# Coordinate convention:
#   X = width (2.2m), left = -X, right = +X
#   Y = depth (1.2m), front = -Y (player faces this), back = +Y
#   Z = height (1.4m), bottom = Z=0, top = Z=1.4
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
# AUTOMATION HUB COMPONENT BUILDERS
# ================================================================

def build_base(M):
    """Base platform — stable footprint, dark, heavy."""
    parts = []

    # Main base platform (slightly wider than body)
    # Width: 2.3m, depth: 1.3m, height: 0.08m
    parts.append(add_box(
        "Base_Platform", (0, 0, 0.04), (2.3, 1.3, 0.08),
        M['base'], bevel_width=0.02, bevel_segments=3, subdiv=1
    ))

    # Four feet at corners
    foot_positions = [
        (-1.0, -0.55),
        (1.0, -0.55),
        (-1.0, 0.55),
        (1.0, 0.55),
    ]
    for i, (fx, fy) in enumerate(foot_positions):
        parts.append(add_box(
            f"Foot_{i}", (fx, fy, 0.015), (0.12, 0.12, 0.03),
            M['base'], bevel_width=0.008
        ))

    return parts


def build_console_body(M):
    """Main console body — desk-like form with angled top section."""
    parts = []

    # Lower cabinet: 2.2m W x 1.2m D x 0.7m H (sits on base at Z=0.08)
    cabinet_z = 0.08 + 0.35
    parts.append(add_box(
        "Console_Lower", (0, 0, cabinet_z), (2.2, 1.2, 0.70),
        M['body'], bevel_width=0.03, bevel_segments=4, subdiv=1
    ))

    # Upper console section — shorter, angled back slightly
    # This section houses the main screen and slopes back
    upper_z = 0.78 + 0.25
    parts.append(add_box(
        "Console_Upper", (0, 0.08, upper_z), (2.0, 1.0, 0.50),
        M['body'], bevel_width=0.025, bevel_segments=3, subdiv=1
    ))

    # Console top surface (angled panel)
    top_z = 1.03
    parts.append(add_box(
        "Console_Top", (0, 0.05, top_z + 0.01), (2.05, 1.05, 0.03),
        M['console'], bevel_width=0.01, bevel_segments=2
    ))

    # Front lower kick panel — visual break
    parts.append(add_box(
        "Console_KickPanel", (0, -0.58, 0.25), (1.9, 0.06, 0.22),
        M['seam'], bevel_width=0.01, bevel_segments=2
    ))

    return parts


def build_main_screen(M):
    """Large angled main display — the defining feature of the console."""
    parts = []

    # Screen recess on the upper front face
    screen_x = 0.0
    screen_z = 0.88
    screen_y = -0.52

    # Screen backing recess (dark)
    parts.append(add_box(
        "Screen_Recess", (screen_x, screen_y, screen_z), (1.2, 0.05, 0.40),
        M['base']
    ))

    # Main screen surface (emissive, angled slightly toward player)
    bpy.ops.mesh.primitive_plane_add(
        size=1,
        location=(screen_x, screen_y + 0.025, screen_z)
    )
    screen = bpy.context.active_object
    screen.name = "Screen_Main"
    screen.scale = (1.1, 0.36, 1.0)
    screen.rotation_euler = Euler((math.radians(80), 0, 0))
    bpy.ops.object.shade_smooth()
    screen.data.materials.append(M['screen'])
    parts.append(screen)

    # Screen bezel — top, bottom, left, right
    parts.append(add_box(
        "Screen_Bezel_Top", (screen_x, screen_y, screen_z + 0.19), (1.18, 0.035, 0.025),
        M['seam']
    ))
    parts.append(add_box(
        "Screen_Bezel_Bot", (screen_x, screen_y, screen_z - 0.19), (1.18, 0.035, 0.025),
        M['seam']
    ))
    parts.append(add_box(
        "Screen_Bezel_L", (screen_x - 0.59, screen_y, screen_z), (0.025, 0.035, 0.35),
        M['seam']
    ))
    parts.append(add_box(
        "Screen_Bezel_R", (screen_x + 0.59, screen_y, screen_z), (0.025, 0.035, 0.35),
        M['seam']
    ))

    return parts


def build_control_panel(M):
    """Recessed control panel below the main screen on the front face."""
    parts = []

    panel_z = 0.52
    panel_y = -0.58

    # Control panel recess
    parts.append(add_box(
        "ControlPanel_Recess", (0, panel_y, panel_z), (1.0, 0.04, 0.22),
        M['base']
    ))

    # Control panel surface (slightly raised from recess)
    parts.append(add_box(
        "ControlPanel_Surface", (0, panel_y + 0.015, panel_z), (0.95, 0.02, 0.18),
        M['console'], bevel_width=0.005
    ))

    # Button rows (3 rows of small raised rectangles)
    for row in range(3):
        for col in range(4):
            bx = -0.3 + col * 0.2
            bz = panel_z - 0.06 + row * 0.06
            parts.append(add_box(
                f"Button_{row}_{col}", (bx, panel_y + 0.025, bz),
                (0.08, 0.015, 0.035),
                M['seam'], bevel_width=0.003
            ))

    return parts


def build_antenna_array(M):
    """Antenna array on top — key silhouette differentiator from other machines."""
    parts = []

    top_z = 1.05

    # Antenna mount base plate
    parts.append(add_box(
        "Antenna_MountPlate", (0, 0.15, top_z + 0.02), (0.50, 0.30, 0.04),
        M['antenna'], bevel_width=0.008, bevel_segments=2
    ))

    # Main antenna mast (center, tallest)
    mast_z = top_z + 0.04
    mast_height = 0.30
    parts.append(add_cylinder(
        "Antenna_MastCenter", (0, 0.15, mast_z + mast_height / 2.0),
        0.025, mast_height, None, M['antenna'], verts=10
    ))

    # Antenna tip sphere
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.035, segments=10, ring_count=8,
        location=(0, 0.15, mast_z + mast_height + 0.02)
    )
    tip = bpy.context.active_object
    tip.name = "Antenna_Tip"
    bpy.ops.object.shade_smooth()
    tip.data.materials.append(M['power_light'])
    parts.append(tip)

    # Two shorter side antennas (angled outward)
    for i, (x_off, angle) in enumerate([(-0.15, -15), (0.15, 15)]):
        rod_height = 0.20
        rod_z = mast_z + rod_height / 2.0
        parts.append(add_cylinder(
            f"Antenna_Side_{i}",
            (x_off, 0.15, rod_z),
            0.015, rod_height,
            (0, math.radians(angle), 0),
            M['antenna'], verts=8
        ))

        # Side antenna cross-bar (horizontal element)
        parts.append(add_box(
            f"Antenna_CrossBar_{i}",
            (x_off, 0.15, mast_z + rod_height - 0.02),
            (0.12, 0.015, 0.015),
            M['antenna'], bevel_width=0.003
        ))

    # Horizontal dish/reflector bar between side antennas
    parts.append(add_box(
        "Antenna_Reflector", (0, 0.15, mast_z + 0.22), (0.40, 0.04, 0.02),
        M['antenna'], bevel_width=0.005, bevel_segments=2
    ))

    return parts


def build_drone_status_panel(M):
    """Drone status LED panel on the right side — shows fleet status."""
    parts = []

    panel_x = 1.08
    panel_z = 0.65

    # Panel housing (recessed dark rectangle)
    parts.append(add_box(
        "DronePanel_Housing", (panel_x, 0, panel_z), (0.06, 0.50, 0.40),
        M['base'], bevel_width=0.008
    ))

    # Panel face plate
    parts.append(add_box(
        "DronePanel_Face", (panel_x + 0.02, 0, panel_z), (0.03, 0.44, 0.34),
        M['seam'], bevel_width=0.005
    ))

    # Drone status LEDs — 4 stacked indicator lights (amber emissive)
    for i in range(4):
        led_z = panel_z - 0.12 + i * 0.08
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.018, segments=8, ring_count=6,
            location=(panel_x + 0.04, 0, led_z)
        )
        led = bpy.context.active_object
        led.name = f"DroneLED_{i}"
        bpy.ops.object.shade_smooth()
        led.data.materials.append(M['drone_light'])
        parts.append(led)

    # Label strips next to each LED
    for i in range(4):
        led_z = panel_z - 0.12 + i * 0.08
        parts.append(add_box(
            f"DroneLabel_{i}", (panel_x + 0.04, -0.06, led_z),
            (0.01, 0.08, 0.02),
            M['seam']
        ))

    return parts


def build_status_indicators(M):
    """Power and status lights on front face below control panel."""
    parts = []

    indicator_z = 0.30
    indicator_y = -0.61

    # Status light (left)
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.02, segments=10, ring_count=8,
        location=(-0.15, indicator_y, indicator_z)
    )
    status = bpy.context.active_object
    status.name = "Status_Light"
    bpy.ops.object.shade_smooth()
    status.data.materials.append(M['status_light'])
    parts.append(status)

    # Power indicator (right)
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.015, segments=8, ring_count=6,
        location=(0.15, indicator_y, indicator_z)
    )
    power = bpy.context.active_object
    power.name = "Power_Indicator"
    bpy.ops.object.shade_smooth()
    power.data.materials.append(M['power_light'])
    parts.append(power)

    return parts


def build_side_vents(M):
    """Ventilation grille on the left side and back for heat dissipation."""
    parts = []

    # Left side vent housing
    vent_x = -1.08
    vent_z = 0.55

    parts.append(add_box(
        "Vent_Housing_L", (vent_x, 0, vent_z), (0.06, 0.40, 0.30),
        M['base'], bevel_width=0.005
    ))

    # Vent slats (horizontal bars across the opening)
    for i in range(5):
        slat_z = vent_z - 0.10 + i * 0.05
        parts.append(add_box(
            f"Vent_Slat_L_{i}", (vent_x - 0.02, 0, slat_z),
            (0.02, 0.35, 0.015),
            M['seam']
        ))

    # Back vent housing
    vent_y = 0.58
    parts.append(add_box(
        "Vent_Housing_Back", (0, vent_y, 0.50), (0.80, 0.06, 0.25),
        M['base'], bevel_width=0.005
    ))

    # Back vent slats
    for i in range(4):
        slat_z = 0.42 + i * 0.05
        parts.append(add_box(
            f"Vent_Slat_Back_{i}", (0, vent_y + 0.02, slat_z),
            (0.72, 0.02, 0.015),
            M['seam']
        ))

    return parts


def build_corner_details(M):
    """Corner reinforcements and panel seams for visual detail."""
    parts = []

    # Lower cabinet corners — vertical strips
    lower_z = 0.43
    corners = [
        (-1.08, -0.58, "FL"),
        (1.08, -0.58, "FR"),
        (-1.08, 0.58, "BL"),
        (1.08, 0.58, "BR"),
    ]
    for cx, cy, label in corners:
        parts.append(add_box(
            f"Corner_{label}", (cx, cy, lower_z), (0.04, 0.04, 0.70),
            M['seam'], bevel_width=0.008, bevel_segments=2
        ))

    # Horizontal seam across front face (divides lower/upper)
    parts.append(add_box(
        "Seam_Front_H", (0, -0.601, 0.78), (2.0, 0.01, 0.025),
        M['seam']
    ))

    # Front reinforcement ribs
    for i, rz in enumerate([0.18, 0.43]):
        parts.append(add_box(
            f"Rib_Front_{i}", (0, -0.601, rz), (1.95, 0.01, 0.02),
            M['seam']
        ))

    # Bolt/fastener circles at front corners
    bolt_positions = [
        (-0.95, -0.61, 0.70),
        (0.95, -0.61, 0.70),
        (-0.95, -0.61, 0.15),
        (0.95, -0.61, 0.15),
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


def build_cable_conduits(M):
    """Cable conduits running along the back — connecting antenna to body."""
    parts = []

    # Two conduit tubes running from antenna mount down the back
    for i, x_off in enumerate([-0.12, 0.12]):
        parts.append(add_cylinder(
            f"Conduit_{i}",
            (x_off, 0.55, 0.90),
            0.02, 0.30,
            (math.radians(10), 0, 0),
            M['antenna'], verts=8
        ))

    # Conduit clamps
    for i, x_off in enumerate([-0.12, 0.12]):
        for j, z_off in enumerate([0.82, 0.98]):
            bpy.ops.mesh.primitive_torus_add(
                major_radius=0.03, minor_radius=0.008,
                major_segments=10, minor_segments=6,
                location=(x_off, 0.55, z_off)
            )
            clamp = bpy.context.active_object
            clamp.name = f"Conduit_Clamp_{i}_{j}"
            bpy.ops.object.shade_smooth()
            clamp.data.materials.append(M['seam'])
            parts.append(clamp)

    return parts


# ================================================================
# MAIN BUILD
# ================================================================
def build_automation_hub_module():
    M = create_materials()

    build_base(M)
    build_console_body(M)
    build_main_screen(M)
    build_control_panel(M)
    build_antenna_array(M)
    build_drone_status_panel(M)
    build_status_indicators(M)
    build_side_vents(M)
    build_corner_details(M)
    build_cable_conduits(M)


# ================================================================
# ENTRY POINT
# ================================================================
if __name__ == "__main__":
    PROMPT = (
        "Automation Hub module machine — a console desk drone command station for a ship "
        "interior. Large angled main display screen on front, recessed control panel with "
        "button array, antenna array on top (key silhouette), drone status LED panel on "
        "right side, ventilation grilles on left and back. "
        "2.2m wide x 1.2m deep x 1.4m tall. Greybox quality with flat PBR materials. "
        "Command console aesthetic, visually distinct from both the Recycler and Fabricator."
    )
    STRATEGY = (
        "Beveled boxes for console body, base, and panel details. Cylinders for antenna "
        "masts and cable conduits. Torus for conduit clamps. Flat plane for emissive screen. "
        "UV spheres for status/power/drone lights. Cone not used — antennas use cylinders "
        "with cross-bars. 10 PBR materials covering body, seams, base, console surface, "
        "antenna metal, vent interior, emissive screen, status/power lights, and drone amber."
    )
    generate_and_export(
        object_name="mesh_automation_hub_module",
        prompt=PROMPT,
        build_fn=build_automation_hub_module,
        strategy=STRATEGY,
    )
