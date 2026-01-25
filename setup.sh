#!/bin/bash
set -e

# ==============================================================================
# 1. User Context Detection
# ==============================================================================
# Detect the original user and home directory when running with sudo
REAL_USER="${SUDO_USER:-$(whoami)}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# ==============================================================================
# Configuration
# ==============================================================================
TARGET_PARENT="$REAL_HOME/Projects/Code"

echo "=============================================================================="
echo "  Hadev's Workstation Setup"
echo "  Target User: $REAL_USER ($REAL_HOME)"
echo "=============================================================================="

# ==============================================================================
# 2. Dependency Check (Ansible)
# ==============================================================================
if ! command -v ansible >/dev/null; then
    echo "[+] Ansible not found. Installing..."
    
    if [ "$EUID" -ne 0 ]; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq software-properties-common
        sudo add-apt-repository --yes --update ppa:ansible/ansible
        sudo apt-get install -y -qq ansible git
    else
        apt-get update -qq
        apt-get install -y -qq software-properties-common
        add-apt-repository --yes --update ppa:ansible/ansible
        apt-get install -y -qq ansible git
    fi
fi

# ==============================================================================
# 3. Playbook Execution
# ==============================================================================

# Function to run ansible with proper user context and privilege escalation
run_ansible() {
    echo "[+] Running Ansible Playbook..."
    
    # Construct command to run as root while injecting original user facts
    CMD="ansible-playbook -i inventory local.yml -e ansible_user_id=$REAL_USER -e ansible_user_dir=$REAL_HOME"
    
    # Elevate privileges if not already root
    if [ "$EUID" -ne 0 ]; then
        CMD="sudo $CMD"
    fi
    
    # Execute playbook, passing through any additional arguments (e.g., --tags)
    $CMD "$@"
}

# Execute the ansible playbook
run_ansible "$@"

# ==============================================================================
# 4. Repository Relocation
# ==============================================================================
CURRENT_DIR=$(pwd)
REPO_NAME=$(basename "$CURRENT_DIR")
TARGET_DIR="$TARGET_PARENT/$REPO_NAME"

# Check if repository is already in the target location
if [ "$CURRENT_DIR" != "$TARGET_DIR" ]; then
    echo "=============================================================================="
    echo "  Relocating Repository"
    echo "=============================================================================="

    if [ ! -d "$TARGET_PARENT" ]; then
        echo "[!] Error: Parent directory $TARGET_PARENT does not exist."
        exit 1
    fi

    if [ -d "$TARGET_DIR" ]; then
        echo "[!] Target directory $TARGET_DIR already exists. Skipping move."
    else
        echo "[+] Moving repo to: $TARGET_DIR"
        # Copy with sudo to bypass read permissions
        sudo cp -a "$CURRENT_DIR" "$TARGET_DIR"
        # Fix ownership on the destination immediately
        sudo chown -R "$REAL_USER:$REAL_USER" "$TARGET_DIR"
        # Remove the old directory
        sudo rm -rf "$CURRENT_DIR"   
             
        # Restore ownership to the standard user
        if [ "$EUID" -ne 0 ]; then
            sudo chown -R "$REAL_USER:$REAL_USER" "$TARGET_DIR"
        else
            chown -R "$REAL_USER:$REAL_USER" "$TARGET_DIR"
        fi
        
        echo ""
        echo "✅ Setup Complete!"
        echo "   Please change directory: cd $TARGET_DIR"
    fi
else
    echo ""
    echo "✅ Execution Complete!"
fi