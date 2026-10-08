#!/bin/bash
# Qt's half of the graphite theme, for every session:
#   QT_QPA_PLATFORMTHEME=gtk3  font and icons from the same gsettings GTK uses,
#                              which theme-toggle already flips
#   QT_STYLE_OVERRIDE=kvantum  widgets drawn by the Kvantum theme that
#                              build-kvantum writes, in Qt5 and Qt6 alike
# /etc/environment because pam_env hands it to every login, ly's and a tty's,
# so Hyprland, sway and the systemd user services all see it; sway has no env
# file of its own. Only these two lines are set: the rest of the file is the
# machine's own. Takes effect at the next login.
#
# Root-owned, so staged as the user and installed with one pkexec, which is
# skipped when the file already says this, like configure-dns.
set -euo pipefail

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

{
    grep -vE '^(QT_QPA_PLATFORMTHEME|QT_STYLE_OVERRIDE)=' /etc/environment || true
    printf 'QT_QPA_PLATFORMTHEME=gtk3\nQT_STYLE_OVERRIDE=kvantum\n'
} >"$STAGE/environment"

cmp -s "$STAGE/environment" /etc/environment && exit 0
pkexec /usr/bin/install -m644 -o root -g root "$STAGE/environment" /etc/environment
