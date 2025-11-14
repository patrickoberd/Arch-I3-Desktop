#!/bin/bash
# Enhanced Screenshot Tool
# Captures screenshots and saves them to organized directory

set -euo pipefail

# Screenshot directory
SCREENSHOT_DIR="$HOME/Pictures/screenshots"
mkdir -p "$SCREENSHOT_DIR"

# Generate filename with timestamp
FILENAME="$SCREENSHOT_DIR/screenshot_$(date +%Y%m%d_%H%M%S).png"

# Capture screenshot based on mode
case "${1:-select}" in
    full)
        maim "$FILENAME"
        MODE="Full screen"
        ;;
    window)
        maim -i "$(xdotool getactivewindow)" "$FILENAME"
        MODE="Active window"
        ;;
    select)
        maim -s "$FILENAME"
        MODE="Selected area"
        ;;
    *)
        echo "Usage: $0 {full|window|select}"
        exit 1
        ;;
esac

# Check if screenshot was captured
if [ -f "$FILENAME" ]; then
    # Copy to clipboard
    xclip -selection clipboard -t image/png < "$FILENAME"

    # Show notification with preview
    notify-send "Screenshot Captured" "$MODE saved to:\n$FILENAME\n\nCopied to clipboard!" -i "$FILENAME" -t 5000

    echo "Screenshot saved: $FILENAME"
    echo "Copied to clipboard"
else
    notify-send "Screenshot Failed" "Could not capture screenshot" -u critical -t 5000
    echo "Failed to capture screenshot"
    exit 1
fi
