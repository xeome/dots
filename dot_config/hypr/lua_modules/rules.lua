-- =============================================================================
-- SHARED LAYER RULES
-- =============================================================================

-- The default shell (`qs -c xeome`) draws every surface opaque, so it has no
-- blur rules at all — there is nothing to see through them, and its hairline
-- borders work precisely because the surfaces sit at a known lightness.
--
-- `qs -c zinc` is the old translucent theme, kept alongside it. It is the only
-- reason blur rules still exist here, which is why it carries its own
-- namespaces: shared ones would have meant blurring behind the opaque bar too,
-- every frame, for nothing.

hl.layer_rule({
  name = "quickshell-zinc-bar-blur",
  match = { namespace = "quickshell-zinc-bar" },
  blur = true,
})

hl.layer_rule({
  name = "quickshell-zinc-notifications-blur",
  match = { namespace = "quickshell-zinc-notifications" },
  blur = true,
  -- The gaps between stacked cards are fully transparent; only the cards
  -- themselves (alpha 0.82) should get a blurred backdrop.
  ignore_alpha = 0.5,
})

hl.layer_rule({
  name = "quickshell-zinc-osd-blur",
  match = { namespace = "quickshell-zinc-osd" },
  blur = true,
  ignore_alpha = 0,
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
