---
name: worktree
description: Implement a subtask in an isolated git worktree (via worktrunk `wt`) and safely integrate it — agents merge into a per-feature integration branch, NEVER into `main`; a human gates `main` with a reviewed PR. Use when running parallel-agent work across worktrees, or when asked to do a subtask in its own worktree and merge it back.
---

# Worktree subtask workflow (worktrunk `wt`)

Isolate each subtask in its own git worktree, commit it, and merge into a **per-feature integration
branch** — **never merge into `main` directly**. A human merges the integration branch into `main`
via a reviewed PR.

Subtask / feature context: $ARGUMENTS

## Safety model (non-negotiable)

```
main                       ← protected; ONLY a human merges in (via PR). Agents NEVER touch it.
  └── <feature>-into-main   ← integration branch (off main); agents merge HERE
        ├── alpha           ← agent worktree (off <feature>-into-main)
        └── beta            ← agent worktree
```

## A. Per-feature setup (once — usually the orchestrator)

```bash
git -C <repo> pull --ff-only origin main       # update main first (run on the main worktree)
wt switch --create <feature>-into-main         # integration branch, branched off main
```

## B. Per subtask (your job as the agent)

```bash
# 1. new worktree off the INTEGRATION branch (NOT main); wt switch auto-cd's you in
wt switch --create <name> --base <feature>-into-main

# 2. implement the subtask; make its tests pass

# 3. commit — stage ONLY the files you changed, BY NAME. NEVER `git add .` / `-A`.
git add path/to/changed_file path/to/test_file
git commit -m "implement <subtask>"

# 4. merge into the integration branch (never main)
wt switch <feature>-into-main
git merge <name>            # on conflict: resolve markers → git add <files> → git commit

# 5. remove the merged worktree (+ its now-merged branch)
wt remove --force <name>
```

## C. Push the integration branch, then hand off (agent pushes; human PRs)

**You MUST push the integration branch** so it appears on GitHub for review — then STOP. A human
opens the PR into `main`; you never do.
```bash
git -C <repo> push -u origin <feature>-into-main   # REQUIRED — makes the branch visible online
# A HUMAN then opens a PR on GitHub: <feature>-into-main → main, reviews the combined diff, and merges.
```
Do NOT open the PR yourself and do NOT merge into / push `main` — that stays human-gated. Only the
**integration branch** is pushed; agent sub-branches (`<name>`) stay local and ephemeral.

## Guardrails (critical — read before acting)

- **Never merge into `main`.** Agents only merge into `<feature>-into-main`; `main` is human-gated.
- **Push the integration branch — and nothing else.** The agent pushes `<feature>-into-main`
  (section C) so it's visible on GitHub for review; never push agent sub-branches or `main`, and
  never open the PR yourself.
- **Stage by name — never `git add .` / `git add -A`.** Worktrees are seeded with untracked files
  including **secrets (`dev.env`)**, `.claude/`, `results/`, and scratch `z-*.md`. A blind add
  commits secrets. Stage only the files this subtask actually changed.
- **Use plain `git merge`** (from the integration worktree), *not* `wt merge`, when the work is
  already committed: it works whether or not branches diverged, needs no clean working tree, and
  never sweeps untracked files. (`wt merge`'s default `--stage all` would commit untracked
  scratch/secrets; if you must use it, pass `--no-commit` for already-committed work.)
- **`wt remove` needs `--force`** — seeded worktrees have untracked files, so plain `wt remove` fails.
- **`wt` must be a shell *function*** for `wt switch` to change directory (`type wt` → "wt is a
  shell function"). If it's a plain binary, `cd` into the worktree manually.

## Notes

- All worktrees share one `.git`, so a commit on `<name>` is visible from the integration worktree
  immediately — **no push needed** for a local merge.
- `git merge <X>` merges *into the current branch*, so run it from the integration worktree.
- Run `wt` from the repo root; `wt list` shows current worktrees.
