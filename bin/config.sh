#!/bin/bash
# shellcheck disable=SC2034

declare -A Config

Config.Set() {
    Config["EXECUTABLE"]="RobloxStudioBeta.exe"
    Config["VINEGAR_DIR"]="$HOME/.local/share/vinegar/versions/"
    Config["WINEPREFIX"]="$HOME/.local/share/vinegar/prefixes/studio"
    Config["GAMEID"]="0"
    Config["PROTONPATH"]="GE-Proton"
    Config["RUN"]="umu-run"
}; Config.Set
