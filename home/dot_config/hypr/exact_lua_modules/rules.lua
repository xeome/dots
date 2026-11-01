-- The xeome shell draws every surface opaque (its hairlines rely on a known
-- surface lightness), so no layer rule turns blur on for it.

-- Shot shows a frozen frame of the screen; fading that in reads as a flicker.
hl.layer_rule({
  name = "quickshell-shot-noanim",
  match = { namespace = "quickshell-shot" },
  no_anim = true,
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
