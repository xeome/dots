hl.on("hyprland.start", function()
  -- Hand the session env to user services and portals.
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE SDL_VIDEODRIVER QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE QT_AUTO_SCREEN_SCALE_FACTOR QT_WAYLAND_DISABLE_WINDOWDECORATION SSH_AUTH_SOCK GNOME_KEYRING_CONTROL HYPRCURSOR_THEME HYPRCURSOR_SIZE XCURSOR_THEME XCURSOR_SIZE OBSIDIAN_USE_WAYLAND")

  hl.exec_cmd([[/usr/bin/swayidle timeout 840 "pidof hyprlock || hyprlock" timeout 900 "hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'" resume "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'"]])

  hl.exec_cmd("/usr/lib/mate-polkit/polkit-mate-authentication-agent-1")
  hl.exec_cmd("/usr/bin/kdeconnectd")
  hl.exec_cmd("hyprpm reload -n")
  hl.exec_cmd("systemctl --user start vicinae.service")

  -- Bar, notifications and OSD, all one process.
  hl.exec_cmd("qs -c xeome")
  hl.exec_cmd("waypaper --restore")

  hl.exec_cmd("systemctl start --user app-com.mitchellh.ghostty.service")
  hl.exec_cmd(app("thunar --daemon"))
  hl.exec_cmd("nm-applet")
  hl.exec_cmd(app("bitwarden-desktop"))
  hl.exec_cmd("[workspace 2 silent] " .. app("zen-browser"))
end)
