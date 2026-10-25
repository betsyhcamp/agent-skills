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
4. If evidence is missing or contradictory, ask one concise question before drafting. If the user confirms nothing ran, say so plainly.

## Write

Read the repo's CLAUDE.md and AGENTS.md, whichever exist, and follow their prose rules. If the repo has a pull request template, fill its headings instead of the ones below. Be as concise as possible while staying clear, and scale the bullets to the diff: a small PR may need two.

- **Title:** one line under 70 characters in the repo's commit-subject style, summarizing the net change. Never the branch name.
- **Summary:** at most two sentences: what changes and why, for a reader outside the project. Never pack a list into one sentence. Name any breaking change here too.
- **Key changes:** reviewer-relevant behaviors, most important first. Lead each bullet with a bold label, adding a path when it helps locate the change. Describe the end state: fold review fixes into the bullet for what they fixed, and do not list every file or commit.
- **Verification:** confirmed outcomes only, each with its method and result: the command, count, URI, comparison or manual scenario.
- **Notes for reviewers:** only when non-empty: breaking changes, migrations, limitations, and findings outside this PR's scope.

## Output

The title on its own line, then the description in one block fenced with four backticks, so code blocks inside it survive. Add `## Notes for reviewers` after Verification only when it has content.

<PR title>

````markdown
## Summary

<summary>

## Key changes

- <change>

## Verification

- <evidence>
````
