# Product Context — Hadev Station

## Why it exists

Rebuild or evolve the workstation without ritual: one command re-creates or
converges the full personal dev environment (shell, languages, containers,
virtualization, git identity, SSH keys).

## Problems it solves

- Machine drift: re-runs converge instead of drifting (ADR-002).
- Partial-update safety: tag runs are complete by construction (ADR-001) —
  no "tool installed but its deps silently skipped".
- Lost personal config: `config.yml` is user-owned and gitignored; first run
  bootstraps it from the template and stops.

## How it should feel (Run Confidence epic)

The user always knows what a run will do and trusts its outcome:

| Moment | Story | State |
|---|---|---|
| Before a run | US-002 pre-flight summary + destructive-run confirmation | Draft |
| On failure | US-003 friendly failure + recovery guidance | **Shipped** |
| On typo'd args | US-004 help instead of an ansible error | Draft |
| After success | US-005 completion summary ("what changed?") | Draft |

## Usage model

- Full apply: `./setup.sh` (mutates live machine — only on explicit request)
- Partial apply: `./setup.sh --tags "dotfiles"`
- Read-only: `--syntax-check`, `--list-tags`, `--list-hosts`, `--help`
- Integration test: `docker build -t hadev-station-test tests/` (throwaway
  container, never the host)
