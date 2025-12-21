#!/bin/bash

# Configuration
SEARCH_DIR="$HOME/qsp/qsp_extract_games/games/27"

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
#    gawk -v simple=1 -f "$SCRIPT_DIR/find_same_keywords.awk" "$file"
   gawk -f "$SCRIPT_DIR/find_same_keywords.awk" "$file"
done < <(find "$SEARCH_DIR" -type f -iname "*.qspsrc")

# Summary
echo ""
echo "=========================================="
echo "Summary:"
echo "----------------------------------------"
echo "Total files searched: $total_files"
echo "=========================================="
