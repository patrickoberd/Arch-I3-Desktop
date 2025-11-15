terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

# Non-user-facing variables (not exposed as parameters)
variable "image" {
  description = "Container image (automatically built via GitHub Actions)"
  default     = "ghcr.io/patrickoberd/arch-i3-desktop:latest"
  type        = string
}

variable "coder_url" {
  description = "Coder server URL (cluster-internal service)"
  default     = "http://coder.coder.svc.cluster.local"
  type        = string
}

# Coder data sources
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

# ============================================================================
# CODER PARAMETERS - User-configurable workspace options
# ============================================================================

# Infrastructure parameters (immutable - set at creation)
data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU Cores"
  description  = "Number of CPU cores allocated to the workspace"
  type         = "string"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = false
  order        = 1

  option {
    name  = "2 Cores"
    value = "2"
  }
  option {
    name  = "4 Cores"
    value = "4"
  }
  option {
    name  = "6 Cores"
    value = "6"
  }
  option {
    name  = "8 Cores"
    value = "8"
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory (GB)"
  description  = "Amount of RAM allocated to the workspace"
  type         = "string"
  default      = "4"
  icon         = "/icon/memory.svg"
  mutable      = false
  order        = 2

  option {
    name  = "2 GB"
    value = "2"
  }
  option {
    name  = "4 GB"
    value = "4"
  }
  option {
    name  = "8 GB"
    value = "8"
  }
  option {
    name  = "16 GB"
    value = "16"
  }
}

data "coder_parameter" "disk_size" {
  name         = "disk_size"
  display_name = "Disk Size (GB)"
  description  = "Size of persistent home directory storage"
  type         = "number"
  default      = "20"
  icon         = "/emojis/1f4be.png"
  mutable      = false
  order        = 3

  validation {
    min = 10
    max = 500
  }
}

# Desktop customization parameters (mutable - can change after creation)
data "coder_parameter" "desktop_resolution" {
  name         = "desktop_resolution"
  display_name = "Desktop Resolution"
  description  = "VNC desktop screen resolution"
  type         = "string"
  default      = "1920x1080"
  icon         = "/icon/desktop.svg"
  mutable      = true
  order        = 10

  option {
    name  = "1280x720 (HD)"
    value = "1280x720"
  }
  option {
    name  = "1366x768 (WXGA)"
    value = "1366x768"
  }
  option {
    name  = "1600x900 (HD+)"
    value = "1600x900"
  }
  option {
    name  = "1920x1080 (Full HD)"
    value = "1920x1080"
  }
  option {
    name  = "2560x1440 (QHD)"
    value = "2560x1440"
  }
  option {
    name  = "2560x1600 (WQXGA)"
    value = "2560x1600"
  }
  option {
    name  = "3440x1440 (UWQHD)"
    value = "3440x1440"
  }
  option {
    name  = "3840x2160 (4K)"
    value = "3840x2160"
  }
}

data "coder_parameter" "i3_mod_key" {
  name         = "i3_mod_key"
  display_name = "i3wm Modifier Key"
  description  = "Primary modifier key for i3 window manager shortcuts"
  type         = "string"
  default      = "Mod4"
  icon         = "/icon/keyboard.svg"
  mutable      = true
  order        = 11

  option {
    name  = "Super/Windows Key (Mod4)"
    value = "Mod4"
  }
  option {
    name  = "Alt Key (Mod1)"
    value = "Mod1"
  }
}

data "coder_parameter" "terminal_font_size" {
  name         = "terminal_font_size"
  display_name = "Terminal Font Size"
  description  = "Font size for Alacritty terminal (8-24 points)"
  type         = "number"
  default      = "12"
  icon         = "/icon/terminal.svg"
  mutable      = true
  order        = 12

  validation {
    min = 8
    max = 24
  }
}

data "coder_parameter" "vscode_theme" {
  name         = "vscode_theme"
  display_name = "VS Code Theme"
  description  = "Color theme for VS Code editor"
  type         = "string"
  default      = "Catppuccin Mocha"
  icon         = "/icon/code.svg"
  mutable      = true
  order        = 13

  option {
    name  = "Catppuccin Mocha (Dark)"
    value = "Catppuccin Mocha"
  }
  option {
    name  = "Catppuccin Latte (Light)"
    value = "Catppuccin Latte"
  }
  option {
    name  = "Catppuccin Frappé (Dark)"
    value = "Catppuccin Frappé"
  }
  option {
    name  = "Catppuccin Macchiato (Dark)"
    value = "Catppuccin Macchiato"
  }
  option {
    name  = "Dark+ (VS Code Default Dark)"
    value = "Dark+ (default dark)"
  }
  option {
    name  = "Light+ (VS Code Default Light)"
    value = "Light+ (default light)"
  }
  option {
    name  = "Monokai"
    value = "Monokai"
  }
  option {
    name  = "Solarized Dark"
    value = "Solarized Dark"
  }
  option {
    name  = "Solarized Light"
    value = "Solarized Light"
  }
}

# System settings parameters (mutable)
data "coder_parameter" "timezone" {
  name         = "timezone"
  display_name = "Timezone"
  description  = "System timezone (TZ database format)"
  type         = "string"
  default      = "UTC"
  icon         = "/icon/clock.svg"
  mutable      = true
  order        = 20

  option {
    name  = "UTC"
    value = "UTC"
  }
  option {
    name  = "US Eastern (America/New_York)"
    value = "America/New_York"
  }
  option {
    name  = "US Central (America/Chicago)"
    value = "America/Chicago"
  }
  option {
    name  = "US Mountain (America/Denver)"
    value = "America/Denver"
  }
  option {
    name  = "US Pacific (America/Los_Angeles)"
    value = "America/Los_Angeles"
  }
  option {
    name  = "Europe/London"
    value = "Europe/London"
  }
  option {
    name  = "Europe/Paris"
    value = "Europe/Paris"
  }
  option {
    name  = "Europe/Berlin"
    value = "Europe/Berlin"
  }
  option {
    name  = "Europe/Vienna"
    value = "Europe/Vienna"
  }
  option {
    name  = "Asia/Tokyo"
    value = "Asia/Tokyo"
  }
  option {
    name  = "Asia/Shanghai"
    value = "Asia/Shanghai"
  }
  option {
    name  = "Australia/Sydney"
    value = "Australia/Sydney"
  }
}

data "coder_parameter" "locale" {
  name         = "locale"
  display_name = "System Locale"
  description  = "Language and regional settings"
  type         = "string"
  default      = "en_US.UTF-8"
  icon         = "/icon/globe.svg"
  mutable      = true
  order        = 21

  option {
    name  = "English (US)"
    value = "en_US.UTF-8"
  }
  option {
    name  = "English (GB)"
    value = "en_GB.UTF-8"
  }
  option {
    name  = "German"
    value = "de_DE.UTF-8"
  }
  option {
    name  = "French"
    value = "fr_FR.UTF-8"
  }
  option {
    name  = "Spanish"
    value = "es_ES.UTF-8"
  }
  option {
    name  = "Italian"
    value = "it_IT.UTF-8"
  }
  option {
    name  = "Japanese"
    value = "ja_JP.UTF-8"
  }
  option {
    name  = "Chinese (Simplified)"
    value = "zh_CN.UTF-8"
  }
}

data "coder_parameter" "default_shell" {
  name         = "default_shell"
  display_name = "Default Shell"
  description  = "Default terminal shell (zsh or bash)"
  type         = "string"
  default      = "zsh"
  icon         = "/icon/terminal.svg"
  mutable      = true
  order        = 22

  option {
    name  = "Zsh (with oh-my-zsh)"
    value = "zsh"
  }
  option {
    name  = "Bash"
    value = "bash"
  }
}

# Development settings parameters (mutable)
data "coder_parameter" "git_default_branch" {
  name         = "git_default_branch"
  display_name = "Git Default Branch"
  description  = "Default branch name for new Git repositories"
  type         = "string"
  default      = "main"
  icon         = "/icon/git.svg"
  mutable      = true
  order        = 30

  option {
    name  = "main"
    value = "main"
  }
  option {
    name  = "master"
    value = "master"
  }
  option {
    name  = "develop"
    value = "develop"
  }
}

data "coder_parameter" "auto_start_firefox" {
  name         = "auto_start_firefox"
  display_name = "Auto-start Firefox"
  description  = "Automatically launch Firefox with VS Code on first boot"
  type         = "bool"
  default      = "true"
  icon         = "/icon/firefox.svg"
  mutable      = true
  order        = 31
}

# AI/Ollama settings parameters (mutable)
data "coder_parameter" "ollama_temperature" {
  name         = "ollama_temperature"
  display_name = "Ollama Temperature"
  description  = "Default temperature for Ollama AI models (0.0=deterministic, 1.0=creative)"
  type         = "number"
  default      = "0.7"
  icon         = "/icon/ai.svg"
  mutable      = true
  order        = 40

  validation {
    min = 0
    max = 1
  }
}

data "coder_parameter" "ollama_context_window" {
  name         = "ollama_context_window"
  display_name = "Ollama Context Window"
  description  = "Context window size for Ollama models (larger = more memory)"
  type         = "string"
  default      = "4096"
  icon         = "/icon/ai.svg"
  mutable      = true
  order        = 41

  option {
    name  = "2048 tokens (Fast)"
    value = "2048"
  }
  option {
    name  = "4096 tokens (Balanced)"
    value = "4096"
  }
  option {
    name  = "8192 tokens (Large)"
    value = "8192"
  }
  option {
    name  = "16384 tokens (Maximum)"
    value = "16384"
  }
}

# Locals for dynamic values
locals {
  namespace = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
}

# Coder agent for authentication and connection
resource "coder_agent" "main" {
  arch           = "amd64"
  os             = "linux"
  startup_script = <<-EOT
    #!/bin/bash
    set -e

    # Wait for VNC to be ready
    timeout 60 bash -c 'until nc -z localhost 5901; do sleep 1; done'
    echo "VNC server is ready!"

    # Wait for noVNC to be ready
    timeout 60 bash -c 'until nc -z localhost 6080; do sleep 1; done'
    echo "noVNC is ready!"

    # Wait for code-server to be ready
    timeout 60 bash -c 'until nc -z localhost 8080; do sleep 1; done'
    echo "code-server is ready!"

    # Install Continue extension for AI code assistance
    echo "Installing Continue extension..."
    code-server --install-extension continue.continue || echo "Note: Continue extension may already be installed"

    # Configure Continue with Ollama
    echo "Configuring Continue with Ollama..."
    mkdir -p ~/.local/share/code-server/User/globalStorage/continue.continue

    cat > ~/.local/share/code-server/User/globalStorage/continue.continue/config.json <<'CONTINUE_CONFIG'
{
  "models": [
    {
      "title": "CodeLlama 7B (Fast)",
      "provider": "ollama",
      "model": "codellama:7b",
      "apiBase": "http://ollama.ollama.svc.cluster.local:11434"
    },
    {
      "title": "Qwen2.5 Coder 7B (Smart)",
      "provider": "ollama",
      "model": "qwen2.5-coder:7b",
      "apiBase": "http://ollama.ollama.svc.cluster.local:11434"
    },
    {
      "title": "DeepSeek Coder V2 16B (Powerful)",
      "provider": "ollama",
      "model": "deepseek-coder-v2:16b",
      "apiBase": "http://ollama.ollama.svc.cluster.local:11434"
    }
  ],
  "tabAutocompleteModel": {
    "title": "CodeLlama 7B",
    "provider": "ollama",
    "model": "codellama:7b",
    "apiBase": "http://ollama.ollama.svc.cluster.local:11434"
  },
  "embeddingsProvider": {
    "provider": "ollama",
    "model": "nomic-embed-text",
    "apiBase": "http://ollama.ollama.svc.cluster.local:11434"
  },
  "customCommands": [
    {
      "name": "explain",
      "description": "Explain the selected code",
      "prompt": "Explain how this code works in detail:\n\n{{{ input }}}"
    },
    {
      "name": "optimize",
      "description": "Optimize the selected code",
      "prompt": "Optimize this code for better performance and readability:\n\n{{{ input }}}"
    },
    {
      "name": "test",
      "description": "Generate tests for the selected code",
      "prompt": "Generate comprehensive unit tests for this code:\n\n{{{ input }}}"
    },
    {
      "name": "document",
      "description": "Add documentation to the selected code",
      "prompt": "Add clear documentation and comments to this code:\n\n{{{ input }}}"
    }
  ]
}
CONTINUE_CONFIG

    echo "Continue extension configured successfully!"
    echo "Workspace is fully initialized"
  EOT

  # Metadata
  display_apps {
    vscode                 = false
    vscode_insiders        = false
    web_terminal           = true
    port_forwarding_helper = true
    ssh_helper             = true
  }

  env = {
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = data.coder_workspace_owner.me.email
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email
    OLLAMA_HOST         = "http://ollama.ollama.svc.cluster.local:11434"
  }
}

# noVNC web desktop access
resource "coder_app" "novnc" {
  agent_id     = coder_agent.main.id
  slug         = "desktop"
  display_name = "🖥️ Desktop (noVNC)"
  url          = "http://localhost:6080"
  icon         = "https://cdn.icon-icons.com/icons2/2699/PNG/512/archlinux_logo_icon_167835.png"
  subdomain    = true
  share        = "owner"

  # Health check disabled - noVNC is confirmed working but check stuck at INITIALIZING
  # healthcheck {
  #   url       = "http://localhost:6080"
  #   interval  = 5
  #   threshold = 10
  # }
}

# VS Code (code-server) web IDE access
resource "coder_app" "vscode" {
  agent_id     = coder_agent.main.id
  slug         = "vscode"
  display_name = "📝 VS Code"
  url          = "http://localhost:8080"
  icon         = "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/vscode/vscode-original.svg"
  subdomain    = true
  share        = "owner"

  # Health check for code-server
  healthcheck {
    url       = "http://localhost:8080"
    interval  = 5
    threshold = 10
  }
}

# Terminal access
resource "coder_app" "terminal" {
  agent_id     = coder_agent.main.id
  slug         = "terminal"
  display_name = "💻 Terminal"
  icon         = "/icon/terminal.svg"
  command      = "zsh"
}

# Kubernetes namespace for workspace
resource "kubernetes_namespace" "workspace" {
  metadata {
    name = local.namespace
    labels = {
      "coder.owner"     = data.coder_workspace_owner.me.name
      "coder.workspace" = data.coder_workspace.me.name
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

# Persistent volume claim for home directory
resource "kubernetes_persistent_volume_claim" "home" {
  metadata {
    name      = "home-${lower(data.coder_workspace_owner.me.name)}-${lower(data.coder_workspace.me.name)}"
    namespace = kubernetes_namespace.workspace.metadata[0].name

    labels = {
      "coder.owner"     = data.coder_workspace_owner.me.name
      "coder.workspace" = data.coder_workspace.me.name
    }
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "exoscale-sbs" # Exoscale Block Storage

    resources {
      requests = {
        storage = "${data.coder_parameter.disk_size.value}Gi"
      }
    }
  }
}

# Workspace pod
resource "kubernetes_pod" "main" {
  count = data.coder_workspace.me.start_count

  metadata {
    name      = "coder-${lower(data.coder_workspace_owner.me.name)}-${lower(data.coder_workspace.me.name)}"
    namespace = kubernetes_namespace.workspace.metadata[0].name

    labels = {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/instance" = data.coder_workspace.me.name
      "app.kubernetes.io/owner"    = data.coder_workspace_owner.me.name
    }
  }

  spec {
    # Security context
    security_context {
      run_as_user = 1000
      fs_group    = 1000
    }

    # Run on coder nodepool
    node_selector = {
      "workload-type" = "coder"
    }

    # Main container
    container {
      name  = "desktop"
      image = var.image

      # Image pull policy
      image_pull_policy = "Always"

      # Environment variables
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.main.token
      }

      env {
        name  = "CODER_AGENT_URL"
        value = var.coder_url
      }

      # Customization environment variables
      env {
        name  = "DESKTOP_RESOLUTION"
        value = data.coder_parameter.desktop_resolution.value
      }

      env {
        name  = "I3_MOD_KEY"
        value = data.coder_parameter.i3_mod_key.value
      }

      env {
        name  = "TERMINAL_FONT_SIZE"
        value = tostring(data.coder_parameter.terminal_font_size.value)
      }

      env {
        name  = "TZ"
        value = data.coder_parameter.timezone.value
      }

      env {
        name  = "LANG"
        value = data.coder_parameter.locale.value
      }

      env {
        name  = "LC_ALL"
        value = data.coder_parameter.locale.value
      }

      env {
        name  = "GIT_DEFAULT_BRANCH"
        value = data.coder_parameter.git_default_branch.value
      }

      env {
        name  = "VSCODE_THEME"
        value = data.coder_parameter.vscode_theme.value
      }

      env {
        name  = "AUTO_START_FIREFOX"
        value = tostring(data.coder_parameter.auto_start_firefox.value)
      }

      env {
        name  = "DEFAULT_SHELL"
        value = data.coder_parameter.default_shell.value
      }

      env {
        name  = "OLLAMA_TEMPERATURE"
        value = tostring(data.coder_parameter.ollama_temperature.value)
      }

      env {
        name  = "OLLAMA_CONTEXT_WINDOW"
        value = data.coder_parameter.ollama_context_window.value
      }

      # Resources
      resources {
        requests = {
          cpu    = data.coder_parameter.cpu.value
          memory = "${data.coder_parameter.memory.value}Gi"
        }
        limits = {
          cpu    = "${parseint(data.coder_parameter.cpu.value, 10) + 1}"
          memory = "${parseint(data.coder_parameter.memory.value, 10) + 2}Gi"
        }
      }

      # Volume mounts
      volume_mount {
        name       = "home"
        mount_path = "/home/coder"
      }

      # Startup probe
      startup_probe {
        tcp_socket {
          port = 6080
        }
        initial_delay_seconds = 10
        period_seconds        = 5
        timeout_seconds       = 3
        failure_threshold     = 30
      }

      # Liveness probe
      liveness_probe {
        tcp_socket {
          port = 6080
        }
        initial_delay_seconds = 30
        period_seconds        = 10
        timeout_seconds       = 3
        failure_threshold     = 3
      }

      # Readiness probe
      readiness_probe {
        tcp_socket {
          port = 6080
        }
        initial_delay_seconds = 10
        period_seconds        = 5
        timeout_seconds       = 3
        failure_threshold     = 3
      }
    }

    # Volumes
    volume {
      name = "home"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.home.metadata[0].name
      }
    }
  }
}

# Output instructions
output "access_instructions" {
  value = <<-EOT
    Arch Linux i3wm Desktop Workspace

    Access your desktop:
       Click the "Desktop (noVNC)" app in the Coder dashboard

    Access VS Code Web IDE:
       Click the "VS Code" app in the Coder dashboard
       Or open Firefox and navigate to: http://localhost:8080
       (Firefox opens automatically on first workspace launch)

    Access terminal:
       Click the "Terminal" app or use SSH

    i3wm Quick Start:
       - Mod+Enter:    Open terminal (alacritty)
       - Mod+d:        Application launcher
       - Mod+Shift+f:  Open Firefox
       - Mod+1-9:      Switch workspaces
       - Mod+Shift+q:  Close window
       - Mod+f:        Fullscreen

    Installed tools:
       - Languages: Python, Rust, Go, Node.js
       - Editors: VS Code (browser via code-server), Neovim, Vim
       - AI Code Assistant: Continue extension (powered by Ollama)
         • Press Ctrl+L to open AI chat
         • Tab autocomplete with CodeLlama
         • Select code → Right-click → Continue → Explain/Optimize/Test
       - Shell: Zsh with oh-my-zsh + powerlevel10k
       - Containers: Docker CLI, kubectl, helm
       - System: htop, btop, tmux, fzf, ripgrep
       - Launchers: dmenu, rofi

    Resources:
       - CPU: ${data.coder_parameter.cpu.value} cores
       - Memory: ${data.coder_parameter.memory.value}GB
       - Storage: ${data.coder_parameter.disk_size.value}GB

    Workspace Customizations:
       - Desktop Resolution: ${data.coder_parameter.desktop_resolution.value}
       - i3 Mod Key: ${data.coder_parameter.i3_mod_key.value == "Mod4" ? "Super/Windows" : "Alt"}
       - Terminal Font: ${data.coder_parameter.terminal_font_size.value}pt
       - Timezone: ${data.coder_parameter.timezone.value}
       - Locale: ${data.coder_parameter.locale.value}
       - VS Code Theme: ${data.coder_parameter.vscode_theme.value}
       - Default Shell: ${data.coder_parameter.default_shell.value}
       - Git Default Branch: ${data.coder_parameter.git_default_branch.value}

    Tip: The Mod key is ${data.coder_parameter.i3_mod_key.value == "Mod4" ? "the Windows/Super key" : "the Alt key"}
  EOT
}
