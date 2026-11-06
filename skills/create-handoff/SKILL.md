---
name: create-handoff
description: Writes a handoff for a fresh agent session, preserving what this session learned that the repo doesn't record (decisions and rationale, discoveries, dead ends, open questions), tailored to an optional objective. Use when asked to create a handoff for another agent session.
argument-hint: "[objective for the next session]"
disable-model-invocation: true
---

# Create handoff

Write a Markdown handoff for a fresh agent session that has the repository but none of this conversation. Its job is to carry over what this session learned that the next session needs and can't readily get from the spec, plan, code, tests, commits, or other docs. It is not a summary of the conversation or a substitute for those artifacts: point to them by path or URL instead of restating them.

The user's objective for the next session: "$ARGUMENTS"

If that is empty or an unfilled placeholder, use an objective the user explicitly gave for the next session, in their request or earlier in this conversation. If there is none, write a general-purpose handoff that doesn't assume what the next session will do: describe the state and what remains open, with no Next steps. Don't ask the user for anything you can reasonably infer; record important unknowns as open questions.

## Choose what to include

Include an item only if it matters for the objective and, without it, the next agent would lose real time, repeat work, or get something wrong. Record what this session established; don't start the next session's work with fresh analysis, designs, or test plans. Organize by topic, not chronology, and don't narrate the session. Look especially for:

- Decisions and why, including rejected alternatives
- Instructions or preferences the user gave in this session that aren't written down elsewhere
- Non-obvious discoveries: surprising library, tool, or environment behavior; constraints; workarounds and why they're needed
- How ambiguities in the spec were interpreted, and deliberate deviations from it
- Dead ends worth not repeating
- Unverified assumptions, open questions, risks, and blockers
- State the repo doesn't make obvious: which uncommitted changes are temporary (debug logging, disabled tests), running processes, local data or configuration changes

Let the objective set the emphasis. For example:

- **Continuing implementation:** what's done and what remains, in the spec's own terms; dependencies, blockers, and validation status.
- **Independent review:** exactly what is under review (branch, base, commits, uncommitted files); design intent, undocumented constraints, tradeoffs, spec interpretations, and unverified assumptions. List known gaps and uncertainties, but don't vouch for correctness or completeness, and don't direct the review (no Next steps): the reviewer should reach its own conclusions.
- **Debugging:** exact symptoms and errors, how to reproduce, where diagnostics live, each attempted fix and its result, hypotheses with the evidence for and against, and unexplored leads.
- **Anything else:** apply the same inclusion test to that objective.

If this session started from an earlier handoff, carry forward what is still true and relevant rather than pointing to it.

If little is worth preserving, write a short handoff that states the objective and points to the artifacts. Never pad a section to fill it.

## Accuracy and safety

The next agent will act on what you write, so:

- State as fact only what you verified, with brief evidence: command and result, `path:line`, commit, "per the user", or "per the earlier handoff". Present everything else as a decision, assumption, hypothesis, or open question.
- Check what you're unsure of, including whether something is already documented, against the repo before writing. Keep checks cheap (git commands, targeted searches): this session's context is probably nearly full, so don't reread large files or run builds or test suites for the handoff.
- Report a test or check as run only if it ran in this session, with its result and any changes made since; if nothing ran, say so. Keep a relevant result from an earlier handoff, the user, or CI with its source, the revision it ran against if known, and "not rerun this session".
- If something that matters is lost to you, such as earlier context after compaction, say so at the top instead of reconstructing it.
- Leave out secrets and personal data, including in quoted errors and logs: API keys, tokens, passwords, private keys, and credentials in URLs or connection strings. If the next session needs a secret, say where it lives (an env var or file), never its value.

## Format

Use this skeleton. Drop any section with nothing worth saying, and adapt a heading when the objective calls for it.

```markdown
# Handoff: <topic>

<YYYY-MM-DD HH:MM> · branch `<branch>` @ `<short SHA>` · <clean | uncommitted changes>

**Objective:** <as given; or "None given." and the current task in one line>

## Read first
- `<path or URL>`: <what to look at there>

## Current state
<Done, in progress, not started; uncommitted and temporary changes; what was verified, how, and when>

## Decisions
- <decision>: <why; alternatives rejected; made by the user or the agent>

## Discoveries
- <non-obvious fact>: <evidence>

## Dead ends
- <what was tried>: <why it failed; how firmly ruled out>

## Open questions and risks
- <assumption, hypothesis, question, or risk>: <basis; how to check>

## Next steps
1. <omit this section for a review or when no objective was given; otherwise concrete actions, naming any skill or command to use>
```

Write concisely, one line per item where possible, but spell out anything only this conversation could explain: no "option B" or "the earlier error". In Read first, a pointer says where to look, not what is there. Reference code by repo-relative `path:line`, summarize changes instead of pasting diffs, and quote only what can't be referenced, such as an exact error message.

## Save and report

1. Before saving, reread the draft as the next agent would. Cut every line that the Read first artifacts or the code already make clear, and anything you worked out only while writing, such as a new gap in the spec or a test plan: the next session can do that itself. Then tighten what remains.
2. Save under `.handoffs/` at the repository root (outside a git repository, the current directory). If `.handoffs/.gitignore` is missing, create it containing `*`: the directory then ignores itself, so ordinary staging such as `git add .` skips handoffs, and the repository's own ignore files and config stay untouched. Leave an existing `.handoffs/.gitignore` as it is. In a git repository, check that `git status --porcelain -- .handoffs` prints nothing after saving; if it lists anything, tell the user.
3. Name the file `YYYY-MM-DD-HHMM-<slug>.md`, from the current local time and a short kebab-case slug for the objective or task. Never overwrite an existing file unless the user explicitly asks you to update it; if the name is taken, append `-2`, `-3`, and so on.
4. Create nothing beyond these files. Don't modify code, tests, specs, or anything else, and don't stage, commit, or push.
5. Reply with the handoff's absolute path and, only if needed, one line on anything the user should handle before the next session, such as uncommitted work.
