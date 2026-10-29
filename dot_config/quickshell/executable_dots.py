#!/usr/bin/env python3
"""Bakes wallpapers into a dot matrix: the image is cut into 15 px cells and
each cell becomes one round dot, its brightness the cell's grey, from true
black up to CAP of Theme.qml's `text`, so the wallpaper never outshines the
text over it. Each dot keeps SAT of the cell's own colour, so a grey photo
bakes grey; the cap holds for the grey, while a saturated dot's strongest
channel can sit a little above it (cyan reaches 209 where white stops at 199). The dots dim towards the corners and carry a little grain. True
black, not the shell's `ground`, because the desk's tiles sit on `panel` just
above it and must lift off the screen.

    ~/.local/share/chezmoi/dot_config/quickshell/executable_dots.py [--out DIR] IMAGE...

writes IMAGE's name + "-dots.png" beside each, or into DIR. Run it on the
chezmoi source copy (dot_config/wallpapers/) to keep the result. Walls.qml
runs it with --out ~/.local/share/xeome-dots.

One size for every monitor, 3840x2160 (256 x 144 cells): the 4K draws it 1:1,
1440p and 1080p scale it down, so dots stay round and sharp everywhere.
ponytail: bake per resolution if a monitor ever shows them soft.

Checked by dots.test.py (source only).
"""
import argparse
import os
import pathlib
import re
import subprocess

import numpy as np
from PIL import Image, ImageOps

W, H, CELL = 3840, 2160, 15
RADIUS = 0.3 * CELL  # glyph's dot: 0.3 of the pitch
# The darkest dot, as a share of the way from black to text. Keeps black areas
# a faint grid instead of a hole (dimmed towards the corners with the rest);
# anything brighter is left alone.
FLOOR = 0.06
# Each value below was picked by eye from rendered previews; dots.test.py pins
# them with literals, so a change here wants the same change there.
# The corners fall to VIGNETTE of the centre, starting INNER of the way out
# along the half-diagonal; the floor falls half as far, so the grid never goes.
VIGNETTE, INNER = 0.5, 0.35
# Brightness above KNEE eases into CAP at white, so the brightest dot sits
# below the text read over it.
KNEE, CAP = 0.55, 0.85
SAT = 0.35  # how much of the photo's own colour a dot keeps
# Each dot's brightness varies by this much (one sigma), from a fixed seed so a
# rebake comes out the same.
GRAIN = 0.10


def tone(x, c=2.0, p=0.45):
    """grain.py office()'s S-curve, copied: the two scripts can't import each
    other (executable_ in the source, plain once deployed). Retune both."""
    return x**c * (1 + p**c) / (x**c + p**c)


def ease(x):
    """x below KNEE; above it a curve with slope 1 at KNEE that reaches CAP at 1."""
    a = (1 - KNEE) / (CAP - KNEE)
    u = (x - KNEE) / (1 - KNEE)
    return np.where(x > KNEE, KNEE + (CAP - KNEE) * a * u / (1 + (a - 1) * u), x)


def vignette(k):
    """Per cell: 1 inside INNER, smoothstepping down to 1 - k at the corners."""
    ys, xs = np.mgrid[0 : H // CELL, 0 : W // CELL] + 0.5
    r = np.hypot(xs / (W / CELL / 2) - 1, ys / (H / CELL / 2) - 1) / np.sqrt(2)
    t = np.clip((r - INNER) / (1 - INNER), 0, 1)
    return 1 - k * t * t * (3 - 2 * t)


def dots(im, hi):
    rgb = np.asarray(ImageOps.fit(im.convert("RGB"), (W, H), Image.LANCZOS), float) / 255
    cell = rgb.reshape(H // CELL, CELL, W // CELL, CELL, 3).mean(axis=(1, 3))
    grey = cell @ np.array([0.299, 0.587, 0.114])
    noise = np.random.default_rng(7).normal(0, 1, grey.shape)
    lum = ease(np.clip(tone(grey) * (1 + GRAIN * noise), 0, 1)) * vignette(VIGNETTE)
    # The cell's hue as a per-channel ratio to its grey, moved SAT of the way
    # from 1. Black cells get 1: their lit value is 0 anyway, and 0/0's NaN
    # would win the max below and erase the floor dot.
    hue = np.divide(cell, grey[..., None], out=np.ones_like(cell), where=grey[..., None] > 0)
    lit = hi * (1 + SAT * (hue - 1)) * lum[..., None]
    # The floor stays text's grey, so near-black noise never shows as colour.
    v = np.maximum(lit, hi * FLOOR * vignette(VIGNETTE / 2)[..., None])
    # One cell's dot coverage, antialiased by distance from the dot's edge;
    # the centre pixel sits exactly on the cell's centre (CELL is odd).
    off = np.arange(CELL) + 0.5 - CELL / 2
    cover = np.clip(RADIUS + 0.5 - np.hypot(off[:, None], off[None, :]), 0, 1)
    t = np.repeat(np.repeat(v, CELL, 0), CELL, 1) * np.tile(cover, (H // CELL, W // CELL))[..., None]
    # Strong grain on a bright saturated cell can pass 255, and uint8 would wrap
    # it to near black.
    return Image.fromarray(np.round(np.clip(t, 0, 255)).astype(np.uint8), "RGB")


def text_grey():
    """Theme.qml's dark `text`, from the chezmoi source as grain.py reads its
    grounds: the brightest a dot gets."""
    src = subprocess.run(["chezmoi", "source-path"], capture_output=True, text=True, check=True).stdout.strip()
    theme = pathlib.Path(src, "dot_config/quickshell/exact_xeome/Theme.qml").read_text()
    hexc = re.search(r'property color text: light \? "#\w{8}" : "#\w\w(\w{6})"', theme)[1]
    return np.array([int(hexc[i : i + 2], 16) for i in (0, 2, 4)])


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", type=pathlib.Path)
    ap.add_argument("images", nargs="+", type=pathlib.Path)
    args = ap.parse_args()
    if args.out:
        args.out.mkdir(parents=True, exist_ok=True)
    hi = text_grey()
    for path in args.images:
        out = (args.out or path.parent) / f"{path.stem}-dots.png"
        # Under a hidden name first, then renamed: whoever lists the folder
        # (the picker) only ever sees finished bakes. .png last, since Pillow
        # picks the format from the extension. No optimize=True: 0.4 s of a
        # 0.7 s bake for under 1% of the size.
        tmp = out.with_name(f".{out.stem}.tmp.png")
        dots(Image.open(path), hi).save(tmp)
        os.replace(tmp, out)
        print(out)
