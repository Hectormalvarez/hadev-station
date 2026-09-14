# Sprint — Run Confidence

**Story:** US-003 — Failure & recovery UX for `setup.sh` (see `docs/stories/US-003.md`)
**Status:** Planned

## Tasks

| # | Task | Covers | Depends on | Status |
|---|------|--------|------------|--------|
| T1 | Friendly playbook-failure message: what failed, a concrete next step, and a "safe to re-run" reassurance — raw Ansible output stays visible beneath it | AC 1, 3 | — | Pending |
| T2 | Ansible-install failure message: name the install step and its likely cause (e.g. no network) instead of a silent apt error | AC 2 | — | Pending |
| T3 | Broken-config message: when `config.yml` cannot be used, tell the user that file is the problem and where it lives | AC 5 | — | Pending |
| T4 | Exit discipline: every failure path exits non-zero and never prints the success line | AC 4 | — | Pending |
| T5 | Verification matrix: shellcheck clean, `--syntax-check` passes, containerized integration test green, AC-by-AC walkthrough | all | T1–T4 | Pending |

## Dependency map

T1–T4 are independent of each other; T5 runs last against the finished set.

## Risks

- **R1 (RESOLVED — ADR-002):** Full idempotency audit confirms the playbook is convergent — re-run safety is real. Caveat verified: `~/.bashrc_extras` and `~/.tmux.conf` are regenerated every run, so the "safe to re-run" message must not promise hand-edit preservation.
- **R2:** Messages must not over-claim diagnosis. We are not parsing Ansible output, so wording must stay honest: name *which step* failed, never pretend to know the root cause.
- **R3:** No CI enforcement exists yet (backlog US-006); verification is manual + containerized until that lands.

---

# Sprint — Tag Hygiene (shipped)

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

