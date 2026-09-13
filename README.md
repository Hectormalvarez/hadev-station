# Hadev's Workstation Setup

This Ansible playbook automates the setup of my personal Ubuntu development environment using a role-based architecture.

## What it does

The project is organized into roles that handle specific aspects of the workstation setup:

### Core Role
- **Workspace:** Creates standard directory structure: `~/Projects/{Code,Study,Lab,Scratch}`.
- **Security:** Generates an **Ed25519** SSH key pair.
- **Git:** Configures global user identity and defaults new branches to `main`.
- **Custom Scripts:** Downloads user scripts to `~/.local/bin` (defined in `config.yml`).

### System Role
- **Core Utilities:** `git`, `curl`, `wget`, `vim`, `tmux`, `htop`, `sqlite3`, plus linters (`ansible-lint`, `yamllint`).
- **Extra Packages:** `bat`, `fzf`, `xclip`, `copyq`, `gh` (configurable in `config.yml`).
- **Build Tools:** Installs the dependencies required to compile Python with pyenv.

### Languages Role
- **Python:** Installs `pyenv` and `pyenv-virtualenv` for managing Python versions.
- **Node.js:** Installs `nvm` (Node Version Manager) for managing Node versions.

### Terminal Role
- **Shell:** Templates `~/.bashrc_extras` (pyenv/nvm init, `bat`/`ll`/`toclip` aliases, fzf key bindings, Starship prompt) and wires it into `.bashrc`.
- **Fonts:** Installs the Meslo Nerd Font into `~/.local/share/fonts`.
- **Starship:** Installs the Starship shell prompt.
- **tmux:** Deploys a managed `~/.tmux.conf` with sensible defaults (mouse support, vi copy mode, 256-color/truecolor, custom status bar). Structured so the TPM plugin manager can be enabled later.

### Docker Role
- **Container Tools:** Docker and related containerization tools.

### Virtualization Role
- **HashiCorp:** Adds the official HashiCorp apt repository and installs `packer` and `vagrant`.
- **Vagrant:** Installs the `vagrant-libvirt` plugin (with its build dependencies) for libvirt providers.

## Usage

### Quick Start (Bootstrap & Updates)

This project uses a wrapper script to handle permission elevation and user context detection automatically.

To install or update your configuration:

```bash
./setup.sh

```

### Partial Updates

The setup script passes arguments through to Ansible. You can run specific parts of the configuration using tags:

```bash
# Only update dotfiles (aliases, prompt, tmux config, fonts)
./setup.sh --tags "dotfiles"

# Only install language tooling (pyenv, nvm)
./setup.sh --tags "languages"

# See every available tag
./setup.sh --list-tags
```

### Manual Execution (Advanced)

If you prefer to run `ansible-playbook` directly without the wrapper, you must run as root and explicitly inject your user context to ensure file permissions are correct:

```bash
sudo ansible-playbook -i inventory local.yml \
  -e "ansible_user_id=$(whoami)" \
  -e "ansible_user_dir=$HOME"

```
