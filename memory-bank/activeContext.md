# Active Context — Hadev Station

## Current focus

Nothing in flight — US-004 just shipped. Next pick is the owner's.

## Just shipped

- **US-004 argument discoverability** (commits `5b75357`, `34ac591`):
  `validate_args()` name-level allowlist in `setup.sh`, unknown dash-prefixed
  options rejected with usage help + exit 2 before anything runs; values and
  arity never validated; equals-form judged by base name; `-e/-i/-c/-b`
  family added after code review. QA PASS, review APPROVED, help contract
  line corrected.
- US-009 memory bank initialized (`5c6cd95`).
- US-003 failure & recovery UX (`6f37814`, close-out `e7644af`); ADR-002
  Accepted.

## Next up (priority order)

1. **US-005 post-run feedback** — completion summary ("what ran, what
   changed?"); final piece of the Run Confidence before/after arc
2. **US-006 CI checks** (lint + syntax + shellcheck on push/PR) — nothing yet
   enforces ADR-002's convergence guarantee or the setup.sh logic

## Open items

- **R3 (US-003 sprint):** no CI enforcement; verification is manual +
  containerized until US-006 lands.
- Code-review advisory (US-003): failing command substitutions can print the
  failure message twice; only on already-failing paths — fix only if it
  annoys in practice.

## Sprint (Run Confidence)

- Shipped: US-003, US-004. Drafted, unscheduled: US-002, US-005.
- Backlog: US-006 CI checks, US-007 tmux TPM, US-008 extra tags (on demand).
  US-009 done.

