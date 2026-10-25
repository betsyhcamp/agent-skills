#!/usr/bin/env bash
# Link skills from this repo into Claude Code and Codex, or report drift.
set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")" && pwd)/skills"
TARGETS=("$HOME/.claude/skills" "$HOME/.agents/skills")

usage() {
  cat <<EOF
Usage:
  ./link.sh NAME...   link skills/NAME into each tool's skills directory
  ./link.sh --check   report drift between this repo and those directories
EOF
}

link_skill() {
  local name src target dest
  name="$(basename "$1")"
  src="$SKILLS_DIR/$name"
  if [[ ! -f "$src/SKILL.md" ]]; then
    echo "error: $src/SKILL.md not found" >&2
    return 1
  fi
  for target in "${TARGETS[@]}"; do
    dest="$target/$name"
    mkdir -p "$target"
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
      echo "ok: $dest"
    elif [[ -e "$dest" || -L "$dest" ]]; then
      # Without this, ln -s into an existing folder nests the link inside it.
      echo "error: $dest exists and is not a link to $src" >&2
      return 1
    else
      ln -s "$src" "$dest"
      echo "linked: $dest"
    fi
  done
}

# Prints one line per finding in one tool's skills directory; returns 1 on drift.
# An unlinked skill or a folder from elsewhere is info: both are normal at work.
check_target() {
  local target="$1" drift=0 s p name dest
  [[ -d "$target" ]] || return 0
  for s in "$SKILLS_DIR"/*/; do
    # With no skills, the glob stays a literal pattern.
    [[ -d "$s" ]] || continue
    name="$(basename "$s")"
    dest="$target/$name"
    if [[ -L "$dest" && "$(readlink "$dest")" == "$SKILLS_DIR/$name" ]]; then
      continue
    elif [[ -L "$dest" ]]; then
      echo "drift: $dest links to $(readlink "$dest"), not this repo"
      drift=1
    elif [[ -e "$dest" ]]; then
      echo "drift: $dest is a copy, not a link"
      drift=1
    else
      echo "info: $name is not linked into $target"
    fi
  done
  for p in "$target"/*; do
    name="$(basename "$p")"
    if [[ -d "$SKILLS_DIR/$name" ]]; then
      continue
    elif [[ -L "$p" && ! -e "$p" ]]; then
      echo "drift: $p is a broken link"
      drift=1
    elif [[ -d "$p" && ! -L "$p" ]]; then
      case "$name" in
        # synced is written by claude.ai sync; explain-diff-html is someone else's.
        synced | explain-diff-html) ;;
        *) echo "info: $p is a folder outside this repo" ;;
      esac
    fi
  done
  return "$drift"
}

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

if [[ "$1" == "--check" ]]; then
  status=0
  for target in "${TARGETS[@]}"; do
    check_target "$target" || status=1
  done
  exit "$status"
fi

for name in "$@"; do
  link_skill "$name"
done
