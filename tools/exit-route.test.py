#!/usr/bin/env python3
"""python3 -I tools/exit-route.test.py — checks infra/files/exit/dots-exit-route.service.

Runs the unit's rules in a throwaway network namespace before tailscale0
exists, as at boot. Then it asks the kernel where each kind of packet goes,
with a stand-in tunnel up and down. Needs unprivileged user namespaces.
"""
import pathlib
import re
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
lines = (ROOT / "infra/files/exit/dots-exit-route.service").read_text().splitlines()
assert not any(l.startswith("ExecStop=") for l in lines), "ExecStop drops the kill switch on every stop and restart"
table = re.search(r'"ipv4.route-table": "(\d+)"', (ROOT / "infra/deploy.py").read_text())[1]


# As systemd runs it: a failing line stops the unit, unless it starts with "-".
def systemd(line):
    cmd = line.removeprefix("ExecStart=")
    return cmd[1:] if cmd.startswith("-") else f"{cmd} || exit 99"


start = "\n".join(systemd(l) for l in lines if l.startswith("ExecStart="))

QUERIES = {
    "exit": "1.1.1.1 from 100.100.1.4 iif tailscale0",
    "exit6": "2606:4700::1111 from fd7a:115c:a1e0::4 iif tailscale0",
    "bridge": "172.17.0.2 from 100.100.1.4 iif tailscale0",
    "tailnet": "100.100.1.4",
    "tunnel-reply": "100.100.1.4 from 1.1.1.1 iif ws-exit",
    "underlay": "1.1.1.1 mark 0x80000",
    "own": "1.1.1.1",
}
ask = "\n".join(f'echo "{k}: $(ip route get {q} 2>&1 | head -1)"' for k, q in QUERIES.items())

script = f"""
sysctl -qw net.ipv4.ip_forward=1 net.ipv6.conf.all.forwarding=1 net.ipv4.conf.all.rp_filter=0
{start}
set -e
for i in eth0 tailscale0 ws-exit docker0; do ip link add $i type dummy; ip link set $i up; done
ip addr add 192.168.1.105/24 dev eth0; ip route add default via 192.168.1.1 dev eth0
ip -6 addr add 2001:db8::5/64 dev eth0 nodad; ip -6 route add default via 2001:db8::1 dev eth0
ip addr add 172.17.0.1/16 dev docker0
ip addr add 100.100.1.1/32 dev tailscale0; ip route add 100.100.1.4 dev tailscale0 table 52
ip -6 addr add fd7a:115c:a1e0::1/128 dev tailscale0 nodad; ip -6 route add fd7a:115c:a1e0::4 dev tailscale0 table 52
for f in -4 -6; do ip $f rule add pref 5210 fwmark 0x80000/0xff0000 lookup main; ip $f rule add pref 5270 lookup 52; done
ip route add default dev ws-exit table {table}
echo "== up"
{ask}
ip route del default dev ws-exit table {table}
echo "== down"
{ask}
"""
run = subprocess.run(["unshare", "-rn", "bash", "-c", script], capture_output=True, text=True)
print(run.stdout)
assert run.returncode != 99, f"an ExecStart line failed, which fails the unit at boot:\n{run.stderr}"
assert run.returncode == 0, f"the namespace setup failed:\n{run.stderr}"
up, down = (dict(l.split(": ", 1) for l in s.strip().splitlines()[1:]) for s in run.stdout.split("== ")[1:])

assert "dev ws-exit" in up["exit"], f"exit clients bypass the tunnel: {up['exit']}"
assert "dev tailscale0" in up["tailnet"], up["tailnet"]
assert "dev tailscale0" in up["tunnel-reply"], f"replies from the tunnel miss the tailnet: {up['tunnel-reply']}"
assert "dev eth0" in up["underlay"], f"tailscaled's own UDP enters the tunnel: {up['underlay']}"
assert "dev eth0" in up["own"], f"the desktop's own traffic enters the tunnel: {up['own']}"
assert "unreachable" in up["exit6"], f"exit clients leak over IPv6: {up['exit6']}"
assert "unreachable" in down["exit"], f"exit clients leak with the tunnel down: {down['exit']}"
assert "dev eth0" in down["own"], down["own"]
for state, got in (("up", up["bridge"]), ("down", down["bridge"])):
    assert "dev docker0" in got, f"tailnet to a local bridge misses it with the tunnel {state}: {got}"
print("ok")
