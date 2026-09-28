"""Regenerates every model in assets/models from code.

    python3 tools/blender/build_all.py            # uses the `bpy` pip module
    blender -b -P tools/blender/build_all.py      # or a real Blender 4.2+
    python3 tools/blender/build_all.py knight     # only some groups

Pass --preview to also render review PNGs into tools/blender/out/.
"""

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "assets", "models")
PREVIEW = os.path.join(HERE, "out")

import knight  # noqa: E402

GROUPS = {
    "knight": lambda pv: knight.build(OUT, pv),
    "book": lambda pv: knight.build_book(OUT, pv),
}

try:
    import errata  # noqa: E402
    GROUPS.update(errata.GROUPS(OUT))
except ImportError as e:
    print("errata module not available:", e)

try:
    import props  # noqa: E402
    GROUPS.update(props.GROUPS(OUT))
except ImportError as e:
    print("props module not available:", e)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    if "--" in sys.argv:
        args = [a for a in sys.argv[sys.argv.index("--") + 1:] if not a.startswith("-")]
    preview = PREVIEW if "--preview" in sys.argv else None
    if preview:
        os.makedirs(preview, exist_ok=True)
    wanted = args or list(GROUPS.keys())
    for name in wanted:
        if name not in GROUPS:
            print("unknown group", name)
            continue
        print("== building", name)
        GROUPS[name](preview)


if __name__ == "__main__":
    main()
