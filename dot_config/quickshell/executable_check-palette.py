#!/usr/bin/env python3
"""Guards the two claims the Caffeine palette makes that a human can't eyeball.

1. The contrast floors asserted in Theme.qml's comments, in both modes.
   The smallest text on this desktop is 10px, so a token drifting to 3:1 is a
   legibility bug that only shows up on the one label nobody looks at.
2. That the terminals, the compositor and the shell agree. The whole point of
   pinning a scheme is that #111111 is #111111 everywhere; six config files in
   four syntaxes is exactly where that silently stops being true.

Run it after touching any palette:  ~/.config/quickshell/check-palette.py
"""
import pathlib
import re
import subprocess
import sys

# The chezmoi source tree, not the deployed targets. Machine-specific
# .chezmoiignore rules mean the sway palette is absent on a hyprland box and
# vice versa, and a stale unmanaged leftover at the target path would be
# reported as drift in a file chezmoi does not own. Checking the source
# instead covers every machine's palette from any one of them.
SRC = pathlib.Path(
    subprocess.run(
        ["chezmoi", "source-path"], capture_output=True, text=True, check=True
    ).stdout.strip()
)
THEME = SRC / "dot_config/quickshell/xeome/Theme.qml"


def tokens(mode):
    """{name: '#rrggbb'} for one mode, read out of Theme.qml's ternaries."""
    pat = re.compile(r'property color (\w+): light \? "(#\w+)" : "(#\w+)"')
    return {
        m[1]: (m[2] if mode == "light" else m[3])
        for m in pat.finditer(THEME.read_text())
    }


def luminance(hex6):
    def chan(v):
        v /= 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4

    r, g, b = (int(hex6[i : i + 2], 16) for i in (1, 3, 5))
    return 0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(b)


def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)))
    return (lb + 0.05) / (la + 0.05)


# (text, ground, floor) — the floor each comment in Theme.qml claims.
PAIRS = [
    ("fg", "bar", 7.0),
    ("fg", "panel", 7.0),
    ("fg", "surface", 7.0),
    ("fgDim", "panel", 4.5),
    ("fgMuted", "panel", 4.5),   # 9px Power detail line, the tightest case
    ("fgMuted", "bar", 4.5),
    ("fgMuted", "surface", 4.5),       # Audio's muted label sits on a module fill
    ("fgMuted", "surfaceHover", 4.5),  # ...and on the hover fill under the pointer
    ("accent", "bar", 4.5),      # accent also draws as text, not just as fill
    ("fgOnAccent", "accent", 4.5),
    ("fgOnAccent", "warn", 4.5),
    ("fg", "toggle", 4.5),       # toggle fills carry ordinary fg, not fgOnAccent
]

# A visible hairline is the only separator in this shell — nothing casts a
# shadow — so the border has to actually differ from what it sits on. Caffeine's
# own #201e18 fails this against #191919, which is why Theme.qml lifts it.
SEPARATORS = [("border", "panel"), ("border", "bar"), ("divider", "panel")]

fails = []

for mode in ("light", "dark"):
    t = tokens(mode)
    for text, ground, floor in PAIRS:
        ratio = contrast(t[text], t[ground])
        if ratio < floor:
            fails.append(
                f"{mode}: {text} on {ground} is {ratio:.2f}:1, floor {floor}"
            )
    for edge, ground in SEPARATORS:
        ratio = contrast(t[edge], t[ground])
        if ratio < 1.12:
            fails.append(
                f"{mode}: {edge} is invisible on {ground} ({ratio:.3f}:1)"
            )

# Every source file that hardcodes a surface or the accent, and what it must
# say. Matched as plain text with runs of whitespace collapsed: six syntaxes,
# and a parser for each would be more code than the thing it checks — but the
# alignment padding inside them is nobody's business.
SHARED = {
    "dot_config/ghostty/themes/caffeine": ("background = #111111", "cursor-color = #ffe0c2"),
    "dot_config/ghostty/themes/caffeine-light": ("background = #f9f9f9", "cursor-color = #644a40"),
    "dot_config/alacritty/caffeine.toml": ('background = "#111111"', 'cursor = "#ffe0c2"'),
    "dot_config/foot/foot.ini": ("background=111111", "cursor=081a1b ffe0c2"),
    "dot_config/hypr/lua_modules/colors.lua": ('background = "rgb(111111)"', 'primary = "rgb(FFE0C2)"'),
    "dot_config/sway/conf.d/colors.conf": ("set $background #111111", "set $primary #ffe0c2"),
    "dot_config/gtklock/style.css": ("@define-color background #111111;", "@define-color primary #ffe0c2;"),
    "dot_config/rofi/private_shared/colors.rasi": ("background: #111111;", "selected: #ffe0c2;"),
    "dot_local/private_share/vicinae/themes/caffeine.toml": ('background = "#111111"', 'accent = "#ffe0c2"'),
}


def flat(text):
    return re.sub(r"[ \t]+", " ", text)


for rel, needles in SHARED.items():
    body = flat((SRC / rel).read_text())
    for needle in needles:
        if flat(needle) not in body:
            fails.append(f"{rel} has drifted: expected {needle!r}")

if fails:
    print("\n".join(fails), file=sys.stderr)
    sys.exit(1)
print("palette OK")
