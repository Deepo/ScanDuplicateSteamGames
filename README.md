# Steam Duplicate Game Scanner

A bash script to find and manage duplicate game installations across multiple Steam Library locations on Linux systems, particularly designed for Steam Deck users.

## 🎮 Overview

This script scans for duplicate game installations across:
- External storage devices (SD cards, USB drives)
- Internal storage
- Multiple Steam Library folders

It helps you identify and optionally remove duplicate game installations to save storage space and maintain a clean Steam library.

## ✨ Features

- **Multi-location scanning**: Automatically detects and scans all mounted external storage devices
- **Size calculation**: Shows folder sizes for each duplicate installation (can be disabled for faster scanning)
- **Interactive deletion**: Option to interactively delete duplicate installations
- **Comprehensive coverage**: Scans both `/run/media/deck` and `/media` directories for external storage
- **Steam Deck optimized**: Designed specifically for Steam Deck's storage structure
- **Safe operation**: Non-destructive by default, requires explicit deletion mode

## 🚀 Usage

### Basic Scan
```bash
./scan_duplicate_games.sh
```
Scans for duplicates and displays results with folder sizes.

### Fast Scan (No Size Calculation)
```bash
./scan_duplicate_games.sh -no-sizes
```
Faster scanning by skipping folder size calculations.

### Interactive Deletion Mode
```bash
./scan_duplicate_games.sh -delete
```
Enables interactive mode to delete duplicate installations.

### Combined Options
```bash
./scan_duplicate_games.sh -delete -no-sizes
```
Interactive deletion mode with fast scanning.

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

## 📊 Output Example

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

## ⚠️ Safety Notes

- **Backup First**: Always backup important data before running deletion operations
- **Steam Integration**: This script only manages files, not Steam library entries
- **Manual Verification**: Verify game functionality after deletion
- **Steam Library**: You may need to re-add games to Steam if library entries are affected

## 🛠️ Installation

1. **Download the script**:
   ```bash
   wget https://raw.githubusercontent.com/Deepo/ScanDuplicateSteamGames/main/scan_duplicate_games.sh
   ```

2. **Make it executable**:
   ```bash
   chmod +x scan_duplicate_games.sh
   ```

3. **Run the script**:
   ```bash
   ./scan_duplicate_games.sh
   ```

## 🔧 Troubleshooting

### No External Disks Found
- Ensure your external storage is properly mounted
- Check if disks are mounted under `/run/media/deck` or `/media`
- Verify Steam Library folders exist in `steamapps/common`

### Permission Denied
- Ensure the script has execute permissions: `chmod +x scan_duplicate_games.sh`
- Run with appropriate permissions for the directories you're scanning

### Steam Library Not Found
- Verify Steam is installed in the default location
- Check if the Steam Library folder structure is correct

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## ⚡ Performance Tips

- Use `-no-sizes` flag for faster scanning on systems with many games
- Run during low-activity periods for better performance
- Consider running on SSD storage for faster I/O operations

**Note**: This script is designed for Steam Deck and Linux systems. Use with caution on other platforms. 