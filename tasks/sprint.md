# Sprint — Tag Hygiene

**Story:** US-001 — Predictable partial updates via cleaned-up playbook tags
**Status:** In progress (implementation complete, awaiting QA)

## Tasks

| # | Task | Status | Notes |
|---|------|--------|-------|
| T1 | Define tag taxonomy | Done | Role tags (6) + `dotfiles`, `python`, `nvm`; see `docs/decisions/ADR-001.md` |
| T2 | Rework `local.yml` role tags | Done | One tag per role; `always` pre-tasks untouched |
| T3 | Rework task-level tags in roles | Done | 14 ad-hoc tags removed; `.bashrc` wiring task gained `dotfiles`; `python` spans system+languages |
| T4 | Update docs (README, `setup.sh --help`) | Done | Tag table matches the new taxonomy |
| T5 | Verification matrix | In progress | `--list-tasks` per documented tag mapped to acceptance criteria |
