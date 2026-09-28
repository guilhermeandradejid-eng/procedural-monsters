"""The Wick Knight (Cavaleiro-Pavio): a chibi candle-knight with a pen-nib
sword and a candle on the helm. Rigid-skinned toy proportions, 16 actions."""

import math

import lib as L

BONES = [
    ("root", (0, 0, 0), (0, 0, 0.15), None),
    ("hips", (0, 0, 0.34), (0, 0, 0.46), "root"),
    ("spine", (0, 0, 0.46), (0, 0, 0.6), "hips"),
    ("chest", (0, 0, 0.6), (0, 0, 0.78), "spine"),
    ("head", (0, 0, 0.8), (0, 0, 1.15), "chest"),
    ("flame", (0, 0, 1.46), (0, 0, 1.56), "head"),
    ("cape", (0, 0.17, 0.76), (0, 0.24, 0.34), "chest"),
    ("upper_arm.L", (0.29, 0, 0.7), (0.29, 0, 0.53), "chest"),
    ("forearm.L", (0.29, 0, 0.53), (0.29, 0, 0.41), "upper_arm.L"),
    ("hand.L", (0.29, 0, 0.41), (0.29, 0, 0.33), "forearm.L"),
    ("upper_arm.R", (-0.29, 0, 0.7), (-0.29, 0, 0.53), "chest"),
    ("forearm.R", (-0.29, 0, 0.53), (-0.29, 0, 0.41), "upper_arm.R"),
    ("hand.R", (-0.29, 0, 0.41), (-0.29, 0, 0.33), "forearm.R"),
    ("thigh.L", (0.1, 0, 0.34), (0.1, 0, 0.2), "hips"),
    ("shin.L", (0.1, 0, 0.2), (0.1, 0, 0.07), "thigh.L"),
    ("foot.L", (0.1, 0, 0.07), (0.1, -0.13, 0.04), "shin.L"),
    ("thigh.R", (-0.1, 0, 0.34), (-0.1, 0, 0.2), "hips"),
    ("shin.R", (-0.1, 0, 0.2), (-0.1, 0, 0.07), "thigh.R"),
    ("foot.R", (-0.1, 0, 0.07), (-0.1, -0.13, 0.04), "shin.R"),
]


def materials():
    return {
        "cloth": L.material("Cloth", "b8452a", 0.85),
        "cloth_dark": L.material("ClothDark", "5a2418", 0.9),
        "metal": L.material("Metal", "8f979c", 0.4, 0.6),
        "trim": L.material("Trim", "c9a15b", 0.35, 0.8),
        "leather": L.material("Leather", "5b3a26", 0.8),
        "wax": L.material("Wax", "efe2c4", 0.6),
        "eyes": L.material("Eyes", "ffd06a", 0.5, 0.0, "ffb347", 6.0),
        "ink": L.material("Ink", "1c1411", 0.9),
        "nib": L.material("Nib", "d9b25a", 0.3, 0.9),
        "quill": L.material("Quill", "f3ead8", 0.8),
    }


def build_body(m):
    parts = []
    # --- legs & boots
    for side, sx in (("L", 1), ("R", -1)):
        x = 0.1 * sx
        parts.append((L.cone("thigh." + side, 0.075, 0.065, 0.16, loc=(x, 0, 0.28), mat=m["leather"]), "thigh." + side))
        parts.append((L.cone("shin." + side, 0.062, 0.058, 0.13, loc=(x, 0, 0.14), mat=m["leather"]), "shin." + side))
        boot = L.sphere("boot." + side, 1.0, loc=(x, -0.035, 0.05), scale=(0.075, 0.12, 0.055), segs=12, rings=6, mat=m["leather"])
        parts.append((boot, "foot." + side))
        cuff = L.torus("cuff." + side, 0.065, 0.018, loc=(x, 0, 0.1), mat=m["trim"], seg_major=14, seg_minor=6)
        parts.append((cuff, "shin." + side))
    # --- skirt (tabard lower half) and armoured torso
    skirt = L.lathe("skirt", [(0.23, 0.46), (0.25, 0.4), (0.28, 0.3), (0.3, 0.22), (0.285, 0.2), (0.0, 0.2)], segs=18, mat=m["cloth"])
    L.jitter(skirt, 0.006, 3)
    parts.append((skirt, "hips"))
    hem = L.torus("hem", 0.295, 0.018, loc=(0, 0, 0.215), mat=m["trim"], seg_major=24, seg_minor=6)
    parts.append((hem, "hips"))
    torso = L.lathe("torso", [(0.0, 0.44), (0.22, 0.44), (0.245, 0.52), (0.25, 0.6), (0.225, 0.7), (0.16, 0.77), (0.09, 0.8), (0.0, 0.8)], segs=18, mat=m["metal"])
    parts.append((torso, "chest"))
    belt = L.torus("belt", 0.235, 0.03, loc=(0, 0, 0.465), mat=m["leather"], seg_major=24, seg_minor=6)
    parts.append((belt, "hips"))
    buckle = L.box("buckle", (0.07, 0.03, 0.06), loc=(0, -0.255, 0.465), mat=m["trim"], bevel=0.008)
    parts.append((buckle, "hips"))
    # Tabard front panel with a flame emblem.
    panel_pts = [(-0.08, 0.0), (0.08, 0.0), (0.12, -0.3), (0.0, -0.36), (-0.12, -0.3)]
    panel = L.extrude_shape("panel", panel_pts, depth=0.016, loc=(0, -0.243, 0.72), rot=(96, 0, 0), mat=m["cloth"])
    parts.append((panel, "chest"))
    emblem = [(0.0, 0.07), (0.035, 0.0), (0.02, -0.05), (0.0, -0.035), (-0.02, -0.05), (-0.035, 0.0)]
    parts.append((L.extrude_shape("emblem", emblem, depth=0.012, loc=(0, -0.258, 0.6), rot=(96, 0, 0), mat=m["trim"]), "chest"))
    scarf = L.torus("scarf", 0.14, 0.05, loc=(0, 0.0, 0.795), mat=m["cloth"], seg_major=16, seg_minor=8)
    parts.append((scarf, "chest"))
    # --- cape (curved slab behind the shoulders)
    cape = L.box("cape", (1, 1, 1), mat=m["cloth"])
    import bmesh
    bm = bmesh.new()
    rows, cols = 7, 7
    grid = []
    for j in range(rows):
        row = []
        z = 0.76 - 0.42 * j / (rows - 1)
        w = 0.2 + 0.07 * j / (rows - 1)
        for i in range(cols):
            u = -1 + 2 * i / (cols - 1)
            x = u * w
            y = 0.17 + 0.07 * (u * u) + 0.06 * (j / (rows - 1))
            zz = z - 0.03 * (u * u) * (j / (rows - 1))
            row.append(bm.verts.new((x, y, zz)))
        grid.append(row)
    for j in range(rows - 1):
        for i in range(cols - 1):
            bm.faces.new((grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i]))
    me = cape.data
    bm.to_mesh(me)
    bm.free()
    solid = cape.modifiers.new("Solid", "SOLIDIFY")
    solid.thickness = 0.022
    L.apply_modifiers(cape)
    for p in cape.data.polygons:
        p.use_smooth = True
    parts.append((cape, "cape"))
    # --- arms
    for side, sx in (("L", 1), ("R", -1)):
        x = 0.29 * sx
        pad = L.sphere("pad." + side, 1.0, loc=(0.27 * sx, 0, 0.71), scale=(0.12, 0.12, 0.09), segs=12, rings=6, mat=m["metal"])
        parts.append((pad, "upper_arm." + side))
        pad_rim = L.torus("padrim." + side, 0.1, 0.014, loc=(0.27 * sx, 0, 0.665), mat=m["trim"], seg_major=14, seg_minor=5)
        parts.append((pad_rim, "upper_arm." + side))
        parts.append((L.cone("uarm." + side, 0.052, 0.048, 0.16, loc=(x, 0, 0.61), mat=m["cloth_dark"]), "upper_arm." + side))
        parts.append((L.cone("farm." + side, 0.05, 0.056, 0.12, loc=(x, 0, 0.47), mat=m["metal"]), "forearm." + side))
        parts.append((L.sphere("hand." + side, 0.066, loc=(x, -0.01, 0.37), segs=10, rings=6, mat=m["leather"]), "hand." + side))
    # --- helm
    helm = L.sphere("helm", 1.0, loc=(0, 0, 1.0), scale=(0.25, 0.24, 0.235), segs=20, rings=12, mat=m["metal"])
    parts.append((helm, "head"))
    brim = L.torus("brim", 0.245, 0.028, loc=(0, 0, 0.885), mat=m["trim"], seg_major=24, seg_minor=6)
    parts.append((brim, "head"))
    visor = L.box("visor", (0.3, 0.06, 0.062), loc=(0, -0.205, 0.99), mat=m["ink"], bevel=0.012)
    parts.append((visor, "head"))
    for sx in (1, -1):
        parts.append((L.sphere("eye%d" % sx, 0.026, loc=(0.065 * sx, -0.238, 0.99), segs=8, rings=5, mat=m["eyes"]), "head"))
    ridge = L.box("ridge", (0.03, 0.34, 0.03), loc=(0, 0.0, 1.225), mat=m["trim"], bevel=0.01)
    parts.append((ridge, "head"))
    # Candle crest: dish, drippy wax, wick. The flame itself is a Godot effect on bone "flame".
    parts.append((L.cone("dish", 0.11, 0.075, 0.04, loc=(0, 0, 1.24), mat=m["trim"], segs=14), "head"))
    candle = L.lathe("candle", [(0.0, 1.25), (0.078, 1.25), (0.076, 1.33), (0.073, 1.4), (0.058, 1.418), (0.0, 1.41)], segs=14, mat=m["wax"])
    parts.append((candle, "head"))
    for i, (a, h) in enumerate(((20, 0.05), (140, 0.035), (250, 0.045))):
        ang = math.radians(a)
        drip = L.sphere("drip%d" % i, 1.0, loc=(0.076 * math.cos(ang), 0.076 * math.sin(ang), 1.39 - h * 0.5), scale=(0.018, 0.018, h * 0.6), segs=8, rings=5, mat=m["wax"])
        parts.append((drip, "head"))
    parts.append((L.cone("wick", 0.009, 0.006, 0.045, loc=(0, 0, 1.43), mat=m["ink"], segs=6), "head"))
    return parts


def build_weapon(m):
    """Pen-nib sword held in the right hand: nib blade forward, feather pommel behind."""
    parts = []
    hx, hy, hz = -0.29, -0.01, 0.37
    # Blade: an elongated pen nib, extruded, pointing forward (-Y).
    nib = [(-0.05, 0.0), (0.05, 0.0), (0.052, 0.18), (0.04, 0.38), (0.018, 0.54), (0.0, 0.6), (-0.018, 0.54), (-0.04, 0.38), (-0.052, 0.18)]
    blade = L.extrude_shape("blade", nib, depth=0.022, mat=m["nib"])
    L.add_bevel(blade, 0.006, 1)
    slit = L.box("slit", (0.008, 0.3, 0.026), loc=(0, 0.42, 0), mat=m["ink"])
    hole = L.cone("hole", 0.017, 0.017, 0.028, loc=(0, 0.25, 0), mat=m["ink"], segs=10)
    guard = L.box("guard", (0.16, 0.03, 0.045), loc=(0, -0.01, 0), mat=m["trim"], bevel=0.01)
    grip = L.cone("grip", 0.024, 0.024, 0.15, loc=(0, -0.09, 0), rot=(90, 0, 0), mat=m["leather"], segs=8)
    # Feather pommel: a curved vane behind the hand.
    vane_pts = []
    n = 12
    for i in range(n + 1):
        t = i / n
        vane_pts.append((0.075 * math.sin(math.pi * t) ** 0.8 + 0.004, -0.17 - 0.42 * t))
    for i in range(n, -1, -1):
        t = i / n
        notch = 0.012 if i % 3 == 1 else 0.0
        vane_pts.append((-0.05 * math.sin(math.pi * t) ** 0.9 + notch - 0.004, -0.17 - 0.42 * t))
    vane = L.extrude_shape("vane", vane_pts, depth=0.012, mat=m["quill"])
    rachis = L.cone("rachis", 0.009, 0.004, 0.44, loc=(0, -0.38, 0), rot=(90, 0, 0), mat=m["wax"], segs=6)
    group = [blade, slit, hole, guard, grip, vane, rachis]
    from mathutils import Matrix
    # Weapon space: blade along +Y, flat face normal +Z. At rest (arm hanging) the blade
    # points down and 35 degrees forward, so when the arm swings forward the blade
    # extends the arm and its flat nib face looks up at the camera.
    a = math.radians(35)
    s, c = math.sin(a), math.cos(a)
    rot = Matrix(((-1, 0, 0), (0, -s, -c), (0, -c, s))).to_4x4()
    xform = Matrix.Translation((hx, hy, hz)) @ rot @ Matrix.Translation((0, 0.09, 0))
    for ob in group:
        ob.data.transform(xform)
        parts.append((ob, "hand.R"))
    return parts


# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------

STANCE = {
    "spine": {"rot": (4, 0, 0)},
    "head": {"rot": (-4, 0, 0)},
    "upper_arm.L": {"rot": (8, 0, 14)},
    "forearm.L": {"rot": (18, 0, 0)},
    "upper_arm.R": {"rot": (22, 0, -10)},
    "forearm.R": {"rot": (38, 0, 0)},
    "cape": {"rot": (-6, 0, 0)},
}


def pose(**over):
    p = {k: dict(v) for k, v in STANCE.items()}
    for k, v in over.items():
        p[k.replace("__", ".")] = v
    return p


def P(base=None, **over):
    """Pose from a base pose dict with overrides. Use __ for '.' in bone names."""
    p = {k: dict(v) for k, v in (base or STANCE).items()}
    for k, v in over.items():
        p[k.replace("__", ".")] = v
    return p


def animate_all(arm):
    A = L.animate
    # Idle: breathing, cape sway, flame bone bob.
    A(arm, "idle", [
        (0.0, P()),
        (1.0, P(spine={"rot": (6, 0, 0)}, chest={"rot": (2, 0, 0)}, head={"rot": (-7, 0, 2)},
                upper_arm__L={"rot": (6, 0, 18)}, upper_arm__R={"rot": (20, 0, -13)},
                hips={"loc": (0, -0.008, 0)}, cape={"rot": (-10, 0, 2)})),
        (2.0, P()),
    ])
    # Run cycle (0.56 s): contact / passing / contact / passing.
    lean = {"rot": (14, 0, 0)}
    A(arm, "run", [
        (0.0, P(spine=lean, head={"rot": (-10, 0, 0)}, hips={"loc": (0, 0.0, 0), "rot": (0, 8, 0)},
                thigh__L={"rot": (42, 0, 0)}, shin__L={"rot": (-12, 0, 0)}, foot__L={"rot": (-10, 0, 0)},
                thigh__R={"rot": (-32, 0, 0)}, shin__R={"rot": (-42, 0, 0)},
                upper_arm__L={"rot": (-34, 0, 14)}, forearm__L={"rot": (30, 0, 0)},
                upper_arm__R={"rot": (40, 0, -10)}, forearm__R={"rot": (45, 0, 0)}, cape={"rot": (-28, 0, 0)})),
        (0.14, P(spine=lean, head={"rot": (-8, 0, 0)}, hips={"loc": (0, 0.045, 0)},
                 thigh__L={"rot": (-4, 0, 0)}, shin__L={"rot": (-8, 0, 0)},
                 thigh__R={"rot": (18, 0, 0)}, shin__R={"rot": (-70, 0, 0)},
                 upper_arm__L={"rot": (0, 0, 14)}, forearm__L={"rot": (25, 0, 0)},
                 upper_arm__R={"rot": (18, 0, -10)}, forearm__R={"rot": (40, 0, 0)}, cape={"rot": (-36, 0, 0)})),
        (0.28, P(spine=lean, head={"rot": (-10, 0, 0)}, hips={"loc": (0, 0.0, 0), "rot": (0, -8, 0)},
                 thigh__R={"rot": (42, 0, 0)}, shin__R={"rot": (-12, 0, 0)}, foot__R={"rot": (-10, 0, 0)},
                 thigh__L={"rot": (-32, 0, 0)}, shin__L={"rot": (-42, 0, 0)},
                 upper_arm__R={"rot": (-20, 0, -10)}, forearm__R={"rot": (50, 0, 0)},
                 upper_arm__L={"rot": (44, 0, 14)}, forearm__L={"rot": (30, 0, 0)}, cape={"rot": (-28, 0, 0)})),
        (0.42, P(spine=lean, head={"rot": (-8, 0, 0)}, hips={"loc": (0, 0.045, 0)},
                 thigh__R={"rot": (-4, 0, 0)}, shin__R={"rot": (-8, 0, 0)},
                 thigh__L={"rot": (18, 0, 0)}, shin__L={"rot": (-70, 0, 0)},
                 upper_arm__R={"rot": (20, 0, -10)}, forearm__R={"rot": (40, 0, 0)},
                 upper_arm__L={"rot": (10, 0, 14)}, forearm__L={"rot": (25, 0, 0)}, cape={"rot": (-36, 0, 0)})),
        (0.56, P(spine=lean, head={"rot": (-10, 0, 0)}, hips={"loc": (0, 0.0, 0), "rot": (0, 8, 0)},
                 thigh__L={"rot": (42, 0, 0)}, shin__L={"rot": (-12, 0, 0)}, foot__L={"rot": (-10, 0, 0)},
                 thigh__R={"rot": (-32, 0, 0)}, shin__R={"rot": (-42, 0, 0)},
                 upper_arm__L={"rot": (-34, 0, 14)}, forearm__L={"rot": (30, 0, 0)},
                 upper_arm__R={"rot": (40, 0, -10)}, forearm__R={"rot": (45, 0, 0)}, cape={"rot": (-28, 0, 0)})),
    ])
    dash_pose = P(spine={"rot": (38, 0, 0)}, head={"rot": (-24, 0, 0)}, hips={"loc": (0, -0.03, 0)},
                  upper_arm__L={"rot": (-60, 0, 20)}, forearm__L={"rot": (10, 0, 0)},
                  upper_arm__R={"rot": (-55, 0, -20)}, forearm__R={"rot": (20, 0, 0)},
                  thigh__L={"rot": (35, 0, 0)}, shin__L={"rot": (-70, 0, 0)},
                  thigh__R={"rot": (-40, 0, 0)}, shin__R={"rot": (-30, 0, 0)}, cape={"rot": (-60, 0, 0)})
    A(arm, "dash", [(0.0, P(hips={"loc": (0, -0.05, 0)}, spine={"rot": (20, 0, 0)})), (0.06, dash_pose), (0.3, dash_pose)])
    # Quill combo.
    A(arm, "attack_1", [
        (0.0, P(spine={"rot": (6, -32, 0)}, chest={"rot": (0, -14, 0)}, upper_arm__R={"rot": (70, 75, -30)}, forearm__R={"rot": (25, 0, 0)}, upper_arm__L={"rot": (10, 0, 30)})),
        (0.07, P(spine={"rot": (10, 0, 0)}, upper_arm__R={"rot": (86, 0, -8)}, forearm__R={"rot": (8, 0, 0)}, upper_arm__L={"rot": (-10, 0, 24)})),
        (0.13, P(spine={"rot": (10, 32, 0)}, chest={"rot": (0, 14, 0)}, upper_arm__R={"rot": (80, -72, -8)}, forearm__R={"rot": (10, 0, 0)}, upper_arm__L={"rot": (-20, 0, 20)})),
        (0.22, P(spine={"rot": (8, 28, 0)}, chest={"rot": (0, 12, 0)}, upper_arm__R={"rot": (74, -66, -8)}, forearm__R={"rot": (18, 0, 0)})),
        (0.36, P()),
    ])
    A(arm, "attack_2", [
        (0.0, P(spine={"rot": (6, 26, 0)}, chest={"rot": (0, 12, 0)}, upper_arm__R={"rot": (78, -70, -8)}, forearm__R={"rot": (40, 0, 0)})),
        (0.07, P(spine={"rot": (10, 0, 0)}, upper_arm__R={"rot": (86, 0, -12)}, forearm__R={"rot": (10, 0, 0)})),
        (0.13, P(spine={"rot": (10, -30, 0)}, chest={"rot": (0, -14, 0)}, upper_arm__R={"rot": (80, 78, -20)}, forearm__R={"rot": (8, 0, 0)}, upper_arm__L={"rot": (10, 0, 34)})),
        (0.22, P(spine={"rot": (8, -26, 0)}, chest={"rot": (0, -12, 0)}, upper_arm__R={"rot": (74, 70, -20)}, forearm__R={"rot": (16, 0, 0)})),
        (0.36, P()),
    ])
    A(arm, "attack_3", [
        (0.0, P(spine={"rot": (-8, 0, 0)}, head={"rot": (-10, 0, 0)}, upper_arm__R={"rot": (140, 0, -12)}, forearm__R={"rot": (10, 0, 0)}, upper_arm__L={"rot": (60, 0, 40)}, hips={"loc": (0, 0.03, 0)})),
        (0.12, P(spine={"rot": (-12, 0, 0)}, head={"rot": (-12, 0, 0)}, upper_arm__R={"rot": (150, 0, -10)}, forearm__R={"rot": (16, 0, 0)}, upper_arm__L={"rot": (70, 0, 44)}, hips={"loc": (0, 0.06, 0)})),
        (0.19, P(spine={"rot": (34, 0, 0)}, head={"rot": (-18, 0, 0)}, upper_arm__R={"rot": (8, 0, -6)}, forearm__R={"rot": (10, 0, 0)}, upper_arm__L={"rot": (-10, 0, 30)},
                 hips={"loc": (0, -0.06, 0)}, thigh__L={"rot": (30, 0, 0)}, shin__L={"rot": (-50, 0, 0)}, thigh__R={"rot": (22, 0, 0)}, shin__R={"rot": (-40, 0, 0)})),
        (0.32, P(spine={"rot": (30, 0, 0)}, upper_arm__R={"rot": (6, 0, -6)}, forearm__R={"rot": (12, 0, 0)}, hips={"loc": (0, -0.05, 0)}, thigh__L={"rot": (26, 0, 0)}, shin__L={"rot": (-44, 0, 0)}, thigh__R={"rot": (18, 0, 0)}, shin__R={"rot": (-34, 0, 0)})),
        (0.5, P()),
    ])
    # Casts: the free (left) hand does the talking; each form maps to one gesture.
    A(arm, "cast_thrust", [
        (0.0, P(spine={"rot": (4, -18, 0)}, upper_arm__L={"rot": (-24, 0, 16)}, forearm__L={"rot": (70, 0, 0)})),
        (0.08, P(spine={"rot": (12, 14, 0)}, chest={"rot": (6, 0, 0)}, upper_arm__L={"rot": (88, 0, 4)}, forearm__L={"rot": (0, 0, 0)}, hand__L={"rot": (-35, 0, 0)}, cape={"rot": (-18, 0, 0)})),
        (0.24, P(spine={"rot": (10, 12, 0)}, upper_arm__L={"rot": (84, 0, 4)}, forearm__L={"rot": (6, 0, 0)}, hand__L={"rot": (-30, 0, 0)})),
        (0.4, P()),
    ])
    A(arm, "cast_slam", [
        (0.0, P(spine={"rot": (-10, 0, 0)}, upper_arm__L={"rot": (150, 0, 16)}, upper_arm__R={"rot": (150, 0, -16)}, forearm__L={"rot": (10, 0, 0)}, forearm__R={"rot": (10, 0, 0)}, root={"loc": (0, 0.08, 0)})),
        (0.1, P(spine={"rot": (-12, 0, 0)}, upper_arm__L={"rot": (160, 0, 18)}, upper_arm__R={"rot": (160, 0, -18)}, root={"loc": (0, 0.12, 0)})),
        (0.17, P(spine={"rot": (38, 0, 0)}, head={"rot": (-20, 0, 0)}, upper_arm__L={"rot": (40, 0, 28)}, upper_arm__R={"rot": (40, 0, -28)},
                 hips={"loc": (0, -0.08, 0)}, thigh__L={"rot": (38, 0, 0)}, shin__L={"rot": (-64, 0, 0)}, thigh__R={"rot": (34, 0, 0)}, shin__R={"rot": (-60, 0, 0)}, cape={"rot": (10, 0, 0)})),
        (0.32, P(spine={"rot": (32, 0, 0)}, upper_arm__L={"rot": (36, 0, 26)}, upper_arm__R={"rot": (36, 0, -26)}, hips={"loc": (0, -0.07, 0)},
                 thigh__L={"rot": (34, 0, 0)}, shin__L={"rot": (-58, 0, 0)}, thigh__R={"rot": (30, 0, 0)}, shin__R={"rot": (-54, 0, 0)})),
        (0.5, P()),
    ])
    A(arm, "cast_raise", [
        (0.0, P(hips={"loc": (0, -0.04, 0)}, upper_arm__L={"rot": (10, 0, 20)}, upper_arm__R={"rot": (10, 0, -20)})),
        (0.12, P(spine={"rot": (-12, 0, 0)}, head={"rot": (-22, 0, 0)}, upper_arm__L={"rot": (172, 0, 22)}, upper_arm__R={"rot": (172, 0, -22)}, forearm__L={"rot": (0, 0, 0)}, forearm__R={"rot": (0, 0, 0)}, hips={"loc": (0, 0.03, 0)}, cape={"rot": (-20, 0, 0)})),
        (0.36, P(spine={"rot": (-10, 0, 0)}, head={"rot": (-18, 0, 0)}, upper_arm__L={"rot": (168, 0, 24)}, upper_arm__R={"rot": (168, 0, -24)})),
        (0.55, P()),
    ])
    A(arm, "cast_sweep", [
        (0.0, P(spine={"rot": (4, -24, 0)}, upper_arm__L={"rot": (80, 62, 6)}, forearm__L={"rot": (20, 0, 0)})),
        (0.1, P(spine={"rot": (8, 26, 0)}, chest={"rot": (0, 10, 0)}, upper_arm__L={"rot": (86, -72, 10)}, forearm__L={"rot": (4, 0, 0)}, hand__L={"rot": (-20, 0, 0)})),
        (0.24, P(spine={"rot": (8, 24, 0)}, upper_arm__L={"rot": (82, -68, 10)}, forearm__L={"rot": (8, 0, 0)})),
        (0.4, P()),
    ])
    A(arm, "cast_spin", [
        (0.0, P(upper_arm__L={"rot": (10, 0, 80)}, upper_arm__R={"rot": (10, 0, -80)}, forearm__L={"rot": (0, 0, 0)}, forearm__R={"rot": (0, 0, 0)}, root={"rot": (0, 0, 0)})),
        (0.12, P(upper_arm__L={"rot": (10, 0, 84)}, upper_arm__R={"rot": (10, 0, -84)}, root={"rot": (0, 120, 0)}, cape={"rot": (-40, 0, 0)})),
        (0.24, P(upper_arm__L={"rot": (10, 0, 84)}, upper_arm__R={"rot": (10, 0, -84)}, root={"rot": (0, 240, 0)}, cape={"rot": (-40, 0, 0)})),
        (0.36, P(upper_arm__L={"rot": (10, 0, 80)}, upper_arm__R={"rot": (10, 0, -80)}, root={"rot": (0, 360, 0)})),
        (0.5, P(root={"rot": (0, 360, 0)})),
    ], interp="LINEAR")
    A(arm, "cast_blink", [
        (0.0, P(hips={"loc": (0, -0.1, 0)}, spine={"rot": (26, 0, 0)}, upper_arm__L={"rot": (-40, 0, 20)}, upper_arm__R={"rot": (-40, 0, -20)},
                thigh__L={"rot": (40, 0, 0)}, shin__L={"rot": (-70, 0, 0)}, thigh__R={"rot": (40, 0, 0)}, shin__R={"rot": (-70, 0, 0)})),
        (0.1, P(hips={"loc": (0, 0.05, 0)}, spine={"rot": (-6, 0, 0)}, upper_arm__L={"rot": (60, 0, 50)}, upper_arm__R={"rot": (60, 0, -50)}, root={"scale": (0.9, 1.15, 0.9)})),
        (0.3, P()),
    ])
    A(arm, "hit", [
        (0.0, P(spine={"rot": (-22, 0, 4)}, head={"rot": (-16, 0, 0)}, upper_arm__L={"rot": (-10, 0, 40)}, upper_arm__R={"rot": (0, 0, -36)}, cape={"rot": (14, 0, 0)})),
        (0.25, P()),
    ])
    kneel = P(hips={"loc": (0, -0.2, 0)}, spine={"rot": (40, 0, 0)}, head={"rot": (35, 0, 0)},
              thigh__L={"rot": (95, 0, 0)}, shin__L={"rot": (-125, 0, 0)}, thigh__R={"rot": (90, 0, 0)}, shin__R={"rot": (-120, 0, 0)},
              upper_arm__L={"rot": (12, 0, 6)}, forearm__L={"rot": (10, 0, 0)}, upper_arm__R={"rot": (18, 0, -6)}, forearm__R={"rot": (20, 0, 0)}, cape={"rot": (20, 0, 0)})
    A(arm, "downed", [
        (0.0, P()),
        (0.2, P(hips={"loc": (0, -0.08, 0)}, spine={"rot": (-14, 0, 0)}, head={"rot": (-20, 0, 0)}, upper_arm__L={"rot": (-10, 0, 40)}, upper_arm__R={"rot": (-10, 0, -40)})),
        (0.55, kneel),
        (0.8, kneel),
    ])
    A(arm, "revive", [
        (0.0, kneel),
        (0.25, P(hips={"loc": (0, -0.1, 0)}, spine={"rot": (20, 0, 0)}, thigh__L={"rot": (50, 0, 0)}, shin__L={"rot": (-70, 0, 0)}, thigh__R={"rot": (40, 0, 0)}, shin__R={"rot": (-60, 0, 0)})),
        (0.42, P(hips={"loc": (0, 0.05, 0)}, spine={"rot": (-10, 0, 0)}, head={"rot": (-18, 0, 0)}, upper_arm__L={"rot": (160, 0, 30)}, upper_arm__R={"rot": (160, 0, -30)})),
        (0.6, P()),
    ])
    A(arm, "victory", [
        (0.0, P()),
        (0.18, P(root={"loc": (0, 0.12, 0)}, spine={"rot": (-8, 0, 0)}, head={"rot": (-16, 0, 0)}, upper_arm__R={"rot": (168, 0, -8)}, forearm__R={"rot": (4, 0, 0)}, upper_arm__L={"rot": (20, 0, 40)})),
        (0.32, P(spine={"rot": (-6, 0, 0)}, head={"rot": (-14, 0, 0)}, upper_arm__R={"rot": (166, 0, -8)}, forearm__R={"rot": (6, 0, 0)}, upper_arm__L={"rot": (16, 0, 34)})),
        (1.2, P(spine={"rot": (-6, 0, 0)}, head={"rot": (-12, 0, 0)}, upper_arm__R={"rot": (164, 0, -8)}, forearm__R={"rot": (6, 0, 0)}, upper_arm__L={"rot": (16, 0, 30)})),
    ])


def build(out_dir, preview_dir=None):
    L.reset()
    m = materials()
    arm = L.armature("KnightRig", BONES)
    parts = build_body(m) + build_weapon(m)
    L.rigid_parts(parts, arm, "Knight")
    animate_all(arm)
    if preview_dir:
        L.preview(preview_dir + "/knight.png", target=(0, 0, 0.7), dist=3.4)
    L.export_glb(out_dir + "/knight.glb", [arm])


# ---------------------------------------------------------------------------
# The floating grimoire
# ---------------------------------------------------------------------------

BOOK_BONES = [
    ("spine", (0, -0.2, 0), (0, 0.2, 0), None),
    ("back", (0, -0.2, -0.03), (0, 0.2, -0.03), "spine"),
    ("front", (0, -0.2, 0.03), (0, 0.2, 0.03), "spine"),
    ("page", (0, -0.19, 0.012), (0, 0.19, 0.012), "spine"),
]


def build_book(out_dir, preview_dir=None):
    L.reset()
    cover = L.material("Cover", "7a1f1a", 0.7)
    paper = L.material("Paper", "f1e6c8", 0.9)
    trim = L.material("Trim", "c9a15b", 0.35, 0.8)
    gem = L.material("Gem", "ff8a2b", 0.2, 0.0, "ff7a1f", 4.0)
    leather = L.material("Leather", "5b3a26", 0.8)
    arm = L.armature("BookRig", BOOK_BONES)
    parts = []
    W, H, T = 0.3, 0.4, 0.018
    # Back cover + left page block (stays), front cover + right page block (opens).
    parts.append((L.box("back_cover", (W, H + 0.02, T), loc=(W / 2, 0, -0.03), mat=cover, bevel=0.006), "back"))
    parts.append((L.box("pages_back", (W - 0.02, H - 0.01, 0.022), loc=(W / 2 - 0.005, 0, -0.012), mat=paper, bevel=0.003), "back"))
    parts.append((L.box("front_cover", (W, H + 0.02, T), loc=(W / 2, 0, 0.03), mat=cover, bevel=0.006), "front"))
    parts.append((L.box("pages_front", (W - 0.02, H - 0.01, 0.022), loc=(W / 2 - 0.005, 0, 0.012), mat=paper, bevel=0.003), "front"))
    parts.append((L.cone("spine_roll", 0.034, 0.034, H + 0.02, loc=(0, 0, 0), rot=(90, 0, 0), mat=cover, segs=10), "spine"))
    for sy in (-1, 1):
        corner = L.extrude_shape("corner%d" % sy, [(0, 0), (0.06, 0), (0, 0.06 * sy)], depth=0.024, loc=(W - 0.06, sy * (H / 2 + 0.01) - 0.0, 0.03), mat=trim)
        parts.append((corner, "front"))
    parts.append((L.box("strap", (0.06, 0.05, 0.05), loc=(W + 0.005, 0, 0.0), mat=leather, bevel=0.01), "front"))
    parts.append((L.sphere("gem", 0.03, loc=(W / 2, 0, 0.045), scale=(1, 1, 0.5), mat=gem, segs=10, rings=6), "front"))
    ring = L.torus("gemring", 0.04, 0.008, loc=(W / 2, 0, 0.04), mat=trim, seg_major=12, seg_minor=4)
    parts.append((ring, "front"))
    parts.append((L.box("page_sheet", (W - 0.03, H - 0.03, 0.003), loc=(W / 2 - 0.01, 0, 0.026), mat=paper), "page"))
    L.rigid_parts(parts, arm, "Grimoire")
    A = L.animate
    A(arm, "closed", [(0.0, {"spine": {"rot": (0, 0, 0)}}), (1.0, {"spine": {"rot": (0, 0, 0)}})])
    opened = {"front": {"rot": (0, -168, 0)}, "page": {"rot": (0, -8, 0)}}
    A(arm, "open", [(0.0, {}), (0.25, opened)])
    A(arm, "open_idle", [
        (0.0, opened),
        (0.8, {"front": {"rot": (0, -164, 0)}, "page": {"rot": (0, -20, 0)}}),
        (1.6, opened),
    ])
    A(arm, "flip", [
        (0.0, {"front": {"rot": (0, -168, 0)}, "page": {"rot": (0, -4, 0)}}),
        (0.14, {"front": {"rot": (0, -166, 0)}, "page": {"rot": (0, -95, 0)}}),
        (0.28, {"front": {"rot": (0, -168, 0)}, "page": {"rot": (0, -166, 0)}}),
        (0.34, {"front": {"rot": (0, -168, 0)}, "page": {"rot": (0, -8, 0)}}),
    ])
    if preview_dir:
        L.preview(preview_dir + "/book.png", target=(0.1, 0, 0), dist=1.4, elevation=40)
    L.export_glb(out_dir + "/grimoire.glb", [arm])
