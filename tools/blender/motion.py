"""Animation authoring layer built on the twelve principles of animation.

Clips are authored pose-to-pose (keys + per-segment easing) and then baked
frame by frame, so every principle is an explicit, testable step:

* slow in / slow out  -> per-key easing curves (``ease=``), incl. overshoot
* anticipation, exaggeration, staging -> the key poses themselves
* follow-through / overlapping action -> per-bone time lag (``lag``) plus
  damped springs (``springs``) that overshoot and settle on their own
* squash & stretch -> ``squash()`` scales that preserve volume
* arcs -> FK rotations + eased curves (joints travel on circles)
* secondary action -> additive procedural layers (``layers``)
* solid drawing / weight -> analytic two-bone leg IK keeps feet planted on
  the ground while the hips drop, lunge and shift weight

Poses are dicts ``{bone: {"rot": (x, y, z) deg, "loc": (x, y, z), "scale": (x, y, z)}}``
in bone-local space. Every bone of the rig stands with local +Y along the bone and
local +Z facing the character's front, so +X rotation always swings a bone's tail
forward (spine leans forward, a leg kicks forward).

This module is pure Python so its maths can be tested without Blender.
"""

import math

FPS = 30

# ---------------------------------------------------------------------------
# Easing
# ---------------------------------------------------------------------------


def _clamp01(x):
    return 0.0 if x < 0.0 else 1.0 if x > 1.0 else x


def e_linear(x):
    return x


def e_in(x):  # accelerate into the key (strikes, falls)
    return x * x * x


def e_out(x):  # decelerate into the key (settles)
    return 1.0 - (1.0 - x) ** 3


def e_inout(x):
    return 4 * x * x * x if x < 0.5 else 1.0 - (-2 * x + 2) ** 3 / 2


def e_snap(x):  # very fast start, long cushion: the Ember Knights "whip"
    return 1.0 - (1.0 - x) ** 5


def e_back(x, s=1.9):  # overshoot then settle (follow-through baked into the key)
    x -= 1.0
    return x * x * ((s + 1) * x + s) + 1.0


def e_hold(x):  # step: stay on the previous pose until the key time
    return 0.0 if x < 1.0 else 1.0


def e_smooth(x):
    return x * x * (3 - 2 * x)


EASES = {
    "linear": e_linear, "in": e_in, "out": e_out, "inout": e_inout, "snap": e_snap,
    "back": e_back, "hold": e_hold, "smooth": e_smooth,
}


# ---------------------------------------------------------------------------
# Pose helpers
# ---------------------------------------------------------------------------

REST = {"rot": (0.0, 0.0, 0.0), "loc": (0.0, 0.0, 0.0), "scale": (1.0, 1.0, 1.0)}


def chan(pose, bone, key):
    return tuple(pose.get(bone, {}).get(key, REST[key]))


def squash(amount):
    """Volume-preserving scale along the bone (+Y). amount > 1 stretches."""
    side = 1.0 / math.sqrt(max(amount, 0.05))
    return (side, amount, side)


def lerp(a, b, t):
    return a + (b - a) * t


def lerp3(a, b, t):
    return tuple(lerp(a[i], b[i], t) for i in range(3))


def merge(base, **over):
    """Copy of ``base`` with bone overrides; ``__`` stands for '.' in bone names.
    Overrides merge per channel, so ``hips={"loc": ...}`` keeps the base rotation."""
    p = {k: dict(v) for k, v in base.items()}
    for k, v in over.items():
        bn = k.replace("__", ".")
        d = dict(p.get(bn, {}))
        d.update(v)
        p[bn] = d
    return p


def add_rot(pose, bone, dx=0.0, dy=0.0, dz=0.0):
    d = pose.setdefault(bone, {})
    r = d.get("rot", (0.0, 0.0, 0.0))
    d["rot"] = (r[0] + dx, r[1] + dy, r[2] + dz)


def add_loc(pose, bone, dx=0.0, dy=0.0, dz=0.0):
    d = pose.setdefault(bone, {})
    r = d.get("loc", (0.0, 0.0, 0.0))
    d["loc"] = (r[0] + dx, r[1] + dy, r[2] + dz)


def mul_scale(pose, bone, s):
    d = pose.setdefault(bone, {})
    r = d.get("scale", (1.0, 1.0, 1.0))
    d["scale"] = (r[0] * s[0], r[1] * s[1], r[2] * s[2])


# ---------------------------------------------------------------------------
# Leg IK (sagittal two-bone solver)
# ---------------------------------------------------------------------------


class Leg:
    """Two-bone leg in the character's sagittal plane.

    Coordinates are (forward, up) in the root bone's space; the hip joint sits at
    ``hip_up`` above the root head at rest, the ankle rests at ``ankle_up``.
    """

    def __init__(self, thigh, shin, foot, l1, l2, hip_up, ankle_up, parent="hips", root="root",
                 foot_len=0.13, foot_drop=0.03):
        self.thigh, self.shin, self.foot = thigh, shin, foot
        self.l1, self.l2 = l1, l2
        self.hip_up, self.ankle_up = hip_up, ankle_up
        self.parent, self.root = parent, root
        # toe tip relative to the ankle at rest (forward, down)
        self.foot_len, self.foot_drop = foot_len, foot_drop

    def tiptoe(self, heel_deg, fwd=0.0):
        """Keyed-foot sample (fwd, up, toe) for a heel raised by ``heel_deg`` while
        the toe tip stays put: the ankle swings up and forward around the toes."""
        a0 = math.atan2(self.foot_drop, self.foot_len)
        r = math.hypot(self.foot_len, self.foot_drop)
        a = a0 + math.radians(heel_deg)
        df = self.foot_len - r * math.cos(a)
        du = r * math.sin(a) - self.foot_drop
        return (fwd + df, du, -heel_deg)

    def solve(self, pose, target, toe_pitch=0.0):
        """Write thigh/shin/foot X rotations so the ankle lands on ``target``
        (forward, up) given in armature space; the foot stays level with the
        ground plus ``toe_pitch`` degrees (positive = toes up, negative = heel up)."""
        rr = chan(pose, self.root, "rot")
        rl = chan(pose, self.root, "loc")
        rs = chan(pose, self.root, "scale")
        hr = chan(pose, self.parent, "rot")
        hl = chan(pose, self.parent, "loc")
        a_root = math.radians(rr[0])
        a_hips = math.radians(hr[0])
        # Target into root space: undo root loc, rotation (pitch) and scale.
        tf, tu = target[0] - rl[2], target[1] - rl[1]
        # Pitching forward maps up (0,1) to (sin a, cos a); apply the inverse.
        f2 = tf * math.cos(a_root) - tu * math.sin(a_root)
        u2 = tf * math.sin(a_root) + tu * math.cos(a_root)
        f2 /= max(rs[2], 1e-4)
        u2 /= max(rs[1], 1e-4)
        # Hip joint in root space (hips loc is expressed in the root frame).
        hf, hu = hl[2], self.hip_up + hl[1]
        df, du = f2 - hf, u2 - hu
        d = math.hypot(df, du)
        lo = abs(self.l1 - self.l2) + 1e-4
        hi = (self.l1 + self.l2) * 0.9995
        d = min(max(d, lo), hi)
        phi = math.atan2(df, -du)  # angle of hip->ankle from straight down, forward +
        cos_a = (self.l1 ** 2 + d * d - self.l2 ** 2) / (2 * self.l1 * d)
        cos_b = (self.l1 ** 2 + self.l2 ** 2 - d * d) / (2 * self.l1 * self.l2)
        alpha = math.acos(max(-1.0, min(1.0, cos_a)))
        beta = math.acos(max(-1.0, min(1.0, cos_b)))
        theta1 = phi + alpha  # knee points forward
        thigh_x = theta1 + a_hips
        shin_x = -(math.pi - beta)
        foot_x = a_hips + a_root - thigh_x - shin_x + math.radians(toe_pitch)
        for bn, ang in ((self.thigh, thigh_x), (self.shin, shin_x), (self.foot, foot_x)):
            d0 = pose.setdefault(bn, {})
            r = d0.get("rot", (0.0, 0.0, 0.0))
            d0["rot"] = (math.degrees(ang), r[1], r[2])

    def ankle(self, pose):
        """Forward kinematics of the ankle (armature space) for verification."""
        rr = chan(pose, self.root, "rot")
        rl = chan(pose, self.root, "loc")
        rs = chan(pose, self.root, "scale")
        hr = chan(pose, self.parent, "rot")
        hl = chan(pose, self.parent, "loc")
        a_root, a_hips = math.radians(rr[0]), math.radians(hr[0])
        t1 = math.radians(chan(pose, self.thigh, "rot")[0]) - a_hips
        t2 = t1 + math.radians(chan(pose, self.shin, "rot")[0])
        f = hl[2] + self.l1 * math.sin(t1) + self.l2 * math.sin(t2)
        u = self.hip_up + hl[1] - self.l1 * math.cos(t1) - self.l2 * math.cos(t2)
        f *= rs[2]
        u *= rs[1]
        wf = f * math.cos(a_root) + u * math.sin(a_root) + rl[2]
        wu = -f * math.sin(a_root) + u * math.cos(a_root) + rl[1]
        return (wf, wu)


# ---------------------------------------------------------------------------
# Clips
# ---------------------------------------------------------------------------


class Spring:
    """Critically-to-under damped spring on a pose channel.

    freq: natural frequency in Hz; zeta: damping ratio (<1 overshoots);
    gain: how much of the target motion leaks through instantly (0 = pure lag)."""

    def __init__(self, freq=3.0, zeta=0.35, gain=0.0, chans=("rot",), parents=(), xsign=1.0):
        self.freq, self.zeta, self.gain, self.chans = freq, zeta, gain, chans
        # World-space springs: the simulated value is the bone's angle in the world,
        # so when the body pitches/rolls the bone lags behind and swings back
        # (true follow-through instead of a delayed copy of the keys).
        # xsign is +1 for bones pointing up (their +X matches the parents'),
        # -1 for bones hanging down (their +X is the parents' -X).
        self.parents, self.xsign = parents, xsign

    def parent_angles(self, pose):
        px = sum(chan(pose, b, "rot")[0] for b in self.parents)
        pz = sum(chan(pose, b, "rot")[2] for b in self.parents)
        return (-self.xsign * px, 0.0, -pz)


class Clip:
    def __init__(self, name, length, loop=False):
        self.name = name
        self.length = length
        self.loop = loop
        self.keys = []  # (t, pose, ease)
        self.lag = {}  # bone -> seconds
        self.springs = {}  # bone -> Spring
        self.layers = []  # fn(t, pose) additive procedural motion
        self.ik = {}  # Leg -> fn(t, pose) -> (target(f,u), toe_pitch) or None for FK
        self.tail = 0.0  # extra time after the last key for springs/lag to settle

    def key(self, t, pose, ease="inout"):
        self.keys.append((t, pose, ease))
        self.keys.sort(key=lambda k: k[0])
        return self

    # -- sampling ---------------------------------------------------------------
    def _bones(self):
        out = set()
        for _, p, _ in self.keys:
            out.update(p.keys())
        return out

    def _pose_at(self, t, bone):
        keys = self.keys
        if self.loop:
            t = t % self.length
        if t <= keys[0][0]:
            return keys[0][1].get(bone, {})
        for i in range(1, len(keys)):
            t1, p1, ease = keys[i]
            t0, p0, _ = keys[i - 1]
            if t <= t1:
                x = _clamp01((t - t0) / max(t1 - t0, 1e-6))
                k = EASES[ease](x)
                a, b = p0.get(bone, {}), p1.get(bone, {})
                out = {}
                for ch in ("rot", "loc", "scale"):
                    va = a.get(ch, REST[ch])
                    vb = b.get(ch, REST[ch])
                    if ch == "scale":
                        # interpolate scale in log space so squash reads symmetric
                        out[ch] = tuple(math.exp(lerp(math.log(max(va[j], 1e-4)), math.log(max(vb[j], 1e-4)), k)) for j in range(3))
                    else:
                        out[ch] = lerp3(va, vb, k)
                return out
        if self.loop:
            # wrap from last key to the first over the remaining loop time
            t0, p0, _ = keys[-1]
            t1 = self.length + keys[0][0]
            x = _clamp01((t - t0) / max(t1 - t0, 1e-6))
            k = EASES[keys[0][2]](x)
            a, b = p0.get(bone, {}), keys[0][1].get(bone, {})
            return {ch: lerp3(a.get(ch, REST[ch]), b.get(ch, REST[ch]), k) for ch in ("rot", "loc", "scale")}
        return keys[-1][1].get(bone, {})

    def sample(self, t):
        pose = {}
        for b in self._bones():
            lag = self.lag.get(b, 0.0)
            tt = t - lag
            if not self.loop:
                tt = max(tt, 0.0)
            pose[b] = {k: tuple(v) for k, v in self._pose_at(tt, b).items()}
        for fn in self.layers:
            fn(t, pose)
        return pose

    # -- baking -----------------------------------------------------------------
    def frame_count(self):
        return int(round((self.length + (0.0 if self.loop else self.tail)) * FPS)) + (0 if self.loop else 1)

    def bake(self):
        """Returns a list of poses, one per frame (loops exclude the duplicate end frame)."""
        n = self.frame_count()
        dt = 1.0 / FPS
        if not self.springs:
            frames = [self.sample(i * dt) for i in range(n)]
        else:
            # Springs: simulate; loops run a few warm-up cycles for a seamless wrap.
            warm = 3 if self.loop else 0
            state = {}
            frames = []
            total = n * (warm + 1)
            first = self.sample(0.0)
            def offset(sp, pose, ch):
                if ch != "rot" or not sp.parents:
                    return (0.0, 0.0, 0.0)
                return sp.parent_angles(pose)

            for b, sp in self.springs.items():
                for ch in sp.chans:
                    v = chan(first, b, ch)
                    o = offset(sp, first, ch)
                    state[(b, ch)] = [[v[j] - o[j] for j in range(3)], [0.0, 0.0, 0.0]]
            for i in range(total):
                t = (i % n) * dt if self.loop else i * dt
                pose = self.sample(t)
                for b, sp in self.springs.items():
                    w = 2 * math.pi * sp.freq
                    for ch in sp.chans:
                        o = offset(sp, pose, ch)
                        local = chan(pose, b, ch)
                        target = tuple(local[j] - o[j] for j in range(3))
                        x, v = state[(b, ch)]
                        # semi-implicit Euler with 4 substeps for stability
                        h = dt / 4
                        for _ in range(4):
                            for j in range(3):
                                acc = w * w * (target[j] - x[j]) - 2 * sp.zeta * w * v[j]
                                v[j] += acc * h
                                x[j] += v[j] * h
                        out = tuple(lerp(x[j], target[j], sp.gain) + o[j] for j in range(3))
                        pose.setdefault(b, {})[ch] = out
                if i >= total - n:
                    frames.append(pose)
        # IK last so feet land exactly where they should, whatever the hips did.
        if self.ik:
            for i, pose in enumerate(frames):
                t = i * dt
                for leg, fn in self.ik.items():
                    res = fn(t, pose)
                    if res is None:
                        continue
                    target, toe = res
                    leg.solve(pose, target, toe)
        return frames


# ---------------------------------------------------------------------------
# Gait helpers
# ---------------------------------------------------------------------------


def planted(leg, forward=0.0, up=None, toe=0.0):
    """IK driver keeping a foot fixed on the ground."""
    u = leg.ankle_up if up is None else up

    def fn(_t, _pose):
        return ((forward, u), toe)
    return fn


def keyed_foot(leg, keys):
    """IK driver following keyed (t, forward, up, toe) samples with smoothstep."""
    keys = sorted(keys)

    def fn(t, _pose):
        if t <= keys[0][0]:
            k = keys[0]
            return ((k[1], leg.ankle_up + k[2]), k[3])
        for i in range(1, len(keys)):
            if t <= keys[i][0]:
                a, b = keys[i - 1], keys[i]
                x = e_smooth(_clamp01((t - a[0]) / max(b[0] - a[0], 1e-6)))
                return ((lerp(a[1], b[1], x), leg.ankle_up + lerp(a[2], b[2], x)), lerp(a[3], b[3], x))
        k = keys[-1]
        return ((k[1], leg.ankle_up + k[2]), k[3])
    return fn


def run_foot(leg, period, phase, stride, lift, duty=0.42):
    """Running foot path: flat stance sliding back under the body, then an arcing
    swing that tucks the heel up (reads as speed from a top-down camera)."""

    def fn(t, _pose):
        p = ((t / period) + phase) % 1.0
        if p < duty:
            q = p / duty
            f = lerp(stride, -stride, q)
            return ((f, leg.ankle_up), lerp(10.0, -16.0, q))  # heel strike -> toe push
        q = (p - duty) / (1.0 - duty)
        f = lerp(-stride, stride, e_inout(q))
        u = leg.ankle_up + lift * math.sin(math.pi * q) ** 0.8
        # pull the foot back up under the body mid-swing (heel kick)
        f -= stride * 0.35 * math.sin(math.pi * q)
        return ((f, u), lerp(-34.0, 10.0, q))  # trailing toes -> reaching heel
    return fn


def selftest():
    leg = Leg("t", "s", "f", 0.14, 0.13, 0.34, 0.07)
    for hips_drop, fwd, pitch, root_pitch in ((-0.02, 0.0, 0, 0), (-0.06, 0.05, 10, 0), (-0.07, -0.08, -15, 8)):
        pose = {"hips": {"loc": (0, hips_drop, 0.02), "rot": (pitch, 0, 0)}, "root": {"rot": (root_pitch, 0, 0), "loc": (0, 0.01, 0.0)}}
        leg.solve(pose, (fwd, 0.07))
        got = leg.ankle(pose)
        assert abs(got[0] - fwd) < 1e-3 and abs(got[1] - 0.07) < 1e-3, (got, fwd)
    print("motion selftest ok")


if __name__ == "__main__":
    selftest()
