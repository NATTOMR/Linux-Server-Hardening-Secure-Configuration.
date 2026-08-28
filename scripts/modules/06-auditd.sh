#!/usr/bin/env bash
# scripts/modules/06-auditd.sh
# System Auditing Module (Auditd)

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/backup.sh"
source "${SCRIPT_DIR}/../lib/validation.sh"

echo "=================================================="
echo "               SYSTEM AUDITING (AUDITD)"
echo "=================================================="

if ! command_exists auditd; then
    log_warn "Auditd is not installed."
    if [[ "$IS_DRY_RUN" == "true" ]]; then
        log_dry_run "Would prompt to install Auditd."
    else
        if confirm "Would you like to install Auditd now?"; then
            apt-get update && apt-get install -y auditd audispd-plugins
        else
            log_info "Skipping Auditd hardening."
            exit 0
        fi
    fi
fi

if [[ "$IS_DRY_RUN" == "false" ]]; then
    safe_exec backup_target "/etc/audit"
fi

AUDIT_RULES="/etc/audit/rules.d/99-hardening.rules"

if [[ "$IS_DRY_RUN" == "true" ]]; then
    log_dry_run "Would create auditd hardening rules at $AUDIT_RULES"
    log_dry_run "Would monitor /etc/passwd, /etc/shadow, /etc/sudoers, /etc/ssh"
    log_dry_run "Would reload Auditd rules"
    exit 0
fi

log_info "Writing Auditd hardening rules to $AUDIT_RULES..."

cat <<EOF > "$AUDIT_RULES"
# Monitor critical identity and authentication files
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k privilege_escalation
-w /etc/sudoers.d/ -p wa -k privilege_escalation

# Monitor SSH configuration changes
-w /etc/ssh/sshd_config -p wa -k sshd_config

# Monitor PAM configuration changes
-w /etc/pam.d/ -p wa -k pam_config
EOF

log_info "Reloading Auditd rules..."
if command_exists augenrules; then
    augenrules --load
else
    log_warn "augenrules not found. Trying to restart service."
    if command_exists systemctl; then
        systemctl restart auditd
    else
        service auditd restart
    fi
fi

log_success "Auditd rules applied and active."

exit 0
