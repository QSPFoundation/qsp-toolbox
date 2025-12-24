#!/bin/bash
#
# Convert QSPSRC files back to QSP/GAM format using txt2gam tool
#

# Configuration
SEARCH_DIR="$HOME/qsp/qsp_extract_games/games"
TXT2GAM_TOOL="$HOME/txt2gam"

echo "Starting QSPSRC → QSP/GAM conversion..."
echo "Directory: $SEARCH_DIR"
echo "Tool: $TXT2GAM_TOOL"
echo "----------------------------------------"

# Check for txt2gam tool
if [ ! -f "$TXT2GAM_TOOL" ]; then
    echo "Error: txt2gam tool not found at $TXT2GAM_TOOL"
    exit 1
fi

if [ ! -x "$TXT2GAM_TOOL" ]; then
    echo "Error: txt2gam tool is not executable. Run: chmod +x $TXT2GAM_TOOL"
    exit 1
fi

# Counters
total_files=0
success_count=0
error_count=0

# Process each .qspsrc file found recursively
while IFS= read -r src; do
    ((total_files++))

    # Destination file = same name without ".qspsrc"
    dest="${src%.qspsrc}"

    echo "Processing: $src"
    echo "  -> Output: $dest"

    if "$TXT2GAM_TOOL" "$src" "$dest" 2>/dev/null; then
        echo "  ✓ Converted"
        ((success_count++))
    else
        echo "  ✗ Failed"
        ((error_count++))
    fi

    echo ""
done < <(find "$SEARCH_DIR" -type f -iname "*.qspsrc")

echo "----------------------------------------"
echo "Conversion complete!"
echo "Total files: $total_files"
echo "Successful: $success_count"
echo "Failed: $error_count"
