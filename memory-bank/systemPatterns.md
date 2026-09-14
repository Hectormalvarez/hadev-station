# System Patterns — Hadev Station

## Architecture

```
setup.sh (bash wrapper)
  ├─ REAL_USER/REAL_HOME via SUDO_USER + getent (never assume invoker = target user)
  ├─ report_failure() on ERR trap  ── US-003 failure UX (CURRENT_STEP names the step)
  ├─ install_ansible()             ── ppa:ansible/ansible (guarded by command -v)
  ├─ ensure_config()               ── first run: bootstrap config.yml + exit 0;
  │                                   then parse-validate via /usr/bin/python3+PyYAML
  ├─ is_parse_only()               ── --syntax-check/--list-tags/--list-hosts skip sudo
  └─ run_playbook()                ── as_root ansible-playbook local.yml
                                      -e ansible_user_id / ansible_user_dir + "$@"

local.yml
  ├─ vars_files: config.yml
  ├─ pre_tasks (tags: [always]): /etc/apt/keyrings + HashiCorp GPG refresh
  └─ roles: core, system, terminal, languages, docker, virtualization
```

## Tag taxonomy (ADR-001)

- 9 tags total: 6 role tags (`core system terminal languages docker
  virtualization`) + 3 fine-grained cross-cutting (`dotfiles`, `python`, `nvm`).
- Role tags live **only** in `local.yml`; fine-grained tags live **only** on
  individual tasks and may span roles (`python` = languages pyenv tasks +
  system build-deps task).
- Completeness rule: a fine-grained tag must carry every dependency for its
  concern (the old `vagrant` gap is the cautionary tale).
- Never alter `become` flags, `when` conditions, registered vars, or task
  ordering when touching tags. `pre_tasks` keep `tags: [always]`.
- Typo'd/undocumented tag = harmless no-op (US-001 AC 5).

## Convergence guarantee (ADR-002)

- Every state-changing task is re-run safe (idempotent modules or guarded
  shell with `creates:`/`changed_when: false`/`when:`).
- Caveats: `~/.bashrc_extras` and `~/.tmux.conf` are regenerated from
  templates every run — hand-edits are NOT preserved (message wording in
  `report_failure()` must keep this hedge); HashiCorp GPG fetch always
  reports `changed` (why a converged run is never fully green).
- New shell guards need a comment explaining why no module suffices.

## setup.sh conventions (US-003)

- `set -Eeuo pipefail` (the `-E` is load-bearing: without errtrace the ERR
  trap is invisible inside functions).
- `CURRENT_STEP` set before each phase; `report_failure()` names the step,
  preserves the original exit code, adds orientation only — never root-cause
  claims, raw output stays visible above the message.
- Config validation: `/usr/bin/python3` explicitly (PATH python3 may be a
  pyenv build without PyYAML); stderr discarded so config contents are never
  echoed; skip gracefully if system python is absent.

## Feature pipeline convention

Story (`docs/stories/US-0XX.md`, format = US-001's) → SDM task breakdown +
backlog (`tasks/`) → Architect constraints/ADR (`docs/decisions/`) → **human
gate** → Developer → QA (sandbox tests, zero host mutation) → Code Review →
SDM close-out (story → Approved, sprint → Shipped). Conventional commits with
scopes: `feat(terminal):`, `docs(stories):`, `fix(virtualization):`,
`chore(tasks):`.

## Ansible style (enforced by .ansible-lint)

`profile: min`; FQCN not required (`apt:`); task names optional; simple YAML
allowed. `ansible_facts['os_family']` dict access — never dotted `ansible_*`
vars (INJECT_FACTS_AS_VARS deprecation). Null-safe booleans:
`| default(false) | bool`. Third-party apt repos: GPG keys in
`/etc/apt/keyrings/` + refresh registered in `local.yml` pre_tasks.
