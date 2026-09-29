"""Tiny DSP toolkit for Emberquill's procedural audio (numpy + scipy).

Everything is mono float64 at SR unless noted; stereo is shape (n, 2)."""

import math
import wave

import numpy as np
from scipy.signal import butter, sosfilt

SR = 44100


def secs(n):
    return n / SR


def length(dur):
    return max(1, int(round(dur * SR)))


def t_axis(dur):
    return np.arange(length(dur)) / SR


def rng(seed):
    return np.random.default_rng(seed)


# ---------------------------------------------------------------------------
# Envelopes and curves
# ---------------------------------------------------------------------------

def ramp(dur, a, b, curve=1.0):
    """a -> b over dur; curve > 1 eases in, < 1 eases out."""
    x = np.linspace(0.0, 1.0, length(dur))
    return a + (b - a) * x ** curve


def exp_curve(dur, a, b):
    """Exponential glide (natural for pitch)."""
    x = np.linspace(0.0, 1.0, length(dur))
    return a * (b / a) ** x


def env_perc(dur, attack=0.003, decay=0.2, curve=1.0):
    t = t_axis(dur)
    e = np.exp(-t / max(decay, 1e-4))
    if curve != 1.0:
        e = e ** curve
    na = length(attack)
    if na > 1:
        e[:na] *= np.linspace(0.0, 1.0, na)
    return e


def env_ar(dur, attack, release):
    n = length(dur)
    e = np.ones(n)
    na, nr = min(length(attack), n), min(length(release), n)
    e[:na] *= np.linspace(0.0, 1.0, na) ** 0.8
    e[n - nr:] *= np.linspace(1.0, 0.0, nr) ** 1.6
    return e


def env_adsr(dur, a, d, s, r):
    n = length(dur)
    e = np.full(n, s)
    na, nd, nr = length(a), length(d), length(r)
    na = min(na, n)
    e[:na] = np.linspace(0.0, 1.0, na)
    nd = min(nd, n - na)
    if nd > 0:
        e[na:na + nd] = np.linspace(1.0, s, nd)
    nr = min(nr, n)
    e[n - nr:] *= np.linspace(1.0, 0.0, nr)
    return e


def fade(x, fin=0.002, fout=0.01):
    x = x.copy()
    ni, no = min(length(fin), len(x)), min(length(fout), len(x))
    x[:ni] *= np.linspace(0.0, 1.0, ni)[:, None] if x.ndim == 2 else np.linspace(0.0, 1.0, ni)
    x[len(x) - no:] *= np.linspace(1.0, 0.0, no)[:, None] if x.ndim == 2 else np.linspace(1.0, 0.0, no)
    return x


# ---------------------------------------------------------------------------
# Oscillators
# ---------------------------------------------------------------------------

def phase_of(freq, n=None):
    f = np.broadcast_to(np.asarray(freq, dtype=float), (n,)) if n is not None else np.asarray(freq, dtype=float)
    return 2 * np.pi * np.cumsum(f) / SR


def osc(kind, freq, dur, phase0=0.0):
    n = length(dur)
    ph = phase_of(freq, n) + phase0
    if kind == "sine":
        return np.sin(ph)
    frac = (ph / (2 * np.pi)) % 1.0
    if kind == "saw":
        return 2.0 * frac - 1.0
    if kind == "square":
        return np.where(frac < 0.5, 1.0, -1.0)
    if kind == "tri":
        return 4.0 * np.abs(frac - 0.5) - 1.0
    raise ValueError(kind)


def supersaw(freq, dur, voices=5, detune=0.012, seed=0):
    r = rng(seed)
    out = np.zeros(length(dur))
    for i in range(voices):
        d = 1.0 + detune * (i - (voices - 1) / 2) / max(1, (voices - 1) / 2)
        out += osc("saw", np.asarray(freq) * d, dur, r.uniform(0, 2 * np.pi))
    return out / voices


def noise(dur, color="white", seed=0):
    n = length(dur)
    w = rng(seed).standard_normal(n)
    if color == "white":
        return w / 3.0
    if color == "pink":
        # Voss-McCartney-ish via filtering white noise with a 1/f approximation
        b = [0.049922035, -0.095993537, 0.050612699, -0.004408786]
        a = [1, -2.494956002, 2.017265875, -0.522189400]
        from scipy.signal import lfilter
        return lfilter(b, a, w) * 2.5
    if color == "brown":
        x = np.cumsum(w)
        x -= np.convolve(x, np.ones(2048) / 2048, mode="same")
        return x / (np.max(np.abs(x)) + 1e-9)
    raise ValueError(color)


def fm(freq, dur, ratio=3.5, index=3.0, index_decay=0.3, seed=0):
    """FM bell/metal: carrier freq, modulator freq*ratio, decaying index."""
    t = t_axis(dur)
    idx = index * np.exp(-t / max(index_decay, 1e-3))
    mod = np.sin(2 * np.pi * freq * ratio * t)
    return np.sin(2 * np.pi * freq * t + idx * mod)


def pluck(freq, dur, bright=0.55, decay=0.996, seed=0):
    """Karplus-Strong string, vectorised one period at a time."""
    n = length(dur)
    N = max(2, int(round(SR / freq)))
    r = rng(seed)
    burst = r.uniform(-1.0, 1.0, N)
    # brighter pluck = less smoothing of the initial burst
    for _ in range(int((1.0 - bright) * 6)):
        burst = 0.5 * (burst + np.roll(burst, 1))
    out = np.zeros(n + 2 * N)
    out[:N] = burst - burst.mean()
    k = N
    while k < n + N:
        prev = out[k - N:k]
        before = out[k - N - 1] if k - N - 1 >= 0 else 0.0
        shifted = np.concatenate(([before], prev[:-1]))
        out[k:k + N] = decay * 0.5 * (prev + shifted)
        k += N
    return out[:n]


# ---------------------------------------------------------------------------
# Filters
# ---------------------------------------------------------------------------

def _sos(kind, f, order=2):
    nyq = SR / 2
    if kind == "band":
        lo, hi = f
        lo = max(10.0, min(lo, nyq * 0.98))
        hi = max(lo * 1.01, min(hi, nyq * 0.99))
        return butter(order, [lo / nyq, hi / nyq], btype="band", output="sos")
    f = max(10.0, min(f, nyq * 0.99))
    return butter(order, f / nyq, btype=kind, output="sos")


def lp(x, f, order=2):
    return sosfilt(_sos("low", f, order), x, axis=0)


def hp(x, f, order=2):
    return sosfilt(_sos("high", f, order), x, axis=0)


def bp(x, lo, hi, order=2):
    return sosfilt(_sos("band", (lo, hi), order), x, axis=0)


def svf(x, cutoff, q=0.7, mode="lp"):
    """Time-varying state-variable filter (cutoff may be an array)."""
    n = len(x)
    fc = np.broadcast_to(np.asarray(cutoff, dtype=float), (n,))
    g = np.tan(np.pi * np.clip(fc, 20.0, SR * 0.45) / SR)
    k = 1.0 / max(q, 0.05)
    a1 = 1.0 / (1.0 + g * (g + k))
    a2 = g * a1
    a3 = g * a2
    ic1 = ic2 = 0.0
    out = np.empty(n)
    sel = {"lp": 0, "bp": 1, "hp": 2}[mode]
    xs = np.asarray(x, dtype=float).tolist()
    a1l, a2l, a3l = a1.tolist(), a2.tolist(), a3.tolist()
    for i in range(n):
        v3 = xs[i] - ic2
        v1 = a1l[i] * ic1 + a2l[i] * v3
        v2 = ic2 + a2l[i] * ic1 + a3l[i] * v3
        ic1 = 2 * v1 - ic1
        ic2 = 2 * v2 - ic2
        if sel == 0:
            out[i] = v2
        elif sel == 1:
            out[i] = v1
        else:
            out[i] = xs[i] - k * v1 - v2
    return out


def formants(x, vowel="a"):
    table = {
        "a": ((730, 1.0), (1090, 0.5), (2440, 0.25)),
        "o": ((570, 1.0), (840, 0.45), (2410, 0.15)),
        "u": ((300, 1.0), (870, 0.3), (2240, 0.1)),
        "e": ((530, 1.0), (1840, 0.4), (2480, 0.2)),
    }
    out = np.zeros_like(x)
    for f, g in table[vowel]:
        out += bp(x, f * 0.9, f * 1.1, 2) * g
    return out


# ---------------------------------------------------------------------------
# Effects
# ---------------------------------------------------------------------------

def _comb(x, D, g):
    y = np.zeros(len(x) + D)
    y[:len(x)] += 0.0
    xx = np.concatenate([x, np.zeros(D)])
    for k in range(0, len(xx), D):
        seg = xx[k:k + D]
        fb = y[k - D:k] if k >= D else np.zeros(D)
        y[k:k + len(seg)] = seg + g * fb[:len(seg)]
    return y[:len(x)]


def _allpass(x, D, g=0.5):
    n = len(x)
    y = np.zeros(n)
    for k in range(0, n, D):
        m = min(D, n - k)
        xd = x[k - D:k - D + m] if k >= D else np.zeros(m)
        yd = y[k - D:k - D + m] if k >= D else np.zeros(m)
        y[k:k + m] = -g * x[k:k + m] + xd + g * yd
    return y


def reverb(x, size=0.8, damp=4500.0, width=1.0, pre=0.012):
    """Freeverb-style: parallel combs + series allpasses, per channel. Returns stereo."""
    mono = x if x.ndim == 1 else x.mean(axis=1)
    src = lp(mono, damp)
    npre = length(pre)
    src = np.concatenate([np.zeros(npre), src])[:len(mono)]
    combs = [1116, 1188, 1277, 1356, 1422, 1491]
    aps = [556, 441, 341]
    g = 0.7 + 0.28 * size
    outs = []
    for ch, spread in ((0, 0), (1, 23)):
        acc = np.zeros(len(src))
        for c in combs:
            acc += _comb(src, int((c + spread) * SR / 44100), g)
        acc /= len(combs)
        for a in aps:
            acc = _allpass(acc, int((a + spread) * SR / 44100), 0.5)
        outs.append(acc)
    l, r = outs
    mid, side = (l + r) * 0.5, (l - r) * 0.5 * width
    return np.stack([mid + side, mid - side], axis=1)


def pan(x, p):
    """p in -1..1 -> stereo (constant power)."""
    a = (p + 1) * np.pi / 4
    return np.stack([x * np.cos(a), x * np.sin(a)], axis=1)


def stereo(x):
    return x if x.ndim == 2 else np.stack([x, x], axis=1)


def delay(x, time, fb=0.35, mix=0.3, tone=3000.0):
    D = length(time)
    y = x.copy()
    tap = x.copy()
    for i in range(1, 6):
        tap = lp(tap, tone) * fb
        shifted = np.zeros_like(x)
        if D * i < len(x):
            shifted[D * i:] = tap[:len(x) - D * i]
        y = y + shifted * (mix / fb)
    return y


def drive(x, amount=2.0):
    return np.tanh(x * amount) / np.tanh(amount)


def normalize(x, peak=0.89):
    m = np.max(np.abs(x))
    return x if m < 1e-9 else x * (peak / m)


def mix_at(dst, src, start_s, gain=1.0):
    """Adds src into dst at time start_s (both mono or both stereo); grows dst if needed."""
    if np.ndim(dst) != np.ndim(src):
        dst, src = stereo(np.asarray(dst)), stereo(np.asarray(src))
    dst = np.array(dst, dtype=float)
    i = int(round(start_s * SR))
    end = i + len(src)
    if end > len(dst):
        pad = np.zeros((end - len(dst),) + dst.shape[1:])
        dst = np.concatenate([dst, pad])
    dst[i:end] += src * gain
    return dst


def silence(dur, channels=1):
    n = length(dur)
    return np.zeros(n) if channels == 1 else np.zeros((n, channels))


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


# ---------------------------------------------------------------------------
# IO
# ---------------------------------------------------------------------------

def write_wav(path, x, sr=SR):
    x = np.asarray(x)
    ch = 1 if x.ndim == 1 else x.shape[1]
    pcm = (np.clip(x, -1.0, 1.0) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(ch)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())


def write_ogg(path, x, sr=SR, quality=0.45):
    """Vorbis via libsndfile. Written in small blocks: one big write of a long
    stereo buffer crashes libsndfile's Vorbis encoder."""
    import soundfile as sf
    data = np.ascontiguousarray(np.clip(x, -1.0, 1.0), dtype=np.float32)
    ch = 1 if data.ndim == 1 else data.shape[1]
    with sf.SoundFile(path, "w", sr, ch, format="OGG", subtype="VORBIS") as f:
        for i in range(0, len(data), 4096):
            f.write(data[i:i + 4096])
