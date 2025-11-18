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
  description = "Container image (cached from GHCR to local registry)"
  default     = "docker-registry.registry.svc.cluster.local:5000/patrickoberd/arch-i3-desktop:latest"
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
  display_name = "CPU Limit (Burst)"
  description  = "Maximum CPU cores for builds and compilation (guaranteed minimum: 2 cores)"
  type         = "string"
  default      = "4"
  icon         = "/icon/memory.svg"
  mutable      = false
  order        = 1

  option {
    name  = "2 Cores (Minimum)"
    value = "2"
  }
  option {
    name  = "4 Cores (Full Node)"
    value = "4"
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
  default      = 20
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
  default      = 12
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
  description  = "Automatically open Firefox with VS Code on workspace startup"
  type         = "bool"
  default      = "true"
  icon         = "/icon/firefox.svg"
  mutable      = true
  order        = 31
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

    # Wait for Selkies WebRTC to be ready
    timeout 90 bash -c 'until nc -z localhost 8082; do sleep 1; done'
    echo "Selkies WebRTC is ready!"

    # Wait for code-server to be ready
    timeout 60 bash -c 'until nc -z localhost 8080; do sleep 1; done'
    echo "code-server is ready!"

    # Install Continue extension for AI code assistance
    echo "Installing Continue extension..."
    code-server --install-extension continue.continue || echo "Note: Continue extension may already be installed"

    # Configure Continue with KServe (serverless inference)
    echo "Configuring Continue with KServe..."
    mkdir -p ~/.continue

    cat > ~/.continue/config.json <<'CONTINUE_CONFIG'
{
  "models": [
    {
      "title": "Qwen 2.5 Coder 3B (Fast & Light)",
      "provider": "openai",
      "model": "qwen-coder-7b",
      "apiBase": "http://qwen-coder-7b-predictor.kserve-inference.svc.cluster.local/openai/v1",
      "apiKey": "dummy-key-not-required",
      "contextLength": 16384,
      "completionOptions": {
        "temperature": 0.2,
        "topP": 0.95,
        "maxTokens": 2048,
        "presencePenalty": 0.0,
        "frequencyPenalty": 0.0
      }
    },
    {
      "title": "DeepSeek Coder 6.7B (Best Quality)",
      "provider": "openai",
      "model": "deepseek-coder-6.7b",
      "apiBase": "http://deepseek-coder-6.7b-predictor.kserve-inference.svc.cluster.local/openai/v1",
      "apiKey": "dummy-key-not-required",
      "contextLength": 16384,
      "completionOptions": {
        "temperature": 0.2,
        "topP": 0.95,
        "maxTokens": 2048,
        "presencePenalty": 0.0,
        "frequencyPenalty": 0.0
      }
    },
    {
      "title": "StarCoder2 3B (619 Languages)",
      "provider": "openai",
      "model": "starcoder2-3b",
      "apiBase": "http://starcoder2-3b-predictor.kserve-inference.svc.cluster.local/openai/v1",
      "apiKey": "dummy-key-not-required",
      "contextLength": 16384,
      "completionOptions": {
        "temperature": 0.2,
        "topP": 0.95,
        "maxTokens": 2048,
        "presencePenalty": 0.0,
        "frequencyPenalty": 0.0
      }
    },
    {
      "title": "Yi Coder 9B (128K Context)",
      "provider": "openai",
      "model": "yi-coder-9b",
      "apiBase": "http://yi-coder-9b-predictor.kserve-inference.svc.cluster.local/openai/v1",
      "apiKey": "dummy-key-not-required",
      "contextLength": 32768,
      "completionOptions": {
        "temperature": 0.2,
        "topP": 0.95,
        "maxTokens": 2048,
        "presencePenalty": 0.0,
        "frequencyPenalty": 0.0
      }
    }
  ],
  "tabAutocompleteModel": {
    "title": "DeepSeek Coder 6.7B (Autocomplete)",
    "provider": "openai",
    "model": "deepseek-coder-6.7b",
    "apiBase": "http://deepseek-coder-6.7b-predictor.kserve-inference.svc.cluster.local/openai/v1",
    "apiKey": "dummy-key-not-required",
    "contextLength": 8192,
    "completionOptions": {
      "temperature": 0.1,
      "topP": 0.95,
      "maxTokens": 256,
      "presencePenalty": 0.0,
      "frequencyPenalty": 0.0
    }
  },
  "embeddingsProvider": {
    "provider": "transformers.js"
  },
  "slashCommands": [
    {
      "name": "edit",
      "description": "Edit selected code"
    },
    {
      "name": "comment",
      "description": "Add comments to code"
    },
    {
      "name": "share",
      "description": "Export conversation"
    },
    {
      "name": "cmd",
      "description": "Generate shell command"
    }
  ],
  "customCommands": [
    {
      "name": "test",
      "description": "Generate tests for the selected code",
      "prompt": "Generate comprehensive unit tests for this code:\n\n{{{ input }}}"
    },
    {
      "name": "optimize",
      "description": "Optimize the selected code",
      "prompt": "Analyze and suggest performance optimizations for this code:\n\n{{{ input }}}"
    },
    {
      "name": "explain",
      "description": "Explain the selected code",
      "prompt": "Explain how this code works in detail, including its purpose and key concepts:\n\n{{{ input }}}"
    },
    {
      "name": "docs",
      "description": "Generate documentation",
      "prompt": "Generate comprehensive documentation for this code:\n\n{{{ input }}}"
    }
  ],
  "allowAnonymousTelemetry": false,
  "docs": []
}
CONTINUE_CONFIG

    echo "Continue extension configured successfully!"
    echo ""
    echo "NOTE: First AI request may take 10-15 minutes (GPU provisioning + model load)"
    echo "      Subsequent requests will be fast. KServe will buffer your request automatically."

    # Start file server for upload/download
    echo "Starting file server..."
    /usr/local/bin/file-server.sh start

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

# Selkies WebRTC desktop access (native clipboard support!)
resource "coder_app" "selkies" {
  agent_id     = coder_agent.main.id
  slug         = "selkies"
  display_name = "🚀 Desktop (Selkies WebRTC)"
  url          = "http://localhost:8082"
  icon         = "https://cdn.icon-icons.com/icons2/2699/PNG/512/archlinux_logo_icon_167835.png"
  subdomain    = true
  share        = "owner"

  healthcheck {
    url       = "http://localhost:8082"
    interval  = 5
    threshold = 15
  }
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

# File server for upload/download
resource "coder_app" "file_server" {
  agent_id     = coder_agent.main.id
  slug         = "files"
  display_name = "📁 Files"
  url          = "http://localhost:8888"
  icon         = "📁"
  subdomain    = true
  share        = "owner"

  healthcheck {
    url       = "http://localhost:8888"
    interval  = 10
    threshold = 6
  }
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

  # Terraform timeouts for long-running operations
  # Allows up to 45 minutes for initial image pull (1.5GB from ghcr.io)
  timeouts {
    create = "45m"
    delete = "5m"
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

      # Image pull policy - Always checks registry for latest digest
      # Ensures workspace always uses newest :latest tag after builds
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
      # Resources
      resources {
        requests = {
          cpu    = "2" # Fixed at 2 cores for scheduling - always fits on 4 vCPU nodes
          memory = "${data.coder_parameter.memory.value}Gi"
        }
        limits = {
          cpu    = data.coder_parameter.cpu.value # User selection - allows bursting
          memory = "${parseint(data.coder_parameter.memory.value, 10) + 2}Gi"
        }
      }

      # Volume mounts
      volume_mount {
        name       = "home"
        mount_path = "/home/coder"
      }

      # Startup probe - increased to handle long image pull
      # Max startup time: 10 + (240 × 10) = 2410 seconds = ~40 minutes
      # Covers: 30min image pull + 10min container start buffer
      startup_probe {
        tcp_socket {
          port = 6080
        }
        initial_delay_seconds = 10
        period_seconds        = 10  # Check every 10 seconds
        timeout_seconds       = 5   # Allow 5 seconds per probe
        failure_threshold     = 240 # 240 failures = 40 minutes
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
       🖥️ Desktop (noVNC):       Standard VNC access (copy button in toolbar)
       🚀 Desktop (Selkies):     WebRTC access with NATIVE CLIPBOARD SUPPORT!
                                 → Use Ctrl+C/Ctrl+V directly in your browser!
                                 → Lower latency, smoother experience
                                 → Recommended for daily use

    Access VS Code Web IDE:
       Click the "VS Code" app in the Coder dashboard
       Or open Firefox and navigate to: http://localhost:8080
       (Firefox opens automatically on first workspace launch)

    Access terminal:
       Click the "Terminal" app or use SSH

    Clipboard Comparison:
       noVNC:    Use clipboard button in top toolbar (limited)
       Selkies:  Native Ctrl+C/Ctrl+V works directly! 🎉

    i3wm Quick Start:
       - Mod+Space:    Quick Actions Menu (apps, screenshots, file server, tools)
       - Mod+Enter:    Open terminal (alacritty)
       - Mod+d:        Application launcher (dmenu)
       - Mod+p:        Application launcher (rofi)
       - Mod+Shift+f:  Open Firefox
       - Mod+1-9:      Switch workspaces
       - Mod+Shift+q:  Close window
       - Mod+f:        Fullscreen
       - Mod+u:        Toggle file upload/download server

    Installed tools:
       - Languages: Python, Rust, Go, Node.js
       - Editors: VS Code (browser via code-server), Neovim, Vim
       - AI Code Assistant: Continue extension (powered by KServe)
         • Models: 4 available (Qwen 2.5, DeepSeek, StarCoder2, Yi Coder)
         • Switch models via dropdown in Continue.dev sidebar
         • Autocomplete: DeepSeek Coder 6.7B (best quality, HumanEval 80.2)
         • Press Ctrl+L to open AI chat
         • Tab autocomplete enabled
         • Select code → Right-click → Continue → Explain/Optimize/Test/Document
         • First request: 10-15 min cold start (GPU provision), then fast
         • All models scale-to-zero when not in use (KServe serverless)
       - Shell: Zsh with oh-my-zsh + powerlevel10k
       - Containers: Docker CLI, kubectl, helm
       - System: htop, btop, tmux, fzf, ripgrep
       - Launchers: dmenu, rofi

    Resources:
       - CPU Guaranteed: 2 cores (always available)
       - CPU Limit (Burst): ${data.coder_parameter.cpu.value} cores (for builds/compilation)
       - Memory: ${data.coder_parameter.memory.value}GB (limit: ${parseint(data.coder_parameter.memory.value, 10) + 2}GB)
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
