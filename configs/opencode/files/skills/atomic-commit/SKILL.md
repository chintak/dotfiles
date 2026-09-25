---
name: atomic-commit
description: >-
  Commit completed logical chunks as separate Conventional Commits in a feature worktree. Use when asked to make atomic commits or when the ship skill needs to commit work. Never commit on the default branch or in the primary checkout.
compatibility: Requires git
allowed-tools: Bash(git:*)
---

# Atomic Commit

- Commit each completed logical unit of work separately.
- Never push or open a PR — use `ship` for that.

## 1. Verify the checkout

- Identify:
  - Default branch: `git symbolic-ref --short refs/remotes/origin/HEAD` (strip `origin/`; fallback: `main`/`master`)
  - Current branch: `git branch --show-current`
  - Checkout: `git rev-parse --show-toplevel`
  - Primary checkout: first `worktree` entry of `git worktree list --porcelain`
- Work only in a **feature worktree on a feature branch** — never the primary checkout, default branch, or detached HEAD.
- Primary checkout clean: `git worktree add -b <branch> <path> <default-branch>`; work there. Use descriptive, non-colliding names.
- Primary checkout dirty: stop and ask. Never move, stash, reset, or commit its changes without permission; never assume they belong to this task.
- On the default branch in a secondary worktree: create or switch to a feature branch before staging. Never switch branches over unrelated local changes.

## 2. Partition the work

- Inspect `git status --short`, `git diff`, `git diff --cached`.
- Stage only files/hunks belonging to this task; preserve unrelated user changes.
- Unclear ownership of staged work: separate it safely or ask — never commit it in one unit.
- One commit per completed, validated chunk. Multiple distinct changes → multiple commits, even in the same file.
- Stage exactly: `git add -- <paths>` or `git add -p`. Never `git add .` or `git add -A`.
- Before each commit: review `git diff --cached` and `git diff --cached --name-status`.
- Run relevant checks per chunk; record what actually ran — or say why checks couldn't run.
- Never amend already-pushed commits.

## 3. Write each commit

- Subject: `<type>(<optional-scope>): <imperative summary>` — `<type>!: ...` for breaking changes.
  - Type reflects *this commit*, not the branch: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `perf`, `style`.
  - Under 72 characters.
- Body — use exactly these sections, with truthful, concise bullets:

```text
feat(skills): add atomic commit workflow

Changes:
- Describe the logical change and why it matters.

Validation:
- `command` (passed), or "Not run: reason".

Files Changed:
- A: skills/atomic-commit/SKILL.md
```

- `Files Changed`: list **every** staged file with status (`A`, `M`, `D`, `R`).
- Verify the commit and remaining working tree before the next chunk. No unrelated leftovers in the last commit.
