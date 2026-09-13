#!/bin/bash
set -euo pipefail

# ==============================================================================
#  Bootstrap and entry point for Hadev's Workstation Setup.
#
#  Responsibilities:
#    1. Detect the invoking user (even under sudo) so the playbook can
#       target their home directory.
#    2. Install Ansible if missing.
#    3. Bootstrap config.yml from the example template.
#    4. Execute the playbook, forwarding any extra arguments to Ansible.
#
#  Run from anywhere:  ./setup.sh [extra ansible-playbook arguments]
#  Common usage:       ./setup.sh --tags "dotfiles"
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ==============================================================================
# 1. User Context Detection
# ==============================================================================
# When the script runs under sudo, SUDO_USER holds the original user. The
# playbook needs that identity so files land in the right home directory.
REAL_USER="${SUDO_USER:-$(whoami)}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

# ==============================================================================
# Helpers
# ==============================================================================

# Run a command as root, elevating with sudo only when necessary.
as_root() {
    if [[ $EUID -ne 0 ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

usage() {
    cat <<EOF
Usage: ./setup.sh [ansible-playbook options]

Bootstraps and runs the local workstation playbook (local.yml).

The script automatically:
  - installs Ansible if it is missing
  - creates config.yml from config.yml.example on first run
  - runs the playbook with your user context injected
    (-e ansible_user_id / -e ansible_user_dir)

All arguments are passed through to ansible-playbook untouched.

Common tags (limit the run to part of the setup):
  core           workspace dirs, SSH key, git config, custom scripts
  system         base packages, linters
  terminal       everything terminal (fonts, starship, tmux, bashrc)
  dotfiles       bashrc_extras, .bashrc wiring, tmux config
  languages      pyenv (Python) and nvm (Node.js)
  python         pyenv and its build dependencies
  nvm            nvm only
  docker         docker and container tools
  virtualization KVM/QEMU, packer, vagrant (+ libvirt plugin)

Examples:
  ./setup.sh                      # full setup
  ./setup.sh --tags "dotfiles"    # only update dotfiles
  ./setup.sh --tags "languages"   # only install language tooling
  ./setup.sh --list-tags          # show every available tag
  ./setup.sh --syntax-check       # validate the playbook without running it
EOF
}

install_ansible() {
    echo "[+] Ansible not found. Installing..."
    as_root apt-get update -qq
    as_root apt-get install -y -qq software-properties-common
    as_root add-apt-repository --yes --update ppa:ansible/ansible
    as_root apt-get install -y -qq ansible git
}

# Copy config.yml.example to config.yml on first run. The playbook requires
# the file to exist, and its contents are personal, so stop after creating it.
ensure_config() {
    if [[ ! -f config.yml ]]; then
        echo "[+] Configuration file not found. Creating from template..."
        cp config.yml.example config.yml
        echo "[!] A new config.yml file has been created."
        echo "[!] Please review and update config.yml with your personal information."
        echo "[!] Exiting setup. Run ./setup.sh again after configuring."
        exit 0
    fi
}

# True when the given arguments only ask Ansible to parse/report (no tasks
# run), so privilege elevation is unnecessary and would only prompt for sudo.
is_parse_only() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            --syntax-check|--list-tags|--list-hosts) return 0 ;;
        esac
    done
    return 1
}

# Execute the playbook as root while injecting the original user context,
# forwarding any additional arguments (e.g. --tags, --syntax-check).
run_playbook() {
    echo "[+] Running Ansible Playbook..."
    if is_parse_only "$@"; then
        ansible-playbook -i inventory local.yml \
            -e "ansible_user_id=$REAL_USER" \
            -e "ansible_user_dir=$REAL_HOME" \
            "$@"
        return
    fi
    as_root ansible-playbook -i inventory local.yml \
        -e "ansible_user_id=$REAL_USER" \
        -e "ansible_user_dir=$REAL_HOME" \
        "$@"
}

# ==============================================================================
# Main
# ==============================================================================
if [[ $# -ge 1 && ( $1 == "-h" || $1 == "--help" ) ]]; then
    usage
    exit 0
fi

command -v ansible >/dev/null || install_ansible

echo "=============================================================================="
echo "  Hadev's Workstation Setup"
echo "  Target User: $REAL_USER ($REAL_HOME)"
echo "=============================================================================="

ensure_config
run_playbook "$@"

echo ""
echo "✅ Setup Complete!"
