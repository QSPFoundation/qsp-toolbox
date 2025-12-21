#!/bin/bash
#
# Script to find filenames that are present in both input files
# Filenames are extracted from lines containing the specified prefix
#

# Check if correct number of arguments provided
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 <file1> <file2> [pattern]"
    echo ""
    echo "Arguments:"
    echo "  file1     - First file to compare"
    echo "  file2     - Second file to compare"
    echo "  pattern   - Optional. Regex pattern to extract filenames (default: 'file: ')"
    echo ""
    echo "Example: $0 no_dups.txt no_regexp.txt"
    echo "Example: $0 file1.txt file2.txt 'path: '"
    echo ""
    echo "Finds filenames that appear in both files."
    exit 1
fi

FILE1="$1"
FILE2="$2"
PATTERN="${3:-file: }"

# Check if files exist
if [ ! -f "$FILE1" ]; then
    echo "Error: File not found: $FILE1"
    exit 1
fi

if [ ! -f "$FILE2" ]; then
    echo "Error: File not found: $FILE2"
    exit 1
fi

echo "Finding common filenames between:"
echo "  File 1: $FILE1"
echo "  File 2: $FILE2"
echo "  Pattern: '$PATTERN'"
echo "=========================================="
echo ""

# Create temporary files for extracted filenames
TEMP1=$(mktemp)
TEMP2=$(mktemp)

# Cleanup function
cleanup() {
    rm -f "$TEMP1" "$TEMP2"
}
trap cleanup EXIT

# Extract filenames from both files (everything after the pattern)
# Escape the pattern for use in regex
ESCAPED_PATTERN=$(printf '%s\n' "$PATTERN" | sed 's/[[\.*^$/]/\\&/g')
grep -oP "(?<=${ESCAPED_PATTERN}).*" "$FILE1" | sort -u > "$TEMP1"
grep -oP "(?<=${ESCAPED_PATTERN}).*" "$FILE2" | sort -u > "$TEMP2"

# Count total files in each
count1=$(wc -l < "$TEMP1")
count2=$(wc -l < "$TEMP2")

echo "Unique files in $FILE1: $count1"
echo "Unique files in $FILE2: $count2"
echo ""

# Find common files
echo "Common files (present in both):"
echo "=========================================="
common_files=$(comm -12 "$TEMP1" "$TEMP2")
common_count=$(echo "$common_files" | grep -c '^' || echo 0)

if [ -n "$common_files" ] && [ "$common_count" -gt 0 ]; then
    echo "$common_files"
    echo ""
    echo "=========================================="
    echo "Total common files: $common_count"
else
    echo "No common files found."
fi
