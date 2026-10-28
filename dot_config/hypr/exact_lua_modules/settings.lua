-- Appearance, animation and general settings shared by every Hyprland
-- machine. Monitors are in hyprland.lua.tmpl.

-- Graphite edges: a translucent white border, brighter on the focused window,
-- with a sharp 1px dark shadow outside it. Focus is told by lightness alone.
local focus = "rgba(ffffff80)"
local line = "rgba(ffffff14)"
local ring = "rgba(0000004d)"

hl.config({
  group = {
    groupbar = {
      enabled = true,
      font_family = "Inter",
      font_size = 8,
    },
  },
  decoration = {
    rounding = 10,
    rounding_power = 2.0,
    blur = {
      enabled = true,
      size = 10,
      noise = 0.02,
      passes = 2,
      contrast = 1.1,
      vibrancy = 0.1696,
      xray = true,
    },
    shadow = {
      enabled = true,
      sharp = true,
      range = 1,
      render_power = 1,
      color = ring,
      color_inactive = ring,
    },
  },
  general = {
    allow_tearing = true,
    border_size = 1,
    col = {
      active_border = focus,
      inactive_border = line,
    },
    gaps_in = 5,
    gaps_out = 5,
  },
  misc = {
    vrr = 2,
    enable_anr_dialog = false,
  },
  debug = {
    vfr = true,
  },
})

hl.curve("fast", { type = "bezier", points = { {0.48, 0}, {0.15, 1} } })
hl.animation({ leaf = "global", enabled = true, speed = 3, bezier = "fast" })
