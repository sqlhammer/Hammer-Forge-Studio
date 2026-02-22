"""
Space Suit Character - Blender Generation Script
=================================================
Fully suited astronaut in deep blue & gunmetal, with:
- Smooth opaque helmet visor
- Modern Pipboy-style wrist device on left wrist
- Tall boots (nearly to knees)
- Mixed shiny (armor) and matte (suit fabric) surfaces
- Posed looking at wrist device
"""

import bpy
import bmesh
import math
import sys
import os
from mathutils import Vector, Euler, Quaternion

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ROOT)
from master_control import generate_and_export

# ================================================================
# COLOR PALETTE
# ================================================================
DEEP_BLUE = (0.015, 0.04, 0.16, 1.0)
DEEP_BLUE_LIGHT = (0.03, 0.07, 0.24, 1.0)
GUNMETAL = (0.22, 0.24, 0.27, 1.0)
GUNMETAL_DARK = (0.11, 0.12, 0.14, 1.0)
VISOR_BLACK = (0.005, 0.01, 0.025, 1.0)
SCREEN_CYAN = (0.05, 0.85, 0.75, 1.0)
BOOT_DARK = (0.015, 0.025, 0.055, 1.0)
WHITE_ACCENT = (0.82, 0.85, 0.90, 1.0)

# ================================================================
# POSED SKELETON - all positions in world space
# Character faces -Y, Z up
# ================================================================
P = {
    # Torso
    'chest_top':    Vector((0, 0, 1.44)),
    'chest_bot':    Vector((0, 0, 1.02)),
    'waist':        Vector((0, 0, 0.94)),
    'pelvis':       Vector((0, 0, 0.86)),

    # Neck / Head
    'neck_base':    Vector((0, 0, 1.48)),
    'neck_top':     Vector((0, -0.01, 1.56)),
    'head':         Vector((0, -0.02, 1.68)),

    # Left arm - POSED: bent to look at wrist device
    'l_shoulder':   Vector((-0.26, 0.0, 1.40)),
    'l_bicep_mid':  Vector((-0.32, -0.12, 1.28)),
    'l_elbow':      Vector((-0.36, -0.22, 1.16)),
    'l_forearm_mid':Vector((-0.28, -0.28, 1.24)),
    'l_wrist':      Vector((-0.18, -0.33, 1.32)),
    'l_hand':       Vector((-0.15, -0.36, 1.30)),

    # Right arm - relaxed at side
    'r_shoulder':   Vector((0.26, 0.0, 1.40)),
    'r_bicep_mid':  Vector((0.30, 0.03, 1.27)),
    'r_elbow':      Vector((0.32, 0.05, 1.13)),
    'r_forearm_mid':Vector((0.31, 0.06, 1.00)),
    'r_wrist':      Vector((0.30, 0.07, 0.87)),
    'r_hand':       Vector((0.30, 0.07, 0.82)),

    # Left leg
    'l_hip':        Vector((-0.11, 0.0, 0.86)),
    'l_knee':       Vector((-0.13, -0.02, 0.50)),
    'l_ankle':      Vector((-0.13, 0.0, 0.08)),
    'l_toe':        Vector((-0.13, -0.10, 0.02)),

    # Right leg
    'r_hip':        Vector((0.11, 0.0, 0.86)),
    'r_knee':       Vector((0.13, -0.02, 0.50)),
    'r_ankle':      Vector((0.13, 0.0, 0.08)),
    'r_toe':        Vector((0.13, -0.10, 0.02)),
}


# ================================================================
# MATERIAL FACTORY
# ================================================================
def mat_pbr(name, color, metallic=0.0, roughness=0.5):
    """Create a Principled BSDF material."""
    m = bpy.data.materials.new(name)
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return m


def mat_emissive(name, base_color, emit_color, strength=5.0):
    """Create a material with emission (for device screen)."""
    m = bpy.data.materials.new(name)
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = base_color
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = 0.15
    bsdf.inputs["Emission Color"].default_value = emit_color
    bsdf.inputs["Emission Strength"].default_value = strength
    return m


def create_materials():
    """Build the full material palette."""
    return {
        'suit':         mat_pbr("Suit_DeepBlue", DEEP_BLUE, 0.05, 0.88),
        'suit_flex':    mat_pbr("Suit_Flex", DEEP_BLUE_LIGHT, 0.08, 0.72),
        'armor_shiny':  mat_pbr("Armor_Shiny", GUNMETAL, 0.93, 0.18),
        'armor_matte':  mat_pbr("Armor_Matte", GUNMETAL_DARK, 0.72, 0.55),
        'helmet':       mat_pbr("Helmet_Shell", (0.13, 0.15, 0.20, 1.0), 0.88, 0.22),
        'visor':        mat_pbr("Visor", VISOR_BLACK, 0.97, 0.03),
        'boot':         mat_pbr("Boot", BOOT_DARK, 0.28, 0.62),
        'boot_plate':   mat_pbr("Boot_Plate", GUNMETAL_DARK, 0.88, 0.28),
        'device':       mat_pbr("Device_Body", GUNMETAL_DARK, 0.92, 0.12),
        'screen':       mat_emissive("Device_Screen",
                                     (0.01, 0.03, 0.03, 1.0),
                                     SCREEN_CYAN, 8.0),
        'accent':       mat_pbr("Accent", WHITE_ACCENT, 0.35, 0.38),
        'ground':       mat_pbr("Ground", (0.025, 0.025, 0.03, 1.0), 0.0, 0.95),
    }


# ================================================================
# GEOMETRY HELPERS
# ================================================================
def _align_z_to(direction):
    """Return Euler rotation that maps local +Z to the given direction."""
    d = direction.normalized()
    z = Vector((0, 0, 1))
    if d.cross(z).length < 1e-6:
        if d.z > 0:
            return Euler((0, 0, 0))
        else:
            return Euler((math.pi, 0, 0))
    return z.rotation_difference(d).to_euler()


def segment(name, start, end, radius, material, verts=20):
    """Cylinder between two points, beveled caps, smooth shaded."""
    s, e = Vector(start), Vector(end)
    mid = (s + e) / 2
    length = (e - s).length

    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius, depth=length,
        location=mid, vertices=verts
    )
    obj = bpy.context.active_object
    obj.name = name
    obj.rotation_euler = _align_z_to(e - s)
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(material)

    bev = obj.modifiers.new("Bev", 'BEVEL')
    bev.width = radius * 0.18
    bev.segments = 3
    return obj


def joint(name, center, radius, material, segs=16):
    """Smooth sphere at a joint."""
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=radius, segments=segs, ring_count=segs // 2,
        location=center
    )
    obj = bpy.context.active_object
    obj.name = name
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(material)
    return obj


def plate(name, loc, scale, rot, material):
    """Beveled + subdivided cube for armor plates."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    obj.rotation_euler = Euler(rot)
    bev = obj.modifiers.new("Bev", 'BEVEL')
    bev.width = min(scale) * 0.28
    bev.segments = 4
    sub = obj.modifiers.new("Sub", 'SUBSURF')
    sub.levels = 1
    sub.render_levels = 2
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(material)
    return obj


def ring(name, loc, major_r, minor_r, material, rot=None):
    """Torus ring (belt, boot cuff, collar, etc.)."""
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major_r, minor_radius=minor_r,
        location=loc
    )
    obj = bpy.context.active_object
    obj.name = name
    if rot:
        obj.rotation_euler = Euler(rot)
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(material)
    return obj


# ================================================================
# BODY PART BUILDERS
# ================================================================
def build_torso(M):
    parts = []

    # Core torso (matte suit)
    parts.append(segment("Torso_Upper", P['chest_bot'], P['chest_top'], 0.17, M['suit'], 24))
    parts.append(segment("Torso_Lower", P['waist'], P['chest_bot'], 0.155, M['suit'], 24))
    parts.append(segment("Pelvis", P['pelvis'], P['waist'], 0.145, M['suit'], 24))

    # Front chest plate (shiny gunmetal)
    parts.append(plate("ChestPlate_Front",
                        (0, -0.14, 1.26), (0.26, 0.035, 0.20),
                        (0.08, 0, 0), M['armor_shiny']))

    # Back plate (matte gunmetal)
    parts.append(plate("ChestPlate_Back",
                        (0, 0.15, 1.24), (0.24, 0.032, 0.18),
                        (-0.06, 0, 0), M['armor_matte']))

    # Shoulder caps (shiny)
    for tag, xs in [("L", -1), ("R", 1)]:
        parts.append(plate(f"ShoulderCap_{tag}",
                            (xs * 0.27, 0.0, 1.42), (0.09, 0.11, 0.055),
                            (0, 0, xs * 0.18), M['armor_shiny']))

    # Collar ring
    parts.append(ring("CollarRing", (0, 0, 1.47), 0.115, 0.022, M['armor_shiny']))

    # Belt
    parts.append(ring("Belt", (0, 0, 0.95), 0.16, 0.018, M['armor_matte']))

    # Belt buckle (small accent plate)
    parts.append(plate("BeltBuckle", (0, -0.155, 0.95), (0.04, 0.012, 0.03),
                        (0, 0, 0), M['accent']))

    # Neck
    parts.append(segment("Neck", P['neck_base'], P['neck_top'], 0.075, M['suit_flex'], 16))

    return parts


def build_helmet(M):
    parts = []
    hc = P['head']

    # Tilt: looking down-left at wrist device
    head_rot = Euler((0.28, 0.0, -0.22))

    # Helmet shell
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.145, segments=32, ring_count=16, location=hc)
    shell = bpy.context.active_object
    shell.name = "Helmet_Shell"
    shell.scale = (1.0, 0.96, 1.06)
    shell.rotation_euler = head_rot
    bpy.ops.object.shade_smooth()
    shell.data.materials.append(M['helmet'])
    parts.append(shell)

    # Visor (carved from slightly larger sphere)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.149, segments=32, ring_count=16, location=hc)
    visor = bpy.context.active_object
    visor.name = "Visor"
    visor.scale = (1.0, 0.96, 1.06)
    visor.rotation_euler = head_rot

    # Edit mode: keep only front-face area
    bpy.ops.object.mode_set(mode='EDIT')
    bm = bmesh.from_edit_mesh(visor.data)
    bm.faces.ensure_lookup_table()

    to_del = [f for f in bm.faces
              if not (f.calc_center_median().y < -0.035
                      and -0.075 < f.calc_center_median().z < 0.065
                      and abs(f.calc_center_median().x) < 0.105)]
    bmesh.ops.delete(bm, geom=to_del, context='FACES')
    bmesh.update_edit_mesh(visor.data)
    bpy.ops.object.mode_set(mode='OBJECT')

    sol = visor.modifiers.new("Solidify", 'SOLIDIFY')
    sol.thickness = 0.006
    sol.offset = 1
    bpy.ops.object.shade_smooth()
    visor.data.materials.append(M['visor'])
    parts.append(visor)

    # Visor rim (torus arc around visor opening)
    rim_loc = Vector(hc) + Vector((0, -0.08, -0.005))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.098, minor_radius=0.01, location=rim_loc)
    rim = bpy.context.active_object
    rim.name = "Visor_Rim"
    # Tilt to match helmet, plus lean forward for face plane
    rim.rotation_euler = Euler((math.radians(78) + head_rot.x, head_rot.y, head_rot.z))
    rim.scale = (1.0, 0.65, 1.0)
    bpy.ops.object.shade_smooth()
    rim.data.materials.append(M['armor_shiny'])
    parts.append(rim)

    # Chin guard / jaw line
    chin_loc = Vector(hc) + Vector((0, -0.06, -0.10))
    parts.append(plate("Chin_Guard", chin_loc, (0.08, 0.04, 0.025),
                        (head_rot.x + 0.3, head_rot.y, head_rot.z), M['armor_matte']))

    # Top ridge on helmet
    ridge_loc = Vector(hc) + Vector((0, 0.02, 0.12))
    parts.append(plate("Helmet_Ridge", ridge_loc, (0.03, 0.10, 0.015),
                        (head_rot.x, head_rot.y, head_rot.z), M['armor_shiny']))

    return parts


def build_arm(M, side):
    """Build one arm with armor plates."""
    s = "l" if side == "left" else "r"
    tag = "L" if side == "left" else "R"
    parts = []

    shoulder = P[f'{s}_shoulder']
    elbow = P[f'{s}_elbow']
    wrist = P[f'{s}_wrist']
    hand = P[f'{s}_hand']

    # Shoulder joint
    parts.append(joint(f"Shoulder_{tag}", shoulder, 0.062, M['suit_flex']))

    # Upper arm
    parts.append(segment(f"UpperArm_{tag}", shoulder, elbow, 0.052, M['suit']))

    # Upper arm armor
    ua_mid = (Vector(shoulder) + Vector(elbow)) / 2
    ua_dir = (Vector(elbow) - Vector(shoulder)).normalized()
    ua_rot = _align_z_to(ua_dir)
    parts.append(plate(f"UpperArm_Plate_{tag}", ua_mid,
                        (0.045, 0.038, 0.11), ua_rot, M['armor_matte']))

    # Elbow joint
    parts.append(joint(f"Elbow_{tag}", elbow, 0.055, M['suit_flex']))

    # Elbow cap (shiny)
    parts.append(plate(f"Elbow_Cap_{tag}", elbow,
                        (0.04, 0.04, 0.035), ua_rot, M['armor_shiny']))

    # Forearm
    parts.append(segment(f"Forearm_{tag}", elbow, wrist, 0.046, M['suit']))

    # Forearm armor plate (only on the outer face)
    fa_mid = (Vector(elbow) + Vector(wrist)) / 2
    fa_dir = (Vector(wrist) - Vector(elbow)).normalized()
    fa_rot = _align_z_to(fa_dir)
    # Offset plate outward (away from body)
    x_sign = -1 if side == "left" else 1
    offset = Vector((x_sign * 0.015, -0.015, 0))
    parts.append(plate(f"Forearm_Plate_{tag}", fa_mid + offset,
                        (0.038, 0.032, 0.09), fa_rot, M['armor_shiny']))

    # Wrist joint
    parts.append(joint(f"Wrist_{tag}", wrist, 0.038, M['suit_flex']))

    # Hand (flattened sphere)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.032, segments=12, ring_count=8, location=hand)
    h = bpy.context.active_object
    h.name = f"Hand_{tag}"
    # Orient hand based on forearm direction
    hand_dir = (Vector(hand) - Vector(wrist)).normalized()
    h.rotation_euler = _align_z_to(hand_dir)
    h.scale = (1.0, 0.65, 0.55)
    bpy.ops.object.shade_smooth()
    h.data.materials.append(M['suit'])
    parts.append(h)

    # Glove cuff (ring at wrist)
    parts.append(ring(f"GloveCuff_{tag}", wrist, 0.042, 0.008, M['armor_matte'],
                       rot=tuple(_align_z_to(fa_dir))))

    return parts


def build_leg(M, side):
    """Build one leg with tall boot."""
    s = "l" if side == "left" else "r"
    tag = "L" if side == "left" else "R"
    parts = []

    hip = P[f'{s}_hip']
    knee = P[f'{s}_knee']
    ankle = P[f'{s}_ankle']
    toe = P[f'{s}_toe']

    # Hip joint
    parts.append(joint(f"Hip_{tag}", hip, 0.068, M['suit_flex']))

    # Upper leg (thigh) - suit material
    parts.append(segment(f"Thigh_{tag}", hip, knee, 0.072, M['suit'], 22))

    # Thigh armor plate (front)
    th_mid = (Vector(hip) + Vector(knee)) / 2
    th_dir = (Vector(knee) - Vector(hip)).normalized()
    th_rot = _align_z_to(th_dir)
    offset_fwd = Vector((0, -0.055, 0))
    parts.append(plate(f"Thigh_Plate_{tag}", th_mid + offset_fwd,
                        (0.048, 0.025, 0.14), th_rot, M['armor_matte']))

    # Knee joint (armored)
    parts.append(joint(f"Knee_{tag}", knee, 0.063, M['armor_matte']))

    # Knee pad (shiny)
    parts.append(plate(f"KneePad_{tag}",
                        Vector(knee) + Vector((0, -0.05, 0)),
                        (0.052, 0.028, 0.058), (0.1, 0, 0), M['armor_shiny']))

    # === TALL BOOT (from just below knee to foot) ===
    boot_top = Vector(knee) + Vector((0, 0, -0.03))

    # Boot shaft
    parts.append(segment(f"Boot_Shaft_{tag}", boot_top, ankle, 0.065, M['boot'], 22))

    # Boot cuff ring at top
    parts.append(ring(f"Boot_Cuff_{tag}", boot_top, 0.072, 0.014, M['armor_shiny']))

    # Shin guard plate (shiny gunmetal)
    shin_mid = (boot_top + Vector(ankle)) / 2
    parts.append(plate(f"Shin_Guard_{tag}",
                        shin_mid + Vector((0, -0.048, 0)),
                        (0.042, 0.022, 0.14), (0.04, 0, 0), M['boot_plate']))

    # Boot ankle joint
    parts.append(joint(f"Ankle_{tag}", ankle, 0.052, M['boot']))

    # Boot foot
    bpy.ops.mesh.primitive_cube_add(size=1, location=toe)
    foot = bpy.context.active_object
    foot.name = f"Boot_Foot_{tag}"
    foot.scale = (0.065, 0.12, 0.038)
    bev = foot.modifiers.new("Bev", 'BEVEL')
    bev.width = 0.018
    bev.segments = 4
    sub = foot.modifiers.new("Sub", 'SUBSURF')
    sub.levels = 1
    bpy.ops.object.shade_smooth()
    foot.data.materials.append(M['boot'])
    parts.append(foot)

    # Boot sole
    sole_loc = (toe.x, toe.y, toe.z - 0.022)
    bpy.ops.mesh.primitive_cube_add(size=1, location=sole_loc)
    sole = bpy.context.active_object
    sole.name = f"Boot_Sole_{tag}"
    sole.scale = (0.072, 0.13, 0.013)
    bev2 = sole.modifiers.new("Bev", 'BEVEL')
    bev2.width = 0.006
    bev2.segments = 2
    bpy.ops.object.shade_smooth()
    sole.data.materials.append(M['boot_plate'])
    parts.append(sole)

    # Accent stripe on boot shaft (ring)
    stripe_z = (boot_top.z + ankle.z) / 2 + 0.04
    stripe_loc = (ankle.x, ankle.y, stripe_z)
    parts.append(ring(f"Boot_Stripe_{tag}", stripe_loc, 0.068, 0.005, M['accent']))

    return parts


def build_wrist_device(M):
    """Modern Pipboy-like wrist device on left forearm."""
    parts = []

    wrist = Vector(P['l_wrist'])
    elbow = Vector(P['l_elbow'])
    fa_dir = (wrist - elbow).normalized()

    # Device sits on the forearm, slightly back from wrist
    dev_center = wrist - fa_dir * 0.07

    # Compute local frame for the device
    world_up = Vector((0, 0, 1))
    dev_right = fa_dir.cross(world_up).normalized()
    dev_up = dev_right.cross(fa_dir).normalized()

    # Rotation: align Z to forearm direction
    dev_rot = _align_z_to(fa_dir)

    # --- Main body ---
    bpy.ops.mesh.primitive_cube_add(size=1, location=dev_center)
    body = bpy.context.active_object
    body.name = "Device_Body"
    body.scale = (0.058, 0.068, 0.10)
    body.rotation_euler = dev_rot
    bev = body.modifiers.new("Bev", 'BEVEL')
    bev.width = 0.008
    bev.segments = 3
    bpy.ops.object.shade_smooth()
    body.data.materials.append(M['device'])
    parts.append(body)

    # --- Raised housing (top section, thicker) ---
    housing_loc = dev_center + dev_up * 0.028
    bpy.ops.mesh.primitive_cube_add(size=1, location=housing_loc)
    housing = bpy.context.active_object
    housing.name = "Device_Housing"
    housing.scale = (0.052, 0.060, 0.085)
    housing.rotation_euler = dev_rot
    bev2 = housing.modifiers.new("Bev", 'BEVEL')
    bev2.width = 0.006
    bev2.segments = 3
    bpy.ops.object.shade_smooth()
    housing.data.materials.append(M['device'])
    parts.append(housing)

    # --- Screen (emissive, on top of housing) ---
    screen_loc = dev_center + dev_up * 0.045
    bpy.ops.mesh.primitive_plane_add(size=1, location=screen_loc)
    screen = bpy.context.active_object
    screen.name = "Device_Screen"
    screen.scale = (0.038, 0.058, 1)
    screen.rotation_euler = dev_rot
    bpy.ops.object.shade_smooth()
    screen.data.materials.append(M['screen'])
    parts.append(screen)

    # --- Screen bezel ---
    bezel_loc = screen_loc + dev_up * 0.002
    bpy.ops.mesh.primitive_cube_add(size=1, location=bezel_loc)
    bezel = bpy.context.active_object
    bezel.name = "Device_Bezel"
    bezel.scale = (0.045, 0.065, 0.004)
    bezel.rotation_euler = dev_rot
    bev3 = bezel.modifiers.new("Bev", 'BEVEL')
    bev3.width = 0.002
    bev3.segments = 2
    bpy.ops.object.shade_smooth()
    bezel.data.materials.append(M['armor_shiny'])
    parts.append(bezel)

    # --- Side buttons (3 small cylinders) ---
    for i, t in enumerate([-0.025, 0.0, 0.025]):
        btn_loc = dev_center + dev_right * 0.045 + fa_dir * t + dev_up * 0.015
        bpy.ops.mesh.primitive_cylinder_add(radius=0.005, depth=0.01, location=btn_loc)
        btn = bpy.context.active_object
        btn.name = f"Device_Btn_{i}"
        btn.rotation_euler = _align_z_to(dev_right)
        bpy.ops.object.shade_smooth()
        btn.data.materials.append(M['accent'])
        parts.append(btn)

    # --- Antenna nub ---
    ant_loc = dev_center + fa_dir * 0.055 + dev_up * 0.04
    bpy.ops.mesh.primitive_cylinder_add(radius=0.004, depth=0.035, location=ant_loc)
    ant = bpy.context.active_object
    ant.name = "Device_Antenna"
    ant.rotation_euler = _align_z_to(dev_up)
    bpy.ops.object.shade_smooth()
    ant.data.materials.append(M['armor_shiny'])
    parts.append(ant)

    # Antenna tip ball
    ant_tip = ant_loc + dev_up * 0.02
    parts.append(joint("Device_Antenna_Tip", ant_tip, 0.006, M['accent']))

    # --- Forearm straps (two rings) ---
    for offset in [-0.035, 0.035]:
        strap_loc = dev_center + fa_dir * offset
        bpy.ops.mesh.primitive_torus_add(
            major_radius=0.052, minor_radius=0.007, location=strap_loc
        )
        strap = bpy.context.active_object
        strap.name = f"Device_Strap_{offset:.0f}"
        strap.rotation_euler = _align_z_to(fa_dir)
        bpy.ops.object.shade_smooth()
        strap.data.materials.append(M['armor_matte'])
        parts.append(strap)

    return parts


def build_scene_setup(M):
    """Ground, lights, camera."""
    parts = []

    # Ground
    bpy.ops.mesh.primitive_plane_add(size=8, location=(0, 0, -0.015))
    gnd = bpy.context.active_object
    gnd.name = "Ground"
    gnd.data.materials.append(M['ground'])
    parts.append(gnd)

    # --- 3-point lighting ---
    # Key light: warm, front-right, above
    bpy.ops.object.light_add(type='AREA', location=(2.0, -2.5, 3.0))
    key = bpy.context.active_object
    key.name = "Key_Light"
    key.data.energy = 250
    key.data.size = 2.0
    key.data.color = (1.0, 0.95, 0.88)
    key.rotation_euler = Euler((math.radians(55), 0, math.radians(40)))
    parts.append(key)

    # Fill light: cool blue, from left
    bpy.ops.object.light_add(type='AREA', location=(-2.5, -1.0, 2.0))
    fill = bpy.context.active_object
    fill.name = "Fill_Light"
    fill.data.energy = 100
    fill.data.size = 3.0
    fill.data.color = (0.7, 0.8, 1.0)
    fill.rotation_euler = Euler((math.radians(50), 0, math.radians(-45)))
    parts.append(fill)

    # Rim light: behind, accentuates silhouette
    bpy.ops.object.light_add(type='AREA', location=(0.5, 3.0, 2.5))
    rim = bpy.context.active_object
    rim.name = "Rim_Light"
    rim.data.energy = 180
    rim.data.size = 1.5
    rim.data.color = (0.75, 0.82, 1.0)
    rim.rotation_euler = Euler((math.radians(120), 0, math.radians(170)))
    parts.append(rim)

    # Subtle under-glow from wrist device (cyan point light)
    bpy.ops.object.light_add(type='POINT', location=P['l_wrist'])
    glow = bpy.context.active_object
    glow.name = "Device_Glow"
    glow.data.energy = 15
    glow.data.color = (0.1, 0.8, 0.7)
    glow.data.shadow_soft_size = 0.3
    parts.append(glow)

    # Camera - 3/4 view, slightly low angle for heroic feel
    bpy.ops.object.camera_add(
        location=(1.4, -2.4, 1.1),
        rotation=Euler((math.radians(78), 0, math.radians(28)))
    )
    cam = bpy.context.active_object
    cam.name = "Camera"
    cam.data.lens = 55
    bpy.context.scene.camera = cam
    parts.append(cam)

    # Render settings
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 128
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.01, 0.012, 0.018, 1.0)

    return parts


# ================================================================
# MAIN BUILD
# ================================================================
def build_space_suit_character():
    M = create_materials()

    build_torso(M)
    build_helmet(M)
    build_arm(M, "left")
    build_arm(M, "right")
    build_leg(M, "left")
    build_leg(M, "right")
    build_wrist_device(M)
    build_scene_setup(M)


# ================================================================
# ENTRY POINT
# ================================================================
if __name__ == "__main__":
    PROMPT = (
        "Human player character fully encased in a sleek space suit with a smooth opaque visor helmet. "
        "Left wrist has a modern Pipboy-like device. Tall boots nearly to knees. "
        "Deep blue and gunmetal color theme. Posed looking at wrist device. "
        "Mix of shiny armor plates and matte suit fabric."
    )
    STRATEGY = (
        "Multi-segment character from primitives (cylinders, spheres, cubes) posed at static joint positions. "
        "BMesh face-deletion for visor cutout from UV sphere. Bevel + SubSurf modifiers for smooth edges. "
        "12 PBR materials: matte deep-blue suit (roughness 0.88), shiny gunmetal armor (roughness 0.18), "
        "near-mirror visor (roughness 0.03), emissive cyan device screen. "
        "3-point area lighting with cyan point glow from wrist device. Cycles renderer @ 128 samples."
    )
    generate_and_export(
        object_name="space_suit_character",
        prompt=PROMPT,
        build_fn=build_space_suit_character,
        strategy=STRATEGY,
    )
