"""
Everything this repo puts outside $HOME: the machine's packages, and drop-ins
under /etc. .chezmoiscripts/run_onchange_before_pyinfra.sh.tmpl runs it from
this directory whenever a file here or the machine's wm/is_laptop changes:

    uvx pyinfra@3.10.0 -y --sudo @local deploy.py --data wm=hyprland --data is_laptop=false

Every file goes to a drop-in directory, so the distro's own config stays stock.
/etc, not /usr/lib: /usr/lib belongs to the package manager. Deleting a put
leaves its file in /etc: to drop one, turn it into
files.file(path=..., present=False) until every machine has applied it.
"""

from pyinfra import host
from pyinfra.facts.pacman import PacmanPackages
from pyinfra.facts.server import OsRelease
from pyinfra.operations import files, server, systemd
from pyinfra.operations.util import any_changed

# Keyed by OsRelease id or id_like, so another family is one more entry here.
# `helper` names are outside the family's own repos. Deleting a name leaves it
# installed: to remove a package, add a
# server.packages(packages=[...], present=False) op below.
#
# equibop, waypaper, zen-browser-bin and swayfx are repo packages on CachyOS
# but AUR ones on plain Arch, so they are helper names: yay takes either.
PACKAGES = {
    "arch": {
        "repo": {
            "common": [
                "adw-gtk-theme", "age", "autotiling-rs", "bc", "bitwarden", "brightnessctl",
                "btop", "chezmoi", "evince", "fd", "fzf", "ghostty", "git-delta",
                "gnome-keyring", "grc", "gsettings-desktop-schemas", "gtk-update-icon-cache",
                "htop", "hyprlock", "inter-font", "jq", "kdeconnect", "kvantum", "kvantum-qt5",
                "libnotify", "mate-polkit", "most", "neovim", "network-manager-applet",
                "pamixer", "pavucontrol", "playerctl", "python-gobject", "python-numpy",
                "python-pillow", "qt5ct", "qt6ct", "quickshell", "seahorse", "starship",
                "swayidle", "thunar", "ttf-jetbrains-mono-nerd", "vim", "wl-clipboard",
                "xorg-xprop", "xorg-xwayland", "yazi", "yt-dlp", "zathura", "zellij", "zoxide",
                "zsh", "zsh-completions",
                # dns, oom and power below
                "systemd", "networkmanager", "polkit", "tlp", "tlp-pd",
            ],
            # quickshell/xeome/Shot.qml freezes the screen with grim and crops with vips.
            "hyprland": ["hyprland", "grim", "libvips"],
            "sway": ["flameshot"],
        },
        "helper": {
            "command": "yay -S --needed --noconfirm",
            "installed": PacmanPackages,
            "common": [
                "bibata-cursor-theme-bin", "equibop", "vicinae-bin", "waypaper",
                "zen-browser-bin", "zorin-icon-themes",
            ],
            "hyprland": [],
            "sway": ["swayfx"],
        },
    },
}

wm = host.data.get("wm")
is_laptop = host.data.get("is_laptop")
assert wm in ("hyprland", "sway") and isinstance(is_laptop, bool), (wm, is_laptop)

os_release = host.get_fact(OsRelease)
families = [os_release["id"], *os_release.get("id_like", "").split()]
family = next((PACKAGES[f] for f in families if f in PACKAGES), None)
if family is None:
    raise SystemExit(f"infra/deploy.py has no package names for {families}")


def put(src, dest, mode="644"):
    # Explicit mode: the local connector copies from a 0600 temp file.
    return files.put(name=dest, src=f"files/{src}", dest=dest, user="root", group="root", mode=mode)


# --- packages ----------------------------------------------------------------
server.packages(name="Packages", packages=family["repo"]["common"] + family["repo"][wm])


# --- desktop -----------------------------------------------------------------
put("desktop/50-dots-qt.conf", "/etc/environment.d/50-dots-qt.conf")
put("desktop/dots-qt.sh", "/etc/profile.d/dots-qt.sh")

keychron = put("desktop/70-dots-keychron.rules", "/etc/udev/rules.d/70-dots-keychron.rules")

# --- dns ---------------------------------------------------------------------
# DoT to Cloudflare/Quad9 as the machine's only resolvers.
#
# What this buys is privacy from passive observers — the ISP, the AP you happen
# to be sitting on. Not integrity: DNSOverTLS=opportunistic is documented as
# downgradeable (man resolved.conf), so an active on-path attacker can still
# force cleartext. Deliberate trade — strict `yes` hard-fails on every captive
# portal. Networks that block outside DNS are handled by the dispatcher hook,
# which falls back to the network's resolver on that link.
#
# The servers live on each link, set by the dispatcher, not in the global DNS=.
# Global servers race per-link ones ("in parallel to suitable per-link DNS
# servers"), and resolved only short-circuits on a positive answer: an NXDOMAIN
# from the link waits for the global side. When DoT is blocked that side never
# answers, so every nonexistent name hung for 120s. Same race is why dns=none
# in the NetworkManager drop-in is load-bearing.
#
# DNSSEC=no is deliberate. Against an active attacker it buys nothing that
# opportunistic DoT hasn't already conceded — allow-downgrade is strippable by
# the same attacker — and against a passive one DoT does all the work, since
# DNSSEC is integrity, not confidentiality. Cloudflare and Quad9 both validate
# upstream regardless. What local validation did buy was silent dead sites:
# resolved fails `no-signature` on CNAME chains into unsigned zones
# (discordstatus.com -> stspg-customer.com), with nothing but a journal line.
dns = [
    put("dns/50-dots-dot.conf", "/etc/systemd/resolved.conf.d/50-dots-dot.conf"),
    # /etc/NetworkManager/conf.d outranks NetworkManager.conf, which on this
    # machine says dns=systemd-resolved.
    put("dns/50-dots-dns.conf", "/etc/NetworkManager/conf.d/50-dots-dns.conf"),
    put("dns/50-dots-portal-dns", "/etc/NetworkManager/dispatcher.d/50-dots-portal-dns", mode="755"),
    # Stub mode, not the uplink file: anything reading resolv.conf directly (Go,
    # dig, Chrome's resolver, Docker) would otherwise skip resolved and send
    # cleartext :53 straight to whatever servers are listed — no DoT, no portal
    # hook. force: a fresh install ships a regular file here.
    files.link(name="/etc/resolv.conf", path="/etc/resolv.conf",
               target="/run/systemd/resolve/stub-resolv.conf", force=True),
]

# --- oom ---------------------------------------------------------------------
# systemd-oomd: kill one app under real memory pressure instead of freezing.
#
# Arch ships oomd with no policy, so enabling the service alone does nothing.
# These are Fedora's defaults:
#   - an app scope under user@.service is killed after 20s at 50% memory stall
#   - the biggest swap user anywhere is killed once swap passes 90%
# oomd kills whole cgroups. Hyprland runs in session-N.scope, outside
# user@.service, so the pressure kill never picks it. The swap kill covers
# every cgroup, so session scopes are omitted: a swap kill once picked the
# session scope for Zen's swap and took the compositor with it. Heavy apps
# launch into their own scopes (app() in hypr/hyprland.lua.tmpl), so they
# stay killable. ~/.local/bin/memwatch warns before either kill.
oom_units = [
    put("oom/slice.conf", "/etc/systemd/system/-.slice.d/50-dots-oomd.conf"),
    put("oom/session.conf", "/etc/systemd/system/session-.scope.d/50-dots-oomd.conf"),
    put("oom/user.conf", "/etc/systemd/system/user@.service.d/50-dots-oomd.conf"),
]
oomd_conf = put("oom/oomd.conf", "/etc/systemd/oomd.conf.d/50-dots-oomd.conf")

# --- power -------------------------------------------------------------------
# Power profiles for the quickshell bar's battery module. Two halves behind one
# three-way choice:
#   - tlp-pd answers org.freedesktop.UPower.PowerProfiles, which quickshell
#     binds natively. TLP applies the profile; polkit allows an active session
#     without a password.
#   - On a hybrid Intel CPU, power-saver also pins user.slice to the E-cores
#     via `systemctl set-property --runtime`. The polkit rule is what stops
#     that from popping a password dialog.
#
# Plus the menu's CPU limit slider, which writes intel_pstate/max_perf_pct
# directly, or every CPU's scaling_max_freq where there is no intel_pstate.
# The tmpfiles lines hand those files to wheel.
put("power/49-dots-ecore-pin.rules", "/etc/polkit-1/rules.d/49-dots-ecore-pin.rules")
tlp_unit = put("power/tlp-cpu-perf.conf", "/etc/systemd/system/tlp.service.d/50-dots-cpu-perf.conf")
tlp = [
    tlp_unit,
    put("power/dots-cpu-perf.conf", "/etc/tmpfiles.d/dots-cpu-perf.conf"),
    # TLP reads drop-ins from /etc/tlp.d only.
    put(f"power/tlp-{'laptop' if is_laptop else 'desktop'}.conf", "/etc/tlp.d/50-dots-profiles.conf"),
]

# --- services ----------------------------------------------------------------
# Before any restart below, so tlp starts with its new drop-in.
systemd.daemon_reload(name="daemon-reload", _if=any_changed(*oom_units, tlp_unit))

systemd.service(name="resolved", service="systemd-resolved.service", running=True, enabled=True)
# Restarting NetworkManager drops the link for a second. The dispatcher run
# re-derives every link now: resolved keeps bus-set link settings across a
# restart, so links set by an older dispatcher would otherwise stay stale until
# the next NM event.
systemd.service(name="Restart resolved", service="systemd-resolved.service", restarted=True, _if=any_changed(*dns))
systemd.service(name="Restart NetworkManager", service="NetworkManager.service", restarted=True, _if=any_changed(*dns))
server.shell(name="Dispatch DNS", commands=["/etc/NetworkManager/dispatcher.d/50-dots-portal-dns '' up"],
             _if=any_changed(*dns))

systemd.service(name="oomd", service="systemd-oomd.service", running=True, enabled=True)
# oomd reads oomd.conf.d only at start.
systemd.service(name="Restart oomd", service="systemd-oomd.service", restarted=True,
                _if=any_changed(*oom_units, oomd_conf))

# tlp.service is not enabled by the package on Arch, and without it nothing
# applies a profile at boot — tlp-pd alone only covers switching at runtime.
systemd.service(name="tlp", service="tlp.service", running=True, enabled=True)
systemd.service(name="tlp-pd", service="tlp-pd.service", running=True, enabled=True)
# Its ExecStartPost re-runs the tmpfiles lines, which TLP's driver mode switch
# would otherwise leave at root 0644. Only on a change, because a restart drops
# a manually picked profile.
systemd.service(name="Restart tlp", service="tlp.service", restarted=True, _if=any_changed(*tlp))

# Rules in /usr/lib/udev get this from systemd's alpm hook. /etc ones do not.
systemd.service(name="Reload udev", service="systemd-udevd.service", reloaded=True, _if=keychron.did_change)
server.shell(name="Trigger hidraw", commands=["udevadm trigger --subsystem-match=hidraw --action=change"],
             _if=keychron.did_change)

# --- helper packages ---------------------------------------------------------
# Last, so a helper build that fails (an AUR package, say) leaves the /etc
# state above applied. None of it needs these.
helper = family["helper"]
installed = host.get_fact(helper["installed"])
missing = [p for p in helper["common"] + helper[wm] if p not in installed]
if missing:  # an unconditional shell op would report a change on every run
    # As the invoking user: makepkg refuses root.
    server.shell(name="Helper packages", commands=[f"{helper['command']} {' '.join(missing)}"], _sudo=False)
