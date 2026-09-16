#!/usr/bin/env bash
set -euo pipefail

# Link the /research skill into Claude Code config dirs.
#   ./install.sh                      every ~/.claude and ~/.claude-* dir found
#   ./install.sh <config-dir> [...]   only these
# A symlink, not a copy: edits here are live everywhere, and nothing is ever
# written into a config dir except the one link.

LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$#" -gt 0 ]; then
  dirs=("$@")
else
  dirs=()
  for d in "$HOME/.claude" "$HOME"/.claude-*; do
    [ -d "$d" ] && [ ! -L "$d" ] && dirs+=("$d")
  done
fi

[ "${#dirs[@]}" -gt 0 ] || { echo "no Claude config dirs found" >&2; exit 1; }

for d in "${dirs[@]}"; do
  target="$d/skills/research"
  mkdir -p "$d/skills"
  if [ -L "$target" ]; then
    ln -sfn "$LIB/skill" "$target"
    echo "relinked  $target"
  elif [ -e "$target" ]; then
    echo "skipped   $target — exists and isn't a symlink; move it first" >&2
  else
    ln -s "$LIB/skill" "$target"
    echo "linked    $target"
  fi
done
