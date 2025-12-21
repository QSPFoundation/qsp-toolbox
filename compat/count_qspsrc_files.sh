#!/bin/bash
#
# Script to recursively scan directories and count .qspsrc files
#

# Check if directory argument is provided
if [ "$#" -gt 1 ]; then
    echo "Usage: $0 [start_directory]"
    echo ""
    echo "Arguments:"
    echo "  start_directory - Optional. Directory to start scanning (default: current directory)"
    echo ""
    echo "Example: $0 /path/to/games"
    echo "Example: $0"
    echo ""
    echo "Recursively scans directories and shows count of .qspsrc files."
    exit 1
fi

START_DIR="${1:-.}"

# Check if directory exists
if [ ! -d "$START_DIR" ]; then
    echo "Error: Directory not found: $START_DIR"
    exit 1
fi

# Convert to absolute path
START_DIR=$(cd "$START_DIR" && pwd)

echo "Scanning directories for .qspsrc files..."
echo "Starting directory: $START_DIR"
echo "=========================================="
echo ""

# Initialize counters
total_directories=0
total_files=0
directories_with_files=0

# Find all directories and count .qspsrc files in each (recursively)
while IFS= read -r dir; do
    ((total_directories++))
    
    # Count .qspsrc files recursively in this directory and all subdirectories
    count=$(find "$dir" -type f -iname "*.qspsrc" 2>/dev/null | wc -l)
    
    if [ "$count" -gt 0 ]; then
        ((directories_with_files++))
        ((total_files += count))
        echo "$dir: $count"
    fi
done < <(find "$START_DIR" -type d | sort)

echo ""
echo "=========================================="
echo "Scan complete."
echo "=========================================="
