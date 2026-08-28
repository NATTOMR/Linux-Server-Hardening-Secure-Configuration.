# Troubleshooting

## Common Issues

### Script Refuses to Run
**Error:** `This script must be run as root.`
**Solution:** Ensure you are executing the script using `sudo`.

### Unsupported OS
**Error:** `Unsupported OS: ...`
**Solution:** The framework strictly limits execution to tested operating systems (Ubuntu, Debian, Kali). Attempting to run it on RHEL/CentOS/Arch will safely abort to prevent system damage.

### Missing Permissions
**Error:** `Permission denied` when running `./scripts/harden.sh`
**Solution:** Make the scripts executable:
```bash
chmod +x scripts/*.sh scripts/lib/*.sh
```
