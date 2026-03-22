#!/bin/bash
# =============================================================================
# Script Name  : apache_backup_restore.sh
# Description  : Backup and restore Apache HTTP Server configurations
# Purpose      : Create timestamped backups of Apache configs, sites, and data.
#                Restore from previous backups. List and clean old backups.
# Usage        : sudo bash apache_backup_restore.sh
# Author       : Open Source Audit Project
# =============================================================================

# ----- Color Definitions -----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ----- Configuration -----
BACKUP_DIR="/var/backups/apache2"
APACHE_CONF_DIR="/etc/apache2"
WEB_ROOT="/var/www"
LOG_FILE="/var/log/apache_backup.log"
MAX_BACKUPS=10  # Maximum number of backups to retain

# =============================================================================
# Function: print_banner
# =============================================================================
print_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}   ${BOLD}Apache Backup & Restore Manager${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Protect your Apache configuration and data            ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# =============================================================================
# Function: check_root
# =============================================================================
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Error: This script must be run as root (use sudo).${NC}"
        exit 1
    fi
}

# =============================================================================
# Function: log_action
# Writes a timestamped entry to the backup log file
# Arguments: $1 - Log message
# =============================================================================
log_action() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
    echo -e "  ${CYAN}LOG:${NC} $message"
}

# =============================================================================
# Function: ensure_backup_dir
# Creates the backup directory if it doesn't exist
# =============================================================================
ensure_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log_action "Created backup directory: $BACKUP_DIR"
    fi
}

# =============================================================================
# Function: show_menu
# =============================================================================
show_menu() {
    echo -e "${BOLD}── Main Menu ──${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}) Full backup (configs + sites)"
    echo -e "  ${GREEN}2${NC}) Backup configs only"
    echo -e "  ${GREEN}3${NC}) Backup sites/web data only"
    echo -e "  ${GREEN}4${NC}) Restore from backup"
    echo -e "  ${GREEN}5${NC}) List available backups"
    echo -e "  ${GREEN}6${NC}) Cleanup old backups"
    echo -e "  ${GREEN}7${NC}) View backup log"
    echo -e "  ${RED}0${NC}) Exit"
    echo ""
    echo -n -e "  ${BOLD}Select an option [0-7]:${NC} "
}

# =============================================================================
# Function: full_backup
# Creates a complete backup of Apache configs and web data
# Uses: tar (archiving), date (timestamps), du (size calculation)
# =============================================================================
full_backup() {
    echo ""
    echo -e "${BOLD}── Full Backup ──${NC}"
    echo ""

    ensure_backup_dir

    # Generate a timestamped filename
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="${BACKUP_DIR}/apache_full_${timestamp}.tar.gz"

    echo -e "  ${CYAN}Starting full backup...${NC}"
    echo -e "  ${CYAN}Backing up:${NC}"
    echo -e "    - Apache configs: $APACHE_CONF_DIR"
    echo -e "    - Web data:       $WEB_ROOT"
    echo ""

    # Create a compressed tar archive containing both config and web data
    # -c: create, -z: gzip compress, -f: filename, -p: preserve permissions
    local dirs_to_backup=""

    # Only add directories that exist
    if [ -d "$APACHE_CONF_DIR" ]; then
        dirs_to_backup="$APACHE_CONF_DIR"
    fi
    if [ -d "$WEB_ROOT" ]; then
        dirs_to_backup="$dirs_to_backup $WEB_ROOT"
    fi

    if [ -z "$dirs_to_backup" ]; then
        echo -e "  ${RED}Error: No directories found to backup.${NC}"
        log_action "FAILED: Full backup — no directories found"
        return 1
    fi

    # Execute the tar command
    if tar -czpf "$backup_file" $dirs_to_backup 2>/dev/null; then
        # Get the size of the backup file
        local backup_size
        backup_size=$(du -h "$backup_file" | awk '{print $1}')

        echo -e "  ${GREEN}✓ Full backup created successfully!${NC}"
        echo -e "  ${CYAN}File:${NC} $backup_file"
        echo -e "  ${CYAN}Size:${NC} $backup_size"
        log_action "SUCCESS: Full backup created — $backup_file ($backup_size)"
    else
        echo -e "  ${RED}✗ Backup failed!${NC}"
        log_action "FAILED: Full backup — tar command failed"
        return 1
    fi
}

# =============================================================================
# Function: config_backup
# Backs up only the Apache configuration directory
# =============================================================================
config_backup() {
    echo ""
    echo -e "${BOLD}── Configuration Backup ──${NC}"
    echo ""

    ensure_backup_dir

    if [ ! -d "$APACHE_CONF_DIR" ]; then
        echo -e "  ${RED}Error: Apache config directory not found: $APACHE_CONF_DIR${NC}"
        return 1
    fi

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="${BACKUP_DIR}/apache_config_${timestamp}.tar.gz"

    echo -e "  ${CYAN}Backing up: $APACHE_CONF_DIR${NC}"

    if tar -czpf "$backup_file" "$APACHE_CONF_DIR" 2>/dev/null; then
        local backup_size
        backup_size=$(du -h "$backup_file" | awk '{print $1}')
        echo -e "  ${GREEN}✓ Config backup created!${NC}"
        echo -e "  ${CYAN}File:${NC} $backup_file ($backup_size)"
        log_action "SUCCESS: Config backup — $backup_file ($backup_size)"
    else
        echo -e "  ${RED}✗ Config backup failed!${NC}"
        log_action "FAILED: Config backup"
        return 1
    fi
}

# =============================================================================
# Function: sites_backup
# Backs up only the web data (document roots)
# =============================================================================
sites_backup() {
    echo ""
    echo -e "${BOLD}── Sites/Web Data Backup ──${NC}"
    echo ""

    ensure_backup_dir

    if [ ! -d "$WEB_ROOT" ]; then
        echo -e "  ${RED}Error: Web root not found: $WEB_ROOT${NC}"
        return 1
    fi

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="${BACKUP_DIR}/apache_sites_${timestamp}.tar.gz"

    # Show size of data being backed up
    local data_size
    data_size=$(du -sh "$WEB_ROOT" 2>/dev/null | awk '{print $1}')
    echo -e "  ${CYAN}Backing up: $WEB_ROOT ($data_size)${NC}"

    if tar -czpf "$backup_file" "$WEB_ROOT" 2>/dev/null; then
        local backup_size
        backup_size=$(du -h "$backup_file" | awk '{print $1}')
        echo -e "  ${GREEN}✓ Sites backup created!${NC}"
        echo -e "  ${CYAN}File:${NC} $backup_file ($backup_size)"
        log_action "SUCCESS: Sites backup — $backup_file ($backup_size)"
    else
        echo -e "  ${RED}✗ Sites backup failed!${NC}"
        log_action "FAILED: Sites backup"
        return 1
    fi
}

# =============================================================================
# Function: restore_backup
# Restores Apache configuration and/or data from a selected backup
# IMPORTANT: Creates a safety backup before restoring
# =============================================================================
restore_backup() {
    echo ""
    echo -e "${BOLD}── Restore from Backup ──${NC}"
    echo ""

    # Show available backups
    list_backups

    echo ""
    read -r -p "  Enter the FULL path of the backup file to restore: " backup_path

    # Validate the backup file exists
    if [ -z "$backup_path" ] || [ ! -f "$backup_path" ]; then
        echo -e "  ${RED}Error: Backup file not found: $backup_path${NC}"
        return 1
    fi

    # Verify it's a valid tar.gz file
    if ! file "$backup_path" 2>/dev/null | grep -qi "gzip\|tar"; then
        echo -e "  ${RED}Error: File does not appear to be a valid backup archive.${NC}"
        return 1
    fi

    # Show contents of the backup before restoring
    echo ""
    echo -e "  ${BOLD}Backup contents:${NC}"
    tar -tzf "$backup_path" 2>/dev/null | head -20
    echo "  ..."
    echo ""

    # Safety warning
    echo -e "  ${RED}WARNING: Restoring will OVERWRITE existing files!${NC}"
    echo -e "  ${YELLOW}A safety backup will be created first.${NC}"
    read -r -p "  Proceed with restore? (type 'yes'): " confirm

    if [ "$confirm" != "yes" ]; then
        echo -e "  ${YELLOW}Restore cancelled.${NC}"
        return 0
    fi

    # Create a safety backup before restoring
    echo -e "  ${CYAN}Creating safety backup...${NC}"
    local safety_file="${BACKUP_DIR}/safety_pre_restore_$(date '+%Y%m%d_%H%M%S').tar.gz"
    local safety_dirs=""
    [ -d "$APACHE_CONF_DIR" ] && safety_dirs="$APACHE_CONF_DIR"
    [ -d "$WEB_ROOT" ] && safety_dirs="$safety_dirs $WEB_ROOT"

    if [ -n "$safety_dirs" ]; then
        tar -czpf "$safety_file" $safety_dirs 2>/dev/null
        echo -e "  ${GREEN}✓ Safety backup: $safety_file${NC}"
        log_action "Created safety backup before restore: $safety_file"
    fi

    # Perform the restore by extracting the archive to root (/)
    # The archive contains absolute paths, so extracting to / restores to original locations
    echo -e "  ${CYAN}Restoring from backup...${NC}"
    if tar -xzpf "$backup_path" -C / 2>/dev/null; then
        echo -e "  ${GREEN}✓ Restore completed successfully!${NC}"
        log_action "SUCCESS: Restored from $backup_path"

        # Offer to reload Apache to apply restored config
        read -r -p "  Reload Apache to apply changes? (y/n): " reload
        if [ "$reload" = "y" ] || [ "$reload" = "Y" ]; then
            # Test config first
            if apache2ctl configtest 2>/dev/null; then
                systemctl reload apache2 2>/dev/null
                echo -e "  ${GREEN}✓ Apache reloaded.${NC}"
            else
                echo -e "  ${RED}Config test failed! Apache NOT reloaded.${NC}"
                echo -e "  ${YELLOW}Review configuration before reloading manually.${NC}"
            fi
        fi
    else
        echo -e "  ${RED}✗ Restore failed!${NC}"
        log_action "FAILED: Restore from $backup_path"
        return 1
    fi
}

# =============================================================================
# Function: list_backups
# Displays all available backups with size and date information
# Uses: for loop, stat, du, file system operations
# =============================================================================
list_backups() {
    echo ""
    echo -e "${BOLD}── Available Backups ──${NC}"
    echo ""

    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "  ${YELLOW}No backup directory found. No backups exist yet.${NC}"
        return 0
    fi

    # Count backup files
    local count
    count=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f 2>/dev/null | wc -l)

    if [ "$count" -eq 0 ]; then
        echo -e "  ${YELLOW}No backups found in $BACKUP_DIR${NC}"
        return 0
    fi

    echo -e "  ${BOLD}Type        Size      Date                 Filename${NC}"
    echo -e "  ──────────────────────────────────────────────────────────────"

    # Loop through all backup files and display info
    for backup in "$BACKUP_DIR"/*.tar.gz; do
        if [ ! -f "$backup" ]; then
            continue
        fi

        local filename
        filename=$(basename "$backup")
        local file_size
        file_size=$(du -h "$backup" | awk '{print $1}')
        local file_date
        file_date=$(stat -c '%y' "$backup" 2>/dev/null | cut -d'.' -f1)

        # Determine backup type from filename prefix
        local backup_type=""
        case "$filename" in
            apache_full_*)    backup_type="[FULL]   ";;
            apache_config_*)  backup_type="[CONFIG] ";;
            apache_sites_*)   backup_type="[SITES]  ";;
            safety_*)         backup_type="[SAFETY] ";;
            *)                backup_type="[OTHER]  ";;
        esac

        printf "  %-11s %-9s %-20s %s\n" "$backup_type" "$file_size" "$file_date" "$filename"
    done

    echo ""
    echo -e "  Total backups: ${BOLD}$count${NC}"
    echo -e "  Backup directory: $BACKUP_DIR"

    # Show total disk usage of backups
    local total_size
    total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | awk '{print $1}')
    echo -e "  Total backup size: ${BOLD}$total_size${NC}"
}

# =============================================================================
# Function: cleanup_backups
# Removes old backups, keeping only the most recent MAX_BACKUPS
# Uses: sort, tail, while loop, rm
# =============================================================================
cleanup_backups() {
    echo ""
    echo -e "${BOLD}── Cleanup Old Backups ──${NC}"
    echo ""

    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "  ${YELLOW}No backup directory found.${NC}"
        return 0
    fi

    local count
    count=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f 2>/dev/null | wc -l)

    echo -e "  Current backups: ${BOLD}$count${NC}"
    echo -e "  Retention limit: ${BOLD}$MAX_BACKUPS${NC}"

    if [ "$count" -le "$MAX_BACKUPS" ]; then
        echo -e "  ${GREEN}No cleanup needed — within retention limit.${NC}"
        return 0
    fi

    # Calculate how many to delete
    local to_delete=$((count - MAX_BACKUPS))
    echo -e "  ${YELLOW}Will delete $to_delete oldest backup(s).${NC}"
    read -r -p "  Proceed? (y/n): " confirm

    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "  ${YELLOW}Cancelled.${NC}"
        return 0
    fi

    # Sort by modification time (oldest first) and delete excess
    local deleted=0
    find "$BACKUP_DIR" -name "*.tar.gz" -type f -printf '%T@ %p\n' 2>/dev/null \
        | sort -n \
        | head -n "$to_delete" \
        | while read -r _ filepath; do
            rm -f "$filepath"
            echo -e "  ${RED}Deleted:${NC} $(basename "$filepath")"
            log_action "Cleanup: Deleted old backup $(basename "$filepath")"
            deleted=$((deleted + 1))
        done

    echo ""
    echo -e "  ${GREEN}✓ Cleanup complete.${NC}"
    log_action "Cleanup: Removed $to_delete old backup(s)"
}

# =============================================================================
# Function: view_log
# Displays the backup activity log
# =============================================================================
view_log() {
    echo ""
    echo -e "${BOLD}── Backup Activity Log ──${NC}"
    echo ""

    if [ ! -f "$LOG_FILE" ]; then
        echo -e "  ${YELLOW}No log file found. No operations performed yet.${NC}"
        return 0
    fi

    # Show the last 20 log entries
    echo -e "  ${CYAN}Last 20 entries:${NC}"
    echo ""
    tail -20 "$LOG_FILE" | while IFS= read -r line; do
        # Color-code based on content
        if echo "$line" | grep -q "SUCCESS"; then
            echo -e "  ${GREEN}$line${NC}"
        elif echo "$line" | grep -q "FAILED"; then
            echo -e "  ${RED}$line${NC}"
        else
            echo -e "  $line"
        fi
    done

    echo ""
    local total_entries
    total_entries=$(wc -l < "$LOG_FILE" 2>/dev/null)
    echo -e "  ${CYAN}Total log entries: $total_entries${NC}"
    echo -e "  ${CYAN}Log file: $LOG_FILE${NC}"
}

# =============================================================================
# MAIN EXECUTION
# Menu loop using while + case
# =============================================================================
main() {
    check_root

    while true; do
        print_banner
        show_menu
        read -r choice

        case "$choice" in
            1)
                full_backup
                ;;
            2)
                config_backup
                ;;
            3)
                sites_backup
                ;;
            4)
                restore_backup
                ;;
            5)
                list_backups
                ;;
            6)
                cleanup_backups
                ;;
            7)
                view_log
                ;;
            0)
                echo ""
                echo -e "  ${GREEN}Goodbye!${NC}"
                log_action "Session ended"
                echo ""
                exit 0
                ;;
            *)
                echo ""
                echo -e "  ${RED}Invalid option. Please select 0-7.${NC}"
                ;;
        esac

        echo ""
        read -r -p "  Press Enter to continue..."
    done
}

# Entry point
main
