# Arch Linux i3wm Desktop for Coder
# Browser-accessible development environment with full GUI

FROM archlinux:latest

# Optimize mirrors and enable features for faster, more reliable builds
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Sy --noconfirm reflector && \
    reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist && \
    echo "[multilib]" >> /etc/pacman.conf && \
    echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf && \
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf && \
    pacman -Syyu --noconfirm && \
    rm -rf /var/cache/pacman/pkg/*

# Install core packages
RUN pacman -S --noconfirm \
    # Window manager & X11
    xorg-server xorg-xauth xorg-xinit xorg-xrandr xorg-xdpyinfo \
    i3-wm i3status i3lock dmenu rofi \
    # Notifications & QoL
    dunst \
    # VNC & remote access
    tigervnc \
    # Terminal & shell
    alacritty zsh zsh-completions \
    # Development tools
    base-devel git curl wget \
    gcc clang make cmake ninja \
    python python-pip python-pipx \
    nodejs npm \
    go rust \
    neovim vim \
    # System utilities
    htop btop ncdu \
    tmux \
    fzf ripgrep fd bat eza \
    jq yq \
    openssh sudo \
    xclip xsel xdotool \
    # File managers
    ranger thunar \
    # Browsers & GUI apps
    firefox \
    # QoL tools
    qalculate-gtk \
    clipmenu \
    # Networking
    net-tools iproute2 bind openbsd-netcat \
    # Container tools
    docker kubectl helm \
    # Fonts
    ttf-dejavu ttf-liberation ttf-hack \
    noto-fonts noto-fonts-emoji \
    ttf-firacode-nerd \
    # Media & screenshots
    feh maim imagemagick \
    # Archive tools
    unzip zip p7zip \
    # Additional libraries for code-server
    libxkbfile && \
    # Clean package cache to reduce image size
    rm -rf /var/cache/pacman/pkg/*

# Install noVNC for browser access
RUN mkdir -p /opt/noVNC /opt/websockify && \
    curl -L https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar -xz -C /opt/noVNC --strip-components=1 && \
    curl -L https://github.com/novnc/websockify/archive/v0.11.0.tar.gz | tar -xz -C /opt/websockify --strip-components=1 && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Install code-server (VS Code in browser) - direct binary to avoid AUR/makepkg issues
RUN CODE_SERVER_VERSION=4.96.2 && \
    curl -fsSL "https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-amd64.tar.gz" | tar -xz -C /tmp && \
    mv "/tmp/code-server-${CODE_SERVER_VERSION}-linux-amd64" /usr/local/lib/code-server && \
    ln -s /usr/local/lib/code-server/bin/code-server /usr/local/bin/code-server

# Create user
RUN useradd -m -s /bin/zsh -G wheel coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install oh-my-zsh to /etc/skel (will be copied to home directory at runtime)
RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /etc/skel/.oh-my-zsh && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /etc/skel/.oh-my-zsh/custom/themes/powerlevel10k && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions /etc/skel/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /etc/skel/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Note: Coder agent is installed at runtime in start-vnc.sh
# This ensures the correct version is always used

# Copy default configuration files to skeleton directory
# These will be copied to user home on first run
RUN mkdir -p /etc/skel/.config/i3 /etc/skel/.config/dunst /etc/skel/.config/alacritty
COPY build/i3-config /etc/skel/.config/i3/config
COPY build/i3status.conf /etc/skel/.config/i3/i3status.conf
COPY build/dunstrc /etc/skel/.config/dunst/dunstrc
COPY build/.zshrc /etc/skel/.zshrc
COPY build/.tmux.conf /etc/skel/.tmux.conf

# Create Continue.dev configuration for Ollama AI coding assistant
RUN mkdir -p /etc/skel/.continue && \
    cat > /etc/skel/.continue/config.json << 'EOF'
{
  "models": [
    {
      "title": "Llama 3.3 70B",
      "provider": "ollama",
      "model": "llama3.3:70b",
      "apiBase": "http://ollama.ollama.svc.cluster.local:11434"
    },
    {
      "title": "CodeLlama",
      "provider": "ollama",
      "model": "codellama",
      "apiBase": "http://ollama.ollama.svc.cluster.local:11434"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Starcoder 3b",
    "provider": "ollama",
    "model": "starcoder2:3b",
    "apiBase": "http://ollama.ollama.svc.cluster.local:11434"
  },
  "embeddingsProvider": {
    "provider": "transformers.js"
  }
}
EOF

# Copy startup scripts
COPY build/start-vnc.sh /usr/local/bin/start-vnc.sh
COPY build/setup-i3-modkey.sh /usr/local/bin/setup-i3-modkey.sh
COPY build/resolution-menu.sh /usr/local/bin/resolution-menu.sh

# Copy QoL scripts
COPY build/file-server.sh /usr/local/bin/file-server.sh
COPY build/quick-actions.sh /usr/local/bin/quick-actions.sh
COPY build/screenshot.sh /usr/local/bin/screenshot.sh

# Create alacritty config
RUN cat > /etc/skel/.config/alacritty/alacritty.toml << 'EOF'
[window]
opacity = 0.95
padding = { x = 10, y = 10 }

[font]
normal = { family = "FiraCode Nerd Font", style = "Regular" }
size = 11.0

[colors.primary]
background = "#1e1e2e"
foreground = "#cdd6f4"

[colors.cursor]
text = "#1e1e2e"
cursor = "#f5e0dc"

[[keyboard.bindings]]
key = "V"
mods = "Control|Shift"
action = "Paste"

[[keyboard.bindings]]
key = "C"
mods = "Control|Shift"
action = "Copy"
EOF

# Make scripts executable
# Note: No VNC password needed - secured by Coder authentication + localhost-only access
RUN chmod +x /usr/local/bin/start-vnc.sh && \
    chmod +x /usr/local/bin/setup-i3-modkey.sh && \
    chmod +x /usr/local/bin/resolution-menu.sh && \
    chmod +x /usr/local/bin/file-server.sh && \
    chmod +x /usr/local/bin/quick-actions.sh && \
    chmod +x /usr/local/bin/screenshot.sh

# Environment setup
ENV DISPLAY=:1
ENV HOME=/home/coder
ENV USER=coder
ENV SHELL=/bin/zsh

WORKDIR /home/coder
USER coder

# Expose VNC, noVNC, and code-server ports
EXPOSE 5901 6080 8080

CMD ["/usr/local/bin/start-vnc.sh"]
