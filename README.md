![jomo_dotfiles](https://cdn.discordapp.com/attachments/739162076886597715/954111167926767636/unknown.png)

This is my personal repo for my Arch linux configurations.

# Dependencies

| Type            | Package(s)                                           |
| --------------- | ---------------------------------------------------- |
| WM              | `sway`                                               |
| Bar             | `waybar`                                             |
| Launcher        | `rofi`                                               |
| Notifications   | `dunst`                                              |
| Terminal        | `alacritty`                                          |
| GTK             | `Fluent Dark`                                        |
| QT              | `Fluent Round Dark`                                  |
| Icons           | `papirus-dark`                                       |
| Cursor          | `bibata`                                             |
| File manager    | `pcmanfm-qt`                                         |
| Screenshot tool | `flameshot`                                          |
| Polkit manager  | `lxsession`                                          |
| Fonts           | `ttf-iosevka-nerd ttf-jetbrains-mono monaspace Neon` |
| Editor          | `neovim`                                             |

You can also use `yay -S --needed - < pkgs` to install all dependencies.

# Installation

```bash
chezmoi init https://github.com/xeome/laptopdots
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
| Super + Q              | Launch web browser (`thorium`)     |
| Super + Shift + C      | Close focused application          |
| Super + Shift + R      | Restart window manager             |
| Super + Shift + Q      | Quit window manager                |
| Super + R              | Start program launcher (`rofi`)    |
| Super + 1-9            | Switch workspaces from 1 to 9      |

## Screenshots

![Untitled](https://github.com/xeome/laptopdots/assets/44901648/887457fa-cbee-4e7a-80a4-4d383f1f14f2)
