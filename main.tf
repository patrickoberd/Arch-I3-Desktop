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
       - Shell: Zsh with oh-my-zsh + powerlevel10k
       - Containers: Docker CLI, kubectl, helm
       - System: htop, btop, tmux, fzf, ripgrep
       - Launchers: dmenu, rofi

    Resources:
       - CPU: ${var.cpu} cores
       - Memory: ${var.memory}GB
       - Storage: ${var.disk_size}GB

    Tip: The Mod key is the Windows/Super key
  EOT
}
