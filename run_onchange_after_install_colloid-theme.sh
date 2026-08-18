#!/bin/bash
# Builds vinceliuice/Colloid-gtk-theme and Colloid-icon-theme from source
# instead of the AUR packages: those build with `-t all`, no --tweaks, and
# install every accent/scheme combination that exists rather than the one
# (orange, black, normal-titlebuttons) Theme.qml's light/dark toggle actually
# uses. Building ourselves means one command controls exactly what gets
# installed.
#
# chezmoi re-runs this whenever it changes; a plain `git pull` on every run
# keeps the source current, same rolling-release contract as this repo's
# other "-git" AUR picks.
set -euo pipefail

SRC="$HOME/.cache/colloid-theme-src"
THEMES="$HOME/.local/share/themes"
ICONS="$HOME/.local/share/icons"
GTK4="$HOME/.config/gtk-4.0"

mkdir -p "$SRC" "$THEMES" "$ICONS" "$GTK4"

clone_or_pull() {
    if [[ -d "$2/.git" ]]; then
        git -C "$2" pull --ff-only --quiet
    else
        git clone --quiet --depth 1 "$1" "$2"
    fi
}

clone_or_pull https://github.com/vinceliuice/Colloid-gtk-theme.git "$SRC/gtk"
clone_or_pull https://github.com/vinceliuice/Colloid-icon-theme.git "$SRC/icons"

# GTK2/3 + gnome-shell/metacity assets, both colors in one pass (that's what
# the installer's own -c light dark loop is for). Orange accent to match
# Theme.qml's peach/burnt-orange; black is Colloid's own "blackness" tweak;
# normal keeps stock max/min/close window buttons instead of Colloid's own.
# Produces Colloid-Orange-Light and Colloid-Orange-Dark under $THEMES.
"$SRC/gtk/install.sh" -t orange -c light dark --tweaks black normal -d "$THEMES"

# GTK4/libadwaita apps read ~/.config/gtk-4.0/gtk.css unconditionally at
# startup and don't support swapping theme folders at runtime — the -l flag
# just overwrites that one file, so build each color separately and stash
# both. theme-toggle symlinks gtk.css to whichever one is current; apps pick
# up a change on their next restart, not live.
#
# -t orange here too: install_theme() (which also writes plain, blue-accented
# Colloid-Light/-Dark folders under $THEMES) runs unconditionally on every
# invocation regardless of -l, so dropping it would both re-introduce the
# stray untweaked variants this script exists to avoid and, if the libadwaita
# scss reads the accent the same way blackness does, leave the gtk-4.0
# overlay blue instead of orange.
"$SRC/gtk/install.sh" -t orange -c light -l system --tweaks black normal -d "$THEMES"
cp "$GTK4/gtk.css" "$GTK4/colloid-light.css"
"$SRC/gtk/install.sh" -t orange -c dark -l system --tweaks black normal -d "$THEMES"
cp "$GTK4/gtk.css" "$GTK4/colloid-dark.css"

# Icons + cursors, same orange accent. No --tweaks here: colors_folder()
# only reads -t/-s, not the GTK theme's --tweaks. cursors/install.sh uses
# relative paths with no internal cd, so it has to be run from its own dir.
"$SRC/icons/install.sh" -t orange -d "$ICONS"
(cd "$SRC/icons/cursors" && bash install.sh)

# Re-point gtk.css at whichever mode is current every run — the -l builds
# above just deleted and rewrote it as a plain (non-symlink) dark file, so
# skipping this on a re-run would silently drop a light-mode user back to
# dark until they toggled twice.
current="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo '')"
if [[ "$current" == *Light* ]]; then
    ln -sf "$GTK4/colloid-light.css" "$GTK4/gtk.css"
else
    ln -sf "$GTK4/colloid-dark.css" "$GTK4/gtk.css"
fi

# Bootstrap the rest of gsettings once. Skipped once gtk-theme already says
# Colloid, so a later git pull bumping this script doesn't stomp on
# whichever mode theme-toggle last set.
if [[ "$current" != *Colloid* ]]; then
    gsettings set org.gnome.desktop.interface gtk-theme 'Colloid-Orange-Dark'
    gsettings set org.gnome.desktop.interface icon-theme 'Colloid-Orange-Dark'
    # dark-cursors is the white cursor (built from svg-white) — right for a
    # dark bg despite the name. theme-toggle keeps both in sync from here.
    gsettings set org.gnome.desktop.interface cursor-theme 'Colloid-dark-cursors'
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi
