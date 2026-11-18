# agent-tools

[![License](https://img.shields.io/github/license/betsyhcamp/agent-tools)](LICENSE)

Personal skills, instructions and a hook for coding agents. 

Skills use the open [Agent Skills](https://agentskills.io/) format, so [Claude Code](https://code.claude.com/docs/en/skills), [Codex](https://learn.chatgpt.com/docs/build-skills) and [GitHub Copilot](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills) all load them. The instructions reach Claude Code and Codex, and the hook only Claude Code.


- **`skills/NAME/`:** one skill each; its `SKILL.md` says what it does and when it runs. Linked into `~/.claude/skills` and `~/.agents/skills`.
- **`hooks/NAME.sh`:** a Claude Code hook, linked into `~/.claude/hooks`. `hooks/NAME.json` holds the entry `link.sh` adds to `~/.claude/settings.json`. `commit-concision` pauses Claude's first attempt at each commit that changes non-data files, so Claude can tighten the commit's prose; it covers only Claude Code's commits, not Codex's or yours.
- **`global/AGENTS.md`, named `instructions`:** global instructions, linked as both `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`.

## Install

```sh
git clone https://github.com/betsyhcamp/agent-tools.git
cd agent-tools
./link.sh --all      # every skill and hook, and the instructions
./link.sh NAME...    # or pick, e.g. ./link.sh pr-notes commit-concision instructions
./link.sh --check    # confirm each tool reads from this clone
```

Everything is linked, not copied, so `git pull` updates it. Before `link.sh` replaces a file or edits `settings.json`, it shows the change, asks, and keeps a `.bak-` copy beside the original.

Links store this clone's absolute path. After moving the clone, remove the old skill links (`rm ~/.claude/skills/NAME ~/.agents/skills/NAME`) and rerun `link.sh`; it offers to relink hooks and instructions.

Requires bash (3.2 or later). Hooks need `jq`, both to install and, for `commit-concision`, to run. MIT licensed.
