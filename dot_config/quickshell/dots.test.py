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

BLACK = np.array([0, 0, 0])
# Black, grey byte 115 and white, a third of the width each.
src = np.zeros((2160, 3840), np.uint8)
src[:, 1280:2560] = 115
src[:, 2560:] = 255
out = np.asarray(dots.dots(Image.fromarray(src, "L"), np.array([0xE6, 0xE7, 0xEA])))

assert out.shape == (2160, 3840, 3), out.shape
c = 7 + 15 * 10  # a cell centre, ten cells in from the top
black, grey, white = (out[c, 7 + 15 * k] for k in (20, 120, 220))

# Dark areas keep a faint grid: 6% of the way from black to text.
assert black.tolist() == [14, 14, 14], black
# Grey goes through grain.py's S-curve: #E6E7EA × S(115/255).
assert grey.tolist() == [139, 139, 141], grey
assert white.tolist() == [0xE6, 0xE7, 0xEA], white
# Round, not square: (+4, +4) from a centre is 5.7 px out, past the 4.5 px radius.
for k in (20, 120, 220):
    assert out[c + 4, 7 + 15 * k + 4].tolist() == BLACK.tolist(), (k, out[c + 4, 7 + 15 * k + 4])

print("dots OK")
