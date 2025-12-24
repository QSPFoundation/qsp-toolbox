#!/usr/bin/env bash
#
# Reassemble directories into archives, preserving folder hierarchy
#

########## Configuration ##########
EXTRACTED_ROOT="$HOME/qsp/qsp_extract_games/games"
REASSEMBLED_ROOT="${EXTRACTED_ROOT}_reassembled"

ARCHIVE_EXTENSIONS=("zip" "rar" "7z" "aqsp")

TMP_BASE="$(mktemp -d "${TMPDIR:-/tmp}/reassemble_base.XXXXXX")"

trap 'rm -rf "$TMP_BASE"' EXIT
###################################

# --- Checks
command -v 7z >/dev/null 2>&1 || { echo "Error: 7z not found"; exit 1; }
command -v rar >/dev/null 2>&1 || { echo "Error: rar not found"; exit 1; }

lower_ext() { local name="$1"; local ext="${name##*.}"; printf '%s' "${ext,,}"; }
is_in_list() { local val="$1"; shift; for e in "$@"; do [[ "$val" == "$e" ]] && return 0; done; return 1; }
map_ext_to_tool() {
    local ext="$1"
    case "$ext" in
        zip|aqsp) printf "7z -tzip" ;;
        7z) printf "7z -t7z" ;;
        rar) printf "rar" ;;
        *) echo "Error: unsupported archive extension '$ext'" >&2; return 1 ;;
    esac
}

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

# --- Recursive function to process a directory ---
process_dir() {
    local src_dir="$1"
    local rel_path="$2"  # relative path from EXTRACTED_ROOT
    local dest_dir="$REASSEMBLED_ROOT/$rel_path"

    mkdir -p "$dest_dir"

    shopt -s dotglob nullglob
    for item in "$src_dir"/*; do
        [[ -e "$item" ]] || continue
        base="$(basename "$item")"
        if [[ -d "$item" ]]; then
            ext="$(lower_ext "$base")"
            if is_in_list "$ext" "${ARCHIVE_EXTENSIONS[@]}"; then
                # Archive directory: package it
                tmp_archive="$TMP_BASE/${base}.tmp"
                echo "Packaging archive directory: $item -> $base"
                tool_and_type="$(map_ext_to_tool "$ext")"
                (
                    cd "$item"
                    files=(./*)
                    if [[ ${#files[@]} -eq 0 ]]; then
                        placeholder="$TMP_BASE/.empty_placeholder_$$"
                        : > "$placeholder"
                        files=("$placeholder")
                        placeholder_created=1
                    else
                        placeholder_created=0
                    fi

                    if [[ "$tool_and_type" == "rar" ]]; then
                        echo "Running: rar a -idq \"$tmp_archive\" ${files[*]}"
                        rar a -idq "$tmp_archive" "${files[@]}" || { echo "ERROR: rar creation failed"; exit 1; }
                    else
                        tool_cmd=( $tool_and_type )
                        echo "Running: ${tool_cmd[*]} a \"$tmp_archive\" ${files[*]}"
                        "${tool_cmd[0]}" a "${tool_cmd[1]:-}" "$tmp_archive" "${files[@]}" || { echo "ERROR: 7z creation failed"; exit 1; }
                    fi

                    [[ "$placeholder_created" -eq 1 ]] && rm -f "$placeholder" || true
                )

                [[ -f "$tmp_archive" ]] || { echo "Archive not created: $tmp_archive"; exit 1; }

                dest_archive_path="$(join_path "$dest_dir" "$base")"
                mv -- "$tmp_archive" "$dest_archive_path"
                printf '%s\n' "-> Created archive at: $dest_archive_path"

            else
                # Regular directory: recurse
                process_dir "$item" "$(join_path "$rel_path" "$base")"
            fi
        elif [[ -f "$item" ]]; then
            # Regular file: copy
            dest_file="$(join_path "$dest_dir" "$base")"
            cp -p "$item" "$dest_file"
            printf 'Copied file: %s\n' "$dest_file"
        fi
    done
}

# --- Main ---
echo "Starting reassembly from: $EXTRACTED_ROOT"
process_dir "$EXTRACTED_ROOT" ""
echo "Reassembly complete. Output in: $REASSEMBLED_ROOT"
exit 0
