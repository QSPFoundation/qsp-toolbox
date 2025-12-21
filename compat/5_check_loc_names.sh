#!/usr/bin/env bash

if [[ $# -lt 2 || $# -gt 2 ]]; then
  echo "Usage: $0 <keyword_file> <input file>" >&2
  exit 1
fi

input="$2"
keywords="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gawk -f "$SCRIPT_DIR/check_loc_names.awk" "$keywords" "$input"
