#!/bin/bash
# DoT to Cloudflare/Quad9, with nothing on the network able to override it.
# resolved's global DNS= only wins once no link publishes its own servers.
set -euo pipefail

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# Drop-in, so the package's resolved.conf stays stock. It has to: DNS= appends
# across files, so an uncommented DNS= over there would add to this list.
cat > "$STAGE/10-dot.conf" <<'RESOLVED'
# Managed by chezmoi — edit: ~/.local/share/chezmoi/run_onchange_after_configure-dns.sh
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net
DNSOverTLS=opportunistic
Domains=~.
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
