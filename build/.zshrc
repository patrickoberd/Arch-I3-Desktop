# Zsh configuration for Arch Linux i3wm Desktop
# Powered by oh-my-zsh with powerlevel10k theme

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    git
    docker
    kubectl
    helm
    python
    rust
    golang
    npm
    zsh-autosuggestions
    zsh-syntax-highlighting
    fzf
)

source $ZSH/oh-my-zsh.sh

# User configuration

# Preferred editor
export EDITOR='nvim'
export VISUAL='nvim'

# Aliases
alias ls='eza --icons'
alias ll='eza -la --icons'
alias lt='eza --tree --icons'
alias cat='bat'
alias vim='nvim'
alias k='kubectl'
alias h='helm'
alias g='git'

# Git aliases
alias gst='git status'
alias gaa='git add --all'
alias gc='git commit -v'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# Docker aliases
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias di='docker images'

# Kubernetes aliases
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias kex='kubectl exec -it'

# Custom functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# FZF configuration
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# History configuration
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ===== QUALITY OF LIFE ENHANCEMENTS =====

# Clipboard helpers for noVNC (web-based VNC clipboard workarounds)
alias cb='xclip -selection clipboard -o'              # Get clipboard contents
alias pbcopy='xclip -selection clipboard -i'           # Copy to clipboard (macOS-style)
alias pbpaste='xclip -selection clipboard -o'          # Paste from clipboard (macOS-style)
alias clip='xclip -selection clipboard'                # Pipe to clipboard

# Quick directory access
alias proj='cd ~/projects'
alias tmp='cd /tmp'
alias dl='cd ~/Downloads'
alias docs='cd ~/Documents'
alias conf='cd ~/.config'
alias work='cd ~/workspace'

# System shortcuts
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias search='pacman -Ss'
alias cleanup='sudo pacman -Sc'
alias orphans='sudo pacman -Rns $(pacman -Qtdq)'

# Enhanced Docker shortcuts
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcl='docker compose logs -f'
alias dce='docker compose exec'
alias dcb='docker compose build'
alias dcp='docker compose pull'
alias dprune='docker system prune -af --volumes'

# Enhanced Git shortcuts
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gcm='git commit -m'
alias gcam='git commit -am'
alias gd='git diff'
alias gds='git diff --staged'
alias gps='git push'
alias gpl='git pull'
alias gf='git fetch'
alias gcl='git clone'

# Tmux helpers
alias t='tmux attach || tmux new'                      # Attach to session or create new
alias ta='tmux attach -t'                              # Attach to named session
alias tl='tmux list-sessions'                          # List sessions
alias tn='tmux new -s'                                 # New named session
alias tk='tmux kill-session -t'                        # Kill named session

# Quick notes system
note() {
    local notes_dir="$HOME/notes"
    mkdir -p "$notes_dir"
    local note_file="$notes_dir/$(date +%Y-%m-%d).md"

    if [ $# -eq 0 ]; then
        # No arguments: open today's note in editor
        $EDITOR "$note_file"
    else
        # Arguments provided: append to today's note
        echo "## $(date +%H:%M) - $*" >> "$note_file"
        echo "Quick note added to $note_file"
    fi
}

notes() {
    local notes_dir="$HOME/notes"
    mkdir -p "$notes_dir"

    if command -v fzf &> /dev/null; then
        # Use fzf to search and open notes
        local selected=$(ls -t "$notes_dir"/*.md 2>/dev/null | fzf --preview 'bat --style=numbers --color=always {}')
        [ -n "$selected" ] && $EDITOR "$selected"
    else
        # Fallback: list recent notes
        echo "Recent notes:"
        ls -lt "$notes_dir"/*.md 2>/dev/null | head -10
    fi
}

# Workspace layout helpers
save-workspace() {
    local layout_dir="$HOME/.config/i3/layouts"
    mkdir -p "$layout_dir"
    local workspace_num=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).num')
    local layout_file="$layout_dir/workspace-${workspace_num}.json"
    i3-save-tree --workspace "$workspace_num" > "$layout_file"
    echo "Workspace $workspace_num layout saved to $layout_file"
}

# System information shortcuts
alias cpu='watch -n1 "cat /proc/cpuinfo | grep MHz"'
alias temp='watch -n1 sensors'
alias ports='netstat -tulanp'
alias listening='ss -tulpn'

# File operations helpers
alias cp='cp -iv'                                       # Interactive, verbose copy
alias mv='mv -iv'                                       # Interactive, verbose move
alias rm='rm -iv'                                       # Interactive, verbose remove
alias mkdir='mkdir -pv'                                 # Create parent dirs, verbose

# Quick searches
alias findfile='fd -H'                                  # Find files (including hidden)
alias findtext='rg'                                     # Find text in files

# Extract any archive
extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar x $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# FZF key bindings (if not already loaded by plugin)
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh

# Welcome message
if [[ -o interactive ]]; then
    echo "🎨 Welcome to Arch Linux i3wm Desktop"
    echo "💻 Development environment ready!"
    echo ""
fi
