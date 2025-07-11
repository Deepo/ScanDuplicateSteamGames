#!/bin/bash

# Script to find orphaned .acf files
# Looks for Steam app manifest files that have no corresponding game directory
# Scans Steam Library folders under /run/media/deck/*/steamapps and internal storage

# Parse command line arguments
DELETE_MODE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -delete)
            DELETE_MODE=true
            shift
            ;;
        -help|--help|-h)
            echo "Steam Orphaned .acf File Scanner"
            echo "================================="
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -delete     Interactive mode to delete orphaned .acf files"
            echo "  -help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Basic scan"
            echo "  $0 -delete            # Interactive deletion mode"
            echo ""
            echo "Description:"
            echo "  This script scans for orphaned Steam .acf files (app manifest files)"
            echo "  that have no corresponding game directory. These files can accumulate"
            echo "  after manual deletion of games or Steam library inconsistencies."
            echo ""
            echo "Note: Only .acf files with no corresponding game folder will be"
            echo "      considered orphaned. This script is safe to run."
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo "  -delete: Interactive mode to delete orphaned .acf files"
            echo "  -help: Show help message"
            echo ""
            echo "Run '$0 -help' for more information."
            exit 1
            ;;
    esac
done

# Function to check if a game directory exists for a given .acf file
check_game_directory_exists() {
    local acf_file="$1"
    local steamapps_dir="$2"
    
    # Extract the installdir value from the .acf file
    local installdir=$(grep -o '"installdir"[[:space:]]*"[^"]*"' "$acf_file" 2>/dev/null | cut -d'"' -f4)
    
    if [ -z "$installdir" ]; then
        return 1  # No installdir found, consider it orphaned
    fi
    
    # Check if the game directory exists
    [ -d "$steamapps_dir/common/$installdir" ]
}

echo "Scanning for orphaned Steam .acf files..."
echo "========================================="

# Find all mounted disks
declare -a all_disk_paths=()

# Add disks from /run/media/deck and /media
for base_path in "/run/media/deck" "/media"; do
    if [ -d "$base_path" ]; then
        while IFS= read -r -d '' disk; do
            all_disk_paths+=("$base_path/$disk")
        done < <(find "$base_path" -maxdepth 1 -mindepth 1 -type d -printf "%f\0" 2>/dev/null)
    fi
done

if [ ${#all_disk_paths[@]} -eq 0 ]; then
    echo "No external disks found. Scanning internal storage only..."
else
    echo "Found ${#all_disk_paths[@]} disk(s):"
    for path in "${all_disk_paths[@]}"; do
        echo "  - $path"
    done
fi
echo ""

# Function to scan a Steam Library for orphaned .acf files
scan_steam_library() {
    local steam_path="$1"
    local location_name="$2"
    
    if [ ! -d "$steam_path" ]; then
        return
    fi
    
    echo "Scanning $location_name: $steam_path"
    
    # Find all .acf files in this Steam Library
    for acf_file in "$steam_path"/*.acf; do
        if [ -f "$acf_file" ]; then
            # Check if this .acf file is orphaned
            if ! check_game_directory_exists "$acf_file" "$steam_path"; then
                # Extract information from the .acf file
                app_id=$(basename "$acf_file" .acf | sed 's/appmanifest_//')
                game_name=$(grep -o '"name"[[:space:]]*"[^"]*"' "$acf_file" 2>/dev/null | cut -d'"' -f4)
                installdir=$(grep -o '"installdir"[[:space:]]*"[^"]*"' "$acf_file" 2>/dev/null | cut -d'"' -f4)
                
                # Use installdir as game name if name is not available
                if [ -z "$game_name" ]; then
                    game_name="$installdir"
                fi
                
                # Process the orphaned file
                process_orphaned_file "$acf_file" "$location_name" "$app_id" "$game_name"
            fi
        fi
    done
}

# Function to process an orphaned .acf file
process_orphaned_file() {
    local acf_file="$1"
    local location="$2"
    local app_id="$3"
    local game_name="$4"
    
    echo "ORPHANED: '$game_name' (App ID: $app_id) on $location"
    echo "  File: $acf_file"
    
    # Handle interactive deletion if enabled
    if [ "$DELETE_MODE" = true ]; then
        echo ""
        echo "Would you like to delete this orphaned .acf file?"
        echo "  (1) Delete"
        echo "  (0) Skip"
        echo ""
        read -p "Enter your choice (0-1): " choice
        
        # Validate input
        if [[ "$choice" =~ ^[01]$ ]]; then
            if [ "$choice" -eq 1 ]; then
                echo "  Deleting orphaned .acf file: $acf_file"
                if rm -f "$acf_file"; then
                    echo "    ✓ Orphaned .acf file deleted successfully"
                else
                    echo "    ✗ Failed to delete orphaned .acf file"
                fi
            else
                echo "Skipped deletion of orphaned .acf file for '$game_name'"
            fi
        else
            echo "Invalid choice. Skipping deletion of orphaned .acf file for '$game_name'"
        fi
    fi
    
    echo ""
}

# Scan external disks
for disk_path in "${all_disk_paths[@]}"; do
    scan_steam_library "$disk_path/steamapps" "$(basename "$disk_path")"
done

# Scan internal storage
scan_steam_library "/home/deck/.local/share/Steam/steamapps" "internal storage"

echo ""
echo "Scan complete." 