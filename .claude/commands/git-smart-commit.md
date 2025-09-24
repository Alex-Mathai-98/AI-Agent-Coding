# git-smart-commit
You are operating in a Git repo with a terminal. Perform a **non-interactive staged-only commit + push** with a high-quality message derived from the staged diff.

**Behavior**
1) Verify there are staged changes. If none, print “No staged files” and stop.
   - Check with: `git diff --cached --name-only`
2) Gather context to write the message:
   - Staged summary: `git diff --cached --stat`
   - Staged patch: `git diff --cached`
   - Current branch: `git rev-parse --abbrev-ref HEAD`
3) Compose a descriptive commit message using **Conventional Commits** style if possible, with:
   - A concise title (≤ 72 chars)
   - A wrapped body explaining what changed and why
   - Optional scope and references (issue/PR) if detectable
   - If the user passed text as arguments (`$ARGUMENTS`), treat it as an **additional hint**; blend it into the body but still summarize the changes from the diff.
4) Run the commit (staged only):
   - `git commit -m "<generated subject>" -m "<generated body>"`
5) Push:
   - If upstream exists: `git push`
   - Else set upstream to `origin <branch>`: `git push -u origin "$(git rev-parse --abbrev-ref HEAD)"`
6) Error handling (print and stop, don’t prompt):
   - Repo not initialized, auth failures, protected branch, diverged history
   - If push is rejected due to non-fast-forward, print: 
     “Push rejected (non-fast-forward). Pull/rebase required.”
7) Finally, print:
   - The branch name, commit SHA (`git rev-parse --short HEAD`), and the one-line subject.

**Notes**
- Only include **staged** changes; do not auto-stage files.
- Never include secrets or large diffs in the commit message; summarize instead.
- Wrap lines at ~72/100 chars.
- Use the terminal tool for all shell commands.
