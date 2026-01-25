# Hadev's Workstation Setup

This Ansible playbook automates the setup of my personal Ubuntu development environment using a role-based architecture.

## What it does

The project is organized into roles that handle specific aspects of the workstation setup:

### Core Role
- **Updates Cache:** Refreshes apt repositories.
- **Core Utilities:** `git`, `curl`, `wget`, `htop`, `tmux`, `vim`.
- **Modern CLI:** `fastfetch` (system info), `bat` (cat replacement), `fzf` (fuzzy finder).
- **Build Tools:** Installs dependencies required to build Python and other packages.

### System Role
- **Workspace:** Creates standard directory structure: `~/Projects/{Code,Study,Lab,Scratch}`.
- **Security:** Generates an **Ed25519** SSH key pair.
- **Git:** Configures global user identity and defaults new branches to `main`.
- **Shell:** Wires up `.bashrc` with aliases, tool paths, and environment variables.

### Languages Role
- **Python:** Installs `pyenv` and `pyenv-virtualenv` for managing Python versions.
- **Node.js:** Installs `nvm` (Node Version Manager) for managing Node versions.

### Terminal Role
- **Shell Enhancements:** Additional terminal configuration and improvements.

### Docker Role
- **Container Tools:** Docker and related containerization tools.

### Scripts Role
- **Custom Scripts:** Downloads custom user scripts to `~/.local/bin`.

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
# Only update dotfiles (aliases, prompt, etc.)
./setup.sh --tags "dotfiles"

# Only update user scripts
./setup.sh --tags "scripts"

```

### Manual Execution (Advanced)

If you prefer to run `ansible-playbook` directly without the wrapper, you must run as root and explicitly inject your user context to ensure file permissions are correct:

```bash
sudo ansible-playbook -i inventory local.yml \
  -e "ansible_user_id=$(whoami)" \
  -e "ansible_user_dir=$HOME"

```
