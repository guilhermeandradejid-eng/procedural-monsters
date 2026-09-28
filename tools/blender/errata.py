"""The Errata: living ink and paper escaped from the Grimoire's margins.

Blot (ink slime), Scribbler (paper wraith caster), Wax Brute (candle golem),
Paper Moth (origami flyer), Inkpot (mortar) and the boss, the Binder."""

import math

import lib as L


def P(base=None, **over):
    p = {k: dict(v) for k, v in (base or {}).items()}
    for k, v in over.items():
        p[k.replace("__", ".")] = v
    return p


def mats():
    return {
        "ink": L.material("InkGloss", "1b1a2e", 0.25),
        "ink_matte": L.material("Ink", "1c1411", 0.9),
        "paper": L.material("Paper", "f1e6c8", 0.9),
        "paper_old": L.material("PaperOld", "d9c49a", 0.9),
        "eyes": L.material("Eyes", "ffd06a", 0.4, 0.0, "ffb347", 5.0),
        "eye_white": L.material("EyeWhite", "f7eedb", 0.5),
        "violet": L.material("GlowViolet", "c08cff", 0.4, 0.0, "a060ff", 5.0),
        "cyan": L.material("GlowCyan", "7fe3ff", 0.4, 0.0, "4cc3e8", 5.0),
        "wax": L.material("Wax", "ead8ae", 0.6),
        "wax_dark": L.material("WaxDark", "c9a878", 0.7),
        "quill": L.material("Quill", "f3ead8", 0.8),
        "nib": L.material("Nib", "d9b25a", 0.3, 0.9),
        "trim": L.material("Trim", "c9a15b", 0.35, 0.8),
        "metal": L.material("Metal", "7d8589", 0.45, 0.6),
        "rubric": L.material("Rubric", "9e2b25", 0.8),
        "cover": L.material("Cover", "7a1f1a", 0.7),
        "cover_blue": L.material("CoverBlue", "2d4a6b", 0.7),
        "cover_green": L.material("CoverGreen", "3f5a2b", 0.7),
        "leather": L.material("Leather", "5b3a26", 0.8),
    }


# ---------------------------------------------------------------------------
# Blot — the ink slime
# ---------------------------------------------------------------------------

def build_blot(out, pv):
    L.reset()
    m = mats()
    arm = L.armature("BlotRig", [
        ("root", (0, 0, 0), (0, 0, 0.1), None),
        ("body", (0, 0, 0.02), (0, 0, 0.5), "root"),
    ])
    parts = []
    body = L.sphere("blob", 1.0, loc=(0, 0, 0.3), scale=(0.44, 0.42, 0.34), segs=20, rings=12, mat=m["ink"])
    L.jitter(body, 0.018, 7)
    parts.append((body, "body"))
    skirt = L.lathe("skirt", [(0.0, 0.0), (0.52, 0.0), (0.5, 0.03), (0.42, 0.1), (0.3, 0.16), (0.0, 0.16)], segs=20, mat=m["ink"])
    L.jitter(skirt, 0.035, 11)
    parts.append((skirt, "body"))
    for i, (x, r) in enumerate(((0.13, 0.105), (-0.12, 0.085))):
        parts.append((L.sphere("eye%d" % i, r, loc=(x, -0.3, 0.44), segs=12, rings=8, mat=m["eye_white"]), "body"))
        parts.append((L.sphere("pupil%d" % i, r * 0.48, loc=(x * 0.95, -0.3 - r * 0.78, 0.43), segs=8, rings=6, mat=m["ink_matte"]), "body"))
    teeth = []
    n = 6
    for i in range(n + 1):
        x = -0.14 + 0.28 * i / n
        teeth.append((x, 0.0 if i % 2 == 0 else -0.045))
    teeth += [(0.14, 0.02), (-0.14, 0.02)]
    parts.append((L.extrude_shape("teeth", teeth, depth=0.03, loc=(0, -0.405, 0.23), rot=(96, 0, 0), mat=m["eye_white"]), "body"))
    scrap = L.box("scrap", (0.14, 0.1, 0.008), loc=(0.08, 0.02, 0.63), rot=(20, -25, 30), mat=m["paper"])
    parts.append((scrap, "body"))
    L.rigid_parts(parts, arm, "Blot")
    A = L.animate
    A(arm, "idle", [(0.0, {"body": {}}), (0.5, {"body": {"scale": (1.06, 0.93, 1.06)}}), (1.0, {"body": {}})])
    A(arm, "move", [
        (0.0, {"body": {"scale": (1.2, 0.75, 1.2)}}),
        (0.08, {"body": {"scale": (0.85, 1.25, 0.85), "loc": (0, 0.2, 0)}}),
        (0.22, {"body": {"scale": (0.96, 1.08, 0.96), "loc": (0, 0.42, 0)}}),
        (0.38, {"body": {"scale": (0.9, 1.15, 0.9), "loc": (0, 0.14, 0)}}),
        (0.46, {"body": {"scale": (1.2, 0.75, 1.2)}}),
    ])
    A(arm, "attack", [
        (0.0, {"body": {"rot": (-18, 0, 0), "scale": (1.15, 0.85, 1.15)}}),
        (0.32, {"body": {"rot": (-24, 0, 0), "scale": (1.22, 0.78, 1.22)}}),
        (0.42, {"body": {"rot": (28, 0, 0), "scale": (0.82, 1.25, 0.82), "loc": (0, 0.12, 0)}}),
        (0.55, {"body": {"rot": (12, 0, 0), "scale": (1.2, 0.84, 1.2)}}),
        (0.75, {"body": {}}),
    ])
    A(arm, "hit", [(0.0, {"body": {"scale": (1.3, 0.7, 1.3)}}), (0.2, {"body": {}})])
    A(arm, "death", [
        (0.0, {"body": {}}),
        (0.12, {"body": {"scale": (0.8, 1.3, 0.8), "loc": (0, 0.1, 0)}}),
        (0.45, {"body": {"scale": (1.9, 0.06, 1.9)}}),
    ])
    if pv:
        L.preview(pv + "/blot.png", target=(0, 0, 0.3), dist=2.2)
    L.export_glb(out + "/blot.glb", [arm])


# ---------------------------------------------------------------------------
# Scribbler — floating paper wraith with a quill; casts procedural spells
# ---------------------------------------------------------------------------

def build_scribbler(out, pv):
    L.reset()
    m = mats()
    arm = L.armature("ScribRig", [
        ("root", (0, 0, 0), (0, 0, 0.15), None),
        ("body", (0, 0, 0.25), (0, 0, 0.9), "root"),
        ("head", (0, 0, 0.9), (0, 0, 1.35), "body"),
        ("arm.L", (0.24, 0, 0.86), (0.3, 0, 0.5), "body"),
        ("arm.R", (-0.24, 0, 0.86), (-0.3, 0, 0.5), "body"),
    ])
    parts = []
    cloak = L.lathe("cloak", [(0.0, 0.22), (0.3, 0.22), (0.34, 0.3), (0.28, 0.55), (0.2, 0.8), (0.14, 0.95), (0.0, 0.98)], segs=14, mat=m["paper"], smooth=False)
    L.jitter(cloak, 0.03, 5)
    parts.append((cloak, "body"))
    for i in range(7):
        a = 2 * math.pi * i / 7 + 0.3
        x, y = math.cos(a) * 0.27, math.sin(a) * 0.27
        strip = L.extrude_shape("rag%d" % i, [(-0.05, 0), (0.05, 0), (0.0, -0.16 - 0.06 * (i % 3))], depth=0.012,
                                loc=(x, y, 0.24), rot=(90, 0, math.degrees(a) + 90), mat=m["paper_old"])
        parts.append((strip, "body"))
    hood = L.sphere("hood", 1.0, loc=(0, 0.02, 1.12), scale=(0.24, 0.24, 0.26), segs=14, rings=8, mat=m["paper"], smooth=False)
    L.jitter(hood, 0.02, 9)
    parts.append((hood, "head"))
    face = L.sphere("face", 1.0, loc=(0, -0.16, 1.1), scale=(0.16, 0.08, 0.18), segs=12, rings=8, mat=m["ink_matte"])
    parts.append((face, "head"))
    parts.append((L.sphere("eye", 0.06, loc=(0, -0.235, 1.12), segs=10, rings=6, mat=m["violet"]), "head"))
    tip = L.cone("hoodtip", 0.08, 0.0, 0.3, loc=(0, 0.14, 1.36), rot=(-40, 0, 0), mat=m["paper"], segs=8, smooth=False)
    parts.append((tip, "head"))
    for side, sx in (("L", 1), ("R", -1)):
        limb = L.cone("arm" + side, 0.05, 0.035, 0.38, loc=(0.27 * sx, 0, 0.68), rot=(0, -8 * sx, 0), mat=m["paper_old"], segs=6, smooth=False)
        parts.append((limb, "arm." + side))
        hand = L.sphere("hand" + side, 0.06, loc=(0.3 * sx, 0, 0.48), segs=8, rings=6, mat=m["ink"])
        parts.append((hand, "arm." + side))
    # Quill in the right hand, pointing down-forward like a wand.
    shaft = L.cone("qshaft", 0.018, 0.01, 0.55, loc=(-0.31, -0.1, 0.38), rot=(-60, 0, 0), mat=m["quill"], segs=6)
    vane = L.extrude_shape("qvane", [(0.0, 0.0), (0.06, 0.15), (0.05, 0.35), (0.0, 0.45), (-0.03, 0.3), (-0.04, 0.12)], depth=0.01,
                           loc=(-0.31, 0.05, 0.62), rot=(30, 90, 0), mat=m["quill"])
    nib = L.cone("qnib", 0.02, 0.0, 0.08, loc=(-0.31, -0.33, 0.25), rot=(-60, 0, 0), mat=m["nib"], segs=6)
    for ob in (shaft, vane, nib):
        parts.append((ob, "arm.R"))
    L.rigid_parts(parts, arm, "Scribbler")
    A = L.animate
    A(arm, "idle", [
        (0.0, {"root": {"loc": (0, 0.0, 0)}, "arm.L": {"rot": (0, 0, 10)}, "arm.R": {"rot": (10, 0, -10)}}),
        (0.9, {"root": {"loc": (0, 0.08, 0)}, "body": {"rot": (3, 0, 2)}, "head": {"rot": (-6, 0, -3)}, "arm.L": {"rot": (8, 0, 16)}, "arm.R": {"rot": (14, 0, -14)}}),
        (1.8, {"root": {"loc": (0, 0.0, 0)}, "arm.L": {"rot": (0, 0, 10)}, "arm.R": {"rot": (10, 0, -10)}}),
    ])
    A(arm, "move", [
        (0.0, {"root": {"loc": (0, 0.02, 0)}, "body": {"rot": (16, 0, 0)}, "head": {"rot": (-10, 0, 0)}, "arm.L": {"rot": (-30, 0, 20)}, "arm.R": {"rot": (-30, 0, -20)}}),
        (0.4, {"root": {"loc": (0, 0.1, 0)}, "body": {"rot": (20, 0, 0)}, "head": {"rot": (-12, 0, 0)}, "arm.L": {"rot": (-40, 0, 26)}, "arm.R": {"rot": (-40, 0, -26)}}),
        (0.8, {"root": {"loc": (0, 0.02, 0)}, "body": {"rot": (16, 0, 0)}, "head": {"rot": (-10, 0, 0)}, "arm.L": {"rot": (-30, 0, 20)}, "arm.R": {"rot": (-30, 0, -20)}}),
    ])
    A(arm, "cast", [
        (0.0, {"arm.R": {"rot": (10, 0, -10)}}),
        (0.35, {"body": {"rot": (-10, 0, 0)}, "head": {"rot": (-14, 0, 0)}, "arm.R": {"rot": (160, 0, -20)}, "arm.L": {"rot": (60, 0, 40)}, "root": {"loc": (0, 0.12, 0)}}),
        (0.5, {"body": {"rot": (-12, 0, 0)}, "head": {"rot": (-16, 0, 0)}, "arm.R": {"rot": (166, 0, -20)}, "arm.L": {"rot": (64, 0, 42)}, "root": {"loc": (0, 0.14, 0)}}),
        (0.6, {"body": {"rot": (22, 0, 0)}, "head": {"rot": (8, 0, 0)}, "arm.R": {"rot": (70, 0, -6)}, "arm.L": {"rot": (-10, 0, 20)}}),
        (0.95, {"arm.R": {"rot": (10, 0, -10)}}),
    ])
    A(arm, "hit", [(0.0, {"body": {"rot": (-20, 0, 8)}, "head": {"rot": (-18, 0, 0)}, "root": {"scale": (1.1, 0.9, 1.1)}}), (0.25, {})])
    A(arm, "death", [
        (0.0, {}),
        (0.2, {"body": {"rot": (-25, 0, 20)}, "root": {"loc": (0, 0.2, 0)}}),
        (0.7, {"body": {"rot": (60, 30, 60)}, "root": {"scale": (0.3, 0.1, 0.3)}}),
    ])
    if pv:
        L.preview(pv + "/scribbler.png", target=(0, 0, 0.7), dist=3.2)
    L.export_glb(out + "/scribbler.glb", [arm])


# ---------------------------------------------------------------------------
# Wax Brute — melting candle golem, slow, slams
# ---------------------------------------------------------------------------

def build_brute(out, pv):
    L.reset()
    m = mats()
    arm = L.armature("BruteRig", [
        ("root", (0, 0, 0), (0, 0, 0.2), None),
        ("hips", (0, 0, 0.35), (0, 0, 0.65), "root"),
        ("chest", (0, 0, 0.65), (0, 0, 1.3), "hips"),
        ("head", (0, 0, 1.3), (0, 0, 1.75), "chest"),
        ("flame", (0, 0, 1.9), (0, 0, 2.05), "head"),
        ("arm.L", (0.62, 0, 1.2), (0.7, 0, 0.8), "chest"),
        ("fore.L", (0.7, 0, 0.8), (0.72, 0, 0.42), "arm.L"),
        ("arm.R", (-0.62, 0, 1.2), (-0.7, 0, 0.8), "chest"),
        ("fore.R", (-0.7, 0, 0.8), (-0.72, 0, 0.42), "arm.R"),
        ("leg.L", (0.24, 0, 0.4), (0.24, 0, 0.02), "hips"),
        ("leg.R", (-0.24, 0, 0.4), (-0.24, 0, 0.02), "hips"),
    ])
    parts = []
    body = L.lathe("body", [(0.0, 0.35), (0.5, 0.35), (0.54, 0.5), (0.52, 0.9), (0.5, 1.3), (0.52, 1.5), (0.5, 1.7), (0.4, 1.76), (0.0, 1.72)], segs=18, mat=m["wax"])
    L.jitter(body, 0.025, 4)
    parts.append((body, "chest"))
    pelvis = L.lathe("pelvis", [(0.0, 0.3), (0.46, 0.3), (0.5, 0.42), (0.48, 0.6), (0.0, 0.6)], segs=16, mat=m["wax_dark"])
    parts.append((pelvis, "hips"))
    for i in range(9):
        a = 2 * math.pi * i / 9 + 0.2
        h = 0.18 + 0.12 * ((i * 37) % 5) / 4
        drip = L.sphere("drip%d" % i, 1.0, loc=(0.52 * math.cos(a), 0.52 * math.sin(a), 1.62 - h), scale=(0.07, 0.07, h), segs=8, rings=6, mat=m["wax"])
        parts.append((drip, "chest"))
    crater = L.lathe("crater", [(0.0, 1.66), (0.34, 1.7), (0.4, 1.76), (0.0, 1.76)], segs=16, mat=m["wax_dark"])
    parts.append((crater, "head"))
    parts.append((L.cone("wick", 0.03, 0.018, 0.22, loc=(0, 0, 1.82), mat=m["ink_matte"], segs=6), "head"))
    for sx in (1, -1):
        parts.append((L.sphere("socket%d" % sx, 1.0, loc=(0.17 * sx, -0.44, 1.38), scale=(0.11, 0.08, 0.12), segs=10, rings=6, mat=m["ink_matte"]), "head"))
        parts.append((L.sphere("ember%d" % sx, 0.05, loc=(0.17 * sx, -0.5, 1.38), segs=8, rings=6, mat=m["eyes"]), "head"))
    mouth = [(-0.2, 0.0), (-0.1, 0.05), (0.0, 0.0), (0.1, 0.05), (0.2, 0.0), (0.12, -0.08), (-0.12, -0.08)]
    parts.append((L.extrude_shape("mouth", mouth, depth=0.08, loc=(0, -0.47, 1.12), rot=(92, 0, 0), mat=m["ink_matte"]), "head"))
    for side, sx in (("L", 1), ("R", -1)):
        parts.append((L.sphere("shoulder" + side, 0.26, loc=(0.62 * sx, 0, 1.15), segs=12, rings=8, mat=m["wax"]), "arm." + side))
        parts.append((L.sphere("elbow" + side, 0.2, loc=(0.7 * sx, 0, 0.8), segs=10, rings=8, mat=m["wax_dark"]), "arm." + side))
        fist = L.sphere("fist" + side, 1.0, loc=(0.72 * sx, -0.04, 0.42), scale=(0.3, 0.3, 0.27), segs=12, rings=8, mat=m["wax"])
        L.jitter(fist, 0.03, 13 if sx > 0 else 17)
        parts.append((fist, "fore." + side))
        parts.append((L.cone("fore" + side, 0.18, 0.22, 0.34, loc=(0.71 * sx, 0, 0.62), mat=m["wax"], segs=10), "fore." + side))
        parts.append((L.cone("leg" + side, 0.2, 0.24, 0.36, loc=(0.24 * sx, 0, 0.2), mat=m["wax_dark"], segs=10), "leg." + side))
        parts.append((L.sphere("foot" + side, 1.0, loc=(0.24 * sx, -0.08, 0.06), scale=(0.24, 0.3, 0.1), segs=10, rings=6, mat=m["wax_dark"]), "leg." + side))
    band = L.torus("band", 0.53, 0.035, loc=(0, 0, 0.95), mat=m["metal"], seg_major=24, seg_minor=6)
    parts.append((band, "chest"))
    L.rigid_parts(parts, arm, "WaxBrute")
    A = L.animate
    base = {"arm.L": {"rot": (6, 0, 8)}, "arm.R": {"rot": (6, 0, -8)}, "fore.L": {"rot": (20, 0, 0)}, "fore.R": {"rot": (20, 0, 0)}}
    A(arm, "idle", [
        (0.0, P(base)),
        (1.1, P(base, chest={"rot": (4, 0, 0), "scale": (1.02, 0.98, 1.02)}, head={"rot": (-4, 0, 0)}, arm__L={"rot": (10, 0, 12)}, arm__R={"rot": (10, 0, -12)})),
        (2.2, P(base)),
    ])
    A(arm, "move", [
        (0.0, P(base, hips={"rot": (0, 10, 6)}, leg__L={"rot": (28, 0, 0)}, leg__R={"rot": (-24, 0, 0)}, arm__L={"rot": (-18, 0, 8)}, arm__R={"rot": (24, 0, -8)}, root={"loc": (0, 0, 0)})),
        (0.25, P(base, hips={"rot": (0, 0, 0)}, leg__L={"rot": (0, 0, 0)}, leg__R={"rot": (8, 0, 0)}, root={"loc": (0, 0.06, 0)})),
        (0.5, P(base, hips={"rot": (0, -10, -6)}, leg__R={"rot": (28, 0, 0)}, leg__L={"rot": (-24, 0, 0)}, arm__R={"rot": (-18, 0, -8)}, arm__L={"rot": (24, 0, 8)}, root={"loc": (0, 0, 0)})),
        (0.75, P(base, hips={"rot": (0, 0, 0)}, leg__R={"rot": (0, 0, 0)}, leg__L={"rot": (8, 0, 0)}, root={"loc": (0, 0.06, 0)})),
        (1.0, P(base, hips={"rot": (0, 10, 6)}, leg__L={"rot": (28, 0, 0)}, leg__R={"rot": (-24, 0, 0)}, arm__L={"rot": (-18, 0, 8)}, arm__R={"rot": (24, 0, -8)}, root={"loc": (0, 0, 0)})),
    ])
    windup = P(base, chest={"rot": (-18, 0, 0)}, head={"rot": (-12, 0, 0)}, arm__L={"rot": (165, 0, 20)}, arm__R={"rot": (165, 0, -20)}, fore__L={"rot": (30, 0, 0)}, fore__R={"rot": (30, 0, 0)}, root={"loc": (0, 0.1, 0)})
    slam = P(base, chest={"rot": (38, 0, 0)}, head={"rot": (-20, 0, 0)}, arm__L={"rot": (70, 0, 20)}, arm__R={"rot": (70, 0, -20)}, fore__L={"rot": (10, 0, 0)}, fore__R={"rot": (10, 0, 0)}, hips={"loc": (0, -0.12, 0)}, leg__L={"rot": (20, 0, 8)}, leg__R={"rot": (20, 0, -8)})
    A(arm, "slam", [(0.0, P(base)), (0.55, windup), (0.7, windup), (0.8, slam), (1.1, slam), (1.45, P(base))])
    A(arm, "hit", [(0.0, P(base, chest={"rot": (-10, 0, 6)}, head={"rot": (-10, 0, 0)})), (0.3, P(base))])
    A(arm, "death", [
        (0.0, P(base)),
        (0.3, P(base, chest={"rot": (10, 0, 10)}, head={"rot": (20, 0, 10)})),
        (1.1, P(base, root={"scale": (1.5, 0.18, 1.5)}, chest={"rot": (15, 0, 5)})),
    ])
    if pv:
        L.preview(pv + "/brute.png", target=(0, 0, 0.9), dist=5.0)
    L.export_glb(out + "/brute.glb", [arm])


# ---------------------------------------------------------------------------
# Paper Moth — origami flyer that dives
# ---------------------------------------------------------------------------

def build_moth(out, pv):
    L.reset()
    m = mats()
    arm = L.armature("MothRig", [
        ("root", (0, 0, 0), (0, 0, 0.2), None),
        ("body", (0, 0.15, 1.1), (0, -0.25, 1.1), "root"),
        ("wing.L1", (0.05, -0.05, 1.12), (0.55, -0.1, 1.12), "body"),
        ("wing.L2", (0.05, 0.08, 1.1), (0.45, 0.22, 1.1), "body"),
        ("wing.R1", (-0.05, -0.05, 1.12), (-0.55, -0.1, 1.12), "body"),
        ("wing.R2", (-0.05, 0.08, 1.1), (-0.45, 0.22, 1.1), "body"),
    ])
    parts = []
    thorax = L.ico("thorax", 1.0, loc=(0, 0.0, 1.1), scale=(0.1, 0.3, 0.1), subdiv=1, mat=m["paper"])
    parts.append((thorax, "body"))
    head = L.ico("mhead", 0.1, loc=(0, -0.3, 1.12), subdiv=1, mat=m["paper"])
    parts.append((head, "body"))
    for sx in (1, -1):
        parts.append((L.sphere("meye%d" % sx, 0.035, loc=(0.06 * sx, -0.37, 1.14), segs=8, rings=6, mat=m["eyes"]), "body"))
        ant = L.cone("ant%d" % sx, 0.01, 0.004, 0.3, loc=(0.08 * sx, -0.48, 1.27), rot=(-50, 0, -25 * sx), mat=m["ink_matte"], segs=5)
        parts.append((ant, "body"))
    for i in range(3):
        parts.append((L.box("stripe%d" % i, (0.21, 0.03, 0.21), loc=(0, 0.08 + 0.08 * i, 1.1), mat=m["ink_matte"]), "body"))
    # Folded wings: two triangles per wing with a crease; inked eye-spots.
    def wing(name, pts, bone, spot, z):
        w = L.extrude_shape(name, pts, depth=0.01, loc=(0, 0, z), mat=m["paper"])
        parts.append((w, bone))
        parts.append((L.cone(name + "spot", 0.06, 0.06, 0.014, loc=(spot[0], spot[1], z + 0.004), mat=m["rubric"], segs=12), bone))
        parts.append((L.cone(name + "spot2", 0.03, 0.03, 0.016, loc=(spot[0], spot[1], z + 0.006), mat=m["ink_matte"], segs=10), bone))
    for sx in (1, -1):
        s = "L" if sx > 0 else "R"
        wing("fw" + s, [(0.05 * sx, -0.12), (0.62 * sx, -0.22), (0.5 * sx, 0.1), (0.05 * sx, 0.05)], "wing.%s1" % s, (0.36 * sx, -0.08), 1.12)
        wing("hw" + s, [(0.05 * sx, 0.04), (0.42 * sx, 0.12), (0.34 * sx, 0.36), (0.04 * sx, 0.2)], "wing.%s2" % s, (0.25 * sx, 0.18), 1.1)
    L.rigid_parts(parts, arm, "PaperMoth")
    A = L.animate

    def flap(up):
        return {"wing.L1": {"rot": (0, 0, up)}, "wing.L2": {"rot": (0, 0, up * 0.8)}, "wing.R1": {"rot": (0, 0, -up)}, "wing.R2": {"rot": (0, 0, -up * 0.8)}}
    A(arm, "idle", [
        (0.0, P(flap(45), root={"loc": (0, 0.0, 0)})),
        (0.15, P(flap(-35), root={"loc": (0, 0.06, 0)})),
        (0.3, P(flap(45), root={"loc": (0, 0.0, 0)})),
    ])
    A(arm, "move", [
        (0.0, P(flap(50), body={"rot": (-10, 0, 0)})),
        (0.12, P(flap(-40), body={"rot": (-12, 0, 0)}, root={"loc": (0, 0.05, 0)})),
        (0.24, P(flap(50), body={"rot": (-10, 0, 0)})),
    ])
    dive = P(flap(-70), body={"rot": (-30, 0, 0)})
    A(arm, "attack", [(0.0, P(flap(60))), (0.2, dive), (0.6, dive), (0.8, P(flap(40)))])
    A(arm, "hit", [(0.0, P(flap(10), body={"rot": (20, 0, 20)})), (0.2, P(flap(40)))])
    A(arm, "death", [
        (0.0, P(flap(30))),
        (0.3, P(flap(80), body={"rot": (40, 20, 60)}, root={"loc": (0, -0.4, 0)})),
        (0.6, P(flap(85), body={"rot": (0, 0, 90)}, root={"loc": (0, -1.05, 0)})),
    ])
    if pv:
        L.preview(pv + "/moth.png", target=(0, 0, 1.1), dist=2.6, elevation=35)
    L.export_glb(out + "/moth.glb", [arm])


# ---------------------------------------------------------------------------
# Inkpot — a stationary mortar that lobs ink bombs
# ---------------------------------------------------------------------------

def build_inkpot(out, pv):
    L.reset()
    m = mats()
    arm = L.armature("PotRig", [
        ("root", (0, 0, 0), (0, 0, 0.1), None),
        ("pot", (0, 0, 0.02), (0, 0, 0.7), "root"),
        ("quill", (0, 0, 0.7), (0.1, 0, 1.4), "pot"),
    ])
    parts = []
    pot = L.lathe("pot", [(0.0, 0.0), (0.36, 0.0), (0.44, 0.08), (0.47, 0.3), (0.4, 0.5), (0.22, 0.58), (0.2, 0.68), (0.25, 0.72), (0.2, 0.74), (0.0, 0.74)], segs=20, mat=m["ink"])
    parts.append((pot, "pot"))
    label = L.lathe("label", [(0.475, 0.18), (0.485, 0.2), (0.485, 0.38), (0.465, 0.4)], segs=20, mat=m["paper_old"], cap_top=False, cap_bottom=False)
    parts.append((label, "pot"))
    parts.append((L.box("rubric", (0.06, 0.02, 0.12), loc=(0, -0.49, 0.29), mat=m["rubric"]), "pot"))
    for sx in (1, -1):
        parts.append((L.sphere("peye%d" % sx, 0.045, loc=(0.08 * sx, -0.14, 0.72), segs=8, rings=6, mat=m["cyan"]), "pot"))
    shaft = L.cone("pshaft", 0.022, 0.012, 0.8, loc=(0.06, 0.0, 0.98), rot=(0, 16, 0), mat=m["quill"], segs=6)
    vane = L.extrude_shape("pvane", [(0.0, 0.0), (0.08, 0.2), (0.07, 0.45), (0.0, 0.55), (-0.05, 0.4), (-0.06, 0.15)], depth=0.012,
                           loc=(0.13, 0.0, 1.05), rot=(90, -16, 90), mat=m["quill"])
    parts.append((shaft, "quill"))
    parts.append((vane, "quill"))
    L.rigid_parts(parts, arm, "Inkpot")
    A = L.animate
    A(arm, "idle", [(0.0, {"pot": {}}), (0.8, {"pot": {"scale": (1.03, 0.96, 1.03)}, "quill": {"rot": (4, 0, 3)}}), (1.6, {"pot": {}})])
    A(arm, "attack", [
        (0.0, {"pot": {}}),
        (0.35, {"pot": {"scale": (1.18, 0.8, 1.18)}, "quill": {"rot": (-14, 0, 0)}}),
        (0.45, {"pot": {"scale": (0.86, 1.25, 0.86)}, "quill": {"rot": (20, 0, 0)}}),
        (0.7, {"pot": {}}),
    ])
    A(arm, "hit", [(0.0, {"pot": {"scale": (1.2, 0.82, 1.2)}}), (0.2, {"pot": {}})])
    A(arm, "death", [(0.0, {"pot": {}}), (0.15, {"pot": {"scale": (1.3, 0.8, 1.3)}}), (0.5, {"pot": {"scale": (1.4, 0.3, 1.4), "rot": (0, 0, 20)}, "quill": {"rot": (60, 0, 30)}})])
    if pv:
        L.preview(pv + "/inkpot.png", target=(0, 0, 0.5), dist=2.6)
    L.export_glb(out + "/inkpot.glb", [arm])


# ---------------------------------------------------------------------------
# The Binder — boss: a golem of stacked tomes with chain arms
# ---------------------------------------------------------------------------

def build_binder(out, pv):
    L.reset()
    m = mats()
    arm = L.armature("BinderRig", [
        ("root", (0, 0, 0), (0, 0, 0.3), None),
        ("hips", (0, 0, 0.9), (0, 0, 1.3), "root"),
        ("spine", (0, 0, 1.3), (0, 0, 1.9), "hips"),
        ("chest", (0, 0, 1.9), (0, 0, 2.6), "spine"),
        ("head", (0, 0, 2.6), (0, 0, 3.3), "chest"),
        ("arm.L", (1.05, 0, 2.45), (1.25, 0, 1.75), "chest"),
        ("fore.L", (1.25, 0, 1.75), (1.35, 0, 1.05), "arm.L"),
        ("hand.L", (1.35, 0, 1.05), (1.38, 0, 0.6), "fore.L"),
        ("arm.R", (-1.05, 0, 2.45), (-1.25, 0, 1.75), "chest"),
        ("fore.R", (-1.25, 0, 1.75), (-1.35, 0, 1.05), "arm.R"),
        ("hand.R", (-1.35, 0, 1.05), (-1.38, 0, 0.6), "fore.R"),
        ("leg.L", (0.45, 0, 0.95), (0.48, 0, 0.45), "hips"),
        ("shin.L", (0.48, 0, 0.45), (0.5, 0, 0.02), "leg.L"),
        ("leg.R", (-0.45, 0, 0.95), (-0.48, 0, 0.45), "hips"),
        ("shin.R", (-0.48, 0, 0.45), (-0.5, 0, 0.02), "leg.R"),
    ])
    parts = []
    covers = [m["cover"], m["cover_blue"], m["cover_green"], m["cover"], m["cover_blue"]]

    def tome(name, size, loc, rot, cover, bone, pages_side=-1):
        w, d, h = size
        parts.append((L.box(name, (w, d, h), loc=loc, rot=rot, mat=cover, bevel=0.03), bone))
        # Page block visible on the front edge.
        px = loc[0]
        py = loc[1] + pages_side * (d / 2 - 0.04)
        parts.append((L.box(name + "pg", (w * 0.94, 0.09, h * 0.78), loc=(px, py, loc[2]), rot=rot, mat=m["paper"]), bone))
        for cx in (-1, 1):
            parts.append((L.box(name + "c%d" % cx, (0.14, 0.14, h * 1.04), loc=(loc[0] + cx * (w / 2 - 0.05), loc[1] - d / 2 + 0.05, loc[2]), rot=rot, mat=m["trim"]), bone))
    tome("hipbook", (1.5, 1.0, 0.42), (0, 0, 1.08), (0, 0, 3), covers[0], "hips")
    tome("waist", (1.25, 0.9, 0.36), (0.04, 0.02, 1.48), (0, 0, -6), covers[1], "spine")
    tome("belly", (1.4, 0.95, 0.4), (-0.03, 0, 1.86), (0, 0, 4), covers[2], "spine")
    tome("chest", (1.9, 1.05, 0.5), (0, 0, 2.3), (0, 0, -2), covers[3], "chest")
    # Lectern head with an open glowing book as its face.
    parts.append((L.box("lectern", (0.9, 0.7, 0.5), loc=(0, 0.05, 2.78), rot=(-18, 0, 0), mat=m["leather"], bevel=0.04), "head"))
    pages = L.box("openbook", (0.92, 0.55, 0.06), loc=(0, -0.22, 2.98), rot=(-40, 0, 0), mat=m["paper"], bevel=0.02)
    parts.append((pages, "head"))
    for sx in (1, -1):
        parts.append((L.sphere("beye%d" % sx, 0.08, loc=(0.2 * sx, -0.4, 3.12), segs=10, rings=6, mat=m["eyes"]), "head"))
    parts.append((L.box("ribbon", (0.06, 0.02, 0.5), loc=(0.22, -0.46, 2.72), rot=(-10, 0, 8), mat=m["rubric"]), "head"))
    # Chain arms ending in clasped book fists.
    for side, sx in (("L", 1), ("R", -1)):
        parts.append((L.sphere("pauldron" + side, 1.0, loc=(1.02 * sx, 0, 2.5), scale=(0.34, 0.34, 0.26), segs=12, rings=8, mat=m["metal"]), "arm." + side))
        for i in range(5):
            t = i / 5
            z = 2.35 - 0.62 * t
            x = (1.08 + 0.2 * t) * sx
            link = L.torus("link%s%d" % (side, i), 0.1, 0.035, loc=(x, 0, z), rot=(0 if i % 2 else 90, 90, 0), mat=m["metal"], seg_major=10, seg_minor=5)
            parts.append((link, "arm." + side))
        for i in range(5):
            t = i / 5
            z = 1.72 - 0.6 * t
            x = (1.27 + 0.1 * t) * sx
            link = L.torus("flink%s%d" % (side, i), 0.1, 0.035, loc=(x, 0, z), rot=(0 if i % 2 else 90, 90, 0), mat=m["metal"], seg_major=10, seg_minor=5)
            parts.append((link, "fore." + side))
        fist_cover = covers[4] if sx > 0 else covers[0]
        parts.append((L.box("fist" + side, (0.62, 0.5, 0.55), loc=(1.38 * sx, -0.02, 0.8), mat=fist_cover, bevel=0.04), "hand." + side))
        parts.append((L.box("fistpg" + side, (0.55, 0.42, 0.1), loc=(1.38 * sx, -0.02, 0.5), mat=m["paper"]), "hand." + side))
        parts.append((L.box("clasp" + side, (0.12, 0.56, 0.2), loc=(1.38 * sx, -0.02, 0.8), mat=m["trim"], bevel=0.02), "hand." + side))
        tome("thigh" + side, (0.55, 0.6, 0.45), (0.46 * sx, 0, 0.7), (0, 0, 8 * sx), m["cover_green"], "leg." + side)
        tome("shin" + side, (0.6, 0.7, 0.4), (0.49 * sx, -0.03, 0.22), (0, 0, -5 * sx), m["cover"], "shin." + side)
    L.rigid_parts(parts, arm, "Binder")
    A = L.animate
    base = {"arm.L": {"rot": (4, 0, 6)}, "arm.R": {"rot": (4, 0, -6)}, "fore.L": {"rot": (14, 0, 0)}, "fore.R": {"rot": (14, 0, 0)}}
    A(arm, "idle", [
        (0.0, P(base)),
        (1.4, P(base, chest={"rot": (4, 0, 0)}, head={"rot": (-6, 0, 3)}, spine={"rot": (0, 3, 0)}, arm__L={"rot": (8, 0, 9)}, arm__R={"rot": (8, 0, -9)})),
        (2.8, P(base)),
    ])
    A(arm, "move", [
        (0.0, P(base, leg__L={"rot": (26, 0, 0)}, shin__L={"rot": (-10, 0, 0)}, leg__R={"rot": (-22, 0, 0)}, shin__R={"rot": (-30, 0, 0)}, hips={"rot": (0, 8, 4)}, arm__L={"rot": (-14, 0, 6)}, arm__R={"rot": (20, 0, -6)})),
        (0.35, P(base, root={"loc": (0, 0.08, 0)}, leg__L={"rot": (0, 0, 0)}, leg__R={"rot": (10, 0, 0)}, shin__R={"rot": (-40, 0, 0)})),
        (0.7, P(base, leg__R={"rot": (26, 0, 0)}, shin__R={"rot": (-10, 0, 0)}, leg__L={"rot": (-22, 0, 0)}, shin__L={"rot": (-30, 0, 0)}, hips={"rot": (0, -8, -4)}, arm__R={"rot": (-14, 0, -6)}, arm__L={"rot": (20, 0, 6)})),
        (1.05, P(base, root={"loc": (0, 0.08, 0)}, leg__R={"rot": (0, 0, 0)}, leg__L={"rot": (10, 0, 0)}, shin__L={"rot": (-40, 0, 0)})),
        (1.4, P(base, leg__L={"rot": (26, 0, 0)}, shin__L={"rot": (-10, 0, 0)}, leg__R={"rot": (-22, 0, 0)}, shin__R={"rot": (-30, 0, 0)}, hips={"rot": (0, 8, 4)}, arm__L={"rot": (-14, 0, 6)}, arm__R={"rot": (20, 0, -6)})),
    ])
    up = P(base, chest={"rot": (-16, 0, 0)}, head={"rot": (-14, 0, 0)}, arm__L={"rot": (170, 0, 16)}, arm__R={"rot": (170, 0, -16)}, fore__L={"rot": (20, 0, 0)}, fore__R={"rot": (20, 0, 0)})
    down = P(base, chest={"rot": (36, 0, 0)}, spine={"rot": (10, 0, 0)}, head={"rot": (-24, 0, 0)}, arm__L={"rot": (62, 0, 14)}, arm__R={"rot": (62, 0, -14)}, fore__L={"rot": (6, 0, 0)}, fore__R={"rot": (6, 0, 0)}, hips={"loc": (0, -0.16, 0)}, leg__L={"rot": (22, 0, 6)}, shin__L={"rot": (-30, 0, 0)}, leg__R={"rot": (22, 0, -6)}, shin__R={"rot": (-30, 0, 0)})
    A(arm, "slam", [(0.0, P(base)), (0.6, up), (0.75, up), (0.88, down), (1.2, down), (1.6, P(base))])
    A(arm, "sweep", [
        (0.0, P(base)),
        (0.5, P(base, spine={"rot": (0, -35, 0)}, arm__R={"rot": (70, 90, -40)}, fore__R={"rot": (10, 0, 0)}, arm__L={"rot": (20, 0, 30)})),
        (0.65, P(base, spine={"rot": (0, -38, 0)}, arm__R={"rot": (72, 95, -40)}, fore__R={"rot": (8, 0, 0)}, arm__L={"rot": (20, 0, 30)})),
        (0.85, P(base, spine={"rot": (0, 40, 0)}, arm__R={"rot": (80, -80, -20)}, fore__R={"rot": (4, 0, 0)}, arm__L={"rot": (-10, 0, 24)})),
        (1.1, P(base, spine={"rot": (0, 36, 0)}, arm__R={"rot": (74, -76, -20)}, fore__R={"rot": (8, 0, 0)})),
        (1.5, P(base)),
    ])
    A(arm, "volley", [
        (0.0, P(base)),
        (0.4, P(base, chest={"rot": (-12, 0, 0)}, arm__L={"rot": (100, -20, 20)}, arm__R={"rot": (100, 20, -20)}, fore__L={"rot": (30, 0, 0)}, fore__R={"rot": (30, 0, 0)})),
        (0.55, P(base, chest={"rot": (18, 0, 0)}, arm__L={"rot": (88, 10, 30)}, arm__R={"rot": (88, -10, -30)}, fore__L={"rot": (0, 0, 0)}, fore__R={"rot": (0, 0, 0)})),
        (1.0, P(base)),
    ])
    A(arm, "summon", [
        (0.0, P(base)),
        (0.45, P(base, chest={"rot": (-20, 0, 0)}, head={"rot": (-25, 0, 0)}, arm__L={"rot": (150, 0, 50)}, arm__R={"rot": (150, 0, -50)})),
        (0.9, P(base, chest={"rot": (-22, 0, 0)}, head={"rot": (-28, 0, 0)}, arm__L={"rot": (155, 0, 55)}, arm__R={"rot": (155, 0, -55)})),
        (1.3, P(base)),
    ])
    A(arm, "roar", [
        (0.0, P(base)),
        (0.25, P(base, chest={"rot": (-24, 0, 0)}, head={"rot": (-30, 0, 0)}, arm__L={"rot": (40, 0, 60)}, arm__R={"rot": (40, 0, -60)})),
        (0.5, P(base, chest={"rot": (-26, 0, 4)}, head={"rot": (-32, 0, -4)}, arm__L={"rot": (44, 0, 64)}, arm__R={"rot": (44, 0, -64)})),
        (0.75, P(base, chest={"rot": (-24, 0, -4)}, head={"rot": (-30, 0, 4)}, arm__L={"rot": (40, 0, 60)}, arm__R={"rot": (40, 0, -60)})),
        (1.1, P(base)),
    ])
    A(arm, "hit", [(0.0, P(base, chest={"rot": (-10, 0, 5)}, head={"rot": (-12, 0, 0)})), (0.3, P(base))])
    A(arm, "death", [
        (0.0, P(base)),
        (0.4, P(base, chest={"rot": (-20, 0, 10)}, head={"rot": (-30, 0, 10)}, arm__L={"rot": (60, 0, 60)}, arm__R={"rot": (60, 0, -60)})),
        (1.2, P(base, root={"loc": (0, -0.6, 0), "rot": (25, 0, 8)}, chest={"rot": (30, 0, 12)}, head={"rot": (40, 0, 20)}, arm__L={"rot": (10, 0, 30)}, arm__R={"rot": (10, 0, -30)}, leg__L={"rot": (70, 0, 0)}, shin__L={"rot": (-90, 0, 0)}, leg__R={"rot": (60, 0, 0)}, shin__R={"rot": (-80, 0, 0)})),
        (2.0, P(base, root={"loc": (0, -0.7, 0), "rot": (80, 0, 8)}, chest={"rot": (20, 0, 12)}, head={"rot": (30, 0, 20)}, arm__L={"rot": (100, 0, 40)}, arm__R={"rot": (100, 0, -40)}, leg__L={"rot": (20, 0, 0)}, leg__R={"rot": (20, 0, 0)})),
    ])
    if pv:
        L.preview(pv + "/binder.png", target=(0, 0, 1.6), dist=8.0)
    L.export_glb(out + "/binder.glb", [arm])


def GROUPS(out):
    return {
        "blot": lambda pv: build_blot(out, pv),
        "scribbler": lambda pv: build_scribbler(out, pv),
        "brute": lambda pv: build_brute(out, pv),
        "moth": lambda pv: build_moth(out, pv),
        "inkpot": lambda pv: build_inkpot(out, pv),
        "binder": lambda pv: build_binder(out, pv),
    }
