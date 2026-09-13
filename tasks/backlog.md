# Backlog

Candidate stories surfaced during US-001's pipeline. None are scheduled.

## US-002 — CI checks: lint + syntax + shellcheck on push/PR

**Source:** QA observation during US-001; earlier session discussion.
**Summary:** Add a GitHub Actions workflow running `ansible-lint`, `./setup.sh --syntax-check`, and `shellcheck setup.sh` on every push and PR to `main`.
**Why:** The playbook is currently lint-clean (production profile) but nothing enforces it — regressions can land silently.
**Notes:** Consider adding a repo-level `.yamllint` config (and a trailing-newline chore for touched YAML files) so yamllint noise doesn't drown the signal.

## US-003 — tmux TPM plugin support

**Source:** README hint — `tmux.conf.j2` was structured for the plugin manager to be enabled later.
**Summary:** Enable TPM in the managed `~/.tmux.conf` and install/populate plugins declaratively.
**Why:** Only candidate that adds new capability rather than hygiene.

## US-004 — Extra fine-grained tags (on demand)

**Source:** US-001 explicit MVP trims (see `docs/stories/US-001.md`).
**Summary:** Add concern-scoped tags (e.g. `fonts`, `hashicorp`, `vagrant`) only when whole-role runs feel too slow; must follow ADR-001 completeness rules.
**Why:** Deferred by design — do not build until a real iteration need appears.

## US-005 — Initialize memory bank

**Source:** Project rules; no `memory-bank/` directory exists yet.
**Summary:** Create the memory bank structure from the codebase, capturing ADR-001, the tag taxonomy, and the feature-pipeline conventions.
**Why:** Session continuity for future work.
