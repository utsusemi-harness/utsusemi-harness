#!/usr/bin/env bash
# Packaging workaround: https://github.com/utsusemi-harness/utsusemi-harness/issues/1
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/skills/utsusemi-harness/init.sh" "$@"
