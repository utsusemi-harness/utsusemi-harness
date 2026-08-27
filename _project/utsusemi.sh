#!/usr/bin/env bash
# utsusemi.sh — one-shot implementation runner; each run works in its own worktree.
#
# Usage:
#   ./utsusemi.sh [guidance...]
#   ./utsusemi.sh --resume <run-id> [guidance...]
#
# Behavior:
#   - A new run gets a fresh worktree at .utsusemi/worktrees/<run-id> on branch
#     utsusemi/<run-id>, cut from the integration branch (whatever is checked
#     out when the run starts); the agent CLI runs once inside it. The
#     integration branch stays yours while the run is in flight: spec-layer
#     edits and new tasks can land on it at any time.
#   - After the agent exits, the run is integrated deterministically: rebase
#     onto the integration branch, re-run the pass gate (.utsusemi/gate.sh),
#     fast-forward the branch, remove the worktree. On a rebase conflict or a red gate nothing is
#     integrated and the worktree stays for inspection — this script never
#     resolves anything; escalation is the invoker's job.
#   - --resume <run-id> starts a fresh agent context inside an existing run
#     worktree (interrupted or deliberately paused runs).
#   - Concurrent runs are supported: integration is serialized by a lock, and
#     per-task claims (.utsusemi/claims/<task-id>, owner-checked at integration)
#     keep two runs from landing the same task.
#
# Environment:
#   UTSUSEMI_CMD — agent command that reads the prompt on stdin; split on
#               whitespace. Default: claude --dangerously-skip-permissions -p
#   UTSUSEMI_LOCK_TIMEOUT — seconds a finished run waits for the integration
#               lock before giving up (default 900). A waiter never removes
#               the lock itself.
#   .utsusemi/env.sh — optional repo knobs, sourced before the run and the gate
#               (agent/model via UTSUSEMI_CMD, shared build caches, …). Values
#               already set in the invoking environment win over the file.

set -euo pipefail

MAIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$MAIN_DIR"

if [[ ! -f .utsusemi/prompt.md ]]; then
  echo "error: .utsusemi/prompt.md not found in $MAIN_DIR." >&2
  exit 1
fi
if [[ ! -f .utsusemi/gate.sh ]]; then
  echo "error: .utsusemi/gate.sh not found in $MAIN_DIR — integration would have nothing to verify against." >&2
  exit 1
fi

base=$(git symbolic-ref --quiet --short HEAD) || {
  echo "error: detached HEAD; check out the integration branch first." >&2
  exit 1
}

_invoker_utsusemi_cmd="${UTSUSEMI_CMD:-}"
if [[ -f .utsusemi/env.sh ]]; then
  source .utsusemi/env.sh
fi
if [[ -n "$_invoker_utsusemi_cmd" ]]; then
  UTSUSEMI_CMD="$_invoker_utsusemi_cmd"
fi
UTSUSEMI_CMD=${UTSUSEMI_CMD:-"claude --dangerously-skip-permissions -p"}

read -r -a cmd <<< "$UTSUSEMI_CMD"
command -v "${cmd[0]}" >/dev/null 2>&1 || { echo "error: '${cmd[0]}' not found on PATH." >&2; exit 1; }

acquire_integration_lock() {
  local waited=0 timeout="${UTSUSEMI_LOCK_TIMEOUT:-900}" holder
  until mkdir "$lock" 2>/dev/null; do
    if (( waited >= timeout )); then
      holder=$(cat "$lock/pid" 2>/dev/null || echo unknown)
      echo "INTEGRATE LOCKED OUT: $lock held for ${timeout}s (holder pid: $holder); worktree kept at $wt." >&2
      echo "if that integration is dead, remove the lock and rerun: rm -r $lock && $0 --resume $run_id" >&2
      exit 6
    fi
    sleep 2
    waited=$((waited + 2))
  done
  echo "$$" > "$lock/pid"
  trap 'rm -r "$lock" 2>/dev/null || true' EXIT
}

enforce_claims() {
  local id
  while IFS= read -r id; do
    [[ -n "$id" ]] || continue
    if [[ "$(cat ".utsusemi/claims/$id/owner" 2>/dev/null)" != "utsusemi/$run_id" ]]; then
      echo "INTEGRATE REFUSED: $id was checked off without an owned claim; worktree kept at $wt." >&2
      exit 7
    fi
  done < <(git -C "$wt" diff "$base"..HEAD -- TASKS.md | sed -n 's/^+- \[x\] \(T[0-9][0-9]*\):.*/\1/p')
}

release_claims() {
  local c
  for c in .utsusemi/claims/*/; do
    [[ -e "$c" ]] || continue
    if [[ "$(cat "${c}owner" 2>/dev/null)" == "utsusemi/$run_id" ]]; then
      rm -r "$c"
    fi
  done
}

resume=""
if [[ "${1:-}" == "--resume" ]]; then
  if [[ $# -lt 2 ]]; then
    echo "usage: $0 --resume <run-id> [guidance...]" >&2
    exit 1
  fi
  resume="$2"
  shift 2
fi

if [[ -n "$resume" ]]; then
  run_id="$resume"
  wt=".utsusemi/worktrees/$run_id"
  if [[ ! -d "$wt" ]]; then
    echo "error: no run worktree at $wt." >&2
    exit 1
  fi
else
  run_id="$(date +%Y%m%d-%H%M%S)-$$"
  wt=".utsusemi/worktrees/$run_id"
  mkdir -p .utsusemi/worktrees
  git worktree add --quiet "$wt" -b "utsusemi/$run_id" "$base"
  git -C "$wt" branch --quiet --set-upstream-to="$base"
fi

prompt=$(cat "$wt/.utsusemi/prompt.md")
if (( $# > 0 )); then
  prompt+=$'\n\n## Guidance from the invoker\n\n'"$*"
  echo "=== Implementation run $run_id (guided) ==="
else
  echo "=== Implementation run $run_id ==="
fi
echo ""

if ! ( cd "$wt" && printf '%s\n' "$prompt" | "${cmd[@]}" ); then
  echo "RUN FAILED: agent exited non-zero; worktree kept at $wt ($0 --resume $run_id)." >&2
  exit 2
fi

if [[ ! -f "$wt/.utsusemi/gate.sh" ]]; then
  echo "INTEGRATE FAILED: no pass gate at .utsusemi/gate.sh; worktree kept at $wt." >&2
  exit 4
fi

lock=".utsusemi/integrate.lock"
acquire_integration_lock

if ! git -C "$wt" -c core.longpaths=true rebase --quiet "$base"; then
  git -C "$wt" rebase --abort >/dev/null 2>&1 || true
  echo "INTEGRATE CONFLICT: utsusemi/$run_id does not rebase onto $base; worktree kept at $wt for the invoker." >&2
  exit 3
fi

if ! ( cd "$wt" && bash .utsusemi/gate.sh ); then
  echo "INTEGRATE GATE RED: rebased utsusemi/$run_id fails the gate; worktree kept at $wt for the invoker." >&2
  exit 4
fi

enforce_claims

if [[ "$(git symbolic-ref --quiet --short HEAD)" != "$base" ]]; then
  echo "INTEGRATE BLOCKED: the checked-out branch changed since the run started (expected $base); worktree kept at $wt." >&2
  exit 5
fi
before=$(git rev-parse "$base")
if ! git merge --ff-only --quiet "utsusemi/$run_id"; then
  echo "INTEGRATE BLOCKED: fast-forward of $base refused (uncommitted changes in the way?)." >&2
  echo "recover with: git merge --ff-only utsusemi/$run_id && git worktree remove --force $wt && git branch -D utsusemi/$run_id" >&2
  exit 5
fi
git worktree remove --force "$wt"
git branch --quiet -D "utsusemi/$run_id"
release_claims

echo ""
echo "INTEGRATED into $base:"
git log --oneline "$before..$base" | sed 's/^/  /'
