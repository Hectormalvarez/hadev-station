#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# ==============================================================================
# Configuration
# ==============================================================================
# The destination parent folder (Must match what is in tasks/filesystem.yml)
TARGET_PARENT="$HOME/Projects/Code"

echo "=============================================================================="
echo "  Hadev's Workstation Setup"
echo "=============================================================================="

# 1. Install Ansible (if missing)
# ------------------------------------------------------------------------------
if ! command -v ansible >/dev/null; then
    echo "[+] Ansible not found. Installing..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq software-properties-common
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt-get install -y -qq ansible git
else
    echo "[+] Ansible is already installed."
fi

# 2. Run the Playbook
# ------------------------------------------------------------------------------
echo "[+] Running Ansible Playbook..."
# This runs the tasks that create ~/Projects/Code
ansible-playbook -i inventory local.yml -K

# 3. Relocate Repository
# ------------------------------------------------------------------------------
CURRENT_DIR=$(pwd)
REPO_NAME=$(basename "$CURRENT_DIR")
TARGET_DIR="$TARGET_PARENT/$REPO_NAME"

# Check if we are already in the correct location
if [ "$CURRENT_DIR" == "$TARGET_DIR" ]; then
    echo "[+] Repository is already in the correct location: $TARGET_DIR"
    exit 0
fi

echo "=============================================================================="
echo "  Relocating Repository"
echo "=============================================================================="

# Verify the parent directory exists (Ansible should have created it)
if [ ! -d "$TARGET_PARENT" ]; then
    echo "[!] Error: $TARGET_PARENT does not exist."
    echo "    Did the Ansible playbook fail to create the filesystem structure?"
    exit 1
fi

# Check if the target folder already exists to prevent overwriting
if [ -d "$TARGET_DIR" ]; then
    echo "[!] WARNING: Target directory $TARGET_DIR already exists."
    echo "    Skipping move to prevent overwriting data."
else
    echo "[+] Moving repo from: $CURRENT_DIR"
    echo "              to: $TARGET_DIR"
    
    # Move the directory
    mv "$CURRENT_DIR" "$TARGET_DIR"
    
    echo ""
    echo "✅ Setup Complete!"
    echo "------------------------------------------------------------------------------"
    echo "NOTE: Your terminal is still inside the old path."
    echo "      Please cd into the new location to continue working:"
    echo ""
    echo "      cd $TARGET_DIR"
    echo "------------------------------------------------------------------------------"
fi