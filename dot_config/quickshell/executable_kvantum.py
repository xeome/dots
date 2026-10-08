#!/usr/bin/env python3
"""Builds graphite's Kvantum theme, the Qt side of the GTK themes, from
KvLibadwaita: libadwaita's shapes, so Qt and GTK apps match, recoloured to
Theme.qml and given graphite's two-line edges, corner glow and grain.

Generated, not committed: chezmoi runs this on apply whenever Theme.qml, this
file or the grain tile changes (run_onchange_after_build-kvantum.sh.tmpl), so
the Qt palette cannot drift from the shell's. check-palette.py runs it too.

    kvantum.py [OUTDIR]     default ~/.config/Kvantum/graphite

KvLibadwaita is GPL-3.0 (github.com/GabePoel/KvLibadwaita); the theme this
writes is a derivative of it under the same licence. It is not maintained
upstream, so the pin below is the version every colour in TABLE was read from.
"""
import base64
import pathlib
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

REPO = "https://github.com/GabePoel/KvLibadwaita.git"
PIN = "1f4e0bec44b13dabfa1fe4047aa8eeaccf2f3557"
CACHE = pathlib.Path.home() / ".cache/kvlibadwaita-src"
HERE = pathlib.Path(__file__).resolve().parent
THEME = HERE / "xeome/Theme.qml"
GRAIN = HERE / "xeome/grain-ground.png"

SVG_NS = "http://www.w3.org/2000/svg"
XLINK = "{http://www.w3.org/1999/xlink}href"
# Registered so ElementTree writes them back under their own prefixes: QtSvg
# looks xlink:href up by that literal name, and an unregistered namespace is
# written as ns0:, ns1:..., which breaks every <use> and inherited gradient
# while the file still loads.
for prefix, uri in {
    "": SVG_NS,
    "xlink": "http://www.w3.org/1999/xlink",
    "sodipodi": "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd",
    "inkscape": "http://www.inkscape.org/namespaces/inkscape",
}.items():
    ET.register_namespace(prefix, uri)

PAINT = ("fill", "stroke", "stop-color", "opacity", "fill-opacity", "stroke-opacity",
         "stop-opacity", "color", "display", "visibility")
NAMED = {"white": "#ffffff", "black": "#000000"}


def fetch():
    """The pinned upstream checkout, fetched once into ~/.cache."""
    git = ["git", "-C", str(CACHE)]
    if not (CACHE / ".git").is_dir():
        CACHE.mkdir(parents=True, exist_ok=True)
        subprocess.run(git + ["init", "--quiet"], check=True)
    head = subprocess.run(git + ["rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    if head != PIN:
        subprocess.run(git + ["fetch", "--quiet", "--depth", "1", REPO, PIN], check=True)
        subprocess.run(git + ["checkout", "--quiet", "--detach", "FETCH_HEAD"], check=True)
    return CACHE / "src/KvLibadwaita"


def tokens(mode):
    """{name: (#rrggbb, alpha)} from Theme.qml, which writes #AARRGGBB."""
    out = {}
    for m in re.finditer(r'property color (\w+): light \? "#(\w{8})" : "#(\w{8})"', THEME.read_text()):
        h = (m[2] if mode == "light" else m[3]).lower()
        out[m[1]] = ("#" + h[2:], round(int(h[:2], 16) / 255, 3))
    return out


def style_of(e):
    s = {}
    for decl in (e.get("style") or "").split(";"):
        k, _, v = decl.partition(":")
        if k.strip():
            s[k.strip()] = v.strip()
    return s


def set_style(e, s):
    if s:
        e.set("style", ";".join(f"{k}:{v}" for k, v in s.items()))
    elif "style" in e.attrib:
        del e.attrib["style"]


def colour(v):
    """#rrggbb for a paint value, or None for none/url()/inherit."""
    v = NAMED.get(v.lower(), v.lower())
    if re.fullmatch(r"#[0-9a-f]{3}", v):
        return "#" + "".join(c * 2 for c in v[1:])
    if re.fullmatch(r"#[0-9a-f]{6}", v):
        return v
    if v in ("none", "inherit", "") or v.startswith("url("):
        return None
    raise SystemExit(f"kvantum.py: unhandled paint value {v!r}")


def normalise(root):
    """One place for every paint property, as QtSvg and the spec agree.

    KvLibadwaita sets some properties both as an attribute and in `style`, with
    different values. Qt6 paints the style (the spec), Qt5 the attribute, so the
    same theme drew 103 elements differently in Qt5 and Qt6 apps. Attributes
    move into style unless style already sets them; class-based colours go,
    since every element using one also sets its fill in style.
    """
    parent = {c: p for p in root.iter() for c in p}
    for e in list(root.iter()):
        tag = e.tag.split("}")[-1]
        if tag in ("style", "namedview"):
            parent[e].remove(e)
            continue
        s = style_of(e)
        for k in PAINT:
            if k in e.attrib:
                s.setdefault(k, e.attrib.pop(k))
        e.attrib.pop("class", None)
        set_style(e, s)


SHAPES = ("rect", "path", "circle", "ellipse", "polygon", "polyline", "line")


def paints(root):
    """Every visible paint, resolved onto the element that draws it.

    Yields (element, kind, #rrggbb, alpha, family, shape, shape property):
    kind is fill, stroke or stop, and for a stop the shape is the one its
    gradient paints. Inherited fills and
    every ancestor's opacity are folded in, so a paint's alpha is what the
    pixel gets. Gradients yield their stops, scaled by the shape that uses
    them. Paints under alpha < 0.01 are KvLibadwaita's invisible sizing rects
    and are left alone.
    """
    parent = {c: p for p in root.iter() for c in p}
    byid = {e.get("id"): e for e in root.iter() if e.get("id")}
    users = {}
    for e in root.iter():
        if e.tag.endswith("}use") and e.get(XLINK):
            users.setdefault(e.get(XLINK)[1:], []).append(e)

    def family(e, seen=()):
        n = e
        while n is not None:
            i = n.get("id") or ""
            if re.match(r"[A-Za-z]+-", i):
                return i.split("-")[0]
            if i in users and n not in seen:
                return family(users[i][0], seen + (n,))
            n = parent.get(n)
        return None

    def inherited(e, k, default):
        n = e
        while n is not None:
            v = style_of(n).get(k)
            if v not in (None, "inherit"):
                return v
            n = parent.get(n)
        return default

    def chain(e):
        a, n = 1.0, e
        while n is not None:
            a *= float(style_of(n).get("opacity", 1))
            n = parent.get(n)
        return a

    def stops(grad):
        while grad is not None and not any(c.tag.endswith("}stop") for c in grad):
            ref = grad.get(XLINK)
            grad = byid.get(ref[1:]) if ref else None
        return [c for c in grad if c.tag.endswith("}stop")] if grad is not None else []

    for e in root.iter():
        if e.tag.split("}")[-1] not in SHAPES:
            continue
        fam = family(e)
        if fam is None:  # neither named nor reached through <use>: never drawn
            continue
        for k in ("fill", "stroke"):
            v = inherited(e, k, "#000000" if k == "fill" else "none")
            a = chain(e) * float(inherited(e, k + "-opacity", 1))
            if a < 0.01:
                continue
            m = re.fullmatch(r"url\(#([^)]+)\)", v)
            if m:
                for st in stops(byid.get(m[1])):
                    ss = style_of(st)
                    c = colour(ss.get("stop-color", "#000000"))
                    yield (st, "stop", c, round(a * float(ss.get("stop-opacity", 1)), 3), fam, e, k)
            elif colour(v):
                yield (e, k, colour(v), round(a, 3), fam, e, k)


def own_gradients(root):
    """Give every gradient its own stops and drop its xlink:href.

    Inkscape writes a gradient as a stopless one that links to a shared list of
    stops. A stop's alpha has to carry the opacity of the shape it paints, so
    each gradient gets its own copy. The link goes too: QtSvg takes a linked
    gradient's stops even when the gradient has its own, against the spec, so
    the coordinates it would have inherited are copied in instead.
    """
    byid = {e.get("id"): e for e in root.iter() if e.get("id")}
    inherit = ("x1", "y1", "x2", "y2", "cx", "cy", "r", "fx", "fy",
               "gradientUnits", "gradientTransform", "spreadMethod")
    for g in list(byid.values()):
        if not g.tag.endswith("Gradient") or not g.get(XLINK):
            continue
        src, has_stops = g, any(c.tag.endswith("}stop") for c in g)
        while src.get(XLINK):
            src = byid[src.get(XLINK)[1:]]
            for k in inherit:
                if k not in g.attrib and k in src.attrib:
                    g.set(k, src.get(k))
            if not has_stops and any(c.tag.endswith("}stop") for c in src):
                for i, st in enumerate(c for c in src if c.tag.endswith("}stop")):
                    copy = ET.fromstring(ET.tostring(st))
                    copy.set("id", f"{g.get('id')}_s{i}")
                    g.append(copy)
                has_stops = True
        del g.attrib[XLINK]


def flatten(root, recolour):
    """Rewrite every paint with recolour(colour, alpha, family) -> (colour, alpha).

    Each shape gets its own explicit fill and stroke, and no element keeps an
    opacity, so what is written is exactly what is drawn. Gradient stops take
    the alpha of the shape using them, which is safe because no KvLibadwaita
    gradient is shared between shapes (checked below).
    """
    own_gradients(root)
    found = list(paints(root))
    stop_users = {}
    for st, k, c, a, fam, shape, sk in found:
        if k == "stop":
            stop_users.setdefault(st, set()).add(shape)
    shared = [st.get("id") for st, u in stop_users.items() if len(u) > 1]
    if shared:
        raise SystemExit(f"kvantum.py: gradient stops shared between shapes: {shared}")
    writes = {}
    for st, k, c, a, fam, shape, sk in found:
        nc, na = recolour(c, a, fam)
        if k == "stop":
            writes.setdefault(st, {}).update({"stop-color": nc, "stop-opacity": f"{na:g}"})
            writes.setdefault(shape, {}).update({sk + "-opacity": "1"})
        else:
            writes.setdefault(shape, {}).update({k: nc, k + "-opacity": f"{na:g}"})
    drawn = {f[5] for f in found}
    for e in root.iter():
        s = style_of(e)
        if e in drawn:
            for k in ("fill", "stroke"):  # resolve inheritance onto the shape
                s.setdefault(k, s.get(k) or "none")
        # Opacity is folded into the paints; a near-zero one marks one of
        # KvLibadwaita's invisible sizing rects, which paints() left alone.
        if (e in drawn or e.tag.split("}")[-1] == "g") and float(s.get("opacity", 1)) >= 0.01:
            s.pop("opacity", None)
        s.update(writes.get(e, {}))
        set_style(e, s)


# Upstream elements the generated ones replace. KvLibadwaita draws controls
# as solid fills with no edge; graphite's are nearly clear with a two-line
# edge, so their frames and interiors are drawn here instead (EDGES).
REPLACED = re.compile(
    r"(button|tbutton|lineedit|combo|tab|tooltip|common|menu)"
    r"-(normal|focused|pressed|toggled|disabled)(-inactive)?"
    r"(-(top|bottom|left|right|topleft|topright|bottomleft|bottomright))?"
    r"|(menu|tooltip)-shadow(-hint)?-\w+"
    r"|expand-(button|tbutton|lineedit|combo|tab|tooltip|common|menu)-\w+"
    r"|window-normal(-inactive)?")

# family: (corner radius in px, {state: (fill token, edge token)}). None means
# nothing is drawn. Kvantum falls back to -normal for any state not listed.
# "focused" is Kvantum's word for hover, except on line edits, where it is
# keyboard focus, which graphite marks in warm.
EDGES = {
    "button": (6, {"normal": ("card", "line"), "focused": ("hover", "line"),
                   "pressed": ("sel", "line"), "toggled": ("sel", "line")}),
    "tbutton": (6, {"normal": (None, None), "focused": ("hover", "line"),
                    "pressed": ("sel", "line"), "toggled": ("sel", "line")}),
    "lineedit": (6, {"normal": ("card", "line"), "focused": ("card", "warm")}),
    "combo": (6, {"normal": ("card", "line"), "focused": ("hover", "line"),
                  "pressed": ("sel", "line"), "toggled": ("sel", "line")}),
    "tab": (6, {"normal": (None, None), "focused": ("hover", None), "toggled": ("sel", "line")}),
    "menu": (10, {"normal": ("raised", "line")}),
    "tooltip": (6, {"normal": ("raised", "line")}),
    # QFrame panels and scroll areas: flat chrome, so square, and no fill.
    "common": (0, {"normal": (None, "line")}),
}

# kvconfig keys the generated elements need. Frame widths equal the corner
# radius, since a two-line edge cannot fit in KvLibadwaita's 1px slices, and
# expansion is off so corners keep their radius instead of stretching.
def frame(el, w):
    return {"frame.element": el, "interior.element": el, "frame.top": w, "frame.bottom": w,
            "frame.left": w, "frame.right": w, "frame.expansion": 0}


SECTIONS = {
    # Kvantum's own section is "%General". No shadow: the ring is the edge, and
    # a depth with no shadow artwork pads every menu by it, which Qt 6.11 on
    # Wayland no longer lets Kvantum move back over its menu bar item.
    "%General": {"menu_shadow_depth": 0, "tooltip_shadow_depth": 0},
    "PanelButtonCommand": frame("edge-button", 6),
    "ToolbarButton": frame("edge-tbutton", 6),
    "LineEdit": frame("edge-lineedit", 6),
    "ToolbarLineEdit": frame("edge-lineedit", 6),
    "ComboBox": frame("edge-combo", 6),
    "Tab": frame("edge-tab", 6),
    "Menu": frame("edge-menu", 10),
    "ToolTip": frame("edge-tooltip", 6),
    "GenericFrame": {"frame.element": "edge-common", "interior.element": "edge-common", "frame.top": 2, "frame.bottom": 2,
                     "frame.left": 2, "frame.right": 2},
}
# The fixed-size glow: Kvantum draws the window interior at least this big
# and cuts it at the window's right and bottom (Theme-Config, min_width under
# Window), so a glow at its top-left keeps its size. 4096 exceeds every
# monitor in .chezmoidata.toml; a bigger window would stretch it.
GLOW_CANVAS = 4096
GLOW_RADIUS = 360  # Surface.qml's glowSize 480 * 0.75
GRAIN_TILE = 160


def svg(tag, **attrs):
    return ET.Element(f"{{{SVG_NS}}}{tag}", {k.replace("_", "-"): str(v) for k, v in attrs.items()})


def paint(tok, t):
    """style for a token, or an invisible paint that still sets the bounds."""
    if tok is None:
        c, a = t["ring"][0], 0
    else:
        c, a = t[tok]
    return f"fill:{c};fill-opacity:{a:g};stroke:none"


def slices(fam, state, radius, fill, edge, t):
    """The interior and eight frame slices of one state, as SVG groups.

    Each slice is drawn in its own box, one unit per pixel: the ring is the
    outer pixel, the line the next, the fill the rest. Kvantum draws the
    interior inside the frame widths, so the slices carry the fill too.
    """
    w = max(radius, 2)
    ring = "ring" if edge else None
    out = []

    def group(name, *shapes):
        g = svg("g", id=name)
        g.extend(shapes)
        out.append(g)

    def path(d, tok):
        return svg("path", d=d, style=paint(tok, t))

    base = f"edge-{fam}-{state}"
    group(base, svg("rect", x=0, y=0, width=w, height=w, style=paint(fill, t)))
    # top, then the others by mirroring and transposing its coordinates
    bands = [(0, 1, ring), (1, 2, edge), (2, w, fill)]
    for side in ("top", "bottom", "left", "right"):
        shapes = []
        for a, b, tok in bands:
            if b <= a:
                continue
            lo, hi = (a, b) if side in ("top", "left") else (w - b, w - a)
            if side in ("top", "bottom"):
                shapes.append(svg("rect", x=0, y=lo, width=1, height=hi - lo, style=paint(tok, t)))
            else:
                shapes.append(svg("rect", x=lo, y=0, width=hi - lo, height=1, style=paint(tok, t)))
        group(f"{base}-{side}", svg("rect", x=0, y=0, width=1 if side in ("top", "bottom") else w,
                                    height=w if side in ("top", "bottom") else 1, style=paint(None, t)), *shapes)
    for side in ("topleft", "topright", "bottomleft", "bottomright"):
        fx = (lambda x: w - x) if "right" in side else (lambda x: x)
        fy = (lambda y: w - y) if side.startswith("bottom") else (lambda y: y)
        sweep = 1 if (("right" in side) == side.startswith("bottom")) else 0

        def pt(x, y):
            return f"{fx(x):g},{fy(y):g}"

        shapes = [svg("rect", x=0, y=0, width=w, height=w, style=paint(None, t))]
        if radius >= 2:  # quarter annuli around the corner's centre (w, w)
            for outer, inner, tok in ((w, w - 1, ring), (w - 1, w - 2, edge)):
                d = (f"M {pt(w - outer, w)} A {outer},{outer} 0 0 {sweep} {pt(w, w - outer)} "
                     f"L {pt(w, w - inner)} A {inner},{inner} 0 0 {1 - sweep} {pt(w - inner, w)} Z")
                shapes.append(path(d, tok))
            d = f"M {pt(2, w)} A {w - 2},{w - 2} 0 0 {sweep} {pt(w, 2)} L {pt(w, w)} Z"
            shapes.append(path(d, fill))
        else:  # square: an L of ring, an L of line inside it
            shapes.append(path(f"M {pt(0, 0)} L {pt(w, 0)} L {pt(w, 1)} L {pt(1, 1)} L {pt(1, w)} L {pt(0, w)} Z", ring))
            shapes.append(path(f"M {pt(1, 1)} L {pt(w, 1)} L {pt(w, 2)} L {pt(2, 2)} L {pt(2, w)} L {pt(1, w)} Z", edge))
        group(f"{base}-{side}", *shapes)
    return out


def window(mode, t):
    """window-normal: the ground, and in dark mode graphite's corner glow,
    plus the grain tile Kvantum repeats over it (window-normal-pattern)."""
    out = [svg("g", id="window-normal")]
    out[0].append(svg("rect", x=0, y=0, width=GLOW_CANVAS, height=GLOW_CANVAS,
                      style=f"fill:{t['ground'][0]};fill-opacity:1;stroke:none"))
    if mode == "dark":
        c, a = t["glow"]
        grad = svg("radialGradient", id="graphite-glow", cx=0, cy=0, r=GLOW_RADIUS,
                   gradientUnits="userSpaceOnUse")
        grad.append(svg("stop", offset=0, style=f"stop-color:{c};stop-opacity:{a:g}"))
        grad.append(svg("stop", offset=1, style=f"stop-color:{c};stop-opacity:0"))
        out.append(grad)
        out[0].append(svg("rect", x=0, y=0, width=GLOW_CANVAS, height=GLOW_CANVAS,
                          style="fill:url(#graphite-glow);fill-opacity:1;stroke:none"))
        tile = svg("g", id="window-normal-pattern")
        img = svg("image", x=0, y=0, width=GRAIN_TILE, height=GRAIN_TILE)
        img.set(XLINK, "data:image/png;base64," + base64.b64encode(GRAIN.read_bytes()).decode())
        tile.append(img)
        out.append(tile)
    return out


def kvcolour(c, a):
    """Kvantum's colour syntax: #RRGGBB, or #RRGGBBAA with alpha last."""
    return c if a >= 1 else f"{c}{round(a * 255):02x}"


def patch_kvconfig(text, mode, t, recolour):
    """Recolour every colour key and apply SECTIONS (and the window keys)."""
    sections = {k: dict(v) for k, v in SECTIONS.items()}
    if mode == "dark":
        sections.setdefault("Window", {}).update({
            "min_width": GLOW_CANVAS, "min_height": GLOW_CANVAS,
            "interior.x.patternsize": GRAIN_TILE, "interior.y.patternsize": GRAIN_TILE})
    out, section, pending = [], None, {}

    def flush():
        for k, v in pending.items():
            out.append(f"{k}={v}")

    for line in text.splitlines():
        m = re.fullmatch(r"\[(.+)\]", line.strip())
        if m:
            flush()
            section = m[1]
            pending = dict(sections.pop(section, {}))
            out.append(line)
            continue
        k, eq, v = line.partition("=")
        k = k.strip()
        if eq and k in pending:
            out.append(f"{k}={pending.pop(k)}")
        elif eq and k.endswith("color") and v.strip():
            nc, na = recolour(section, k, v.strip())
            out.append(f"{k}={kvcolour(nc, na)}")
        else:
            out.append(line)
    flush()
    # A section upstream lacks would be written where Kvantum never reads it.
    if sections:
        raise SystemExit(f"kvantum.py: upstream kvconfig has no section {sorted(sections)}")
    return "\n".join(out) + "\n"


def kv_value(v):
    """(#rrggbb, alpha) for a kvconfig colour; Kvantum's 9-char hex is RRGGBBAA."""
    v = NAMED.get(v.lower(), v.lower())
    if re.fullmatch(r"#[0-9a-f]{8}", v):
        return v[:7], round(int(v[7:], 16) / 255, 2)
    return colour(v), 1.0


def build(src, out, mode, name, upstream):
    t = tokens(mode)
    misses = []

    def lookup(key, fam=None):
        spec = OVERRIDES[mode].get((fam,) + key) or TABLE[mode].get(key)
        if spec is None:
            misses.append((key, fam))
            return key
        tok, alpha = (spec, None) if isinstance(spec, str) else spec
        c, a = t[tok]
        return c, key[1] if alpha == "keep" else a if alpha is None else alpha

    tree = ET.parse(src / f"{upstream}.svg")
    root = tree.getroot()
    for p in list(root.iter()):
        for c in list(p):
            if REPLACED.fullmatch(c.get("id") or ""):
                p.remove(c)
    normalise(root)
    flatten(root, lambda c, a, fam: lookup((c, round(a, 2)), fam))
    layer = svg("g", id="graphite")
    for fam, (radius, states) in EDGES.items():
        for state, (fill, edge) in states.items():
            layer.extend(slices(fam, state, radius, fill, edge, t))
    layer.extend(window(mode, t))
    root.append(layer)

    kv = (src / f"{upstream}.kvconfig").read_text()

    def kv_recolour(section, key, value):
        if section == "GeneralColors":
            spec = GENERAL[mode].get(key)
            if spec is None:
                misses.append(((key,), section))
                return kv_value(value)
            return t[spec]
        return lookup(kv_value(value), "kvconfig")

    kv = patch_kvconfig(kv, mode, t, kv_recolour)
    if misses:
        return [f"{mode}: no TABLE entry for {k} ({fam})" for k, fam in dict.fromkeys(misses)]
    out.mkdir(parents=True, exist_ok=True)
    tree.write(out / f"{name}.svg", xml_declaration=True, encoding="utf-8")
    (out / f"{name}.kvconfig").write_text(kv)
    return []


def main(out):
    src = fetch()
    fails = []
    for mode, name, upstream in (("light", "graphite", "KvLibadwaita"), ("dark", "graphiteDark", "KvLibadwaitaDark")):
        fails += build(src, out, mode, name, upstream)
    if fails:
        raise SystemExit("kvantum.py: an upstream colour has no graphite token; add it to TABLE:\n"
                         + "\n".join(fails))


# Every colour KvLibadwaita paints, by (colour, alpha) as drawn, mapped to a
# Theme.qml token. A value is a token (drawn at the token's alpha), (token,
# "keep") to keep upstream's alpha (shadow fades, disabled glyphs), or (token,
# alpha). An upstream colour missing here stops the build: an unmapped
# Adwaita grey or blue never reaches an app. The roles follow the GTK side:
# Adwaita's blue is the accent, which graphite spends on the text tone; hover
# and selection are `hover` and `sel`; glyphs are `dim`, `text` under the
# pointer; scrollbars are libadwaita's own 20% and 40% of the text tone.
TABLE = {
    "dark": {
        ("#000000", 0.0): ("ring", "keep"), ("#000000", 0.5): ("ring", "keep"),   # shadow fades
        ("#090000", 0.5): ("ring", "keep"), ("#000006", 0.05): ("ring", "keep"),
        ("#000006", 1.0): ("ring", "keep"),                                        # masks
        ("#000000", 0.25): "rule",                                                 # slider groove
        ("#1d1d20", 1.0): "ground", ("#222226", 1.0): "ground", ("#2c2c2c", 1.0): "ground",
        ("#2e2e32", 1.0): "ground", ("#212121", 1.0): "panel",
        ("#3584e4", 1.0): "text", ("#3584e4", 0.35): ("dim", "keep"),             # accent
        ("#4990e7", 1.0): "bright",                                                # accent, hovered
        ("#f2ffff", 1.0): "ground",                                                # check mark on it
        ("#3d3d3d", 1.0): "hover", ("#414141", 1.0): "hover", ("#ffffff", 0.08): "hover",
        ("#ffffff", 0.1): "hover", ("#ffffff", 0.15): "hover",
        ("#444444", 1.0): "sel", ("#4b4b4b", 1.0): "sel", ("#616161", 1.0): "sel",
        ("#4285f4", 1.0): "sel", ("#ffffff", 0.2): "sel",
        ("#404040", 1.0): "line", ("#ffffff", 0.12): "line",
        ("#ffffff", 0.01): "card", ("#ffffff", 0.25): "rule",
        ("#5a5a5a", 1.0): "dim", ("#646464", 1.0): "dim",
        ("#dfdfdf", 0.75): "dim", ("#dfdfdf", 1.0): "dim", ("#ffffff", 0.75): "dim",
        ("#dfdfdf", 0.3): ("dim", "keep"), ("#ffffff", 0.3): ("dim", "keep"), ("#ffffff", 0.35): ("dim", "keep"),
        ("#ffffff", 1.0): "text",
        ("#707070", 1.0): ("text", 0.4),
        ("#f04a50", 1.0): "hot",
    },
    "light": {
        ("#000000", 0.0): ("ring", "keep"), ("#000000", 0.5): ("ring", "keep"),
        ("#090000", 0.5): ("ring", "keep"), ("#000006", 0.05): ("ring", "keep"),
        ("#000006", 0.01): ("ring", "keep"),
        ("#000000", 0.12): "rule", ("#000000", 0.25): "rule", ("#ffffff", 0.25): "rule",
        ("#fafafb", 1.0): "ground", ("#ffffff", 1.0): "ground", ("#212121", 1.0): "panel",
        ("#f9ffff", 1.0): "card",
        ("#3584e4", 1.0): "text", ("#3c84f7", 1.0): "text", ("#3584e4", 0.35): ("dim", "keep"),
        ("#4990e7", 1.0): "bright",
        ("#f2ffff", 1.0): "ground",
        ("#e6e6e6", 1.0): "hover", ("#000006", 0.08): "hover", ("#000006", 0.1): "hover",
        ("#000006", 0.15): "hover",
        ("#ebebed", 1.0): "sel", ("#bfbfbf", 1.0): "sel", ("#4285f4", 1.0): "sel",
        ("#bdbdbd", 1.0): "line", ("#000006", 0.12): "line",
        ("#b0b0b0", 1.0): "dim", ("#5a5a5a", 1.0): "dim", ("#444444", 1.0): "dim",
        ("#000006", 0.35): "dim", ("#000006", 0.75): "dim",
        ("#000006", 0.3): ("dim", "keep"), ("#ebebed", 0.3): ("dim", "keep"),
        ("#000006", 1.0): "text", ("#333333", 1.0): "text",
        ("#a6a6a6", 1.0): ("text", 0.4),
        ("#f04a50", 1.0): "hot",
    },
}

# Where one upstream colour plays two graphite roles, by family (the id's
# first word). "kvconfig" is the text colours in the .kvconfig sections.
OVERRIDES = {
    "dark": {
        # checkbox and radio boxes are nearly clear, like every control
        ("checkbox", "#1d1d20", 1.0): "card", ("radio", "#1d1d20", 1.0): "card", ("menu", "#1d1d20", 1.0): "card",
        ("checkbox", "#4b4b4b", 1.0): "dim", ("radio", "#4b4b4b", 1.0): "dim", ("menu", "#ffffff", 0.15): "dim",
        ("menu", "#ffffff", 0.1): "line",
        ("slidercursor", "#2c2c2c", 1.0): "text",                                # the knob, as in Track.qml
        ("tabframe", "#2e2e32", 1.0): "panel", ("progress", "#2e2e32", 1.0): "rule",
        ("progress", "#616161", 1.0): "rule",                                    # progress trough
        ("scrollbarslider", "#4b4b4b", 1.0): ("text", 0.2),
        ("menuitem", "#ffffff", 0.1): "sel",                                     # the highlighted row
        ("focus", "#ffffff", 0.1): "warm",                                       # graphite's focus colour
        ("tabBarFrame", "#ffffff", 0.1): "line", ("resize", "#ffffff", 0.1): "line",
        ("toolbar", "#ffffff", 0.15): "line", ("header", "#ffffff", 0.15): "sel",
        ("kvconfig", "#ffffff", 1.0): "bright", ("kvconfig", "#dfdfdf", 1.0): "text",
        ("kvconfig", "#dedede", 1.0): "text", ("kvconfig", "#787878", 1.0): "dim",
    },
    "light": {
        ("checkbox", "#ffffff", 1.0): "card", ("radio", "#ffffff", 1.0): "card", ("menu", "#ffffff", 1.0): "card",
        ("menu", "#000006", 0.15): "dim", ("menu", "#000006", 0.1): "line",
        ("itemview", "#ffffff", 1.0): "hover", ("slidercursor", "#ffffff", 1.0): "text",
        ("scrollbarslider", "#ebebed", 1.0): ("text", 0.2),
        ("mask", "#000006", 1.0): ("ring", "keep"),
        ("menuitem", "#000006", 0.1): "sel", ("focus", "#000006", 0.1): "warm",
        ("tabBarFrame", "#000006", 0.1): "line", ("resize", "#000006", 0.1): "line",
        ("toolbar", "#000006", 0.15): "line", ("header", "#000006", 0.15): "sel",
        ("kvconfig", "#444444", 1.0): "text", ("kvconfig", "#424242", 1.0): "text",
        ("kvconfig", "#444444", 0.45): "dim", ("kvconfig", "#efefef", 1.0): "text",
        ("kvconfig", "#ffffff", 1.0): "text",
    },
}

# [GeneralColors], the QPalette Kvantum hands to every app, by role. The
# selection is opaque because apps fill it without blending, as in GTK3.
# Links take the accent, which is the text tone, as GTK draws them.
_GENERAL = {
    "window.color": "ground", "base.color": "panel", "alt.base.color": "raised",
    "button.color": "raised", "light.color": "rule", "mid.light.color": "rule",
    "dark.color": "ground", "mid.color": "rule", "highlight.color": "rule",
    "inactive.highlight.color": "rule", "text.color": "text", "window.text.color": "text",
    "button.text.color": "text", "disabled.text.color": "dim", "tooltip.text.color": "text",
    "highlight.text.color": "bright", "link.color": "text", "link.visited.color": "dim",
    "progress.indicator.text.color": "text",
}
GENERAL = {"dark": _GENERAL, "light": dict(_GENERAL, **{"light.color": "raised", "mid.light.color": "ground", "dark.color": "rule"})}


if __name__ == "__main__":
    main(pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path.home() / ".config/Kvantum/graphite")
