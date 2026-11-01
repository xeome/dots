#!/bin/bash
# Links ~/.config/zen/userChrome.css into every Zen profile. Zen only reads a
# profile's own chrome/ folder, and profile folders have random names, so
# chezmoi can't own the file at its real path. Runs on every apply, so a profile
# created later is covered by the next apply.
set -euo pipefail

ZEN="$HOME/.zen"
[[ -f "$ZEN/profiles.ini" ]] || exit 0

sed -n 's/^Path=//p' "$ZEN/profiles.ini" | while IFS= read -r path; do
    # Relative paths are the default; an absolute one (IsRelative=0) is kept.
    [[ "$path" == /* ]] && profile="$path" || profile="$ZEN/$path"
    [[ -d "$profile" ]] || continue
    css="$profile/chrome/userChrome.css"
    # Never replace a stylesheet someone wrote by hand.
    if [[ -e "$css" && ! -L "$css" ]]; then
        echo "zen: left $css alone (not a link)" >&2
        continue
    fi
    mkdir -p "$profile/chrome"
    ln -sfn "$HOME/.config/zen/userChrome.css" "$css"
    # Zen has had userChrome.css off by default since 1.x (ZenUIMigration).
    pref='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
    js="$profile/user.js"
    if ! grep -qxF "$pref" "$js" 2>/dev/null; then
        # A hand-written user.js may not end in a newline; don't glue onto its last line.
        [[ -s "$js" && -n "$(tail -c1 "$js")" ]] && echo >> "$js"
        echo "$pref" >> "$js"
    fi
done
