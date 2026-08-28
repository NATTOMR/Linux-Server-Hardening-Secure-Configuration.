#!/usr/bin/env bash
# scripts/system-info.sh
# Safely detects and displays system information. Read-only.

set -Eeuo pipefail

# Find script directory to source libs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/common.sh"

echo "=================================================="
echo "          SYSTEM INFORMATION GATHERING"
echo "=================================================="

# Use common detection for OS
detect_os

# Gather Kernel Info
KERNEL_VERSION=$(uname -r)
ARCH=$(uname -m)
HOSTNAME=$(hostname)
UPTIME=$(uptime -p)
CURRENT_USER=$(id -un)
IS_ROOT="No"
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    IS_ROOT="Yes"
fi

# Gather IP Addresses
IP_ADDRS=$(ip -4 addr show scope global 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1 | tr '\n' ' ' || true)
DEFAULT_ROUTE=$(ip route show default 2>/dev/null | awk '{print $3}' || true)

echo ""
echo "[*] System Identity:"
echo "    OS: $DETECTED_OS_NAME ($DETECTED_OS_VERSION)"
echo "    Kernel: $KERNEL_VERSION"
echo "    Architecture: $ARCH"
echo "    Hostname: $HOSTNAME"
echo "    Uptime: $UPTIME"

echo ""
echo "[*] User & Privileges:"
echo "    Current User: $CURRENT_USER"
echo "    Running as Root: $IS_ROOT"

echo ""
echo "[*] Networking:"
echo "    IP Addresses: ${IP_ADDRS:-None}"
echo "    Default Gateway: ${DEFAULT_ROUTE:-None}"

echo ""
echo "[*] Listening TCP/UDP Ports:"
if command_exists ss; then
    ss -tuln | awk 'NR>1 {print "    " $1, $5}'
elif command_exists netstat; then
    netstat -tuln | awk 'NR>2 {print "    " $1, $4}'
else
    echo "    (Command 'ss' or 'netstat' not found)"
fi

echo ""
echo "[*] Active Services (Sample):"
if command_exists systemctl; then
    systemctl list-units --type=service --state=running 2>/dev/null | head -n 10 | awk '{print "    " $1}' || true
else
    echo "    (systemctl not found)"
fi

echo ""
echo "[*] Resource Usage:"
if command_exists df; then
    echo "    Disk Space (Root): $(df -h / | awk 'NR==2 {print $5 " used of " $2}')"
else
    echo "    (Command 'df' not found)"
fi

if command_exists free; then
    echo "    Memory: $(free -m | awk 'NR==2 {print $3 "MB used of " $2 "MB"}')"
else
    echo "    (Command 'free' not found)"
fi

echo ""
echo "=================================================="
echo "          SYSTEM GATHERING COMPLETE"
echo "=================================================="

log_info "System info gathered successfully."
exit 0
