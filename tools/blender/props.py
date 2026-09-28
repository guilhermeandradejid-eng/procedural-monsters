"""Pop-up book scenery kit. Static props; Godot raises them from the page.

Empties named "Flame*" mark where Godot attaches candle flames, and
"Socket*" where interactables put their icons."""

import math
import random

import bpy

import lib as L


def mats():
    return {
        "wood": L.material("Wood", "7a4e2d", 0.85),
        "wood_dark": L.material("WoodDark", "4f3220", 0.9),
        "stone": L.material("Stone", "b3a58c", 0.95),
        "stone_dark": L.material("StoneDark", "8a7c66", 0.95),
        "paper": L.material("Paper", "f1e6c8", 0.9),
        "paper_old": L.material("PaperOld", "d9c49a", 0.9),
        "leaf": L.material("PaperLeaf", "a8b86a", 0.9),
        "leaf_dark": L.material("PaperLeafDark", "6f8a4a", 0.9),
        "wax": L.material("Wax", "efe2c4", 0.6),
        "trim": L.material("Trim", "c9a15b", 0.35, 0.8),
        "metal": L.material("Metal", "7d8589", 0.45, 0.6),
        "ink": L.material("Ink", "1c1411", 0.9),
        "rubric": L.material("Rubric", "9e2b25", 0.8),
        "cover": L.material("Cover", "7a1f1a", 0.7),
        "cover_blue": L.material("CoverBlue", "2d4a6b", 0.7),
        "cover_green": L.material("CoverGreen", "3f5a2b", 0.7),
        "cover_ochre": L.material("CoverOchre", "a8742a", 0.7),
        "leather": L.material("Leather", "5b3a26", 0.8),
        "straw": L.material("Straw", "d8b35e", 0.9),
        "bone": L.material("Bone", "e8dcc0", 0.8),
        "kelp": L.material("InkKelp", "27508a", 0.6),
    }


COVERS = ["cover", "cover_blue", "cover_green", "cover_ochre"]


def empty(name, loc):
    e = bpy.data.objects.new(name, None)
    e.empty_display_size = 0.1
    e.location = loc
    bpy.context.collection.objects.link(e)
    return e


def finish(objs, name, out, pv, target=(0, 0, 0.8), dist=4.0, extra=()):
    ob = L.join(objs, name)
    for e in extra:
        e.parent = ob
    if pv:
        L.preview("%s/prop_%s.png" % (pv, name), target=target, dist=dist, elevation=30)
    L.export_glb("%s/props/%s.glb" % (out, name), [ob])


def book(name, w, d, h, loc, rot, m, cover, rnd):
    parts = [L.box(name, (w, d, h), loc=loc, rot=rot, mat=m[cover], bevel=min(0.02, h * 0.2))]
    # Page edge inset on one long side.
    rz = math.radians(rot[2])
    off = (math.sin(rz) * (d * 0.5 - 0.02) * -1, math.cos(rz) * (d * 0.5 - 0.02) * -1)
    parts.append(L.box(name + "p", (w * 0.94, 0.05, h * 0.78), loc=(loc[0] + off[0], loc[1] + off[1], loc[2]), rot=rot, mat=m["paper"]))
    return parts


# ---------------------------------------------------------------------------

def bookshelf(out, pv):
    L.reset()
    m = mats()
    rnd = random.Random(4)
    W, D, H = 1.5, 0.5, 2.3
    objs = [
        L.box("back", (W, 0.06, H), loc=(0, 0.22, H / 2), mat=m["wood_dark"]),
        L.box("sideL", (0.08, D, H), loc=(W / 2, 0, H / 2), mat=m["wood"], bevel=0.015),
        L.box("sideR", (0.08, D, H), loc=(-W / 2, 0, H / 2), mat=m["wood"], bevel=0.015),
        L.box("top", (W + 0.16, D + 0.08, 0.1), loc=(0, 0, H + 0.05), mat=m["wood"], bevel=0.02),
        L.box("crown", (W + 0.3, D + 0.12, 0.06), loc=(0, 0, H + 0.13), mat=m["wood_dark"], bevel=0.015),
    ]
    shelves = [0.08, 0.62, 1.16, 1.7]
    for i, z in enumerate(shelves):
        objs.append(L.box("shelf%d" % i, (W, D, 0.06), loc=(0, 0, z), mat=m["wood"], bevel=0.01))
        x = -W / 2 + 0.08
        while x < W / 2 - 0.14:
            bw = rnd.uniform(0.06, 0.12)
            bh = rnd.uniform(0.32, 0.46)
            lean = rnd.random() < 0.12
            cover = rnd.choice(COVERS)
            objs.append(L.box("b%d_%.2f" % (i, x), (bw, D * 0.8, bh), loc=(x + bw / 2, -0.02, z + 0.03 + bh / 2),
                              rot=(0, rnd.uniform(-14, -8) if lean else 0, 0), mat=m[cover], bevel=0.01))
            if rnd.random() < 0.5:
                objs.append(L.box("band%d_%.2f" % (i, x), (bw + 0.004, D * 0.8 + 0.004, 0.025), loc=(x + bw / 2, -0.02, z + 0.1 + bh * 0.55), mat=m["trim"]))
            x += bw + rnd.uniform(0.0, 0.02)
            if rnd.random() < 0.08:
                x += 0.12
    finish(objs, "bookshelf", out, pv, target=(0, 0, 1.2), dist=5.5)


def book_stack(out, pv):
    L.reset()
    m = mats()
    rnd = random.Random(8)
    objs = []
    z = 0.0
    for i in range(5):
        w = rnd.uniform(0.7, 1.0)
        d = rnd.uniform(0.5, 0.7)
        h = rnd.uniform(0.12, 0.2)
        objs += book("bk%d" % i, w, d, h, (rnd.uniform(-0.06, 0.06), rnd.uniform(-0.05, 0.05), z + h / 2), (0, 0, rnd.uniform(-20, 20)), m, rnd.choice(COVERS), rnd)
        z += h
    objs.append(L.lathe("cndl", [(0.0, z), (0.06, z), (0.06, z + 0.22), (0.05, z + 0.24), (0.0, z + 0.235)], segs=10, mat=m["wax"]))
    fl = empty("Flame0", (0, 0, z + 0.3))
    finish(objs, "book_stack", out, pv, target=(0, 0, 0.5), dist=3.0, extra=[fl])


def big_book(out, pv):
    L.reset()
    m = mats()
    rnd = random.Random(2)
    objs = book("tome", 1.8, 1.25, 0.4, (0, 0, 0.2), (0, 0, 0), m, "cover", rnd)
    for sx in (-1, 1):
        for sy in (-1, 1):
            objs.append(L.box("corner%d%d" % (sx, sy), (0.2, 0.2, 0.42), loc=(sx * 0.82, sy * 0.54, 0.2), mat=m["trim"], bevel=0.02))
    objs.append(L.box("clasp", (0.3, 0.14, 0.44), loc=(0.8, 0, 0.2), mat=m["leather"], bevel=0.02))
    objs.append(L.sphere("gem", 0.09, loc=(0, 0, 0.42), scale=(1, 1, 0.45), segs=10, rings=6, mat=m["rubric"]))
    finish(objs, "big_book", out, pv, target=(0, 0, 0.2), dist=4.0)


def candles(out, pv):
    L.reset()
    m = mats()
    rnd = random.Random(12)
    objs = [L.cone("dish", 0.45, 0.4, 0.06, loc=(0, 0, 0.03), mat=m["trim"], segs=18)]
    flames = []
    for i, (x, y, h) in enumerate(((0.0, 0.0, 0.75), (0.2, 0.12, 0.5), (-0.18, 0.1, 0.38), (0.06, -0.2, 0.28))):
        r = 0.07 + (0.01 if i == 0 else 0.0)
        objs.append(L.lathe("c%d" % i, [(0.0, 0.06), (r, 0.06), (r, h), (r * 0.85, h + 0.02), (0.0, h + 0.015)], segs=12, loc=(x, y, 0), mat=m["wax"]))
        for k in range(rnd.randint(1, 3)):
            a = rnd.uniform(0, math.tau)
            dh = rnd.uniform(0.06, 0.16)
            objs.append(L.sphere("d%d%d" % (i, k), 1.0, loc=(x + math.cos(a) * r, y + math.sin(a) * r, h - dh * 0.5), scale=(0.02, 0.02, dh * 0.6), segs=6, rings=4, mat=m["wax"]))
        flames.append((x, y, h + 0.1))
    empties = [empty("Flame%d" % i, f) for i, f in enumerate(flames)]
    finish(objs, "candles", out, pv, target=(0, 0, 0.4), dist=2.6, extra=empties)


def pillar(out, pv):
    L.reset()
    m = mats()
    objs = [
        L.box("base", (0.9, 0.9, 0.22), loc=(0, 0, 0.11), mat=m["stone_dark"], bevel=0.03),
        L.cone("shaft", 0.34, 0.3, 2.6, loc=(0, 0, 1.52), mat=m["stone"], segs=10, smooth=False),
        L.box("cap", (0.82, 0.82, 0.2), loc=(0, 0, 2.9), mat=m["stone_dark"], bevel=0.03),
        L.lathe("band", [(0.33, 1.2), (0.36, 1.22), (0.36, 1.55), (0.33, 1.57)], segs=12, mat=m["paper_old"], cap_top=False, cap_bottom=False),
    ]
    for i in range(3):
        objs.append(L.box("script%d" % i, (0.02, 0.2 - 0.04 * i, 0.03), loc=(0, -0.365, 1.48 - 0.07 * i), mat=m["ink"]))
    L.jitter(objs[1], 0.02, 3)
    finish(objs, "pillar", out, pv, target=(0, 0, 1.4), dist=5.5)


def broken_pillar(out, pv):
    L.reset()
    m = mats()
    shaft = L.cone("shaft", 0.34, 0.32, 1.1, loc=(0, 0, 0.77), mat=m["stone"], segs=10, smooth=False)
    for v in shaft.data.vertices:
        if v.co.z > 1.0:
            v.co.z += (math.sin(v.co.x * 20) + math.cos(v.co.y * 17)) * 0.12
    objs = [L.box("base", (0.9, 0.9, 0.22), loc=(0, 0, 0.11), mat=m["stone_dark"], bevel=0.03), shaft,
            L.cone("chunk", 0.3, 0.3, 0.5, loc=(0.7, 0.3, 0.3), rot=(90, 0, 30), mat=m["stone"], segs=10, smooth=False)]
    finish(objs, "broken_pillar", out, pv, target=(0, 0, 0.6), dist=4.0)


def arch(out, pv):
    """Page exit: two pillars and a pointed arch with a bookmark ribbon."""
    L.reset()
    m = mats()
    objs = []
    for sx in (-1, 1):
        objs.append(L.box("post%d" % sx, (0.4, 0.4, 2.4), loc=(sx * 1.1, 0, 1.2), mat=m["stone"], bevel=0.03))
        objs.append(L.box("foot%d" % sx, (0.55, 0.55, 0.2), loc=(sx * 1.1, 0, 0.1), mat=m["stone_dark"], bevel=0.03))
    pts = []
    n = 10
    for i in range(n + 1):
        t = i / n
        a = math.pi * t
        pts.append((math.cos(a) * 1.3, 2.4 + math.sin(a) * 0.9 + (0.25 * (1 - abs(2 * t - 1)) ** 3)))
    inner = []
    for i in range(n, -1, -1):
        t = i / n
        a = math.pi * t
        inner.append((math.cos(a) * 0.9, 2.4 + math.sin(a) * 0.6))
    objs.append(L.extrude_shape("arc", pts + inner, depth=0.4, loc=(0, 0, 0), rot=(90, 0, 0), mat=m["stone"]))
    objs.append(L.box("key", (0.3, 0.46, 0.35), loc=(0, 0, 3.32), mat=m["trim"], bevel=0.03))
    ribbon = L.extrude_shape("ribbon", [(-0.13, 0.0), (0.13, 0.0), (0.13, -1.2), (0.0, -1.05), (-0.13, -1.2)], depth=0.02, loc=(0, -0.22, 3.1), rot=(90, 0, 0), mat=m["rubric"])
    objs.append(ribbon)
    sock = empty("Socket", (0, -0.3, 4.1))
    finish(objs, "arch", out, pv, target=(0, 0, 1.8), dist=7.0, extra=[sock])


def paper_tree(out, pv, variant=0):
    L.reset()
    m = mats()
    rnd = random.Random(20 + variant)
    objs = [L.cone("trunk", 0.16, 0.1, 1.1, loc=(0, 0, 0.55), mat=m["wood"], segs=6, smooth=False)]
    z = 0.8
    r = 1.1 - 0.15 * variant
    for i in range(3):
        c = L.cone("tier%d" % i, r, 0.05, 0.9, loc=(0, 0, z + 0.45), rot=(0, 0, rnd.uniform(0, 60)), mat=m["leaf" if i % 2 == 0 else "leaf_dark"], segs=7, smooth=False)
        L.jitter(c, 0.04, 30 + i + variant)
        objs.append(c)
        z += 0.55
        r *= 0.75
    for i in range(4):
        a = rnd.uniform(0, math.tau)
        objs.append(L.box("tag%d" % i, (0.1, 0.004, 0.14), loc=(math.cos(a) * 0.7, math.sin(a) * 0.7, 1.2 + rnd.uniform(0, 0.6)), rot=(0, 0, math.degrees(a)), mat=m["paper"]))
    finish(objs, "paper_tree%d" % variant, out, pv, target=(0, 0, 1.3), dist=5.0)


def bush(out, pv):
    L.reset()
    m = mats()
    rnd = random.Random(5)
    objs = []
    for i in range(5):
        a = math.tau * i / 5
        c = L.cone("b%d" % i, 0.35, 0.02, 0.6, loc=(math.cos(a) * 0.3, math.sin(a) * 0.3, 0.3), rot=(rnd.uniform(-15, 15), rnd.uniform(-15, 15), 0), mat=m["leaf" if i % 2 else "leaf_dark"], segs=5, smooth=False)
        objs.append(c)
    objs.append(L.cone("bc", 0.4, 0.02, 0.8, loc=(0, 0, 0.4), mat=m["leaf"], segs=6, smooth=False))
    finish(objs, "bush", out, pv, target=(0, 0, 0.3), dist=2.8)


def rock(out, pv, variant=0):
    L.reset()
    m = mats()
    r = L.ico("rock", 1.0, loc=(0, 0, 0.35), scale=(0.7 + 0.2 * variant, 0.6, 0.45), subdiv=1, mat=m["stone"])
    L.jitter(r, 0.12, 40 + variant)
    objs = [r]
    if variant == 1:
        s = L.ico("rock2", 1.0, loc=(0.6, 0.3, 0.2), scale=(0.3, 0.3, 0.22), subdiv=1, mat=m["stone_dark"])
        L.jitter(s, 0.06, 7)
        objs.append(s)
    finish(objs, "rock%d" % variant, out, pv, target=(0, 0, 0.3), dist=3.0)


def scroll_pile(out, pv):
    L.reset()
    m = mats()
    rnd = random.Random(3)
    objs = []
    for i in range(6):
        a = rnd.uniform(0, 180)
        z = 0.08 + (0.14 if i > 3 else 0.0)
        objs.append(L.cone("s%d" % i, 0.08, 0.08, 0.7, loc=(rnd.uniform(-0.3, 0.3), rnd.uniform(-0.3, 0.3), z), rot=(90, 0, a), mat=m["paper"], segs=10))
        objs.append(L.cone("r%d" % i, 0.085, 0.085, 0.06, loc=objs[-1].location, rot=(90, 0, a), mat=m["rubric"], segs=10))
    finish(objs, "scroll_pile", out, pv, target=(0, 0, 0.15), dist=2.4)


def lectern(out, pv):
    L.reset()
    m = mats()
    objs = [
        L.cone("foot", 0.45, 0.32, 0.12, loc=(0, 0, 0.06), mat=m["wood_dark"], segs=8),
        L.cone("post", 0.1, 0.09, 1.0, loc=(0, 0, 0.6), mat=m["wood"], segs=8),
        L.box("desk", (0.9, 0.6, 0.08), loc=(0, 0.05, 1.18), rot=(-25, 0, 0), mat=m["wood"], bevel=0.02),
        L.box("lip", (0.9, 0.05, 0.08), loc=(0, -0.24, 1.08), rot=(-25, 0, 0), mat=m["trim"], bevel=0.01),
        L.box("open_l", (0.4, 0.5, 0.05), loc=(-0.2, 0.05, 1.25), rot=(-25, -8, 0), mat=m["paper"], bevel=0.01),
        L.box("open_r", (0.4, 0.5, 0.05), loc=(0.2, 0.05, 1.25), rot=(-25, 8, 0), mat=m["paper"], bevel=0.01),
    ]
    sock = empty("Socket", (0, 0, 1.7))
    finish(objs, "lectern", out, pv, target=(0, 0, 0.8), dist=3.5, extra=[sock])


def pedestal(out, pv):
    L.reset()
    m = mats()
    objs = [
        L.cone("base", 0.6, 0.5, 0.2, loc=(0, 0, 0.1), mat=m["stone_dark"], segs=8, smooth=False),
        L.cone("col", 0.32, 0.36, 0.55, loc=(0, 0, 0.47), mat=m["stone"], segs=8, smooth=False),
        L.cone("top", 0.48, 0.52, 0.12, loc=(0, 0, 0.8), mat=m["stone_dark"], segs=8, smooth=False),
        L.torus("rim", 0.46, 0.03, loc=(0, 0, 0.87), mat=m["trim"], seg_major=16, seg_minor=5),
    ]
    sock = empty("Socket", (0, 0, 1.4))
    finish(objs, "pedestal", out, pv, target=(0, 0, 0.5), dist=3.0, extra=[sock])


def ember_tree(out, pv):
    """Hub upgrade station: a brass candelabrum shaped like a tree."""
    L.reset()
    m = mats()
    objs = [L.cone("foot", 0.7, 0.4, 0.2, loc=(0, 0, 0.1), mat=m["trim"], segs=12),
            L.cone("trunk", 0.12, 0.08, 2.0, loc=(0, 0, 1.1), mat=m["trim"], segs=8)]
    empties = []
    rnd = random.Random(9)
    k = 0
    for tier, (z, n, r) in enumerate(((0.9, 5, 0.9), (1.5, 4, 0.7), (2.0, 3, 0.45))):
        for i in range(n):
            a = math.tau * i / n + tier * 0.4
            tip = (math.cos(a) * r, math.sin(a) * r, z + 0.3)
            mid = (math.cos(a) * r * 0.5, math.sin(a) * r * 0.5, z)
            objs.append(L.cone("br%d" % k, 0.035, 0.03, r * 0.6, loc=mid, rot=(0, 70, math.degrees(a)), mat=m["trim"], segs=6))
            objs.append(L.cone("cup%d" % k, 0.1, 0.07, 0.06, loc=tip, mat=m["trim"], segs=8))
            h = rnd.uniform(0.12, 0.22)
            objs.append(L.cone("cn%d" % k, 0.05, 0.05, h, loc=(tip[0], tip[1], tip[2] + 0.03 + h / 2), mat=m["wax"], segs=8))
            empties.append(empty("Flame%d" % k, (tip[0], tip[1], tip[2] + 0.1 + h)))
            k += 1
    objs.append(L.cone("topcup", 0.12, 0.08, 0.08, loc=(0, 0, 2.12), mat=m["trim"], segs=8))
    objs.append(L.cone("topcn", 0.06, 0.06, 0.3, loc=(0, 0, 2.3), mat=m["wax"], segs=8))
    empties.append(empty("Flame%d" % k, (0, 0, 2.55)))
    finish(objs, "ember_tree", out, pv, target=(0, 0, 1.3), dist=6.0, extra=empties)


def dummy(out, pv):
    L.reset()
    m = mats()
    objs = [
        L.cone("post", 0.06, 0.06, 1.4, loc=(0, 0, 0.7), mat=m["wood"], segs=6),
        L.cone("cross", 0.05, 0.05, 1.0, loc=(0, 0, 1.1), rot=(0, 90, 0), mat=m["wood"], segs=6),
        L.sphere("body", 1.0, loc=(0, 0, 0.95), scale=(0.34, 0.3, 0.42), segs=10, rings=8, mat=m["straw"], smooth=False),
        L.sphere("head", 0.22, loc=(0, 0, 1.5), segs=10, rings=8, mat=m["straw"], smooth=False),
        L.box("sign", (0.36, 0.02, 0.28), loc=(0, -0.31, 0.95), rot=(8, 0, 0), mat=m["paper"]),
        L.cone("target", 0.1, 0.1, 0.03, loc=(0, -0.33, 0.95), rot=(98, 0, 0), mat=m["rubric"], segs=12),
        L.box("stand", (0.6, 0.6, 0.1), loc=(0, 0, 0.05), mat=m["wood_dark"], bevel=0.02),
    ]
    finish(objs, "dummy", out, pv, target=(0, 0, 0.8), dist=3.4)


def gravestone(out, pv):
    L.reset()
    m = mats()
    pts = [(-0.35, 0.0), (0.35, 0.0), (0.35, 0.8)] + [(math.cos(a) * 0.35, 0.8 + math.sin(a) * 0.3) for a in [i * math.pi / 8 for i in range(1, 8)]] + [(-0.35, 0.8)]
    s = L.extrude_shape("stone", pts, depth=0.18, loc=(0, 0, 0), rot=(90, 0, 0), mat=m["stone"])
    L.jitter(s, 0.02, 4)
    objs = [s, L.box("base", (0.9, 0.5, 0.12), loc=(0, 0, 0.06), mat=m["stone_dark"], bevel=0.02),
            L.box("glyph", (0.3, 0.02, 0.04), loc=(0, -0.1, 0.75), mat=m["ink"]),
            L.box("glyph2", (0.04, 0.02, 0.3), loc=(0, -0.1, 0.7), mat=m["ink"])]
    for i in range(3):
        objs.append(L.lathe("wx%d" % i, [(0.0, 0.12), (0.04, 0.12), (0.04, 0.2 + 0.08 * i), (0.0, 0.2 + 0.08 * i)], segs=8, loc=(-0.3 + 0.14 * i, -0.3, 0), mat=m["wax"]))
    fl = empty("Flame0", (-0.16, -0.3, 0.52))
    finish(objs, "gravestone", out, pv, target=(0, 0, 0.5), dist=3.0, extra=[fl])


def ink_kelp(out, pv):
    L.reset()
    m = mats()
    objs = []
    rnd = random.Random(6)
    for i in range(4):
        pts = []
        h = rnd.uniform(1.4, 2.4)
        n = 10
        for k in range(n + 1):
            t = k / n
            pts.append((0.08 * (1 - t) + 0.02 + math.sin(t * 6 + i) * 0.05, t * h))
        for k in range(n, -1, -1):
            t = k / n
            pts.append((-0.08 * (1 - t) - 0.02 + math.sin(t * 6 + i) * 0.05, t * h))
        a = math.tau * i / 4
        objs.append(L.extrude_shape("kelp%d" % i, pts, depth=0.03, loc=(math.cos(a) * 0.25, math.sin(a) * 0.25, 0), rot=(90, 0, math.degrees(a)), mat=m["kelp"]))
    finish(objs, "ink_kelp", out, pv, target=(0, 0, 1.0), dist=4.0)


def chest(out, pv):
    L.reset()
    m = mats()
    objs = [L.box("box", (0.9, 0.6, 0.5), loc=(0, 0, 0.25), mat=m["wood"], bevel=0.03),
            L.cone("lid", 0.3, 0.3, 0.9, loc=(0, 0, 0.5), rot=(0, 90, 0), scale=(1, 1, 1), mat=m["wood_dark"], segs=10),
            L.box("lock", (0.14, 0.05, 0.16), loc=(0, -0.31, 0.5), mat=m["trim"], bevel=0.01)]
    for sx in (-1, 1):
        objs.append(L.box("strap%d" % sx, (0.08, 0.64, 0.56), loc=(sx * 0.3, 0, 0.3), mat=m["metal"]))
    finish(objs, "chest", out, pv, target=(0, 0, 0.4), dist=3.0)


def GROUPS(out):
    return {
        "props": lambda pv: [f(out, pv) for f in (bookshelf, book_stack, big_book, candles, pillar, broken_pillar, arch, bush,
                                                  scroll_pile, lectern, pedestal, ember_tree, dummy, gravestone, ink_kelp, chest)]
        + [paper_tree(out, pv, v) for v in range(2)] + [rock(out, pv, v) for v in range(2)],
    }
