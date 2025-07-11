# Steam Library Management Tools

A collection of bash scripts to manage Steam Library installations on Linux systems, particularly designed for Steam Deck users.

## 📦 Scripts Included

### 1. `scan_duplicate_games.sh` - Duplicate Game Scanner
Finds and manages duplicate game installations across multiple Steam Library locations.

### 2. `scan_orphaned_acf_files.sh` - Orphaned .acf File Scanner  
Finds and removes orphaned Steam app manifest files that have no corresponding game directories.

## 🎮 Overview

These scripts help you maintain a clean Steam library by addressing two common issues:

### Duplicate Game Installations
The duplicate scanner finds games installed in multiple locations:
- External storage devices (SD cards, USB drives)
- Internal storage
- Multiple Steam Library folders

### Orphaned Steam Library Entries
The orphaned .acf scanner finds Steam app manifest files that reference non-existent game directories, which can accumulate after:
- Manual deletion of game folders
- Steam library inconsistencies
- Failed installations or updates

## ✨ Features

### Duplicate Game Scanner (`scan_duplicate_games.sh`)
- **Multi-location scanning**: Automatically detects and scans all mounted external storage devices
- **Size calculation**: Shows folder sizes for each duplicate installation (can be disabled for faster scanning)
- **Interactive deletion**: Option to interactively delete duplicate installations
- **Comprehensive coverage**: Scans both `/run/media/deck` and `/media` directories for external storage
- **Steam Deck optimized**: Designed specifically for Steam Deck's storage structure
- **Safe operation**: Non-destructive by default, requires explicit deletion mode
- **Steam library cleanup**: Properly removes both game folders and corresponding .acf files

### Orphaned .acf File Scanner (`scan_orphaned_acf_files.sh`)
- **Smart detection**: Finds .acf files with no corresponding game directories
- **Streamlined operation**: Processes files immediately without storing in memory
- **Interactive cleanup**: Option to interactively delete orphaned manifest files
- **Comprehensive scanning**: Covers all Steam Library locations (internal and external)
- **Safe operation**: Non-destructive by default, requires explicit deletion mode
- **Memory efficient**: No large arrays, processes files as they're found

## 🚀 Usage

### Duplicate Game Scanner

#### Basic Scan
```bash
./scan_duplicate_games.sh
```
Scans for duplicates and displays results with folder sizes.

#### Fast Scan (No Size Calculation)
```bash
./scan_duplicate_games.sh -no-sizes
```
Faster scanning by skipping folder size calculations.

#### Interactive Deletion Mode
```bash
./scan_duplicate_games.sh -delete
```
Enables interactive mode to delete duplicate installations.

#### Combined Options
```bash
./scan_duplicate_games.sh -delete -no-sizes
```
Interactive deletion mode with fast scanning.

### Orphaned .acf File Scanner

#### Basic Scan
```bash
./scan_orphaned_acf_files.sh
```
Scans for orphaned .acf files and displays results.

#### Interactive Deletion Mode
```bash
./scan_orphaned_acf_files.sh -delete
```
Enables interactive mode to delete orphaned .acf files.

## 📋 Requirements

- **Operating System**: Linux (tested on Steam Deck)
- **Shell**: Bash
- **Dependencies**: 
  - `find` (usually pre-installed)
  - `du` (for size calculation)
  - `tr`, `wc` (for text processing)

## 🔍 How It Works

1. **Disk Detection**: Automatically finds all mounted external storage devices
2. **Steam Library Scanning**: Searches for Steam Library folders in `steamapps/common` directories
3. **Duplicate Detection**: Compares game names across all locations
4. **Size Calculation**: Calculates folder sizes for each installation (optional)
5. **Interactive Management**: Allows selective deletion of duplicates

### Scanned Locations

- **External Storage**: `/run/media/deck/*/steamapps/common`
- **Media Mounts**: `/media/*/steamapps/common`
- **Internal Storage**: `/home/deck/.local/share/Steam/steamapps/common`

## 📊 Output Examples

### Duplicate Game Scanner Output
```
Scanning for duplicate game installations across disks and internal storage...
==========================================================================
Found 2 disk(s):
  - /run/media/deck/SteamDeckSD
  - /media/usb-drive

Scanning external disk: SteamDeckSD (at /run/media/deck/SteamDeckSD)
Scanning external disk: usb-drive (at /media/usb-drive)
Scanning internal storage: /home/deck/.local/share/Steam/

Results:
========
DUPLICATE: 'Cyberpunk 2077' found on 2 disk(s): (SteamDeckSD) - 67G, (internal) - 67G
DUPLICATE: 'Red Dead Redemption 2' found on 3 disk(s): (SteamDeckSD) - 120G, (usb-drive) - 120G, (internal) - 120G
```

### Orphaned .acf File Scanner Output
```
Scanning for orphaned Steam .acf files...
=========================================
Found 2 disk(s):
  - /run/media/deck/SteamDeckSD
  - /media/usb-drive

Scanning SteamDeckSD: /run/media/deck/SteamDeckSD/steamapps
Scanning internal storage: /home/deck/.local/share/Steam/steamapps

ORPHANED: 'Cyberpunk 2077' (App ID: 1091500) on SteamDeckSD
  File: /run/media/deck/SteamDeckSD/steamapps/appmanifest_1091500.acf

Would you like to delete this orphaned .acf file?
  (1) Delete
  (0) Skip

Enter your choice (0-1):
```

## ⚠️ Safety Notes

- **Backup First**: Always backup important data before running deletion operations
- **Steam Integration**: This script only manages files, not Steam library entries
- **Manual Verification**: Verify game functionality after deletion
- **Steam Library**: You may need to re-add games to Steam if library entries are affected

## 🛠️ Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/ScanDuplicateSteamGames.git
   cd ScanDuplicateSteamGames
   ```

2. **Make scripts executable**:
   ```bash
   chmod +x scan_duplicate_games.sh scan_orphaned_acf_files.sh
   ```

3. **Run the scripts**:
   ```bash
   # Scan for duplicate games
   ./scan_duplicate_games.sh
   
   # Scan for orphaned .acf files
   ./scan_orphaned_acf_files.sh
   ```

## 🔧 Troubleshooting

### No External Disks Found
- Ensure your external storage is properly mounted
- Check if disks are mounted under `/run/media/deck` or `/media`
- Verify Steam Library folders exist in `steamapps/common`

### Permission Denied
- Ensure the scripts have execute permissions: `chmod +x scan_duplicate_games.sh scan_orphaned_acf_files.sh`
- Run with appropriate permissions for the directories you're scanning

### Steam Library Not Found
- Verify Steam is installed in the default location
- Check if the Steam Library folder structure is correct

### Orphaned .acf Files Not Found
- This is normal if your Steam library is clean
- Orphaned files typically accumulate over time after manual deletions
- The scanner will show "No orphaned .acf files found" if everything is clean

## 📝 License

This project is open source and available under the [MIT License](LICENSE).


## 🔄 Recommended Workflow

1. **First, scan for duplicates** to free up storage space:
   ```bash
   ./scan_duplicate_games.sh -delete
   ```

2. **Then, clean up orphaned entries** to maintain Steam library consistency:
   ```bash
   ./scan_orphaned_acf_files.sh -delete
   ```

3. **Run both scans periodically** to keep your Steam library clean and organized.

**Note**: These scripts are designed for Steam Deck and Linux systems. Use with caution on other platforms. 