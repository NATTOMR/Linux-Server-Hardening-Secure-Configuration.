# Auditing and Baselines

The framework provides a built-in read-only auditing tool to gather a security baseline of your server.

## Generating a Read-Only Baseline

Before applying hardening, you can gather an inventory of current system settings without making changes:

```bash
sudo ./scripts/audit.sh
```

This reads:
- Current OS and Kernel
- Network interface status
- Current SSH configuration (if readable)
- Active UFW status

The results are timestamped and placed in `audit/baselines/`.

---

## Automated Security Scoring (Lynis)

In **Phase 4**, the framework incorporates **Lynis** to automatically evaluate the system's security posture and generate a quantifiable score.

### Running Lynis

The Lynis module (`07-lynis.sh`) is designed to run automatically at the very end of the hardening process when executing `--module all`.

You can also run it independently to get a standalone score:

```bash
sudo ./scripts/harden.sh --module lynis
```

### How It Works

1. **Detection & Installation:** The module checks if `lynis` is installed. If not, it safely prompts you to install it (or skips it in dry-run mode).
2. **Execution:** It runs a non-interactive audit (`lynis audit system --quick`), ensuring it doesn't block automated deployments.
3. **Scoring:** It parses the Lynis log to extract the official **Hardening Index** (e.g., `65/100`).
4. **Reporting:** The full audit reports are copied from `/var/log/` into the framework's local audit directory at `audit/reports/<timestamp>/`.

### Locating Lynis Reports

After execution, you can view the full diagnostic report and the Lynis data file in:
- `audit/reports/<timestamp>/lynis.log`
- `audit/reports/<timestamp>/lynis-report.dat`

These files contain hundreds of specific security tests and their outcomes, which can guide further manual hardening beyond the automated framework.
