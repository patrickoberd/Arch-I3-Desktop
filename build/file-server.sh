#!/bin/bash
# File Upload/Download Server for Browser Access
# Simple HTTP server for easy file transfers

set -euo pipefail

PORT=8888
SERVE_DIR="$HOME/Downloads"
PID_FILE="/tmp/file-server.pid"

# Ensure Downloads directory exists
mkdir -p "$SERVE_DIR"

# Check if server is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Start server
start_server() {
    if is_running; then
        notify-send "File Server" "Already running on port $PORT" -t 3000
        echo "File server is already running on http://localhost:$PORT"
        return 0
    fi

    # Start Python HTTP server in background
    cd "$SERVE_DIR"
    python -m http.server $PORT > /tmp/file-server.log 2>&1 &
    echo $! > "$PID_FILE"

    sleep 1

    if is_running; then
        notify-send "File Server Started" "Access at http://localhost:$PORT\nServing: $SERVE_DIR" -t 5000 -i folder
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  File Server Started Successfully"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  URL:       http://localhost:$PORT"
        echo "  Directory: $SERVE_DIR"
        echo ""
        echo "  Open in Firefox to:"
        echo "   - Browse files"
        echo "   - Download files to your computer"
        echo "   - Upload files (drag & drop in browser)"
        echo ""
        echo "  Stop server: Press Mod+u again"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # Open in Firefox after a short delay
        sleep 1
        firefox "http://localhost:$PORT" &
    else
        notify-send "File Server Error" "Failed to start server" -t 5000 -u critical
        echo "Failed to start file server"
        return 1
    fi
}

# Stop server
stop_server() {
    if ! is_running; then
        notify-send "File Server" "Not running" -t 3000
        echo "File server is not running"
        return 0
    fi

    pid=$(cat "$PID_FILE")
    kill "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"

    notify-send "File Server Stopped" "Server on port $PORT stopped" -t 3000
    echo "File server stopped"
}

# Toggle server
toggle_server() {
    if is_running; then
        stop_server
    else
        start_server
    fi
}

# Main
case "${1:-toggle}" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    toggle)
        toggle_server
        ;;
    status)
        if is_running; then
            echo "File server is running on http://localhost:$PORT"
            echo "PID: $(cat $PID_FILE)"
            echo "Serving: $SERVE_DIR"
        else
            echo "File server is not running"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|toggle|status}"
        exit 1
        ;;
esac
