# Project Brief — Hadev Station

## What this is

An Ansible playbook that bootstraps Hadev's personal Ubuntu development
workstation. A bash wrapper (`setup.sh`) handles sudo elevation, user-context
injection, Ansible installation, and first-run config bootstrapping; the
playbook (`local.yml`) orchestrates 6 roles under `roles/`.

## Goals

1. **One-command reproducibility** — `./setup.sh` takes a machine from stock
   Ubuntu to a fully configured dev environment.
2. **Idempotent installer AND updater** — every run must be safe; the playbook
   converges (guarantee formalized in `docs/decisions/ADR-002.md`).
3. **Predictable partial updates** — any tag run updates exactly the intended
   concern, completely (`docs/decisions/ADR-001.md`).
4. **Personal data separation** — `config.yml` (git identity, custom scripts,
   extra packages) is gitignored by design; `config.yml.example` is the
   committed template.
5. **Run Confidence** — the user always knows a run's blast radius: before
   (US-002), on failure (US-003, shipped), after (US-005).

## Hard constraints

- `config.yml` holds personal data: never commit, regenerate, or echo it.
  All user-facing config additions go to `config.yml.example`.
- Never run `./setup.sh` or any playbook apply without explicit user request —
  it mutates the live machine with sudo and rewrites dotfiles.
- The safe validation path is non-mutating: `./setup.sh --syntax-check`,
  `ansible-lint`, and the Docker integration test (`tests/Dockerfile`).
- Localhost-only repo: `ansible.cfg` disables host key checking — never extend
  that to any remote inventory.

## Out of scope

Multi-user or remote-host inventory; anything beyond this one workstation.
