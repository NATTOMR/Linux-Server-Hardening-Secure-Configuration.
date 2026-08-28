# Development Roadmap & Architecture Strategy

## 1. Target Project Vision
**"Linux Server Security Hardening & Continuous Security Audit Framework"**

The project will evolve from a manual documentation guide into an enterprise-grade automated hardening framework. It will provide:
- Automated, modular Linux hardening scripts.
- Continuous security auditing with automated before/after scoring.
- Failsafe execution with configuration backups and rollback capabilities.
- Comprehensive logging and compliance reporting.

## 2. Proposed Architecture
To support automation, safety, and modularity, the following repository structure is proposed:

```text
linux-server-hardening/
├── README.md                 # Project overview and quickstart
├── LICENSE                   # Open-source license
├── requirements.txt          # Python dependencies (if reporting tools are used)
│
├── scripts/
│   ├── harden.sh             # Main execution script
│   ├── audit.sh              # Wrapper for Lynis and custom audits
│   ├── rollback.sh           # Restores system from backups
│   ├── system-info.sh        # OS and prerequisite detection
│   └── modules/              # Modular hardening scripts
│       ├── 01-prep.sh
│       ├── 02-ssh.sh
│       ├── 03-firewall.sh
│       ├── 04-sysctl.sh
│       ├── 05-users.sh
│       └── 06-services.sh
│
├── config/                   # Template configurations
│   ├── ssh/sshd_config.tmpl
│   ├── sysctl/99-security.conf
│   └── fail2ban/jail.local
│
├── audit/
│   ├── reports/              # Generated HTML/MD reports
│   └── baselines/            # Pre-hardening system states
│
├── docs/                     # Professional documentation
│   ├── architecture.md
│   ├── installation.md
│   ├── hardening.md
│   ├── auditing.md
│   ├── rollback.md
│   └── troubleshooting.md
│
└── .github/
    └── workflows/            # CI/CD for shell linting (ShellCheck)
```

## 3. Development Roadmap

### Phase 1: Core Automation & Safety Foundation
- Initialize repository structure.
- Develop `system-info.sh` to strictly enforce OS detection (Ubuntu/Debian/Kali) and Root privileges.
- Develop the core backup mechanism to snapshot `/etc/` configurations before any changes.
- Implement a dry-run flag (`-d`) in `harden.sh`.

### Phase 2: Modular Hardening Implementation
- **SSH Module:** Automate key-auth enforcement, disable root, and validate with `sshd -t` before restart.
- **Firewall Module:** Automate UFW configuration, including IPv6 rules and rate-limiting.
- **Sysctl Module:** Implement a robust `99-security.conf` for network hardening (SYN cookies, disable ICMP redirects, IP spoofing protection).
- **Users Module:** Automate PAM configurations for password policies and lockout.

### Phase 3: Advanced Security & Intrusion Prevention
- Automate `fail2ban` installation and SSH jail configuration.
- Automate `auditd` installation and deploy standard security rules.
- Secure `/dev/shm` and `/tmp` in `/etc/fstab`.

### Phase 4: Auditing & Reporting
- Develop `audit.sh` to automate Lynis installation, execution, and parsing of the hardening index.
- Create automated "Before vs. After" comparison reports.

### Phase 5: Testing & CI/CD
- Integrate `ShellCheck` via GitHub actions to ensure script quality.
- Perform isolated VM testing (Snapshot -> Audit -> Harden -> Audit -> Compare).

## 4. Safety Requirements & Strategy
Any script modifying the system **MUST** adhere to these principles:
1. **Root Verification:** Exit immediately if not run as root.
2. **OS Validation:** Exit safely if run on an unsupported OS (e.g., RedHat/CentOS).
3. **Atomic Backups:** Create a timestamped tarball of configuration files (e.g., `/etc/ssh`, `/etc/default/ufw`) before modification.
4. **Validation First:** Never restart a service without validating the config (e.g., `sshd -t`).
5. **Idempotency:** Running the script twice should not break the system or append duplicate lines to config files.
6. **Rollback:** `rollback.sh` must be able to restore the system to its pre-hardened state using the timestamped backups.

## 5. Testing Strategy
Testing will be conducted in an isolated hypervisor environment (e.g., VirtualBox, Proxmox, or AWS EC2).
1. **Deploy:** Clean Ubuntu Server VM.
2. **Snapshot:** Take a hypervisor-level snapshot.
3. **Pre-Audit:** Run `audit.sh` to establish a baseline score.
4. **Execution:** Run `harden.sh`.
5. **Validation:** Open a *new* terminal and attempt SSH access (Ensures we aren't locked out). Verify UFW status.
6. **Post-Audit:** Run `audit.sh` to confirm the score increased.
7. **Rollback Test:** Run `rollback.sh` and verify the pre-audit state is restored.
8. **Restore:** Revert to the hypervisor snapshot for the next iteration.

## 6. Documentation Strategy
The `/docs` folder will contain highly detailed markdown files:
- **architecture.md:** Explains how the bash modules interact.
- **hardening.md:** Detailed breakdown of exactly what each module changes (for transparency).
- **rollback.md:** Emergency instructions if the system breaks.
- **README.md:** A clean, professional landing page with warnings, badges, and quick-start commands.
