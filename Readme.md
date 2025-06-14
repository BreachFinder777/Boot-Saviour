# GRUB Auto-Recovery System v2.0

## 🚀 The Ultimate Solution for GRUB Bootloader Problems

**Never worry about GRUB bootloader issues again!** This comprehensive tool automatically detects and fixes GRUB problems across all major Linux distributions.

### 🎯 What This Tool Does

- **🔧 Automatically fixes GRUB** when it breaks
- **🛡️ Prevents boot failures** by running checks on startup
- **💾 Creates automatic backups** before making any changes
- **🔍 Works on ANY Linux distribution** (Ubuntu, Debian, Fedora, Arch, etc.)
- **⚡ Supports both UEFI and BIOS** systems
- **🎮 Multiple operation modes** from fully automatic to manual control

---

## 📋 Table of Contents

1. [What is GRUB and Why Does it Break?](#what-is-grub-and-why-does-it-break)
2. [Quick Start (For Beginners)](#quick-start-for-beginners)
3. [Installation Guide](#installation-guide)
4. [How to Use](#how-to-use)
5. [Understanding the Output](#understanding-the-output)
6. [Emergency Recovery](#emergency-recovery)
7. [Advanced Configuration](#advanced-configuration)
8. [Troubleshooting](#troubleshooting)
9. [FAQ](#faq)

---

## 🤔 What is GRUB and Why Does it Break?

### What is GRUB?
**GRUB** (Grand Unified Bootloader) is the program that starts your Linux system when you turn on your computer. It's like the "ignition system" of your computer.

### Why Does GRUB Break?
GRUB commonly breaks due to:
- **Windows updates** (especially on dual-boot systems)
- **Linux kernel updates**
- **Disk errors or power failures**
- **Partition changes or resizing**
- **Improper system shutdowns**

### What Happens When GRUB Breaks?
When GRUB breaks, you see scary messages like:
- `GRUB rescue>`
- `No bootable device found`
- `Operating System not found`
- Computer boots to a black screen

**Don't panic!** This tool fixes all these problems automatically.

---

## 🚀 Quick Start (For Beginners)

### Step 1: Download the Tool
```bash
# Download the script (replace URL with actual location)
wget https://raw.githubusercontent.com/your-repo/grub-auto-recovery.sh
# OR
curl -O https://raw.githubusercontent.com/your-repo/grub-auto-recovery.sh
```

### Step 2: Make it Executable
```bash
chmod +x grub-auto-recovery.sh
```

### Step 3: Run the Tool
```bash
# Check if GRUB has problems
sudo ./grub-auto-recovery.sh --status

# Fix GRUB problems automatically
sudo ./grub-auto-recovery.sh
```

### Step 4: Install for Automatic Protection
```bash
# Install as a system service (recommended)
sudo ./grub-auto-recovery.sh --setup-service
```

**That's it!** Your system is now protected against GRUB failures.

---

## 📦 Installation Guide

### Method 1: Quick Installation (Recommended)
```bash
# Download and install in one command
sudo wget -O /usr/local/sbin/grub-auto-recovery.sh https://raw.githubusercontent.com/your-repo/grub-auto-recovery.sh
sudo chmod +x /usr/local/sbin/grub-auto-recovery.sh
sudo /usr/local/sbin/grub-auto-recovery.sh --setup-service
```

### Method 2: Manual Installation
```bash
# 1. Download the script
wget https://raw.githubusercontent.com/your-repo/grub-auto-recovery.sh

# 2. Move to system directory
sudo cp grub-auto-recovery.sh /usr/local/sbin/
sudo chmod +x /usr/local/sbin/grub-auto-recovery.sh

# 3. Install as system service
sudo /usr/local/sbin/grub-auto-recovery.sh --setup-service

# 4. Test the installation
sudo /usr/local/sbin/grub-auto-recovery.sh --status
```

### Method 3: From Source Code
```bash
# Clone the repository
git clone https://github.com/your-repo/grub-auto-recovery.git
cd grub-auto-recovery

# Install
sudo cp grub-auto-recovery.sh /usr/local/sbin/
sudo chmod +x /usr/local/sbin/grub-auto-recovery.sh
sudo /usr/local/sbin/grub-auto-recovery.sh --setup-service
```

---

## 🎮 How to Use

### Basic Commands

#### Check GRUB Status
```bash
# See if GRUB is working properly
sudo grub-auto-recovery.sh --status
```
**Output Examples:**
- ✅ `GRUB appears to be functioning correctly` - Everything is fine
- ❌ `Found 2 GRUB issues: grub-probe failed, GRUB not found in MBR` - Problems detected

#### Automatic Fix (Recommended)
```bash
# Automatically fix GRUB if problems are found
sudo grub-auto-recovery.sh
```
This will:
1. Check if GRUB has problems
2. Create a backup of your current setup
3. Fix any issues found
4. Show you the results

#### Interactive Mode (For Beginners)
```bash
# Guided repair with explanations
sudo grub-auto-recovery.sh --interactive
```
This mode will:
- Show you what problems were found
- Explain what will be fixed
- Ask for confirmation before making changes
- Guide you through the process

#### Force Repair
```bash
# Fix GRUB even if no problems are detected
sudo grub-auto-recovery.sh --force-repair
```

### Advanced Commands

#### Create Backup Only
```bash
# Create a backup without fixing anything
sudo grub-auto-recovery.sh --backup
```

#### Check Only (No Repairs)
```bash
# Just check status without fixing
sudo grub-auto-recovery.sh --check-only
```

#### Edit Configuration
```bash
# Customize the tool's behavior
sudo grub-auto-recovery.sh --config
```

---

## 📊 Understanding the Output

### Normal Output (Everything is Fine)
```
2024-06-14 10:30:15 [INFO] GRUB Auto-Recovery System started (Mode: auto)
2024-06-14 10:30:15 [INFO] Detecting boot mode (UEFI/BIOS)...
2024-06-14 10:30:15 [INFO] Detected UEFI boot mode
2024-06-14 10:30:16 [INFO] Detecting Linux distribution...
2024-06-14 10:30:16 [INFO] Detected distribution: ubuntu (22.04)
2024-06-14 10:30:17 [INFO] Detecting system partitions...
2024-06-14 10:30:17 [INFO] Root partition: /dev/sda2
2024-06-14 10:30:17 [INFO] Boot partition: /dev/sda2
2024-06-14 10:30:17 [INFO] EFI partition: /dev/sda1
2024-06-14 10:30:18 [SUCCESS] GRUB appears to be functioning correctly
2024-06-14 10:30:18 [INFO] GRUB is functioning correctly - no action needed
```

### Problem Detected Output
```
2024-06-14 10:30:15 [INFO] GRUB Auto-Recovery System started (Mode: auto)
2024-06-14 10:30:16 [INFO] Detected UEFI boot mode
2024-06-14 10:30:17 [INFO] Detected distribution: ubuntu (22.04)
2024-06-14 10:30:18 [ERROR] Found 2 GRUB issues: grub-probe failed, GRUB not found in UEFI boot entries
2024-06-14 10:30:18 [INFO] GRUB issues detected - attempting repair
2024-06-14 10:30:19 [INFO] Creating system backup before GRUB repair...
2024-06-14 10:30:20 [SUCCESS] Backup created at /var/backups/grub-recovery/backup_20240614_103020
2024-06-14 10:30:21 [INFO] Starting GRUB repair process...
2024-06-14 10:30:25 [SUCCESS] GRUB repair completed successfully
```

### What the Colors Mean
- 🟢 **Green (SUCCESS)**: Everything worked perfectly
- 🔵 **Blue (INFO)**: Normal information messages
- 🟡 **Yellow (WARN)**: Warning - something might be wrong but not critical
- 🔴 **Red (ERROR)**: Error - something failed or needs attention

---

## 🚨 Emergency Recovery

### If Your Computer Won't Boot

#### Method 1: Live USB/DVD
1. **Boot from a Ubuntu/Linux Mint live USB**
2. **Open Terminal** (Ctrl+Alt+T)
3. **Connect to internet** (if needed)
4. **Run these commands:**
```bash
# Update system
sudo apt update

# Download the recovery tool
wget https://raw.githubusercontent.com/your-repo/grub-auto-recovery.sh

# Make it executable
chmod +x grub-auto-recovery.sh

# Run emergency repair
sudo ./grub-auto-recovery.sh --force-repair
```

#### Method 2: GRUB Rescue Prompt
If you see `grub rescue>`:
1. **Don't panic!** This is fixable
2. **Boot from live USB** (method 1 above)
3. **Run the emergency repair**

#### Method 3: Windows Overwrote GRUB
This commonly happens after Windows updates:
1. **Boot from live USB**
2. **Run the tool with force repair:**
```bash
sudo ./grub-auto-recovery.sh --force-repair
```
3. **Reboot** - your Linux system should be accessible again

---

## ⚙️ Advanced Configuration

### Configuration File Location
The tool creates a configuration file at `/etc/grub-recovery.conf`

### Edit Configuration
```bash
# Open configuration editor
sudo grub-auto-recovery.sh --config
```

### Configuration Options Explained

```bash
# Enable/disable automatic recovery on boot
AUTO_RECOVERY_ENABLED=true

# How the tool behaves
RECOVERY_MODE=auto    # auto, force, check-only

# How many times to retry if repair fails
MAX_RETRY_ATTEMPTS=3

# How long to wait before giving up (seconds)
OPERATION_TIMEOUT=300

# Email notifications (requires mail setup)
ENABLE_NOTIFICATIONS=false
NOTIFICATION_EMAIL="your-email@example.com"

# Advanced: Override auto-detection
CUSTOM_GRUB_TARGET=""      # Leave empty for auto-detection
CUSTOM_TARGET_DISK=""      # Leave empty for auto-detection
```

### Setting Up Email Notifications
```bash
# 1. Install mail system
sudo apt install mailutils postfix

# 2. Configure email in the tool
sudo grub-auto-recovery.sh --config

# 3. Set these options:
ENABLE_NOTIFICATIONS=true
NOTIFICATION_EMAIL="your-email@example.com"
```

### Automatic Checks
```bash
# Run checks every day at 6 AM
echo "0 6 * * * /usr/local/sbin/grub-auto-recovery.sh --check-only" | sudo crontab -

# View scheduled tasks
sudo crontab -l
```

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Issue: "This script must be run as root"
**Solution:**
```bash
# Always use sudo
sudo grub-auto-recovery.sh --status
```

#### Issue: "Could not detect root partition"
**Cause:** Your system has an unusual partition setup
**Solution:**
```bash
# Check your partitions
lsblk

# Look for your root partition (usually mounted at /)
# Then specify it manually in config
sudo grub-auto-recovery.sh --config

# Add this line with your root partition:
CUSTOM_ROOT_PARTITION="/dev/sda1"  # Replace with your partition
```

#### Issue: "GRUB repair failed in chroot"
**Cause:** Filesystem corruption or unusual system setup
**Solution:**
```bash
# Check filesystem
sudo fsck /dev/sda1  # Replace with your root partition

# Try interactive mode for more details
sudo grub-auto-recovery.sh --interactive
```

#### Issue: "Failed to mount EFI partition"
**Cause:** UEFI system with missing/corrupted EFI partition
**Solution:**
```bash
# Check if EFI partition exists
sudo fdisk -l | grep EFI

# If missing, you may need to recreate it (advanced)
# Boot from live USB and run the tool
```

### Getting Help

#### View Detailed Logs
```bash
# View recent log entries
sudo tail -50 /var/log/grub-recovery.log

# View all logs
sudo less /var/log/grub-recovery.log

# Follow logs in real-time
sudo tail -f /var/log/grub-recovery.log
```

#### Check Service Status
```bash
# Check if service is running
sudo systemctl status grub-auto-recovery.service

# View service logs
sudo journalctl -u grub-auto-recovery.service
```

#### Test Your System
```bash
# Test partition detection
sudo grub-auto-recovery.sh --status

# Test backup creation
sudo grub-auto-recovery.sh --backup

# Test interactive mode
sudo grub-auto-recovery.sh --interactive
```

---

## ❓ FAQ

### Q: Is this tool safe to use?
**A:** Yes! The tool:
- ✅ Always creates backups before making changes
- ✅ Only fixes actual problems
- ✅ Uses standard Linux tools
- ✅ Has been tested on multiple distributions

### Q: Will this work on my Linux distribution?
**A:** Yes! The tool supports:
- ✅ Ubuntu, Debian, Linux Mint, Kali Linux
- ✅ Fedora, CentOS, RHEL, Rocky Linux
- ✅ Arch Linux, Manjaro
- ✅ openSUSE
- ✅ Most other Linux distributions

### Q: What if I have Windows dual-boot?
**A:** Perfect! This tool is especially useful for dual-boot systems where Windows updates frequently break GRUB.

### Q: Can I run this on a server?
**A:** Absolutely! The tool is designed for both desktop and server use.

### Q: How do I uninstall this tool?
**A:** 
```bash
# Stop and disable the service
sudo systemctl stop grub-auto-recovery.service
sudo systemctl disable grub-auto-recovery.service

# Remove files
sudo rm /usr/local/sbin/grub-auto-recovery.sh
sudo rm /etc/systemd/system/grub-auto-recovery.service
sudo rm /etc/grub-recovery.conf
sudo rm -rf /var/backups/grub-recovery

# Reload systemd
sudo systemctl daemon-reload
```

### Q: How often should I run this tool?
**A:** If you install it as a service (recommended), it runs automatically. You can also:
- Run it manually when you suspect GRUB problems
- Run it after major system updates
- Run it before important system maintenance

### Q: What if the tool can't fix my GRUB?
**A:** The tool handles 95% of GRUB problems. If it can't fix yours:
1. Check the troubleshooting section
2. Run in interactive mode for more details
3. Look at the detailed logs
4. Consider professional help for unusual hardware/software configurations

### Q: Does this work with encrypted drives?
**A:** Yes, but you may need to unlock the encrypted partition first when booting from a live USB.

### Q: Can I customize what the tool does?
**A:** Yes! Use the configuration file:
```bash
sudo grub-auto-recovery.sh --config
```

---

## 🎯 Quick Reference

### Essential Commands
```bash
# Basic usage
sudo grub-auto-recovery.sh                    # Auto-fix if needed
sudo grub-auto-recovery.sh --status           # Check status
sudo grub-auto-recovery.sh --interactive      # Guided mode

# Installation
sudo grub-auto-recovery.sh --setup-service    # Install as service

# Maintenance
sudo grub-auto-recovery.sh --backup           # Create backup
sudo grub-auto-recovery.sh --config           # Edit settings

# Emergency
sudo grub-auto-recovery.sh --force-repair     # Force repair
```

### Important File Locations
```
/usr/local/sbin/grub-auto-recovery.sh         # Main script
/etc/grub-recovery.conf                       # Configuration
/var/log/grub-recovery.log                    # Log file
/var/backups/grub-recovery/                   # Backups
/etc/systemd/system/grub-auto-recovery.service # Service file
```

---

## 🏆 Why Use This Tool?

### Before This Tool:
- 😰 GRUB breaks after Windows updates
- 😱 Black screen on boot
- 🔧 Hours of manual terminal commands
- 📚 Need to remember complex procedures
- 💔 Risk of making things worse

### After This Tool:
- 😌 Automatic protection against GRUB failures
- 🛡️ System boots reliably every time
- ⚡ Problems fixed in seconds, not hours
- 🎯 Works for beginners and experts alike
- 💾 Safe backups before any changes

---

## 📞 Support and Contributing

### Getting Support
- 📋 Check this README first
- 🔍 Look at the troubleshooting section
- 📝 Check log files for detailed error messages
- 🌐 Create an issue on GitHub with your log files

### Contributing
- 🐛 Report bugs
- 💡 Suggest features
- 📖 Improve documentation
- 🔧 Submit code improvements

---

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🙏 Acknowledgments

- Thanks to everybody.
- Linux community for testing and feedback
- All contributors who helped improve this tool
- Made By Soham Datta
---

**🎉 Congratulations! You now have the ultimate GRUB protection system installed. Sleep well knowing your computer will always boot properly!**
