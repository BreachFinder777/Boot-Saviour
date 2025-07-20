#!/bin/bash

# ===================================================================
# Enhanced GRUB Auto-Recovery System v2.0
# Comprehensive solution for GRUB bootloader issues
# Supports multiple distributions, UEFI/BIOS, and various failure modes
# ===================================================================

# --- Configuration ---
readonly LOG_FILE="/var/log/grub-recovery.log"
readonly MOUNT_POINT="/mnt/recovery_chroot"
readonly SCRIPT_PATH="/usr/local/sbin/grub-auto-recovery.sh"
readonly SERVICE_NAME="grub-auto-recovery.service"
readonly SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"
readonly CONFIG_FILE="/etc/grub-recovery.conf"
readonly BACKUP_DIR="/var/backups/grub-recovery"
readonly MAX_LOG_SIZE=10485760  # 10MB
readonly RETRY_ATTEMPTS=3
readonly TIMEOUT_SECONDS=300    # 5 minutes timeout for operations

# --- Global Variables ---
declare -g BOOT_MODE=""           # UEFI or BIOS
declare -g DISTRO=""             # Distribution name
declare -g ROOT_PART=""          # Root partition
declare -g BOOT_PART=""          # Boot partition
declare -g EFI_PART=""           # EFI partition (if UEFI)
declare -g GRUB_TARGET=""        # GRUB target (i386-pc, x86_64-efi, etc.)
declare -g RECOVERY_MODE="auto"   # auto, force, check-only

# --- Enhanced Logging System ---
function log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%F %T')
    local log_entry="$timestamp [$level] $message"
    
    # Rotate log if too large
    if [[ -f "$LOG_FILE" && $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) -gt $MAX_LOG_SIZE ]]; then
        mv "$LOG_FILE" "${LOG_FILE}.old" 2>/dev/null
    fi
    
    echo "$log_entry" | tee -a "$LOG_FILE"
    
    # Also send to syslog for system integration
    logger -t "grub-recovery" "$log_entry"
    
    # Color coding for terminal output
    case "$level" in
        "ERROR") echo -e "\033[1;31m$log_entry\033[0m" ;;
        "WARN")  echo -e "\033[1;33m$log_entry\033[0m" ;;
        "SUCCESS") echo -e "\033[1;32m$log_entry\033[0m" ;;
    esac
}

# --- System Detection Functions ---
function detect_boot_mode() {
    log "INFO" "Detecting boot mode (UEFI/BIOS)..."
    
    if [[ -d /sys/firmware/efi ]]; then
        BOOT_MODE="UEFI"
        GRUB_TARGET="x86_64-efi"
        log "INFO" "Detected UEFI boot mode"
    else
        BOOT_MODE="BIOS"
        GRUB_TARGET="i386-pc"
        log "INFO" "Detected BIOS boot mode"
    fi
}

function detect_distribution() {
    log "INFO" "Detecting Linux distribution..."
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
        log "INFO" "Detected distribution: $DISTRO ($VERSION_ID)"
    else
        DISTRO="unknown"
        log "WARN" "Could not detect distribution"
    fi
}

function detect_partitions() {
    log "INFO" "Detecting system partitions..."
    
    # Detect root partition
    ROOT_PART=$(findmnt -n -o SOURCE /)
    if [[ -z "$ROOT_PART" ]]; then
        ROOT_PART=$(lsblk -nro MOUNTPOINT,KNAME,FSTYPE | awk '$1 == "/" && $3 ~ /ext[2-4]|xfs|btrfs|f2fs/ {print "/dev/" $2}' | head -1)
    fi
    
    # Detect boot partition
    BOOT_PART=$(findmnt -n -o SOURCE /boot 2>/dev/null)
    if [[ -z "$BOOT_PART" && "$ROOT_PART" ]]; then
        BOOT_PART="$ROOT_PART"  # Boot is on root partition
    fi
    
    # Detect EFI partition (if UEFI)
    if [[ "$BOOT_MODE" == "UEFI" ]]; then
        EFI_PART=$(findmnt -n -o SOURCE /boot/efi 2>/dev/null)
        if [[ -z "$EFI_PART" ]]; then
            EFI_PART=$(lsblk -nro MOUNTPOINT,KNAME,FSTYPE | awk '$1 == "/boot/efi" && $3 == "vfat" {print "/dev/" $2}' | head -1)
        fi
    fi
    
    log "INFO" "Root partition: ${ROOT_PART:-NOT_FOUND}"
    log "INFO" "Boot partition: ${BOOT_PART:-NOT_FOUND}"
    [[ "$BOOT_MODE" == "UEFI" ]] && log "INFO" "EFI partition: ${EFI_PART:-NOT_FOUND}"
    
    # Validate critical partitions
    if [[ -z "$ROOT_PART" ]]; then
        log "ERROR" "Could not detect root partition"
        return 1
    fi
    
    if [[ "$BOOT_MODE" == "UEFI" && -z "$EFI_PART" ]]; then
        log "ERROR" "Could not detect EFI partition (required for UEFI systems)"
        return 1
    fi
    
    return 0
}

# --- Enhanced GRUB Status Checking ---
function check_grub_status() {
    log "INFO" "Performing comprehensive GRUB status check..."
    
    local issues=0
    local issue_descriptions=()
    
    # Test 1: grub-probe functionality
    if ! timeout 30 grub-probe /boot &>/dev/null; then
        ((issues++))
        issue_descriptions+=("grub-probe failed")
        log "WARN" "GRUB probe test failed"
    fi
    
    # Test 2: GRUB configuration file exists and is readable
    local grub_cfg="/boot/grub/grub.cfg"
    [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]] && grub_cfg="/boot/grub/grub.cfg"
    [[ "$DISTRO" == "fedora" || "$DISTRO" == "centos" || "$DISTRO" == "rhel" ]] && grub_cfg="/boot/grub2/grub.cfg"
    
    if [[ ! -r "$grub_cfg" ]]; then
        ((issues++))
        issue_descriptions+=("GRUB configuration missing or unreadable")
        log "WARN" "GRUB configuration file issue: $grub_cfg"
    fi
    
    # Test 3: GRUB installation in MBR/EFI
    if [[ "$BOOT_MODE" == "BIOS" ]]; then
        local disk=$(lsblk -no PKNAME "$ROOT_PART" | head -1)
        if [[ -n "$disk" ]]; then
            if ! dd if="/dev/$disk" bs=512 count=1 2>/dev/null | strings | grep -q "GRUB"; then
                ((issues++))
                issue_descriptions+=("GRUB not found in MBR")
                log "WARN" "GRUB not detected in MBR of /dev/$disk"
            fi
        fi
    elif [[ "$BOOT_MODE" == "UEFI" ]]; then
        if ! efibootmgr 2>/dev/null | grep -qi grub; then
            ((issues++))
            issue_descriptions+=("GRUB not found in UEFI boot entries")
            log "WARN" "GRUB not detected in UEFI boot entries"
        fi
    fi
    
    # Test 4: Check for kernel panic or boot failure indicators
    if journalctl -b -1 --no-pager -q 2>/dev/null | grep -q "Kernel panic\|grub_cmd_linux\|error.*grub"; then
        ((issues++))
        issue_descriptions+=("Previous boot failures detected")
        log "WARN" "Previous GRUB-related boot failures detected in journal"
    fi
    
    # Report results
    if [[ $issues -eq 0 ]]; then
        log "SUCCESS" "GRUB appears to be functioning correctly"
        return 1  # No issues found
    else
        log "ERROR" "Found $issues GRUB issues: ${issue_descriptions[*]}"
        return 0  # Issues found
    fi
}

# --- Backup System ---
function create_backup() {
    log "INFO" "Creating system backup before GRUB repair..."
    
    mkdir -p "$BACKUP_DIR" || {
        log "ERROR" "Failed to create backup directory"
        return 1
    }
    
    local backup_timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_path="$BACKUP_DIR/backup_$backup_timestamp"
    
    mkdir -p "$backup_path"
    
    # Backup critical files
    [[ -f /boot/grub/grub.cfg ]] && cp /boot/grub/grub.cfg "$backup_path/" 2>/dev/null
    [[ -f /boot/grub2/grub.cfg ]] && cp /boot/grub2/grub.cfg "$backup_path/" 2>/dev/null
    [[ -f /etc/default/grub ]] && cp /etc/default/grub "$backup_path/" 2>/dev/null
    [[ -d /etc/grub.d ]] && cp -r /etc/grub.d "$backup_path/" 2>/dev/null
    
    # Backup EFI entries if UEFI
    if [[ "$BOOT_MODE" == "UEFI" ]]; then
        efibootmgr -v > "$backup_path/efi_entries.txt" 2>/dev/null
    fi
    
    # Backup MBR if BIOS
    if [[ "$BOOT_MODE" == "BIOS" && -n "$ROOT_PART" ]]; then
        local disk=$(lsblk -no PKNAME "$ROOT_PART" | head -1)
        [[ -n "$disk" ]] && dd if="/dev/$disk" of="$backup_path/mbr_backup.bin" bs=512 count=1 2>/dev/null
    fi
    
    log "SUCCESS" "Backup created at $backup_path"
    echo "$backup_path" > "$BACKUP_DIR/latest_backup.txt"
    
    # Clean old backups (keep last 5)
    cd "$BACKUP_DIR" && ls -t | tail -n +6 | xargs rm -rf 2>/dev/null
    
    return 0
}

# --- Enhanced Chroot Environment ---
function setup_chroot() {
    log "INFO" "Setting up chroot environment..."
    
    # Clean any existing mounts
    cleanup_chroot
    
    # Create mount point
    mkdir -p "$MOUNT_POINT" || {
        log "ERROR" "Failed to create mount point"
        return 1
    }
    
    # Mount root filesystem
    if ! mount "$ROOT_PART" "$MOUNT_POINT"; then
        log "ERROR" "Failed to mount root partition $ROOT_PART"
        return 1
    fi
    
    # Mount boot partition if separate
    if [[ "$BOOT_PART" != "$ROOT_PART" && -n "$BOOT_PART" ]]; then
        mkdir -p "$MOUNT_POINT/boot"
        if ! mount "$BOOT_PART" "$MOUNT_POINT/boot"; then
            log "ERROR" "Failed to mount boot partition $BOOT_PART"
            cleanup_chroot
            return 1
        fi
    fi
    
    # Mount EFI partition if UEFI
    if [[ "$BOOT_MODE" == "UEFI" && -n "$EFI_PART" ]]; then
        mkdir -p "$MOUNT_POINT/boot/efi"
        if ! mount "$EFI_PART" "$MOUNT_POINT/boot/efi"; then
            log "ERROR" "Failed to mount EFI partition $EFI_PART"
            cleanup_chroot
            return 1
        fi
    fi
    
    # Bind mount essential directories
    local bind_mounts=("/dev" "/dev/pts" "/proc" "/sys" "/run")
    for mount_point in "${bind_mounts[@]}"; do
        mkdir -p "$MOUNT_POINT$mount_point"
        if ! mount --bind "$mount_point" "$MOUNT_POINT$mount_point"; then
            log "ERROR" "Failed to bind mount $mount_point"
            cleanup_chroot
            return 1
        fi
    done
    
    log "SUCCESS" "Chroot environment ready"
    return 0
}

function cleanup_chroot() {
    log "INFO" "Cleaning up chroot environment..."
    
    if [[ -d "$MOUNT_POINT" ]]; then
        # Unmount in reverse order
        local mount_points=(
            "$MOUNT_POINT/run"
            "$MOUNT_POINT/sys"
            "$MOUNT_POINT/proc"
            "$MOUNT_POINT/dev/pts"
            "$MOUNT_POINT/dev"
            "$MOUNT_POINT/boot/efi"
            "$MOUNT_POINT/boot"
            "$MOUNT_POINT"
        )
        
        for mp in "${mount_points[@]}"; do
            if mountpoint -q "$mp" 2>/dev/null; then
                umount -l "$mp" 2>/dev/null || umount -f "$mp" 2>/dev/null
            fi
        done
        
        # Remove mount point if empty
        rmdir "$MOUNT_POINT" 2>/dev/null
    fi
    
    log "INFO" "Chroot cleanup completed"
}

# --- Distribution-Specific GRUB Repair ---
function repair_grub() {
    log "INFO" "Starting GRUB repair process..."
    
    # Create backup first
    if ! create_backup; then
        log "WARN" "Backup creation failed, but continuing with repair"
    fi
    
    # Setup chroot environment
    if ! setup_chroot; then
        log "ERROR" "Failed to setup chroot environment"
        return 1
    fi
    
    # Determine target disk
    local target_disk=""
    if [[ "$BOOT_MODE" == "BIOS" ]]; then
        target_disk="/dev/$(lsblk -no PKNAME "$ROOT_PART" | head -1)"
    fi
    
    log "INFO" "Entering chroot to repair GRUB..."
    
    # Create repair script for chroot
    local chroot_script="$MOUNT_POINT/tmp/grub_repair.sh"
    cat > "$chroot_script" << 'EOF'
#!/bin/bash
set -e

# Distribution-specific commands
DISTRO="$1"
BOOT_MODE="$2"
TARGET_DISK="$3"
GRUB_TARGET="$4"

log_chroot() {
    echo "$(date '+%F %T') [CHROOT] $1" >> /tmp/chroot.log
}

log_chroot "Starting GRUB repair in chroot (Distro: $DISTRO, Mode: $BOOT_MODE)"

# Update package cache if possible
case "$DISTRO" in
    ubuntu|debian|kali)
        if command -v apt-get >/dev/null; then
            log_chroot "Updating package cache..."
            apt-get update -qq 2>/dev/null || true
        fi
        ;;
    fedora|centos|rhel)
        if command -v dnf >/dev/null; then
            log_chroot "Updating package cache..."
            dnf check-update -q 2>/dev/null || true
        elif command -v yum >/dev/null; then
            log_chroot "Updating package cache..."
            yum check-update -q 2>/dev/null || true
        fi
        ;;
    arch)
        if command -v pacman >/dev/null; then
            log_chroot "Updating package cache..."
            pacman -Syy --noconfirm 2>/dev/null || true
        fi
        ;;
esac

# Install/reinstall GRUB
log_chroot "Installing GRUB to $TARGET_DISK with target $GRUB_TARGET"

case "$DISTRO" in
    ubuntu|debian|kali)
        if [[ "$BOOT_MODE" == "UEFI" ]]; then
            grub-install --target="$GRUB_TARGET" --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
        else
            grub-install --target="$GRUB_TARGET" "$TARGET_DISK" --recheck
        fi
        update-grub
        ;;
    fedora|centos|rhel)
        if [[ "$BOOT_MODE" == "UEFI" ]]; then
            grub2-install --target="$GRUB_TARGET" --efi-directory=/boot/efi --bootloader-id=GRUB
        else
            grub2-install --target="$GRUB_TARGET" "$TARGET_DISK"
        fi
        grub2-mkconfig -o /boot/grub2/grub.cfg
        ;;
    arch)
        if [[ "$BOOT_MODE" == "UEFI" ]]; then
            grub-install --target="$GRUB_TARGET" --efi-directory=/boot/efi --bootloader-id=GRUB
        else
            grub-install --target="$GRUB_TARGET" "$TARGET_DISK"
        fi
        grub-mkconfig -o /boot/grub/grub.cfg
        ;;
    *)
        # Generic approach
        if [[ "$BOOT_MODE" == "UEFI" ]]; then
            grub-install --target="$GRUB_TARGET" --efi-directory=/boot/efi --bootloader-id=GRUB
        else
            grub-install --target="$GRUB_TARGET" "$TARGET_DISK"
        fi
        # Try different config generation commands
        if command -v update-grub >/dev/null; then
            update-grub
        elif command -v grub2-mkconfig >/dev/null; then
            grub2-mkconfig -o /boot/grub2/grub.cfg
        elif command -v grub-mkconfig >/dev/null; then
            grub-mkconfig -o /boot/grub/grub.cfg
        fi
        ;;
esac

log_chroot "GRUB repair completed successfully"
EOF

    chmod +x "$chroot_script"
    
    # Execute repair in chroot with timeout
    if timeout $TIMEOUT_SECONDS chroot "$MOUNT_POINT" /tmp/grub_repair.sh "$DISTRO" "$BOOT_MODE" "$target_disk" "$GRUB_TARGET"; then
        log "SUCCESS" "GRUB repair completed successfully"
        
        # Copy chroot log to main log
        if [[ -f "$MOUNT_POINT/tmp/chroot.log" ]]; then
            cat "$MOUNT_POINT/tmp/chroot.log" >> "$LOG_FILE"
        fi
        
        cleanup_chroot
        return 0
    else
        log "ERROR" "GRUB repair failed in chroot"
        [[ -f "$MOUNT_POINT/tmp/chroot.log" ]] && cat "$MOUNT_POINT/tmp/chroot.log" >> "$LOG_FILE"
        cleanup_chroot
        return 1
    fi
}

# --- Configuration Management ---
function load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        log "INFO" "Configuration loaded from $CONFIG_FILE"
    else
        # Create default configuration
        cat > "$CONFIG_FILE" << 'EOF'
# GRUB Recovery Configuration
# Set to 'true' to enable automatic recovery on boot
AUTO_RECOVERY_ENABLED=true

# Recovery mode: auto, force, check-only
RECOVERY_MODE=auto

# Maximum number of retry attempts
MAX_RETRY_ATTEMPTS=3

# Timeout for operations (seconds)
OPERATION_TIMEOUT=300

# Enable notifications (requires mail/notification system)
ENABLE_NOTIFICATIONS=false

# Email for notifications (if enabled)
NOTIFICATION_EMAIL=""

# Custom GRUB target (leave empty for auto-detection)
CUSTOM_GRUB_TARGET=""

# Custom target disk (leave empty for auto-detection)
CUSTOM_TARGET_DISK=""
EOF
        log "INFO" "Default configuration created at $CONFIG_FILE"
    fi
}

# --- Service Management ---
function setup_service() {
    log "INFO" "Setting up systemd service..."
    
    # Ensure script is in correct location
    if [[ "$0" != "$SCRIPT_PATH" ]]; then
        cp "$0" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        log "INFO" "Script copied to $SCRIPT_PATH"
    fi
    
    # Create enhanced service file
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=GRUB Auto Recovery Service
Documentation=man:grub-auto-recovery(8)
After=local-fs.target systemd-fsck-root.service
Before=display-manager.service
DefaultDependencies=no
ConditionPathExists=$SCRIPT_PATH

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH --auto-check
RemainAfterExit=yes
StandardOutput=journal+console
StandardError=journal+console
TimeoutStartSec=$TIMEOUT_SECONDS
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    log "SUCCESS" "Service enabled and configured"
    
    # Create logrotate configuration
    cat > "/etc/logrotate.d/grub-recovery" << EOF
$LOG_FILE {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF
    
    log "INFO" "Log rotation configured"
}

# --- Interactive Repair Mode ---
function interactive_mode() {
    echo "=== GRUB Recovery Interactive Mode ==="
    echo
    echo "System Information:"
    echo "  Distribution: $DISTRO"
    echo "  Boot Mode: $BOOT_MODE"
    echo "  Root Partition: $ROOT_PART"
    echo "  Boot Partition: $BOOT_PART"
    [[ "$BOOT_MODE" == "UEFI" ]] && echo "  EFI Partition: $EFI_PART"
    echo
    
    read -p "Proceed with GRUB repair? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if repair_grub; then
            echo
            read -p "GRUB repair completed. Reboot now? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "INFO" "Rebooting system..."
                reboot
            fi
        else
            log "ERROR" "GRUB repair failed. Check logs for details."
            return 1
        fi
    else
        log "INFO" "Repair cancelled by user"
        return 1
    fi
}

# --- Main Functions ---
function print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

GRUB Auto-Recovery System v2.0

OPTIONS:
    --auto-check        Automatically check and repair GRUB if needed
    --force-repair      Force GRUB repair regardless of status
    --check-only        Only check GRUB status, don't repair
    --interactive       Interactive repair mode
    --setup-service     Install and configure systemd service
    --status            Show current GRUB status
    --backup            Create backup only
    --restore [path]    Restore from backup
    --config            Edit configuration
    --help             Show this help

EXAMPLES:
    $0 --auto-check     # Check and repair if needed (default)
    $0 --interactive    # Interactive mode with user prompts
    $0 --setup-service  # Install as system service
    $0 --status         # Check GRUB status only

EOF
}

function main() {
    # Ensure running as root
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root"
        exit 1
    fi
    
    # Setup signal handlers
    trap cleanup_chroot EXIT INT TERM
    
    # Create log directory
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Load configuration
    load_config
    
    # Detect system configuration
    detect_boot_mode
    detect_distribution
    
    if ! detect_partitions; then
        log "ERROR" "Failed to detect system partitions"
        exit 1
    fi
    
    # Parse command line arguments
    case "${1:-}" in
        --setup-service)
            setup_service
            exit 0
            ;;
        --force-repair)
            RECOVERY_MODE="force"
            ;;
        --check-only)
            RECOVERY_MODE="check-only"
            ;;
        --interactive)
            interactive_mode
            exit $?
            ;;
        --status)
            check_grub_status
            exit $?
            ;;
        --backup)
            create_backup
            exit $?
            ;;
        --restore)
            # Restore functionality would go here
            log "INFO" "Restore functionality not yet implemented"
            exit 1
            ;;
        --config)
            ${EDITOR:-nano} "$CONFIG_FILE"
            exit 0
            ;;
        --help)
            print_usage
            exit 0
            ;;
        --auto-check|"")
            RECOVERY_MODE="auto"
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
    
    # Main logic
    log "INFO" "GRUB Auto-Recovery System started (Mode: $RECOVERY_MODE)"
    
    case "$RECOVERY_MODE" in
        "check-only")
            check_grub_status
            exit $?
            ;;
        "force")
            log "INFO" "Force repair mode - skipping status check"
            if repair_grub; then
                log "SUCCESS" "GRUB repair completed successfully"
                exit 0
            else
                log "ERROR" "GRUB repair failed"
                exit 1
            fi
            ;;
        "auto"|*)
            check_grub_status
            if [[ $? -eq 0 ]]; then
                log "INFO" "GRUB issues detected - attempting repair"
                if repair_grub; then
                    log "SUCCESS" "GRUB repair completed successfully"
                    exit 0
                else
                    log "ERROR" "GRUB repair failed"
                    exit 1
                fi
            else
                log "INFO" "GRUB is functioning correctly - no action needed"
                exit 0
            fi
            ;;
    esac
}

# Execute main function
main "$@"
