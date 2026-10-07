#!/bin/bash
# systemd-oomd: kill one app under real memory pressure instead of freezing.
#
# Arch ships oomd with no policy, so enabling the service alone does nothing.
# These are Fedora's defaults:
#   - an app scope under user@.service is killed after 20s at 50% memory stall
#   - the biggest swap user anywhere is killed once swap passes 90%
# Hyprland runs in session-N.scope, outside user@.service, so the pressure
# kill never picks the compositor. ~/.local/bin/memwatch warns before either.
#
# Root-owned, so staged as the user and installed with one pkexec, like
# configure-power. chezmoi re-runs this when this file changes.
set -euo pipefail

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

printf '[Slice]\nManagedOOMSwap=kill\n' >"$STAGE/slice.conf"
printf '[Service]\nManagedOOMMemoryPressure=kill\nManagedOOMMemoryPressureLimit=50%%\n' >"$STAGE/user.conf"
printf '[OOM]\nDefaultMemoryPressureDurationSec=20s\n' >"$STAGE/oomd.conf"

pkexec /usr/bin/bash -c '
set -euo pipefail
install -Dm644 "$1/slice.conf" "/etc/systemd/system/-.slice.d/10-oomd.conf"
install -Dm644 "$1/user.conf" "/etc/systemd/system/user@.service.d/10-oomd.conf"
install -Dm644 "$1/oomd.conf" /etc/systemd/oomd.conf.d/10-duration.conf
systemctl daemon-reload
systemctl enable --now systemd-oomd
' _ "$STAGE"

systemctl --user daemon-reload
systemctl --user enable --now memwatch.service
