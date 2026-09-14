# Tech Context — Hadev Station

## Stack

- Target: Ubuntu workstation (localhost only), bash wrapper script.
- Ansible from `ppa:ansible/ansible` (installed by `setup.sh` if missing).
- Lint: `ansible-lint` (`.ansible-lint`: profile min; fqcn-builtins, yaml,
  name skipped) + `yamllint` (installed by the system role itself).
- Integration test: `tests/Dockerfile` — runs the full playbook as non-root
  `testuser` in a throwaway Ubuntu container with assertions. Baseline at
  US-003: `ok=39 failed=0`.

## Canonical commands

| Purpose | Command |
|---|---|
| Syntax validation (non-mutating) | `./setup.sh --syntax-check` |
| Lint | `ansible-lint` |
| List tags | `./setup.sh --list-tags` |
| Integration test | `docker build -t hadev-station-test tests/` |
| Apply (DESTRUCTIVE — explicit request only) | `./setup.sh` |
| Partial apply (DESTRUCTIVE — explicit request only) | `./setup.sh --tags "dotfiles"` |

## Environment gotchas

- PATH `python3` may be a pyenv build **without PyYAML** — use
  `/usr/bin/python3` for YAML parsing (Ansible ships python3-yaml).
- `shellcheck` is not installed on the workstation (QA used a static v0.10.0
  binary in /tmp); CI enforcement is backlog US-006.
- No CI exists at all (no `.github/workflows/`).
- `ansible.cfg` disables host key checking — acceptable localhost-only; never
  extend to remote inventories.

## Repo layout

```
setup.sh  local.yml  ansible.cfg  .ansible-lint  inventory
config.yml.example        # committed template (config.yml itself is gitignored)
roles/{core,system,terminal,languages,docker,virtualization}/
templates/{bashrc_extras,tmux.conf}.j2
tests/Dockerfile, tests/.dockerignore
docs/stories/US-001..005   docs/decisions/ADR-001, ADR-002
tasks/{sprint,backlog}.md  memory-bank/
```
