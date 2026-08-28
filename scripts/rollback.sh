#!/usr/bin/env bash
# scripts/rollback.sh
# Framework for listing backups and rolling back configurations

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/validation.sh"

BACKUP_ROOT="${SCRIPT_DIR}/../backups"

check_root

echo "=================================================="
echo "            SYSTEM ROLLBACK MANAGER"
echo "=================================================="

if [[ ! -d "$BACKUP_ROOT" ]] || [[ -z "$(ls -A "$BACKUP_ROOT" 2>/dev/null)" ]]; then
    log_warn "No backup sessions found in $BACKUP_ROOT."
    exit 0
fi

echo "Available Backup Sessions:"
echo "--------------------------------------------------"
count=1
declare -a SESSION_DIRS
for session in "$BACKUP_ROOT"/session_*; do
    if [[ -d "$session" ]]; then
        SESSION_DIRS[$count]="$session"
        timestamp=$(basename "$session" | sed 's/session_//')
        
        # Determine files in backup
        files="None"
        if [[ -f "$session/targets.txt" ]]; then
            files=$(cat "$session/targets.txt" | tr '\n' ', ' | sed 's/, $//')
        fi
        
        echo "[$count] $timestamp - Targets: $files"
        ((count++))
    fi
done

echo "--------------------------------------------------"
if [[ ${#SESSION_DIRS[@]} -eq 0 ]]; then
    log_warn "No valid backup sessions found."
    exit 0
fi

read -r -p "Select session to inspect (1-$((count-1))) or 'q' to quit: " selection

if [[ "$selection" == "q" ]]; then
    exit 0
fi

if [[ -n "${SESSION_DIRS[$selection]:-}" ]]; then
    selected_session="${SESSION_DIRS[$selection]}"
    log_info "Selected session: $(basename "$selected_session")"
    
    if confirm "Would you like to restore this backup session?"; then
        log_warn "Phase 1 limits: Destructive rollback logic is not yet implemented."
        log_info "Restoration cancelled safely."
    else
        log_info "Rollback aborted by user."
    fi
else
    log_error "Invalid selection."
    exit 1
fi

exit 0
