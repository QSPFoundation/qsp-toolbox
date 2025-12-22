#!/bin/bash

# Configuration
SEARCH_DIR="$HOME/qsp/qsp_extract_games/games"
SIMPLE=0  # Set to 1 for SIMPLE mode (print only keywords, one per line)

# Check if a specific file is provided as argument
if [ "$#" -gt 1 ]; then
    echo "Usage: $0 [file.qspsrc]"
    echo ""
    echo "Arguments:"
    echo "  file.qspsrc - Optional. Process a specific file instead of scanning directory"
    echo ""
    echo "Example: $0"
    echo "Example: $0 /path/to/file.qspsrc"
    exit 1
fi

if [ "$#" -eq 1 ]; then
    # Process single file
    SINGLE_FILE="$1"
    
    if [ ! -f "$SINGLE_FILE" ]; then
        echo "Error: File not found: $SINGLE_FILE"
        exit 1
    fi
    
    echo "Checking for duplicate var names (plain vs \$/#/%-prefixed) in file..."
    echo "File: $SINGLE_FILE"
else
    # Process directory
    if [ ! -d "$SEARCH_DIR" ]; then
        echo "Error: Directory not found: $SEARCH_DIR"
        exit 1
    fi
    
    echo "Checking for duplicate var names (plain vs \$/#/%-prefixed) in QSPSRC files..."
    echo "Directory: $SEARCH_DIR"
fi

echo "=========================================="
echo ""

# Statistics
total_files=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine file list to process
if [ -n "$SINGLE_FILE" ]; then
    # Process single file
    file_list=("$SINGLE_FILE")
else
    # Search all .qspsrc files recursively
    mapfile -t file_list < <(find "$SEARCH_DIR" -type f -iname "*.qspsrc")
fi

# Process files
for file in "${file_list[@]}"; do
    ((total_files++))
    echo "Processing file: $file"
    gawk -v simple="$SIMPLE" -f "$SCRIPT_DIR/_find_same_keywords.awk" "$file"
done

# Summary
echo ""
echo "=========================================="
echo "Summary:"
echo "----------------------------------------"
echo "Total files searched: $total_files"
echo "=========================================="
