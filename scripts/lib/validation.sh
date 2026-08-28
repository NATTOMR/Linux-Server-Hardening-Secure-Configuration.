#!/usr/bin/env bash
# scripts/lib/validation.sh
# Functions for dry-run modes, confirmation prompts, etc.

set -Eeuo pipefail

# Load logging if not loaded
if ! type log_info >/dev/null 2>&1; then
    source "${BASH_SOURCE%/*}/logging.sh"
fi

export IS_DRY_RUN=false

# Enable dry run
enable_dry_run() {
    IS_DRY_RUN=true
    log_info "Dry-run mode enabled. No system changes will be made."
}

# Execute a command safely respecting dry-run
safe_exec() {
    local cmd=("$@")
    if [[ "$IS_DRY_RUN" == "true" ]]; then
        log_dry_run "Would execute: ${cmd[*]}"
    else
        log_info "Executing: ${cmd[*]}"
        "${cmd[@]}"
    fi
}

# Prompt user for confirmation
confirm() {
    local prompt="${1:-Are you sure you want to proceed?}"
    local response
    
    # If in dry-run, we can assume 'yes' to simulate flow without changes
    if [[ "$IS_DRY_RUN" == "true" ]]; then
        log_dry_run "Would prompt: $prompt (auto-accepting for dry-run)"
        return 0
    fi
    
    read -r -p "$prompt [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}
