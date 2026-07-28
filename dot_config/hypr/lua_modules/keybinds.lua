-- =============================================================================
-- SHARED KEYBINDINGS
-- =============================================================================
-- Device-agnostic keybindings. GPU-specific app launches are in the main config
-- =============================================================================

local mod = "SUPER"
local alt = "ALT"

hl.config({
  binds = {
    workspace_back_and_forth = true,
  },
})

-- ~~~ general
hl.bind(mod .. " + SHIFT + r", hl.dsp.exec_cmd("hyprctl reload"))
-- Dropped: SUPER+SHIFT+q and SUPER+m ran `ags -t powermenu` / `-t quicksettings`.
-- ags isn't installed, so both have been dead binds; quickshell has no
-- equivalent yet.

-- ~~~ user applications (device-agnostic)
hl.bind(mod .. " + return", hl.dsp.exec_cmd(terminal or "alacritty"))
hl.bind(mod .. " + q", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mod .. " + e", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + r", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(mod .. " + v", hl.dsp.exec_cmd("code --ozone-platform=wayland"))
hl.bind(mod .. " + j", hl.dsp.exec_cmd("quickshell:toggle-llm-overlay"))

-- ~~~ audio
hl.bind(alt .. " + up", hl.dsp.exec_cmd("pamixer -i 5"))
hl.bind(alt .. " + down", hl.dsp.exec_cmd("pamixer -d 5"))
hl.bind(mod .. " + a", hl.dsp.exec_cmd("bash ~/.local/bin/status"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

-- ~~~ media keys
-- These only change the value; the quickshell OSD watches Pipewire and the
-- backlight sysfs node directly, so nothing has to tell it something happened.
-- Caps Lock is deliberately unbound for the same reason: its OSD keys off the
-- keyboard LED, and binding the key here would take over the actual toggle.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pamixer --default-source -t"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))

-- ~~~ misc utilities
hl.bind(mod .. " + o", hl.dsp.exec_cmd("xset dpms force off"))
hl.bind(mod .. " + l", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + b", hl.dsp.exec_cmd("sh ~/.config/emoji/emoji.sh &"))
hl.bind(mod .. " + k", hl.dsp.exec_cmd("qs -c xeome ipc call notifs toggle"))
hl.bind(mod .. " + p", hl.dsp.exec_cmd("ghostty --class='com.sessionizer.fzf' -e ~/.local/bin/sessionizer"))

-- ~~~ window management
hl.bind(mod .. " + escape", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mod .. " + SHIFT + c", hl.dsp.window.close())
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "d" }))
hl.bind(mod .. " + f", hl.dsp.window.fullscreen())
hl.bind(mod .. " + CTRL + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ~~~ workspace switching
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
