#!/bin/bash
# Zen only reads a profile's own folder, and profile folders have random
# names, so chezmoi can't own these files at their real paths. Runs on every
# apply, so a profile created later is covered by the next one.
# tools/zen-link.test.py checks it.
set -euo pipefail

ZEN="$HOME/.zen"
HOMETAB="$HOME/.config/zen/hometab"
[[ -f "$ZEN/profiles.ini" ]] || exit 0

# userChrome.css is off by default since Zen 1.x. The hometab is unsigned;
# Zen's build lets the pref turn the check off (MOZ_REQUIRE_SIGNING is false).
# Without replace-newtab false, Ctrl+T opens only the URL bar. Scheme 2 is
# Auto, so Zen follows theme-toggle; 0 and 1 pin it dark or light.
PREFS=(
    'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
    'user_pref("xpinstall.signatures.required", false);'
    'user_pref("zen.urlbar.replace-newtab", false);'
    'user_pref("zen.view.window.scheme", 2);'
)

sed -n 's/^Path=//p' "$ZEN/profiles.ini" | while IFS= read -r path; do
    # Relative paths are the default; an absolute one (IsRelative=0) is kept.
    [[ "$path" == /* ]] && profile="$path" || profile="$ZEN/$path"
    [[ -d "$profile" ]] || continue

    css="$profile/chrome/userChrome.css"
    # Never replace a stylesheet someone wrote by hand.
    if [[ -e "$css" && ! -L "$css" ]]; then
        echo "zen: left $css alone (not a link)" >&2
    else
        mkdir -p "$profile/chrome"
        ln -sfn "$HOME/.config/zen/userChrome.css" "$css"
    fi

    # A proxy file: Firefox loads the extension unpacked from the folder it
    # names. Zen installs it disabled and asks once.
    proxy="$profile/extensions/hometab@xeome"
    if [[ "$(cat "$proxy" 2>/dev/null)" != "$HOMETAB" ]]; then
        mkdir -p "$profile/extensions"
        echo "$HOMETAB" > "$proxy"
    fi

    js="$profile/user.js"
    for pref in "${PREFS[@]}"; do
        grep -qxF "$pref" "$js" 2>/dev/null && continue
        # A hand-written user.js may not end in a newline; don't glue onto its last line.
        [[ -s "$js" && -n "$(tail -c1 "$js")" ]] && echo >> "$js"
        echo "$pref" >> "$js"
    done
done
