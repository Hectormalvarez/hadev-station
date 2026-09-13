# Sprint — Tag Hygiene

**Story:** US-001 — Predictable partial updates via cleaned-up playbook tags
**Status:** Shipped (commit 1ef7780)

## Tasks

| # | Task | Status | Notes |
|---|------|--------|-------|
| T1 | Define tag taxonomy | Done | Role tags (6) + `dotfiles`, `python`, `nvm`; see `docs/decisions/ADR-001.md` |
| T2 | Rework `local.yml` role tags | Done | One tag per role; `always` pre-tasks untouched |
| T3 | Rework task-level tags in roles | Done | 14 ad-hoc tags removed; `.bashrc` wiring task gained `dotfiles`; `python` spans system+languages |
| T4 | Update docs (README, `setup.sh --help`) | Done | Tag table matches the new taxonomy |
| T5 | Verification matrix | Done | `--list-tasks` per tag verified against ACs; ansible-lint 0 failures, 0 warnings (production profile) |
