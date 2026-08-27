#!/usr/bin/env bash
# init.sh — bootstrap a new project from this template.
#
# Usage:
#   ./init.sh <destination-path>
#
# Behavior:
#   1. Copies _project/ to the destination path.
#   2. Makes utsusemi.sh executable.
#   3. Runs `git init -b main`.
#
# The template files leave {{PROJECT_NAME}} placeholders literal. The
# conversational LLM driving setup is expected to replace them as part of
# first-time setup, alongside filling in the substantive spec sections.
# See AGENTS.md in the generated project for the order of attention.
#
# Notes:
#   - Refuses to overwrite an existing non-empty destination.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <destination-path>" >&2
  exit 1
fi

DEST="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/_project"

if [[ ! -d "$SOURCE" ]]; then
  echo "error: $SOURCE not found; run this script from inside the template repo." >&2
  exit 1
fi

if [[ -e "$DEST" ]] && [[ -n "$(ls -A "$DEST" 2>/dev/null || true)" ]]; then
  echo "error: $DEST already exists and is not empty." >&2
  exit 1
fi

mkdir -p "$DEST"
cp -r "$SOURCE"/. "$DEST"/

chmod +x "$DEST/utsusemi.sh"

(
  cd "$DEST"
  git init -b main >/dev/null
)

cat <<EOF
Initialized at $DEST

Next steps:
  cd $DEST
  # 1. Replace {{PROJECT_NAME}} placeholders and fill in PRD.md, README.md,
  #    SPEC/SPEC.md, CONVENTIONS.md together with your conversational LLM.
  # 2. Stage and commit the initial files when ready.
  # 3. Ask your agent to start an implementation run (./utsusemi.sh) when the specs are in shape.
EOF
