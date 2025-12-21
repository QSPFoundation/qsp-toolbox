#!/usr/bin/env bash

if [[ $# -lt 2 || $# -gt 4 ]]; then
  echo "Usage: $0 <input_file> <keyword_file> [exclusion_file] [template with {} for kw]" >&2
  exit 1
fi

input="$1"
keywords="$2"
exclusions="${3:-}"
template="${4:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gawk -v kwfile="$keywords" -v exfile="$exclusions" -v template="$template" -f "$SCRIPT_DIR/_replace_keywords.awk" "$input"
