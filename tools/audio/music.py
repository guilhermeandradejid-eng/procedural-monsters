"""Emberquill music: small storybook pieces rendered as two synchronised stems.

`calm` always plays; `combat` fades in on top when a page fights back
(Audio.set_intensity). Both stems share tempo, key and length, and loop
seamlessly: the piece renders one extra bar whose reverb tail is folded back
onto the start before trimming to the exact loop length."""

import zlib

import numpy as np

import dsp as D

# ---------------------------------------------------------------------------
# Instruments (mono note renderers)
# ---------------------------------------------------------------------------


def lute(f, dur, vel=1.0, seed=0):
    x = D.pluck(f, dur + 0.6, 0.6, 0.9965, seed)
    body = D.bp(x, 180, 2600)
    return (x * 0.5 + body * 0.8) * vel


def harp(f, dur, vel=1.0, seed=0):
    x = D.pluck(f, dur + 1.4, 0.75, 0.9985, seed)
    return D.lp(x, 5000) * vel


def bass(f, dur, vel=1.0, seed=0):
    x = D.pluck(f, dur + 0.4, 0.35, 0.997, seed)
    s = np.sin(2 * np.pi * f * D.t_axis(dur + 0.4)) * D.env_perc(dur + 0.4, 0.005, 0.5)
    return (D.lp(x, 1200) + s * 0.5) * vel


def flute(f, dur, vel=1.0, seed=0):
    total = dur + 0.12
    t = D.t_axis(total)
    vib = 1 + 0.005 * np.sin(2 * np.pi * 5.2 * t) * np.clip(t / 0.4, 0, 1)
    ph = D.phase_of(f * vib)
    tone = np.sin(ph) + 0.22 * np.sin(2 * ph) + 0.06 * np.sin(3 * ph)
    breath = D.bp(D.noise(total, "white", seed), f * 0.8, f * 3.0) * 0.12
    env = D.env_adsr(total, 0.06, 0.1, 0.8, 0.12)
    return (tone + breath) * env * vel * 0.5


def pad(freqs, dur, vel=1.0, seed=0, cutoff=1300.0):
    total = dur + 0.8
    x = np.zeros(D.length(total))
    for i, f in enumerate(freqs):
        x += D.supersaw(f, total, 4, 0.01, seed + i)
    x = D.lp(x / len(freqs), cutoff, 2)
    return x * D.env_adsr(total, 0.6, 0.3, 0.8, 0.8) * vel


def choir(freqs, dur, vel=1.0, seed=0, vowel="a"):
    total = dur + 0.8
    t = D.t_axis(total)
    x = np.zeros(len(t))
    for i, f in enumerate(freqs):
        vib = 1 + 0.006 * np.sin(2 * np.pi * (5.0 + 0.3 * i) * t + i)
        x += D.supersaw(f * vib, total, 3, 0.008, seed + i)
    x = D.formants(x / len(freqs), vowel) * 2.5
    return x * D.env_adsr(total, 0.35, 0.3, 0.85, 0.7) * vel


def strings(f, dur, vel=1.0, seed=0):
    """Marcato low strings for the combat ostinato."""
    total = dur + 0.15
    x = D.supersaw(f, total, 3, 0.006, seed)
    x = D.lp(x, 900 + 900 * vel)
    return x * D.env_adsr(total, 0.01, 0.12, 0.55, 0.12) * vel


def bellnote(f, dur, vel=1.0, seed=0):
    return D.fm(f, dur + 1.5, 3.01, 1.6, 0.4) * D.env_perc(dur + 1.5, 0.002, 1.0) * vel * 0.5


def frame_drum(vel=1.0, seed=0):
    t = 0.35
    body = np.sin(D.phase_of(D.exp_curve(t, 120, 62))) * D.env_perc(t, 0.002, 0.16)
    skin = D.lp(D.noise(t, "white", seed), 1600) * D.env_perc(t, 0.001, 0.03)
    return (body + skin * 0.5) * vel


def taiko(vel=1.0, seed=0):
    t = 0.7
    body = np.sin(D.phase_of(D.exp_curve(t, 85, 44))) * D.env_perc(t, 0.002, 0.3)
    hit = D.lp(D.noise(t, "brown", seed), 500) * D.env_perc(t, 0.001, 0.06)
    return D.drive((body * 1.2 + hit * 0.8) * vel, 1.5)


def rim(vel=1.0, seed=0):
    t = 0.12
    x = D.bp(D.noise(t, "white", seed), 1500, 6000) * D.env_perc(t, 0.0005, 0.02)
    x += np.sin(2 * np.pi * 820 * D.t_axis(t)) * D.env_perc(t, 0.0005, 0.015) * 0.4
    return x * vel


def shaker(vel=1.0, seed=0):
    t = 0.09
    return D.hp(D.noise(t, "white", seed), 6000) * D.env_ar(t, 0.02, 0.06) * vel * 0.6


# ---------------------------------------------------------------------------
# Theory helpers
# ---------------------------------------------------------------------------

MODES = {
    "dorian": [0, 2, 3, 5, 7, 9, 10],
    "aeolian": [0, 2, 3, 5, 7, 8, 10],
    "mixolydian": [0, 2, 4, 5, 7, 9, 10],
    "ionian": [0, 2, 4, 5, 7, 9, 11],
}


class Key:
    def __init__(self, root, mode):
        self.root, self.steps = root, MODES[mode]

    def note(self, degree, octave=0):
        """Scale degree (0-based, may exceed 6) -> midi."""
        o, d = divmod(degree, 7)
        return self.root + 12 * (o + octave) + self.steps[d]

    def chord(self, degree, octave=0, size=3):
        return [self.note(degree + 2 * i, octave) for i in range(size)]

    def scale_notes(self, lo, hi):
        out = []
        for o in range(-3, 5):
            for s in self.steps:
                n = self.root + 12 * o + s
                if lo <= n <= hi:
                    out.append(n)
        return sorted(out)


RHYTHMS = [
    [1, 1, 2], [0.5, 0.5, 1, 2], [1.5, 0.5, 1, 1], [2, 1, 1], [1, 0.5, 0.5, 2], [1, 1, 1, 1], [0.5, 0.5, 0.5, 0.5, 2],
]


def melody(key, prog, rng, lo, hi, start_bar=0, bars=None, phrase=4):
    """Returns [(beat, dur_beats, midi)]. Phrases reuse their rhythm (A A' B A'')
    and resolve on the chord root; strong beats land on chord tones."""
    bars = bars or len(prog)
    scale = key.scale_notes(lo, hi)
    notes = []
    motif = [RHYTHMS[int(rng.integers(len(RHYTHMS)))] for _ in range(phrase)]
    b_motif = [RHYTHMS[int(rng.integers(len(RHYTHMS)))] for _ in range(phrase)]
    cur = scale[len(scale) // 2]
    for bar in range(start_bar, bars):
        ph = (bar // phrase) % 4
        rhythm = (b_motif if ph == 2 else motif)[bar % phrase]
        last_in_phrase = bar % phrase == phrase - 1
        if last_in_phrase:
            rhythm = [2, 2] if ph != 1 else [1, 1, 2]
        chord_pcs = {(key.note(prog[bar] + 2 * i)) % 12 for i in range(3)}
        beat = 0.0
        for j, r in enumerate(rhythm):
            strong = beat in (0.0, 2.0) or r >= 2
            if last_in_phrase and j == len(rhythm) - 1:
                target = [n for n in scale if n % 12 == key.note(prog[bar]) % 12]
                cur = min(target, key=lambda n: abs(n - cur))
            elif strong:
                cands = [n for n in scale if n % 12 in chord_pcs]
                cands.sort(key=lambda n: abs(n - cur) + rng.uniform(0, 2.5))
                cur = cands[0]
            else:
                i = scale.index(cur) if cur in scale else len(scale) // 2
                step = int(rng.choice([-2, -1, -1, 1, 1, 2]))
                cur = scale[max(0, min(len(scale) - 1, i + step))]
            notes.append((bar * 4 + beat, r, cur))
            beat += r
    return notes


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------


class Track:
    def __init__(self, seconds, pan=0.0, gain=1.0, send=0.25):
        self.x = np.zeros(D.length(seconds))
        self.pan, self.gain, self.send = pan, gain, send

    def add(self, audio, t):
        self.x = D.mix_at(self.x, audio, t)


def mixdown(tracks, loop_s, reverb_size=0.85):
    n = D.length(loop_s)
    longest = max(len(t.x) for t in tracks)
    dry = np.zeros((longest, 2))
    send = np.zeros(longest)
    for t in tracks:
        mono = np.zeros(longest)
        mono[:len(t.x)] = t.x
        dry += D.pan(mono * t.gain, t.pan)
        send += mono * t.gain * t.send
    wet = D.reverb(np.concatenate([send, np.zeros(D.length(2.5))]), reverb_size, 4200)
    full = np.zeros((len(wet), 2))
    full[:longest] += dry
    full += wet * 0.9
    # fold everything past the loop end back onto the start: seamless loop
    out = full[:n].copy()
    tail = full[n:]
    k = 0
    while k < len(tail):
        m = min(n, len(tail) - k)
        out[:m] += tail[k:k + m]
        k += n
    out = D.drive(out * 1.2, 1.3)
    return out


def beats_to_s(bpm):
    return 60.0 / bpm


def render_piece(spec, seed=0):
    bpm, key, prog = spec["bpm"], spec["key"], spec["prog"]
    bar_s = 4 * beats_to_s(bpm)
    bars = len(prog)
    loop_s = bars * bar_s
    rng = D.rng(seed)
    b = beats_to_s(bpm)
    stems = {}
    for layer, parts in spec["layers"].items():
        tracks = []
        for part in parts:
            tracks.append(part(key, prog, bpm, bars, b, loop_s, rng))
        mix = mixdown(tracks, loop_s, spec.get("reverb", 0.85))
        stems[layer] = mix
    # common gain: calm peaks ~0.62, combat scaled with the same factor so the
    # sum of both (what plays in a fight) stays under the bus limiter.
    peak = max(np.max(np.abs(stems["calm"])), 1e-6)
    stems["calm"] = stems["calm"] * (0.62 / peak)
    calm_rms = np.sqrt(np.mean(stems["calm"] ** 2))
    for k in stems:
        if k == "calm":
            continue
        # the combat stem sits ~2 dB above the calm one, never louder than it peaks
        rms = max(np.sqrt(np.mean(stems[k] ** 2)), 1e-9)
        stems[k] = stems[k] * (calm_rms * 1.26 / rms)
        p = np.max(np.abs(stems[k]))
        if p > 0.62:
            stems[k] *= 0.62 / p
    return stems


# --- parts ------------------------------------------------------------------------------

def part_lute_arp(octave=0, gain=0.55, pan=-0.25, pattern=(0, 2, 1, 2, 3, 2, 1, 2), start=0, inst=None):
    inst = inst or lute

    def fn(key, prog, bpm, bars, b, loop_s, rng):
        tr = Track(loop_s + 3, pan, gain, 0.3)
        for bar in range(start, bars + 1):
            deg = prog[bar % bars]
            ch = key.chord(deg, octave - 1, 3) + [key.note(deg, octave)]
            for i, p in enumerate(pattern):
                t = (bar * 4 + i * 0.5) * b
                vel = (1.0 if i % 4 == 0 else 0.72) * rng.uniform(0.9, 1.05)
                tr.add(inst(D.midi(ch[p]), b * 0.5, vel, int(rng.integers(1 << 30))), t + rng.uniform(0, 0.008))
        return tr
    return fn


def part_pad(octave=-1, gain=0.22, cutoff=1300.0, start=0, sus=False):
    def fn(key, prog, bpm, bars, b, loop_s, rng):
        tr = Track(loop_s + 3, 0.0, gain, 0.5)
        for bar in range(start, bars + 1):
            deg = prog[bar % bars]
            notes = key.chord(deg, octave, 3 if not sus else 4)
            tr.add(pad([D.midi(n) for n in notes], 4 * b, 1.0, bar, cutoff), bar * 4 * b)
        return tr
    return fn


def part_melody(inst=flute, lo=74, hi=88, gain=0.42, pan=0.2, start=4, seed=7):
    def fn(key, prog, bpm, bars, b, loop_s, rng):
        tr = Track(loop_s + 3, pan, gain, 0.35)
        mrng = D.rng(seed)
        for beat, dur, n in melody(key, prog, mrng, lo, hi, start, bars):
            tr.add(inst(D.midi(n), dur * b * 0.95, mrng.uniform(0.85, 1.0), int(mrng.integers(1 << 30))), beat * b)
        return tr
    return fn


def part_bass(octave=-2, gain=0.5, pattern=((0, 1.5), (1.5, 0.5), (2, 2)), start=0):
    def fn(key, prog, bpm, bars, b, loop_s, rng):
        tr = Track(loop_s + 3, 0.0, gain, 0.12)
        for bar in range(start, bars + 1):
            deg = prog[bar % bars]
            for beat, dur in pattern:
                n = key.note(deg, octave + 1) if beat == 1.5 else key.note(deg, octave)
                tr.add(bass(D.midi(n), dur * b, 0.9, int(rng.integers(1 << 30))), (bar * 4 + beat) * b)
        return tr
    return fn


def part_frame_drum(gain=0.35, pattern=(0, 2), start=0, shaker_from=None):
    def fn(key, prog, bpm, bars, b, loop_s, rng):
        tr = Track(loop_s + 3, -0.1, gain, 0.2)
        for bar in range(start, bars + 1):
            for beat in pattern:
                tr.add(frame_drum(1.0 if beat == 0 else 0.7, int(rng.integers(1 << 30))), (bar * 4 + beat) * b)
            if shaker_from is not None and bar >= shaker_from:
                for i in range(8):
                    tr.add(shaker(0.5 if i % 2 else 0.25, int(rng.integers(1 << 30))), (bar * 4 + i * 0.5) * b)
        return tr
    return fn


def part_taiko(gain=0.7):
    def fn(key, prog, bpm, bars, b, loop_s, rng):
        tr = Track(loop_s + 3, 0.0, gain, 0.18)
        for bar in range(bars + 1):
            for beat, vel in ((0, 1.0), (1.5, 0.6), (2, 0.9), (3, 0.6), (3.5, 0.5)):
                tr.add(taiko(vel, int(rng.integers(1 << 30))), (bar * 4 + beat) * b)
            if bar % 4 == 3:
                for i in range(4):
                    tr.add(taiko(0.35 + 0.15 * i, int(rng.integers(1 << 30))), (bar * 4 + 3 + i * 0.25) * b)
        return tr
    return fn


def part_rim(gain=0.3):
    def fn(key, prog, bpm, bars, b, loop_s, rng):
        tr = Track(loop_s + 3, 0.3, gain, 0.2)
        for bar in range(bars + 1):
            for beat in (1, 3):
                tr.add(rim(1.0, int(rng.integers(1 << 30))), (bar * 4 + beat) * b)
            for beat in (0.5, 1.5, 2.5, 3.5):
                tr.add(shaker(0.6, int(rng.integers(1 << 30))), (bar * 4 + beat) * b)
        return tr
    return fn


def part_ostinato(octave=-2, gain=0.42):
    def fn(key, prog, bpm, bars, b, loop_s, rng):
        tr = Track(loop_s + 3, -0.15, gain, 0.2)
        for bar in range(bars + 1):
            deg = prog[bar % bars]
            for i in range(8):
                n = key.note(deg, octave + (1 if i in (3, 7) else 0))
                vel = 1.0 if i in (0, 3, 6) else 0.6
                tr.add(strings(D.midi(n), b * 0.42, vel, int(rng.integers(1 << 30))), (bar * 4 + i * 0.5) * b)
        return tr
    return fn


def part_choir(octave=0, gain=0.3):
    def fn(key, prog, bpm, bars, b, loop_s, rng):
        tr = Track(loop_s + 3, 0.1, gain, 0.45)
        for bar in range(bars + 1):
            deg = prog[bar % bars]
            tr.add(choir([D.midi(n) for n in key.chord(deg, octave - 1, 3)], 4 * b, 1.0, bar), bar * 4 * b)
        return tr
    return fn


def part_bells(gain=0.25, every=2, octave=1):
    def fn(key, prog, bpm, bars, b, loop_s, rng):
        tr = Track(loop_s + 3, 0.35, gain, 0.5)
        for bar in range(0, bars + 1, every):
            deg = prog[bar % bars]
            for i, n in enumerate(key.chord(deg, octave, 3)):
                tr.add(bellnote(D.midi(n), b, 0.8, bar + i), (bar * 4 + 1.0 + i * 0.5) * b)
        return tr
    return fn


# ---------------------------------------------------------------------------
# Pieces
# ---------------------------------------------------------------------------

# Degrees are 0-based scale degrees of the key (0 = tonic).
GROVE = {
    # D dorian: i  VII  IV  i | i  VII  IV  i | III  VII  IV  v | i  VII  IV  i
    "bpm": 96, "key": Key(62, "dorian"),
    "prog": [0, 6, 3, 0, 0, 6, 3, 0, 2, 6, 3, 4, 0, 6, 3, 0],
    "layers": {
        "calm": [part_lute_arp(), part_pad(), part_melody(flute, 74, 88, 0.42, 0.2, 4, 11),
                 part_bass(gain=0.4), part_frame_drum(0.3, (0, 2), 0, 8)],
        "combat": [part_taiko(0.75), part_ostinato(), part_choir(0, 0.28), part_rim(0.28)],
    },
}

TITLE = {
    # A aeolian, slow music-box harp: i VI III VII | i VI iv v ...
    "bpm": 72, "key": Key(57, "aeolian"),
    "prog": [0, 5, 2, 6, 0, 5, 3, 4, 0, 5, 2, 6, 3, 5, 4, 0],
    "layers": {
        "calm": [part_lute_arp(1, 0.5, -0.2, (0, 1, 2, 3, 2, 1, 2, 1), 0, harp), part_pad(-1, 0.2, 1100),
                 part_melody(bellnote, 76, 91, 0.35, 0.3, 4, 23), part_bass(-2, 0.3, ((0, 4),))],
    },
    "reverb": 0.92,
}

HUB = {
    # G mixolydian, a warm tavern-by-the-fire loop: I  bVII  IV  I | vi  IV  V  I
    "bpm": 84, "key": Key(55, "mixolydian"),
    "prog": [0, 6, 3, 0, 5, 3, 4, 0, 0, 6, 3, 0, 5, 3, 4, 0],
    "layers": {
        "calm": [part_lute_arp(0, 0.5, -0.3, (0, 2, 1, 2, 3, 2, 1, 2)), part_melody(flute, 71, 86, 0.38, 0.25, 2, 5),
                 part_bass(-2, 0.38), part_frame_drum(0.26, (0, 2.5), 0, 4), part_pad(-1, 0.14, 1000)],
    },
}

PIECES = {"grove": GROVE, "title": TITLE, "hub": HUB}


def render_all(only=None):
    out = {}
    for name, spec in PIECES.items():
        if only and name not in only:
            continue
        out[name] = render_piece(spec, seed=zlib.crc32(name.encode()) & 0xFFFF)
    return out
