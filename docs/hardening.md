> [!NOTE]
> Phase 3 Modules (SSH, Firewall, Sysctl, Fail2Ban, Auditd) are active. Subsequent modules are planned for future phases.

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

## 3. Sysctl Kernel/Network Hardening (`04-sysctl.sh`)
This module fortifies the Linux kernel against network-based attacks.

### Applied Controls:
- **TCP SYN Cookies:** Enabled (`net.ipv4.tcp_syncookies = 1`) to mitigate SYN flood DoS attacks.
- **IP Forwarding:** Disabled to ensure the server cannot be used as a router.
- **ICMP Redirects:** Ignored to prevent routing manipulation.
- **Source Routing:** Disabled.
- **Martian Packets:** Logging enabled for spoofed/unroutable packets.

## 4. Fail2Ban Intrusion Prevention (`05-fail2ban.sh`)
This module dynamically bans IP addresses that show malicious signs, such as too many password failures.

### Applied Controls:
- **SSH Jail:** Activates the `sshd` jail.
- **Ban Policy:** Bans IPs for 1 hour after 5 failed login attempts within 10 minutes.

## 5. Auditd System Auditing (`06-auditd.sh`)
This module deploys kernel-level auditing to track who modified what.

### Applied Controls:
- **Identity Files:** Monitors `/etc/passwd`, `/etc/shadow`, and `/etc/group` for any write/attribute changes.
- **Privilege Escalation:** Monitors `/etc/sudoers` and `/etc/sudoers.d/`.
- **Configuration Security:** Monitors SSH (`/etc/ssh/sshd_config`) and PAM (`/etc/pam.d/`) configs for unauthorized modifications.
