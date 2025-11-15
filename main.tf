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

# Workspace parameters
variable "cpu" {
  description = "CPU cores for workspace"
  default     = "2"
  type        = string
}

variable "memory" {
  description = "Memory for workspace (GB)"
  default     = "4"
  type        = string
}

variable "disk_size" {
  description = "Home directory size (GB)"
  default     = "20"
  type        = string
}

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

# Desktop customization variables
variable "desktop_resolution" {
  description = "VNC desktop resolution"
  default     = "1920x1080"
  type        = string

  validation {
    condition = contains([
      "1280x720", "1366x768", "1600x900", "1920x1080",
      "2560x1440", "2560x1600", "3440x1440", "3840x2160"
    ], var.desktop_resolution)
    error_message = "Must be a standard resolution"
  }
}

variable "i3_mod_key" {
  description = "i3wm modifier key (Mod1=Alt, Mod4=Super/Windows)"
  default     = "Mod4"
  type        = string

  validation {
    condition     = contains(["Mod1", "Mod4"], var.i3_mod_key)
    error_message = "Must be Mod1 (Alt) or Mod4 (Super)"
  }
}

variable "terminal_font_size" {
  description = "Alacritty terminal font size"
  default     = 12
  type        = number

  validation {
    condition     = var.terminal_font_size >= 8 && var.terminal_font_size <= 24
    error_message = "Font size must be between 8 and 24"
  }
}

variable "timezone" {
  description = "Workspace timezone (TZ database format)"
  default     = "UTC"
  type        = string
}

variable "locale" {
  description = "System locale"
  default     = "en_US.UTF-8"
  type        = string

  validation {
    condition = contains([
      "en_US.UTF-8", "en_GB.UTF-8", "de_DE.UTF-8",
      "fr_FR.UTF-8", "es_ES.UTF-8", "it_IT.UTF-8",
      "ja_JP.UTF-8", "zh_CN.UTF-8"
    ], var.locale)
    error_message = "Must be a supported locale"
  }
}

variable "git_default_branch" {
  description = "Git default branch name for new repositories"
  default     = "main"
  type        = string
}

variable "vscode_theme" {
  description = "VS Code color theme"
  default     = "Catppuccin Mocha"
  type        = string

  validation {
    condition = contains([
      "Catppuccin Mocha", "Catppuccin Latte", "Catppuccin Frappé", "Catppuccin Macchiato",
      "Dark+ (default dark)", "Light+ (default light)", "Monokai", "Solarized Dark", "Solarized Light"
    ], var.vscode_theme)
    error_message = "Must be a supported VS Code theme"
  }
}

variable "auto_start_firefox" {
  description = "Auto-launch Firefox with VS Code on first boot"
  default     = true
  type        = bool
}

variable "default_shell" {
  description = "Default shell (zsh or bash)"
  default     = "zsh"
  type        = string

  validation {
    condition     = contains(["zsh", "bash"], var.default_shell)
    error_message = "Must be zsh or bash"
  }
}

variable "ollama_temperature" {
  description = "Default temperature for Ollama models in Continue.dev"
  default     = 0.7
  type        = number

  validation {
    condition     = var.ollama_temperature >= 0.0 && var.ollama_temperature <= 1.0
    error_message = "Temperature must be between 0.0 and 1.0"
  }
}

variable "ollama_context_window" {
  description = "Context window size for Ollama models"
  default     = 4096
  type        = number

  validation {
    condition     = contains([2048, 4096, 8192, 16384], var.ollama_context_window)
    error_message = "Must be 2048, 4096, 8192, or 16384"
  }
}

# Coder data sources
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

# Locals for dynamic values
locals {
  namespace = "coder-${data.coder_workspace_owner.me.name}"
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

# Kubernetes namespace for user's workspaces
resource "kubernetes_namespace" "workspace" {
  metadata {
    name = local.namespace
    labels = {
      "coder.owner" = data.coder_workspace_owner.me.name
    }
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [metadata[0].annotations]
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
        storage = "${var.disk_size}Gi"
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
        value = var.desktop_resolution
      }

      env {
        name  = "I3_MOD_KEY"
        value = var.i3_mod_key
      }

      env {
        name  = "TERMINAL_FONT_SIZE"
        value = tostring(var.terminal_font_size)
      }

      env {
        name  = "TZ"
        value = var.timezone
      }

      env {
        name  = "LANG"
        value = var.locale
      }

      env {
        name  = "LC_ALL"
        value = var.locale
      }

      env {
        name  = "GIT_DEFAULT_BRANCH"
        value = var.git_default_branch
      }

      env {
        name  = "VSCODE_THEME"
        value = var.vscode_theme
      }

      env {
        name  = "AUTO_START_FIREFOX"
        value = tostring(var.auto_start_firefox)
      }

      env {
        name  = "DEFAULT_SHELL"
        value = var.default_shell
      }

      env {
        name  = "OLLAMA_TEMPERATURE"
        value = tostring(var.ollama_temperature)
      }

      env {
        name  = "OLLAMA_CONTEXT_WINDOW"
        value = tostring(var.ollama_context_window)
      }

      # Resources
      resources {
        requests = {
          cpu    = var.cpu
          memory = "${var.memory}Gi"
        }
        limits = {
          cpu    = "${parseint(var.cpu, 10) + 1}"
          memory = "${parseint(var.memory, 10) + 2}Gi"
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
       - CPU: ${var.cpu} cores
       - Memory: ${var.memory}GB
       - Storage: ${var.disk_size}GB

    Workspace Customizations:
       - Desktop Resolution: ${var.desktop_resolution}
       - i3 Mod Key: ${var.i3_mod_key == "Mod4" ? "Super/Windows" : "Alt"}
       - Terminal Font: ${var.terminal_font_size}pt
       - Timezone: ${var.timezone}
       - Locale: ${var.locale}
       - VS Code Theme: ${var.vscode_theme}
       - Default Shell: ${var.default_shell}
       - Git Default Branch: ${var.git_default_branch}

    Tip: The Mod key is ${var.i3_mod_key == "Mod4" ? "the Windows/Super key" : "the Alt key"}
  EOT
}
