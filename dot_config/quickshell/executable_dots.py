#!/usr/bin/env python3
"""Bakes wallpapers into a dot matrix, after glyph-rice's wallpaper shader:
the image is cut into 15 px cells and each cell becomes one round dot, its
brightness the cell's grey, from true black up to Theme.qml's `text`.
Black and not the shell's `ground`, as glyph does: the desk's tiles sit on
`panel` just above it, so the screen reads AMOLED-black and the tiles lift
off it, where a grey ground made the whole desk read grey.

    ~/.local/share/chezmoi/dot_config/quickshell/executable_dots.py IMAGE...

writes IMAGE's name + "-dots.png" beside each. Run it on the chezmoi source
copy (dot_config/wallpapers/) to keep the result; then pick it in waypaper.

One size for every monitor, 3840x2160 (256 x 144 cells): the 4K draws it 1:1,
1440p and 1080p scale it down, so dots stay round and sharp everywhere.
ponytail: bake per resolution if a monitor ever shows them soft.

Checked by dots.test.py (source only).
"""
import pathlib
import re
import subprocess
import sys

import numpy as np
from PIL import Image, ImageOps

W, H, CELL = 3840, 2160, 15
RADIUS = 0.3 * CELL  # glyph's dot: 0.3 of the pitch
# The darkest dot, as a share of the way from black to text. Keeps black areas
# a faint, even grid instead of a hole; anything brighter is left alone.
FLOOR = 0.06


def tone(x, c=2.0, p=0.45):
    """grain.py office()'s S-curve, copied: the two scripts can't import each
    other (executable_ in the source, plain once deployed). Retune both."""
    return x**c * (1 + p**c) / (x**c + p**c)


def dots(im, hi):
    grey = np.asarray(ImageOps.fit(im.convert("L"), (W, H), Image.LANCZOS), float) / 255
    lum = np.maximum(tone(grey.reshape(H // CELL, CELL, W // CELL, CELL).mean(axis=(1, 3))), FLOOR)
    # One cell's dot coverage, antialiased by distance from the dot's edge;
    # the centre pixel sits exactly on the cell's centre (CELL is odd).
    off = np.arange(CELL) + 0.5 - CELL / 2
    cover = np.clip(RADIUS + 0.5 - np.hypot(off[:, None], off[None, :]), 0, 1)
    t = np.repeat(np.repeat(lum, CELL, 0), CELL, 1) * np.tile(cover, (H // CELL, W // CELL))
    return Image.fromarray(np.round(hi * t[..., None]).astype(np.uint8), "RGB")


def text_grey():
    """Theme.qml's dark `text`, from the chezmoi source as grain.py reads its
    grounds: the brightest a dot gets."""
    src = subprocess.run(["chezmoi", "source-path"], capture_output=True, text=True, check=True).stdout.strip()
    theme = pathlib.Path(src, "dot_config/quickshell/exact_xeome/Theme.qml").read_text()
    hexc = re.search(r'property color text: light \? "#\w{8}" : "#\w\w(\w{6})"', theme)[1]
    return np.array([int(hexc[i : i + 2], 16) for i in (0, 2, 4)])


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    hi = text_grey()
    for arg in sys.argv[1:]:
        path = pathlib.Path(arg)
        out = path.with_name(f"{path.stem}-dots.png")
        dots(Image.open(path), hi).save(out, optimize=True)
        print(out)
