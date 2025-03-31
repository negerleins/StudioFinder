#!/bin/bash
# shellcheck disable=SC2034

declare -A Config

Config.Set() {
    Config["EXECUTABLE"]="RobloxStudioBeta.exe"
    Config["VINEGAR_DIR"]="$HOME/.var/app/org.vinegarhq.Vinegar/data/vinegar/versions/"
    Config["WINEPREFIX"]="$HOME/.var/app/org.vinegarhq.Vinegar/data/vinegar/prefixes/studio"
    Config["GAMEID"]="0"
    Config["PROTONPATH"]="GE-Proton"
    Config["RUN"]="umu-run"
}; Config.Set
