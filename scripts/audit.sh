#!/usr/bin/env bash
# scripts/audit.sh
# Performs read-only security checks and baseline gathering.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/common.sh"

BASELINE_DIR="${SCRIPT_DIR}/../audit/baselines"
mkdir -p "$BASELINE_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${BASELINE_DIR}/baseline_${TIMESTAMP}.txt"

echo "=================================================="
echo "          SYSTEM SECURITY AUDIT (READ-ONLY)"
echo "=================================================="
log_info "Starting baseline audit. Saving to $REPORT_FILE"

{
    echo "=================================================="
    echo " SECURITY BASELINE REPORT - $TIMESTAMP"
    echo "=================================================="
    
    echo -e "\n[+] OS Information"
    if [[ -f /etc/os-release ]]; then
        cat /etc/os-release | grep -E "^PRETTY_NAME=|^VERSION="
    fi
    uname -a
    
    echo -e "\n[+] Local Users with bash shell"
    grep -E 'bash$' /etc/passwd | cut -d: -f1,3
    
    echo -e "\n[+] Sudo Group Members"
    getent group sudo || echo "No sudo group found."
    
    echo -e "\n[+] Listening Ports"
    if command_exists ss; then
        ss -tuln
    fi
    
    echo -e "\n[+] SSH Status"
    systemctl is-active ssh || systemctl is-active sshd || echo "SSH service not found."
    
    echo -e "\n[+] Firewall Status"
    if command_exists ufw; then
        ufw status verbose 2>/dev/null || echo "UFW requires root to show full status."
    else
        echo "UFW not installed."
    fi
    
    echo -e "\n[+] Important Security Packages"
    for pkg in fail2ban auditd lynis apparmor selinux-basics; do
        if dpkg -l | grep -q "^ii  $pkg"; then
            echo "Installed: $pkg"
        else
            echo "Not installed: $pkg"
        fi
    done
    
} > "$REPORT_FILE"

log_success "Audit completed. Report saved to $(basename "$REPORT_FILE")"
exit 0
