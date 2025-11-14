#!/bin/bash
# Quick Actions Menu for i3wm
# Fast access to common actions and applications

set -euo pipefail

# Define menu items with icons
MENU="🖥️  Terminal
🌐  Firefox
📝  VS Code
📁  File Manager
📊  System Monitor (htop)
🧮  Calculator
📸  Screenshot (Full Screen)
📷  Screenshot (Select Area)
🖼️  Screenshot (Window)
📐  Change Resolution
📤  File Upload/Download Server
📓  Quick Note
📚  Browse Notes
🔒  Lock Screen
🔄  Restart i3
⚡  Reload i3 Config
🚪  Exit i3"

# Show rofi menu and get selection
CHOICE=$(echo -e "$MENU" | rofi -dmenu -i -p "Quick Actions:" -theme Arc-Dark -lines 17)

# Exit if no selection
[ -z "$CHOICE" ] && exit 0

# Execute selected action
case "$CHOICE" in
    *"Terminal")
        alacritty &
        ;;
    *"Firefox")
        firefox &
        ;;
    *"VS Code")
        firefox http://localhost:8080 &
        ;;
    *"File Manager")
        thunar &
        ;;
    *"System Monitor"*)
        alacritty -e htop &
        ;;
    *"Calculator")
        if command -v qalculate-gtk &> /dev/null; then
            qalculate-gtk &
        elif command -v gnome-calculator &> /dev/null; then
            gnome-calculator &
        else
            alacritty -e bc &
        fi
        ;;
    *"Screenshot (Full"*)
        /usr/local/bin/screenshot.sh full
        ;;
    *"Screenshot (Select"*)
        /usr/local/bin/screenshot.sh select
        ;;
    *"Screenshot (Window"*)
        /usr/local/bin/screenshot.sh window
        ;;
    *"Change Resolution")
        /usr/local/bin/resolution-menu.sh &
        ;;
    *"File Upload"*)
        /usr/local/bin/file-server.sh toggle
        ;;
    *"Quick Note")
        # Use rofi to get note text
        NOTE_TEXT=$(rofi -dmenu -p "Quick Note:" -theme Arc-Dark -lines 0)
        if [ -n "$NOTE_TEXT" ]; then
            notes_dir="$HOME/notes"
            mkdir -p "$notes_dir"
            note_file="$notes_dir/$(date +%Y-%m-%d).md"
            echo "## $(date +%H:%M) - $NOTE_TEXT" >> "$note_file"
            notify-send "Note Saved" "Added to $note_file" -t 3000
        fi
        ;;
    *"Browse Notes")
        notes_dir="$HOME/notes"
        mkdir -p "$notes_dir"
        if [ -n "$(ls -A $notes_dir/*.md 2>/dev/null)" ]; then
            SELECTED_NOTE=$(ls -t "$notes_dir"/*.md | sed "s|$notes_dir/||" | rofi -dmenu -p "Open Note:" -theme Arc-Dark)
            [ -n "$SELECTED_NOTE" ] && alacritty -e nvim "$notes_dir/$SELECTED_NOTE" &
        else
            notify-send "No Notes" "No notes found in $notes_dir" -t 3000
        fi
        ;;
    *"Lock Screen")
        i3lock -c 000000 &
        ;;
    *"Restart i3")
        i3-msg restart
        ;;
    *"Reload i3"*)
        i3-msg reload
        notify-send "i3 Config Reloaded" "Configuration reloaded successfully" -t 3000
        ;;
    *"Exit i3")
        i3-nagbar -t warning -m 'Do you really want to exit i3?' -B 'Yes, exit i3' 'i3-msg exit' &
        ;;
esac
