#!/usr/bin/env bash
# scripts/lib/common.sh
# Reusable functions for OS detection, root checking, etc.

set -Eeuo pipefail

# Load logging if not loaded
if ! type log_info >/dev/null 2>&1; then
    source "${BASH_SOURCE%/*}/logging.sh"
fi

# Function to check for root privileges
check_root() {
    if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
        log_error "This script must be run as root."
        echo "Please execute with sudo or as the root user."
        exit 1
    fi
}

# Function to detect supported OS
detect_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "/etc/os-release not found. Unsupported Linux distribution."
        exit 1
    fi
    
    # Source the OS release file
    . /etc/os-release
    
    local os_id="${ID:-unknown}"
    local os_version="${VERSION_ID:-unknown}"
    local os_name="${PRETTY_NAME:-unknown}"
    
    log_info "Detected OS: $os_name"
    
    # Check if OS is supported
    case "$os_id" in
        ubuntu|debian|kali)
            log_success "OS '$os_id' is supported."
            export DETECTED_OS_ID="$os_id"
            export DETECTED_OS_VERSION="$os_version"
            export DETECTED_OS_NAME="$os_name"
            ;;
        *)
            log_error "Unsupported OS: $os_id. Supported OS: ubuntu, debian, kali."
            exit 1
            ;;
    esac
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# General error handler trap
handle_error() {
    local line_no=$1
    local script_name=$2
    log_error "Error occurred in $script_name on line $line_no."
}

trap 'handle_error ${LINENO} "$BASH_SOURCE"' ERR
