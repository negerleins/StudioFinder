#!/bin/bash

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
        notify_os "GameMode detected. Setting up compatibility."
        GAMEMODE_PREFIX="gamemoderun"
    else
        GAMEMODE_PREFIX=""
    fi

    echo "Compatibility setup complete."
}

configure_wine() {
    WINEPREFIX="${Config["WINEPREFIX"]}" winetricks settings win10
    WINEPREFIX="${Config["WINEPREFIX"]}" wine reg add "HKEY_CURRENT_USER\Software\Wine\Direct3D" /v "MaxVersionGL" /t REG_DWORD /d 0xffffffff /f
}

ensure_gamemode_running() {
    if ! systemctl --user is-active --quiet gamemoded; then
        notify_os "Starting GameMode service..."
        systemctl --user start gamemoded
    fi
}

setup_gamemode_polkit() {
    POLKIT_FILE="/etc/polkit-1/rules.d/90-gamemode.rules"
    if [ ! -f "$POLKIT_FILE" ]; then
        notify_os "Setting up GameMode polkit rules..."
        echo "polkit.addRule(function(action, subject) {
    if ((action.id == \"com.feralinteractive.GameMode.governor-set\" ||
         action.id == \"com.feralinteractive.GameMode.renice\" ||
         action.id == \"com.feralinteractive.GameMode.ioprio\" ||
         action.id == \"com.feralinteractive.GameMode.inhibit\") &&
        subject.isInGroup(\"gamemode\")) {
            return polkit.Result.YES;
    }
});" | sudo tee "$POLKIT_FILE" > /dev/null
        sudo systemctl restart polkit.service
        notify_os "GameMode polkit rules set up. You may need to log out and back in for changes to take effect."
    fi
}

launch_new_instance() {
    EXECUTABLE=$(find "${Config["VINEGAR_DIR"]}" -name "${Config["EXECUTABLE"]}" 2>/dev/null)

    if [ -z "$EXECUTABLE" ]; then
        notify_os "Roblox Studio executable not found."
        exit 1
    fi

    LD_PRELOAD="/usr/lib/libgamemodeauto.so.0:/usr/lib32/libgamemodeauto.so.0" \
    WINEPREFIX="${Config["WINEPREFIX"]}" \
    WINESERVER="$(command -v wineserver)" \
    GAMEID="${Config["GAMEID"]}" \
    PROTONPATH="${Config["PROTONPATH"]}" \
    WINE_FULLSCREEN_FSR=1 \
    WINE_FULLSCREEN_FSR_STRENGTH=2 \
    DXVK_ASYNC=1 \
    PROTON_NO_ESYNC=1 \
    PROTON_NO_FSYNC=1 \
    PROTON_FORCE_LARGE_ADDRESS_AWARE=1 \
    $GAMEMODE_PREFIX \
    $PROTON_OPTS \
    $GPU_PREFIX \
    ${Config["RUN"]} "$EXECUTABLE" &

    # Wait for the process to start
    sleep 2

    # Check if GameMode is active
    if gamemoded -s | grep -q "gamemode is active"; then
        notify_os "GameMode activated for Roblox Studio"
    else
        notify_os "GameMode failed to activate for Roblox Studio"
    fi
}


check_dependencies
check_gamemode
ensure_gamemode_running
setup_gamemode_polkit
check_and_set_gpu
setup_compatibility
configure_wine

export LD_LIBRARY_PATH="/usr/lib:/usr/lib32:/usr/lib/gamemode:/usr/lib32/gamemode:$LD_LIBRARY_PATH"

launch_new_instance

echo "Launching new Roblox Studio instance."
