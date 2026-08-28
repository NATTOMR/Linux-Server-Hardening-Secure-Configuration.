#!/usr/bin/env bash
# scripts/modules/07-lynis.sh
# Automated Security Scoring (Lynis)

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/backup.sh"
source "${SCRIPT_DIR}/../lib/validation.sh"

echo "=================================================="
echo "          AUTOMATED SECURITY SCORING"
echo "=================================================="

# Detect Lynis
if ! command_exists lynis; then
    log_warn "Lynis is not installed."
    if [[ "$IS_DRY_RUN" == "true" ]]; then
        log_dry_run "Would prompt to install Lynis."
    else
        if confirm "Would you like to install Lynis now?"; then
            apt-get update && apt-get install -y lynis
        else
            log_info "Skipping automated security scoring."
            exit 0
        fi
    fi
fi

if [[ "$IS_DRY_RUN" == "true" ]]; then
    log_dry_run "Would run 'lynis audit system --quick'"
    log_dry_run "Would parse Hardening Index score"
    log_dry_run "Would copy reports to audit/reports/"
    exit 0
fi

log_info "Running Lynis system audit. This may take a moment..."
# Run Lynis silently, writing to standard log files
lynis audit system --quick > /dev/null 2>&1 || true

# Extract Hardening Index
if [[ -f "/var/log/lynis.log" ]]; then
    # Usually logged as: Hardening index : 65
    SCORE=$(grep -i "Hardening index" /var/log/lynis.log | grep -o -E "[0-9]+" | tail -n 1 || echo "")
    if [[ -n "$SCORE" ]]; then
        log_success "LYNIS HARDENING INDEX: ${SCORE}/100"
    else
        log_warn "Could not extract Hardening Index from Lynis logs."
    fi
else
    log_error "Lynis log file not found. Audit may have failed."
    exit 1
fi

# Save report
REPORT_DIR="${SCRIPT_DIR}/../../audit/reports/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

if [[ -f "/var/log/lynis.log" ]]; then
    cp "/var/log/lynis.log" "${REPORT_DIR}/"
fi
if [[ -f "/var/log/lynis-report.dat" ]]; then
    cp "/var/log/lynis-report.dat" "${REPORT_DIR}/"
fi

log_info "Lynis audit reports saved to: ${REPORT_DIR}"
exit 0
