#!/usr/bin/env bash

set -euo pipefail

# Configuration
BACKUP_ROOT="/mnt/data/backups/docker-compose-nas"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_PREFIX="docker-compose-nas"
DAILY_RETENTION=30
MONTHLY_RETENTION=12

# Ensure backup directory exists
mkdir -p "$BACKUP_ROOT/daily" "$BACKUP_ROOT/monthly"

# Function to create a backup
create_backup() {
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_ROOT/daily/${BACKUP_PREFIX}_${timestamp}.tar.gz"
    
    echo "Creating backup: $backup_file"
    tar -czf "$backup_file" \
        -C "$SOURCE_DIR" \
        --exclude="*.tar.gz" \
        --exclude="*/downloads" \
        --exclude="*/cache" \
        --exclude="*/logs" \
        --exclude="*/metadata" \
        --exclude="*/ipc-socket" \
        .
    
    # Set permissions so non-root user can manage the backup
    chown "$USER:$USER" "$backup_file"
    
    echo "Backup created successfully"
}

# Function to rotate backups
rotate_backups() {
    echo "Rotating backups..."
    
    # Move oldest daily backup to monthly if it's the first of the month
    if [[ $(date +%d) == "01" ]]; then
        local oldest_daily
        oldest_daily=$(ls -t "$BACKUP_ROOT/daily"/*.tar.gz 2>/dev/null | tail -n 1)
        if [[ -n "$oldest_daily" ]]; then
            mv "$oldest_daily" "$BACKUP_ROOT/monthly/"
            echo "Moved oldest daily backup to monthly storage"
        fi
    fi
    
    # Remove daily backups older than DAILY_RETENTION days
    find "$BACKUP_ROOT/daily" -name "*.tar.gz" -type f -mtime +"$DAILY_RETENTION" -delete
    
    # Keep only last MONTHLY_RETENTION monthly backups
    local monthly_count
    monthly_count=$(ls -1 "$BACKUP_ROOT/monthly"/*.tar.gz 2>/dev/null | wc -l)
    if [[ $monthly_count -gt $MONTHLY_RETENTION ]]; then
        ls -t "$BACKUP_ROOT/monthly"/*.tar.gz | tail -n +"$((MONTHLY_RETENTION + 1))" | xargs rm -f
    fi
}

# Function to list all backups
list_backups() {
    echo "Available backups:"
    echo "Daily backups:"
    ls -lht "$BACKUP_ROOT/daily" 2>/dev/null || echo "No daily backups found"
    echo -e "\nMonthly backups:"
    ls -lht "$BACKUP_ROOT/monthly" 2>/dev/null || echo "No monthly backups found"
}

# Function to restore a backup
restore_backup() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        echo "Error: Backup file not found: $backup_file"
        exit 1
    fi
    
    # Create a backup before restoring
    echo "Creating backup before restore..."
    create_backup
    
    echo "Restoring from backup: $backup_file"
    tar -xzf "$backup_file" -C "$SOURCE_DIR"
    echo "Restore completed successfully"
}

# Function to install cron job
install_cron() {
    local script_path
    script_path=$(readlink -f "$0")
    local cron_cmd="0 2 * * * $script_path backup >/dev/null 2>&1"
    
    # Get existing crontab without our backup command
    local existing_crontab
    existing_crontab=$(sudo crontab -l 2>/dev/null | grep -v "$script_path" || true)
    
    # Combine existing crontab with our backup command
    printf '%s\n%s\n' "$existing_crontab" "$cron_cmd" | sudo crontab -
    
    echo "Cron job updated successfully in root's crontab"
}

# Main logic
case "${1:-}" in
    "backup")
        create_backup
        rotate_backups
        ;;
    "list")
        list_backups
        ;;
    "restore")
        if [[ -z "${2:-}" ]]; then
            echo "Usage: $0 restore <backup_file>"
            list_backups
            exit 1
        fi
        restore_backup "$2"
        ;;
    "install")
        install_cron
        ;;
    *)
        echo "Usage: $0 {backup|list|restore <backup_file>|install}"
        echo "  backup  - Create a new backup"
        echo "  list    - List available backups"
        echo "  restore - Restore from a backup file"
        echo "  install - Install cron job for daily backups"
        exit 1
        ;;
esac


