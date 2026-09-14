# Sprint — Run Confidence II

**Story:** US-004 — Discoverability: wrong arguments get help, not an ansible error (see `docs/stories/US-004.md`)
**Status:** Planned (human gate pending)

## Tasks

| # | Task | Covers | Depends on | Status |
|---|------|--------|------------|--------|
| T1 | `validate_args()` in `setup.sh`: check every `-`-prefixed argument against a name-level allowlist; on a miss print a one-line "unrecognized option: X" message, then the usage help, and exit 2 — without installing Ansible or touching config | AC 1 | T2 | Pending |
| T2 | Curate the allowlist: script-owned (`-h`, `--help`) + documented pass-through (`--syntax-check`, `--list-tags`, `--list-hosts`, `--tags`/`-t`) + common ansible-playbook options with aliases (`--check`/`-C`, `--diff`/`-D`, `--limit`/`-l`, `--skip-tags`, `--start-at-task`, `--step`, `--vault-id`, `--vault-password-file`, `-v` … `-vvvv`), as one commented array in `setup.sh` | AC 2 | — | Pending |
| T3 | Guarantee forward-compat behavior: option *values* and arity are never validated (`--tags` with no value is forwarded untouched; ansible reports the error), non-dash arguments are forwarded untouched | AC 4 | — | Pending |
| T4 | One-line help correction: line 93 "All arguments are passed through to ansible-playbook untouched" → reflects the validated contract (see R3 — needs human-gate approval as a scope deviation) | AC 2 | T1 | Pending |
| T5 | Verification matrix: `bash -n`, shellcheck, `--help`/`-h` exit 0, `--syntax-check`/`--list-tags` unchanged, `--tagz` rejected with exit 2 + help shown, `--tags` alone forwarded (ansible's error surfaces), container integration test green | all | T1–T4 | Pending |

## Dependency map

T2 first (the allowlist is the contract T1 enforces); T3 and T4 are
independent; T5 runs last against the finished set.

## Risks

- **R1:** The allowlist may false-reject a valid ansible-playbook option the
  owner later needs. Mitigation: broad curated list incl. aliases; the error
  message notes the direct `ansible-playbook` escape hatch; additions are a
  one-line array change.
- **R2:** Validation placement — must run before `install_ansible` and
  `ensure_config` so garbage args fail fast with exit 2 regardless of machine
  state.
- **R3 (needs human-gate decision):** The story marks help content as
  out-of-scope, but leaving "All arguments are passed through untouched" in
  place after this change would make `--help` lie. T4 proposes the minimal
  one-line correction; rejecting T4 keeps the story literally in-scope at the
  cost of inaccurate help.
- **R4:** No CI enforcement (US-006); verification is manual + containerized,
  same as US-003.

---

# Sprint — Run Confidence (shipped)

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

