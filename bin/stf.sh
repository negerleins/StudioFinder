#!/bin/bash
# shellcheck source=/home/smith/Projects/StudioFinder/utility.sh disable=SC1091

# Get the script directory
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
export SCRIPT_PATH="$SCRIPT_DIR/config.sh"
export UPDATE_SCRIPT="$SCRIPT_DIR/update.sh"

# source utility.sh
source "$SCRIPT_PATH" || { echo "Failed to source config.sh"; exit 1; }

# source update.sh
source "$UPDATE_SCRIPT" || { echo "Failed to source update.sh"; exit 1; }

# Exports associative array(s)
export Config

EXECUTABLE=$(find "${Config["VINEGAR_DIR"]}" -name "${Config["EXECUTABLE"]}" 2>/dev/null)
COMMAND="WINEPREFIX=\"${Config["WINEPREFIX"]}\" GAMEID=\"${Config["GAMEID"]}\" PROTON_VERB=runinprefix PROTONPATH=\"${Config["PROTONPATH"]}\" ${Config["RUN"]} \"${EXECUTABLE}\""

# Run the script
bash << EOF
    echo "EXECUTABLE path: $EXECUTABLE"
    echo "Running command: $COMMAND"
    $COMMAND
EOF


# GAMEID=0 PROTON_VERB=runinprefix umu-run app1.exe
# protontricks-launch --appid <steam_appid> <path_to_exe1>
# WINEPREFIX="/path/to/prefix" PROTON_PATH="/path/to/proton" \"$PROTON_PATH/proton" run ./app2.exe &
