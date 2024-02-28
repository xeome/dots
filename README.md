![jomo_dotfiles](https://xeome.dev/unknown.png)

This is my personal repo for my Arch linux configurations.

# Dependencies

| Type            | Package(s)                                           |
| --------------- | ---------------------------------------------------- |
| WM              | `swayfx`                                             |
| Bar             | `waybar`                                             |
| Launcher        | `rofi`                                               |
| Notifications   | `ags`                                                |
| Terminal        | `alacritty`                                          |
| GTK             | `Catppuccin Mocha`                                   |
| QT              | `Catppuccin Mocha`                                   |
| Icons           | `papirus-dark`                                       |
| Cursor          | `bibata`                                             |
| File manager    | `pcmanfm-qt`                                         |
| Screenshot tool | `flameshot`                                          |
| Polkit manager  | `lxsession`                                          |
| Fonts           | `ttf-iosevka-nerd ttf-jetbrains-mono monaspace Neon` |
| Editor          | `neovim`                                             |

You can also use `yay -S --needed - < pkgs` to install all dependencies.

# Installation

Incomplete but should get you most things.

```bash
chezmoi init https://github.com/xeome/dots
chezmoi apply -v
# Optional if you want to get san francisco pro font
mkdir -p ~/.fonts
wget xeome.dev/sf-pro.zip && unzip sf-pro.zip -d ~/.fonts
wget https://github.com/githubnext/monaspace/releases/download/v1.000/monaspace-v1.000.zip && unzip monaspace-v1.000.zip -d ~/.fonts
fc-cache -frv
rm -rf "sf-pro.zip" "monaspace-v1.000.zip"
```

# Some shortcuts

| Shortcut               | Action                             |
| ---------------------- | ---------------------------------- |
| Super + Return (enter) | Launch terminal (`alacritty`)      |
| Super + E              | Launch file manager (`pcmanfm-qt`) |
| Super + Q              | Launch web browser (`brave`)       |
| Super + Shift + C      | Close focused application          |
| Super + Shift + R      | Restart window manager             |
| Super + Shift + Q      | Quit window manager                |
| Super + R              | Start program launcher (`rofi`)    |
| Super + 1-9            | Switch workspaces from 1 to 9      |

## Screenshots

![sway](https://github.com/xeome/laptopdots/assets/44901648/90cc9330-3e1d-4e03-8c83-993f0da35360)
