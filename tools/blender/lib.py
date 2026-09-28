"""Shared helpers for Emberquill's procedural Blender models.

Everything is built from code so the art can be regenerated, tweaked and
reviewed like any other source file. Works both with the `bpy` Python module
(`python3 build_all.py`) and inside Blender (`blender -b -P build_all.py`).

Conventions
-----------
* 1 Blender unit = 1 metre = 1 Godot unit. Characters face -Y (Blender front).
* Rigid skinning: every part is assigned 100% to one bone, then joined.
  It gives the chunky "painted toy" silhouette we want and exports cleanly.
* Bone roll: every bone's local Z axis points forward (-Y), so for vertical
  bones  +X rotation = pitch forward,  Z rotation = lean sideways.
* Material names are contracts with Godot (see scripts/fx/toon.gd):
  Cloth, ClothDark, Metal, Leather, Wax, Eyes, Quill, Nib, Ink, Paper, ...
"""

import math
import os

import bpy  # must come first: the pip `bpy` module registers bmesh/mathutils
import bmesh
from mathutils import Euler, Matrix, Vector

FPS = 30


# ---------------------------------------------------------------------------
# Scene / colour helpers
# ---------------------------------------------------------------------------

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scn = bpy.context.scene
    scn.render.fps = FPS
    scn.frame_start = 1
    return scn


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hex_color(h):
    h = h.lstrip("#")
    return tuple(srgb_to_linear(int(h[i:i + 2], 16) / 255.0) for i in (0, 2, 4))


def material(name, color_hex, rough=0.75, metal=0.0, emit_hex=None, emit_strength=0.0):
    m = bpy.data.materials.get(name)
    if m is None:
        m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    col = hex_color(color_hex)
    bsdf.inputs["Base Color"].default_value = (*col, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if emit_hex:
        bsdf.inputs["Emission Color"].default_value = (*hex_color(emit_hex), 1.0)
        bsdf.inputs["Emission Strength"].default_value = emit_strength
    m.diffuse_color = (*col, 1.0)
    return m


# ---------------------------------------------------------------------------
# Mesh building
# ---------------------------------------------------------------------------

def _mat4(loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
    return (Matrix.Translation(Vector(loc))
            @ Euler([math.radians(a) for a in rot], "XYZ").to_matrix().to_4x4()
            @ Matrix.Diagonal((*scale, 1.0)))


def _obj_from_bm(name, bm, mat=None, smooth=True):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = smooth
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    if mat is not None:
        ob.data.materials.append(mat)
    return ob


def sphere(name, r=1.0, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), segs=16, rings=10, mat=None, smooth=True):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=r, matrix=_mat4(loc, rot, scale))
    return _obj_from_bm(name, bm, mat, smooth)


def ico(name, r=1.0, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), subdiv=1, mat=None, smooth=False):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=r, matrix=_mat4(loc, rot, scale))
    return _obj_from_bm(name, bm, mat, smooth)


def cone(name, r1=1.0, r2=0.5, depth=1.0, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), segs=12, mat=None, smooth=True, caps=True):
    """Cylinder/cone along local Z, centred on loc."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=caps, cap_tris=False, segments=segs, radius1=r1, radius2=r2,
                          depth=depth, matrix=_mat4(loc, rot, scale))
    return _obj_from_bm(name, bm, mat, smooth)


def box(name, size=(1, 1, 1), loc=(0, 0, 0), rot=(0, 0, 0), mat=None, bevel=0.0, smooth=False):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0, matrix=_mat4(loc, rot, size))
    ob = _obj_from_bm(name, bm, mat, smooth)
    if bevel > 0:
        add_bevel(ob, bevel, 2)
    return ob


def torus(name, major=1.0, minor=0.2, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), seg_major=24, seg_minor=8, mat=None, smooth=True):
    bm = bmesh.new()
    verts = []
    for i in range(seg_major):
        a = 2 * math.pi * i / seg_major
        ring = []
        for j in range(seg_minor):
            b = 2 * math.pi * j / seg_minor
            x = (major + minor * math.cos(b)) * math.cos(a)
            y = (major + minor * math.cos(b)) * math.sin(a)
            z = minor * math.sin(b)
            ring.append(bm.verts.new((x, y, z)))
        verts.append(ring)
    for i in range(seg_major):
        for j in range(seg_minor):
            a = verts[i][j]
            b = verts[(i + 1) % seg_major][j]
            c = verts[(i + 1) % seg_major][(j + 1) % seg_minor]
            d = verts[i][(j + 1) % seg_minor]
            bm.faces.new((a, b, c, d))
    bmesh.ops.transform(bm, matrix=_mat4(loc, rot, scale), verts=bm.verts)
    return _obj_from_bm(name, bm, mat, smooth)


def lathe(name, profile, segs=16, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), mat=None, smooth=True, cap_top=True, cap_bottom=True):
    """Revolve a (radius, z) profile around Z. Great for candles, bottles, helmets."""
    bm = bmesh.new()
    rings = []
    for (r, z) in profile:
        ring = []
        for i in range(segs):
            a = 2 * math.pi * i / segs
            ring.append(bm.verts.new((r * math.cos(a), r * math.sin(a), z)))
        rings.append(ring)
    for k in range(len(rings) - 1):
        for i in range(segs):
            a = rings[k][i]
            b = rings[k][(i + 1) % segs]
            c = rings[k + 1][(i + 1) % segs]
            d = rings[k + 1][i]
            bm.faces.new((a, b, c, d))
    if cap_bottom and profile[0][0] > 1e-4:
        bm.faces.new(list(reversed(rings[0])))
    if cap_top and profile[-1][0] > 1e-4:
        bm.faces.new(rings[-1])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.transform(bm, matrix=_mat4(loc, rot, scale), verts=bm.verts)
    return _obj_from_bm(name, bm, mat, smooth)


def extrude_shape(name, pts2d, depth=0.05, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), mat=None, smooth=False):
    """Extrude a closed 2D polygon (x, y) along Z by `depth` (centred)."""
    bm = bmesh.new()
    bottom = [bm.verts.new((x, y, -depth / 2)) for (x, y) in pts2d]
    top = [bm.verts.new((x, y, depth / 2)) for (x, y) in pts2d]
    bm.faces.new(list(reversed(bottom)))
    bm.faces.new(top)
    n = len(pts2d)
    for i in range(n):
        bm.faces.new((bottom[i], bottom[(i + 1) % n], top[(i + 1) % n], top[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.transform(bm, matrix=_mat4(loc, rot, scale), verts=bm.verts)
    return _obj_from_bm(name, bm, mat, smooth)


def add_bevel(ob, width=0.02, segments=2):
    mod = ob.modifiers.new("Bevel", "BEVEL")
    mod.width = width
    mod.segments = segments
    mod.limit_method = "ANGLE"
    apply_modifiers(ob)


def add_subsurf(ob, levels=1):
    mod = ob.modifiers.new("Subsurf", "SUBSURF")
    mod.levels = levels
    mod.render_levels = levels
    apply_modifiers(ob)


def apply_modifiers(ob):
    view = bpy.context.view_layer
    for o in view.objects:
        o.select_set(False)
    view.objects.active = ob
    ob.select_set(True)
    for mod in list(ob.modifiers):
        if mod.type != "ARMATURE":
            bpy.ops.object.modifier_apply(modifier=mod.name)


def jitter(ob, amount=0.02, seed=1):
    """Deterministic vertex noise so shapes feel hand-made, not CAD."""
    import random
    rnd = random.Random(seed)
    cache = {}
    for v in ob.data.vertices:
        key = tuple(round(c, 4) for c in v.co)
        if key not in cache:
            cache[key] = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1))) * amount
        v.co += cache[key]


def taper_z(ob, z0, z1, s0, s1):
    """Scale XY linearly from s0 at z0 to s1 at z1 (in object space)."""
    for v in ob.data.vertices:
        t = min(1.0, max(0.0, (v.co.z - z0) / max(1e-5, (z1 - z0))))
        s = s0 + (s1 - s0) * t
        v.co.x *= s
        v.co.y *= s


def set_material(ob, mat):
    ob.data.materials.clear()
    ob.data.materials.append(mat)


# ---------------------------------------------------------------------------
# Rigging
# ---------------------------------------------------------------------------

def armature(name, bones):
    """bones: list of (name, head, tail, parent_or_None). Z axis of every bone faces -Y."""
    data = bpy.data.armatures.new(name)
    arm = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(arm)
    view = bpy.context.view_layer
    view.objects.active = arm
    arm.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for (bn, head, tail, parent) in bones:
        eb = data.edit_bones.new(bn)
        eb.head = head
        eb.tail = tail
        d = (Vector(tail) - Vector(head)).normalized()
        if abs(d.y) > 0.9:
            eb.align_roll(Vector((0, 0, 1)))
        else:
            eb.align_roll(Vector((0, -1, 0)))
        if parent:
            eb.parent = data.edit_bones[parent]
            eb.use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in arm.pose.bones:
        pb.rotation_mode = "XYZ"
    return arm


def assign_bone(ob, bone):
    vg = ob.vertex_groups.new(name=bone)
    vg.add([v.index for v in ob.data.vertices], 1.0, "REPLACE")


def join(objs, name):
    view = bpy.context.view_layer
    for o in view.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    view.objects.active = objs[0]
    bpy.ops.object.join()
    ob = view.objects.active
    ob.name = name
    ob.data.name = name
    return ob


def bind(mesh, arm):
    mesh.parent = arm
    mod = mesh.modifiers.new("Armature", "ARMATURE")
    mod.object = arm


def rigid_parts(parts, arm, name):
    """parts: list of (object, bone). Assign, join and bind to the armature."""
    objs = []
    for ob, bone in parts:
        assign_bone(ob, bone)
        objs.append(ob)
    mesh = join(objs, name)
    bind(mesh, arm)
    return mesh


# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------

def _frame(t):
    return 1 + round(t * FPS)


def animate(arm, name, keys, interp="BEZIER", cyclic=False):
    """keys: list of (time_seconds, {bone: {"rot": (x,y,z) deg, "loc": (x,y,z), "scale": (x,y,z)}}).
    Bones absent from a key return to rest. The action is stored on an NLA track so the
    glTF exporter picks every clip."""
    if arm.animation_data is None:
        arm.animation_data_create()
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    arm.animation_data.action = act
    used = set()
    for _, pose in keys:
        used.update(pose.keys())
    for t, pose in keys:
        f = _frame(t)
        for bn in used:
            pb = arm.pose.bones[bn]
            d = pose.get(bn, {})
            pb.rotation_euler = [math.radians(a) for a in d.get("rot", (0, 0, 0))]
            pb.location = d.get("loc", (0, 0, 0))
            pb.scale = d.get("scale", (1, 1, 1))
            pb.keyframe_insert("rotation_euler", frame=f)
            pb.keyframe_insert("location", frame=f)
            pb.keyframe_insert("scale", frame=f)
    _set_interpolation(act, interp)
    track = arm.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, _frame(keys[0][0]), act)
    track.mute = True
    arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.rotation_euler = (0, 0, 0)
        pb.location = (0, 0, 0)
        pb.scale = (1, 1, 1)
    return act


def _fcurves(act):
    # Blender 4.4+ layered actions keep fcurves in channel bags; older ones on the action.
    if hasattr(act, "layers") and len(act.layers) > 0:
        out = []
        for layer in act.layers:
            for strip in layer.strips:
                for bag in getattr(strip, "channelbags", []):
                    out.extend(bag.fcurves)
        if out:
            return out
    return list(getattr(act, "fcurves", []))


def _set_interpolation(act, interp):
    for fc in _fcurves(act):
        for kp in fc.keyframe_points:
            kp.interpolation = interp


# ---------------------------------------------------------------------------
# Export / preview
# ---------------------------------------------------------------------------

def export_glb(path, objects):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    view = bpy.context.view_layer
    view.update()
    for o in list(view.objects):
        if o is not None:
            o.select_set(False)
    for o in objects:
        o.select_set(True)
        for c in o.children_recursive:
            c.select_set(True)
    view.objects.active = objects[0]
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_skins=True,
        export_morph=False,
        export_materials="EXPORT",
        export_force_sampling=True,
        export_optimize_animation_size=False,
    )
    print("exported", path)


def preview(path, target=(0, 0, 0.7), dist=4.0, size=420, azimuth=-35.0, elevation=18.0):
    """Quick Cycles render for reviewing a model from code."""
    scn = bpy.context.scene
    scn.render.engine = "CYCLES"
    scn.cycles.samples = 24
    scn.cycles.device = "CPU"
    scn.render.resolution_x = size
    scn.render.resolution_y = size
    scn.render.film_transparent = False
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (*hex_color("efe2c4"), 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.8
    scn.world = world
    cam_data = bpy.data.cameras.new("PreviewCam")
    cam_data.lens = 50
    cam = bpy.data.objects.new("PreviewCam", cam_data)
    scn.collection.objects.link(cam)
    az = math.radians(azimuth)
    el = math.radians(elevation)
    t = Vector(target)
    cam.location = t + Vector((math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el))) * dist
    direction = t - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scn.camera = cam
    sun_data = bpy.data.lights.new("Sun", "SUN")
    sun_data.energy = 3.0
    sun = bpy.data.objects.new("Sun", sun_data)
    sun.rotation_euler = (math.radians(50), 0, math.radians(30))
    scn.collection.objects.link(sun)
    scn.render.filepath = path
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)
    bpy.data.objects.remove(sun, do_unlink=True)
    bpy.context.view_layer.update()
    print("preview", path)
