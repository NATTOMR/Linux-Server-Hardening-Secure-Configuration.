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
    echo "  -d, --dry-run      Simulate hardening without making changes"
    echo "  -i, --info         Display system information and exit"
    echo "  -m, --module <mod> Run specific module (ssh, firewall, all)"
    echo "  -h, --help         Show this help message"
    exit 0
}

MODE="harden"
TARGET_MODULE="none"

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
        -m|--module)
            TARGET_MODULE="$2"
            shift 2
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

if [[ "$MODE" == "info" ]]; then
    "${SCRIPT_DIR}/system-info.sh"
    exit 0
fi

echo "=================================================="
echo "       LINUX SERVER HARDENING FRAMEWORK"
echo "=================================================="

if [[ "$TARGET_MODULE" == "none" ]]; then
    log_error "You must specify a module to run. Use '--module all' or '--help'."
    exit 1
fi

log_info "Starting hardening framework initialization..."
check_root
detect_os

if [[ "$IS_DRY_RUN" == "true" ]]; then
    log_dry_run "Would initialize backup session for configuration files."
else
    init_backup_session
    log_info "Backup framework initialized. Ready for module execution."
fi

echo ""

# Module Orchestration
run_module() {
    local mod="$1"
    local script="${SCRIPT_DIR}/modules/${mod}.sh"
    
    if [[ -f "$script" ]]; then
        log_info "Executing module: $mod"
        # Export BACKUP_SESSION_DIR and IS_DRY_RUN are already in environment
        bash "$script"
    else
        log_warn "Module '$mod' not found at $script."
    fi
}

case "$TARGET_MODULE" in
    ssh)
        run_module "02-ssh"
        ;;
    firewall)
        run_module "03-firewall"
        ;;
    all)
        run_module "02-ssh"
        run_module "03-firewall"
        ;;
    *)
        log_error "Unknown module: $TARGET_MODULE. Available: ssh, firewall, all"
        exit 1
        ;;
esac

echo ""
log_success "Hardening framework execution complete."
exit 0
