#!/usr/bin/env bash
# Claude Code PreToolUse hook: pauses Claude's first attempt at each commit that
# changes non-data files, so Claude can tighten its prose. Fails open on errors.

input="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0
cmd="$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null)" || exit 0
dir="$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)" || exit 0
[[ -n $cmd && -n $dir ]] || exit 0

# Regexes live in variables because bash 3.2 misparses some literal ones.
git_re='(^|[[:space:];&|(])git([[:space:]]+-[Cc][[:space:]]+[^[:space:]]+)*[[:space:]]+'
commit_re="${git_re}commit([[:space:]]|\$)"
[[ $cmd =~ $commit_re ]] || exit 0

resolve() {
  local p="$1"
  p="${p#[\"\']}"
  p="${p%[\"\']}"
  p="${p/#\~/$HOME}"
  [[ $p == /* ]] || p="$dir/$p"
  printf '%s' "$p"
}
cd_re='^[[:space:]]*cd[[:space:]]+([^[:space:];&|]+)'
[[ $cmd =~ $cd_re ]] && dir="$(resolve "${BASH_REMATCH[1]}")"
dash_c_re='git[[:space:]]+-C[[:space:]]+([^[:space:];&|]+)'
[[ $cmd =~ $dash_c_re ]] && dir="$(resolve "${BASH_REMATCH[1]}")"

git_dir="$(git -C "$dir" rev-parse --absolute-git-dir 2>/dev/null)" || exit 0
head="$(git -C "$dir" rev-parse -q --verify HEAD 2>/dev/null || echo none)"
# Keyed on HEAD, not the diff, because the concision pass changes the diff.
marker="$git_dir/commit-concision-paused"
[[ "$(cat "$marker" 2>/dev/null)" == "$head" ]] && exit 0

# A command that also stages hides its final diff, so assume it changes prose.
stages_too() {
  local add_re="${git_re}add([[:space:]]|\$)"
  local all_re="${git_re}commit([[:space:]]+[^[:space:]]+)*[[:space:]]+(-[[:alnum:]]*a[[:alnum:]]*|--all)([[:space:]]|\$)"
  [[ $cmd =~ $add_re || $cmd =~ $all_re ]]
}

# Any added line outside binary and data files counts; Claude judges what's prose.
changes_text() {
  local added _ path
  while IFS=$'\t' read -r added _ path; do
    case "$added" in - | 0) continue ;; esac
    case "$path" in *.csv | *.tsv | *.jsonl | *.lock | *package-lock.json) continue ;; esac
    return 0
  done < <(git -C "$dir" diff --cached --numstat 2>/dev/null)
  return 1
}

stages_too || changes_text || exit 0
printf '%s\n' "$head" >"$marker" 2>/dev/null || exit 0
cat >&2 <<'EOF'
Commit paused once by the commit-concision hook. Make the prose this commit adds or changes as concise as possible while keeping it clear, following any writing rules in your instructions. Prose includes comments, docstrings, strings people read, and docs. Leave unchanged any wording the user wrote or approved word for word. Then restage any edits and rerun the commit; it will go through, even if you changed nothing.
EOF
exit 2
