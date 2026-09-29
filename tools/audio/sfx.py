"""Emberquill sound effects, synthesised from a handful of gestures.

Palette: paper (crinkles, page flips), ink (blups, splats), wax and candle
flame (crackle, whoomph), quill (scratches), and bright bell-like magic.
Each recipe takes a seed so every sound can have a few natural variants."""

import numpy as np

import dsp as D

# ---------------------------------------------------------------------------
# Sound arrays that line up at t=0 when summed (shorter parts are padded with
# silence, mono meets stereo as centred stereo), so recipes read like a mix.
# ---------------------------------------------------------------------------


class Snd(np.ndarray):
    def __new__(cls, a):
        return np.asarray(a, dtype=float).view(cls)

    @staticmethod
    def _align(a, b):
        a, b = np.asarray(a), np.asarray(b)
        if a.ndim != b.ndim:
            a, b = D.stereo(a), D.stereo(b)
        n = max(len(a), len(b))
        pa = np.zeros((n,) + a.shape[1:])
        pa[:len(a)] = a
        pb = np.zeros((n,) + b.shape[1:])
        pb[:len(b)] = b
        return pa, pb

    def __add__(self, other):
        if isinstance(other, np.ndarray) and other.ndim > 0 and other.shape != self.shape:
            a, b = Snd._align(self, other)
            return Snd(a + b)
        return np.ndarray.__add__(self, other)

    def __radd__(self, other):
        return self.__add__(other)

    def __iadd__(self, other):
        return self.__add__(other)


def snd(fn):
    def wrap(*a, **k):
        return Snd(fn(*a, **k))
    wrap.__name__ = fn.__name__
    return wrap


# ---------------------------------------------------------------------------
# Gestures
# ---------------------------------------------------------------------------


@snd
def whoosh(dur, f0, f1, q=1.4, seed=0, color="pink", shape=(0.35, 1.6)):
    """Filtered-noise swish; the filter sweeps f0 -> f1 (air, cloth, blades)."""
    n = D.noise(dur, color, seed)
    x = D.svf(n, D.exp_curve(dur, f0, f1), q, "bp")
    t = np.linspace(0, 1, len(x))
    peak, sharp = shape
    env = np.where(t < peak, (t / peak) ** sharp, ((1 - t) / (1 - peak)) ** 1.2)
    return x * env


@snd
def thump(dur, f0, f1, decay=0.12, click=0.3, seed=0):
    """Pitch-dropping sine body + tiny transient (impacts, drums, landings)."""
    f = D.exp_curve(dur, f0, f1)
    body = np.sin(D.phase_of(f)) * D.env_perc(dur, 0.001, decay)
    tr = D.hp(D.noise(0.012, "white", seed), 2000) * D.env_perc(0.012, 0.0005, 0.003)
    body[:len(tr)] += tr * click * 3
    return body


@snd
def click(dur=0.02, bright=4000.0, seed=0):
    x = D.bp(D.noise(dur, "white", seed), bright * 0.5, bright * 1.6)
    return x * D.env_perc(dur, 0.0005, dur * 0.25)


@snd
def bell(freq, dur, ratio=3.5, index=2.5, decay=0.9, index_decay=0.25):
    return D.fm(freq, dur, ratio, index, index_decay) * D.env_perc(dur, 0.002, decay)


@snd
def chime(freqs, dur=1.2, gap=0.06, decay=0.7, ratio=3.01, index=1.4):
    out = np.zeros(D.length(dur + gap * len(freqs)))
    for i, f in enumerate(freqs):
        out = D.mix_at(out, bell(f, dur, ratio, index, decay, 0.12), i * gap, 1.0 / (1 + 0.15 * i))
    return out


@snd
def crackle(dur, density=60.0, seed=0, bright=3500.0):
    """Sparse random clicks: flame, embers, crinkling wax."""
    r = D.rng(seed)
    out = np.zeros(D.length(dur))
    n = int(dur * density)
    for _ in range(n):
        c = click(r.uniform(0.004, 0.02), r.uniform(bright * 0.5, bright * 1.5), int(r.integers(1 << 30)))
        out = D.mix_at(out, c, r.uniform(0, dur), r.uniform(0.2, 1.0))
    return out[:D.length(dur)]


@snd
def blup(f0=500.0, f1=1400.0, dur=0.09):
    """Ink bubble: a sine whose pitch rises as the bubble pops."""
    f = D.exp_curve(dur, f0, f1)
    return np.sin(D.phase_of(f)) * D.env_perc(dur, 0.003, dur * 0.35)


@snd
def bubbles(dur, n=6, seed=0, lo=300.0, hi=900.0):
    r = D.rng(seed)
    out = np.zeros(D.length(dur))
    for _ in range(n):
        f = r.uniform(lo, hi)
        out = D.mix_at(out, blup(f, f * r.uniform(1.8, 3.0), r.uniform(0.05, 0.12)), r.uniform(0, dur * 0.85), r.uniform(0.4, 1.0))
    return out[:D.length(dur)]


@snd
def paper(dur, density=140.0, seed=0, tone=2500.0):
    """Crinkle: band-limited noise with a jagged amplitude."""
    r = D.rng(seed)
    base = D.bp(D.noise(dur, "white", seed), tone * 0.4, tone * 2.2)
    grain = D.lp(np.abs(r.standard_normal(D.length(dur))) ** 3, density)
    grain /= grain.max() + 1e-9
    return base * grain + crackle(dur, density * 0.3, seed + 1, tone * 1.4) * 0.5


@snd
def page_swish(dur=0.32, seed=0):
    s = whoosh(dur, 700, 2600, 0.9, seed, "pink", (0.55, 1.3))
    return s + paper(dur, 90, seed + 3, 2800) * D.env_ar(dur, 0.1, 0.12) * 0.5


@snd
def quill_scratch(dur=0.5, seed=0, strokes=6):
    r = D.rng(seed)
    out = np.zeros(D.length(dur))
    t = 0.0
    for _ in range(strokes):
        sd = r.uniform(0.04, 0.1)
        s = D.bp(D.noise(sd, "white", int(r.integers(1 << 30))), 2600, 7000)
        am = 0.6 + 0.4 * np.sin(np.linspace(0, r.uniform(20, 60), len(s)))
        out = D.mix_at(out, s * am * D.env_ar(sd, 0.005, 0.02), t, r.uniform(0.5, 1.0))
        t += sd + r.uniform(0.0, 0.03)
        if t > dur:
            break
    return out[:D.length(dur)]


@snd
def flame_whoomph(dur=0.5, seed=0, bright=900.0):
    w = whoosh(dur, 180, bright, 0.8, seed, "brown", (0.25, 1.2))
    return w * 1.6 + crackle(dur, 40, seed + 5, 2600) * D.env_perc(dur, 0.02, dur * 0.4) * 0.35


@snd
def sub(dur, f0, f1, decay):
    return np.sin(D.phase_of(D.exp_curve(dur, f0, f1))) * D.env_perc(dur, 0.004, decay)


@snd
def splat(dur=0.3, seed=0):
    x = D.svf(D.noise(dur, "white", seed), D.exp_curve(dur, 3000, 400), 1.2, "bp")
    return x * D.env_perc(dur, 0.001, dur * 0.3) + bubbles(dur, 3, seed + 2, 250, 600) * 0.5


@snd
def zapper(dur, f=90.0, seed=0):
    r = D.rng(seed)
    fr = f * (1 + 0.5 * D.lp(r.standard_normal(D.length(dur)), 40) * 8)
    buzz = D.osc("square", fr, dur) * 0.4 + D.osc("saw", fr * 2.01, dur) * 0.3
    buzz = D.hp(buzz, 400)
    gate = (D.lp(r.standard_normal(D.length(dur)), 60) > -0.1).astype(float)
    return buzz * gate * D.env_perc(dur, 0.002, dur * 0.5) * 1.6 + crackle(dur, 120, seed + 1, 5000) * 0.18


def norm(x, peak=0.89):
    return D.normalize(D.fade(x, 0.001, 0.015), peak)


def rev(x, mix=0.25, size=0.6, damp=5000.0):
    wet = D.reverb(x, size, damp)
    return Snd(D.stereo(x) * (1 - mix) + wet * mix * 2.2)


# ---------------------------------------------------------------------------
# Recipes (name -> fn(seed) -> mono or stereo array)
# ---------------------------------------------------------------------------

R = {}


def recipe(name, variants=1):
    def deco(fn):
        R[name] = (fn, variants)
        return fn
    return deco


# --- player / melee ------------------------------------------------------------
@recipe("swing", 3)
def _swing(s):
    return norm(whoosh(0.2, 500 + 80 * s, 3200 + 300 * s, 1.8, s, "pink", (0.4, 1.8)) + whoosh(0.16, 2000, 5000, 3.0, s + 9) * 0.25, 0.8)


@recipe("hit_melee", 3)
def _hit_melee(s):
    x = thump(0.2, 210 - 15 * s, 70, 0.07, 0.7, s) + splat(0.2, s) * 0.5 + click(0.012, 5200, s) * 0.8
    return norm(x)


@recipe("hit_soft", 3)
def _hit_soft(s):
    x = thump(0.16, 320 + 30 * s, 120, 0.05, 0.4, s) * 0.8 + whoosh(0.12, 3000, 900, 1.0, s) * 0.5
    return norm(x, 0.75)


@recipe("hit_hard", 3)
def _hit_hard(s):
    x = thump(0.35, 160 - 10 * s, 45, 0.14, 1.0, s) + D.lp(D.noise(0.25, "white", s), 2400) * D.env_perc(0.25, 0.001, 0.05) * 0.8
    x += splat(0.3, s + 4) * 0.4
    return norm(D.drive(x, 1.6))


@recipe("dash", 2)
def _dash(s):
    return norm(whoosh(0.26, 300, 2400, 1.2, s, "pink", (0.3, 1.4)) + paper(0.22, 80, s, 3000) * 0.25, 0.8)


@recipe("perfect")
def _perfect(s):
    rise = whoosh(0.35, 800, 6000, 2.5, s, "white", (0.9, 2.0)) * 0.5
    ch = chime([D.midi(88), D.midi(95), D.midi(100)], 1.1, 0.04, 0.5)
    x = D.mix_at(rise, ch * 0.8, 0.28)
    return norm(rev(x, 0.35, 0.7))


@recipe("step", 4)
def _step(s):
    r = D.rng(s)
    x = thump(0.09, r.uniform(140, 180), 60, 0.03, 0.2, s) * 0.6 + D.bp(D.noise(0.06, "white", s), 800, 3000) * D.env_perc(0.06, 0.001, 0.012) * 0.6
    return norm(x, 0.6)


@recipe("hurt")
def _hurt(s):
    x = thump(0.4, 140, 50, 0.15, 0.8, s) + crackle(0.35, 70, s, 3000) * D.env_perc(0.35, 0.001, 0.12) * 0.6
    x += sub(0.3, 90, 55, 0.12) * 0.6
    return norm(D.drive(x, 1.4))


@recipe("downed")
def _downed(s):
    snuff = whoosh(0.5, 2500, 200, 1.0, s, "pink", (0.1, 1.0))
    toll = bell(D.midi(50), 1.8, 1.41, 2.0, 1.2, 0.5) * 0.7
    x = D.mix_at(snuff, toll, 0.12)
    return norm(rev(x, 0.35, 0.8, 3000))


@recipe("revive")
def _revive(s):
    ch = chime([D.midi(n) for n in (67, 71, 74, 79, 83)], 1.0, 0.07, 0.6)
    x = D.mix_at(flame_whoomph(0.6, s, 1600) * 0.8, ch, 0.05)
    return norm(rev(x, 0.3, 0.7))


@recipe("heal")
def _heal(s):
    ch = chime([D.midi(n) for n in (72, 76, 79, 84)], 0.9, 0.08, 0.6, 2.0, 0.8)
    return norm(rev(ch + whoosh(0.6, 1500, 5000, 3.0, s, "white", (0.6, 1.5)) * 0.15, 0.35, 0.7), 0.8)


@recipe("join")
def _join(s):
    x = D.mix_at(flame_whoomph(0.5, s, 1400), chime([D.midi(74), D.midi(81)], 1.0, 0.1, 0.6), 0.1, 0.9)
    return norm(rev(x, 0.3))


# --- casting & elements -----------------------------------------------------------
@recipe("cast_light", 3)
def _cast_light(s):
    base = 900 + 120 * s
    zip_ = np.sin(D.phase_of(D.exp_curve(0.14, base, base * 2.6))) * D.env_perc(0.14, 0.002, 0.06)
    x = zip_ * 0.5 + whoosh(0.18, 1200, 5000, 2.0, s, "white", (0.3, 1.4)) * 0.6
    x = D.mix_at(x, bell(base * 2.0, 0.4, 2.0, 1.0, 0.25) * 0.3, 0.02)
    return norm(rev(x, 0.2, 0.5))


@recipe("cast_heavy", 2)
def _cast_heavy(s):
    x = flame_whoomph(0.55, s, 1200) + sub(0.5, 120, 60, 0.25) * 0.7
    x = D.mix_at(x, chime([D.midi(57 + s), D.midi(64 + s), D.midi(69 + s)], 1.0, 0.02, 0.6, 1.5, 1.0) * 0.5, 0.05)
    return norm(rev(x, 0.25, 0.7))


@recipe("el_ember", 2)
def _el_ember(s):
    return norm(flame_whoomph(0.45, s, 1500) + crackle(0.45, 90, s, 3200) * D.env_perc(0.45, 0.01, 0.2) * 0.5, 0.8)


@recipe("el_frost", 2)
def _el_frost(s):
    r = D.rng(s)
    x = np.zeros(D.length(0.6))
    for i in range(7):
        f = r.uniform(2500, 6000)
        x = D.mix_at(x, bell(f, 0.35, 1.0, 0.3, 0.12, 0.05) * 0.4, r.uniform(0, 0.3))
    x = Snd(x) + D.hp(D.noise(0.6, "white", s), 5000) * D.env_perc(0.6, 0.01, 0.15) * 0.3
    return norm(rev(x, 0.3, 0.6), 0.75)


@recipe("el_storm", 2)
def _el_storm(s):
    return norm(zapper(0.35, 70 + 20 * s, s), 0.8)


@recipe("el_void", 2)
def _el_void(s):
    t = D.t_axis(0.7)
    swell = D.supersaw(D.exp_curve(0.7, 110, 55), 0.7, 5, 0.03, s)
    x = D.lp(swell, 900) * (t / 0.7) ** 2.5 * 0.8
    x += sub(0.7, 70, 35, 0.4) * np.clip(t / 0.3, 0, 1)
    x = x[::-1] * 0.4 + x * 0.6
    return norm(rev(x, 0.35, 0.8, 2000), 0.8)


@recipe("el_venom", 2)
def _el_venom(s):
    return norm(bubbles(0.5, 9, s, 250, 700) + D.lp(D.noise(0.5, "pink", s), 1200) * D.env_perc(0.5, 0.02, 0.2) * 0.3, 0.8)


@recipe("el_radiant", 2)
def _el_radiant(s):
    dur = 0.8
    t = D.t_axis(dur)
    x = np.zeros(len(t))
    for i, n in enumerate((72, 76, 79, 84)):
        f = D.midi(n + s * 2)
        x += (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t)) * (1 + 0.006 * np.sin(2 * np.pi * 5.5 * t))
    x = x * D.env_ar(dur, 0.12, 0.4) * 0.25
    return norm(rev(x + whoosh(dur, 2000, 8000, 2.0, s, "white", (0.5, 1.2)) * 0.2, 0.4, 0.8), 0.75)


@recipe("el_arcane", 2)
def _el_arcane(s):
    ch = chime([D.midi(n + s) for n in (79, 86, 91)], 0.8, 0.03, 0.4, 3.5, 2.5)
    return norm(rev(ch, 0.35, 0.6), 0.75)


@recipe("zap", 2)
def _zap(s):
    return norm(zapper(0.25, 110 + 30 * s, s + 10), 0.8)


@recipe("freeze")
def _freeze(s):
    cr = crackle(0.7, 110, s, 6500) * np.linspace(0.3, 1, D.length(0.7))
    frost = np.asarray(_el_frost(s)).mean(axis=1)
    return norm(rev(cr + Snd(frost) * 0.8, 0.25, 0.6), 0.8)


@recipe("shatter", 2)
def _shatter(s):
    r = D.rng(s)
    x = D.hp(D.noise(0.5, "white", s), 3000) * D.env_perc(0.5, 0.001, 0.07)
    for i in range(14):
        f = r.uniform(3000, 9000)
        x = D.mix_at(x, bell(f, 0.3, 1.0 + r.uniform(0, 0.5), 0.5, 0.1, 0.03) * 0.3, r.uniform(0, 0.25))
    return norm(rev(x[:D.length(0.6)], 0.25, 0.5), 0.85)


@recipe("boom_small", 2)
def _boom_small(s):
    x = sub(0.5, 130, 40, 0.18) + D.lp(D.noise(0.5, "brown", s), 1400) * D.env_perc(0.5, 0.002, 0.15) * 1.2
    x += crackle(0.4, 50, s, 3000) * D.env_perc(0.4, 0.01, 0.15) * 0.3
    return norm(D.drive(x, 1.8))


@recipe("boom_big", 2)
def _boom_big(s):
    x = sub(1.4, 100, 28, 0.5) * 1.2 + D.lp(D.noise(1.4, "brown", s), 900) * D.env_perc(1.4, 0.003, 0.45) * 1.4
    x += D.bp(D.noise(1.4, "white", s + 1), 1000, 5000) * D.env_perc(1.4, 0.001, 0.06) * 0.6
    x += crackle(1.2, 40, s, 2500) * D.env_perc(1.2, 0.05, 0.5) * 0.3
    return norm(rev(D.drive(x, 2.0), 0.2, 0.9, 2000))


@recipe("lance")
def _lance(s):
    whistle = np.sin(D.phase_of(D.exp_curve(0.22, 2500, 1200))) * D.env_perc(0.22, 0.004, 0.1) * 0.4
    x = whistle + whoosh(0.22, 1500, 7000, 2.5, s, "white", (0.2, 1.2)) * 0.7
    x = D.mix_at(x, thump(0.12, 300, 120, 0.04, 0.8, s) * 0.6, 0.15)
    return norm(x)


@recipe("meteor_fall")
def _meteor_fall(s):
    dur = 1.0
    whistle = np.sin(D.phase_of(D.exp_curve(dur, 1800, 300))) * np.linspace(0.1, 1.0, D.length(dur)) ** 2 * 0.3
    roar = whoosh(dur, 200, 1200, 0.8, s, "brown", (0.95, 2.0))
    return norm(whistle + roar * 1.2)


@recipe("vortex")
def _vortex(s):
    dur = 1.0
    lfo = 900 + 700 * np.sin(2 * np.pi * np.linspace(0, 7, D.length(dur)))
    x = D.svf(D.noise(dur, "pink", s), lfo, 3.0, "bp") * D.env_ar(dur, 0.2, 0.4)
    return norm(rev(x, 0.3), 0.8)


@recipe("totem")
def _totem(s):
    x = thump(0.3, 220, 90, 0.08, 0.9, s)
    hum = np.sin(2 * np.pi * D.midi(45) * D.t_axis(0.9)) * D.env_ar(0.9, 0.15, 0.5) * 0.35
    return norm(rev(D.mix_at(x, hum, 0.05), 0.25))


@recipe("blink")
def _blink(s):
    pop = thump(0.1, 900, 300, 0.03, 0.3, s)
    rev_whoosh = whoosh(0.3, 5000, 800, 2.0, s, "white", (0.85, 2.5))
    return norm(rev(D.mix_at(rev_whoosh, pop, 0.26), 0.3, 0.5))


@recipe("ricochet", 2)
def _ricochet(s):
    ping = bell(2400 + 300 * s, 0.5, 1.41, 3.0, 0.2, 0.05)
    glide = np.sin(D.phase_of(D.exp_curve(0.2, 3200, 1800))) * D.env_perc(0.2, 0.001, 0.08) * 0.4
    return norm(rev(ping + np.pad(glide, (0, len(ping) - len(glide))), 0.2), 0.75)


@recipe("echo")
def _echo(s):
    b = chime([D.midi(81)], 0.6, 0, 0.3)
    x = D.delay(np.pad(b, (0, D.length(0.8))), 0.14, 0.5, 0.6)
    return norm(rev(x, 0.25), 0.75)


@recipe("ward")
def _ward(s):
    dur = 0.9
    t = D.t_axis(dur)
    hum = (np.sin(2 * np.pi * 220 * t) + 0.5 * np.sin(2 * np.pi * 330.5 * t)) * D.env_ar(dur, 0.05, 0.5) * 0.3
    return norm(rev(hum + chime([D.midi(76), D.midi(83)], 0.8, 0.05, 0.5) * 0.7, 0.3))


@recipe("sigil")
def _sigil(s):
    x = whoosh(0.5, 1500, 6000, 3.0, s, "white", (0.7, 1.4)) * 0.4
    return norm(rev(D.mix_at(x, chime([D.midi(84), D.midi(91)], 0.8, 0.05, 0.5) * 0.6, 0.3), 0.35), 0.75)


@recipe("rune")
def _rune(s):
    t = D.t_axis(0.8)
    hum = np.sin(2 * np.pi * 110 * t + 0.8 * np.sin(2 * np.pi * 55 * t)) * D.env_ar(0.8, 0.02, 0.5) * 0.5
    return norm(rev(hum + chime([D.midi(69 + s)], 0.7, 0, 0.4) * 0.6, 0.3))


@recipe("volley")
def _volley(s):
    x = np.zeros(D.length(0.7))
    for i in range(5):
        x = D.mix_at(x, whoosh(0.18, 700, 3500, 1.8, s + i, "pink", (0.3, 1.5)), i * 0.09, 0.8)
    return norm(x[:D.length(0.8)])


@recipe("fizzle")
def _fizzle(s):
    sput = np.sin(D.phase_of(D.exp_curve(0.4, 900, 180))) * D.env_perc(0.4, 0.002, 0.15) * 0.4
    return norm(sput + crackle(0.4, 60, s, 2500) * D.env_perc(0.4, 0.01, 0.2) * 0.6 + whoosh(0.3, 1500, 300, 1.0, s) * 0.3, 0.7)


@recipe("enemy_cast", 2)
def _enemy_cast(s):
    ch = chime([D.midi(n + s) for n in (62, 65, 68)], 0.9, 0.05, 0.5, 1.5, 1.8)
    return norm(rev(ch + whoosh(0.4, 2500, 500, 1.5, s, "pink", (0.2, 1.0)) * 0.4, 0.35, 0.6, 3000), 0.8)


# --- errata ---------------------------------------------------------------------
@recipe("spawn", 3)
def _spawn(s):
    gurgle = bubbles(0.6, 8, s, 150, 450)
    rise = whoosh(0.6, 200, 1400, 1.2, s, "brown", (0.8, 1.5)) * 0.6
    return norm(gurgle + rise, 0.75)


@recipe("bite", 2)
def _bite(s):
    x = thump(0.15, 260, 90, 0.05, 1.0, s) + D.bp(D.noise(0.12, "white", s), 500, 3000) * D.env_perc(0.12, 0.001, 0.03)
    x = D.mix_at(x, blup(300, 800, 0.08) * 0.6, 0.04)
    return norm(x)


@recipe("brute_windup")
def _brute_windup(s):
    dur = 0.8
    groan = D.lp(D.supersaw(D.exp_curve(dur, 55, 90), dur, 4, 0.02, s), 700) * D.env_ar(dur, 0.2, 0.2)
    creak = D.svf(D.noise(dur, "white", s), D.exp_curve(dur, 400, 1400), 8.0, "bp") * 0.4
    return norm(groan + creak)


@recipe("slam", 2)
def _slam(s):
    x = sub(0.9, 90, 26, 0.35) * 1.3 + D.lp(D.noise(0.9, "brown", s), 700) * D.env_perc(0.9, 0.002, 0.3)
    x += crackle(0.6, 60, s, 2200) * D.env_perc(0.6, 0.02, 0.2) * 0.4
    return norm(rev(D.drive(x, 2.2), 0.15, 0.8, 2000))


@recipe("moth_screech", 2)
def _moth_screech(s):
    dur = 0.45
    am = 0.5 + 0.5 * np.sin(2 * np.pi * 38 * D.t_axis(dur))
    x = D.svf(D.noise(dur, "white", s), D.exp_curve(dur, 2400, 4200), 6.0, "bp") * am
    x += np.sin(D.phase_of(D.exp_curve(dur, 1800, 2600))) * 0.15
    return norm(x * D.env_ar(dur, 0.03, 0.2), 0.7)


@recipe("lob")
def _lob(s):
    return norm(thump(0.25, 240, 80, 0.07, 0.4, s) + whoosh(0.3, 400, 1500, 1.0, s, "pink", (0.3, 1.0)) * 0.5)


@recipe("splash", 2)
def _splash(s):
    return norm(splat(0.45, s) + bubbles(0.45, 6, s + 3, 300, 900) * 0.6)


@recipe("hurt_small", 3)
def _hurt_small(s):
    return norm(paper(0.14, 160, s, 2000) * 0.7 + thump(0.12, 300 + 40 * s, 140, 0.04, 0.4, s) * 0.6, 0.8)


@recipe("hurt_big", 2)
def _hurt_big(s):
    return norm(thump(0.25, 180, 60, 0.09, 0.8, s) + splat(0.25, s) * 0.6)


@recipe("die_small", 2)
def _die_small(s):
    x = splat(0.4, s) + paper(0.3, 200, s + 1, 2600) * 0.5
    return norm(D.mix_at(x, blup(400, 1200, 0.1) * 0.6, 0.02))


@recipe("die_big", 2)
def _die_big(s):
    x = sub(0.9, 110, 35, 0.3) + splat(0.8, s) * 0.8 + paper(0.8, 150, s, 2200) * D.env_perc(0.8, 0.01, 0.3) * 0.6
    return norm(rev(D.drive(x, 1.5), 0.2))


@recipe("book_thud")
def _book_thud(s):
    x = thump(0.35, 120, 50, 0.12, 0.6, s) + paper(0.25, 120, s, 2000) * D.env_perc(0.25, 0.001, 0.08) * 0.6
    return norm(x)


@recipe("boss_roar")
def _boss_roar(s):
    dur = 1.7
    t = D.t_axis(dur)
    pitch = D.exp_curve(dur, 70, 48) * (1 + 0.04 * np.sin(2 * np.pi * 7 * t))
    raw = D.supersaw(pitch, dur, 7, 0.03, s) + D.noise(dur, "pink", s) * 0.4
    voice = D.formants(raw, "o") * 1.4 + D.formants(raw, "a") * 0.8
    x = D.drive(voice * D.env_ar(dur, 0.12, 0.7) * 3, 2.5) + sub(dur, 60, 40, 0.8) * 0.7
    return norm(rev(x, 0.3, 0.9, 2500))


@recipe("boss_summon")
def _boss_summon(s):
    dur = 1.6
    t = D.t_axis(dur)
    chord = sum(D.lp(D.supersaw(D.midi(n), dur, 4, 0.015, s + n), 1400) for n in (38, 45, 50, 53)) * 0.25
    chord *= (t / dur) ** 1.5
    pages = paper(dur, 120, s, 2600) * np.linspace(0.2, 1.0, len(t)) * 0.4
    return norm(rev(chord + pages, 0.35, 0.9))


@recipe("chain_sweep")
def _chain_sweep(s):
    dur = 0.8
    x = whoosh(dur, 300, 1800, 1.0, s, "pink", (0.5, 1.3)) * 1.2
    r = D.rng(s)
    for i in range(18):
        x = D.mix_at(x, bell(r.uniform(1500, 3500), 0.12, 1.41, 2.0, 0.04, 0.02) * 0.25, r.uniform(0.1, 0.7))
    return norm(x[:D.length(dur)])


@recipe("boss_death")
def _boss_death(s):
    dur = 3.2
    boom = _boom_big(s)
    boom = boom if boom.ndim == 1 else boom.mean(axis=1)
    x = np.zeros(D.length(dur))
    x = D.mix_at(x, boom, 0.0)
    t = D.t_axis(2.6)
    choir = sum(D.formants(D.supersaw(D.exp_curve(2.6, D.midi(n), D.midi(n - 5)), 2.6, 4, 0.01, s + n), "a") for n in (57, 60, 64))
    choir *= D.env_ar(2.6, 0.4, 1.2) * 0.9
    x = D.mix_at(x, choir, 0.4)
    x = D.mix_at(x, paper(2.0, 150, s, 2500) * np.linspace(1, 0, D.length(2.0)) * 0.5, 0.3)
    return norm(rev(x[:D.length(dur)], 0.35, 0.95, 3000))


# --- pickups & progression -----------------------------------------------------------
@recipe("coin", 3)
def _coin(s):
    f = [2093, 2349, 2637][s % 3]
    x = D.mix_at(bell(f, 0.4, 2.76, 1.2, 0.25, 0.05), bell(f * 1.5, 0.3, 2.76, 1.0, 0.2, 0.05) * 0.6, 0.05)
    return norm(x, 0.7)


@recipe("ember", 2)
def _ember(s):
    x = bell(D.midi(79 + s * 2), 0.5, 2.0, 1.0, 0.3, 0.1) * 0.7 + crackle(0.4, 50, s, 3000) * D.env_perc(0.4, 0.01, 0.15) * 0.3
    return norm(rev(x[:D.length(0.5)], 0.2), 0.7)


@recipe("reward")
def _reward(s):
    notes = (67, 71, 74, 79)
    x = np.zeros(D.length(1.6))
    for i, n in enumerate(notes):
        x = D.mix_at(x, D.pluck(D.midi(n), 1.2, 0.6, 0.997, s + i) * 0.6, i * 0.07)
    x = D.mix_at(x, chime([D.midi(86), D.midi(91)], 1.2, 0.08, 0.7) * 0.5, 0.25)
    return norm(rev(x, 0.3, 0.7))


@recipe("buy")
def _buy(s):
    x = np.zeros(D.length(0.6))
    for i in range(4):
        x = D.mix_at(x, _coin(i) * 0.5, i * 0.05)
    return norm(D.mix_at(x, chime([D.midi(84)], 0.6, 0, 0.4) * 0.6, 0.2)[:D.length(0.9)], 0.75)


@recipe("door_open")
def _door_open(s):
    creak = D.svf(D.noise(0.6, "white", s), D.exp_curve(0.6, 300, 900), 10.0, "bp") * D.env_ar(0.6, 0.05, 0.2) * 0.6
    x = D.mix_at(page_swish(0.4, s), creak, 0.0)
    return norm(rev(D.mix_at(x, chime([D.midi(76), D.midi(83)], 0.9, 0.06, 0.5) * 0.4, 0.2), 0.25), 0.75)


@recipe("page_turn", 2)
def _page_turn(s):
    return norm(page_swish(0.45, s) + paper(0.45, 110, s + 2, 2400) * 0.3, 0.8)


@recipe("page_clear")
def _page_clear(s):
    x = np.zeros(D.length(1.8))
    for i, n in enumerate((62, 66, 69, 74)):
        x = D.mix_at(x, D.pluck(D.midi(n), 1.4, 0.6, 0.997, s + i) * 0.5, i * 0.03)
    x = D.mix_at(x, chime([D.midi(81), D.midi(86), D.midi(90)], 1.3, 0.09, 0.8) * 0.6, 0.12)
    return norm(rev(x, 0.35, 0.8))


@recipe("victory")
def _victory(s):
    # little fanfare: lute strum + bells, I - IV - V - I
    x = np.zeros(D.length(3.2))
    chords = [(62, 66, 69, 74), (67, 71, 74, 79), (69, 73, 76, 81), (74, 78, 81, 86)]
    times = [0.0, 0.45, 0.9, 1.4]
    for c, t0 in zip(chords, times):
        for j, n in enumerate(c):
            x = D.mix_at(x, D.pluck(D.midi(n), 1.6, 0.65, 0.998, s + j + int(t0 * 10)) * 0.45, t0 + j * 0.025)
    x = D.mix_at(x, chime([D.midi(86), D.midi(90), D.midi(93), D.midi(98)], 1.8, 0.1, 1.0) * 0.6, 1.4)
    return norm(rev(x, 0.35, 0.85))


@recipe("upgrade")
def _upgrade(s):
    x = D.mix_at(flame_whoomph(0.5, s, 1400) * 0.7, chime([D.midi(n) for n in (72, 79, 84, 88)], 1.0, 0.06, 0.7), 0.05)
    return norm(rev(x, 0.3))


# --- UI -------------------------------------------------------------------------------
@recipe("ui_hover")
def _ui_hover(s):
    return norm(click(0.025, 3500, s) * 0.6 + bell(D.midi(96), 0.08, 2.0, 0.4, 0.03, 0.02) * 0.15, 0.45)


@recipe("ui_click")
def _ui_click(s):
    x = thump(0.08, 900, 400, 0.02, 0.8, s) * 0.5 + click(0.03, 2500, s) * 0.8 + paper(0.06, 200, s, 3000) * 0.3
    return norm(x, 0.7)


@recipe("ui_tick")
def _ui_tick(s):
    return norm(click(0.015, 5000, s), 0.4)


@recipe("ui_back")
def _ui_back(s):
    return norm(thump(0.1, 500, 250, 0.03, 0.6, s) * 0.6 + page_swish(0.15, s) * 0.4, 0.6)


@recipe("book_open")
def _book_open(s):
    x = thump(0.3, 140, 60, 0.1, 0.7, s) * 0.8
    x = D.mix_at(x, page_swish(0.4, s) * 0.7, 0.05)
    x = D.mix_at(x, paper(0.3, 150, s, 2600) * 0.3, 0.15)
    return norm(x, 0.8)


@recipe("book_close")
def _book_close(s):
    x = D.lp(page_swish(0.2, s), 2500) * 0.35
    return norm(D.mix_at(x, thump(0.3, 150, 52, 0.11, 0.5, s) + D.lp(D.noise(0.1, "pink", s), 900) * D.env_perc(0.1, 0.001, 0.03) * 0.5, 0.14), 0.85)


@recipe("page_flip", 3)
def _page_flip(s):
    return norm(page_swish(0.2 + 0.03 * s, s), 0.65)


@recipe("glyph_pick")
def _glyph_pick(s):
    return norm(D.pluck(D.midi(79), 0.4, 0.7, 0.996, s) * 0.6 + click(0.02, 3000, s) * 0.4, 0.6)


@recipe("glyph_place")
def _glyph_place(s):
    x = thump(0.12, 400, 180, 0.03, 0.8, s) * 0.7
    return norm(D.mix_at(x, bell(D.midi(86), 0.5, 2.0, 1.0, 0.25, 0.08) * 0.4, 0.01), 0.7)


@recipe("glyph_lift")
def _glyph_lift(s):
    return norm(D.pluck(D.midi(74), 0.3, 0.5, 0.995, s) * 0.5 + paper(0.08, 150, s, 3000) * 0.3, 0.55)


@recipe("quill_write", 2)
def _quill_write(s):
    return norm(quill_scratch(0.55, s, 7), 0.6)


@recipe("cards")
def _cards(s):
    x = np.zeros(D.length(0.6))
    for i in range(3):
        x = D.mix_at(x, page_swish(0.16, s + i) * 0.7, i * 0.11)
    return norm(x[:D.length(0.6)], 0.7)


@recipe("paper_fold", 2)
def _paper_fold(s):
    return norm(paper(0.25, 180, s, 2200) * D.env_ar(0.25, 0.02, 0.1), 0.6)


@recipe("wax_seal")
def _wax_seal(s):
    squish = D.svf(D.noise(0.3, "pink", s), D.exp_curve(0.3, 1800, 300), 1.5, "bp") * D.env_perc(0.3, 0.005, 0.1)
    x = D.mix_at(squish * 0.7, thump(0.25, 180, 70, 0.08, 0.6, s), 0.03)
    return norm(D.mix_at(x, crackle(0.3, 60, s, 2500) * 0.3, 0.05))
