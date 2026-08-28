#!/usr/bin/env bash
# scripts/harden.sh
# Main framework for Linux Server Hardening

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/backup.sh"
source "${SCRIPT_DIR}/lib/validation.sh"

usage() {
    echo "Usage: sudo $0 [OPTIONS]"
    echo "Options:"
    echo "  -d, --dry-run    Simulate hardening without making changes"
    echo "  -i, --info       Display system information and exit"
    echo "  -h, --help       Show this help message"
    exit 0
}

MODE="harden"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            enable_dry_run
            shift
            ;;
        -i|--info)
            MODE="info"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown parameter passed: $1"
            usage
            ;;
    esac
done

# Execute based on mode
if [[ "$MODE" == "info" ]]; then
    "${SCRIPT_DIR}/system-info.sh"
    exit 0
fi

echo "=================================================="
echo "       LINUX SERVER HARDENING FRAMEWORK"
echo "=================================================="

log_info "Starting hardening framework initialization..."

# 1. Validate Environment & 3. Check Privileges
check_root

# 2. Detect OS
detect_os

# 4. Initialize Backup Framework (only if not dry-run, though we could just mock it)
if [[ "$IS_DRY_RUN" == "true" ]]; then
    log_dry_run "Would initialize backup session for configuration files."
else
    init_backup_session
    # Define files we would backup, but don't backup yet in Phase 1
    log_info "Backup framework initialized. Ready for module execution."
fi

echo ""
log_warn "Phase 1 limits: Hardening modules are not yet enabled."
log_info "Framework initialized safely. Exiting."

exit 0
