#!/bin/bash
# shellcheck source=/home/smith/Projects/StudioFinder/utility.sh disable=SC1091

# Get the script directory
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
export SCRIPT_PATH="$SCRIPT_DIR/config.sh"

# source utility.sh
source "$SCRIPT_PATH" || { echo "Failed to source config.sh"; exit 1; }

# Exports associative array(s)
export Config

EXECUTABLE=$(find "${Config["VINEGAR_DIR"]}" -name "${Config["EXECUTABLE"]}" 2>/dev/null)

# Run the script
bash << EOF
    WINEPREFIX="${Config["WINEPREFIX"]}" GAMEID="${Config["GAMEID"]}" PROTONPATH="${Config["PROTONPATH"]}" ${Config["RUN"]} "${EXECUTABLE}"
EOF
