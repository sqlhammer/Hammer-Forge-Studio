"""
Ship Exterior - Blender Generation Script
==========================================
Atmospheric vessel / mobile base.
- Utilitarian, asymmetric research vessel (Outer Wilds reference)
- Riveted plating, engine housings, cargo hatches, antenna arrays
- ~45m long, ~24m wide, ~15m tall (3× original M2 dimensions)
- Target: 8,000-15,000 triangles
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
HULL_PRIMARY = (0.32, 0.34, 0.38, 1.0)        # Main hull plating
HULL_DARK = (0.15, 0.16, 0.19, 1.0)           # Dark hull panels
HULL_ACCENT = (0.50, 0.30, 0.10, 1.0)         # Orange-rust accent
ENGINE_METAL = (0.20, 0.21, 0.24, 1.0)        # Engine housing
THRUSTER_GLOW = (0.95, 0.55, 0.10, 1.0)       # Warm thruster glow
WINDOW_CYAN = (0.10, 0.65, 0.80, 1.0)         # Cockpit window
ANTENNA_METAL = (0.55, 0.57, 0.60, 1.0)       # Bright antenna metal
LANDING_GEAR = (0.18, 0.19, 0.22, 1.0)        # Landing strut metal


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
    bsdf.inputs["Roughness"].default_value = 0.2
    bsdf.inputs["Emission Color"].default_value = emit_color
    bsdf.inputs["Emission Strength"].default_value = strength
    return m


def create_materials():
    return {
        'hull':         mat_pbr("Ship_Hull", HULL_PRIMARY, 0.80, 0.45),
        'hull_dark':    mat_pbr("Ship_Hull_Dark", HULL_DARK, 0.70, 0.55),
        'hull_accent':  mat_pbr("Ship_Accent", HULL_ACCENT, 0.15, 0.65),
        'engine':       mat_pbr("Ship_Engine", ENGINE_METAL, 0.85, 0.30),
        'thruster':     mat_emissive("Ship_Thruster", (0.15, 0.08, 0.02, 1.0),
                                     THRUSTER_GLOW, 8.0),
        'window':       mat_emissive("Ship_Window", (0.02, 0.08, 0.10, 1.0),
                                     WINDOW_CYAN, 4.0),
        'antenna':      mat_pbr("Ship_Antenna", ANTENNA_METAL, 0.90, 0.20),
        'landing':      mat_pbr("Ship_Landing", LANDING_GEAR, 0.75, 0.40),
    }


# ================================================================
# GEOMETRY HELPERS
# ================================================================
def beveled_box(name, loc, scale, rot, material, bevel=None, subdiv=1):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    obj.rotation_euler = Euler(rot)
    bw = bevel if bevel else min(scale) * 0.2
    bev = obj.modifiers.new("Bev", 'BEVEL')
    bev.width = bw
    bev.segments = 3
    if subdiv > 0:
        sub = obj.modifiers.new("Sub", 'SUBSURF')
        sub.levels = subdiv
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(material)
    return obj


def cyl(name, loc, radius, depth, rot, material, verts=20):
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
# SHIP COMPONENT BUILDERS
# ================================================================
def build_hull(M):
    """Main fuselage - elongated, slightly asymmetric."""
    parts = []

    # Central fuselage - wide, flat-ish shape
    parts.append(beveled_box(
        "Hull_Main", (0, 0, 0), (3.5, 7.0, 2.0),
        (0, 0, 0), M['hull'], bevel=0.4
    ))

    # Forward section (cockpit area) - narrower, tapered
    parts.append(beveled_box(
        "Hull_Fore", (0, -5.5, 0.2), (2.2, 3.5, 1.6),
        (0, 0, 0), M['hull'], bevel=0.35
    ))

    # Aft section - slightly wider for engine room
    parts.append(beveled_box(
        "Hull_Aft", (0, 4.0, -0.1), (3.0, 3.0, 1.8),
        (0, 0, 0), M['hull_dark'], bevel=0.3
    ))

    # Asymmetric cargo pod (starboard side)
    parts.append(beveled_box(
        "Cargo_Pod", (2.8, 1.0, -0.3), (1.2, 2.5, 1.2),
        (0, 0, 0), M['hull_dark'], bevel=0.2
    ))

    # Cargo pod strut connecting to hull
    parts.append(beveled_box(
        "Cargo_Strut", (2.0, 1.0, -0.1), (0.8, 0.4, 0.3),
        (0, 0, 0), M['engine'], bevel=0.05
    ))

    return parts


def build_cockpit(M):
    """Cockpit windshield and forward details."""
    parts = []

    # Windshield - angled flat panels
    parts.append(beveled_box(
        "Windshield_Main", (0, -6.8, 0.6), (1.2, 0.8, 0.6),
        (math.radians(25), 0, 0), M['window'], bevel=0.08
    ))

    # Side windows (port)
    parts.append(beveled_box(
        "Window_Port", (-1.5, -5.0, 0.6), (0.08, 0.5, 0.3),
        (0, 0, 0), M['window'], bevel=0.03
    ))

    # Side windows (starboard)
    parts.append(beveled_box(
        "Window_Starboard", (1.5, -5.0, 0.6), (0.08, 0.5, 0.3),
        (0, 0, 0), M['window'], bevel=0.03
    ))

    # Nose sensor array
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.35, segments=16, ring_count=10,
        location=(0, -7.8, 0.1)
    )
    nose = bpy.context.active_object
    nose.name = "Nose_Sensor"
    nose.scale = (1.0, 1.5, 0.8)
    bpy.ops.object.shade_smooth()
    nose.data.materials.append(M['engine'])
    parts.append(nose)

    return parts


def build_engines(M):
    """Main engines and thruster nozzles."""
    parts = []
    nozzle_rot = (math.radians(90), 0, 0)

    # Port main engine
    parts.append(cyl(
        "Engine_Port", (-1.8, 5.8, 0), 0.65, 1.8,
        nozzle_rot, M['engine'], 24
    ))

    # Port thruster glow
    parts.append(cyl(
        "Thruster_Port", (-1.8, 6.5, 0), 0.50, 0.3,
        nozzle_rot, M['thruster'], 24
    ))

    # Starboard main engine
    parts.append(cyl(
        "Engine_Starboard", (1.8, 5.8, 0), 0.65, 1.8,
        nozzle_rot, M['engine'], 24
    ))

    # Starboard thruster glow
    parts.append(cyl(
        "Thruster_Starboard", (1.8, 6.5, 0), 0.50, 0.3,
        nozzle_rot, M['thruster'], 24
    ))

    # Engine housing fairings
    for x_sign, tag in [(-1, "Port"), (1, "Starboard")]:
        parts.append(beveled_box(
            f"Engine_Fairing_{tag}", (x_sign * 1.8, 4.8, 0),
            (0.9, 1.5, 0.9), (0, 0, 0), M['hull_dark'], bevel=0.15
        ))

    # Maneuvering thrusters (4 small ones)
    for x, y, tag in [(-2.5, -2, "FL"), (2.5, -2, "FR"),
                       (-2.5, 3, "RL"), (2.5, 3, "RR")]:
        parts.append(cyl(
            f"Thruster_Maneuver_{tag}", (x, y, -0.8), 0.15, 0.4,
            (0, 0, 0), M['engine'], 12
        ))

    return parts


def build_hull_details(M):
    """Panel lines, hatches, and surface details."""
    parts = []

    # Dorsal hatch (top, center)
    parts.append(beveled_box(
        "Hatch_Dorsal", (0, -1.0, 1.05), (1.0, 1.2, 0.06),
        (0, 0, 0), M['hull_accent'], bevel=0.02
    ))

    # Ventral cargo bay door
    parts.append(beveled_box(
        "Hatch_Ventral", (0, 0.5, -1.05), (1.8, 2.0, 0.06),
        (0, 0, 0), M['hull_dark'], bevel=0.03
    ))

    # Panel line strips (horizontal seams)
    for y_pos in [-3.0, 0.0, 3.0]:
        parts.append(beveled_box(
            f"Seam_{y_pos:.0f}", (0, y_pos, 1.02), (3.4, 0.04, 0.02),
            (0, 0, 0), M['hull_dark'], bevel=0.005, subdiv=0
        ))

    # Hull accent stripe (port side)
    parts.append(beveled_box(
        "Stripe_Port", (-3.45, -1.0, 0), (0.04, 4.0, 0.15),
        (0, 0, 0), M['hull_accent'], bevel=0.01, subdiv=0
    ))

    return parts


def build_antenna_array(M):
    """Communication and sensor antennas."""
    parts = []

    # Main antenna mast (dorsal)
    parts.append(cyl(
        "Antenna_Mast", (0.8, -2.0, 1.8), 0.06, 1.5,
        (0, 0, 0), M['antenna'], 8
    ))

    # Antenna dish
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.4, segments=16, ring_count=8,
        location=(0.8, -2.0, 2.6)
    )
    dish = bpy.context.active_object
    dish.name = "Antenna_Dish"
    dish.scale = (1.0, 1.0, 0.3)
    bpy.ops.object.shade_smooth()
    dish.data.materials.append(M['antenna'])
    parts.append(dish)

    # Side antenna (shorter, port side)
    parts.append(cyl(
        "Antenna_Side", (-2.0, -3.5, 1.2), 0.04, 0.8,
        (math.radians(15), 0, 0), M['antenna'], 6
    ))

    # Antenna tip balls
    for loc in [(0.8, -2.0, 2.8), (-2.0, -3.5, 1.65)]:
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.08, segments=8, ring_count=6, location=loc
        )
        tip = bpy.context.active_object
        tip.name = f"Antenna_Tip_{loc[0]:.0f}"
        bpy.ops.object.shade_smooth()
        tip.data.materials.append(M['hull_accent'])
        parts.append(tip)

    return parts


def build_landing_gear(M):
    """Three-point landing gear (deployed)."""
    parts = []

    gear_positions = [
        ("Nose", (0, -5.5, -1.2)),
        ("Port", (-2.2, 2.0, -1.2)),
        ("Starboard", (2.2, 2.0, -1.2)),
    ]

    for tag, base_pos in gear_positions:
        x, y, z = base_pos

        # Strut
        parts.append(cyl(
            f"Gear_Strut_{tag}", (x, y, z + 0.35), 0.08, 0.9,
            (0, 0, 0), M['landing'], 10
        ))

        # Foot pad
        parts.append(beveled_box(
            f"Gear_Pad_{tag}", (x, y, z - 0.15), (0.3, 0.35, 0.06),
            (0, 0, 0), M['landing'], bevel=0.02
        ))

        # Hydraulic detail cylinder
        parts.append(cyl(
            f"Gear_Hydraulic_{tag}", (x + 0.06, y, z + 0.5), 0.04, 0.5,
            (math.radians(8), 0, 0), M['engine'], 8
        ))

    return parts


# ================================================================
# MAIN BUILD
# ================================================================
def build_ship_exterior():
    M = create_materials()

    build_hull(M)
    build_cockpit(M)
    build_engines(M)
    build_hull_details(M)
    build_antenna_array(M)
    build_landing_gear(M)

    # TICKET-0081: Scale entire ship to 3× and apply transforms so the
    # exported GLB is natively 3× the original M2 dimensions.
    # This eliminates the need for any in-engine scale override.
    SCALE_FACTOR = 3.0
    for obj in bpy.data.objects:
        obj.location *= SCALE_FACTOR
        obj.scale *= SCALE_FACTOR
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)


# ================================================================
# ENTRY POINT
# ================================================================
if __name__ == "__main__":
    PROMPT = (
        "Atmospheric research vessel, mobile base. Chunky utilitarian sci-fi, Outer Wilds aesthetic. "
        "Asymmetric hull with cargo pod, dual main engines, cockpit windshield, antenna array, "
        "landing gear deployed. ~45m long (3x original). Riveted plating, orange accent stripes."
    )
    STRATEGY = (
        "Beveled box primitives for hull sections (main, fore, aft, cargo pod). "
        "Cylinders for engines and thruster nozzles. Asymmetric cargo pod on starboard. "
        "Hull detail via accent strips, panel seams, hatches. Antenna array with dish and mast. "
        "Three-point landing gear with strut + pad + hydraulic. 8 PBR materials. "
        "3x uniform scale applied post-build and baked into mesh data (TICKET-0081)."
    )
    generate_and_export(
        object_name="mesh_ship_exterior",
        prompt=PROMPT,
        build_fn=build_ship_exterior,
        strategy=STRATEGY,
    )
