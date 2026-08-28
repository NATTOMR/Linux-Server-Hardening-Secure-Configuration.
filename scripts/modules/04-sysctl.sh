#!/usr/bin/env bash
# scripts/modules/04-sysctl.sh
# Kernel and Network Hardening Module

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/backup.sh"
source "${SCRIPT_DIR}/../lib/validation.sh"

echo "=================================================="
echo "         SYSCTL KERNEL & NETWORK HARDENING"
echo "=================================================="

if ! command_exists sysctl; then
    log_warn "sysctl command not found. Skipping kernel hardening."
    exit 0
fi

SYSCTL_CONF="/etc/sysctl.d/99-hardening.conf"

# Backup sysctl directories
if [[ "$IS_DRY_RUN" == "false" ]]; then
    safe_exec backup_target "/etc/sysctl.conf"
    safe_exec backup_target "/etc/sysctl.d"
fi

if [[ "$IS_DRY_RUN" == "true" ]]; then
    log_dry_run "Would create hardening configuration at $SYSCTL_CONF"
    log_dry_run "Would enable TCP SYN cookies (net.ipv4.tcp_syncookies = 1)"
    log_dry_run "Would disable IP forwarding (net.ipv4.ip_forward = 0, net.ipv6.conf.all.forwarding = 0)"
    log_dry_run "Would ignore ICMP redirects (net.ipv4.conf.all.accept_redirects = 0)"
    log_dry_run "Would ignore ICMP broadcasts (net.ipv4.icmp_echo_ignore_broadcasts = 1)"
    log_dry_run "Would log martian packets (net.ipv4.conf.all.log_martians = 1)"
    log_dry_run "Would apply configuration using 'sysctl -p'"
    exit 0
fi

log_info "Writing sysctl hardening rules to $SYSCTL_CONF..."

cat <<EOF > "$SYSCTL_CONF"
# TCP SYN cookie protection
net.ipv4.tcp_syncookies = 1

# Disable IP forwarding (Not a router)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Ignore ICMP echo requests to broadcast addresses
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Log spoofed, source routed, and redirect packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
EOF

log_info "Applying sysctl configurations..."
if sysctl -p "$SYSCTL_CONF"; then
    log_success "Kernel and network hardening applied successfully."
else
    log_error "Failed to apply sysctl configurations. The system may not support some keys."
    # We do not strictly fail because some container environments (LXC/Docker) restrict sysctl,
    # but we should log it clearly.
    log_warn "If this is a container/VM, some sysctl keys might be restricted."
fi

exit 0
