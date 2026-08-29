# .utsusemi/env.ps1 — repo-level knobs for utsusemi.ps1, dot-sourced before the run
# and before the integration gate. Values already set in the invoking
# environment win over this file. Keep env.sh behaviorally identical.

# Default agent command — the model choice lives here:
# $env:UTSUSEMI_CMD = 'claude --model sonnet --dangerously-skip-permissions -p'

# Shared caches so per-run worktrees don't rebuild from scratch, e.g. for Rust:
# $env:CARGO_TARGET_DIR = Join-Path (git rev-parse --show-toplevel) 'target'
