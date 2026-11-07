---
name: pr-notes
description: Drafts a copy-ready pull request title and Markdown description from a branch's net diff and confirmed verification evidence. Use when asked to write or revise PR notes or a PR description. Not for code review, and not for creating or updating a pull request.
---

# PR notes

Draft the title and description for the current branch's pull request. Do not modify files or create, edit or post a pull request.

## Gather

1. Base: the branch the user names, else the remote default (`git symbolic-ref --short refs/remotes/origin/HEAD`, which prints a ref such as `origin/main`), else `main`. Prefer the remote ref: a stale local base pulls already-merged work into the diff. If the base looks stale, ask before fetching.
2. Read `git log --oneline <base>..HEAD`, `git diff --stat <base>...HEAD`, then the full diff, per file when large. Describe the committed net diff, not the commit history. Run `git status --short --untracked-files=no` and warn if uncommitted changes would make the draft incomplete.
3. Verification evidence comes from results captured in this conversation, commit messages, and any handoff or review notes the user points to. A check counts only when the evidence records what was done and its result; never infer a pass from changed tests, a command with no result, or a plan. Do not run new checks unless asked.
4. If there is no usable evidence or results conflict, ask one concise question before drafting. If a check ran but a result the reviewer needs isn't recorded, draft from the confirmed results, note under Notes for reviewers that it isn't recorded, and ask for it in one question after the draft. If the user confirms nothing ran, say so plainly.

## Write

Read the repo's CLAUDE.md and AGENTS.md, whichever exist, and follow their prose rules. If the repo has a pull request template, fill its headings instead of the ones below. Write for a reviewer who has the diff open: say what changed and how it was checked, and leave the details to the diff. Scale the bullets to the diff: a small PR may need two.

- **Title:** one line under 70 characters in the repo's commit-subject style, summarizing the net change. Never the branch name.
- **Summary:** at most two sentences: what changes and why, for a reader outside the project. Never pack a list into one sentence. Name any breaking change here too.
- **Key changes:** reviewer-relevant behaviors, most important first. Lead each bullet with a bold label; add a path only when the PR spans several files and the label doesn't say where. Give the behavior and its main constraint, including anything it must never do, not every rule, example or edge case behind it. Describe the end state: fold review fixes into the bullet for what they fixed, and do not list every file or commit.
- **Verification:** confirmed outcomes only, each with its method and result: the command, count, URI, comparison or manual scenario. Give only the setup needed to judge the result: what ran, on which version, which cases it covered, and how it was scored.
- **Notes for reviewers:** only when non-empty: breaking changes, migrations, limitations, and findings outside this PR's scope, as plain bullets of at most 25 words.

Write a full draft, then revise it as that reviewer before output. Check the title, Summary and each bullet against its limit, and cut:

- wording copied from the diff or the evidence: restate it in about half the words, keeping its numbers, names, quotes and qualifiers;
- paths, file names and config keys the diff already shows;
- examples that only illustrate a behavior;
- setup that doesn't change how a result reads, such as where a run happened;
- anything already said.

Unless the repo's prose rules say otherwise, prefer fragments, semicolons, parentheses and compound modifiers ("hand-tested", not "tested by hand") to full sentences. Meet each limit by cutting words, not by splitting a bullet or by dropping or merging away a behavior, result or setup the reviewer needs; run over a limit rather than lose one. Keep the meaning of every count, scope limit and qualifier such as "not rerun"; never widen a claim or add intent or commitments the evidence doesn't state: "all tests pass" when only the new ones ran is wrong.

## Output

The title on its own line, then the description in one block fenced with four backticks, so code blocks inside it survive. Add `## Notes for reviewers` after Verification only when it has content. With a template, put all the notes under this heading, before any checklist, unless every note fits one of the template's own sections; if the template forbids new sections, use its closest prose field.

<PR title>

````markdown
## Summary

<summary>

## Key changes

- **<label>:** <behavior and its main constraint; whole bullet at most 25 words>

## Verification

- <method, with only the setup needed>: <result; whole bullet one sentence of at most 20 words>
````
