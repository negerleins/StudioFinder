#!/bin/bash

# GitHub repository details
GITHUB_USER="negerleins"
GITHUB_REPO="StudioFinder"

# Local version
LOCAL_VERSION="1.0.6"

# Config
declare -A Config

Config["EXECUTABLE"]="RobloxStudioBeta.exe"
Config["VINEGAR_DIR"]="$HOME/.var/app/org.vinegarhq.Vinegar/data/vinegar/versions/"
Config["WINEPREFIX"]="$HOME/.var/app/org.vinegarhq.Vinegar/data/vinegar/prefixes/studio"
Config["GAMEID"]="0"
Config["PROTONPATH"]="GE-Proton"
Config["RUN"]="umu-run"

notify_os() {
    local os_name
    local notification_command
    local message="${1:-"A new update is available"}"
    local timeout=10000

    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os_name="Linux"
        notification_command="notify-send -t $timeout"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_name="macOS"
        notification_command="osascript -e"
        elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
        os_name="Windows"
        notification_command="msg *"
    else
        os_name="Unknown"
        echo "Unsupported OS for notifications"
        return 1
    fi

    # Send notification
    case $os_name in
        "Linux")
            $notification_command "Update Notification" "$message"
        ;;
        "macOS")
            $notification_command "display notification \"$message\" with title \"Update Notification\""
        ;;
        "Windows")
            $notification_command "$message"
        ;;
    esac

    echo "Notification sent on $os_name: $message"
}


fetch_github_version() {
    curl -s "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/releases/latest" |
    grep -oP '"tag_name": "\K(.*)(?=")'
}

version_compare() {
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 0
}

# Main script execution
GITHUB_VERSION=$(fetch_github_version)

if [ -z "$GITHUB_VERSION" ]; then
    echo "Failed to fetch GitHub version. Please check your internet connection or repository details."
    exit 1
fi

echo "Local version: $LOCAL_VERSION"
echo "GitHub version: $GITHUB_VERSION"

version_compare $LOCAL_VERSION $GITHUB_VERSION
case $? in
    0)
        notify_os "StudioFinder is up to date (version $LOCAL_VERSION)."
    ;;
    1)
        notify_os "Your StudioFinder version ($LOCAL_VERSION) is ahead of the GitHub version ($GITHUB_VERSION)."
    ;;
    2)
        notify_os "A new version ($GITHUB_VERSION) is available on GitHub. Current version: $LOCAL_VERSION"
    ;;
esac

check_dependencies() {
    local missing_deps=()

    if ! command -v winetricks &> /dev/null; then
        missing_deps+=("winetricks")
    fi

    if ! command -v gamemoderun &> /dev/null; then
        missing_deps+=("gamemode")
    fi

    if ! command -v "${Config["RUN"]}" &> /dev/null; then
        missing_deps+=("umu-run")
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
    "$PROTON_OPTS" \
    "$GPU_PREFIX" \
    "${Config["RUN"]}" "$EXECUTABLE" &

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

# Add notification before launching
notify_os "Launching Roblox Studio..."

launch_new_instance

# Wait for the process to start
notify_os "Please wait for Roblox Studio to launch. If it doesn't, please check your installation."
notify_os "Roblox Studio launched successfully."
notify_os "If you encounter any issues, please check the logs or contact support."
notify_os "Script execution completed."
notify_os "Thank you for using StudioFinder!"
