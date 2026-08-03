# .ralph/env.sh — repo-level knobs for ralph.sh, sourced before the run and
# before the integration gate. Values already set in the invoking environment
# win over this file. Keep env.ps1 behaviorally identical.

# Default agent command — the model choice lives here:
# RALPH_CMD="claude --model sonnet --dangerously-skip-permissions -p"

# Shared caches so per-run worktrees don't rebuild from scratch, e.g. for Rust:
# export CARGO_TARGET_DIR="$(git rev-parse --show-toplevel)/target"
