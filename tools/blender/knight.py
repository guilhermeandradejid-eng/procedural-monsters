"""The Wick Knight (Cavaleiro-Pavio): a chibi candle-knight with a pen-nib
sword and a candle on the helm. Rigid-skinned toy proportions, 16 actions."""

import math

import lib as L
import motion as M

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
# Authored with motion.py: key poses + eased timing, then overlap (lag),
# follow-through (world-space springs on cape, flame and head), squash & stretch
# on the torso and two-bone IK that keeps the boots planted while the hips work.

LEG_L = M.Leg("thigh.L", "shin.L", "foot.L", 0.14, 0.13, 0.34, 0.07)
LEG_R = M.Leg("thigh.R", "shin.R", "foot.R", 0.14, 0.13, 0.34, 0.07)
UP_CHAIN = ("root", "hips", "spine", "chest")

# Soft knees and a slight contrapposto: never stand locked straight (appeal).
STANCE = {
    "hips": {"loc": (0, -0.016, 0), "rot": (0, 4, 1.5)},
    "spine": {"rot": (5, -3, 0)},
    "chest": {"rot": (0, -2, -1)},
    "head": {"rot": (-6, 3, 0)},
    "upper_arm.L": {"rot": (8, 0, 14)},
    "forearm.L": {"rot": (20, 0, 0)},
    "upper_arm.R": {"rot": (14, 12, -12)},
    "forearm.R": {"rot": (22, 0, 0)},
    "cape": {"rot": (-6, 0, 0)},
}


def P(base=None, **over):
    return M.merge(base or STANCE, **over)


def secondary(clip, head=0.045, arms=0.035, cape=(2.4, 0.36), flame=(3.2, 0.24), head_spring=True, sword_lag=None):
    """Follow-through and overlapping action shared by every clip."""
    sl = arms * 0.6 if sword_lag is None else sword_lag
    clip.lag.update({
        "chest": 0.012, "head": head,
        "forearm.L": arms, "forearm.R": sl, "hand.L": arms * 1.6, "hand.R": sl * 1.5,
    })
    clip.springs["cape"] = M.Spring(cape[0], cape[1], parents=UP_CHAIN, xsign=-1.0)
    clip.springs["flame"] = M.Spring(flame[0], flame[1], parents=UP_CHAIN + ("head",), xsign=1.0)
    if head_spring:
        clip.springs["head"] = M.Spring(6.0, 0.45, gain=0.55)
    return clip


def plant(clip, lf=None, rf=None):
    """Feet stay on the ground; lf/rf: keyed foot paths [(t, fwd, up, toe), ...]."""
    clip.ik[LEG_L] = M.keyed_foot(LEG_L, lf) if lf else M.planted(LEG_L)
    clip.ik[LEG_R] = M.keyed_foot(LEG_R, rf) if rf else M.planted(LEG_R)
    return clip


def step(t0, t1, t2, t3, dist, lift=0.035):
    """A single step: lift at t0, land forward at t1, hold, step back t2..t3."""
    mid = (t0 + t1) * 0.5
    back = (t2 + t3) * 0.5
    return [(0.0, 0.0, 0.0, 0.0), (t0, 0.0, 0.0, 0.0), (mid, dist * 0.55, lift, 12.0), (t1, dist, 0.0, 0.0),
            (t2, dist, 0.0, 0.0), (back, dist * 0.45, lift * 0.6, -10.0), (t3, 0.0, 0.0, 0.0)]


def toes(t, leg, heel_deg, fwd=0.0):
    f, u, toe = leg.tiptoe(heel_deg, fwd)
    return (t, f, u, toe)


def clips():
    out = []

    # --- idle: breathing (chest rise + slight stretch), weight shift, drifting arms
    idle = M.Clip("idle", 2.0, loop=True)
    inhale = P(spine={"rot": (3, -3, 0)}, chest={"rot": (-3, -2, -1), "scale": M.squash(1.045)},
               head={"rot": (-9, 4, 1)}, hips={"loc": (0, -0.024, 0)},
               upper_arm__L={"rot": (5, 0, 18)}, upper_arm__R={"rot": (19, 0, -13)}, cape={"rot": (-10, 0, 0)})
    idle.key(0.0, P(), "inout").key(1.0, inhale, "inout")

    def weight_shift(t, pose):
        w = math.sin(2 * math.pi * t / 2.0 + 0.9)
        M.add_rot(pose, "hips", 0, 2.5 * w, 1.6 * w)
        M.add_rot(pose, "chest", 0, -2.0 * w, -1.2 * w)
        M.add_rot(pose, "hand.R", 3.0 * math.sin(2 * math.pi * t / 1.0), 0, 0)  # restless sword grip
    idle.layers.append(weight_shift)
    secondary(idle, head=0.18, arms=0.14)
    plant(idle)
    out.append(idle)

    # --- run: procedural gait on IK (feet really travel), hips bob & twist, arms
    # counter-swing, head stabilised, cape flapping on a spring.
    per = 0.5
    run = M.Clip("run", per, loop=True)
    run_base = P(hips={"loc": (0, -0.045, 0.01), "rot": (6, 0, 0)}, spine={"rot": (12, 0, 0)}, chest={"rot": (4, 0, 0)},
                 head={"rot": (-18, 0, 0)}, upper_arm__R={"rot": (4, 10, -16)}, forearm__R={"rot": (30, 0, 0)},
                 upper_arm__L={"rot": (0, 0, 16)}, forearm__L={"rot": (60, 0, 0)}, cape={"rot": (-34, 0, 0)})
    run.key(0.0, run_base, "linear")

    def gait(t, pose):
        ph = 2 * math.pi * t / per
        # lowest at each mid-stance (p = 0.2 and 0.7), highest in flight
        M.add_loc(pose, "hips", 0, -0.022 * math.cos(2 * (ph - 0.2 * 2 * math.pi)), 0)
        M.add_rot(pose, "hips", 0, 11 * math.cos(ph), -3 * math.sin(ph))
        M.add_rot(pose, "chest", 2.5 * math.cos(2 * ph), -15 * math.cos(ph - 0.35), 2.5 * math.sin(ph))
        M.add_rot(pose, "head", -2.5 * math.cos(2 * ph), 6 * math.cos(ph - 0.5), 0)  # keeps the eyes level
        lag = 0.35
        M.add_rot(pose, "upper_arm.L", -48 * math.cos(ph), 0, 4 * math.sin(ph))
        M.add_rot(pose, "forearm.L", 22 * math.cos(ph - lag) + 10, 0, 0)
        M.add_rot(pose, "upper_arm.R", 24 * math.cos(ph), 0, 0)
        M.add_rot(pose, "forearm.R", -12 * math.cos(ph - lag), 0, 0)
        M.add_rot(pose, "cape", -9 * math.cos(2 * ph + 0.8), 0, 5 * math.sin(ph))
        sq = 1.0 - 0.035 * max(0.0, math.cos(2 * (ph - 0.12 * 2 * math.pi)))
        M.mul_scale(pose, "spine", M.squash(sq))
    run.layers.append(gait)
    run.ik[LEG_L] = M.run_foot(LEG_L, per, 0.0, 0.1, 0.1)
    run.ik[LEG_R] = M.run_foot(LEG_R, per, 0.5, 0.1, 0.1)
    run.springs["cape"] = M.Spring(3.2, 0.3, parents=UP_CHAIN, xsign=-1.0)
    run.springs["flame"] = M.Spring(3.6, 0.25, parents=UP_CHAIN + ("head",), xsign=1.0)
    out.append(run)

    # --- dash: 1-frame crouch (anticipation), stretched launch, trailing limbs
    dash = M.Clip("dash", 0.3)
    crouch = P(hips={"loc": (0, -0.06, 0)}, spine={"rot": (26, 0, 0)}, root={"scale": M.squash(0.86)},
               upper_arm__L={"rot": (30, 0, 20)}, upper_arm__R={"rot": (40, 0, -20)},
               thigh__L={"rot": (40, 0, 0)}, shin__L={"rot": (-70, 0, 0)}, thigh__R={"rot": (34, 0, 0)}, shin__R={"rot": (-64, 0, 0)})
    launch = P(hips={"loc": (0, 0.0, 0.02)}, spine={"rot": (42, 0, 0)}, head={"rot": (-30, 0, 0)},
               root={"scale": (0.9, 0.92, 1.2)},
               upper_arm__L={"rot": (-70, 0, 24)}, forearm__L={"rot": (6, 0, 0)},
               upper_arm__R={"rot": (-60, 0, -24)}, forearm__R={"rot": (16, 0, 0)},
               thigh__L={"rot": (38, 0, 0)}, shin__L={"rot": (-80, 0, 0)}, foot__L={"rot": (30, 0, 0)},
               thigh__R={"rot": (-46, 0, 0)}, shin__R={"rot": (-28, 0, 0)}, foot__R={"rot": (40, 0, 0)}, cape={"rot": (-70, 0, 0)})
    glide = M.merge(launch, root={"scale": (0.96, 0.97, 1.08)}, spine={"rot": (36, 0, 0)})
    dash.key(0.0, crouch).key(0.05, launch, "snap").key(0.2, glide, "out").key(0.3, M.merge(glide, spine={"rot": (28, 0, 0)}), "inout")
    secondary(dash, head=0.03, arms=0.05, cape=(3.0, 0.3), head_spring=False)
    out.append(dash)

    # --- quill combo: 1-2 frame anticipation, a strike that accelerates (ease in),
    # overshooting follow-through and a slow cushion back; the feet step into it.
    # The blade is almost an extension of the arm (35 deg forward of it), so with the
    # upper arm 45 deg forward and the elbow 10 deg the blade is level; yawing the
    # upper arm (Euler Y is applied after X, i.e. about the shoulder's vertical axis)
    # then sweeps the blade on a clean horizontal arc that reads from the top camera.
    def slash(yaw, body, drop=0.0, **over):
        base = P(spine={"rot": (8 + drop, body * 0.62, 0)}, chest={"rot": (0, body * 0.38, 0)},
                 upper_arm__R={"rot": (45 + drop, yaw, -8)}, forearm__R={"rot": (10, 0, 0)}, hand__R={"rot": (0, 0, 0)})
        return M.merge(base, **over)

    a1 = M.Clip("attack_1", 0.46)
    coil = slash(52, -52, hips={"loc": (0, -0.03, -0.01), "rot": (0, -10, 0)}, upper_arm__L={"rot": (14, 0, 34)}, head={"rot": (-8, 12, 0)})
    coil2 = slash(62, -60, hips={"loc": (0, -0.035, -0.012), "rot": (0, -12, 0)}, upper_arm__L={"rot": (18, 0, 38)}, head={"rot": (-8, 14, 0)})
    strike = slash(0, 0, 4, hips={"loc": (0, -0.055, 0.05), "rot": (0, 4, 0)}, upper_arm__L={"rot": (-10, 0, 26)}, head={"rot": (-10, 0, 0)})
    follow = slash(-44, 56, 4, hips={"loc": (0, -0.05, 0.05), "rot": (0, 12, 0)}, upper_arm__L={"rot": (-30, 0, 24)},
                   head={"rot": (-10, -10, 0)}, chest={"rot": (0, 56 * 0.38, 0), "scale": M.squash(0.95)})
    settle = slash(-32, 42, 2, hips={"loc": (0, -0.04, 0.035), "rot": (0, 9, 0)}, upper_arm__L={"rot": (-12, 0, 22)})
    a1.key(0.0, coil).key(0.03, coil2, "out").key(0.065, strike, "in").key(0.11, follow, "out").key(0.26, settle, "out").key(0.46, P(), "inout")
    secondary(a1, sword_lag=0.0)
    plant(a1, lf=step(0.0, 0.07, 0.3, 0.44, 0.09))
    out.append(a1)

    # Backhand: the arm crosses the chest first, blade on the left, then whips right.
    a2 = M.Clip("attack_2", 0.46)
    coil = slash(-58, 44, -4, hips={"loc": (0, -0.03, 0.02), "rot": (0, 10, 0)}, upper_arm__L={"rot": (-14, 0, 22)}, head={"rot": (-8, -10, 0)})
    coil2 = slash(-66, 50, -4, hips={"loc": (0, -0.035, 0.02), "rot": (0, 12, 0)}, upper_arm__L={"rot": (-18, 0, 20)}, head={"rot": (-8, -12, 0)})
    strike = slash(0, 0, 4, hips={"loc": (0, -0.055, 0.05), "rot": (0, -4, 0)}, upper_arm__L={"rot": (6, 0, 30)}, head={"rot": (-10, 0, 0)})
    follow = slash(60, -48, 4, hips={"loc": (0, -0.05, 0.05), "rot": (0, -12, 0)}, upper_arm__L={"rot": (16, 0, 42)},
                   head={"rot": (-10, 10, 0)}, chest={"rot": (0, -48 * 0.38, 0), "scale": M.squash(0.95)})
    settle = slash(46, -36, 2, hips={"loc": (0, -0.04, 0.035), "rot": (0, -9, 0)}, upper_arm__L={"rot": (10, 0, 34)})
    a2.key(0.0, coil).key(0.03, coil2, "out").key(0.065, strike, "in").key(0.11, follow, "out").key(0.26, settle, "out").key(0.46, P(), "inout")
    secondary(a2, sword_lag=0.0)
    plant(a2, rf=step(0.0, 0.07, 0.3, 0.44, 0.09))
    out.append(a2)

    # Finisher: big anticipation (rise onto the toes, sword high = stretch),
    # accelerating slam, squash on impact and an impact hold before recovering.
    a3 = M.Clip("attack_3", 0.62)
    lift = P(spine={"rot": (-8, 0, 0)}, head={"rot": (-10, 0, 0)}, hips={"loc": (0, 0.0, -0.01)},
             upper_arm__R={"rot": (125, 0, -12)}, forearm__R={"rot": (18, 0, 0)}, upper_arm__L={"rot": (55, 0, 40)})
    peak = P(spine={"rot": (-17, 0, 0)}, chest={"rot": (-4, 0, 0), "scale": M.squash(1.07)}, head={"rot": (-16, 0, 0)},
             hips={"loc": (0, 0.045, -0.015)}, upper_arm__R={"rot": (156, 0, -10)}, forearm__R={"rot": (20, 0, 0)},
             upper_arm__L={"rot": (74, 0, 46)}, cape={"rot": (4, 0, 0)})
    peak_hang = M.merge(peak, spine={"rot": (-18, 0, 0)}, upper_arm__R={"rot": (158, 0, -10)})
    slam = P(spine={"rot": (38, 0, 0)}, chest={"rot": (4, 0, 0), "scale": M.squash(0.88)}, head={"rot": (-22, 0, 0)},
             hips={"loc": (0, -0.1, 0.06)}, upper_arm__R={"rot": (6, 0, -6)}, forearm__R={"rot": (8, 0, 0)},
             upper_arm__L={"rot": (-14, 0, 30)}, cape={"rot": (-30, 0, 0)})
    hold = M.merge(slam, spine={"rot": (33, 0, 0)}, chest={"rot": (3, 0, 0), "scale": M.squash(0.95)}, hips={"loc": (0, -0.085, 0.055)})
    a3.key(0.0, lift, "out").key(0.11, peak, "out").key(0.135, peak_hang, "linear").key(0.17, slam, "in") \
      .key(0.32, hold, "out").key(0.62, P(), "inout")
    secondary(a3, head=0.05, arms=0.04)
    plant(a3, lf=[(0.0, 0, 0, 0), toes(0.08, LEG_L, 18), toes(0.13, LEG_L, 28), (0.15, 0.07, 0.035, 12), (0.18, 0.11, 0, 0),
                  (0.4, 0.11, 0, 0), (0.5, 0.05, 0.02, -8), (0.6, 0, 0, 0)],
          rf=[(0.0, 0, 0, 0), toes(0.08, LEG_R, 18), toes(0.13, LEG_R, 28), (0.18, -0.03, 0, 0), (0.45, -0.03, 0, 0), (0.6, 0, 0, 0)])
    out.append(a3)

    # --- casts: the free (left) hand does the talking; one gesture per spell form.
    # Every release lands on the windup time Player.gd uses for the spell.
    ct = M.Clip("cast_thrust", 0.5)
    pull = P(spine={"rot": (2, -22, 0)}, hips={"loc": (0, -0.03, -0.02)}, upper_arm__L={"rot": (-30, 0, 16)},
             forearm__L={"rot": (82, 0, 0)}, head={"rot": (-8, 8, 0)})
    pull2 = M.merge(pull, spine={"rot": (0, -26, 0)}, upper_arm__L={"rot": (-38, 0, 18)}, forearm__L={"rot": (90, 0, 0)})
    thrust = P(spine={"rot": (14, 16, 0)}, chest={"rot": (6, 0, 0)}, hips={"loc": (0, -0.05, 0.045)},
               upper_arm__L={"rot": (90, 0, 4)}, forearm__L={"rot": (0, 0, 0)}, hand__L={"rot": (-42, 0, 0)}, cape={"rot": (-20, 0, 0)})
    over = M.merge(thrust, spine={"rot": (17, 19, 0)}, upper_arm__L={"rot": (97, 0, 4)}, hand__L={"rot": (-30, 0, 0)},
                   chest={"rot": (6, 0, 0), "scale": M.squash(1.04)})
    ct.key(0.0, pull, "out").key(0.05, pull2, "out").key(0.08, thrust, "in").key(0.12, over, "out") \
      .key(0.3, M.merge(thrust, hips={"loc": (0, -0.04, 0.03)}), "out").key(0.5, P(), "inout")
    secondary(ct)
    plant(ct, lf=step(0.03, 0.09, 0.3, 0.48, 0.07))
    out.append(ct)

    cs = M.Clip("cast_slam", 0.6)
    up = P(spine={"rot": (-12, 0, 0)}, chest={"scale": M.squash(1.06)}, head={"rot": (-14, 0, 0)}, hips={"loc": (0, 0.02, 0)},
           upper_arm__L={"rot": (150, 0, 16)}, upper_arm__R={"rot": (150, 0, -16)}, forearm__L={"rot": (10, 0, 0)}, forearm__R={"rot": (10, 0, 0)})
    up2 = M.merge(up, spine={"rot": (-14, 0, 0)}, upper_arm__L={"rot": (162, 0, 18)}, upper_arm__R={"rot": (162, 0, -18)}, hips={"loc": (0, 0.035, 0)})
    down = P(spine={"rot": (40, 0, 0)}, chest={"rot": (4, 0, 0), "scale": M.squash(0.86)}, head={"rot": (-22, 0, 0)}, hips={"loc": (0, -0.11, 0.03)},
             upper_arm__L={"rot": (40, 0, 28)}, upper_arm__R={"rot": (40, 0, -28)}, forearm__L={"rot": (4, 0, 0)}, forearm__R={"rot": (4, 0, 0)}, cape={"rot": (14, 0, 0)})
    cs.key(0.0, P(hips={"loc": (0, -0.04, 0)}, upper_arm__L={"rot": (40, 0, 20)}, upper_arm__R={"rot": (40, 0, -20)}), "out") \
      .key(0.11, up, "out").key(0.135, up2, "linear").key(0.16, down, "in") \
      .key(0.34, M.merge(down, spine={"rot": (34, 0, 0)}, chest={"rot": (4, 0, 0), "scale": M.squash(0.94)}, hips={"loc": (0, -0.09, 0.03)}), "out") \
      .key(0.6, P(), "inout")
    secondary(cs, head=0.05, arms=0.05)
    plant(cs, lf=[(0.0, 0, 0, 0), toes(0.1, LEG_L, 20), toes(0.14, LEG_L, 30), (0.17, 0, 0, 0)],
          rf=[(0.0, 0, 0, 0), toes(0.1, LEG_R, 20), toes(0.14, LEG_R, 30), (0.17, 0, 0, 0)])
    out.append(cs)

    cr = M.Clip("cast_raise", 0.62)
    crouch = P(spine={"rot": (14, 0, 0)}, chest={"scale": M.squash(0.93)}, hips={"loc": (0, -0.06, 0)},
               upper_arm__L={"rot": (6, 0, 22)}, upper_arm__R={"rot": (8, 0, -22)}, head={"rot": (4, 0, 0)})
    raised = P(spine={"rot": (-12, 0, 0)}, chest={"rot": (-4, 0, 0), "scale": M.squash(1.08)}, head={"rot": (-24, 0, 0)},
               hips={"loc": (0, 0.02, 0)}, upper_arm__L={"rot": (174, 0, 24)}, upper_arm__R={"rot": (172, 0, -24)},
               forearm__L={"rot": (0, 0, 0)}, forearm__R={"rot": (0, 0, 0)}, hand__L={"rot": (-20, 0, 0)}, cape={"rot": (-24, 0, 0)})
    cr.key(0.0, P(), "out").key(0.07, crouch, "out").key(0.12, raised, "snap") \
      .key(0.38, M.merge(raised, spine={"rot": (-9, 0, 0)}, chest={"rot": (-3, 0, 0), "scale": M.squash(1.03)}, upper_arm__L={"rot": (166, 0, 26)}, upper_arm__R={"rot": (164, 0, -26)}), "out") \
      .key(0.62, P(), "inout")
    secondary(cr, head=0.06, arms=0.06)
    plant(cr, lf=[(0.0, 0, 0, 0), (0.08, 0, 0, 0), toes(0.13, LEG_L, 26), toes(0.36, LEG_L, 16), (0.46, 0, 0, 0)],
          rf=[(0.0, 0, 0, 0), (0.08, 0, 0, 0), toes(0.13, LEG_R, 26), toes(0.36, LEG_R, 16), (0.46, 0, 0, 0)])
    out.append(cr)

    sw = M.Clip("cast_sweep", 0.5)
    wind = P(spine={"rot": (4, -26, 0)}, chest={"rot": (0, -10, 0)}, hips={"loc": (0, -0.03, 0), "rot": (0, -8, 0)},
             upper_arm__L={"rot": (80, 62, 6)}, forearm__L={"rot": (22, 0, 0)}, head={"rot": (-8, 10, 0)})
    wind2 = M.merge(wind, spine={"rot": (3, -31, 0)}, upper_arm__L={"rot": (80, 72, 6)})
    through = P(spine={"rot": (9, 26, 0)}, chest={"rot": (0, 10, 0)}, hips={"loc": (0, -0.045, 0.02), "rot": (0, 8, 0)},
                upper_arm__L={"rot": (86, -72, 10)}, forearm__L={"rot": (4, 0, 0)}, hand__L={"rot": (-20, 0, 0)}, head={"rot": (-9, -6, 0)})
    over = M.merge(through, spine={"rot": (10, 32, 0)}, upper_arm__L={"rot": (84, -84, 10)})
    sw.key(0.0, wind, "out").key(0.05, wind2, "out").key(0.09, through, "in").key(0.13, over, "out") \
      .key(0.3, M.merge(through, spine={"rot": (8, 22, 0)}), "out").key(0.5, P(), "inout")
    secondary(sw)
    plant(sw)
    out.append(sw)

    sp = M.Clip("cast_spin", 0.56)
    arms_out = dict(upper_arm__L={"rot": (10, 0, 84)}, upper_arm__R={"rot": (10, 0, -84)},
                    forearm__L={"rot": (0, 0, 0)}, forearm__R={"rot": (4, 0, 0)})
    sp.key(0.0, P(root={"rot": (0, 0, 0)}, hips={"loc": (0, -0.03, 0)}, **arms_out), "out") \
      .key(0.07, P(root={"rot": (0, -28, 0)}, hips={"loc": (0, -0.06, 0)}, spine={"rot": (8, -10, 0)}, **arms_out), "out") \
      .key(0.12, P(root={"rot": (0, 70, 0)}, hips={"loc": (0, -0.04, 0)}, spine={"rot": (6, 8, 0)}, cape={"rot": (-50, 0, 0)}, **arms_out), "in") \
      .key(0.26, P(root={"rot": (0, 250, 0)}, hips={"loc": (0, -0.04, 0)}, spine={"rot": (6, 8, 0)}, cape={"rot": (-55, 0, 0)}, **arms_out), "linear") \
      .key(0.38, P(root={"rot": (0, 378, 0)}, hips={"loc": (0, -0.035, 0)}, spine={"rot": (6, 4, 0)}, **arms_out), "out") \
      .key(0.56, P(root={"rot": (0, 360, 0)}), "inout")
    secondary(sp, head=0.05, arms=0.05)
    plant(sp)
    out.append(sp)

    bl = M.Clip("cast_blink", 0.36)
    low = P(hips={"loc": (0, -0.08, 0)}, spine={"rot": (28, 0, 0)}, root={"scale": M.squash(0.8)},
            upper_arm__L={"rot": (-40, 0, 20)}, upper_arm__R={"rot": (-40, 0, -20)}, head={"rot": (6, 0, 0)})
    pop = P(hips={"loc": (0, 0.02, 0)}, spine={"rot": (-8, 0, 0)}, root={"scale": M.squash(1.28)},
            upper_arm__L={"rot": (60, 0, 52)}, upper_arm__R={"rot": (60, 0, -52)}, head={"rot": (-16, 0, 0)})
    bl.key(0.0, M.merge(low, root={"scale": M.squash(0.9)}), "out").key(0.06, low, "out").key(0.08, pop, "snap") \
      .key(0.2, M.merge(pop, root={"scale": M.squash(0.95)}), "out").key(0.36, P(), "inout")
    secondary(bl, head=0.04, arms=0.05)
    bl_l, bl_r = M.planted(LEG_L), M.planted(LEG_R)
    bl.ik[LEG_L] = lambda t, p: None if 0.07 < t < 0.2 else bl_l(t, p)
    bl.ik[LEG_R] = lambda t, p: None if 0.07 < t < 0.2 else bl_r(t, p)
    out.append(bl)

    # --- reactions
    hit = M.Clip("hit", 0.4)
    recoil = P(spine={"rot": (-24, 0, 6)}, chest={"rot": (-4, 0, 3), "scale": M.squash(1.05)}, head={"rot": (-20, 0, 6)},
               hips={"loc": (0, -0.03, -0.04)}, upper_arm__L={"rot": (-14, 0, 44)}, upper_arm__R={"rot": (0, 0, -40)}, cape={"rot": (16, 0, 0)})
    hit.key(0.0, recoil, "linear").key(0.08, M.merge(recoil, spine={"rot": (-28, 0, 7)}, hips={"loc": (0, -0.045, -0.05)}), "out") \
       .key(0.2, P(spine={"rot": (11, 0, -2)}, chest={"scale": M.squash(0.97)}, hips={"loc": (0, -0.035, 0)}), "inout") \
       .key(0.4, P(), "inout")
    secondary(hit, head=0.05, arms=0.05)
    plant(hit)
    out.append(hit)

    kneel = P(hips={"loc": (0, -0.2, 0)}, spine={"rot": (40, 0, 0)}, head={"rot": (35, 0, 0)},
              thigh__L={"rot": (95, 0, 0)}, shin__L={"rot": (-125, 0, 0)}, thigh__R={"rot": (90, 0, 0)}, shin__R={"rot": (-120, 0, 0)},
              upper_arm__L={"rot": (12, 0, 6)}, forearm__L={"rot": (10, 0, 0)}, upper_arm__R={"rot": (18, 0, -6)}, forearm__R={"rot": (20, 0, 0)}, cape={"rot": (20, 0, 0)})
    dn = M.Clip("downed", 1.0)
    dn.key(0.0, P(), "linear") \
      .key(0.14, P(hips={"loc": (0, -0.06, -0.03)}, spine={"rot": (-18, 0, 4)}, head={"rot": (-26, 0, 4)}, upper_arm__L={"rot": (-12, 0, 44)}, upper_arm__R={"rot": (-12, 0, -44)}), "out") \
      .key(0.26, P(hips={"loc": (0, -0.08, -0.02)}, spine={"rot": (-10, 0, 2)}, head={"rot": (-16, 0, 0)}), "inout") \
      .key(0.5, M.merge(kneel, hips={"loc": (0, -0.215, 0)}, spine={"rot": (46, 0, 0), "scale": M.squash(0.9)}, head={"rot": (44, 0, 0)}), "in") \
      .key(0.72, kneel, "out").key(1.0, M.merge(kneel, spine={"rot": (42, 0, 0)}), "inout")
    secondary(dn, head=0.08, arms=0.1)
    out.append(dn)

    rv = M.Clip("revive", 0.72)
    rv.key(0.0, kneel, "linear") \
      .key(0.2, P(hips={"loc": (0, -0.12, 0)}, spine={"rot": (24, 0, 0)}, chest={"scale": M.squash(0.92)},
                  thigh__L={"rot": (55, 0, 0)}, shin__L={"rot": (-80, 0, 0)}, thigh__R={"rot": (45, 0, 0)}, shin__R={"rot": (-70, 0, 0)}), "out") \
      .key(0.34, P(root={"loc": (0, 0.05, 0), "scale": M.squash(1.1)}, hips={"loc": (0, 0.02, 0)}, spine={"rot": (-12, 0, 0)}, head={"rot": (-22, 0, 0)},
                   upper_arm__L={"rot": (164, 0, 30)}, upper_arm__R={"rot": (164, 0, -30)}), "snap") \
      .key(0.46, P(root={"scale": M.squash(0.93)}, hips={"loc": (0, -0.05, 0)}, spine={"rot": (6, 0, 0)},
                   upper_arm__L={"rot": (60, 0, 40)}, upper_arm__R={"rot": (60, 0, -40)}), "in") \
      .key(0.72, P(), "out")
    secondary(rv, head=0.06, arms=0.08)
    out.append(rv)

    vi = M.Clip("victory", 1.4)
    vi.key(0.0, P(), "linear") \
      .key(0.12, P(hips={"loc": (0, -0.06, 0)}, spine={"rot": (16, 0, 0)}, chest={"scale": M.squash(0.92)},
                   upper_arm__R={"rot": (30, 0, -10)}, forearm__R={"rot": (60, 0, 0)}, upper_arm__L={"rot": (-10, 0, 20)}), "out") \
      .key(0.28, P(root={"loc": (0, 0.14, 0), "scale": M.squash(1.12)}, spine={"rot": (-10, 0, 0)}, head={"rot": (-18, 0, 0)},
                   upper_arm__R={"rot": (170, 0, -8)}, forearm__R={"rot": (4, 0, 0)}, upper_arm__L={"rot": (24, 0, 44)},
                   thigh__L={"rot": (30, 0, 0)}, shin__L={"rot": (-60, 0, 0)}, thigh__R={"rot": (-10, 0, 0)}, shin__R={"rot": (-40, 0, 0)}), "snap") \
      .key(0.44, P(root={"scale": M.squash(0.9)}, hips={"loc": (0, -0.05, 0)}, spine={"rot": (-4, 0, 0)}, head={"rot": (-14, 0, 0)},
                   upper_arm__R={"rot": (166, 0, -8)}, forearm__R={"rot": (6, 0, 0)}, upper_arm__L={"rot": (18, 0, 36)}), "in") \
      .key(0.62, P(spine={"rot": (-6, 0, 0)}, head={"rot": (-14, 0, 0)}, upper_arm__R={"rot": (166, 0, -8)}, forearm__R={"rot": (6, 0, 0)}, upper_arm__L={"rot": (16, 0, 34)}), "out") \
      .key(1.4, P(spine={"rot": (-7, 0, 0)}, head={"rot": (-12, 0, 0)}, upper_arm__R={"rot": (164, 0, -8)}, forearm__R={"rot": (6, 0, 0)}, upper_arm__L={"rot": (16, 0, 30)}), "inout")
    secondary(vi, head=0.06, arms=0.08)
    # airborne between 0.18 and 0.42: IK only while grounded
    grounded = M.planted(LEG_L)
    grounded_r = M.planted(LEG_R)
    vi.ik[LEG_L] = lambda t, p: None if 0.16 < t < 0.42 else grounded(t, p)
    vi.ik[LEG_R] = lambda t, p: None if 0.16 < t < 0.42 else grounded_r(t, p)
    out.append(vi)
    return out


def animate_all(arm):
    for clip in clips():
        L.bake_clip(arm, clip)


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
