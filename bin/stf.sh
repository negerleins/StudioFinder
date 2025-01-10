#!/bin/bash
# shellcheck source=/home/smith/Projects/StudioFinder/utility.sh disable=SC1091

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
export SCRIPT_PATH="$SCRIPT_DIR/config.sh"
export UPDATE_SCRIPT="$SCRIPT_DIR/update.sh"

source "$SCRIPT_PATH" || { echo "Failed to source config.sh"; exit 1; }
source "$UPDATE_SCRIPT" || { echo "Failed to source update.sh"; exit 1; }

export Config
export notify_os

check_dependencies() {
  local missing_deps=()

  if ! command -v winetricks &> /dev/null; then
    missing_deps+=("winetricks")
  fi

  if ! command -v gamemoderun &> /dev/null; then
    missing_deps+=("gamemode")
  fi

  if [ ${#missing_deps[@]} -ne 0 ]; then
    notify_os "Missing dependencies: ${missing_deps[*]}"
    exit 1
  fi
}

check_gamemode() {
  if ! gamemoded -s &> /dev/null; then
    notify_os "GameMode is not running. Please start it with: systemctl --user start gamemoded"
  fi
}

check_and_set_gpu() {
    if lspci | grep -i nvidia > /dev/null; then
        PRIMARY_GPU="nvidia"
        GPU_PREFIX="__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia"
    elif lspci | grep -i amd > /dev/null; then
        PRIMARY_GPU="amd"
        GPU_PREFIX="DRI_PRIME=1"
    else
        PRIMARY_GPU="intel"
        GPU_PREFIX=""
    fi
    notify_os "Primary GPU detected: $PRIMARY_GPU"
    notify_os "GPU prefix set to: $GPU_PREFIX"
}

setup_compatibility() {
    PROTON_OPTS="PROTON_NO_ESYNC=1 PROTON_NO_FSYNC=1"

    WINEPREFIX="${Config["WINEPREFIX"]}" winetricks d3dx9 d3dcompiler_43 vcrun2005 vcrun2008 vcrun2010 vcrun2012 vcrun2013 vcrun2015

    if command -v gamemoderun &> /dev/null; then
        GAMEMODE_PREFIX="gamemoderun"
    else
        GAMEMODE_PREFIX=""
    fi

    echo "Compatibility setup complete."
}

check_dependencies
check_gamemode

EXECUTABLE=$(find "${Config["VINEGAR_DIR"]}" -name "${Config["EXECUTABLE"]}" 2>/dev/null)

check_and_set_gpu

setup_compatibility

export LD_LIBRARY_PATH="/usr/lib/gamemode:$LD_LIBRARY_PATH"

COMMAND="$GAMEMODE_PREFIX $GPU_PREFIX $PROTON_OPTS WINEPREFIX=\"${Config["WINEPREFIX"]}\" GAMEID=\"${Config["GAMEID"]}\" PROTONPATH=\"${Config["PROTONPATH"]}\" ${Config["RUN"]} \"${EXECUTABLE}\""

bash << EOF
    echo "EXECUTABLE path: $EXECUTABLE"
    echo "Running command: $COMMAND"
    $COMMAND
EOF
