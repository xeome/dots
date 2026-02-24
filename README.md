This is my personal repo for my Arch linux configurations.

# Dependencies

| Type            | Package(s)                                           |
| --------------- | ---------------------------------------------------- |
| WM              | `hyprland`                                           |
| Bar             | `waybar`                                             |
| Launcher        | `vicinae`                                            |
| Notifications   | `swaync`                                             |
| Terminal        | `ghostty`                                            |
| Theming         | `matugen`                                            |
| Cursor          | `Bibata-Modern-Classic`                              |
| Wallpaper       | `waypaper`                                           |
| Lock screen     | `hyprlock`                                           |
| OSD             | `swayosd`                                            |
| File manager    | `thunar`                                             |
| Screenshot tool | `flameshot`                                          |
| Polkit manager  | `polkit-gnome`                                       |
| Fonts           | `ttf-iosevka-nerd ttf-jetbrains-mono monaspace Neon` |
| Editor          | `neovim`                                             |

You can also use `yay -S --needed - < pkgs` to install all dependencies.

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

| Shortcut               | Action                              |
| ---------------------- | ----------------------------------- |
| Super + Return         | Launch terminal (`ghostty`)         |
| Super + E              | Launch file manager (`thunar`)      |
| Super + Q              | Launch web browser (`zen-browser`)  |
| Super + R              | Launch app launcher (`vicinae`)     |
| Super + L              | Lock screen (`hyprlock`)            |
| Super + Shift + C      | Close focused window                |
| Super + Shift + R      | Reload Hyprland config              |
| Super + Shift + Q      | Open power menu                     |
| Super + 1-9 / 0        | Switch to workspace 1–10            |
| Print                  | Screenshot (`flameshot`)            |
