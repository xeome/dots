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
    -- 12 px between windows (gaps_in on each side) and to the screen edge:
    -- the shell's Theme.pad, so window edges line up with the bar's modules
    -- and the notification column.
    gaps_in = 6,
    gaps_out = 12,
  },
  misc = {
    vrr = 2,
    enable_anr_dialog = false,
  },
  debug = {
    vfr = true,
  },
})

-- OutCubic over 200 ms (speed is in tenths of a second): the shell's
-- Theme.anim and Theme.ease, so a window and a menu move alike.
hl.curve("ease", { type = "bezier", points = { {0.33, 1}, {0.68, 1} } })
hl.animation({ leaf = "global", enabled = true, speed = 2, bezier = "ease" })
