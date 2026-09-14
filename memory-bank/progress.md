# Progress — Hadev Station

## What works

- Full playbook: 6 roles, idempotent installer/updater, containerized
  integration test green (`ok=39 failed=0` at US-003).
- Tag system (US-001, shipped): 9 predictable tags, complete by construction,
  `--list-tags` discoverable, typo'd tags are harmless no-ops.
- Failure UX (US-003, shipped): step-naming failure messages with re-run
  reassurance + dotfiles caveat, preserved exit codes, broken-config
  detection before any run. QA PASS, review APPROVED.
- Argument validation (US-004, shipped): unknown dash-prefixed options
  rejected with usage help + exit 2 before anything runs; documented options
  and values/arity forwarded untouched; equals-form supported.
- First-run bootstrap: creates `config.yml` from template, instructs, exits 0.
- Parse-only runs skip sudo elevation.

## Story ledger

| Story | Status |
|---|---|
| US-001 tag cleanup | Approved/shipped |
| US-002 pre-flight confirmation | Draft |
| US-003 failure & recovery UX | Approved/shipped |
| US-004 argument discoverability | Approved/shipped |
| US-005 post-run feedback | Draft |
| US-006 CI checks (backlog) | Candidate |
| US-007 tmux TPM (backlog) | Candidate |
| US-008 extra tags (backlog, on demand) | Deferred by design |
| US-009 memory bank | Done |

## What's left / known issues

- No CI (US-006 candidate) — lint/syntax/shellcheck unenforced.
- US-002/US-004/US-005 drafted but not implemented.
- Advisory only: possible double failure message on failing command
  substitutions (US-003 review note).

## Known-good baseline

`main` at US-004 close-out (last code commit `34ac591`); working tree clean;
`bash -n`, shellcheck 0.10.0, `--syntax-check`, `ansible-lint` all clean;
docker integration test EXIT=0.
