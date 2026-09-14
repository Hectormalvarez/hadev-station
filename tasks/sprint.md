# Sprint — Run Confidence

**Story:** US-003 — Failure & recovery UX for `setup.sh` (see `docs/stories/US-003.md`)
**Status:** Shipped (commit 6f37814)

## Tasks

| # | Task | Covers | Depends on | Status |
|---|------|--------|------------|--------|
| T1 | Friendly playbook-failure message: what failed, a concrete next step, and a "safe to re-run" reassurance — raw Ansible output stays visible beneath it | AC 1, 3 | — | Done — `report_failure()` ERR trap; QA sandbox tests 1 & 3 |
| T2 | Ansible-install failure message: name the install step and its likely cause (e.g. no network) instead of a silent apt error | AC 2 | — | Done — `CURRENT_STEP` in `install_ansible`; QA test 2 (stubbed sudo) |
| T3 | Broken-config message: when `config.yml` cannot be used, tell the user that file is the problem and where it lives | AC 5 | — | Done — PyYAML check via `/usr/bin/python3`; QA test 4 |
| T4 | Exit discipline: every failure path exits non-zero and never prints the success line | AC 4 | — | Done — trap re-raises original code (exit 1/4/100 verified) |
| T5 | Verification matrix: shellcheck clean, `--syntax-check` passes, containerized integration test green, AC-by-AC walkthrough | all | T1–T4 | Done — shellcheck 0.10.0 clean; docker build ok=39 failed=0; 6 QA tests |

## Dependency map

T1–T4 are independent of each other; T5 runs last against the finished set.

## Risks

- **R1 (RESOLVED — ADR-002):** Full idempotency audit confirms the playbook is convergent — re-run safety is real. Caveat verified: `~/.bashrc_extras` and `~/.tmux.conf` are regenerated every run, so the "safe to re-run" message must not promise hand-edit preservation.
- **R2 (RESOLVED):** Messages name only the failed *step*; no output parsing, no root-cause claims; config-parse stderr suppressed to avoid echoing personal data.
- **R3 (OPEN):** No CI enforcement exists yet (backlog US-006); verification was manual + containerized for this story. Shellcheck is not installed on the workstation (QA used a static binary in /tmp) — US-006 would close this.

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

