# agent-skills

Personal agent skills which assumes use of [Claude Code](https://code.claude.com/docs/en/skills) and [Codex](https://learn.chatgpt.com/docs/build-skills). Each folder in `skills/` is one skill; its `SKILL.md` says what it does and when it runs.

## Install

```sh
git clone https://github.com/betsyhcamp/agent-skills.git
cd agent-skills
./link.sh NAME...    # symlink skills/NAME into ~/.claude/skills and ~/.agents/skills
./link.sh --check    # confirm each tool reads its skills from this clone
```

Skills are linked, not copied, so `git pull` updates every linked skill. Links store this clone's absolute path: after moving the clone, remove the old links (`rm ~/.claude/skills/NAME ~/.agents/skills/NAME`) and rerun `./link.sh NAME`.

Requires bash (3.2 or later). MIT licensed.
