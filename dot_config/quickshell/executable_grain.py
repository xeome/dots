#!/usr/bin/env python3
"""Bakes graphite's grain into the tiles xeome/Surface.qml draws, and into
hyprlock's background.

Graphite blends its noise as `overlay` at 30% (graphite-ui components.md), so
the grain darkens and lightens a near-black ground without lifting it. QML has
no blend modes. But every surface here is one flat, known colour, so the
overlay result can be worked out ahead of time and stored as a plain
normal-blend tile: black where overlay darkens, white where it lightens.

One tile per ground, because overlay depends on the colour underneath. A tile
built for #0A0A0C is off by up to 3.4 levels on #151618.

Needs rsvg-convert, numpy and pillow. It runs on demand, not at apply time;
rerun it after changing `ground`, `panel` or `raised` in Theme.qml, then
apply the quickshell and Discord themes:

    ~/.local/share/chezmoi/dot_config/quickshell/executable_grain.py
"""
import io
import pathlib
import re
import subprocess

import numpy as np
from PIL import Image

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


def lock(g, a, w=1920, h=1200):
    """hyprlock's background: graphite's shell ground with its corner glow,
    radial-gradient(600px 300px at 0 0, --glow, transparent 75%), and the grain
    overlaid exactly, pixel by pixel, since the glow means no flat base. 1920x1200
    in logical pixels: hyprlock draws it at 2x on a scale-2 monitor, which is
    where graphite's CSS grain would land too."""
    ys, xs = np.mgrid[0:h, 0:w] + 0.5
    glow = 0.05 * np.clip(1 - np.hypot(xs / 600, ys / 300) / 0.75, 0, 1)[..., None]
    ground = np.array([int(GROUNDS["ground"][i : i + 2], 16) / 255 for i in (1, 3, 5)])
    base = ground * (1 - glow) + glow
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
