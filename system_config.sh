#!/bin/bash

# Check if user is root, if not exit
if [[ ${EUID} -ne 0 ]]; then
	echo "Please run as root"
	exit
fi

# Kernel parameters
if grep -E "zswap.enabled=1|zswap.max_pool_percent=6|zswap.compressor=zstd|transparent_hugepage=always|amd-pstate=guided|mitigations=off|skew_tick=1|amd_prefcore=enable" /etc/kernel/cmdline; then
	echo "Kernel parameters already set, skipping"
else
	echo "Kernel parameters not set, setting them now"
	if [[ -f /etc/kernel/cmdline ]]; then
		cp /etc/kernel/cmdline /etc/kernel/cmdline.bak
		echo -n " zswap.enabled=1 zswap.max_pool_percent=6 zswap.compressor=zstd transparent_hugepage=always amd-pstate=guided mitigations=off skew_tick=1 amd_prefcore=enable" >>/etc/kernel/cmdline
		echo "Reboot required to apply kernel parameters, you can reboot now or later."
	else
		echo "No /etc/kernel/cmdline file found"
	fi
fi

# Create a script to run at boot
cat <<EOF >/usr/local/bin/system_config.sh
#!/bin/bash
echo -n "advise" | tee /sys/kernel/mm/transparent_hugepage/shmem_enabled
EOF

# Make it executable
chmod +x /usr/local/bin/system_config.sh

# Create a systemd service to run some commands at boot
cat <<EOF >/etc/systemd/system/system_config.service
[Unit]
Description=System Config
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash /usr/local/bin/system_config.sh

[Install]
WantedBy=multi-user.target
EOF

# Enable
systemctl enable --now system_config.service

# Create sysctl.d file
cat <<EOF >/etc/sysctl.d/99-sysctl-custom.conf
### Memory tweaks
vm.swappiness = 10
vm.vfs_cache_pressure = 110
vm.page-cluster = 0
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.compaction_proactiveness = 20

### Network
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_adv_win_scale = -2
net.ipv4.tcp_mtu_probing = 1
net.core.busy_read=50
net.core.busy_poll=50

### MISC
kernel.nmi_watchdog = 0
kernel.perf_event_paranoid=1
EOF

# Reload sysctl
sysctl --system

# Sway script
cat <<EOF >/usr/local/bin/sw
#!/usr/bin/env bash
export SDL_VIDEODRIVER=wayland
export QT_QPA_PLATFORM=wayland
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_DESKTOP=sway
exec sway "\$@"
EOF

# Make it executable
chmod +x /usr/local/bin/sw
