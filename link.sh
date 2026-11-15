#!/usr/bin/env bash
# Link skills, hooks and global instructions from this repo into Claude Code
# and Codex, or report drift.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$REPO/skills"
TARGETS=("$HOME/.claude/skills" "$HOME/.agents/skills")
HOOKS_DIR="$REPO/hooks"
HOOK_TARGET="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"
INSTRUCTIONS="$REPO/global/AGENTS.md"
INSTRUCTION_LINKS=("$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md")

usage() {
  cat <<EOF
Usage:
  ./link.sh NAME...   link each named skill, hook, or "instructions"
  ./link.sh --all     link every skill and hook, and the instructions
  ./link.sh --check   report drift between this repo and where it's linked
EOF
}

is_link_to() {
  [[ -L "$1" && "$(readlink "$1")" == "$2" ]]
}

confirm() {
  local answer
  read -r -p "$1 [y/N] " answer || return 1
  [[ $answer == [yY] || $answer == [yY][eE][sS] ]]
}

backup_name() {
  printf '%s.bak-%s' "$1" "$(date +%Y%m%d-%H%M%S)"
}

link_skill() {
  local name="$1" src target dest
  src="$SKILLS_DIR/$name"
  for target in "${TARGETS[@]}"; do
    dest="$target/$name"
    mkdir -p "$target"
    if is_link_to "$dest" "$src"; then
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

# Links dest to src. Shows anything already at dest, and backs it up on a yes.
link_file() {
  local src="$1" dest="$2" bak
  mkdir -p "$(dirname "$dest")"
  if is_link_to "$dest" "$src"; then
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

install_instructions() {
  local dest
  for dest in "${INSTRUCTION_LINKS[@]}"; do
    link_file "$INSTRUCTIONS" "$dest"
  done
}

# True if the settings JSON on stdin already runs every command in hooks/NAME.json.
has_entries() {
  # shellcheck disable=SC2016 # $frag is a jq variable.
  jq -e --slurpfile frag "$HOOKS_DIR/$1.json" \
    '([$frag[0][][].hooks[].command] - [.hooks[]?[]?.hooks[]?.command]) == []' \
    >/dev/null 2>&1
}

# Merges hooks/NAME.json into settings.json's hooks. Shows the change, and backs
# up the file on a yes.
add_entries() {
  local name="$1" current new bak tmp
  if [[ -s "$SETTINGS" ]]; then
    current="$(jq . "$SETTINGS")" || {
      echo "error: $SETTINGS is not valid JSON" >&2
      return 1
    }
  else
    current='{}'
  fi
  if has_entries "$name" <<<"$current"; then
    echo "ok: $SETTINGS runs $name"
    return 0
  fi
  # shellcheck disable=SC2016 # $frag and $x are jq variables.
  new="$(jq --slurpfile frag "$HOOKS_DIR/$name.json" \
    'reduce ($frag[0] | to_entries[]) as $x (.; .hooks[$x.key] += $x.value)' \
    <<<"$current")"
  echo "$SETTINGS would gain $name (- now, + after):"
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

install_hook() {
  local name="$1" src="$HOOKS_DIR/$1.sh" dest="$HOOK_TARGET/$1.sh"
  if ! command -v jq >/dev/null; then
    echo "error: hooks need jq to edit $SETTINGS" >&2
    return 1
  fi
  if [[ ! -f "$HOOKS_DIR/$name.json" ]]; then
    echo "error: $HOOKS_DIR/$name.json not found" >&2
    return 1
  fi
  link_file "$src" "$dest"
  # Otherwise settings.json would run whatever else is at dest.
  if is_link_to "$dest" "$src"; then
    add_entries "$name"
  else
    echo "skipped: $SETTINGS entry for $name, since $dest isn't linked"
  fi
}

install_name() {
  local name skill hook
  name="$(basename "$1")"
  name="${name%.sh}"
  skill="$SKILLS_DIR/$name/SKILL.md"
  hook="$HOOKS_DIR/$name.sh"
  if [[ -f $skill && (-f $hook || $name == instructions) ]]; then
    echo "error: $name names a skill and something else; rename one" >&2
    return 1
  elif [[ $name == instructions ]]; then
    install_instructions
  elif [[ -f $hook ]]; then
    install_hook "$name"
  elif [[ -f $skill ]]; then
    link_skill "$name"
  else
    echo "error: $name is not a skill, a hook or \"instructions\"" >&2
    return 1
  fi
}

# Skills go first: they never ask, so a conflict stops the run before any question.
install_all() {
  local s h
  for s in "$SKILLS_DIR"/*/SKILL.md; do
    [[ -f "$s" ]] || continue
    link_skill "$(basename "$(dirname "$s")")"
  done
  for h in "$HOOKS_DIR"/*.sh; do
    [[ -f "$h" ]] || continue
    install_hook "$(basename "$h" .sh)"
  done
  install_instructions
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
    if is_link_to "$dest" "$SKILLS_DIR/$name"; then
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

# A machine's own CLAUDE.md or AGENTS.md is info: that's normal at work.
check_instructions() {
  local drift=0 dest
  for dest in "${INSTRUCTION_LINKS[@]}"; do
    if is_link_to "$dest" "$INSTRUCTIONS"; then
      continue
    elif [[ -L "$dest" ]]; then
      echo "drift: $dest links to $(readlink "$dest"), not this repo"
      drift=1
    else
      echo "info: $dest is not linked to this repo"
    fi
  done
  return "$drift"
}

# A hook is drift when only one of its link and its settings entry is in place.
check_hooks() {
  local drift=0 h name dest has linked
  if ! command -v jq >/dev/null; then
    echo "info: jq not found, so hooks weren't checked"
    return 0
  fi
  for h in "$HOOKS_DIR"/*.sh; do
    [[ -f "$h" ]] || continue
    name="$(basename "$h" .sh)"
    dest="$HOOK_TARGET/$name.sh"
    has=0
    linked=0
    [[ -f "$SETTINGS" ]] && has_entries "$name" <"$SETTINGS" && has=1
    is_link_to "$dest" "$h" && linked=1
    if ((has == 1 && linked == 0)); then
      echo "drift: $SETTINGS runs $dest, which isn't linked to this repo"
      drift=1
    elif ((has == 0 && linked == 1)); then
      echo "drift: $dest is linked, but $SETTINGS doesn't run it"
      drift=1
    elif ((has == 0)); then
      echo "info: hook $name is not installed"
    fi
  done
  return "$drift"
}

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

case "$1" in
  --check)
    status=0
    for target in "${TARGETS[@]}"; do
      check_target "$target" || status=1
    done
    check_hooks || status=1
    check_instructions || status=1
    exit "$status"
    ;;
  --all)
    install_all
    exit 0
    ;;
esac

for name in "$@"; do
  install_name "$name"
done
