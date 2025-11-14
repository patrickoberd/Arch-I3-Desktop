#!/bin/bash
# Dynamic resolution changer for VNC desktop
# Uses xrandr to change display resolution on-the-fly

set -euo pipefail

# Common display resolutions (ordered from highest to lowest)
RESOLUTIONS=(
    "3840x2160"
    "3440x1440"
    "2560x1600"
    "2560x1440"
    "2560x1080"
    "1920x1080"
    "1680x1050"
    "1600x900"
    "1440x900"
    "1366x768"
    "1280x1024"
    "1280x800"
    "1024x768"
)

# Get current resolution
CURRENT=$(xdpyinfo | grep dimensions | awk '{print $2}')

# Build menu with current resolution marked
MENU=""
for res in "${RESOLUTIONS[@]}"; do
    if [ "$res" == "$CURRENT" ]; then
        MENU+="● $res (current)\n"
    else
        MENU+="  $res\n"
    fi
done

# Show menu and get selection
SELECTED=$(echo -e "$MENU" | rofi -dmenu -i -p "Select Resolution:" -theme Arc-Dark | sed 's/^[●] //' | awk '{print $1}')

# Exit if no selection
if [ -z "$SELECTED" ]; then
    exit 0
fi

# Exit if same resolution selected
if [ "$SELECTED" == "$CURRENT" ]; then
    notify-send "Resolution" "Already using $CURRENT" -t 2000
    exit 0
fi

# Get display name (usually :1 for VNC)
DISPLAY_NAME=$(xrandr | grep " connected" | awk '{print $1}')

# Apply new resolution
if xrandr --output "$DISPLAY_NAME" --mode "$SELECTED" 2>/dev/null; then
    notify-send "Resolution Changed" "Display set to $SELECTED" -t 3000
else
    # If mode doesn't exist, create it and apply
    MODELINE=$(cvt ${SELECTED/x/ } | grep Modeline | sed 's/Modeline //' | sed 's/"//g')
    MODE_NAME=$(echo "$MODELINE" | awk '{print $1}')
    MODE_PARAMS=$(echo "$MODELINE" | cut -d' ' -f2-)

    # Create new mode
    xrandr --newmode $MODE_NAME $MODE_PARAMS 2>/dev/null || true

    # Add mode to display
    xrandr --addmode "$DISPLAY_NAME" "$MODE_NAME" 2>/dev/null || true

    # Apply the mode
    if xrandr --output "$DISPLAY_NAME" --mode "$MODE_NAME" 2>/dev/null; then
        notify-send "Resolution Changed" "Display set to $SELECTED" -t 3000
    else
        notify-send "Resolution Error" "Failed to set $SELECTED" -t 5000 -u critical
    fi
fi
