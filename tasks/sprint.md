# Sprint — Run Confidence III

**Stories:** US-002 — Pre-flight summary & destructive-run confirmation · US-005 — Post-run change summary (see `docs/stories/`)
**Status:** Shipped (commits 61f7489, 41e731e)

## Tasks

| # | Story | Task | Covers | Depends on | Status |
|---|-------|------|--------|------------|--------|
| T1 | US-002 | Arg pre-parse in Main: strip `--yes` into `PREFLIGHT_YES` (script-consumed, never forwarded — ansible has no such option), forward the rest; add `--yes` to `KNOWN_OPTIONS` | AC 4 | — | Done — QA: `--yes` absent from forwarded invocation; `--tagz` still exit 2 |
| T2 | US-002 | `run_plan()`: derive the run area and a dotfiles-touch flag from the forwarded tags; a missing/dangling `--tags` value defaults to the safe full-run interpretation | AC 1, edge | — | Done — QA: area strings correct; dangling `--tags` aborts safely (non-TTY) |
| T3 | US-002 | `pre_flight()`: print the run plan before every mutating run; `y/N` gate **only** when the run regenerates the playbook-managed dotfiles; `--yes` bypasses; no TTY → abort with `--yes` hint | AC 2, 3, 6 | T2 | Done — QA: real-pty prompt (n → abort, y → proceed); languages runs unprompted; non-TTY aborts |
| T4 | US-002 | Parse-only short-circuit: `--syntax-check`/`--list-tags`/`--list-hosts` get no summary and no prompt | AC 5 | T3 | Done — QA: no summary on parse-only; host runs exit 0 |
| T5 | US-005 | `run_playbook()` mutating branch tees ansible output to a mktemp recap file; ERR trap disarmed around the pipeline and failure handled explicitly, so the failure message is never printed twice | AC 1 | — | Done — QA: failure message count = 1, exit 4 preserved, raw error visible |
| T6 | US-005 | `summarize_run()`: parse `changed=N` from PLAY RECAP; `changed=0` → explicit "nothing changed", `changed>0` → "N change(s) applied to <area>", unparseable → generic success (never a wrong claim); recap file cleaned on success and in `report_failure` | AC 1, 2, 4 | T5 | Done — QA: full ("5 change(s) applied to the full setup"), partial ("tags: dotfiles"), zero-change, and degrade cases all pass |
| T7 | — | Verification matrix: shellcheck, sandbox stubs (accept/decline/`--yes`/non-TTY/parse-only/tag-combos/recap variants), host parse-only runs, docker integration test | all | T1–T6 | Done — shellcheck clean; docker build EXIT=0 |

## Dependency map

T1–T4 (US-002) are sequential-ish; US-005's T5–T6 reuse US-002's `RUN_AREA`
for the summary wording, so US-002 lands first. T7 runs last against both.

## Risks

- **R1 (RESOLVED):** Prompting under sudo — `read` uses the inherited stdin
  (still the TTY in the normal `sudo ./setup.sh` flow); non-TTY is detected
  and aborts rather than hanging. Verified with a real pty via `script(1)`.
- **R2 (RESOLVED):** PLAY RECAP parse fragility — graceful degradation
  verified: an unparseable recap yields the generic success line, never a
  false "nothing changed".
- **R3 (RESOLVED):** Recapping via a `| tee` pipeline would re-enter the ERR
  trap in the pipeline subshell and print the failure message twice — trap
  disarmed around the pipeline, failure handled explicitly; QA counted
  exactly one failure message with the real exit code.
- **R4 (RESOLVED for this sprint):** No CI (US-006) — verification was manual
  + containerized; US-006 remains the structural fix.
- **Advisory (review):** `run_plan` computes the area from `--tags` only —
  `--skip-tags terminal` on a full run still prompts (conservative
  over-prompt, never under-prompt). Future refinement.

---

# Sprint — Run Confidence II (shipped)

# Sprint — Run Confidence II

**Story:** US-004 — Discoverability: wrong arguments get help, not an ansible error (see `docs/stories/US-004.md`)
**Status:** Shipped (commits 5b75357, 34ac591)

## Tasks

| # | Task | Covers | Depends on | Status |
|---|------|--------|------------|--------|
| T1 | `validate_args()` in `setup.sh`: check every `-`-prefixed argument against a name-level allowlist; on a miss print a one-line "unrecognized option: X" message, then the usage help, and exit 2 — without installing Ansible or touching config | AC 1 | T2 | Done — QA test 1: exit 2, fail-fast proven (no config created, sudo log empty) |
| T2 | Curate the allowlist: script-owned (`-h`, `--help`) + documented pass-through (`--syntax-check`, `--list-tags`, `--list-hosts`, `--tags`/`-t`) + common ansible-playbook options with aliases (`--check`/`-C`, `--diff`/`-D`, `--limit`/`-l`, `--skip-tags`, `--start-at-task`, `--step`, `--vault-id`, `--vault-password-file`, `-v` … `-vvvv`), as one commented array in `setup.sh` | AC 2 | — | Done — extended in 34ac591 with `-e --extra-vars -i --inventory -c --connection -b --become --become-user -u --user --forks` (review W1) |
| T3 | Guarantee forward-compat behavior: option *values* and arity are never validated (`--tags` with no value is forwarded untouched; ansible reports the error), non-dash arguments are forwarded untouched | AC 4 | — | Done — QA byte-exact forwarding verified; `--tags` alone reaches ansible untouched |
| T4 | One-line help correction: line 93 "All arguments are passed through to ansible-playbook untouched" → reflects the validated contract (see R3 — needs human-gate approval as a scope deviation) | AC 2 | T1 | Done — approved at human gate; corrected in 5b75357 |
| T5 | Verification matrix: `bash -n`, shellcheck, `--help`/`-h` exit 0, `--syntax-check`/`--list-tags` unchanged, `--tagz` rejected with exit 2 + help shown, `--tags` alone forwarded (ansible's error surfaces), container integration test green | all | T1–T4 | Done — shellcheck clean; docker build EXIT=0 (ok=39 failed=0); 6 QA tests + post-review fix tests |

## Dependency map

T2 first (the allowlist is the contract T1 enforces); T3 and T4 are
independent; T5 runs last against the finished set.

## Risks

- **R1 (RESOLVED — 34ac591):** The allowlist may false-reject a valid
  ansible-playbook option the owner later needs. Fixed: `-e --extra-vars`,
  `-i --inventory`, `-c --connection`, `-b --become`, `--become-user`,
  `-u --user`, `--forks` added after code review; equals-form options
  (`--tags=x`) now judge by base name; escape-hatch message retained for
  anything else.
- **R2:** Validation placement — must run before `install_ansible` and
  `ensure_config` so garbage args fail fast with exit 2 regardless of machine
  state.
- **R3 (RESOLVED):** The story marked help content as out-of-scope, but
  leaving "All arguments are passed through untouched" in place would make
  `--help` lie. Human gate approved the single-sentence correction at
  development time; nothing else in the help text changed.
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

