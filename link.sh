#!/usr/bin/env bash
# Link skills, global instructions and the commit hook from this repo into
# Claude Code and Codex, or report drift.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$REPO/skills"
TARGETS=("$HOME/.claude/skills" "$HOME/.agents/skills")
GLOBAL_FILE="$REPO/global/AGENTS.md"
GLOBAL_LINKS=("$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md")
HOOK_FILE="$REPO/hooks/commit-concision.sh"
HOOK_LINK="$HOME/.claude/hooks/commit-concision.sh"
SETTINGS="$HOME/.claude/settings.json"
# A fixed path, so moving the clone needs a relink but no settings change.
# shellcheck disable=SC2088 # The shell that runs the hook expands the ~.
HOOK_CMD='~/.claude/hooks/commit-concision.sh'
# shellcheck disable=SC2016 # $cmd is a jq variable.
HAS_HOOK='any(.hooks.PreToolUse[]?.hooks[]?; .command == $cmd)'

usage() {
  cat <<EOF
Usage:
  ./link.sh NAME...   link skills/NAME into each tool's skills directory
  ./link.sh --global  link global/AGENTS.md and the commit hook into place
  ./link.sh --check   report drift between this repo and those places
EOF
}

confirm() {
  local answer
  read -r -p "$1 [y/N] " answer || return 1
  [[ $answer == [yY] || $answer == [yY][eE][sS] ]]
}

backup_name() {
  printf '%s.bak-%s' "$1" "$(date +%Y%m%d-%H%M%S)"
}

# Links dest to src. Shows anything already at dest, and backs it up on a yes.
link_global() {
  local src="$1" dest="$2" bak
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "ok: $dest"
    return 0
  elif [[ -L "$dest" ]]; then
    echo "$dest links to $(readlink "$dest"); it would link to $src instead."
  elif [[ -e "$dest" ]]; then
    echo "$dest would become a link to $src. Content changes (- now, + after):"
    if cmp -s "$dest" "$src"; then
      echo "  none"
    else
      diff -u "$dest" "$src" | tail -n +3 || true
    fi
  else
    ln -s "$src" "$dest"
    echo "linked: $dest"
    return 0
  fi
  if ! confirm "Replace it?"; then
    echo "skipped: $dest"
    return 0
  fi
  bak="$(backup_name "$dest")"
  mv "$dest" "$bak"
  ln -s "$src" "$dest"
  echo "backup: $bak"
  echo "linked: $dest"
}

# Adds the hook to settings.json. Shows the change, and backs up the file on a yes.
install_hook_entry() {
  local current new bak tmp
  if [[ -s "$SETTINGS" ]]; then
    current="$(jq . "$SETTINGS")" || {
      echo "error: $SETTINGS is not valid JSON" >&2
      return 1
    }
  else
    current='{}'
  fi
  if jq -e --arg cmd "$HOOK_CMD" "$HAS_HOOK" <<<"$current" >/dev/null; then
    echo "ok: $SETTINGS runs the commit hook"
    return 0
  fi
  new="$(jq --arg cmd "$HOOK_CMD" \
    '.hooks.PreToolUse += [{matcher: "Bash", hooks: [{type: "command", command: $cmd}]}]' \
    <<<"$current")"
  echo "$SETTINGS would gain the commit hook (- now, + after):"
  diff -u <(printf '%s\n' "$current") <(printf '%s\n' "$new") | tail -n +3 || true
  if ! confirm "Write it?"; then
    echo "skipped: $SETTINGS"
    return 0
  fi
  mkdir -p "$(dirname "$SETTINGS")"
  if [[ -e "$SETTINGS" ]]; then
    bak="$(backup_name "$SETTINGS")"
    cp -p "$SETTINGS" "$bak"
    echo "backup: $bak"
  fi
  # Renamed into place, so a failed write can't leave the file half-written.
  tmp="$SETTINGS.tmp-$$"
  printf '%s\n' "$new" >"$tmp"
  mv "$tmp" "$SETTINGS"
  echo "updated: $SETTINGS"
}

install_global() {
  local dest
  if ! command -v jq >/dev/null; then
    echo "error: --global needs jq to edit $SETTINGS" >&2
    return 1
  fi
  for dest in "${GLOBAL_LINKS[@]}"; do
    link_global "$GLOBAL_FILE" "$dest"
  done
  link_global "$HOOK_FILE" "$HOOK_LINK"
  install_hook_entry
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

# Prints one line per finding for the global files and the hook; returns 1 on drift.
# A machine's own CLAUDE.md or AGENTS.md is info: that's normal at work.
check_global() {
  local drift=0 dest has=0 linked=0
  for dest in "${GLOBAL_LINKS[@]}"; do
    if [[ -L "$dest" && "$(readlink "$dest")" == "$GLOBAL_FILE" ]]; then
      continue
    elif [[ -L "$dest" ]]; then
      echo "drift: $dest links to $(readlink "$dest"), not this repo"
      drift=1
    else
      echo "info: $dest is not linked to this repo"
    fi
  done
  if ! command -v jq >/dev/null; then
    echo "info: jq not found, so the commit hook wasn't checked"
    return "$drift"
  fi
  jq -e --arg cmd "$HOOK_CMD" "$HAS_HOOK" "$SETTINGS" >/dev/null 2>&1 && has=1
  [[ -L "$HOOK_LINK" && "$(readlink "$HOOK_LINK")" == "$HOOK_FILE" ]] && linked=1
  if ((has == 1 && linked == 0)); then
    echo "drift: $SETTINGS runs $HOOK_LINK, which isn't linked to this repo"
    drift=1
  elif ((has == 0 && linked == 1)); then
    echo "drift: $HOOK_LINK is linked, but $SETTINGS doesn't run it"
    drift=1
  elif ((has == 0)); then
    echo "info: the commit hook is not installed"
  fi
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
  check_global || status=1
  exit "$status"
fi

if [[ "$1" == "--global" ]]; then
  install_global
  exit 0
fi

for name in "$@"; do
  link_skill "$name"
done
