# agent-tools

Personal tools for [Claude Code](https://code.claude.com/docs/en/skills) and [Codex](https://learn.chatgpt.com/docs/build-skills):

- `skills/`: one folder per skill; its `SKILL.md` says what it does and when it runs.
- `global/AGENTS.md`: global instructions, used as both `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`.
- `hooks/commit-concision.sh`: a Claude Code hook that pauses Claude's first attempt at each commit that changes non-data files, so Claude can tighten the commit's prose. It covers only Claude Code's commits, not Codex's or yours.

## Install

```sh
git clone https://github.com/betsyhcamp/agent-tools.git
cd agent-tools
./link.sh NAME...    # symlink skills/NAME into ~/.claude/skills and ~/.agents/skills
./link.sh --global   # link global/AGENTS.md and the hook, and add the hook to ~/.claude/settings.json
./link.sh --check    # confirm each tool reads from this clone
```

Everything is linked, not copied, so `git pull` updates it. Before `--global` replaces a file or edits `settings.json`, it shows the change, asks, and keeps a `.bak-` copy beside the original.

Links store this clone's absolute path. After moving the clone, remove the old skill links (`rm ~/.claude/skills/NAME ~/.agents/skills/NAME`), rerun `./link.sh NAME`, then rerun `./link.sh --global`.

Requires bash (3.2 or later). `--global` and the hook need `jq`; without it, the hook checks nothing. MIT licensed.
