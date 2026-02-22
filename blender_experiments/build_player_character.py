"""
Player Character (PoC variant) - Blender Generation Script
==========================================================
Adapted from build_space_suit_character.py for PoC evaluation.
Environmental suit humanoid in T-pose for cleaner evaluation.
- Suited humanoid, researcher aesthetic (not military)
- Helmet with visor, armor plates, equipment mounts
- ~1.8m tall
- Target: 5,000-10,000 triangles
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
# COLOR PALETTE (same deep blue & gunmetal theme)
# ================================================================
DEEP_BLUE = (0.015, 0.04, 0.16, 1.0)
DEEP_BLUE_LIGHT = (0.03, 0.07, 0.24, 1.0)
GUNMETAL = (0.22, 0.24, 0.27, 1.0)
GUNMETAL_DARK = (0.11, 0.12, 0.14, 1.0)
VISOR_BLACK = (0.005, 0.01, 0.025, 1.0)
SCREEN_CYAN = (0.05, 0.85, 0.75, 1.0)
BOOT_DARK = (0.015, 0.025, 0.055, 1.0)
WHITE_ACCENT = (0.82, 0.85, 0.90, 1.0)
BACKPACK_OLIVE = (0.12, 0.14, 0.08, 1.0)


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
    bsdf.inputs["Roughness"].default_value = 0.15
    bsdf.inputs["Emission Color"].default_value = emit_color
    bsdf.inputs["Emission Strength"].default_value = strength
    return m


def create_materials():
    return {
        'suit':         mat_pbr("PC_Suit", DEEP_BLUE, 0.05, 0.88),
        'suit_flex':    mat_pbr("PC_Flex", DEEP_BLUE_LIGHT, 0.08, 0.72),
        'armor':        mat_pbr("PC_Armor", GUNMETAL, 0.93, 0.18),
        'armor_matte':  mat_pbr("PC_ArmorMatte", GUNMETAL_DARK, 0.72, 0.55),
        'helmet':       mat_pbr("PC_Helmet", (0.13, 0.15, 0.20, 1.0), 0.88, 0.22),
        'visor':        mat_pbr("PC_Visor", VISOR_BLACK, 0.97, 0.03),
        'boot':         mat_pbr("PC_Boot", BOOT_DARK, 0.28, 0.62),
        'accent':       mat_pbr("PC_Accent", WHITE_ACCENT, 0.35, 0.38),
        'backpack':     mat_pbr("PC_Backpack", BACKPACK_OLIVE, 0.20, 0.65),
        'screen':       mat_emissive("PC_Screen",
                                     (0.01, 0.03, 0.03, 1.0),
                                     SCREEN_CYAN, 6.0),
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


def segment(name, start, end, radius, material, verts=20):
    s, e = Vector(start), Vector(end)
    mid = (s + e) / 2
    length = (e - s).length
    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius, depth=length, location=mid, vertices=verts
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
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=radius, segments=segs, ring_count=segs // 2, location=center
    )
    obj = bpy.context.active_object
    obj.name = name
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(material)
    return obj


def plate(name, loc, scale, rot, material):
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
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major_r, minor_radius=minor_r, location=loc
    )
    obj = bpy.context.active_object
    obj.name = name
    if rot:
        obj.rotation_euler = Euler(rot)
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(material)
    return obj


# ================================================================
# T-POSE SKELETON - character faces -Y, Z up, arms out
# ================================================================
P = {
    'chest_top':    Vector((0, 0, 1.44)),
    'chest_bot':    Vector((0, 0, 1.02)),
    'waist':        Vector((0, 0, 0.94)),
    'pelvis':       Vector((0, 0, 0.86)),
    'neck_base':    Vector((0, 0, 1.48)),
    'neck_top':     Vector((0, 0, 1.56)),
    'head':         Vector((0, 0, 1.68)),
    # Arms in T-pose (straight out to sides)
    'l_shoulder':   Vector((-0.26, 0, 1.40)),
    'l_elbow':      Vector((-0.52, 0, 1.40)),
    'l_wrist':      Vector((-0.74, 0, 1.40)),
    'l_hand':       Vector((-0.80, 0, 1.40)),
    'r_shoulder':   Vector((0.26, 0, 1.40)),
    'r_elbow':      Vector((0.52, 0, 1.40)),
    'r_wrist':      Vector((0.74, 0, 1.40)),
    'r_hand':       Vector((0.80, 0, 1.40)),
    # Legs straight down
    'l_hip':        Vector((-0.11, 0, 0.86)),
    'l_knee':       Vector((-0.11, 0, 0.48)),
    'l_ankle':      Vector((-0.11, 0, 0.08)),
    'l_toe':        Vector((-0.11, -0.10, 0.02)),
    'r_hip':        Vector((0.11, 0, 0.86)),
    'r_knee':       Vector((0.11, 0, 0.48)),
    'r_ankle':      Vector((0.11, 0, 0.08)),
    'r_toe':        Vector((0.11, -0.10, 0.02)),
}


# ================================================================
# BODY BUILDERS
# ================================================================
def build_torso(M):
    parts = []
    parts.append(segment("Torso_Upper", P['chest_bot'], P['chest_top'], 0.17, M['suit'], 24))
    parts.append(segment("Torso_Lower", P['waist'], P['chest_bot'], 0.155, M['suit'], 24))
    parts.append(segment("Pelvis", P['pelvis'], P['waist'], 0.145, M['suit'], 24))
    # Chest plate
    parts.append(plate("ChestPlate", (0, -0.14, 1.26), (0.26, 0.035, 0.20), (0.08, 0, 0), M['armor']))
    # Back plate
    parts.append(plate("BackPlate", (0, 0.15, 1.24), (0.24, 0.032, 0.18), (-0.06, 0, 0), M['armor_matte']))
    # Shoulder caps
    for tag, xs in [("L", -1), ("R", 1)]:
        parts.append(plate(f"ShoulderCap_{tag}",
                           (xs * 0.27, 0, 1.42), (0.09, 0.11, 0.055),
                           (0, 0, xs * 0.18), M['armor']))
    # Collar ring
    parts.append(ring("CollarRing", (0, 0, 1.47), 0.115, 0.022, M['armor']))
    # Belt
    parts.append(ring("Belt", (0, 0, 0.95), 0.16, 0.018, M['armor_matte']))
    parts.append(plate("BeltBuckle", (0, -0.155, 0.95), (0.04, 0.012, 0.03), (0, 0, 0), M['accent']))
    # Neck
    parts.append(segment("Neck", P['neck_base'], P['neck_top'], 0.075, M['suit_flex'], 16))
    return parts


def build_helmet(M):
    parts = []
    hc = P['head']
    # Helmet shell
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.145, segments=32, ring_count=16, location=hc)
    shell = bpy.context.active_object
    shell.name = "Helmet_Shell"
    shell.scale = (1.0, 0.96, 1.06)
    bpy.ops.object.shade_smooth()
    shell.data.materials.append(M['helmet'])
    parts.append(shell)

    # Visor cutout
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.149, segments=32, ring_count=16, location=hc)
    visor = bpy.context.active_object
    visor.name = "Visor"
    visor.scale = (1.0, 0.96, 1.06)
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

    # Visor rim
    rim_loc = Vector(hc) + Vector((0, -0.08, -0.005))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.098, minor_radius=0.01, location=rim_loc)
    rim = bpy.context.active_object
    rim.name = "Visor_Rim"
    rim.rotation_euler = Euler((math.radians(78), 0, 0))
    rim.scale = (1.0, 0.65, 1.0)
    bpy.ops.object.shade_smooth()
    rim.data.materials.append(M['armor'])
    parts.append(rim)

    # Helmet ridge
    parts.append(plate("Helmet_Ridge", Vector(hc) + Vector((0, 0.02, 0.12)),
                        (0.03, 0.10, 0.015), (0, 0, 0), M['armor']))
    return parts


def build_arm(M, side):
    s = "l" if side == "left" else "r"
    tag = "L" if side == "left" else "R"
    parts = []
    shoulder = P[f'{s}_shoulder']
    elbow = P[f'{s}_elbow']
    wrist = P[f'{s}_wrist']
    hand = P[f'{s}_hand']

    parts.append(joint(f"Shoulder_{tag}", shoulder, 0.062, M['suit_flex']))
    parts.append(segment(f"UpperArm_{tag}", shoulder, elbow, 0.052, M['suit']))
    parts.append(joint(f"Elbow_{tag}", elbow, 0.055, M['suit_flex']))
    parts.append(segment(f"Forearm_{tag}", elbow, wrist, 0.046, M['suit']))
    parts.append(joint(f"Wrist_{tag}", wrist, 0.038, M['suit_flex']))

    # Forearm armor plate
    fa_mid = (Vector(elbow) + Vector(wrist)) / 2
    fa_dir = (Vector(wrist) - Vector(elbow)).normalized()
    fa_rot = _align_z_to(fa_dir)
    parts.append(plate(f"Forearm_Plate_{tag}", fa_mid + Vector((0, -0.015, 0)),
                        (0.038, 0.032, 0.09), fa_rot, M['armor']))

    # Hand
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.032, segments=12, ring_count=8, location=hand)
    h = bpy.context.active_object
    h.name = f"Hand_{tag}"
    h.scale = (0.55, 0.65, 1.0)
    bpy.ops.object.shade_smooth()
    h.data.materials.append(M['suit'])
    parts.append(h)

    # Glove cuff
    parts.append(ring(f"GloveCuff_{tag}", wrist, 0.042, 0.008, M['armor_matte'],
                       rot=tuple(_align_z_to(fa_dir))))
    return parts


def build_leg(M, side):
    s = "l" if side == "left" else "r"
    tag = "L" if side == "left" else "R"
    parts = []
    hip = P[f'{s}_hip']
    knee = P[f'{s}_knee']
    ankle = P[f'{s}_ankle']
    toe = P[f'{s}_toe']

    parts.append(joint(f"Hip_{tag}", hip, 0.068, M['suit_flex']))
    parts.append(segment(f"Thigh_{tag}", hip, knee, 0.072, M['suit'], 22))
    parts.append(joint(f"Knee_{tag}", knee, 0.063, M['armor_matte']))

    # Boot section
    boot_top = Vector(knee) + Vector((0, 0, -0.03))
    parts.append(segment(f"Boot_{tag}", boot_top, ankle, 0.065, M['boot'], 22))
    parts.append(ring(f"BootCuff_{tag}", boot_top, 0.072, 0.014, M['armor']))
    parts.append(joint(f"Ankle_{tag}", ankle, 0.052, M['boot']))

    # Foot
    bpy.ops.mesh.primitive_cube_add(size=1, location=toe)
    foot = bpy.context.active_object
    foot.name = f"Foot_{tag}"
    foot.scale = (0.065, 0.12, 0.038)
    bev = foot.modifiers.new("Bev", 'BEVEL')
    bev.width = 0.018
    bev.segments = 4
    bpy.ops.object.shade_smooth()
    foot.data.materials.append(M['boot'])
    parts.append(foot)

    return parts


def build_backpack(M):
    """Equipment backpack - battery/tool mount point."""
    parts = []
    # Main pack body
    parts.append(plate("Backpack_Body", (0, 0.20, 1.20), (0.18, 0.10, 0.22), (0, 0, 0), M['backpack']))
    # Mounting straps (accent)
    for x in [-0.12, 0.12]:
        parts.append(plate(f"Backpack_Strap_{x}", (x, 0.14, 1.30),
                           (0.02, 0.06, 0.15), (0, 0, 0), M['accent']))
    # Equipment light
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.015, segments=8, ring_count=6,
                                          location=(0, 0.28, 1.35))
    light = bpy.context.active_object
    light.name = "Backpack_Light"
    bpy.ops.object.shade_smooth()
    light.data.materials.append(M['screen'])
    parts.append(light)
    return parts


# ================================================================
# MAIN BUILD
# ================================================================
def build_player_character():
    M = create_materials()

    build_torso(M)
    build_helmet(M)
    build_arm(M, "left")
    build_arm(M, "right")
    build_leg(M, "left")
    build_leg(M, "right")
    build_backpack(M)


# ================================================================
# ENTRY POINT
# ================================================================
if __name__ == "__main__":
    PROMPT = (
        "Full-body humanoid in environmental research suit. T-pose. "
        "Helmet with visor, deep blue suit with gunmetal armor plates, "
        "tall boots, equipment backpack. ~1.8m tall. Stylized sci-fi aesthetic."
    )
    STRATEGY = (
        "Multi-segment character from primitives in T-pose for cleaner PoC evaluation. "
        "Cylinders for limbs, spheres for joints, beveled cubes for armor plates. "
        "BMesh visor cutout. 10 PBR materials: matte suit, shiny armor, visor, backpack, "
        "emissive equipment light. Based on build_space_suit_character.py framework."
    )
    generate_and_export(
        object_name="mesh_player_character",
        prompt=PROMPT,
        build_fn=build_player_character,
        strategy=STRATEGY,
    )
