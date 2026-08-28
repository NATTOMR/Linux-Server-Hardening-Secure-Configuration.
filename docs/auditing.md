# Auditing and Baselines

The framework provides a built-in read-only auditing tool to gather a security baseline of your server.

## Generating a Baseline
Run the audit script to capture current configuration states:
```bash
sudo ./scripts/audit.sh
```

Reports are automatically timestamped and saved in the `audit/baselines/` directory.

*(Note: Advanced auditing using Lynis will be integrated in future phases).*
