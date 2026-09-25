---
name: ship
description: >-
  Ship feature work from a separate worktree: make atomic Conventional Commits, update from the default branch, push, and create or update a focused PR. Use when asked to "ship", "ship it", or open or update a PR. Never commit in the primary checkout or directly on the default branch.
compatibility: Requires git and gh CLI
allowed-tools: Bash(git:*) Bash(gh:*)
---

# Ship

- Never merge the PR unless explicitly asked.
- Never commit in the primary checkout or directly on the default branch.

## 1. Check the checkout first

- Identify:
  - Default branch: `git symbolic-ref --short refs/remotes/origin/HEAD` (strip `origin/`; fallback: `main`/`master`)
  - Current branch: `git branch --show-current`
  - Primary checkout: first `worktree` entry of `git worktree list --porcelain`
  - Changes: `git status --short`
- Dirty primary checkout: **stop and ask.** Never stash, move, discard, or commit its changes — even if they look relevant.
- Clean primary checkout: `git worktree add -b <branch> <path> <default-branch>`; continue there.
- Secondary worktree: must be on a feature branch (not the default branch or detached HEAD). Create one if needed. Never overwrite unrelated changes to switch branches.
- Branch naming: `<author-initials>/<type>/<3-4-word-slug>`
  - Initials: lowercase, from `git config user.name`
  - Type: Conventional Commits type (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `perf`, `style`)
  - Slug: lowercase, hyphenated, descriptive — e.g. `cs/feat/add-atomic-commit-skill`
  - Mismatch: rename with `git branch -m` **before pushing**
  - Already pushed / PR exists: check upstream and PR first; coordinate with the user — never silently break links or delete remote branches.

## 2. Keep the PR focused

- Inspect: branch commits + diff from merge base (`git log`, `git diff`), existing PR (`gh pr view`), working changes.
- Related work: keep on this branch.
- Unrelated work: new worktree + branch — base on the feature branch only if dependent; otherwise on the default branch.
- Dependent work: stacked PR targeting the parent feature branch. Never contaminate either PR with unrelated changes.
- Ambiguous staged/uncommitted user work: ask before moving it.
- Prefer small, concrete PRs over catch-alls.

## 3. Commit and update the branch

- Follow the `atomic-commit` skill for each completed logical chunk. Never commit unrelated files.
- `git fetch origin <default-branch>` — **never `git pull`**.
- `git merge origin/<default-branch>` into the feature branch only — never the primary checkout.
- Stacked PRs: keep the parent branch updated; update the child from its parent; don't move unrelated changes into the parent PR.
- Conflicts: resolve straightforward ones, validate the result. Tricky or ambiguous: stop and ask. Never discard someone else's changes.
- Run relevant checks after the merge.
- Push: `git push -u origin <branch>` (new branch) / `git push` (existing upstream). Never force-push unless explicitly authorized.

## 4. Create or update the PR

- Existing PR: `gh pr view --json number,baseRefName,url` → update with `gh pr edit`; otherwise `gh pr create`.
- Base: default branch — or parent feature branch for stacked PRs.
- Review **all** commits and the full diff from the PR base, not just the latest commit.
- Title: concise, Conventional Commits style, summarizing the entire branch.
- Body — use exactly these headings:

```markdown
## Motivation
<Problem and reason for this change.>

## Changes
- <Concrete, feature-specific change.>

## Validation
- `<command>` — passed (or what was not run and why).

## Files Changed
- `path/to/file` — <purpose>.
```

- Evidence where it helps review: test results, screenshots/video for visual changes, linked docs/URLs, small table or Mermaid diagram for complex flows. No filler, invented results, or diagrams for simple changes.
- Include every changed file (or a compact, unambiguous grouping).
- Report the PR URL and any validation limitations. **Do not merge.**
