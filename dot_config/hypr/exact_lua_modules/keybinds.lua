-- Keybinds shared by every Hyprland machine. Machine-specific ones are in
-- hyprland.lua.tmpl, which also defines `terminal` and `app`.

local mod = "SUPER"

hl.config({
  binds = {
    workspace_back_and_forth = true,
  },
})

-- ~~~ general
hl.bind(mod .. " + SHIFT + r", hl.dsp.exec_cmd("hyprctl reload"))

-- ~~~ user applications
hl.bind(mod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + q", hl.dsp.exec_cmd(app("zen-browser")))
hl.bind(mod .. " + e", hl.dsp.exec_cmd(app("thunar")))
hl.bind(mod .. " + r", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(mod .. " + v", hl.dsp.exec_cmd(app("code --ozone-platform=wayland")))

-- ~~~ audio
hl.bind(mod .. " + a", hl.dsp.exec_cmd("bash ~/.local/bin/status"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

-- ~~~ media keys
-- The quickshell OSD watches PipeWire and the backlight itself, so these only
-- change the value. Caps Lock stays unbound: its OSD reads the keyboard LED,
-- and a bind here would take over the toggle.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pamixer --default-source -t"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))

-- ~~~ misc utilities
hl.bind(mod .. " + o", hl.dsp.dpms({ action = "toggle" }))
hl.bind(mod .. " + l", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + b", hl.dsp.exec_cmd("sh ~/.config/emoji/emoji.sh"))
hl.bind(mod .. " + k", hl.dsp.exec_cmd("qs -c xeome ipc call notifs toggle"))
hl.bind(mod .. " + SHIFT + w", hl.dsp.exec_cmd("qs -c xeome ipc call walls toggle"))
hl.bind(mod .. " + t", hl.dsp.exec_cmd("bash ~/.local/bin/theme-toggle"))
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
  local key = i % 10 -- workspace 10 is on key 0
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
