# GRUB Auto-Recovery System 


**Transparent, Multi-Distro GRUB Bootloader Recovery**  
*Automatically detects UEFI/BIOS, partitions, and distro-specific tools. No configuration needed.*

## ✨ Features

✅ **Multi-Distro Support** - Ubuntu, Debian, Fedora, RHEL, Arch, openSUSE, and more  
✅ **Automatic Detection** - UEFI/BIOS, partitions, GRUB tools, config paths  
✅ **7-Step Transparency** - See exactly what the script will do  
✅ **Safe Dry-Run Mode** - Preview all actions without changes  
✅ **Automatic Backups** - Timestamped backups before any repair  
✅ **systemd Integration** - One-shot service for boot-time recovery  
✅ **Chroot Repair** - Proper environment for distro-specific GRUB commands  
✅ **Color Output** - Clear success/warning/error feedback  

## 📋 Modes (Choose Your Safety Level)

| Mode | Command | What it does | Changes files? | Mounts filesystems? |
|------|---------|--------------|----------------|-------------------|
| **`--dry-run`** | `sudo ./script.sh --dry-run` | **COMPLETE SIMULATION** - Shows every command that would run | ❌ No | ❌ No |
| **`--check-only`** | `sudo ./script.sh --check-only` | Non-destructive health checks only | ❌ No | ❌ No |
| **`--auto-check`** | `sudo ./script.sh` (default) | **RECOMMENDED** - Check → repair only if issues found | ✅ Only if needed | ✅ Only if needed |
| **`--force-repair`** | `sudo ./script.sh --force-repair` | Skip checks, repair immediately | ✅ Yes | ✅ Yes |
| **`--uefi-removable`** | `sudo ./script.sh --uefi-removable` | Force repair + UEFI fallback path | ✅ Yes | ✅ Yes |
| **`--setup-service`**| `sudo ./script.sh --setup-service` | Install systemd service | ✅ Service only | ❌ No |

## 🚀 Quick Start

### 1. Download & Make Executable
```bash
wget https://raw.githubusercontent.com/USER/grub-auto-recovery/main/grub-auto-recovery.sh
chmod +x grub-auto-recovery.sh
```

### 2. Test First (Always!)
```bash
sudo ./grub-auto-recovery.sh --dry-run
```
**Expected output**: Shows 7 steps + all commands that *would* run. No changes made.

### 3. Safe Auto-Repair
```bash
sudo ./grub-auto-recovery.sh --auto-check
```

### 4. Install as Service (Optional)
```bash
sudo ./grub-auto-recovery.sh --setup-service
sudo reboot  # Test it!
```

## 🛠️ Detailed Mode Guide

### `--dry-run` (100% Safe Preview)
```
Step 1/7: Detecting OS...
Step 2/7: Detecting boot mode...
...
Step 6c/7: GRUB repair sequence...
WOULD RUN: mount /dev/sda1 /mnt/grub-recovery-chroot
   → SIMULATED (no changes made)
```
**Use when**: First time, demo, or before production use.

### `--check-only` (Health Check Only)
```
✓ grub-probe works
✓ /boot/grub/grub.cfg exists (1234 bytes)
✗ No GRUB entry in efibootmgr
✗ GRUB health check: 2 ISSUE(S) DETECTED
```
**Use when**: Verify GRUB status without risk.

### `--auto-check` (Smart Default)
```
AUTO mode: Issues found → repair
Step 6a/7: Creating backup... ✓ Backup created: /var/backups/grub-recovery/backup_20260120_2255/
✓ GRUB repair completed successfully
```
**Use when**: Production systems (recommended).

### `--force-repair` (Emergency Fix)
Skips all checks, runs full repair sequence immediately.

### `--uefi-removable` (UEFI Fallback)
Same as `--force-repair` but adds `grub-install --removable` for UEFI systems where NVRAM boot entries are broken.

## 🔍 What Gets Detected Automatically

```
OS detected: Ubuntu 24.04.1 LTS (ID=ubuntu, ID_LIKE=debian)
Boot mode: UEFI (GRUB_TARGET=x86_64-efi)
Mount sources detected:
  → /        = /dev/nvme0n1p2
  → /boot    = /dev/nvme0n1p1  
  → /boot/efi= /dev/nvme0n1p3
BIOS install target disk: /dev/nvme0n1
GRUB tools detected:
  → mkconfig command: update-grub
  → config output path: /boot/grub/grub.cfg
```

## 🛡️ Safety Features

1. **Backups First** - Always creates timestamped backup before repair
2. **Dry-Run Mode** - 100% safe simulation  
3. **Chroot Environment** - Proper distro-specific repair context
4. **Timeout Protection** - 5-minute timeout per operation
5. **Detailed Logging** - `/var/log/grub-recovery.log`
6. **Graceful Cleanup** - Unmounts on exit/error
7. **Root Check** - Prevents accidents

## 📁 Backup Structure
```
/var/backups/grub-recovery/
├── backup_20260120_225512/        # Timestamped backup
│   ├── grub.cfg                   # Current GRUB config
│   ├── default                    # /etc/default/grub
│   ├── grub.d/                    # GRUB config templates
│   ├── efibootmgr.txt             # UEFI NVRAM entries (UEFI only)
│   └── mbr.bin                    # MBR backup (BIOS only)
├── latest_backup.txt              # Symlink to newest
└── grub-recovery.log.old          # Rotated logs
```

## ⚙️ systemd Service (Recommended)

```ini
# /etc/systemd/system/grub-auto-recovery.service
[Unit]
Description=GRUB Auto Recovery v3.2 (Transparent)
After=local-fs.target
Wants=local-fs.target
Before=multi-user.target
DefaultDependencies=no

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/grub-auto-recovery.sh --auto-check
TimeoutStartSec=300
```

**Service runs**:
- After filesystems mount (`local-fs.target`)
- Before login screen (`multi-user.target`)  
- Exactly once per boot (`Type=oneshot`)

**Check service logs**:
```bash
journalctl -u grub-auto-recovery.service -b
```

## 🧪 Supported Distros (Capability-Based)

| Distro Family | `mkconfig` Tool | Status |
|---------------|-----------------|--------|
| Ubuntu/Debian | `update-grub` | ✅ Full |
| Fedora/RHEL   | `grub2-mkconfig` | ✅ Full |
| Arch Linux    | `grub-mkconfig` | ✅ Full |
| openSUSE      | `grub2-mkconfig` | ✅ Full |
| Gentoo        | `grub-mkconfig` | ✅ Full |
| Pop!_OS/Mint  | `update-grub` | ✅ Full |

**Works on any distro** with standard GRUB tools.

## 🚨 Troubleshooting

| Issue | Check |
|-------|-------|
| `Cannot determine root device` | Ensure `/` is properly mounted |
| `No grub mkconfig tool found` | Install `grub-common` / `grub2-tools` |
| `efibootmgr not available` | Normal on BIOS; `apt install efibootmgr` on UEFI |
| `/boot/efi is not mounted` | Mount EFI partition manually first |

## 📊 Health Check Results

```
✓ grub-probe works                    [GRUB can read /boot]
✓ GRUB config exists (1234 bytes)     [Config file OK]  
⚠ No GRUB entry in efibootmgr         [UEFI NVRAM issue]
✓ GRUB signature in MBR               [BIOS bootloader OK]
```

**0 issues** = Healthy  
**1+ issues** = Repair recommended

## 💬 Example Dry-Run Output

```bash
$ sudo ./grub-auto-recovery.sh --dry-run
==================================================
GRUB Auto-Recovery v3.2
Mode: dry-run | Dry-run: true
Log:  /var/log/grub-recovery.log
==================================================
Step 1/7: Detecting OS... ✓ OS detected: Ubuntu 24.04
Step 6c/7: GRUB repair sequence...
WOULD RUN: mount /dev/sda1 /mnt/grub-recovery-chroot
   → SIMULATED (no changes made)
DRY-RUN COMPLETE: No changes made
```

## 🔗 License & Contribution

[MIT License](LICENSE) - Free to use, modify, distribute.

**Issues & PRs welcome!** Report bugs with:
```bash
sudo ./grub-auto-recovery.sh --check-only 2>&1 | tee grub-status.txt
```

***

**⭐ Star if helpful!**  
*Built for sysadmins who want transparency + safety + automation.*
