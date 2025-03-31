#!/bin/bash

# Get the script directory
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

# Declare associative array
declare -A installer

installer.unit() {
    installer['bin']=$HOME'/.local/bin'
    installer['src_bin']=$SCRIPT_DIR'/bin'
    installer['file']="$HOME/.local/share/applications/StudioFinder.desktop"
}; installer.unit

installer.check_existing() {
    if [[ -d "${installer['bin']}/StudioFinder" || -f "${installer['file']}" ]]; then
        read -p "Existing installation found. Do you want to delete previous data? (y/n): " choice
        case "$choice" in
            y|Y )
                rm -rf "${installer['bin']}/StudioFinder"
                rm -f "${installer['file']}"
                echo "Previous data deleted."
                ;;
            n|N )
                echo "Installation cancelled."
                exit 0
                ;;
            * )
                echo "Invalid input. Installation cancelled."
                exit 1
                ;;
        esac
    fi
}; installer.check_existing

installer.install() {
    mkdir -p "${installer['bin']}"
    cp -a "${installer['src_bin']}/." "${installer['bin']}/StudioFinder"
}; installer.install

sleep 1

cat << EOF > "${installer["file"]}"
[Desktop Entry]
Version=1.0
Name=StudioFinder
Comment=Find Roblox Studio
Exec=${installer['bin']}/StudioFinder/stf.sh
Icon=${installer['bin']}/StudioFinder/logo.png
Terminal=false
Type=Application
Categories=Utility;
EOF

chmod +x "${installer["file"]}"

update-desktop-database ~/.local/share/applications

echo "Installation completed successfully."
