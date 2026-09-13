---
paths:
  - "roles/**"
  - "local.yml"
---
# Ansible Standards

## Role Structure

- One role per concern in `roles/<name>/` with `tasks/main.yml`; role-scoped variables in `defaults/main.yml`; managed dotfiles as Jinja2 templates in `templates/*.j2` (see `bashrc_extras.j2`, `tmux.conf.j2`).
- Keep `main.ts`-style entry minimal: `local.yml` only orders roles and maps tags. Role internals stay inside the role.
- Every role's tasks carry the role's tag(s) (wired in `local.yml` `roles:` entries) so partial runs via `--tags` work. Shared pre-task behavior uses `tags: [always]`.

## Variables & Config

- User-personal values come exclusively from `config.yml` (loaded via `vars_files`) using the `user_*` prefix (`user_git_name`, `user_custom_scripts`, `user_extra_packages`). Never hardcode personal values in roles; anything configurable belongs in `config.yml.example` with a safe placeholder.
- Role defaults in `defaults/main.yml` use the role name as a prefix (e.g. `kvm_packages`) to avoid collisions.
- Access facts via the `ansible_facts` dictionary (`ansible_facts['os_family']`), not dotted `ansible_*` vars — the codebase was deliberately refactored this way to avoid `INJECT_FACTS_AS_VARS` deprecation.

## Task Writing

- **Idempotency is mandatory**: every task must be safe on re-run (the playbook is both installer and updater). Use `state: present`, guarded creates, and `creates:`/`when:` conditions rather than shell where a module exists.
- System-level tasks use `become: true`; anything touching the user's home relies on the injected `ansible_user_id`/`ansible_user_dir` — never assume the invoking user is the target user.
- Shell/command tasks need explicit guards (see the `chown -hR` fix for virtualenv symlinks) and a comment explaining why no module suffices.
- Boolean evaluation must handle unset/null vars explicitly (`| default(false) | bool`) — null-safe defaults are enforced (see the `b5e6507` fix pattern).
- Third-party apt repos: add GPG keys to `/etc/apt/keyrings/` and register the refresh in `local.yml` pre_tasks with `tags: [always]`.

## Style & Lint

- `ansible-lint` runs at `profile: min` — FQCN prefixes are not required (`apt:` not `ansible.builtin.apt:`), names optional, simple YAML formatting allowed. Don't add stricter lint config without asking.
- Before committing: `ansible-lint` and `./setup.sh --syntax-check` must both pass.