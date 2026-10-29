#!/bin/bash
# One-time cutover from the pkg/dots-* pacman packages to infra/deploy.py.
# Runs before run_onchange_before_pyinfra, since chezmoi orders before_ scripts
# by name: three of the packages' files sit at the /etc paths the deploy
# writes, so removing the packages after it would delete them. The deploy then
# finds every file new and restarts what reads them. Delete this file once
# every machine has applied it.
set -euo pipefail

mapfile -t pkgs < <(pacman -Qq | grep '^dots-')
((${#pkgs[@]})) || exit 0
# The removal takes the packages' /etc files with it; only the deploy puts
# them back, so stop here while it cannot run. Running it once fetches it, so a
# machine with uvx but no cached pyinfra and no network stops here too.
uvx pyinfra@3.10.0 --version >/dev/null ||
    { echo 'migrate-dots-to-pyinfra: cannot run pyinfra: install uv, or get online' >&2; exit 1; }

# Marked explicit first, or the removal leaves the whole desktop in `pacman -Qdt`.
# Guarded: the TLP profile packages have no dependencies, and may be all that is left.
mapfile -t deps < <(LC_ALL=C pacman -Qi "${pkgs[@]}" | sed -n 's/^Depends On *: //p' |
                    tr ' ' '\n' | grep -vx None | grep . | sort -u)
((${#deps[@]})) && sudo pacman -D --asexplicit "${deps[@]}" >/dev/null
sudo pacman -R --noconfirm "${pkgs[@]}"
