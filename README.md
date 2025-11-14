# 🎨 Arch Linux i3wm Desktop for Coder

A fully-featured Arch Linux desktop environment with i3wm tiling window manager, accessible entirely from your browser. Perfect for development, system administration, or just having a beautiful Linux desktop in the cloud!

## ✨ Features

### 🖥️ Desktop Environment
- **i3wm** - Lightweight, highly configurable tiling window manager
- **noVNC** - Browser-based VNC access (no client installation needed!)
- **Catppuccin Mocha** theme - Beautiful, modern color scheme
- **1920x1080** default resolution

### 🔧 Development Tools
- **Languages**: Python, Rust, Go, Node.js, C/C++
- **Editors**: VS Code (browser via code-server), Neovim, Vim
- **Container Tools**: Docker CLI, kubectl, Helm
- **Version Control**: Git with SSH support
- **Terminal**: Alacritty with FiraCode Nerd Font

### 💻 Modern CLI Experience
- **Zsh** with oh-my-zsh framework
- **Powerlevel10k** theme with git integration
- **Auto-suggestions** and **syntax highlighting**
- **fzf** - Fuzzy finder for everything
- **eza** - Modern `ls` replacement
- **bat** - `cat` with syntax highlighting
- **ripgrep**, **fd** - Fast search tools
- **htop**, **btop** - System monitors

### 🎮 Applications
- **VS Code** - Full IDE accessible from browser
- **Firefox** - Web browser
- **Thunar** - GUI file manager
- **Ranger** - Terminal file manager
- **dmenu** & **rofi** - Application launchers

### ⚡ Quality-of-Life Features
- **Desktop Notifications** - Dunst notification daemon with Catppuccin theme
- **Rich Status Bar** - Custom i3status showing CPU, RAM, disk, network, and time
- **Smart Screenshots** - maim with selection tool and notifications
- **Clipboard Tools** - xclip/xsel for clipboard management
- **Scratchpad Terminal** - Quick-access floating terminal (`Mod+minus`)
- **Auto Workspace Assignment** - Apps automatically go to designated workspaces
- **Smart Window Rules** - Dialogs auto-float, better window management

## 📋 Prerequisites

1. **Coder instance** running (see `DEPLOYMENT-ROADMAP.md` Phase 5)
2. **GitHub repository** with this code (for automated builds)
3. **kubectl** access to your Kubernetes cluster
4. (Optional) **Docker** installed locally if you want manual builds

## 🚀 Quick Start

### Step 1: Automated Build via GitHub Actions (Recommended!)

The Docker image is **automatically built and pushed** to GitHub Container Registry whenever you push changes to the `main` branch or create a version tag.

#### Initial Setup (One-Time):

1. **Enable GitHub Actions permissions**:
   - Go to your repo: Settings → Actions → General
   - Under "Workflow permissions", select **"Read and write permissions"**
   - Save changes

2. **Push your code** to trigger first build:
   ```bash
   git add .
   git commit -m "Add Docker image workflow"
   git push origin main
   ```

3. **Monitor the build**:
   - Go to Actions tab in your GitHub repository
   - Wait ~10-15 minutes for first build (subsequent builds: ~3-5 min)

4. **Make image public** (after first build):
   - Go to https://github.com/users/YOUR_USERNAME/packages
   - Click on `arch-i3-desktop` package
   - Package settings → Change visibility to **Public**

#### Using Version Tags:

```bash
# Create a versioned release
git tag v1.0.0
git push origin v1.0.0

# This creates:
# - ghcr.io/username/arch-i3-desktop:v1.0.0
# - ghcr.io/username/arch-i3-desktop:latest
```

### Step 2: Manual Build (Alternative)

If you prefer building locally or need to test changes:

```bash
cd coder-templates/arch-i3-desktop

# Build the image (takes 10-15 minutes first time)
docker build --no-cache -t arch-i3-desktop:latest .

# Test locally (optional)
docker run -d -p 6080:6080 -p 8080:8080 \
  --name arch-test \
  arch-i3-desktop:latest

# Access at http://localhost:6080 (desktop) or http://localhost:8080 (VS Code)
# Stop test: docker stop arch-test && docker rm arch-test

# Push to GHCR manually
docker tag arch-i3-desktop:latest ghcr.io/your-username/arch-i3-desktop:latest
echo $GITHUB_TOKEN | docker login ghcr.io -u your-username --password-stdin
docker push ghcr.io/your-username/arch-i3-desktop:latest
```

### Step 3: Update Coder Template

The `main.tf` is already configured to use GHCR:

```terraform
variable "image" {
  description = "Container image (automatically built via GitHub Actions)"
  default     = "ghcr.io/fluxkompensat/arch-i3-desktop:latest"
  type        = string
}
```

**Update the username** if different from `fluxkompensat`.

### Step 4: Create Template in Coder

```bash
# Login to Coder
coder login https://coder.coder.example.com

# Create the template
coder templates create arch-i3-desktop \
  --directory ./coder-templates/arch-i3-desktop \
  --name "Arch Linux i3wm Desktop"

# Or push as a new version to existing template
coder templates push arch-i3-desktop \
  --directory ./coder-templates/arch-i3-desktop
```

### Step 5: Create Workspace

1. Go to Coder dashboard: `https://coder.coder.example.com`
2. Click **"Create Workspace"**
3. Select **"Arch Linux i3wm Desktop"** template
4. Choose parameters:
   - **CPU**: 2-4 cores recommended
   - **Memory**: 4-8 GB recommended
   - **Disk**: 20+ GB recommended
5. Click **"Create"**
6. Wait 1-2 minutes for workspace to start
7. Click **"🖥️ Desktop (noVNC)"** for desktop or **"📝 VS Code"** for IDE
8. Enjoy your Arch Linux workspace! 🎉

## ⌨️ i3wm Keybindings

### Essential
| Key | Action |
|-----|--------|
| `Mod` | Windows/Super key |
| `Mod+Enter` | Open terminal (Alacritty) |
| `Mod+space` | **Application launcher (rofi)** - Primary |
| `Mod+d` | Application launcher (dmenu) - Alternative |
| `Mod+Shift+q` | Close window |
| `Mod+Shift+c` | Reload i3 config |
| `Mod+Shift+r` | Restart i3 |
| `Mod+Shift+e` | Exit i3 |

### Navigation
| Key | Action |
|-----|--------|
| `Mod+h/j/k/l` | Focus left/down/up/right |
| `Mod+1-9` | Switch to workspace 1-9 |
| `Mod+Shift+1-9` | Move window to workspace |
| `Mod+f` | Fullscreen toggle |

### Layouts
| Key | Action |
|-----|--------|
| `Mod+s` | Stacking layout |
| `Mod+w` | Tabbed layout |
| `Mod+e` | Toggle split layout |
| `Mod+b` | Split horizontal |
| `Mod+v` | Split vertical |
| `Mod+r` | Resize mode |

### Applications
| Key | Action |
|-----|--------|
| `Mod+Shift+f` | Open Firefox |
| `Mod+Shift+t` | Open Thunar |
| `Mod+c` | Open VS Code (code-server) in Firefox |
| `Mod+p` | Rofi launcher (alternative drun mode) |
| `Mod+Tab` | Rofi window switcher |
| `Mod+x` | Lock screen |

### Screenshots & Clipboard
| Key | Action |
|-----|--------|
| `Print` | Screenshot (full screen) |
| `Mod+Print` | Screenshot (selection) |
| `Mod+Shift+s` | Screenshot (selection) - Alternative |
| `Mod+Insert` | Clipboard manager |

### Scratchpad
| Key | Action |
|-----|--------|
| `Mod+minus` | Toggle scratchpad terminal |
| `Mod+Shift+minus` | Move window to scratchpad |

## 🛠️ Customization

### Security Architecture

This workspace is secured by Coder's authentication layer:

**VNC Access:**
- VNC server listens only on `localhost:5901` (no external access)
- No VNC password needed - network isolation provides security
- All desktop access is via noVNC through Coder dashboard
- noVNC access requires Coder login (authenticated + encrypted)

**Access Flow:**
```
User → Coder Auth → HTTPS → noVNC (port 6080) → localhost:5901
        ✅ Login    ✅ TLS    ✅ In pod        ✅ Localhost only
```

Direct VNC connections are blocked - only Coder-authenticated access works.

### Modify i3 Config

Edit `build/i3-config` to customize:
- Keybindings
- Colors/theme
- Workspace names
- Startup applications
- Gaps size

### Add More Packages

Edit `Dockerfile` and add to the `pacman -S` command:
```dockerfile
RUN pacman -S --noconfirm \
    # ... existing packages ...
    your-new-package \
    another-package
```

### Change Terminal Theme

Edit `build/.zshrc` or create `~/.config/alacritty/alacritty.toml` in the container.

## 🐛 Troubleshooting

### Workspace won't start

```bash
# Check pod status
kubectl get pods -n coder-workspaces

# View logs
kubectl logs -n coder-workspaces <pod-name>

# Common issues:
# - Image pull errors: Check registry authentication
# - Resource limits: Increase CPU/memory in template
# - Node selector: Verify coder nodepool exists
```

### Desktop not loading in browser

```bash
# Check if noVNC is running
kubectl exec -n coder-workspaces <pod-name> -- nc -z localhost 6080

# Check VNC server
kubectl exec -n coder-workspaces <pod-name> -- nc -z localhost 5901

# View startup logs
kubectl logs -n coder-workspaces <pod-name> | grep -i vnc
```

### Slow performance

- Increase CPU/memory in template parameters
- Check if pod is running on correct nodepool
- Monitor resources: `kubectl top pod -n coder-workspaces`

### Can't install packages

```bash
# Inside workspace terminal
sudo pacman -Syu  # Update package database
sudo pacman -S package-name  # Install package
```

### Persistent data not saved

- Ensure PVC is created: `kubectl get pvc -n coder-workspaces`
- Check volume mount: All data in `/home/coder` is persistent
- Data outside `/home/coder` is ephemeral!

## 📦 What's Included

### Development Languages
- Python 3 + pip + pipx
- Rust + Cargo
- Go
- Node.js + npm
- GCC + Clang + Make + CMake

### CLI Tools
- **Search**: ripgrep, fd, fzf
- **Files**: eza, bat, ranger
- **System**: htop, btop, ncdu
- **Network**: curl, wget, netstat, dig
- **Containers**: docker, kubectl, helm
- **Version Control**: git, gh (GitHub CLI)
- **Multiplexer**: tmux
- **Editor**: neovim, vim

### GUI Applications
- Firefox (web browser)
- Thunar (file manager)
- Alacritty (terminal)

## 🎓 Tips & Tricks

### 1. Use Workspaces Like a Pro

i3wm uses numbered workspaces (1-9). Organize them:
- **1: term** - Terminals
- **2: code** - Editors
- **3: web** - Firefox
- **4: files** - File managers
- **5-8**: Your custom uses

### 2. Learn tmux

Inside the terminal, use `tmux` for multiplexing:
```bash
tmux                    # Start new session
Ctrl+b "                # Split horizontally
Ctrl+b %                # Split vertically
Ctrl+b arrow            # Navigate panes
Ctrl+b d                # Detach session
tmux attach             # Reattach
```

### 3. Fuzzy Finding Everything

- `Ctrl+r`: Search command history
- `Ctrl+t`: Search files
- `Alt+c`: Change directory (fzf)

### 4. Git Configuration

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

### 5. Customize Zsh Theme

```bash
p10k configure  # Run powerlevel10k configuration wizard
```

## 🔒 Security Notes

**Desktop Access Security:**
- VNC server restricted to localhost only (no external access)
- No VNC password - secured by Coder's authentication layer
- All desktop access via Coder dashboard (HTTPS + authentication required)
- Direct VNC connections blocked by network isolation

**Container Security:**
- Workspace runs as user `coder` (UID 1000, non-root)
- Sudo access is passwordless (acceptable for isolated containers)
- SSH keys stored in `/home/coder/.ssh` are persistent
- Container isolation provided by Kubernetes pod security

**Network Architecture:**
- Kubernetes network policies can further restrict pod-to-pod traffic
- All external access proxied through Coder's authenticated reverse proxy
- TLS encryption for all browser-based access

## 📚 Additional Resources

- [i3 User's Guide](https://i3wm.org/docs/userguide.html)
- [Arch Linux Wiki](https://wiki.archlinux.org/)
- [Coder Documentation](https://coder.com/docs)
- [noVNC Documentation](https://github.com/novnc/noVNC)

## 🤝 Contributing

Want to improve this template?
1. Add more tools/applications
2. Improve the i3 config
3. Create alternative themes
4. Add startup scripts
5. Optimize image size

## 📝 License

This template is provided as-is for use with Coder. Feel free to modify and distribute!

## 🎉 Enjoy Your Desktop!

You now have a full Arch Linux desktop environment running in Kubernetes, accessible from anywhere with just a browser. Happy coding! 🚀
