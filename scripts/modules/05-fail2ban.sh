#!/usr/bin/env bash
# scripts/modules/05-fail2ban.sh
# Fail2Ban Intrusion Prevention Module

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/backup.sh"
source "${SCRIPT_DIR}/../lib/validation.sh"

echo "=================================================="
echo "          FAIL2BAN INTRUSION PREVENTION"
echo "=================================================="

if ! command_exists fail2ban-client; then
    log_warn "Fail2Ban is not installed."
    if [[ "$IS_DRY_RUN" == "true" ]]; then
        log_dry_run "Would prompt to install Fail2Ban."
    else
        if confirm "Would you like to install Fail2Ban now?"; then
            apt-get update && apt-get install -y fail2ban
        else
            log_info "Skipping Fail2Ban hardening."
            exit 0
        fi
    fi
fi

if [[ "$IS_DRY_RUN" == "false" ]]; then
    safe_exec backup_target "/etc/fail2ban"
fi

FAIL2BAN_LOCAL="/etc/fail2ban/jail.local"

if [[ "$IS_DRY_RUN" == "true" ]]; then
    log_dry_run "Would create SSH jail configuration at $FAIL2BAN_LOCAL"
    log_dry_run "Would restart and enable Fail2Ban service"
    exit 0
fi

log_info "Configuring Fail2Ban local jail for SSH..."

# Write jail.local safely
cat <<EOF > "$FAIL2BAN_LOCAL"
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF

log_info "Restarting Fail2Ban service..."
if command_exists systemctl; then
    systemctl restart fail2ban
    systemctl enable fail2ban
else
    service fail2ban restart
fi

if fail2ban-client status sshd >/dev/null 2>&1; then
    log_success "Fail2Ban is active and monitoring SSH."
else
    log_error "Fail2Ban failed to start or sshd jail is inactive."
    exit 1
fi

exit 0
