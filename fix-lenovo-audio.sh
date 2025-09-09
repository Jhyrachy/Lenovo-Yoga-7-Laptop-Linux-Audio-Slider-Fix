#!/bin/bash

# Lenovo 14IRH8 Audio Volume Control Fix
# This script fixes the common issue where audio volume control goes directly from 0% to 100%
# Source: https://askubuntu.com/questions/1487563/built-in-speakers-volume-control-not-working-it-is-either-mute-or-too-loud

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

echo -e "${BLUE}Lenovo 14IRH8 Audio Volume Control Fix${NC}"
echo "======================================"
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

# Function to detect audio device
detect_audio_device() {
    print_status "Detecting audio devices..."
    
    # Check if wpctl is available
    if ! command -v wpctl &> /dev/null; then
        print_error "wpctl not found. Please install pipewire-utils or wireplumber."
        exit 1
    fi
    
    # Get audio sinks
    echo -e "\n${BLUE}Available audio sinks:${NC}"
    wpctl status | sed -n '/├─ Sinks:/,/├─ Sources:/p' | grep -E "[│ ]*[*]?[ ]*[0-9]+" | head -10 || true
    
    echo
    read -p "Do you want to use the recommended wildcard pattern (y) or try experimental auto-detection (n)? [Y/n]: " choice
    
    if [[ $choice =~ ^[Nn]$ ]]; then
        # EXPERIMENTAL: Try to auto-detect the main speaker sink (marked with *)
        print_warning "EXPERIMENTAL: Attempting auto-detection..."
        print_status "Looking for default speaker sink (marked with *)..."
        local sink_id
        sink_id=$(wpctl status | sed -n '/├─ Sinks:/,/├─ Sources:/p' | grep -E "[│ ]*\*[ ]*[0-9]+" | sed 's/.*\*[ ]*\([0-9]\+\)\..*/\1/' | head -1)
        
        if [ -z "$sink_id" ]; then
            print_status "No default sink found, looking for any speaker sink..."
            # Fallback: get the first speaker-like sink
            sink_id=$(wpctl status | sed -n '/├─ Sinks:/,/├─ Sources:/p' | grep -i "speaker" | sed 's/.*[ ]\([0-9]\+\)\..*/\1/' | head -1)
        fi
        
        if [ -n "$sink_id" ]; then
            print_status "Found speaker sink ID: $sink_id"
            print_status "Inspecting sink $sink_id to get device name..."
            
            # Get the node.name which is the actual device name WirePlumber uses
            local device_name
            device_name=$(wpctl inspect "$sink_id" 2>/dev/null | grep "node.name" | sed 's/.*node.name = "\([^"]*\)".*/\1/')
            
            if [ -n "$device_name" ]; then
                print_status "Auto-detected device name: $device_name"
                echo "$device_name" > /tmp/device_name_result
                return
            else
                print_warning "Could not extract device name from sink $sink_id"
                print_status "wpctl inspect output for debugging:"
                wpctl inspect "$sink_id" | grep -E "(node\.name|device\.name)" | head -3 || true
            fi
        else
            print_warning "Could not find any speaker sink"
        fi
        
        # Fallback to wildcard
        print_warning "Auto-detection failed, using wildcard pattern"
        echo "~alsa_card.*" > /tmp/device_name_result
    else
        # Use the recommended wildcard approach
        print_status "Using recommended wildcard pattern (applies to all ALSA audio devices)"
        echo "~alsa_card.*" > /tmp/device_name_result
    fi
    
    # Manual device entry option (for advanced users)
    echo
    read -p "Or enter a specific device name manually? [leave empty to continue]: " manual_device
    if [ -n "$manual_device" ]; then
        echo "$manual_device" > /tmp/device_name_result
    fi
}

# Function to create backup
create_backup() {
    print_status "Creating backup..."
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Backup existing config if it exists
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$BACKUP_DIR/alsa-soft-mixer.conf.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "Existing configuration backed up"
    fi
    
    # Create restore script
    cat > "$BACKUP_DIR/restore.sh" << 'EOF'
#!/bin/bash
# Restore script for Lenovo audio fix

BACKUP_DIR="$HOME/.config/lenovo-audio-fix-backup"
CONFIG_FILE="$HOME/.config/wireplumber/wireplumber.conf.d/alsa-soft-mixer.conf"

echo "Restoring audio configuration..."

# Find the most recent backup
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.backup.* 2>/dev/null | head -1)

if [ -n "$LATEST_BACKUP" ]; then
    cp "$LATEST_BACKUP" "$CONFIG_FILE"
    echo "Configuration restored from: $LATEST_BACKUP"
else
    # Remove the config file if no backup exists
    rm -f "$CONFIG_FILE"
    echo "Configuration file removed (no previous backup found)"
fi

# Restart pipewire
systemctl --user restart pipewire
echo "Pipewire restarted"
echo "Audio configuration restored!"
EOF
    
    chmod +x "$BACKUP_DIR/restore.sh"
}

# Function to create wireplumber config
create_config() {
    local device_name="$1"
    
    print_status "Creating wireplumber configuration..."
    
    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"
    
    # Determine which field to use based on the device name format
    local match_field
    if [[ "$device_name" == "~alsa_card.*" ]]; then
        match_field="device.name"
    else
        match_field="node.name"
    fi
    
    # Create the configuration file
    cat > "$CONFIG_FILE" << EOF
monitor.alsa.rules = [
  {
    matches = [
      {
        $match_field = "$device_name"
      }
    ]
    actions = {
      update-props = {
        # Do not use the hardware mixer for volume control. It
        # will only use software volume. The mixer is still used
        # to mute unused paths based on the selected port.
        api.alsa.soft-mixer = true
      }
    }
  }
]
EOF
    
    print_status "Configuration file created: $CONFIG_FILE"
    print_status "Using match field: $match_field"
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

# Main execution
main() {
    echo "This script will fix the Lenovo 14IRH8 audio volume control issue"
    echo "where volume jumps directly from 0% to 100%."
    echo
    
    # Check if running on supported system
    if ! command -v systemctl &> /dev/null; then
        print_error "systemctl not found. This script requires systemd."
        exit 1
    fi
    
    # Detect device
    detect_audio_device
    device_name=$(cat /tmp/device_name_result)
    rm -f /tmp/device_name_result
    
    echo
    print_status "Using device name: $device_name"
    echo
    
    read -p "Continue with the fix? [y/N]: " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
    
    # Create backup
    create_backup
    
    # Create configuration
    create_config "$device_name"
    
    # Restart pipewire
    restart_pipewire
    
    echo
    echo -e "${GREEN}✓ Audio fix applied successfully!${NC}"
    echo
    print_status "What was done:"
    echo "  • Created backup in: $BACKUP_DIR"
    echo "  • Created config file: $CONFIG_FILE"
    echo "  • Restarted pipewire service"
    echo
    print_status "To restore original settings, run:"
    echo "  $BACKUP_DIR/restore.sh"
    echo
    print_status "Test your audio volume control now!"
    echo
    echo -e "${BLUE}Press Enter to exit...${NC}"
    read -p ""
}

# Run main function
main "$@"