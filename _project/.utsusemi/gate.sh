#!/usr/bin/env bash
# .utsusemi/gate.sh — the repo's pass gate. A PRD task is checked off only
# after this exits 0, and every run integration re-runs it. Keep gate.ps1
# behaviorally identical.
set -euo pipefail

# placeholder — replace with the real commands once the stack is chosen, e.g.
# cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test
