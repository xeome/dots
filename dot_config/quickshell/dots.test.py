#!/usr/bin/env python3
"""python3 -I dot_config/quickshell/dots.test.py — checks executable_dots.py.
Source-only (.chezmoiignore)."""
import importlib.util
import pathlib
import sys

import numpy as np
from PIL import Image

# The import would leave a __pycache__ in the chezmoi source, which deploys it.
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("dots", pathlib.Path(__file__).with_name("executable_dots.py"))
dots = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dots)

HI = np.array([0xE6, 0xE7, 0xEA])  # Theme.qml's dark text


def bake(rgb):
    """A flat field of one colour, baked."""
    return np.asarray(dots.dots(Image.new("RGB", (16, 9), rgb), HI))


def dot(out, row, col):
    """The centre pixel of cell (row, col), where the dot is fully lit."""
    return out[7 + 15 * row, 7 + 15 * col].tolist()


# The expected values below are worked by hand from the knobs the user picked,
# never read from the module: vignette 0.5 from 0.35 of the half-diagonal,
# highlights eased above 0.55 to 0.85, 35% of the photo's colour, floor 0.06.
GRAIN = dots.GRAIN
dots.GRAIN = 0
CENTRE, CORNER, EDGE = (72, 128), (0, 0), (72, 0)

white = bake((255, 255, 255))
assert dot(white, *CENTRE) == [196, 196, 199], dot(white, *CENTRE)  # 0.85 × text
# Corner: smoothstep is 0.9998 there, so 0.85 × 0.5001 × text.
assert dot(white, *CORNER) == [98, 98, 99], dot(white, *CORNER)
# Left-edge midpoint, 0.704 of the half-diagonal: 0.85 × 0.7163 × text.
assert dot(white, *EDGE) == [140, 141, 142], dot(white, *EDGE)

# Byte 90 tones to 0.458, below the knee, so the ease leaves it alone.
assert dot(bake((90, 90, 90)), *CENTRE) == [105, 106, 107]
# Byte 160 tones to 0.794; the ease takes it to 0.742 (0.794 uncapped would be [183, 183, 186]).
assert dot(bake((160, 160, 160)), *CENTRE) == [171, 171, 174]

# Pure red, luma 0.299, tones to 0.368. Its hue ratio keeps 35% of the way
# from grey: R 1 + 0.35 × (1/0.299 − 1) = 1.821, G and B 0.65.
assert dot(bake((255, 0, 0)), *CENTRE) == [154, 55, 56], dot(bake((255, 0, 0)), *CENTRE)

# Black keeps a faint grid in text's own grey: 0.06 × text in the centre, and
# half the vignette (0.75) in the corner.
black = bake((0, 0, 0))
assert dot(black, *CENTRE) == [14, 14, 14], dot(black, *CENTRE)
assert dot(black, *CORNER) == [10, 10, 11], dot(black, *CORNER)
# A dark red lit below the floor shows the plain grey floor, not a red one.
assert dot(bake((20, 0, 0)), *CENTRE) == [14, 14, 14], dot(bake((20, 0, 0)), *CENTRE)

# Round, not square: (+4, +4) from a centre is 5.7 px out, past the 4.5 px radius.
assert white[7 + 15 * 72 + 4, 7 + 15 * 128 + 4].tolist() == [0, 0, 0]

# Grain: the same picture always bakes the same, it varies dots by about 10%,
# and it never lifts a highlight past the 0.85 ease.
dots.GRAIN = GRAIN
grey = bake((90, 90, 90))
assert (grey == bake((90, 90, 90))).all(), "grain differs between runs"
# The middle of the screen, where the vignette is 1: rows 50-94, cols 90-166.
mid = grey[7 + 15 * 50 : 7 + 15 * 95 : 15, 7 + 15 * 90 : 7 + 15 * 167 : 15, 1].astype(float)
spread = mid.std() / mid.mean()
assert 0.08 <= spread <= 0.12, spread
assert (bake((255, 255, 255)).max(axis=(0, 1)) <= [196, 196, 199]).all()

print("dots OK")
