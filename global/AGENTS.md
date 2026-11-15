# Commits

- Write every commit message as a single line, with no body or trailers.
- Never credit an AI assistant in commits or pull requests: no Co-Authored-By or "Generated with" lines.
- In commit messages and PR titles and descriptions, describe changes in plain English. Never use internal labels such as "Part 4" or "Step 4", or placeholders such as `$1`.


# Prose

- Applies to all prose in and around code: comments, docstrings, strings people read (such as help text and warning, error and log messages), READMEs and other docs, specs, handoffs, PR and issue text, and messages to me.
- Distill first: include only what the reader needs to understand or act. That includes why something was done and how the decision was reached, and an example when it makes a point clearer. Leave out what they already know, what the code or another document already says, and hedges.
- Then compress: use the fewest words that stay clear. When the two pull apart, lean slightly toward concision.
- Docstrings: one line for a test, two at most; one line or none for a module; for anything else, only when the name and signature don't say enough.
- Comments: only what the code can't say, such as why, a constraint or a hazard. Never restate the code.
- To refer to something documented elsewhere, name it in a few words and add its link, path or number; never a bare number or label.
- For documents such as READMEs, specs, handoffs and issue text, reread the draft as its reader before handing it over, and cut what isn't needed, keeping every fact, number and caveat they need.
- Apply this to what you write or change; don't rewrite existing prose unless asked.
- A repository's own documented conventions override these defaults.

