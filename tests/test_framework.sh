#!/usr/bin/env bash
# tests/test_framework.sh
# Basic test suite for the hardening framework

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
H_SCRIPT="${SCRIPT_DIR}/../scripts/harden.sh"
SYS_SCRIPT="${SCRIPT_DIR}/../scripts/system-info.sh"

echo "Running framework tests..."

# Test 1: Ensure scripts exist
if [[ ! -f "$H_SCRIPT" ]]; then
    echo "FAIL: harden.sh not found."
    exit 1
fi
echo "PASS: Scripts exist."

# Test 2: Test system-info script
if ! "$SYS_SCRIPT" >/dev/null; then
    echo "FAIL: system-info.sh failed to execute."
    exit 1
fi
echo "PASS: system-info.sh executed successfully."

# Test 3: Test module parameter requirements
if "$H_SCRIPT" >/dev/null 2>&1; then
    echo "FAIL: harden.sh should fail when run without --module."
    exit 1
fi
echo "PASS: Module flag requirement enforced."

# Test 4: Dry-run mode for all modules
echo "Running dry-run simulation for all modules..."
# We wrap in subshell or handle error if we are not root
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Note: Dry-run test requires root to fully pass execution logic (root check enforced)."
else
    if "$H_SCRIPT" --module all --dry-run | grep -q "Would reload/restart"; then
        echo "PASS: Dry-run mode completed successfully."
    else
        echo "FAIL: Dry-run output not as expected."
        exit 1
    fi
fi

echo "All basic framework tests passed."
exit 0
