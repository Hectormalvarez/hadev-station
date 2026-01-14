# Hadev's Workstation Setup

This Ansible playbook automates the setup of my personal Ubuntu development environment.

## What it does

### 1. System & Tools
* **Updates Cache:** Refreshes apt repositories.
* **Installs Core Utilities:** `git`, `curl`, `wget`, `htop`, `tmux`, `vim`.
* **Installs Build Tools:** `build-essential`, `python3-pip`.

### 2. Configuration
* **Workspace:** Ensures the `~/Projects` directory exists.
* **Git:** Configures global user name, email, and defaults new branches to `main`.

## Usage
Run the playbook locally:

```bash
ansible-playbook -i inventory local.yml -K
```