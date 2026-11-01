This is my personal repo for my Arch linux configurations.

# Layout

```
home/     what chezmoi writes into ~ (.chezmoiroot points here)
  .chezmoidata.toml   what differs per machine: wm, monitors, text scale
  .chezmoiscripts/    what runs on apply: the infra deploy, the Kvantum build, gsettings
  dot_config/         ~/.config, one folder per program
  dot_local/          ~/.local: bin/ scripts, GTK themes, fonts
infra/    what lands outside ~: packages and /etc drop-ins (pyinfra)
  deploy.py           one section per concern, matching the folders in files/
  files/              the files deploy.py puts, by concern
tools/    never deployed; run from the repo
  grain.py, plymouth.py   bake the committed grain tiles and boot splash; run by hand
  kvantum.py              builds the Qt theme; apply runs it when its inputs change
  check-palette.py        holds every copied colour to Theme.qml; run after a palette edit
  *.test.*                checks for scripts that do deploy
```

Names under `home/` are chezmoi's: `dot_` is a leading dot, `exact_` makes
chezmoi delete anything in that folder it does not manage, `private_` sets
mode 0700/0600, `executable_` sets the x bit, `modify_` is a script that
rewrites a file the program also edits, and `.tmpl` files are templates.

The graphite palette is defined once, in
`home/dot_config/exact_quickshell/exact_xeome/Theme.qml`. The GTK, terminal,
compositor, Discord, browser and launcher themes repeat its values, and
`tools/check-palette.py` fails when one drifts.

To add a machine, give it a `[machines.<hostname>]` entry in
`home/.chezmoidata.toml`, then run `python3 -I tools/plymouth.py` and commit
its splash.

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
| Fonts                      | `inter-font ttf-jetbrains-mono-nerd`                 |
| Editor                     | `neovim`                                             |

One `quickshell` process draws the bar, the notification centre and the OSD.
It runs on both compositors: `Compositor.qml.tmpl` picks the
`Quickshell.Hyprland` or `Quickshell.I3` backend from the machine's `wm`, and
nothing else in the shell knows which compositor it's on.

The packages, and everything this repo puts under `/etc`, come from one
[pyinfra](https://pyinfra.com) deploy, `infra/deploy.py`: the package names for
the machine's `wm`, and drop-ins for DNS, systemd-oomd, TLP profiles, polkit,
udev and the Qt environment. `chezmoi apply` runs it through `uvx` whenever a
file in `infra/` changes, so it needs `uv`, `yay` and `base-devel` first.
Remove `power-profiles-daemon` before the first apply: `tlp-pd` conflicts with
it, and the unattended install answers no. On a machine missing AUR packages,
`yay` asks for the sudo password a second time. A package name deleted from
the deploy stays installed; its package table says how to remove one.

The deploy also themes the boot: a `plymouth` splash with the hostname in
dots, a graphite console palette on the kernel cmdline, and Ly's colours and
big clock. It only touches the boot on the dracut + kernel-install +
systemd-boot stack, and skips that section with a printed reason anywhere
else. If the splash ever hangs, press `e` in the boot menu and delete `splash`.
After adding a machine, run `tools/plymouth.py` to draw its wordmark.

# Installation

Incomplete but should get you most things.

```bash
chezmoi init https://github.com/xeome/dots
chezmoi apply -v
```

# Some shortcuts

Kept identical on both compositors, so muscle memory carries between machines.

| Shortcut          | Action                             |
| ----------------- | ---------------------------------- |
| Super + Return    | Launch terminal (`ghostty`)        |
| Super + E         | Launch file manager (`thunar`)     |
| Super + Q         | Launch web browser (`zen-browser`) |
| Super + R         | Launch app launcher (`vicinae`)    |
| Super + B         | Copy a reaction image              |
| Super + Shift + V | Clipboard history                  |
| Super + P         | Project sessionizer                |
| Super + L         | Lock screen (`hyprlock`)           |
| Super + K         | Toggle notification centre         |
| Super + T         | Toggle light and dark theme        |
| Super + Shift + C | Close focused window               |
| Super + Shift + R | Reload compositor config           |
| Super + arrows    | Focus window in that direction     |
| Super + 1-9 / 0   | Switch to workspace 1–10           |
| Print             | Screenshot                         |

The power menu has no keybind — it hangs off the battery module in the bar.
