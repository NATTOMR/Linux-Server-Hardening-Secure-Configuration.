#!/usr/bin/env bash
# scripts/lib/logging.sh
# Centralized logging functions

set -Eeuo pipefail

# Ensure logs directory exists
LOG_DIR="${BASH_SOURCE%/*}/../../logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/hardening_$(date +%Y%m%d).log"

# Function to write to log and optionally to console
log() {
    local severity="$1"
    local message="$2"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local formatted_msg="[$timestamp] [$severity] $message"
    
    # Write to log file
    echo "$formatted_msg" >> "$LOG_FILE"
    
    # Output to console with colors
    case "$severity" in
        INFO)
            echo -e "\e[34m$formatted_msg\e[0m"
            ;;
        WARN)
            echo -e "\e[33m$formatted_msg\e[0m"
            ;;
        ERROR)
            echo -e "\e[31m$formatted_msg\e[0m" >&2
            ;;
        SUCCESS)
            echo -e "\e[32m$formatted_msg\e[0m"
            ;;
        DRY-RUN)
            echo -e "\e[36m[$timestamp] [DRY-RUN] $message\e[0m"
            ;;
        *)
            echo "$formatted_msg"
            ;;
    esac
}

log_info() { log "INFO" "$1"; }
log_warn() { log "WARN" "$1"; }
log_error() { log "ERROR" "$1"; }
log_success() { log "SUCCESS" "$1"; }
log_dry_run() { log "DRY-RUN" "$1"; }
