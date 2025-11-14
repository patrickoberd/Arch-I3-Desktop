#!/bin/bash
# Interactive i3wm Mod key configuration
# Runs only on first boot to let user choose their preferred Mod key

set -euo pipefail

CONFIG_FLAG="$HOME/.config/i3/modkey-configured"
I3_CONFIG="$HOME/.config/i3/config"

# Check if already configured
if [ -f "$CONFIG_FLAG" ]; then
    exit 0
fi

# Clear screen and show banner
clear
cat << 'BANNER'
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║            🎨 Welcome to Arch Linux i3wm Desktop! 🎨                ║
║                                                                    ║
║                      First-Time Setup                              ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝

i3wm is a tiling window manager controlled by keyboard shortcuts.
The main modifier key (Mod) is used for most commands.

Let's configure your preferred Mod key!

BANNER

echo "Available options:"
echo ""
echo "  [1] Alt key      (Mod1) - Common in Linux, conflicts less with apps"
echo "  [2] Super key    (Mod4) - Windows/Command key, i3 default"
echo ""
echo -n "Enter your choice [1 or 2]: "

# Read user choice
while true; do
    read -r choice
    case $choice in
        1)
            MODKEY="Mod1"
            MODKEY_NAME="Alt"
            break
            ;;
        2)
            MODKEY="Mod4"
            MODKEY_NAME="Super (Windows/Command)"
            break
            ;;
        *)
            echo -n "Invalid choice. Please enter 1 or 2: "
            ;;
    esac
done

# Update i3 config
echo ""
echo "🔧 Configuring i3wm with $MODKEY_NAME as Mod key..."
sed -i "s/set \$mod Mod[14]/set \$mod $MODKEY/" "$I3_CONFIG"

# Create flag file
touch "$CONFIG_FLAG"

# Show success message and keybindings
clear
cat << EOF
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║                    ✅ Configuration Complete! ✅                    ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝

Your Mod key is now set to: $MODKEY_NAME

⌨️  ESSENTIAL KEYBINDINGS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Mod = $MODKEY_NAME key

  🚀 LAUNCH APPLICATIONS:
     Mod+Enter         Open terminal (Alacritty)
     Mod+d             Application launcher (dmenu)
     Mod+Shift+f       Open Firefox browser
     Mod+Shift+t       Open file manager (Thunar)

  🪟 WINDOW MANAGEMENT:
     Mod+Shift+q       Close window
     Mod+f             Toggle fullscreen
     Mod+Shift+Space   Toggle floating mode
     Right-Click       Window menu (layout, floating, sticky, etc.)

  🎯 NAVIGATION:
     Mod+h/j/k/l       Focus left/down/up/right (vim-style)
     Mod+Left/Down/Up/Right  Focus with arrow keys

  📐 LAYOUTS:
     Mod+s             Stacking layout
     Mod+w             Tabbed layout
     Mod+e             Toggle split layout
     Mod+b             Split horizontal
     Mod+v             Split vertical

  🏢 WORKSPACES:
     Mod+1 to Mod+9    Switch to workspace 1-9
     Mod+Ctrl+1-9      Move window to workspace (alternative method)
     Mod+Shift+w       Move window via interactive menu (visual picker)

     NOTE: If Mod+Shift+1-9 causes issues with your terminal app,
     use Mod+Ctrl+1-9 or Mod+Shift+w instead to move windows.

  🌐 WEB APPS:
     VS Code Web IDE:  http://localhost:8080
     (Firefox will open automatically with VS Code)

  ⚙️  SYSTEM:
     Mod+Shift+c       Reload i3 config
     Mod+Shift+r       Restart i3
     Mod+Shift+e       Exit i3
     Mod+x             Lock screen

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 For more help, visit: https://i3wm.org/docs/userguide.html

Press Enter to restart i3 and start using your desktop...
EOF

read -r

# Automatically restart i3 to apply the new Mod key configuration
echo ""
echo "Restarting i3 to apply changes..."
sleep 1
i3-msg restart

# Wait for i3 to restart, then open Firefox with VS Code
sleep 2
echo "Opening VS Code in Firefox..."
firefox http://localhost:8080 &

exit 0
