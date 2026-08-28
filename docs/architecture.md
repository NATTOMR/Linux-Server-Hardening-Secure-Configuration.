# System Architecture

The Linux Server Security Hardening Framework uses a modular, bash-based architecture designed for safety and idempotency.

## Directory Structure
- `scripts/`: Core executable scripts.
- `scripts/lib/`: Reusable bash libraries (logging, validation, OS detection).
- `config/`: Template configuration files.
- `audit/`: Location for baseline reports and Lynis audits.
- `docs/`: Project documentation.
- `tests/`: Framework tests.

## Key Components
1. **`harden.sh`**: The main entry point. It orchestrates the execution of individual hardening modules after validating the environment.
2. **`system-info.sh`**: Read-only script for environment detection.
3. **`audit.sh`**: Gathers system state before and after hardening for scoring.
4. **`rollback.sh`**: Allows the system administrator to revert configuration changes using timestamped backups.

## Safety Principles
- **No Blind Execution**: All scripts verify OS and root privileges before executing.
- **Atomic Backups**: Configurations are backed up automatically.
- **Dry-Run Mode**: Allows administrators to preview changes without applying them.
