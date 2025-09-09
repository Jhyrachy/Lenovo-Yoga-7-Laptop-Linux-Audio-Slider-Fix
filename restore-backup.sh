#!/bin/bash

# Lenovo 14IRH8 Audio Fix - Restore Original Settings
# This script restores the original audio configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONFIG_DIR="$HOME/.config/wireplumber/wireplumber.conf.d"
CONFIG_FILE="$CONFIG_DIR/alsa-soft-mixer.conf"
BACKUP_DIR="$HOME/.config/lenovo-audio-fix-backup"

echo -e "${BLUE}Lenovo 14IRH8 Audio Fix - Restore${NC}"
echo "================================="
echo

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to restore configuration
restore_config() {
    if [ ! -d "$BACKUP_DIR" ]; then
        print_error "Backup directory not found: $BACKUP_DIR"
        print_status "It seems the audio fix was never applied, or backups were manually deleted."
        exit 1
    fi
    
    # Find the most recent backup
    local latest_backup
    latest_backup=$(ls -t "$BACKUP_DIR"/*.backup.* 2>/dev/null | head -1)
    
    if [ -n "$latest_backup" ]; then
        print_status "Restoring configuration from: $(basename "$latest_backup")"
        
        # Create config directory if it doesn't exist
        mkdir -p "$CONFIG_DIR"
        
        # Restore the backup
        cp "$latest_backup" "$CONFIG_FILE"
        print_status "Original configuration restored"
    else
        print_warning "No backup found, removing fix configuration file"
        
        if [ -f "$CONFIG_FILE" ]; then
            rm -f "$CONFIG_FILE"
            print_status "Fix configuration file removed"
            
            # Remove directory if empty
            if [ -d "$CONFIG_DIR" ] && [ -z "$(ls -A "$CONFIG_DIR")" ]; then
                rmdir "$CONFIG_DIR"
                print_status "Empty configuration directory removed"
            fi
        else
            print_warning "Fix configuration file doesn't exist"
        fi
    fi
}

# Function to restart pipewire
restart_pipewire() {
    print_status "Restarting pipewire..."
    
    if systemctl --user restart pipewire; then
        print_status "Pipewire restarted successfully"
    else
        print_error "Failed to restart pipewire"
        exit 1
    fi
}

# Function to cleanup backups (optional)
cleanup_backups() {
    echo
    read -p "Do you want to remove the backup directory? [y/N]: " cleanup
    
    if [[ $cleanup =~ ^[Yy]$ ]]; then
        rm -rf "$BACKUP_DIR"
        print_status "Backup directory removed"
    else
        print_status "Backup directory preserved: $BACKUP_DIR"
    fi
}

# Main execution
main() {
    echo "This script will restore the original audio configuration"
    echo "and undo the Lenovo 14IRH8 volume control fix."
    echo
    
    # Check if running on supported system
    if ! command -v systemctl &> /dev/null; then
        print_error "systemctl not found. This script requires systemd."
        exit 1
    fi
    
    # Show current status
    if [ -f "$CONFIG_FILE" ]; then
        print_status "Current fix configuration found: $CONFIG_FILE"
    else
        print_warning "No fix configuration found"
    fi
    
    if [ -d "$BACKUP_DIR" ]; then
        local backup_count
        backup_count=$(ls -1 "$BACKUP_DIR"/*.backup.* 2>/dev/null | wc -l)
        print_status "Found $backup_count backup(s) in: $BACKUP_DIR"
    else
        print_warning "No backup directory found"
    fi
    
    echo
    read -p "Continue with restore? [y/N]: " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
    
    # Restore configuration
    restore_config
    
    # Restart pipewire
    restart_pipewire
    
    # Optional cleanup
    cleanup_backups
    
    echo
    echo -e "${GREEN}✓ Audio configuration restored successfully!${NC}"
    echo
    print_status "Your audio settings have been returned to their original state."
    print_status "Test your audio volume control to verify the restoration."
}

# Run main function
main "$@"