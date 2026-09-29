"""Renders every sound effect (and the music) into assets/audio/.

    python3 tools/audio/build_audio.py          # everything
    python3 tools/audio/build_audio.py sfx      # effects only
    python3 tools/audio/build_audio.py music    # music only
    python3 tools/audio/build_audio.py sfx coin swing   # some effects
"""

import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

import numpy as np  # noqa: E402

import dsp as D  # noqa: E402


def build_sfx(only=None):
    import sfx
    out = os.path.join(ROOT, "assets", "audio", "sfx")
    os.makedirs(out, exist_ok=True)
    total = 0
    for name, (fn, variants) in sorted(sfx.R.items()):
        if only and name not in only:
            continue
        for v in range(variants):
            x = np.asarray(fn(v))
            if x.ndim == 2 and np.max(np.abs(x[:, 0] - x[:, 1])) < 1e-6:
                x = x[:, 0]
            # trim trailing near-silence
            mag = np.abs(x) if x.ndim == 1 else np.abs(x).max(axis=1)
            idx = np.nonzero(mag > 10 ** (-60 / 20))[0]
            if len(idx):
                x = x[:min(len(x), idx[-1] + D.length(0.02))]
            x = D.fade(x, 0.0005, 0.01)
            fname = f"{name}.wav" if variants == 1 else f"{name}_{v + 1}.wav"
            D.write_wav(os.path.join(out, fname), x)
            total += 1
    print("sfx files:", total)


def build_music(only=None):
    import music
    out = os.path.join(ROOT, "assets", "audio", "music")
    os.makedirs(out, exist_ok=True)
    for name, layers in music.render_all(only).items():
        for layer, x in layers.items():
            path = os.path.join(out, f"{name}_{layer}.ogg")
            D.write_ogg(path, x)
            print("music", os.path.basename(path), f"{len(x) / D.SR:.1f}s")


if __name__ == "__main__":
    t0 = time.time()
    args = sys.argv[1:]
    what = args[0] if args else "all"
    rest = args[1:] or None
    if what in ("all", "sfx"):
        build_sfx(rest)
    if what in ("all", "music"):
        build_music(rest)
    print(f"done in {time.time() - t0:.1f}s")
