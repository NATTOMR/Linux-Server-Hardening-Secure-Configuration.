#!/usr/bin/env bash
# scripts/modules/03-firewall.sh
# Firewall Hardening Module (UFW)

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/backup.sh"
source "${SCRIPT_DIR}/../lib/validation.sh"

echo "=================================================="
echo "          FIREWALL SECURITY HARDENING"
echo "=================================================="

if ! command_exists ufw; then
    log_warn "UFW (Uncomplicated Firewall) is not installed."
    if [[ "$IS_DRY_RUN" == "true" ]]; then
        log_dry_run "Would prompt to install UFW."
        exit 0
    else
        if confirm "Would you like to install UFW now?"; then
            apt-get update && apt-get install -y ufw
        else
            log_info "Skipping firewall hardening."
            exit 0
        fi
    fi
fi

# Determine active SSH Port safely
SSH_PORT="22"
if command_exists sshd; then
    DETECTED_PORT=$(sshd -T 2>/dev/null | grep -i "^port " | awk '{print $2}' | head -n 1 || echo "")
    if [[ -n "$DETECTED_PORT" ]]; then
        SSH_PORT="$DETECTED_PORT"
    fi
fi
log_info "Detected active SSH port: $SSH_PORT"

# Backup UFW state
if [[ "$IS_DRY_RUN" == "false" ]]; then
    safe_exec backup_target "/etc/ufw"
    safe_exec backup_target "/etc/default/ufw"
fi

if [[ "$IS_DRY_RUN" == "true" ]]; then
    log_dry_run "Would set UFW default incoming to DENY"
    log_dry_run "Would set UFW default outgoing to ALLOW"
    log_dry_run "Would limit SSH on port $SSH_PORT"
    log_dry_run "Would enable IPv6 in /etc/default/ufw"
    log_dry_run "Would enable UFW"
    exit 0
fi

log_info "Configuring UFW default policies..."
ufw default deny incoming
ufw default allow outgoing
ufw default deny routed

log_info "Configuring UFW for SSH (Rate limiting)..."
# Check if rule exists using a safe approach
if ! ufw status | grep -q -w "$SSH_PORT/tcp.*LIMIT"; then
    ufw limit "$SSH_PORT"/tcp comment 'SSH Rate Limit'
else
    log_info "SSH limit rule for port $SSH_PORT is already configured."
fi

# Enable IPv6 support
if [[ -f "/etc/default/ufw" ]] && grep -q "^IPV6=no" "/etc/default/ufw"; then
    sed -i 's/^IPV6=no/IPV6=yes/' "/etc/default/ufw"
    log_info "Enabled IPv6 support in UFW."
fi

# Enable UFW
log_info "Enabling UFW..."
ufw --force enable

# Verify
if ufw status verbose | grep -q "Status: active"; then
    log_success "Firewall is active and hardened."
    # Verify SSH is allowed
    if ufw status | grep -q -w "$SSH_PORT/tcp"; then
         log_success "Confirmed SSH port $SSH_PORT is allowed."
    else
         log_warn "WARNING: Cannot verify SSH port in UFW status! Attempting to add explicitly."
         ufw allow "$SSH_PORT"/tcp
    fi
else
    log_error "Failed to activate UFW."
    exit 1
fi

exit 0
