#!/bin/bash
# One-time cleanup after /etc moved into the pkg/dots-* packages: deletes what
# the old configure-dns/oom/power/qt-env scripts wrote. The packages ship the
# same settings under new names, so until this runs both copies are read, with
# equal values. Delete this file once every machine has applied it.
set -euo pipefail

sudo bash -c '
set -euo pipefail
rm -f /etc/systemd/resolved.conf.d/10-dot.conf \
      /etc/NetworkManager/conf.d/dns.conf \
      /etc/NetworkManager/dispatcher.d/50-portal-dns \
      /etc/systemd/system/-.slice.d/10-oomd.conf \
      /etc/systemd/system/session-.scope.d/10-oomd.conf \
      /etc/systemd/system/user@.service.d/10-oomd.conf \
      /etc/systemd/oomd.conf.d/10-duration.conf \
      /etc/polkit-1/rules.d/49-ecore-pin.rules \
      /etc/tmpfiles.d/cpu-perf.conf \
      /etc/systemd/system/tlp.service.d/cpu-perf.conf \
      /etc/tlp.d/50-profiles.conf
# Only the directories the old scripts created. polkit, systemd,
# networkmanager and tlp own the other parents.
for d in /etc/systemd/resolved.conf.d /etc/systemd/oomd.conf.d \
         /etc/systemd/system/-.slice.d /etc/systemd/system/session-.scope.d \
         /etc/systemd/system/user@.service.d /etc/systemd/system/tlp.service.d; do
    if [[ -d $d ]]; then rmdir --ignore-fail-on-non-empty "$d"; fi
done
# dots-desktop sets these now; left here they would override its file for
# user services, since environment.d reads /etc/environment last.
sed -i "/^QT_QPA_PLATFORMTHEME=/d; /^QT_STYLE_OVERRIDE=/d" /etc/environment
# The old unit drop-ins are gone; without this, systemd keeps them loaded.
systemctl daemon-reload
'
