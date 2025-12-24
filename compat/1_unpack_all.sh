#!/bin/bash
#
# Extract archives, preserving folder/archive hierarchy
#

# ---------------- Configuration ----------------
SOURCE_DIR="$HOME/qsp/qsp_org/sobi2_downloads"
DEST_DIR="$HOME/qsp/qsp_extract_games/games"

ARCHIVE_EXTENSIONS=("zip" "rar" "7z" "aqsp")   # Archives to extract
ZIP_EXTENSIONS=("zip" "aqsp")                  # Extensions to treat as ZIP

# ---------------- Preparations ----------------
command -v 7z >/dev/null 2>&1 || { echo "7z not found"; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "unzip not found"; exit 1; }

mkdir -p "$DEST_DIR" || { echo "Cannot create DEST_DIR"; exit 1; }
TMP_BASE=$(mktemp -d "${TMPDIR:-/tmp}/extract_base.XXXXXX")
[[ -d "$TMP_BASE" ]] || { echo "Failed to create temp dir"; exit 1; }
trap 'rm -rf "$TMP_BASE"' EXIT

# ---------------- Utilities ----------------
join_path() {
    local out=""
    for p in "$@"; do
        [[ -z "$p" ]] && continue
        p="${p#/}"
        [[ -z "$out" ]] && out="$p" || out="$out/$p"
    done
    [[ "$1" == /* ]] && out="/$out"
    printf '%s' "$out"
}

lower_ext() { local p="${1##*.}"; printf '%s' "${p,,}"; }
is_in_list() { local val="$1"; shift; for x in "$@"; do [[ "$val" == "$x" ]] && return 0; done; return 1; }
is_archive() { is_in_list "$(lower_ext "$1")" "${ARCHIVE_EXTENSIONS[@]}"; }
is_zip_like() { is_in_list "$(lower_ext "$1")" "${ZIP_EXTENSIONS[@]}"; }

# ---------------- Detect weird filenames ----------------
get_weird_filenames_unzip() {
    local dir="$1"
    find "$dir" -type f | while read -r f; do
        local rel="${f#$dir/}"
        if ! printf '%s\n' "$rel" | grep -Pq '^[\x20-\x7Eа-яА-ЯёЁ—]+$' 2>/dev/null; then
            echo "$rel"
        fi
    done
}

# ---------------- Extract ZIP smart ----------------
extract_zip_smart() {
    local archive="$1" outdir="$2"
    mkdir -p "$outdir" || return 1
    unzip -q -O CP866 -o "$archive" -d "$outdir" >/dev/null 2>&1
    local weird_files
    weird_files=$(get_weird_filenames_unzip "$outdir")
    if [[ -n "$weird_files" ]]; then
        echo "Switched to UTF-8 for \"$archive\" due to filenames:"
        while read -r f; do echo "  $f"; done <<< "$weird_files"
        rm -rf "$outdir"
        mkdir -p "$outdir"
        unzip -q -O UTF-8 -o "$archive" -d "$outdir" >/dev/null 2>&1
    fi
}

# ---------------- Extract other archives ----------------
extract_with_7z() {
    local archive="$1" outdir="$2"
    mkdir -p "$outdir" || return 1
    7z x "$archive" -o"$outdir" -y -bd -bb0 >/dev/null 2>&1
}

# ---------------- Recursive processing ----------------
process_directory() {
    local extract_root="$1" rel_chain="$2"

    while IFS= read -r -d '' path; do
        local rel_path dest_path

        rel_path="${path#$extract_root/}"
        [[ -z "$rel_path" ]] && rel_path="$(basename "$path")"

        dest_path="$(join_path "$DEST_DIR" "$rel_chain" "$rel_path")"

        if [[ -d "$path" ]]; then
            mkdir -p "$dest_path"
        elif is_archive "$path"; then
            local tmp_extract new_chain
            tmp_extract=$(mktemp -d "$TMP_BASE/$(basename "$path").XXXXXX") || continue
            if is_zip_like "$path"; then
                extract_zip_smart "$path" "$tmp_extract"
            else
                extract_with_7z "$path" "$tmp_extract"
            fi

            new_chain="$(join_path "$rel_chain" "$rel_path")"
            process_directory "$tmp_extract" "$new_chain"
            rm -rf "$tmp_extract"
        else
            mkdir -p "$(dirname "$dest_path")" || continue
            cp -p "$path" "$dest_path"
            printf 'Copied: %s\n' "$dest_path"
        fi
    done < <(find "$extract_root" -mindepth 1 -print0 2>/dev/null)
}

# ---------------- Main ----------------
echo "Starting extraction..."
process_directory "$SOURCE_DIR" ""
echo "Done! Extracted files are in: $DEST_DIR"
