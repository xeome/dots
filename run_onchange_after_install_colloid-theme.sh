#!/bin/bash
# Builds vinceliuice/Colloid-icon-theme from source in grey, instead of the
# AUR package, which installs every accent. Grey because the graphite palette
# spends colour on meaning only, and a folder is not a meaning.
#
# GTK itself is adw-gtk3 with graphite's colours: chezmoi writes the theme
# folders (~/.local/share/themes/graphite-*) and ~/.config/gtk-4.0/gtk.css, so
# all this script adds is the gsettings that point at them.
#
# chezmoi re-runs this whenever it changes; a plain `git pull` on every run
# keeps the source current, same rolling-release contract as this repo's
# other "-git" AUR picks.
set -euo pipefail

SRC="$HOME/.cache/colloid-theme-src"
ICONS="$HOME/.local/share/icons"

# Before anything that needs the network: .chezmoiremove has already deleted
# the Colloid GTK themes a machine may still be set to, so a failed pull below
# must not leave GTK3 apps pointing at nothing. Light stays light. Skipped
# once it says graphite, so a later run doesn't undo theme-toggle.
current="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo '')"
if [[ "$current" != *graphite-* ]]; then
    if [[ "$current" == *Light* ]]; then mode=light; else mode=dark; fi
    gsettings set org.gnome.desktop.interface gtk-theme "graphite-$mode"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-$mode"
fi
# The Colloid cursors and orange icons are gone too. Bibata is the cursor the
# compositors already use (hyprland.lua, sway settings.conf); icons fall back
# to Adwaita until the grey build below replaces them.
if [[ "$(gsettings get org.gnome.desktop.interface cursor-theme)" == *Colloid* ]]; then
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
fi
if [[ "$(gsettings get org.gnome.desktop.interface icon-theme)" == *Colloid-Orange* ]]; then
    gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
fi

mkdir -p "$SRC" "$ICONS"

clone_or_pull() {
    if [[ -d "$2/.git" ]]; then
        git -C "$2" pull --ff-only --quiet
    else
        git clone --quiet --depth 1 "$1" "$2"
    fi
}

clone_or_pull https://github.com/vinceliuice/Colloid-icon-theme.git "$SRC/icons"

# Produces Colloid-Grey, Colloid-Grey-Light and Colloid-Grey-Dark. No
# cursors: the compositors set Bibata (hyprland.lua, sway settings.conf).
"$SRC/icons/install.sh" -t grey -d "$ICONS"

# Same skip-once-set rule as above; theme-toggle keeps it in step after this.
icons="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo '')"
if [[ "$icons" != *Colloid-Grey* ]]; then
    if [[ "$(gsettings get org.gnome.desktop.interface gtk-theme)" == *light* ]]; then
        gsettings set org.gnome.desktop.interface icon-theme 'Colloid-Grey-Light'
    else
        gsettings set org.gnome.desktop.interface icon-theme 'Colloid-Grey-Dark'
    fi
fi
