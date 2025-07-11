#!/bin/bash

# Script to find games installed on multiple disks
# Looks for Steam Library folders under /run/media/deck/*/steamapps/common
# Also checks internal storage at /home/deck/.local/share/Steam/

# Parse command line arguments
DELETE_MODE=false
SHOW_SIZES=true
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -delete)
            DELETE_MODE=true
            shift
            ;;
        -no-sizes)
            SHOW_SIZES=false
            shift
            ;;
        -dry-run)
            DRY_RUN=true
            shift
            ;;
        -help|--help|-h)
            echo "Steam Duplicate Game Scanner"
            echo "=========================="
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -delete     Interactive mode to delete duplicate folders"
            echo "  -no-sizes   Skip size calculation for faster scanning"
            echo "  -dry-run    Show what would be deleted without actually deleting"
            echo "  -help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Basic scan with size calculation"
            echo "  $0 -no-sizes          # Fast scan without size calculation"
            echo "  $0 -delete            # Interactive deletion mode"
            echo "  $0 -delete -no-sizes  # Interactive deletion with fast scanning"
            echo "  $0 -dry-run           # Show what would be deleted"
            echo ""
            echo "Description:"
            echo "  This script scans for duplicate game installations across multiple"
            echo "  Steam Library locations including external storage devices and"
            echo "  internal storage. It helps identify and optionally remove duplicate"
            echo "  game installations to save storage space."
            echo ""
            echo "Note: When deleting games, both the game folder and the corresponding"
            echo "      Steam .acf file will be removed to maintain Steam library consistency."
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo "  -delete: Interactive mode to delete duplicate folders"
            echo "  -no-sizes: Skip size calculation for faster scanning"
            echo "  -dry-run: Show what would be deleted without actually deleting"
            echo "  -help: Show help message"
            echo ""
            echo "Run '$0 -help' for more information."
            exit 1
            ;;
    esac
done

# Function to find the corresponding .acf file for a game
find_acf_file() {
    local game_folder="$1"
    local steamapps_dir="$2"
    
    # Look for .acf files in the steamapps directory
    for acf_file in "$steamapps_dir"/*.acf; do
        if [ -f "$acf_file" ]; then
            # Extract the installdir value from the .acf file
            local installdir=$(grep -o '"installdir"[[:space:]]*"[^"]*"' "$acf_file" | cut -d'"' -f4)
            
            # Check if the installdir matches our game folder name
            if [ "$installdir" = "$game_folder" ]; then
                echo "$acf_file"
                return 0
            fi
        fi
    done
    
    return 1
}

# Function to safely delete a game and its .acf file
delete_game_and_acf() {
    local game_path="$1"
    local game_name="$2"
    local location_name="$3"
    
    # Get the steamapps directory (parent of 'common')
    local steamapps_dir=$(dirname "$(dirname "$game_path")")
    local acf_file=""
    
    # Find the corresponding .acf file
    acf_file=$(find_acf_file "$game_name" "$steamapps_dir")
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would delete:"
        echo "    - Game folder: $game_path"
        if [ -n "$acf_file" ]; then
            echo "    - Steam .acf file: $acf_file"
        else
            echo "    - Steam .acf file: NOT FOUND (manual cleanup may be needed)"
        fi
    else
        echo "  Deleting game folder: $game_path"
        if rm -rf "$game_path"; then
            echo "    ✓ Game folder deleted successfully"
        else
            echo "    ✗ Failed to delete game folder"
            return 1
        fi
        
        if [ -n "$acf_file" ]; then
            echo "  Deleting Steam .acf file: $acf_file"
            if rm -f "$acf_file"; then
                echo "    ✓ Steam .acf file deleted successfully"
            else
                echo "    ✗ Failed to delete Steam .acf file"
                return 1
            fi
        else
            echo "  ⚠ Warning: No corresponding .acf file found for '$game_name'"
            echo "    You may need to manually remove this game from Steam library"
        fi
    fi
    
    return 0
}

echo "Scanning for duplicate game installations across disks and internal storage..."
echo "=========================================================================="

# Arrays to store all game names and their locations
declare -A game_locations
declare -A game_paths
declare -A game_sizes

# Find all mounted disks - check both /run/media/deck and /media for comprehensive coverage
declare -a all_disk_paths=()

# Add disks from /run/media/deck
if [ -d "/run/media/deck" ]; then
    while IFS= read -r -d '' disk; do
        all_disk_paths+=("/run/media/deck/$disk")
    done < <(find /run/media/deck -maxdepth 1 -mindepth 1 -type d -printf "%f\0" 2>/dev/null)
fi

# Add disks from /media
if [ -d "/media" ]; then
    while IFS= read -r -d '' disk; do
        all_disk_paths+=("/media/$disk")
    done < <(find /media -maxdepth 1 -mindepth 1 -type d -printf "%f\0" 2>/dev/null)
fi

if [ ${#all_disk_paths[@]} -eq 0 ]; then
    echo "No external disks found under /run/media/deck or /media"
    echo "Proceeding with internal storage scan only..."
else
    echo "Found ${#all_disk_paths[@]} disk(s):"
    for path in "${all_disk_paths[@]}"; do
        echo "  - $path"
    done
fi
echo ""

# Scan each external disk for Steam Library folders
for disk_path in "${all_disk_paths[@]}"; do
    steam_path="$disk_path/steamapps/common"
    
    if [ -d "$steam_path" ]; then
        disk_name=$(basename "$disk_path")
        echo "Scanning external disk: $disk_name (at $disk_path)"
        
        # Find all game folders in this Steam Library
        for game in "$steam_path"/*; do
            if [ -d "$game" ]; then
                game_name=$(basename "$game")
                
                # Calculate folder size only if needed
                if [ "$SHOW_SIZES" = true ]; then
                    folder_size=$(du -sh "$game" 2>/dev/null | cut -f1)
                else
                    folder_size="N/A"
                fi
                
                # Add this location to our tracking
                if [ -z "${game_locations[$game_name]}" ]; then
                    game_locations[$game_name]="$disk_name"
                    game_paths[$game_name]="$game"
                    game_sizes[$game_name]="$folder_size"
                else
                    game_locations[$game_name]="${game_locations[$game_name]}|$disk_name"
                    game_paths[$game_name]="${game_paths[$game_name]}|$game"
                    game_sizes[$game_name]="${game_sizes[$game_name]}|$folder_size"
                fi
            fi
        done
    fi
done

# Scan internal storage for Steam Library folders
internal_steam_path="/home/deck/.local/share/Steam/steamapps/common"

if [ -d "$internal_steam_path" ]; then
    echo "Scanning internal storage: /home/deck/.local/share/Steam/"
    
            # Find all game folders in internal Steam Library
        for game in "$internal_steam_path"/*; do
            if [ -d "$game" ]; then
                game_name=$(basename "$game")
                
                # Calculate folder size only if needed
                if [ "$SHOW_SIZES" = true ]; then
                    folder_size=$(du -sh "$game" 2>/dev/null | cut -f1)
                else
                    folder_size="N/A"
                fi
                
                # Add this location to our tracking
                if [ -z "${game_locations[$game_name]}" ]; then
                    game_locations[$game_name]="internal"
                    game_paths[$game_name]="$game"
                    game_sizes[$game_name]="$folder_size"
                else
                    game_locations[$game_name]="${game_locations[$game_name]}|internal"
                    game_paths[$game_name]="${game_paths[$game_name]}|$game"
                    game_sizes[$game_name]="${game_sizes[$game_name]}|$folder_size"
                fi
            fi
        done
else
    echo "Internal Steam folder not found at: $internal_steam_path"
fi

echo ""
echo "Results:"
echo "========"

# Check for duplicates
found_duplicates=false

for game_name in "${!game_locations[@]}"; do
    locations="${game_locations[$game_name]}"
    paths="${game_paths[$game_name]}"
    sizes="${game_sizes[$game_name]}"
    
    # Count how many disks this game is on
    disk_count=$(echo "$locations" | tr '|' '\n' | wc -l)
    
    if [ "$disk_count" -gt 1 ]; then
        # Split locations, paths, and sizes into arrays
        IFS='|' read -ra location_array <<< "$locations"
        IFS='|' read -ra path_array <<< "$paths"
        IFS='|' read -ra size_array <<< "$sizes"
        
        # Format the duplicate message with sizes
        duplicate_msg="DUPLICATE: '$game_name' found on $disk_count disk(s):"
        for i in "${!location_array[@]}"; do
            if [ $i -gt 0 ]; then
                duplicate_msg="$duplicate_msg,"
            fi
            if [ "${size_array[$i]}" = "N/A" ]; then
                duplicate_msg="$duplicate_msg (${location_array[$i]})"
            else
                duplicate_msg="$duplicate_msg (${location_array[$i]}) - ${size_array[$i]}"
            fi
        done
        echo "$duplicate_msg"
        
        found_duplicates=true
        
        # Handle dry-run mode
        if [ "$DRY_RUN" = true ]; then
            echo ""
            echo "  [DRY RUN] Would delete the following files:"
            for i in "${!location_array[@]}"; do
                echo "    - ${location_array[$i]}: ${path_array[$i]}"
                acf_file=$(find_acf_file "$game_name" "$(dirname "$(dirname "${path_array[$i]}")")")
                if [ -n "$acf_file" ]; then
                    echo "      + Steam .acf file: $acf_file"
                else
                    echo "      + Steam .acf file: NOT FOUND"
                fi
            done
            echo ""
        fi
        
        # Handle interactive deletion if enabled
        if [ "$DELETE_MODE" = true ]; then
            # Create working copies of arrays for this game
            current_locations=("${location_array[@]}")
            current_paths=("${path_array[@]}")
            current_sizes=("${size_array[@]}")
            
            # Continue until only one copy remains
            while [ ${#current_locations[@]} -gt 1 ]; do
                echo ""
                echo "Would you like to delete '$game_name' on disk:"
                for i in "${!current_locations[@]}"; do
                    if [ "${current_sizes[$i]}" = "N/A" ]; then
                        echo "  ($((i+1))) ${current_locations[$i]}"
                    else
                        echo "  ($((i+1))) ${current_locations[$i]} - ${current_sizes[$i]}"
                    fi
                done
                echo "  (0) Skip"
                echo ""
                read -p "Enter your choice (0-${#current_locations[@]}): " choice
                
                # Validate input
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "${#current_locations[@]}" ]; then
                    if [ "$choice" -gt 0 ]; then
                        selected_index=$((choice-1))
                        selected_path="${current_paths[$selected_index]}"
                        selected_location="${current_locations[$selected_index]}"
                        
                        echo "Deleting '$game_name' from $selected_location..."
                        if delete_game_and_acf "$selected_path" "$game_name" "$selected_location"; then
                            echo "Successfully deleted '$game_name' from $selected_location"
                            
                            # Remove the deleted location from arrays
                            unset current_locations[$selected_index]
                            unset current_paths[$selected_index]
                            unset current_sizes[$selected_index]
                            
                            # Reindex arrays
                            current_locations=("${current_locations[@]}")
                            current_paths=("${current_paths[@]}")
                            current_sizes=("${current_sizes[@]}")
                            
                            # If more than one copy remains, show updated status
                            if [ ${#current_locations[@]} -gt 1 ]; then
                                echo ""
                                echo "DUPLICATE: '$game_name' found on ${#current_locations[@]} disk(s):"
                                for i in "${!current_locations[@]}"; do
                                    if [ $i -gt 0 ]; then
                                        echo -n ", "
                                    fi
                                    if [ "${current_sizes[$i]}" = "N/A" ]; then
                                        echo -n "(${current_locations[$i]})"
                                    else
                                        echo -n "(${current_locations[$i]}) - ${current_sizes[$i]}"
                                    fi
                                done
                                echo ""
                            fi
                        else
                            echo "Failed to delete '$game_name' from $selected_location"
                        fi
                    else
                        echo "Skipped deletion of '$game_name'"
                        break
                    fi
                else
                    echo "Invalid choice. Skipping deletion of '$game_name'"
                    break
                fi
            done
            echo ""
        fi
    fi
done

if [ "$found_duplicates" = false ]; then
    echo "No duplicate game installations found."
fi

echo ""
echo "Scan complete." 