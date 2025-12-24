#!/bin/bash
#
# Convert QSP/GAM files to QSPSRC format using txt2gam tool
#

# Configuration
SOURCE_DIR="$HOME/qsp/qsp_extract_games/games"
TXT2GAM_TOOL="$HOME/txt2gam"

# Check if txt2gam tool exists
if [ ! -f "$TXT2GAM_TOOL" ]; then
    echo "Error: txt2gam tool not found at $TXT2GAM_TOOL"
    exit 1
fi

# Make sure the tool is executable
if [ ! -x "$TXT2GAM_TOOL" ]; then
    echo "Error: txt2gam tool is not executable. Run: chmod +x $TXT2GAM_TOOL"
    exit 1
fi

echo "Starting QSP/GAM to QSPSRC conversion..."
echo "Source: $SOURCE_DIR"
echo "Tool: $TXT2GAM_TOOL"
echo "----------------------------------------"

# Counter for statistics
total_files=0
success_count=0
error_count=0

# Process all .qsp and .gam files recursively
while IFS= read -r file; do
    ((total_files++))

    # Output file: same directory + original name + .qspsrc extension
    output_file="${file}.qspsrc"

    echo "Processing: $file"

    if "$TXT2GAM_TOOL" "$file" "$output_file" d p123 2>/dev/null; then
        echo "  ✓ Converted: $(basename "$output_file")"
        ((success_count++))
    else
        echo "  ✗ Failed: $file"
        ((error_count++))
    fi

done < <(find "$SOURCE_DIR" -type f \( -iname "*.qsp" -o -iname "*.gam" \))

echo "----------------------------------------"
echo "Conversion complete!"
echo "Total files: $total_files"
echo "Successful: $success_count"
echo "Failed: $error_count"
