#!/usr/bin/env bash
# scripts/lib/backup.sh
# Infrastructure for taking timestamped configuration backups

set -Eeuo pipefail

# Load logging if not loaded
if ! type log_info >/dev/null 2>&1; then
    source "${BASH_SOURCE%/*}/logging.sh"
fi

BACKUP_ROOT="${BASH_SOURCE%/*}/../../backups"

# Function to initialize backup session
init_backup_session() {
    # Only initialize if running as root
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        local session_id
        session_id=$(date +%Y%m%d_%H%M%S)
        export BACKUP_SESSION_DIR="${BACKUP_ROOT}/session_${session_id}"
        mkdir -p "$BACKUP_SESSION_DIR"
        log_info "Initialized backup session: ${BACKUP_SESSION_DIR}"
    else
        log_warn "Not running as root. Backup session will not be initialized."
    fi
}

# Function to backup a file or directory safely
backup_target() {
    local target="$1"
    
    if [[ -z "${BACKUP_SESSION_DIR:-}" ]]; then
        log_error "Backup session not initialized. Call init_backup_session first."
        return 1
    fi
    
    if [[ ! -e "$target" ]]; then
        log_warn "Backup target $target does not exist. Skipping."
        return 0
    fi
    
    local safe_name
    # Replace slashes with underscores for flat backup structure
    safe_name=$(echo "$target" | sed 's|/|_|g')
    local dest="${BACKUP_SESSION_DIR}/${safe_name}.tar.gz"
    
    log_info "Creating backup of $target -> $dest"
    
    # Use tar to preserve permissions and ownership
    if tar -czpf "$dest" -C "/" "${target#/}"; then
        log_success "Backup created successfully."
        # Store metadata
        echo "$target" >> "${BACKUP_SESSION_DIR}/targets.txt"
    else
        log_error "Failed to create backup of $target"
        return 1
    fi
}
