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

bash << EOF
    chmod +x "${installer["file"]}"
EOF

bash << EOF
    update-desktop-database ~/.local/share/applications
EOF
