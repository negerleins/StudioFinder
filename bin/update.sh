#!/usr/bin/bash

# GitHub repository details
GITHUB_USER="negerleins"
GITHUB_REPO="StudioFinder"

# Local version
LOCAL_VERSION="1.0.4"

notify_os() {
    local os_name
    local notification_command
    local message="${1:-"A new update is available"}"  # Default message if none provided

    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os_name="Linux"
        notification_command="notify-send"
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
