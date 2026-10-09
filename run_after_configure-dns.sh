#!/bin/bash
# DoT to Cloudflare/Quad9 as the machine's only resolvers.
#
# What this buys is privacy from passive observers — the ISP, the AP you happen
# to be sitting on. Not integrity: DNSOverTLS=opportunistic is documented as
# downgradeable (man resolved.conf), so an active on-path attacker can still
# force cleartext. Deliberate trade — strict `yes` hard-fails on every captive
# portal. Networks that block outside DNS are handled by the dispatcher hook
# below, which falls back to the network's resolver on that link.
#
# The servers live on each link, set by the hook, not in the global DNS=.
# Global servers race per-link ones ("in parallel to suitable per-link DNS
# servers"), and resolved only short-circuits on a positive answer: an NXDOMAIN
# from the link waits for the global side. When DoT is blocked that side never
# answers, so every nonexistent name hung for 120s. Same race is why dns=none
# below is load-bearing.
#
# DNSSEC=no is deliberate. Against an active attacker it buys nothing that
# opportunistic DoT hasn't already conceded — allow-downgrade is strippable by
# the same attacker — and against a passive one DoT does all the work, since
# DNSSEC is integrity, not confidentiality. Cloudflare and Quad9 both validate
# upstream regardless. What local validation did buy was silent dead sites:
# resolved fails `no-signature` on CNAME chains into unsigned zones
# (discordstatus.com -> stspg-customer.com), with nothing but a journal line.
set -euo pipefail

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# Drop-in, so the package's resolved.conf stays stock. Drop-ins outrank it for
# single-value keys, but DNS= and Domains= are lists that *append* — hence the
# empty assignment before each. Without it a hand-edited DNS= in the main file
# (this repo has met one) silently prepends the router to the system resolvers.
cat > "$STAGE/10-dot.conf" <<'RESOLVED'
# Managed by chezmoi — edit: ~/.local/share/chezmoi/run_after_configure-dns.sh
[Resolve]
DNS=
FallbackDNS=1.0.0.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net
Domains=
DNSOverTLS=opportunistic
DNSSEC=no
MulticastDNS=no
RESOLVED

cat > "$STAGE/dns.conf" <<'NMCONF'
# Managed by chezmoi — edit: ~/.local/share/chezmoi/run_after_configure-dns.sh
# Both keys: dns= picks the plugin, systemd-resolved= stops the separate push
# that defaults to true. Costs per-connection DNS — internal zones go above.
[main]
dns=none
systemd-resolved=false
NMCONF

# FallbackDNS covers the window before the hook has run (it is only used while
# no link has servers), so it names the same two.

# Runs as root. Gives every wifi/ethernet link exactly one set of servers for
# every lookup: pinned DoT if it can leave through that link, otherwise the
# network's DHCP resolver in cleartext (captive portals, office LANs that block
# outside DNS). Never both — see the race above. The cost: on a DoT link, the
# network's own names (a router's .lan) go to Cloudflare and fail.
#
# Probed per interface, not via NM's connectivity state: that is global (a
# working hotspot keeps it "full" while ethernet is dead), and NM's own check
# resolves through the global servers over whichever link still works — it once
# passed ethernet, promoted it to default route, and took DNS down with it.
#
# Stateless: NM publishes no per-link DNS under dns=none, so any link DNS on a
# wifi/ethernet device is ours. Cleared on down: resolved only forgets per-link
# settings when the interface vanishes, and a built-in NIC never does.
cat > "$STAGE/50-portal-dns" <<'DISPATCH'
#!/bin/bash
# Managed by chezmoi — edit: ~/.local/share/chezmoi/run_after_configure-dns.sh
case $2 in
    up|dhcp4-change|dhcp6-change|connectivity-change) ;;  # last one: portal sign-in
    down)
        [[ $DEVICE_IFACE && $(nmcli -g GENERAL.TYPE device show "$DEVICE_IFACE") == @(wifi|ethernet) ]] &&
            resolvectl revert "$DEVICE_IFACE"
        exit 0 ;;
    *) exit 0 ;;
esac

# nmcli -g joins values with " | " and escapes colons.
field() { nmcli -g "$1" device show "$2" | sed 's/ | /\n/g; s/\\:/:/g' | grep .; }

DOT=(1.0.0.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net)

# Puts the link on DoT and has resolved itself look a name up through that link
# only — the exact path real lookups take. Handshake probes lie: the office DPI
# passes curl's HTTPS-looking handshake to 1.0.0.1:853 and stalls resolved's
# (SNI cloudflare-dns.com). A slow network fails this and gets its own resolver,
# which errs toward working DNS. Re-probing a network link puts it on DoT for up
# to 5s; leases here run days, so that is rare.
dot_ok() {
    resolvectl dns "$1" "${DOT[@]}"
    resolvectl dnsovertls "$1" opportunistic
    timeout 5 resolvectl query -i "$1" --cache=no example.com >/dev/null 2>&1
}

for dev in $(nmcli -g DEVICE,TYPE,STATE device |
             awk -F: '$3 == "connected" && ($2 == "wifi" || $2 == "ethernet") { print $1 }'); do
    mapfile -t domains < <({ field IP4.DOMAIN "$dev"; field IP6.DOMAIN "$dev"; } | sort -u)
    mapfile -t dns < <(field IP4.DNS "$dev"; field IP6.DNS "$dev")

    was=network; [[ $(resolvectl dnsovertls "$dev") == *opportunistic ]] && was=dot
    resolvectl domain "$dev" "${domains[@]}" '~.'
    resolvectl default-route "$dev" yes
    resolvectl dnssec "$dev" no
    if dot_ok "$dev" || [[ ${#dns[@]} -eq 0 ]]; then
        now=dot
        dns=("${DOT[@]}")
    else
        now=network
        resolvectl dns "$dev" "${dns[@]}"
        resolvectl dnsovertls "$dev" no
    fi
    if [[ $now != "$was" ]]; then
        resolvectl flush-caches  # or failures from the other mode stay cached
        logger -t portal-dns "$dev: $now -> ${dns[*]}"
    fi
done
DISPATCH

cat > "$STAGE/install.sh" <<'INSTALL'
#!/bin/bash
set -euo pipefail
STAGE="$1"

systemctl enable --now systemd-resolved

# Stub mode, not the uplink file: anything reading resolv.conf directly (Go,
# dig, Chrome's resolver, Docker) would otherwise skip resolved and send
# cleartext :53 straight to whatever servers are listed — no DoT, no portal hook.
stub=/run/systemd/resolve/stub-resolv.conf
[[ $(readlink /etc/resolv.conf) == "$stub" ]] || ln -sf "$stub" /etc/resolv.conf

if ! cmp -s "$STAGE/10-dot.conf" /etc/systemd/resolved.conf.d/10-dot.conf; then
    install -Dm644 -o root -g root "$STAGE/10-dot.conf" \
        /etc/systemd/resolved.conf.d/10-dot.conf
    systemctl restart systemd-resolved
fi

install -Dm755 -o root -g root "$STAGE/50-portal-dns" \
    /etc/NetworkManager/dispatcher.d/50-portal-dns

# Restarting NM drops the wifi for a second, hence the guard.
if ! cmp -s "$STAGE/dns.conf" /etc/NetworkManager/conf.d/dns.conf; then
    install -Dm644 -o root -g root "$STAGE/dns.conf" \
        /etc/NetworkManager/conf.d/dns.conf
    systemctl restart NetworkManager
fi

# Re-derive every link now: resolved keeps bus-set link settings across a
# restart, so links configured by an older hook would otherwise stay stale
# until the next NM event.
/etc/NetworkManager/dispatcher.d/50-portal-dns '' up
INSTALL

# Runs on every apply, so hand edits under /etc get reverted — but only asks for
# a password when something actually differs.
stub=/run/systemd/resolve/stub-resolv.conf
cmp -s "$STAGE/10-dot.conf" /etc/systemd/resolved.conf.d/10-dot.conf &&
    cmp -s "$STAGE/dns.conf" /etc/NetworkManager/conf.d/dns.conf &&
    cmp -s "$STAGE/50-portal-dns" /etc/NetworkManager/dispatcher.d/50-portal-dns &&
    [[ -x /etc/NetworkManager/dispatcher.d/50-portal-dns ]] &&
    [[ $(readlink /etc/resolv.conf) == "$stub" ]] &&
    systemctl -q is-enabled systemd-resolved &&
    systemctl -q is-active systemd-resolved &&
    exit 0

pkexec /usr/bin/bash "$STAGE/install.sh" "$STAGE"
