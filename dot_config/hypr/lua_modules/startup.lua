-- =============================================================================
-- SHARED STARTUP APPLICATIONS
-- =============================================================================
-- Device-agnostic startup applications and services
-- Device-specific startup items are in the main hyprland.lua.tmpl
-- =============================================================================

hl.on("hyprland.start", function()
  -- Environment update
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE SDL_VIDEODRIVER QT_QPA_PLATFORM QT_AUTO_SCREEN_SCALE_FACTOR QT_WAYLAND_DISABLE_WINDOWDECORATION SSH_AUTH_SOCK GNOME_KEYRING_CONTROL HYPRCURSOR_THEME HYPRCURSOR_SIZE XCURSOR_THEME XCURSOR_SIZE OBSIDIAN_USE_WAYLAND")

  -- Power Management
  hl.exec_cmd("/usr/bin/swayidle -w timeout 840 \"hyprlock\" timeout 900 'swaymsg \"output * dpms off\"' resume 'swaymsg \"output * dpms on\"' &")

  -- System Services
  hl.exec_cmd("/usr/lib/mate-polkit/polkit-mate-authentication-agent-1")
  hl.exec_cmd("/usr/bin/kdeconnectd &")
  hl.exec_cmd("hyprpm reload -n &")
  hl.exec_cmd("systemctl --user start vicinae.service &")
  hl.exec_cmd("autotiling-rs &")

  -- Desktop Environment
  hl.exec_cmd("waybar &")
  hl.exec_cmd("swayosd-server &")
  hl.exec_cmd("waypaper --restore")

  -- Applications
  hl.exec_cmd("systemctl start --user app-com.mitchellh.ghostty.service")
  hl.exec_cmd("thunar --daemon &")
  hl.exec_cmd("nm-applet &")

  -- Launch zen-browser on workspace 2
  hl.exec_cmd("[workspace 2 silent] zen-browser")
end)
