#!/usr/bin/env bash
# scripts/modules/02-ssh.sh
# SSH Hardening Module

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/backup.sh"
source "${SCRIPT_DIR}/../lib/validation.sh"

echo "=================================================="
echo "          SSH SECURITY HARDENING"
echo "=================================================="

# Detect SSH service
SSH_SERVICE=""
if command_exists systemctl; then
    if systemctl list-unit-files ssh.service &>/dev/null || systemctl is-active ssh &>/dev/null; then
        SSH_SERVICE="ssh"
    elif systemctl list-unit-files sshd.service &>/dev/null || systemctl is-active sshd &>/dev/null; then
        SSH_SERVICE="sshd"
    fi
fi

if [[ -z "$SSH_SERVICE" ]]; then
    # Fallback if no systemctl
    if command_exists service; then
        if service ssh status &>/dev/null; then SSH_SERVICE="ssh";
        elif service sshd status &>/dev/null; then SSH_SERVICE="sshd"; fi
    fi
fi

if [[ -z "$SSH_SERVICE" ]]; then
    log_warn "OpenSSH server not detected (ssh/sshd service not found). Skipping SSH hardening."
    exit 0
fi

SSHD_CONFIG="/etc/ssh/sshd_config"
if [[ ! -f "$SSHD_CONFIG" ]]; then
    log_warn "SSH config $SSHD_CONFIG not found. Skipping."
    exit 0
fi

# Backup
safe_exec backup_target "/etc/ssh"

# Prepare configuration changes safely (idempotent updates)
update_sshd_config() {
    local key="$1"
    local value="$2"
    
    # Check if already set correctly
    if grep -q -E "^\s*${key}\s+${value}\s*$" "$SSHD_CONFIG"; then
        log_info "$key is already set to $value"
        return 0
    fi
    
    if [[ "$IS_DRY_RUN" == "true" ]]; then
        log_dry_run "Would set '$key $value' in $SSHD_CONFIG"
    else
        log_info "Configuring: $key $value"
        # If the key exists, uncomment and replace
        if grep -q -E -i "^\s*#?\s*${key}\s+" "$SSHD_CONFIG"; then
            sed -i -E "s/^\s*#?\s*${key}\s+.*/${key} ${value}/i" "$SSHD_CONFIG"
        else
            echo "${key} ${value}" >> "$SSHD_CONFIG"
        fi
    fi
}

log_info "Applying SSH baseline controls..."
update_sshd_config "PermitRootLogin" "no"
update_sshd_config "PubkeyAuthentication" "yes"
update_sshd_config "PermitEmptyPasswords" "no"
update_sshd_config "X11Forwarding" "no"

# Check for authorized_keys to disable PasswordAuthentication
DISABLE_PASS="false"
if [[ "$IS_DRY_RUN" == "true" ]]; then
    log_dry_run "Would check for authorized_keys to determine if PasswordAuthentication should be disabled."
    DISABLE_PASS="true" # Simulate finding keys for logging purposes
else
    # Check current user if running with sudo
    ADMIN_USER="${SUDO_USER:-root}"
    if [[ "$ADMIN_USER" != "root" ]]; then
        ADMIN_HOME=$(getent passwd "$ADMIN_USER" | cut -d: -f6 || echo "")
        if [[ -n "$ADMIN_HOME" && -f "$ADMIN_HOME/.ssh/authorized_keys" ]]; then
            log_success "Found authorized_keys for $ADMIN_USER"
            DISABLE_PASS="true"
        fi
    fi
    
    # Fallback to check root if still false
    if [[ "$DISABLE_PASS" == "false" && -f "/root/.ssh/authorized_keys" ]]; then
        log_success "Found authorized_keys for root"
        DISABLE_PASS="true"
    fi
fi

if [[ "$DISABLE_PASS" == "true" ]]; then
    update_sshd_config "PasswordAuthentication" "no"
else
    log_warn "No authorized_keys found for admin user! Leaving PasswordAuthentication ENABLED to prevent lockout."
fi

# Validation and Restart
if [[ "$IS_DRY_RUN" == "true" ]]; then
    log_dry_run "Would validate configuration with 'sshd -t'"
    log_dry_run "Would reload/restart $SSH_SERVICE service"
else
    log_info "Validating new SSH configuration..."
    if sshd -t; then
        log_success "SSH configuration validation passed."
        log_info "Reloading $SSH_SERVICE..."
        if command_exists systemctl; then
            systemctl reload "$SSH_SERVICE" || systemctl restart "$SSH_SERVICE"
        else
            service "$SSH_SERVICE" reload || service "$SSH_SERVICE" restart
        fi
        log_success "SSH hardened successfully."
    else
        log_error "SSH configuration validation FAILED."
        log_info "Attempting rollback of /etc/ssh from latest backup..."
        LATEST_BACKUP="${BACKUP_SESSION_DIR}/_etc_ssh.tar.gz"
        if [[ -f "$LATEST_BACKUP" ]]; then
            tar -xzpf "$LATEST_BACKUP" -C /
            log_success "Rollback successful. System restored."
        else
            log_error "Backup not found for rollback! Manual intervention required."
        fi
        exit 1
    fi
fi

exit 0
