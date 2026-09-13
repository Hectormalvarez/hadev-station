# Hadev Station — Project Rules

Ansible playbook that bootstraps an Ubuntu development workstation: 6 roles (`core`, `system`, `terminal`, `languages`, `docker`, `virtualization`) under `roles/`, orchestrated by `local.yml` and wrapped by `setup.sh` (handles sudo elevation, user-context injection, Ansible install, first-run config bootstrapping). Single `main` branch.

## ⚠️ Safety — read first

- **Never run `./setup.sh`, `ansible-playbook`, or any tag subset without an explicit user request.** This playbook mutates the live machine: it installs packages with sudo and rewrites dotfiles (`~/.bashrc_extras`, `~/.tmux.conf`). Assume every run is destructive to local config.
- The safe validation path is non-mutating: `./setup.sh --syntax-check`, `ansible-lint`, and the Docker integration test (`tests/Dockerfile` runs the full playbook in a throwaway Ubuntu container — never against the host).
- `config.yml` holds **personal data** (git identity, custom scripts) and is **gitignored by design**. Never commit it, never overwrite or regenerate it, never echo its contents. `config.yml.example` is the committed template — user-facing changes go there.
- `ansible.cfg` disables host key checking — acceptable for this localhost-only repo; never extend that setting to any remote inventory.
- Apt signing-key refreshes live in `local.yml` `pre_tasks` (fixed real NO_PUBKEY failures). When adding a third-party apt repo, add its key refresh there too.

## Canonical Commands

| Purpose | Command |
| :--- | :--- |
| Syntax validation (no mutation) | `./setup.sh --syntax-check` |
| Lint | `ansible-lint` |
| List available tags | `./setup.sh --list-tags` |
| Full containerized integration test | `docker build -t hadev-station-test tests/` (runs playbook as non-root testuser + assertions) |
| Apply to the workstation | `./setup.sh` — **only when explicitly asked** |
| Partial apply | `./setup.sh --tags "dotfiles"` — only when explicitly asked |

## Conventions

- Conventional commits with scopes: `feat(terminal):`, `fix(virtualization):`, `refactor(setup):`, `docs(readme):` (see global Commit Discipline rule).
- Each commit should leave the playbook runnable and lint-clean; CI-parity locally means `ansible-lint` + `--syntax-check` at minimum before committing.