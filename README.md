
![jomo_dotfiles](https://cdn.discordapp.com/attachments/739162076886597715/954111167926767636/unknown.png)

This is my personal repo for my Arch linux configurations.

# Dependencies

| Type              | Package(s)                                |
| ----------------- | ----------------------------------------- |
| WM                | `i3-wm`                                   |
| Bar               | `polybar`                                 |
| Launcher          | `rofi`                                    |
| Compositor        | `picom-git`                               |
| Notifications     | `dunst`                                   |
| Terminal          | `alacritty`                               |
| GTK               | `Fluent Dark`                             |
| QT                | `Fluent Round Dark`                       |
| Icons             | `papirus-dark`                            |
| Cursor            | `adwaita`                                 |
| File manager      | `pcmanfm-qt`                              |
| Screenshot tool   | `flameshot`                               |
| Polkit manager    | `lxsession`                               |
| Fonts             | `ttf-iosevka-nerd ttf-jetbrains-mono` [1] |
| Wallpaper manager | `nitrogen`                                |
| Editor            | `neovim`<br> `neovide` (neovim client)    |

[1] For icons on `polybar` and `alacritty`.  
Raw dependency list `i3-wm polybar rofi picom-git dunst alacritty flameshot pcmanfm-qt nitrogen neovim lxsession ttf-iosevka-nerd betterlockscreen`

# Installation
    
```bash
chezmoi init https://github.com/xeome/laptopdots
chezmoi apply -v
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

![Screenshot 1](https://cdn.discordapp.com/attachments/739162076886597715/1135309077535264768/Untitled.png)