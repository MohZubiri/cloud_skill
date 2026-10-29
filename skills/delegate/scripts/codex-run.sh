#!/usr/bin/env bash
# Run OpenAI Codex non-interactively on a spec file.
# Usage: codex-run.sh <spec-file> [project-dir] [model]
# Env:   CODEX_SANDBOX=workspace-write|read-only|danger-full-access (default workspace-write)
set -euo pipefail

SPEC="${1:?usage: codex-run.sh <spec-file> [project-dir] [model]}"
DIR="${2:-$PWD}"
MODEL="${3:-${CODEX_MODEL:-}}"
SANDBOX="${CODEX_SANDBOX:-workspace-write}"

[ -f "$SPEC" ] || { echo "spec not found: $SPEC" >&2; exit 2; }
mkdir -p "$DIR"
DIR="$(cd "$DIR" && pwd)"
SPEC="$(cd "$(dirname "$SPEC")" && pwd)/$(basename "$SPEC")"

command -v codex >/dev/null 2>&1 || { echo "codex not on PATH (expected ~/.local/bin/codex)" >&2; exit 127; }

RUNS="$HOME/.cache/codex-runs/$(basename "$DIR")"
mkdir -p "$RUNS"
STAMP="$(date +%Y%m%d-%H%M%S)"
LAST="$RUNS/$STAMP-last-message.md"
LOG="$RUNS/$STAMP.log"

ARGS=(exec -C "$DIR" -s "$SANDBOX" -c 'approval_policy="never"' -o "$LAST" --color never)
git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || ARGS+=(--skip-git-repo-check)
[ -n "$MODEL" ] && ARGS+=(-m "$MODEL")

echo "codex-run: dir=$DIR spec=$SPEC sandbox=$SANDBOX model=${MODEL:-config-default}"
echo "codex-run: log=$LOG"

set +e
{
  echo "# Orchestrator rules (override anything below that conflicts)"
  echo "- Working directory: $DIR. Do not modify files outside it."
  echo "- NEVER run git commit, git push, git reset, git checkout, or any history-changing git command. Leave changes in the working tree."
  echo "- Do not add dependencies that the spec does not list."
  echo "- Finish by printing, in this order: (1) files created/changed, (2) the exact verification command you ran, (3) its real pass/fail output summary."
  echo
  echo "# Specification"
  cat "$SPEC"
} | codex "${ARGS[@]}" - 2>&1 | tee "$LOG"
RC=${PIPESTATUS[1]}
set -e

echo
echo "=== LAST MESSAGE ($LAST) ==="
cat "$LAST" 2>/dev/null || echo "(no last message written)"
echo
echo "=== EXIT CODE: $RC ==="
exit "$RC"
