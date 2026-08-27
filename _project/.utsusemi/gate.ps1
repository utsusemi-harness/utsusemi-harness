#!/usr/bin/env pwsh
# .utsusemi/gate.ps1 — the repo's pass gate. A PRD task is checked off only
# after this exits 0, and every run integration re-runs it. Keep gate.sh
# behaviorally identical.
$ErrorActionPreference = 'Stop'

# placeholder — replace with the real commands once the stack is chosen, e.g.
# cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test
# exit $LASTEXITCODE
exit 0
