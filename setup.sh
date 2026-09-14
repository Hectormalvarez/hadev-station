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
# Set while a mutating playbook run is in flight; holds the mktemp file with
# the ansible output that summarize_run() parses for the post-run summary.
# Cleaned up on success and in report_failure().
RECAP_FILE=""

report_failure() {
    local exit_code=$?
    if [[ -n $RECAP_FILE ]]; then
        rm -f "$RECAP_FILE"
        RECAP_FILE=""
    fi
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
  ./setup.sh --yes                # skip the destructive-run confirmation
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
    -e --extra-vars -i --inventory -c --connection
    -b --become --become-user -u --user --forks
    --yes
    -v -vv -vvv -vvvv
)

# Reject unknown dash-prefixed options (US-004 AC 1). Non-dash arguments are
# forwarded untouched (AC 4): only option names are judged, never values or
# arity. Runs first in Main so garbage arguments fail fast with exit 2 —
# distinct from config (1) and Ansible (4+) failures — regardless of machine
# state, without installing Ansible or touching config.yml.
validate_args() {
    local arg opt name
    for arg in "$@"; do
        case "$arg" in
            "") continue ;;
            -*) ;;
            *) continue ;;
        esac
        # Judge equals-form options by their base name (--tags=dotfiles counts
        # as --tags); values are still never validated, and forwarding stays
        # byte-exact since we only inspect copies of the arguments.
        name="${arg%%=*}"
        for opt in "${KNOWN_OPTIONS[@]}"; do
            [[ $name == "$opt" ]] && continue 2
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

# Derive the run plan from the forwarded arguments: the area the run will
# cover, and whether it will regenerate the playbook-managed dotfiles
# (~/.bashrc_extras and ~/.tmux.conf — see ADR-002). Only full runs and the
# dotfiles/terminal tags touch those files. A dangling --tags value cannot be
# interpreted, so the safe default is the full-run interpretation.
run_plan() {
    local prev="" arg tags=""
    RUN_TOUCHES_DOTFILES=0
    for arg in "${EXTRA_ARGS[@]}"; do
        case "$arg" in
            --tags|-t) prev="tags" ;;
            --tags=*) tags="${tags:+$tags,}${arg#--tags=}"; prev="" ;;
            -t=*) tags="${tags:+$tags,}${arg#-t=}"; prev="" ;;
            *)
                if [[ $prev == "tags" ]]; then
                    tags="${tags:+$tags,}$arg"
                    prev=""
                fi
                ;;
        esac
    done
    if [[ -z $tags || $prev == "tags" ]]; then
        RUN_AREA="the full setup"
        RUN_TOUCHES_DOTFILES=1
    else
        RUN_AREA="tags: $tags"
        case ",$tags," in
            *,dotfiles,*|*,terminal,*) RUN_TOUCHES_DOTFILES=1 ;;
        esac
    fi
}

# Show the plan before every mutating run and require explicit confirmation
# only when the run will regenerate the playbook-managed dotfiles.
# config.yml is never overwritten after the first-run bootstrap (which exits
# before any pre-flight), so it needs no gate here. --yes skips the prompt;
# with no interactive terminal, abort instead of hanging on read or
# proceeding unconfirmed.
pre_flight() {
    echo "Run plan: $RUN_AREA will run."
    if (( RUN_TOUCHES_DOTFILES )); then
        echo "⚠️  ~/.bashrc_extras and ~/.tmux.conf are regenerated from templates;"
        echo "   hand-edits to those two files will be lost."
        if (( PREFLIGHT_YES )); then
            echo "[+] --yes given — skipping confirmation."
        elif [[ -t 0 ]]; then
            local reply
            read -r -p "Proceed? [y/N] " reply
            case "$reply" in
                y|Y|yes|YES|Yes) ;;
                *) echo "Aborted — nothing was changed." ; exit 1 ;;
            esac
        else
            echo "❌ No interactive terminal available to confirm this destructive run."
            echo "   Re-run with --yes to proceed, or add tags that avoid the dotfiles."
            exit 1
        fi
    fi
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
    # Tee the output to a recap file so summarize_run() can report what
    # changed (US-005). The ERR trap is disarmed around the pipeline on
    # purpose: with set -E it would fire inside the pipeline's subshell AND
    # again in the parent, printing the failure message twice. Failure is
    # handled explicitly instead, so the reporter runs exactly once with the
    # pipeline's real exit code.
    RECAP_FILE="$(mktemp)"
    trap - ERR
    if as_root ansible-playbook -i inventory local.yml \
        -e "ansible_user_id=$REAL_USER" \
        -e "ansible_user_dir=$REAL_HOME" \
        "$@" 2>&1 | tee "$RECAP_FILE"; then
        trap report_failure ERR
    else
        report_failure
    fi
}

# Report what the run did (US-005): parse only the final PLAY RECAP line for
# changed=N. changed=0 gets an explicit "nothing changed"; changes get
# counted per area; an unparseable or missing recap degrades to the original
# generic success line — the summary may be vague, never wrong.
summarize_run() {
    local recap="" changed=""
    if [[ -n $RECAP_FILE && -f $RECAP_FILE ]]; then
        recap="$(grep -A1 '^PLAY RECAP' "$RECAP_FILE" | tail -n 1)" || recap=""
        if [[ -n $recap ]]; then
            changed="$(sed -n 's/.*changed=\([0-9]*\).*/\1/p' <<<"$recap")" || changed=""
        fi
    fi
    if [[ -n $RECAP_FILE ]]; then
        rm -f "$RECAP_FILE"
        RECAP_FILE=""
    fi
    echo ""
    if [[ $changed == 0 ]]; then
        echo "✅ Setup complete — nothing changed: $RUN_AREA is already up to date."
    elif [[ -n $changed ]]; then
        echo "✅ Setup complete — $changed change(s) applied to $RUN_AREA."
    else
        echo "✅ Setup Complete!"
    fi
}

# ==============================================================================
# Main
# ==============================================================================
if [[ $# -ge 1 && ( $1 == "-h" || $1 == "--help" ) ]]; then
    usage
    exit 0
fi

# Split out --yes before validation: the script consumes it itself and never
# forwards it to ansible (which has no such option). Everything else is
# validated and forwarded exactly as given.
EXTRA_ARGS=()
PREFLIGHT_YES=0
for arg in "$@"; do
    if [[ $arg == "--yes" ]]; then
        PREFLIGHT_YES=1
    else
        EXTRA_ARGS+=("$arg")
    fi
done

validate_args "${EXTRA_ARGS[@]}"

command -v ansible >/dev/null || install_ansible

echo "=============================================================================="
echo "  Hadev's Workstation Setup"
echo "  Target User: $REAL_USER ($REAL_HOME)"
echo "=============================================================================="

ensure_config

if ! is_parse_only "${EXTRA_ARGS[@]}"; then
    CURRENT_STEP="Pre-flight check"
    run_plan
    pre_flight
fi

run_playbook "${EXTRA_ARGS[@]}"

# Parse-only runs keep the plain success line; mutating runs get the
# post-run summary (RUN_AREA is only set on the mutating path).
if [[ -n ${RUN_AREA:-} ]]; then
    summarize_run
else
    echo ""
    echo "✅ Setup Complete!"
fi
