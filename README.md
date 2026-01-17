# Hadev's Workstation Setup

This Ansible playbook automates the setup of my personal Ubuntu development environment.

## What it does

### 1. System & Tools

- **Updates Cache:** Refreshes apt repositories.
- **Core Utilities:** `git`, `curl`, `wget`, `htop`, `tmux`, `vim`.
- **Modern CLI:** `fastfetch` (system info), `bat` (cat replacement), `fzf` (fuzzy finder).
- **Build Tools:** Installs dependencies required to build Python and other packages.

### 2. Development Environment

- **Python:** Installs `pyenv` and `pyenv-virtualenv` for managing Python versions.
- **Node.js:** Installs `nvm` (Node Version Manager) for managing Node versions.
- **Scripts:** Downloads custom user scripts to `~/.local/bin`.

### 3. Configuration & Security

- **Workspace:** Creates standard directory structure: `~/Projects/{Code,Study,Lab,Scratch}`.
- **Security:** Generates an **Ed25519** SSH key pair.
- **Git:** Configures global user identity and defaults new branches to `main`.
- **Shell:** Wires up `.bashrc` with aliases, tool paths, and environment variables.

## Usage

### Quick Start (Bootstrap)

On a fresh machine, run the setup script. This installs Ansible, runs the playbook, and relocates the repo to `~/Projects/Code`.

```bash
./setup.sh

```

### Manual Run

If you already have Ansible installed and just want to apply updates:

```bash
ansible-playbook -i inventory local.yml -K
```
