#!/usr/bin/env python3
"""Checks what the graphite palette promises that a human can't eyeball.

1. The contrast floors below, in both modes. Translucent tokens (line, sel,
   hover, card) are measured composited over the surface they sit on.
2. That the configs which repeat a palette value still match Theme.qml.
3. That kvantum.py can still build the Qt theme: it stops on any upstream
   colour it has no Theme.qml token for.

Run it after touching any palette:  ~/.config/quickshell/check-palette.py
"""
import pathlib
import re
import subprocess
import sys
import tempfile

# The chezmoi source, not the deployed targets: .chezmoiignore leaves out the
# sway files on a Hyprland machine and vice versa.
SRC = pathlib.Path(
    subprocess.run(
        ["chezmoi", "source-path"], capture_output=True, text=True, check=True
    ).stdout.strip()
)
THEME = SRC / "dot_config/quickshell/exact_xeome/Theme.qml"


def tokens(mode):
    """{name: (r, g, b, a)} for one mode, read out of Theme.qml's ternaries.

    Qt colour strings are #AARRGGBB, alpha first, unlike CSS's #RRGGBBAA.
    """
    pat = re.compile(r'property color (\w+): light \? "#(\w{8})" : "#(\w{8})"')
    out = {}
    for m in pat.finditer(THEME.read_text()):
        h = m[2] if mode == "light" else m[3]
        a, r, g, b = (int(h[i : i + 2], 16) / 255 for i in (0, 2, 4, 6))
        out[m[1]] = (r, g, b, a)
    return out


def over(top, base):
    """`top` alpha-composited onto an opaque `base`, the way Qt draws it."""
    a = top[3]
    return tuple(t * a + b * (1 - a) for t, b in zip(top[:3], base[:3])) + (1.0,)


def luminance(c):
    def chan(v):
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4

    r, g, b = c[:3]
    return 0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(b)


def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)))
    return (lb + 0.05) / (la + 0.05)


def hexrgb(c):
    return "#" + "".join(f"{round(v * 255):02x}" for v in c[:3])


# (foreground, surface, floor). A surface written "sel/raised" is sel
# composited over raised: a selected menu row.
PAIRS = [
    ("text", "ground", 7.0),
    ("text", "raised", 7.0),
    ("dim", "ground", 4.5),
    ("dim", "raised", 4.5),
    ("dim", "sel/raised", 4.5),     # a selected row's suffix
    ("dim", "hover/raised", 4.5),   # ...and the row under the pointer
    ("dim", "card/ground", 4.5),    # a muted bar module
    ("bright", "sel/raised", 7.0),  # a selected row's label
    ("ground", "hot", 4.5),         # low battery chip
    ("ground", "text", 4.5),        # calendar's today
    ("warm", "card/ground", 4.5),   # the live-mic glyph
]

# A visible edge is the only thing separating one dark surface from another,
# so a line has to actually differ from what it is drawn on.
SEPARATORS = [
    ("line/ground", "ground"),
    ("line/raised", "raised"),
    ("rule", "raised"),
]


def resolve(t, spec):
    """'sel/raised' -> sel composited over raised; 'raised' -> raised."""
    *tops, base = spec.split("/")
    c = t[base]
    for top in reversed(tops):
        c = over(t[top], c)
    return c


fails = []
complete = True

for mode in ("light", "dark"):
    t = tokens(mode)
    missing = ({n for p in PAIRS + SEPARATORS for s in p[:2] for n in s.split("/")}
               | {"ground", "panel", "raised", "text", "warm", "line"}) - set(t)
    if missing:
        fails.append(f"{mode}: Theme.qml lacks {sorted(missing)}")
        complete = False
        continue
    for fg, ground, floor in PAIRS:
        ratio = contrast(resolve(t, fg), resolve(t, ground))
        if ratio < floor:
            fails.append(f"{mode}: {fg} on {ground} is {ratio:.2f}:1, floor {floor}")
    for edge, ground in SEPARATORS:
        ratio = contrast(resolve(t, edge), resolve(t, ground))
        if ratio < 1.12:
            fails.append(f"{mode}: {edge} is invisible on {ground} ({ratio:.3f}:1)")

# Every source file that hardcodes a palette value, and what it must say.
# Matched as plain text with runs of whitespace collapsed rather than parsed:
# the files are in six syntaxes.
if complete:
    dark, light = tokens("dark"), tokens("light")
    D = {k: hexrgb(v) for k, v in dark.items()}
    L = {k: hexrgb(v) for k, v in light.items()}
    rgb = lambda h: ", ".join(str(int(h[i : i + 2], 16)) for i in (1, 3, 5))
    # A translucent token as GTK CSS writes it: rgba(255, 255, 255, 0.05).
    rgba = lambda t: f"rgba({rgb(hexrgb(t))}, {round(t[3], 2):g})"
    SHARED = {
        "dot_config/ghostty/exact_themes/caffeine": (f"background = {D['panel']}",),
        "dot_config/alacritty/caffeine.toml": (f'background = "{D["panel"]}"',),
        "dot_config/foot/foot.ini": (f"background={D['panel'][1:]}",),
        "dot_config/hypr/exact_lua_modules/settings.lua": (
            f'local line = "rgba(ffffff{round(dark["line"][3] * 255):02x})"',
        ),
        "dot_config/sway/conf.d/colors.conf": (
            f"set $background {D['ground']}",
            f"set $line #ffffff{round(dark['line'][3] * 255):02x}",
        ),
        "dot_config/hypr/hyprlock.conf.tmpl": (f"inner_color = rgba({rgb(D['raised'])}, 1)",),
        # vicinae draws alpha as solid, so its file holds line and sel
        # pre-flattened over the ground.
        "dot_local/private_share/vicinae/exact_themes/graphite.toml": (
            f'background = "{D["ground"]}"',
            f'accent = "{D["text"]}"',
            f'border = "{hexrgb(over(dark["line"], dark["ground"]))}"',
            f'background = "{hexrgb(over(dark["sel"], dark["ground"]))}"',
        ),
        "dot_config/zen/userChrome.css": (
            f"--zen-main-browser-background: light-dark({L['ground']}, {D['ground']})",
            f"--zen-dialog-background: light-dark({L['raised']}, {D['raised']})",
            f"--zen-primary-color: light-dark({L['text']}, {D['text']})",
            f"--zen-branding-dark: {D['ground']}",
            f"--zen-branding-paper: {L['ground']}",
            f"--zen-colors-tertiary: light-dark({L['ground']}, {D['ground']})",
            f"--arrowpanel-background: light-dark({L['raised']}, {D['raised']})",
            f"--zen-urlbar-background: light-dark({L['raised']}, {D['raised']})",
        ),
        "dot_config/private_vesktop/exact_themes/graphite.theme.css.tmpl": (
            f"--background-base-lowest: {D['ground']};",
            f"--background-base-lower: {D['panel']};",
            f"--modal-background: {D['raised']};",
            f"--text-default: {D['text']};",
            f"--text-muted: {D['dim']};",
        ),
        # The twin check below holds gtk-4.0/gtk.css to these GTK3 files define
        # by define. Light mode is flat, so it has no glow.
        "dot_local/private_share/exact_themes/exact_graphite-dark/gtk-3.0/gtk.css": (
            f"@define-color window_bg_color {D['ground']};",
            f"@define-color view_bg_color {D['panel']};",
            f"@define-color accent_bg_color {D['text']};",
            f"@define-color graphite_glow {rgba(dark['glow'])};",
            f"@define-color graphite_lift {rgba(dark['lift'])};",
            f"@define-color graphite_glow_panel_far {rgba(dark['glowPanelFar'])};",
            'url("grain-ground.png")',
            'url("grain-panel.png")',
        ),
        "dot_local/private_share/exact_themes/exact_graphite-light/gtk-3.0/gtk.css": (
            f"@define-color window_bg_color {L['ground']};",
            f"@define-color view_bg_color {L['panel']};",
            f"@define-color accent_bg_color {L['text']};",
            f"@define-color graphite_lift {rgba(light['lift'])};",
        ),
        "dot_config/exact_gtk-4.0/gtk.css": (
            f"@define-color window_bg_color {D['ground']};",
            f"@define-color window_bg_color {L['ground']};",
            f"@define-color accent_bg_color {D['text']};",
            f"@define-color accent_bg_color {L['text']};",
            'url("grain-ground.png")',
            'url("grain-panel.png")',
        ),
    }

    def flat(text):
        return re.sub(r"[ \t]+", " ", text)

    for rel, needles in SHARED.items():
        body = flat((SRC / rel).read_text())
        for needle in needles:
            if flat(needle) not in body:
                fails.append(f"{rel} has drifted: expected {needle!r}")

    # The focused-window border has no Theme.qml token: hyprland and sway each
    # spell its alpha, and only need to agree with each other.
    hypr = re.search(r'local focus = "rgba\(ffffff(\w\w)\)"', (SRC / "dot_config/hypr/exact_lua_modules/settings.lua").read_text())
    sway = re.search(r"set \$focus\s+#ffffff(\w\w)", (SRC / "dot_config/sway/conf.d/colors.conf").read_text())
    if not (hypr and sway and hypr[1] == sway[1]):
        fails.append(f"focus border alpha differs: hypr {hypr and hypr[1]}, sway {sway and sway[1]}")

    # The GTK palette is written out three times (GTK3 has no media queries,
    # and its theme folders can't import from ~). This holds each GTK3 file's
    # defines equal to its mode's block in gtk-4.0/gtk.css.
    def defines(text):
        # theme_* are GTK3-only aliases, so libadwaita has none.
        return [l.strip() for l in text.splitlines()
                if l.strip().startswith("@define-color") and not l.strip().startswith("@define-color theme_")]

    g4 = (SRC / "dot_config/exact_gtk-4.0/gtk.css").read_text()
    g4_dark, _, g4_light = g4.partition("@media (prefers-color-scheme: light)")
    for mode, block in (("dark", g4_dark), ("light", g4_light)):
        rel = f"dot_local/private_share/exact_themes/exact_graphite-{mode}/gtk-3.0/gtk.css"
        if defines((SRC / rel).read_text()) != defines(block):
            fails.append(f"{rel} and gtk-4.0/gtk.css ({mode}) define different colours")

# Built into a scratch folder, so an unmapped upstream colour shows up here
# before an apply does.
with tempfile.TemporaryDirectory() as tmp:
    kv = subprocess.run([sys.executable, "-I", str(SRC / "dot_config/quickshell/executable_kvantum.py"), tmp],
                        capture_output=True, text=True)
    if kv.returncode:
        fails.append(f"kvantum.py failed:\n{kv.stderr.strip()}")

if fails:
    print("\n".join(fails), file=sys.stderr)
    sys.exit(1)
print("palette OK")
