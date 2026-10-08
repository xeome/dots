#!/usr/bin/env python3
"""Bakes graphite's grain into the tiles xeome/Surface.qml draws, into
hyprlock's background, and into the office wallpaper.

Graphite blends its noise as `overlay` at 30% (graphite-ui components.md), so
the grain darkens and lightens a near-black ground without lifting it. QML has
no blend modes. But every surface here is one flat, known colour, so the
overlay result can be worked out ahead of time and stored as a plain
normal-blend tile: black where overlay darkens, white where it lightens.

One tile per ground, because overlay depends on the colour underneath. A tile
built for #0A0A0C is off by up to 3.4 levels on #151618.

Needs rsvg-convert, numpy, scipy and pillow. It runs on demand, not at apply time;
rerun it after changing `ground`, `panel` or `raised` in Theme.qml, then
apply the quickshell and Discord themes:

    ~/.local/share/chezmoi/dot_config/quickshell/executable_grain.py
"""
import io
import pathlib
import re
import subprocess

import numpy as np
from PIL import Image, ImageOps
from scipy.ndimage import gaussian_filter, zoom

# graphite's --grain, verbatim.
SVG = b"""<svg xmlns='http://www.w3.org/2000/svg' width='160' height='160'><filter id='n'><feTurbulence type='fractalNoise' baseFrequency='.9' numOctaves='3' stitchTiles='stitch'/><feColorMatrix values='.33 .33 .33 0 0 .33 .33 .33 0 0 .33 .33 .33 0 0 0 0 0 0 1'/></filter><rect width='100%' height='100%' filter='url(#n)' opacity='.3'/></svg>"""

# The chezmoi source, not this file's folder: run from ~/.config/quickshell, the
# tiles would land in the target, and the next apply would put the old ones back.
SRC = pathlib.Path(
    subprocess.run(
        ["chezmoi", "source-path"], capture_output=True, text=True, check=True
    ).stdout.strip()
)
OUT = SRC / "dot_config/quickshell/xeome"
THEME = OUT / "Theme.qml"

# The dark grounds, read from Theme.qml so a retuned ground can't leave a tile
# baked for the old one. panel is not drawn by Quickshell: the Discord theme
# embeds it under its chat (private_vesktop/themes/graphite.theme.css.tmpl).
GROUNDS = {
    m[1]: "#" + m[2][2:]
    for m in re.finditer(r'property color (ground|panel|raised): light \? "#\w{8}" : "#(\w{8})"', THEME.read_text())
}


def render():
    png = subprocess.run(
        ["rsvg-convert"], input=SVG, capture_output=True, check=True
    ).stdout
    rgba = np.asarray(Image.open(io.BytesIO(png)).convert("RGBA"), float) / 255
    return rgba[..., 0], rgba[..., 3]  # grey value, layer alpha (.3)


def bake(base, g, a):
    """Normal-blend RGBA tile that reproduces `overlay` of (g, a) over base."""
    over = np.where(base < 0.5, 2 * base * g, 1 - 2 * (1 - base) * (1 - g))
    d = a * (over - base)  # what overlay adds to each pixel
    white = np.where(d > 0, d / (1 - base), 0)
    black = np.where(d < 0, -d / base, 0)
    tile = np.zeros(g.shape + (4,))
    tile[..., :3] = (white > 0)[..., None]
    tile[..., 3] = white + black
    return tile


def smooth_noise(h, w, cell, seed):
    """Unit-variance noise with features about `cell` pixels across."""
    r = np.random.default_rng(seed).standard_normal((h // cell + 3, w // cell + 3))
    n = gaussian_filter(zoom(r, cell, order=3)[:h, :w], cell / 4)
    return (n - n.mean()) / n.std()


def lock(g, a, w=2560, h=1440):
    """hyprlock's background: graphite's shell ground under faint topographic
    lines, every fifth one brighter, fading towards the edges, with the grain
    overlaid exactly, pixel by pixel. A corner glow alone read as a monitor's
    light leak once it filled a whole screen. Lines cover the screen evenly and
    line up with nothing, so hyprlock can scale it to any monitor. Sized for
    the largest one, 2560x1440; the seeds keep the map the same on each run."""
    ys, xs = np.mgrid[0:h, 0:w] + 0.5
    n = 9 * (smooth_noise(h, w, 420, 3) + 0.4 * smooth_noise(h, w, 160, 4))
    f = n % 1
    line = np.clip(1 - np.minimum(f, 1 - f) / 0.045, 0, 1)
    major = np.floor(n) % 5 == 0
    edge = np.hypot((xs - w / 2) / (w / 2), (ys - h / 2) / (h / 2))
    fade = np.clip(1 - 1.1 * (edge / 1.4) ** 2, 0, 1)
    lum = (line * np.where(major, 0.095, 0.045) * fade)[..., None]
    return grained(on_ground(lum), g, a)


def office(g, a, w=2560, h=1440):
    """The office photo in graphite: its blue cast dropped to grey, its black
    lifted to the shell ground, and the grain overlaid. Cropped to the largest
    monitor so the grain lands 1:1 on its pixels."""
    im = ImageOps.fit(Image.open(SRC / "dot_config/wallpapers/office.jpg"), (w, h), Image.LANCZOS)
    x = np.asarray(im.convert("L"), float)[..., None] / 255
    # An S-curve through 0 and 1: shadows sink, the window brightens. Raise
    # `c` for harder contrast; `p` is the grey where it turns from darkening to
    # brightening. Tuned by eye; 2.4 reads moodier.
    c, p = 2.0, 0.45
    lum = x**c * (1 + p**c) / (x**c + p**c)
    return grained(on_ground(lum), g, a)


def on_ground(lum):
    """Greys from lum, with black at graphite's shell ground instead of #000."""
    ground = np.array([int(GROUNDS["ground"][i : i + 2], 16) / 255 for i in (1, 3, 5)])
    return ground * (1 - lum) + lum


def grained(base, g, a):
    """base with the grain overlaid exactly, pixel by pixel."""
    h, w = base.shape[:2]
    reps = (h // g.shape[0] + 1, w // g.shape[1] + 1)
    gg = np.tile(g, reps)[:h, :w, None]
    aa = np.tile(a, reps)[:h, :w, None]
    over = np.where(base < 0.5, 2 * base * gg, 1 - 2 * (1 - base) * (1 - gg))
    return base + aa * (over - base)

if __name__ == "__main__":
    g, a = render()
    for name, hexc in GROUNDS.items():
        base = int(hexc[1:3], 16) / 255  # graphite's grounds are near-neutral
        tile = bake(base, g, a)
        Image.fromarray(np.round(tile * 255).astype(np.uint8), "RGBA").save(
            OUT / f"grain-{name}.png", optimize=True
        )
        print(f"grain-{name}.png  max alpha {tile[..., 3].max():.3f}")
    Image.fromarray(np.round(lock(g, a) * 255).astype(np.uint8), "RGB").save(
        SRC / "dot_config/hypr/graphite-lock.png", optimize=True
    )
    print("hypr/graphite-lock.png")
    Image.fromarray(np.round(office(g, a) * 255).astype(np.uint8), "RGB").save(
        SRC / "dot_config/wallpapers/office-graphite.jpg", quality=95
    )
    print("wallpapers/office-graphite.jpg")
