# GRUB Auto-Recovery System v2.0

> **A professional automation utility for GRUB bootloader diagnostics and repair**

The **GRUB Auto-Recovery System** is a shell-based tool designed to maintain boot integrity across Linux distributions. It automates detection and resolution of common GRUB bootloader failures, offering a standardized recovery framework for both UEFI and Legacy BIOS systems.

---

## Key Capabilities

- ✅ **Automated Diagnostics**: Detects misconfigurations, missing entries, or corrupted installations in GRUB.
- 🔧 **Proactive Maintenance**: Can run during boot to verify system health before issues escalate.
- 🛡️ **Integrity Protection**: Automatically creates backups before making any system modifications.
- 🐧 **Cross-Distribution Support**: Compatible with Debian, Ubuntu, Fedora, Arch Linux, and openSUSE.
- 💻 **Dual-Boot Resilience**: Recovers Linux boot entries often overwritten by Windows updates.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Operation Modes](#operation-modes)
4. [Log Interpretation](#log-interpretation)
5. [Emergency Recovery](#emergency-recovery)
6. [Configuration](#configuration)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before using this tool, ensure the following:

- **Root Privileges**: `sudo` or root access is required for all operations.
- **System Architecture**: x86_64 (Intel/AMD) platforms only.
- **Firmware Support**: Works on both UEFI and Legacy BIOS systems.
- **Required Tools**: Standard GNU utilities must be available:
  - `grep`, `awk`
  - `mount`, `umount`
  - `grub-install`, `grub-mkconfig`, `grub-probe`
  - `lsblk`, `blkid`, `fsck`

> ⚠️ Internet connectivity is required during installation from remote sources.

---

## Installation

### Method 1: Direct Script Deployment

Download and install the script manually:

```bash
sudo wget -O /usr/local/sbin/grub-auto-recovery.sh \
  https://raw.githubusercontent.com/BreachFinder777/Boot-Saviour/refs/heads/main/grub-auto-recovery.sh

sudo chmod +x /usr/local/sbin/grub-auto-recovery.sh
```

Verify installation:

```bash
grub-auto-recovery.sh --status
```

### Method 2: System Service Installation (Recommended)

Enable automatic boot-time checks by installing the systemd service:

```bash
sudo grub-auto-recovery.sh --setup-service
```

This installs and enables a one-shot service that runs early in the boot process to validate GRUB integrity.

> 🔁 The service respects configuration settings in `/etc/grub-recovery.conf`.

---

## Operation Modes

Run the script with different flags to control behavior.

| Mode | Command | Description |
|------|--------|-----------|
| **Status Assessment** | `sudo grub-auto-recovery.sh --status` | Checks bootloader state without applying changes. |
| **Automated Repair** | `sudo grub-auto-recovery.sh` | Full workflow: diagnose → backup → repair → verify. |
| **Interactive Recovery** | `sudo grub-auto-recovery.sh --interactive` | Step-by-step mode with user confirmation at each stage. |
| **Forced Reinstall** | `sudo grub-auto-recovery.sh --force-repair` | Reinstalls GRUB regardless of current status. |

---

## Log Interpretation

Logs are written to `/var/log/grub-recovery.log` with timestamped entries categorized by severity level.

| Level | Meaning | Action Required? |
|-------|-------|------------------|
| **SUCCESS** | Operation completed successfully; boot integrity confirmed. | No action needed. |
| **INFO** | General system information (e.g., detected partitions, kernel versions). | For auditing purposes. |
| **WARN** | Potential issue detected (e.g., outdated config, missing fallback entry). | Monitor or investigate. |
| **ERROR** | Critical failure (e.g., GRUB not installed, unbootable state). | Immediate repair required. |

> 💡 Use `tail -f /var/log/grub-recovery.log` during recovery to monitor progress.

---

## Emergency Recovery

If your system fails to boot, use a **Live Linux environment** (USB/DVD) to restore GRUB.

### Steps:

1. Boot into a Live ISO (e.g., Ubuntu Live USB).
2. Connect to the internet.
3. Open a terminal and run:

```bash
wget https://raw.githubusercontent.com/BreachFinder777/Boot-Saviour/refs/heads/main/grub-auto-recovery.sh
chmod +x grub-auto-recovery.sh
sudo ./grub-auto-recovery.sh --force-repair
```

> 📌 The script will attempt to auto-detect your installed Linux system. If detection fails, refer to [Troubleshooting](#troubleshooting).

4. Reboot after completion:
```bash
sudo reboot
```

> ⚠️ Ensure Secure Boot is disabled if using unsigned GRUB binaries.

---

## Configuration

Customize behavior via the configuration file:  
**`/etc/grub-recovery.conf`**

| Parameter | Default | Description |
|---------|--------|------------|
| `AUTO_RECOVERY_ENABLED` | `true` | Enable/disable automatic repair on boot. |
| `RECOVERY_MODE` | `auto` | One of: `auto`, `force`, `check-only`. |
| `MAX_RETRY_ATTEMPTS` | `3` | Number of retries for failed operations. |
| `ENABLE_NOTIFICATIONS` | `false` | Send email alerts via local MTA (requires `mailutils`). |

> Example: To disable auto-repair but keep logging:
>
> ```conf
> AUTO_RECOVERY_ENABLED=false
> RECOVERY_MODE=check-only
> ```

### Edit Configuration via CLI

Use the built-in configurator:

```bash
sudo grub-auto-recovery.sh --config
```

This launches an interactive editor to safely modify settings.

---

## Troubleshooting

### ❌ Issue: Script fails to detect root partition

**Solution:** Manually specify the root partition in the config.

Edit `/etc/grub-recovery.conf`:

```conf
CUSTOM_ROOT_PARTITION="/dev/nvme0n1p2"
```

Replace with your actual root device (use `lsblk` to identify it).

---

### ❌ Issue: `grub-probe` errors during repair

**Symptoms:** "cannot find a GRUB drive for /dev/sda" or similar.

**Causes & Fixes:**

1. **Filesystem corruption**  
   Run:
   ```bash
   sudo fsck /dev/sdXY
   ```

2. **Missing or unmounted `/boot` or ESP (EFI System Partition)`**  
   Ensure ESP is mounted at `/boot/efi` (UEFI) or `/boot` (BIOS):
   ```bash
   sudo mount /dev/sdX1 /boot/efi
   ```

3. **Device not recognized**  
   Check output of:
   ```bash
   lsblk -f
   blkid
   ```
   Ensure disks are visible and properly formatted.

---

## License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

---

## Acknowledgments

- Developed by **Soham Datta**
- Special thanks to the open-source Linux community for testing, feedback, and contributions.
- Inspired by real-world dual-boot resilience challenges faced by users worldwide.

---

> 🔄 Always keep a Live USB handy. Prevention is better than recovery.



### ✅ Summary of Improvements

- Fixed broken link syntax (removed unnecessary parentheses around URLs).
- Improved readability with consistent headers, lists, and spacing.
- Added icons and visual cues for enhanced scanning.
- Clarified technical language and commands.
- Structured tables and code blocks for clarity.
- Enhanced troubleshooting section with actionable steps.
- Made tone more professional yet accessible.
- Ensured cross-referencing works smoothly (e.g., linking sections).

