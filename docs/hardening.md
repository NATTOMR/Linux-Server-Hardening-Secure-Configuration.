# Hardening Modules

> [!NOTE]
> Phase 2 Modules (SSH & Firewall) are active. Subsequent modules are planned for future phases.

## 1. SSH Security (`02-ssh.sh`)
This module safely applies baseline security controls to the OpenSSH server (`sshd_config`).

### Applied Controls:
- `PermitRootLogin no`: Prevents root from logging in directly over SSH.
- `PubkeyAuthentication yes`: Ensures key-based authentication is supported.
- `PermitEmptyPasswords no`: Denies login for accounts without passwords.
- `X11Forwarding no`: Disables X11 forwarding to reduce attack surface.
- `PasswordAuthentication no`: Only enforced if an `authorized_keys` file is detected for the executing administrator.

### Safety Mechanisms:
- **Backup:** Creates a tar.gz backup of `/etc/ssh` before modification.
- **Validation:** Validates the new config using `sshd -t`. The service is ONLY restarted if validation succeeds.
- **Rollback:** Restores the backup automatically if validation fails.

## 2. Firewall Security (`03-firewall.sh`)
This module configures `ufw` to enforce a secure baseline while ensuring the administrator is not locked out.

### Applied Controls:
- **Default Incoming:** `deny`
- **Default Outgoing:** `allow`
- **Default Routed:** `deny`
- **IPv6:** Enabled (if supported).
- **SSH Access:** Explicitly allows and rate limits (`ufw limit`) the active SSH port.

### Safety Mechanisms:
- **Port Detection:** The script uses `sshd -T` to discover the exact port currently configured for SSH, guaranteeing it isn't blocked.
- **Verification:** Runs `ufw status` to verify the port was successfully allowed after enablement.
