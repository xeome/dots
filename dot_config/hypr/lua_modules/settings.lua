-- =============================================================================
-- SHARED SETTINGS
-- =============================================================================
-- Device-agnostic appearance, animation, and general settings
-- Monitor configurations are in the main hyprland.lua.tmpl
-- =============================================================================

local colors = require("lua_modules.colors")

hl.config({
  group = {
    groupbar = {
      enabled = true,
      font_family = "Source Code Pro Semi-Bold",
      font_size = 8,
    },
  },
})

hl.config({
  decoration = {
    rounding = 0,
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
      enabled = false,
    },
  },
})

hl.config({
  general = {
    allow_tearing = true,
    layout = "scrolling",
    border_size = 2,
    col = {
      active_border = { colors = { colors.secondary, colors.primary } },
      inactive_border = colors.surface,
    },
    gaps_in = 5,
    gaps_out = 5,
  },
})

hl.curve("fast", { type = "bezier", points = { {0.48, 0}, {0.15, 1} } })
hl.animation({ leaf = "global", enabled = true, speed = 3, bezier = "fast" })

hl.config({
  misc = {
    vrr = 2,
  },
  debug = {
    vfr = true,
  },
})
