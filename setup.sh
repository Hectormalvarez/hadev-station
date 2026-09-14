#!/bin/bash
# -e: exit on error; -u: error on unset vars; -o pipefail: fail on pipe errors;
# -o errtrace (-E): inherit the ERR trap inside functions and subshells, so
# failures in helpers like run_playbook() reach the failure reporter too.
set -Eeuo pipefail

# ==============================================================================
#  Bootstrap and entry point for Hadev's Workstation Setup.
#
#  Responsibilities:
#    1. Detect the invoking user (even under sudo) so the playbook can
#       target their home directory.
#    2. Install Ansible if missing.
#    3. Bootstrap config.yml from the example template.
#    4. Execute the playbook, forwarding any extra arguments to Ansible.
#    5. Report failures with a human-readable message (see report_failure).
#    6. Reject unrecognized dash-prefixed options before anything runs
#       (see validate_args / KNOWN_OPTIONS).
#
#  Run from anywhere:  ./setup.sh [extra ansible-playbook arguments]
#  Common usage:       ./setup.sh --tags "dotfiles"
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ==============================================================================
# Failure handling
# ==============================================================================
# One ERR trap (with `set -e` above) serves every failure path: it names the
# step that failed, keeps the original exit code, and adds only orientation —
# never a root-cause claim, since we do not parse the failing command's output.
# The raw error output stays visible above the message (US-003 / ADR-002).
CURRENT_STEP="startup"

report_failure() {
    local exit_code=$?
    echo ""
    echo "❌ Setup failed during: $CURRENT_STEP (exit code $exit_code)."
    case "$CURRENT_STEP" in
        "Ansible installation")
            echo "   The error above comes from the Ansible install step; the most"
            echo "   likely cause is no network access or an apt repository problem."
            echo "   Fix it, then run ./setup.sh again."
            ;;
        "Playbook run")
            echo "   The Ansible error above shows what failed. Fix it, then run"
            echo "   ./setup.sh again — re-running is safe: the playbook converges,"
            echo "   nothing needs manual un-doing."
            echo "   Note: ~/.bashrc_extras and ~/.tmux.conf are playbook-managed and"
            echo "   regenerated from templates on every run; hand-edits to them are"
            echo "   not preserved."
            ;;
        *)
            echo "   The error above shows what failed. Fix it, then run ./setup.sh again."
            ;;
    esac
    exit "$exit_code"
}
trap report_failure ERR

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

Recognized options are passed through to ansible-playbook; unrecognized
dash-prefixed options are rejected with this help.

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

# Options accepted on the setup.sh command line (US-004). Name-level only:
# option values and arity are never validated here, so a malformed option
# (e.g. --tags with no value) is forwarded untouched and Ansible reports its
# own error. Anything dash-prefixed but not listed is rejected before
# anything runs. Extend this array (one entry per line) to accept more
# ansible-playbook options.
KNOWN_OPTIONS=(
    -h --help
    --syntax-check --list-tags --list-hosts --list-tasks
    --tags -t --skip-tags --limit -l
    --check -C --diff -D --step --start-at-task
    --vault-id --vault-password-file
    -v -vv -vvv -vvvv
)

# Reject unknown dash-prefixed options (US-004 AC 1). Non-dash arguments are
# forwarded untouched (AC 4): only option names are judged, never values or
# arity. Runs first in Main so garbage arguments fail fast with exit 2 —
# distinct from config (1) and Ansible (4+) failures — regardless of machine
# state, without installing Ansible or touching config.yml.
validate_args() {
    local arg opt
    for arg in "$@"; do
        case "$arg" in
            "") continue ;;
            -*) ;;
            *) continue ;;
        esac
        for opt in "${KNOWN_OPTIONS[@]}"; do
            [[ $arg == "$opt" ]] && continue 2
        done
        echo "Unrecognized option: $arg"
        echo "If this is a valid ansible-playbook option, invoke ansible-playbook directly:"
        echo "  ansible-playbook -i inventory local.yml $arg"
        usage
        exit 2
    done
}

install_ansible() {
    CURRENT_STEP="Ansible installation"
    echo "[+] Ansible not found. Installing..."
    as_root apt-get update -qq
    as_root apt-get install -y -qq software-properties-common
    as_root add-apt-repository --yes --update ppa:ansible/ansible
    as_root apt-get install -y -qq ansible git
}

# Copy config.yml.example to config.yml on first run. The playbook requires
# the file to exist, and its contents are personal, so stop after creating it.
ensure_config() {
    CURRENT_STEP="Configuration check"
    if [[ ! -f config.yml ]]; then
        echo "[+] Configuration file not found. Creating from template..."
        cp config.yml.example config.yml
        echo "[!] A new config.yml file has been created."
        echo "[!] Please review and update config.yml with your personal information."
        echo "[!] Exiting setup. Run ./setup.sh again after configuring."
        exit 0
    fi

    # Validate the config parses before running anything (US-003, AC 5), so a
    # broken config gets a message pointing at the file instead of a generic
    # playbook parse error. Use the system interpreter explicitly: Ansible
    # (apt) ships with python3-yaml, while the PATH python3 may be a pyenv
    # build without PyYAML. This adds no dependency. If the system python is
    # somehow absent, skip the check — Ansible still reports parse errors
    # normally. stderr is discarded because YAML error output can echo file
    # contents, and config.yml holds personal data — never print it.
    local config_py="/usr/bin/python3"
    if [[ -x "$config_py" ]] && ! "$config_py" -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1], encoding="utf-8"))' config.yml 2>/dev/null; then
        echo "❌ config.yml could not be parsed."
        echo "   The problem is in: $SCRIPT_DIR/config.yml"
        echo "   Fix the YAML syntax (indentation, quotes, colons), then run ./setup.sh again."
        exit 1
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
    CURRENT_STEP="Playbook run"
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

validate_args "$@"

command -v ansible >/dev/null || install_ansible

echo "=============================================================================="
echo "  Hadev's Workstation Setup"
echo "  Target User: $REAL_USER ($REAL_HOME)"
echo "=============================================================================="

ensure_config
run_playbook "$@"

echo ""
echo "✅ Setup Complete!"
