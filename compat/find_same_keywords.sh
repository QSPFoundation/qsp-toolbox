#!/bin/bash

# Configuration
SEARCH_DIR="$HOME/qsp/qsp_extract_games/games"
SIMPLE=0  # Set to 1 for SIMPLE mode (print only keywords, one per line)

echo "Checking for duplicate var names (plain vs \$/#/%-prefixed) in QSPSRC files..."
echo "Directory: $SEARCH_DIR"
echo "=========================================="
echo ""

# Check if directory exists
if [ ! -d "$SEARCH_DIR" ]; then
    echo "Error: Directory not found: $SEARCH_DIR"
    exit 1
fi

# Statistics
total_files=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Process all .qspsrc files recursively
while IFS= read -r file; do
    ((total_files++))
    echo "Processing file: $file"
    gawk -v simple="$SIMPLE" -f "$SCRIPT_DIR/_find_same_keywords.awk" "$file"
done < <(find "$SEARCH_DIR" -type f -iname "*.qspsrc")

# Summary
echo ""
echo "=========================================="
echo "Summary:"
echo "----------------------------------------"
echo "Total files searched: $total_files"
echo "=========================================="
