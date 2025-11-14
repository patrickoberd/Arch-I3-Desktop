#!/bin/bash
set -euo pipefail

echo "Starting desktop environment..."

# Initialize home directory with default configs on first run
if [ ! -f "$HOME/.workspace-initialized" ]; then
    echo "First run detected, installing default configurations..."

    # Create config directories
    mkdir -p ~/.config/{i3,dunst,alacritty,code-server}
    mkdir -p ~/.local/share/code-server

    # Copy default configs if they don't exist
    [ -f /etc/skel/.config/i3/config ] && cp -n /etc/skel/.config/i3/config ~/.config/i3/config
    [ -f /etc/skel/.config/i3/i3status.conf ] && cp -n /etc/skel/.config/i3/i3status.conf ~/.config/i3/i3status.conf
    [ -f /etc/skel/.config/dunst/dunstrc ] && cp -n /etc/skel/.config/dunst/dunstrc ~/.config/dunst/dunstrc
    [ -f /etc/skel/.config/alacritty/alacritty.toml ] && cp -n /etc/skel/.config/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml
    [ -f /etc/skel/.zshrc ] && cp -n /etc/skel/.zshrc ~/.zshrc

    touch "$HOME/.workspace-initialized"
    echo "Configuration installed"
fi

# Setup display
export DISPLAY=:1
export XDG_RUNTIME_DIR=/tmp/runtime-coder
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Create VNC directory
mkdir -p ~/.vnc

# Configure VNC (localhost-only, no password - secured by Coder authentication)
echo "Configuring secure VNC (localhost-only)..."
cat > ~/.vnc/config << 'EOF'
geometry=1920x1080
depth=24
localhost=yes
alwaysshared=yes
securitytypes=none
EOF

# Configure VNC xstartup
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_RUNTIME_DIR=/tmp/runtime-coder
export XKL_XMODMAP_DISABLE=1

# Start i3
exec i3
EOF
chmod +x ~/.vnc/xstartup

# Kill any existing VNC servers
vncserver -kill :1 2>/dev/null || true
pkill -9 Xvnc 2>/dev/null || true
sleep 1

# Start VNC server using Xvnc directly
echo "Starting VNC server on :1 (port 5901)..."
Xvnc :1 \
  -geometry 1920x1080 \
  -depth 24 \
  -rfbport 5901 \
  -SecurityTypes None \
  -AlwaysShared \
  -localhost yes \
  &
XVNC_PID=$!

# Wait for Xvnc to be ready
echo "Waiting for X server..."
for i in {1..30}; do
    if xdpyinfo -display :1 >/dev/null 2>&1; then
        echo "X server is ready"
        break
    fi
    sleep 1
done

# Start i3 window manager
echo "Starting i3wm..."
DISPLAY=:1 i3 &
I3_PID=$!

# Wait a moment for i3 to initialize
sleep 2

# Start noVNC for browser access
echo "Starting noVNC on port 6080..."
/opt/websockify/run --web /opt/noVNC 6080 localhost:5901 &
NOVNC_PID=$!

# Start code-server (VS Code in browser)
echo "Starting code-server on port 8080..."
# Create config for code-server
mkdir -p ~/.config/code-server
cat > ~/.config/code-server/config.yaml << 'CODECFG'
bind-addr: 0.0.0.0:8080
auth: none
cert: false
CODECFG
code-server --config ~/.config/code-server/config.yaml &
CODE_SERVER_PID=$!

# Wait for services to be ready
sleep 2

echo ""
echo "Desktop environment is ready"
echo ""
echo "Access methods:"
echo "  - Desktop (noVNC):  http://localhost:6080"
echo "  - VS Code:          http://localhost:8080"
echo "  - VNC Access:       Via Coder dashboard (authenticated)"
echo "  - Security:         localhost-only, no password needed"
echo ""
echo "i3wm keybindings:"
echo "  - Mod+Enter:        Open terminal"
echo "  - Mod+d:            Application launcher (dmenu)"
echo "  - Mod+Shift+q:      Close window"
echo "  - Mod+1-9:          Switch workspace"
echo "  - Mod+Shift+f:      Open Firefox"
echo "  - Mod+f:            Fullscreen"
echo "  - Mod+Shift+e:      Exit i3"
echo ""
echo "Tip: Mod key is the Windows/Super key"
echo ""

# Start Coder agent if token is provided
if [ -n "${CODER_AGENT_TOKEN:-}" ]; then
    echo "Installing and starting Coder agent..."

    # Use CODER_AGENT_URL env var (set by template)
    # Default to cluster-internal service if not set
    CODER_SERVER_URL="${CODER_AGENT_URL:-http://coder.coder.svc.cluster.local}"

    # Download Coder agent binary from server
    echo "Downloading agent from $CODER_SERVER_URL..."
    if curl -fsSL "$CODER_SERVER_URL/bin/coder-linux-amd64" -o /tmp/coder; then
        chmod +x /tmp/coder
        echo "Agent downloaded successfully"

        # Start agent in background
        # Agent will use CODER_AGENT_URL and CODER_AGENT_TOKEN env vars automatically
        /tmp/coder agent &
        CODER_PID=$!
        echo "Agent started (PID: $CODER_PID)"
        echo "Connecting to: $CODER_SERVER_URL"
    else
        echo "Failed to download Coder agent from $CODER_SERVER_URL"
        echo "Continuing without Coder integration..."
    fi
else
    echo "Running in standalone mode (no Coder integration)"
fi

# Keep container running and monitor processes
echo "Workspace is running. Press Ctrl+C to stop."
echo ""

# Trap to cleanup on exit
trap "echo 'Shutting down...'; kill $XVNC_PID $NOVNC_PID $CODE_SERVER_PID $I3_PID ${CODER_PID:-} 2>/dev/null; exit" SIGTERM SIGINT

while true; do
    # Check if Xvnc is still running
    if ! kill -0 $XVNC_PID 2>/dev/null; then
        echo "Xvnc died, restarting..."
        Xvnc :1 \
          -geometry 1920x1080 \
          -depth 24 \
          -rfbport 5901 \
          -SecurityTypes VncAuth \
          -PasswordFile ~/.vnc/passwd \
          -AlwaysShared \
          -localhost no \
          &
        XVNC_PID=$!
        sleep 2
        DISPLAY=:1 i3 &
        I3_PID=$!
    fi

    # Check if noVNC is still running
    if ! kill -0 $NOVNC_PID 2>/dev/null; then
        echo "noVNC died, restarting..."
        /opt/websockify/run --web /opt/noVNC 6080 localhost:5901 &
        NOVNC_PID=$!
    fi

    # Check if code-server is still running
    if ! kill -0 $CODE_SERVER_PID 2>/dev/null; then
        echo "code-server died, restarting..."
        code-server --config ~/.config/code-server/config.yaml &
        CODE_SERVER_PID=$!
    fi

    # Check if Coder agent is still running (if it was started)
    if [ -n "${CODER_PID:-}" ] && ! kill -0 $CODER_PID 2>/dev/null; then
        echo "Coder agent died, restarting..."
        CODER_SERVER_URL="${CODER_AGENT_URL:-http://coder.coder.svc.cluster.local}"
        if curl -fsSL "$CODER_SERVER_URL/bin/coder-linux-amd64" -o /tmp/coder; then
            chmod +x /tmp/coder
            /tmp/coder agent &
            CODER_PID=$!
        fi
    fi

    sleep 10
done
