-- =============================================================================
-- SHARED LAYER RULES
-- =============================================================================

hl.layer_rule({
  name = "swaync-control-center-blur",
  match = { namespace = "swaync-control-center" },
  blur = true,
  ignore_alpha = 0.5,
})

hl.layer_rule({
  name = "waybar-blur",
  match = { namespace = "waybar" },
  blur = true,
})

hl.layer_rule({
  name = "swaync-notification-blur",
  match = { namespace = "swaync-notification-window" },
  blur = true,
  ignore_alpha = 0.5,
})

hl.layer_rule({
  name = "swayosd-client-blur",
  match = { namespace = "swayosd-client" },
  blur = true,
  ignore_alpha = 0,
})

hl.layer_rule({
  name = "swayosd-server-blur",
  match = { namespace = "swayosd-server" },
  blur = true,
  ignore_alpha = 0,
})

hl.layer_rule({
  name = "swayosd-blur",
  match = { namespace = "swayosd" },
  blur = true,
  ignore_alpha = 0,
  xray = false,
})

hl.layer_rule({
  name = "vicinae-blur",
  match = { namespace = "vicinae" },
  blur = true,
  ignore_alpha = 0,
})

-- =============================================================================
-- SHARED WINDOW RULES
-- =============================================================================

hl.window_rule({
  name = "swaync-no-focus",
  match = { class = "swaync-notification-window" },
  no_initial_focus = true,
  no_focus = true,
})

hl.window_rule({
  name = "telegram-no-screen-share",
  match = { title = "(Telegram)(.*)" },
  no_screen_share = true,
})

hl.window_rule({
  name = "whatsapp-no-screen-share",
  match = { title = "(WhatsApp)(.*)" },
  no_screen_share = true,
})

hl.window_rule({
  name = "gmail-no-screen-share",
  match = { title = "(.*)(All mail)(.*)" },
  no_screen_share = true,
})

hl.window_rule({
  name = "protonmail-no-screen-share",
  match = { title = "(.*)(Inbox \\| .* \\| Proton Mail)(.*)" },
  no_screen_share = true,
})

hl.window_rule({
  name = "gradia-float",
  match = { class = "^(gradia)$" },
  float = true,
})

hl.window_rule({
  name = "xdg-portal-float",
  match = { class = "^(xdg-desktop-portal-gtk)$" },
  float = true,
  center = true,
})

hl.window_rule({
  name = "pavucontrol-float",
  match = { class = "^(pavucontrol)$" },
  float = true,
})

hl.window_rule({
  name = "settings-float",
  match = { class = "^(nwg-look|wdisplays|qt6ct|qt5ct|kvantummanager)$" },
  float = true,
})

hl.window_rule({
  name = "easyeffects-float",
  match = { class = "^(easyeffects)$" },
  float = true,
})

hl.window_rule({
  name = "archive-float",
  match = { class = "^(org.kde.ark|file-roller)$" },
  float = true,
})

hl.window_rule({
  name = "cs2-immediate",
  match = { class = "^(cs2)$" },
  immediate = true,
})

hl.window_rule({
  name = "sessionizer-float",
  match = { class = "^(com.sessionizer.fzf)$" },
  float = true,
  size = { 800, 500 },
  center = true,
})
