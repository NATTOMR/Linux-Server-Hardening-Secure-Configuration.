# System Rollback

> [!CAUTION]
> Rollback functionality is currently a placeholder (Phase 1). No destructive restoration logic is implemented yet.

## Overview
The framework automatically takes timestamped backups of configuration files (e.g., `/etc/ssh/sshd_config`, `/etc/default/ufw`) before applying any modifications. 

## Using Rollback
To view available backups and simulate a rollback:
```bash
sudo ./scripts/rollback.sh
```

You will be presented with a list of available backup sessions. You must explicitly confirm before any files are restored.
