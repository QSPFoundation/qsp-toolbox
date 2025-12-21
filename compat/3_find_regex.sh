#!/bin/bash

# Configuration
SEARCH_DIR="$HOME/qsp/qsp_extract_games/games/27"
REGEX_PATTERNS=(
    "INSTR\s*\([^,\)]+,[^,\)]+,[^,\)]+\)"
    "ARRPOS\s*\([^,\)]+,[^,\)]+,[^,\)]+\)"
    "ARRCOMP\s*\([^,\)]+,[^,\)]+,[^,\)]+\)"
    "RAND\s*\([^,\)]+\)"
    "\)\s*=\s*-\s*1[^\d]"
    "ADDQST"
    "KILLVAR" # killvar for duplicated vars has to be duplicated
)

# Options
SHOW_LINE_NUMBERS=true      # Show line numbers in output
CASE_INSENSITIVE=true       # Case-insensitive search
SHOW_FILENAME_ONLY=false    # Only show filenames with matches (no content)
CONTEXT_LINES=3             # Number of context lines to show (0 = none)

echo "Searching for regex patterns in QSPSRC files..."
echo "Directory: $SEARCH_DIR"
echo "Patterns: ${#REGEX_PATTERNS[@]}"
echo "----------------------------------------"

# Check if directory exists
if [ ! -d "$SEARCH_DIR" ]; then
    echo "Error: Directory not found: $SEARCH_DIR"
    exit 1
fi

# Build grep options
GREP_OPTS="-P -H"  # Extended regex and always show filename
[ "$CASE_INSENSITIVE" = true ] && GREP_OPTS="$GREP_OPTS -i"
[ "$SHOW_LINE_NUMBERS" = true ] && GREP_OPTS="$GREP_OPTS -n"
[ "$SHOW_FILENAME_ONLY" = true ] && GREP_OPTS="$GREP_OPTS -l"
[ "$CONTEXT_LINES" -gt 0 ] && GREP_OPTS="$GREP_OPTS -C $CONTEXT_LINES"

# Add color if terminal supports it
if [ -t 1 ]; then
    GREP_OPTS="$GREP_OPTS --color=always"
fi

# Statistics
total_files=0
files_with_matches=0
total_matches=0

# Associative array to track matches per pattern
declare -A pattern_matches
declare -A pattern_files

# Initialize counters for each pattern
for pattern in "${REGEX_PATTERNS[@]}"; do
    pattern_matches["$pattern"]=0
    pattern_files["$pattern"]=0
done

# Search all .qspsrc files recursively
while IFS= read -r file; do
    ((total_files++))

    echo ""
    echo "Processing: $file"
    echo "----------------------------------------"

    file_has_matches=false

    # Check each pattern against this file
    for pattern in "${REGEX_PATTERNS[@]}"; do
        echo "  Checking pattern: $pattern"

        # Search for pattern in file
        if grep $GREP_OPTS "$pattern" "$file" 2>/dev/null; then
            file_has_matches=true
            ((pattern_files["$pattern"]++))

            # Count matches if not in filename-only mode
            if [ "$SHOW_FILENAME_ONLY" != true ]; then
                matches=$(grep -c -P ${CASE_INSENSITIVE:+-i} "$pattern" "$file" 2>/dev/null)
                ((pattern_matches["$pattern"] += matches))
                ((total_matches += matches))
            fi
            echo ""
        fi
    done

    [ "$file_has_matches" = true ] && ((files_with_matches++))

done < <(find "$SEARCH_DIR" -type f -iname "*.qspsrc")

echo ""
echo "========================================"
echo "SUMMARY BY PATTERN:"
echo "========================================"
for pattern in "${REGEX_PATTERNS[@]}"; do
    echo "Pattern: $pattern"
    echo "  Matches: ${pattern_matches[$pattern]} in ${pattern_files[$pattern]} file(s)"
    echo ""
done

echo "----------------------------------------"
echo "Search complete!"
echo "Total files searched: $total_files"
echo "Files with matches: $files_with_matches"
echo "Total matches: $total_matches"
