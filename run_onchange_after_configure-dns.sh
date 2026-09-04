#!/bin/bash
# DoT to Cloudflare/Quad9 as the machine's only system resolvers.
#
# What this buys is privacy from passive observers — the ISP, the AP you happen
# to be sitting on. Not integrity: DNSOverTLS=opportunistic is documented as
# downgradeable (man resolved.conf), so an active on-path attacker can still
# force cleartext. Deliberate trade — strict `yes` hard-fails on every captive
# portal, and ~/.local/bin/portal covers the portals that break anyway.
#
# Global servers race per-link ones ("in parallel to suitable per-link DNS
# servers"), they do not wait for them — so dns=none below is load-bearing.
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
# Managed by chezmoi — edit: ~/.local/share/chezmoi/run_onchange_after_configure-dns.sh
[Resolve]
DNS=
DNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net
Domains=
Domains=~.
DNSOverTLS=opportunistic
DNSSEC=no
MulticastDNS=no
RESOLVED

cat > "$STAGE/dns.conf" <<'NMCONF'
# Managed by chezmoi — edit: ~/.local/share/chezmoi/run_onchange_after_configure-dns.sh
# Both keys: dns= picks the plugin, systemd-resolved= stops the separate push
# that defaults to true. Costs per-connection DNS — internal zones go above.
[main]
dns=none
systemd-resolved=false
NMCONF

cat > "$STAGE/install.sh" <<'INSTALL'
#!/bin/bash
set -euo pipefail
STAGE="$1"

if ! cmp -s "$STAGE/10-dot.conf" /etc/systemd/resolved.conf.d/10-dot.conf; then
    install -Dm644 -o root -g root "$STAGE/10-dot.conf" \
        /etc/systemd/resolved.conf.d/10-dot.conf
    systemctl restart systemd-resolved
fi

# Restarting NM drops the wifi for a second, hence the guard.
if ! cmp -s "$STAGE/dns.conf" /etc/NetworkManager/conf.d/dns.conf; then
    install -Dm644 -o root -g root "$STAGE/dns.conf" \
        /etc/NetworkManager/conf.d/dns.conf
    systemctl restart NetworkManager
fi
INSTALL

pkexec /usr/bin/bash "$STAGE/install.sh" "$STAGE"
