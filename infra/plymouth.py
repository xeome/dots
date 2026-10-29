#!/usr/bin/env python3
"""Draws the splash images into files/plymouth/. Run it by hand after adding
a machine to .chezmoidata.toml, and commit the PNGs:

    python3 -I ~/.local/share/chezmoi/infra/plymouth.py

lock/entry/bullet.png are 1x1 black: two-step will not start without them,
and only a password prompt (no LUKS here) shows them.

two-step centres the watermark and the progress frames on the same point, so
each frame carries transparent space above its row to drop it below the name.
ponytail: drawn 1:1, plymouth doubles them on hidpi; draw @2x if a laptop's
splash looks soft.
"""
import pathlib
import tomllib

from PIL import Image, ImageDraw, ImageFont

INFRA = pathlib.Path(__file__).resolve().parent
SRC = INFRA.parent
OUT = INFRA / "files/plymouth"
FONT = SRC / "dot_local/private_share/fonts/Doto[ROND,wght].ttf"

BRIGHT = (247, 248, 248, 255)  # Theme.qml bright
UNLIT = (26, 26, 28, 255)      # Desk.qml's unlit dot
SS = 4                         # supersampling

SIZE = 64                      # wordmark px
DOTS, PITCH, R = 24, 16, 3.5
DROP = 72                      # wordmark centre to dot row centre


def shrink(im):
    return im.resize((im.width // SS, im.height // SS), Image.LANCZOS)


def watermark(name):
    font = ImageFont.truetype(str(FONT), SIZE * SS)
    font.set_variation_by_axes([100, 900])  # ROND, wght
    l, t, r, b = font.getbbox(name)
    im = Image.new("RGBA", (r - l + 2 * SS, b - t + 2 * SS), (0, 0, 0, 0))
    ImageDraw.Draw(im).text((SS - l, SS - t), name, font=font, fill=BRIGHT)
    return shrink(im)


def progress(lit):
    w, h = DOTS * PITCH * SS, int(2 * (DROP + R + 1)) * SS
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    y, r = h - (R + 1) * SS, R * SS
    for i in range(DOTS):
        x = (i + 0.5) * PITCH * SS
        d.ellipse((x - r, y - r, x + r, y + r), fill=BRIGHT if i < lit else UNLIT)
    return shrink(im)


if __name__ == "__main__":
    hosts = tomllib.loads((SRC / ".chezmoidata.toml").read_text())["machines"]
    for host in hosts:
        watermark(host).save(OUT / f"watermark-{host}.png")
    for lit in range(DOTS + 1):
        progress(lit).save(OUT / f"progress-{lit:04d}.png")
    for name in ("lock", "entry", "bullet"):
        Image.new("RGBA", (1, 1), (0, 0, 0, 255)).save(OUT / f"{name}.png")
    print(f"{len(hosts)} watermarks, {DOTS + 1} progress frames -> {OUT}")
