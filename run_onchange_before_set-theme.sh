#!/bin/bash
# Points gsettings at the themes chezmoi writes: GTK is adw-gtk3 with
# graphite's colours (~/.local/share/themes/graphite-*, ~/.config/gtk-4.0/gtk.css),
# icons are ZorinGrey from the zorin-icon-themes package (pkgs). Grey because
# the graphite palette spends colour on meaning only, and a folder is not a
# meaning. A before_ script, after install_packages, so the qt5ct/qt6ct
# modify_ scripts already read these gsettings in the same apply.
set -euo pipefail

# .chezmoiremove has already deleted the Colloid GTK themes a machine may still
# be set to. Light stays light. Skipped once it says graphite, so a later run
# doesn't undo theme-toggle.
current="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo '')"
if [[ "$current" != *graphite-* ]]; then
    if [[ "$current" == *Light* ]]; then mode=light; else mode=dark; fi
    gsettings set org.gnome.desktop.interface gtk-theme "graphite-$mode"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-$mode"
fi
# The Colloid cursors and orange icons are gone too. Bibata is the cursor the
# compositors already use (hyprland.lua, sway settings.conf).
if [[ "$(gsettings get org.gnome.desktop.interface cursor-theme)" == *Colloid* ]]; then
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
fi
# XWayland apps don't read gsettings: they take the cursor from the files
# nwg-look wrote, which still name Colloid and so fall back to the X default.
for f in ~/.icons/default/index.theme ~/.config/xsettingsd/xsettingsd.conf \
         ~/.gtkrc-2.0 ~/.config/gtk-3.0/settings.ini; do
    [[ -f "$f" ]] && sed -i 's/Colloid-cursors/Bibata-Modern-Classic/' "$f"
done

# Same skip-once-set rule as above; theme-toggle keeps it in step after this.
icons="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo '')"
if [[ "$icons" != *ZorinGrey* ]]; then
    if [[ "$(gsettings get org.gnome.desktop.interface gtk-theme)" == *light* ]]; then
        gsettings set org.gnome.desktop.interface icon-theme 'ZorinGrey-Light'
    else
        gsettings set org.gnome.desktop.interface icon-theme 'ZorinGrey-Dark'
    fi
fi

# XWayland GTK3 apps read settings.ini, not gsettings, and nwg-look left it on
# the removed Colloid-Orange themes. theme-toggle keeps it in step after this.
if [[ -f ~/.config/gtk-3.0/settings.ini ]]; then
    gtk="$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")"
    icons="$(gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")"
    sed -i -E "s/^(gtk-theme-name=).*/\1$gtk/; s/^(gtk-icon-theme-name=).*/\1$icons/" \
        ~/.config/gtk-3.0/settings.ini
fi
