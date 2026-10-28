This is my personal repo for my Arch linux configurations.

# Dependencies

| Type                       | Package(s)                                           |
| -------------------------- | ---------------------------------------------------- |
| WM                         | `hyprland`, or `swayfx` on machines set to sway      |
| Bar, notifications and OSD | `quickshell`                                         |
| Launcher                   | `vicinae`                                            |
| Terminal                   | `ghostty`                                            |
| Cursor                     | `Bibata-Modern-Classic`                              |
| Wallpaper                  | `waypaper`                                           |
| Lock screen                | `hyprlock`                                           |
| File manager               | `thunar`                                             |
| Screenshot tool            | quickshell `Shot` on hyprland, `flameshot` on sway   |
| Polkit manager             | `mate-polkit`                                        |
| Fonts                      | `ttf-iosevka-nerd ttf-jetbrains-mono monaspace Neon` |
| Editor                     | `neovim`                                             |

One `quickshell` process draws the bar, the notification centre and the OSD —
waybar, swaync and swayosd are all retired. It runs on both compositors:
`Compositor.qml.tmpl` picks the `Quickshell.Hyprland` or `Quickshell.I3`
backend from the machine's `wm`, and nothing else in the shell knows which
compositor it's on.

The packages, and everything this repo puts under `/etc`, are pacman packages
built from `pkg/`: `dots-desktop` on every machine, `dots-hyprland` or
`dots-sway` by the machine's `wm`, and `dots-dns`, `dots-oom` and `dots-power`
with a laptop or desktop TLP profile. `chezmoi apply` builds and installs the
ones whose files changed, so it needs `yay` and `base-devel` first. Orphans
left by a name dropped from a PKGBUILD show in `pacman -Qdt`.

# Installation

Incomplete but should get you most things.

```bash
chezmoi init https://github.com/xeome/dots
chezmoi apply -v
# Optional: install Monaspace font
mkdir -p ~/.fonts
wget https://github.com/githubnext/monaspace/releases/download/v1.000/monaspace-v1.000.zip && unzip monaspace-v1.000.zip -d ~/.fonts
fc-cache -frv
rm -f monaspace-v1.000.zip
```

# Some shortcuts

Kept identical on both compositors, so muscle memory carries between machines.

| Shortcut          | Action                             |
| ----------------- | ---------------------------------- |
| Super + Return    | Launch terminal (`ghostty`)        |
| Super + E         | Launch file manager (`thunar`)     |
| Super + Q         | Launch web browser (`zen-browser`) |
| Super + R         | Launch app launcher (`vicinae`)    |
| Super + P         | Project sessionizer                |
| Super + L         | Lock screen (`hyprlock`)           |
| Super + K         | Toggle notification centre         |
| Super + Shift + C | Close focused window               |
| Super + Shift + R | Reload compositor config           |
| Super + arrows    | Focus window in that direction     |
| Super + 1-9 / 0   | Switch to workspace 1–10           |
| Print             | Screenshot                         |

The power menu has no keybind — it hangs off the battery module in the bar.
