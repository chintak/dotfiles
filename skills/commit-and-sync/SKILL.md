---
name: commit-and-sync
description: >-
  Commit changes directly to the default branch and sync with upstream, keeping
  a linear commit history. Pulls with rebase before pushing. Use when the user
  says "commit and sync", "sync up", or asks to commit straight to main/master
  and push. Do NOT use when the user says "ship" or asks for a PR — use the
  `ship` skill instead.
compatibility: Requires git
allowed-tools: Bash(git:*)
---

# Commit and Sync: Direct-to-Default-Branch Workflow

Follow this procedure exactly to commit local changes directly onto the default branch, integrate any upstream commits via rebase, and push. Linear history must be preserved — never create a merge commit.

## Step 1: Determine the default branch

```bash
git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
```

If that fails, check which of `main` or `master` exists. Store it as `DEFAULT_BRANCH`.

## Step 2: Verify the current branch

```bash
git rev-parse --abbrev-ref HEAD
```

The current branch MUST equal `DEFAULT_BRANCH`. If not, stop and tell the user — this skill only commits to the default branch. Suggest the `ship` skill for feature-branch workflows.

## Step 3: Stage and commit

### Staging rules

- If there are already staged files, commit ONLY those. Leave unstaged files alone.
- If nothing is staged, stage the relevant files for the change. Never use `git add -A` or `git add .` blindly — stage specific files.
- If there is nothing to commit (clean working tree, no staged changes), skip to Step 4 — still pull and confirm we're up to date.

### Determine the change type

Pick the Conventional Commits type that matches the changes:

- `feat` — new feature or capability
- `fix` — bug fix
- `refactor` — code restructuring without behavior change
- `docs` — documentation only
- `chore` — maintenance, deps, config
- `ci` — CI/CD changes
- `test` — adding or updating tests
- `perf` — performance improvement
- `style` — formatting, whitespace, linting

### Commit message format

Follow the Conventional Commits 1.0.0 specification:

```
<type>[optional scope]: <description>

<body>

Files changed:
- A: path/to/added/file
- M: path/to/modified/file
- D: path/to/deleted/file
```

#### Title line

- `<scope>` is optional, a noun in parentheses describing the area (e.g. `feat(cli):`, `fix(rules):`).
- `<description>` is a concise imperative summary, lowercase, no period, under 72 chars.
- Append `!` after the type/scope for breaking changes (e.g. `feat(api)!: ...`).

#### Body

- Summarize the changes as concise 1-line bullets.
- Explain WHY the change was made, not just WHAT changed.
- Separate from the title by a blank line.

#### File manifest

- List every file in the commit with a status prefix: `A` (added), `M` (modified), `D` (deleted).

### Conventional Commits types reference

| Type | When to use | SemVer |
|------|-------------|--------|
| `feat` | New feature or capability | MINOR |
| `fix` | Bug fix | PATCH |
| `BREAKING CHANGE` | Breaking API change (as footer, or `!` after type) | MAJOR |
| `refactor` | Code restructuring, no behavior change | — |
| `docs` | Documentation only | — |
| `chore` | Maintenance, deps, config | — |
| `ci` | CI/CD pipeline changes | — |
| `test` | Adding or updating tests | — |
| `perf` | Performance improvement | — |
| `style` | Formatting, whitespace, linting | — |

### Commit message example

```
docs(readme): document commit-and-sync skill workflow

- Describe direct-to-default-branch use case
- Note linear-history guarantee via rebase
- Contrast with ship skill for feature branches

Files changed:
- M: README.md
- A: skills/commit-and-sync/SKILL.md
```

## Step 4: Pull with rebase

Integrate any upstream commits before pushing. **Always rebase, never merge** — a merge commit would break linear history.

```bash
git pull --rebase origin "$DEFAULT_BRANCH"
```

If the rebase reports conflicts, stop and surface them to the user. Do NOT run `git rebase --abort` or `--skip` automatically; the user decides how to resolve. Once they finish (`git rebase --continue`), proceed to Step 5.

## Step 5: Push

```bash
git push origin "$DEFAULT_BRANCH"
```

If the push is rejected as non-fast-forward (someone else pushed between Steps 4 and 5), repeat Step 4 then retry. Never use `--force` or `--force-with-lease` on the default branch — surface the conflict to the user instead.

## Rules

1. ONLY commit to the default branch. If on any other branch, stop and direct the user to the `ship` skill.
2. NEVER use `git add -A` or `git add .`. Stage specific files.
3. NEVER use `git merge` or `git pull` without `--rebase` — linear history is non-negotiable.
4. NEVER force-push to the default branch under any circumstance.
5. NEVER amend commits that have already been pushed. Create new commits instead.
6. ALWAYS include the file manifest in the commit body.
7. ALWAYS pull --rebase before pushing, even if the local commit just succeeded.
