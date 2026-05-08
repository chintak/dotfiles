---
name: ship
description: >-
  Commit changes, push branch, and open or update a pull request following
  Conventional Commits. Use when the user says "ship", "ship it", "open a PR",
  or asks to commit and push their work.
compatibility: Requires git and gh CLI
allowed-tools: Bash(git:*) Bash(gh:*)
---

# Ship: Commit and PR Workflow

Follow this procedure exactly to commit the current changes, push the branch, and open or update a pull request. Every step is mandatory.

## Step 1: Determine the default branch

```bash
git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
```

If that fails, check which of `main` or `master` exists. Store it as `DEFAULT_BRANCH`.

## Step 2: Check current branch

```bash
git rev-parse --abbrev-ref HEAD
```

- If on the default branch, you MUST create a new branch before committing (Step 3).
- If already on a feature branch that tracks the correct work, stay on it and skip to Step 4.

## Step 3: Create a new branch (if needed)

### Get the git author initials

```bash
git config user.name
```

Extract initials from the name (e.g. "Chintak Sheth" -> "cs", "Jane Doe-Smith" -> "jds"). Lowercase.

### Determine the change type

Analyze the staged/unstaged changes and pick the Conventional Commits type:
- `feat` — new feature or capability
- `fix` — bug fix
- `refactor` — code restructuring without behavior change
- `docs` — documentation only
- `chore` — maintenance, deps, config
- `ci` — CI/CD changes
- `test` — adding or updating tests
- `perf` — performance improvement
- `style` — formatting, whitespace, linting

### Generate the branch name

Format: `<initials>/<type>/<2-4-word-slug>`

Rules:
- Slug is lowercase, hyphen-separated, 2-4 words describing the change
- Must be git-compatible (no spaces, special chars)

Examples:
- `cs/feat/add-ship-skill`
- `cs/fix/cursor-block-style`
- `cs/refactor/simplify-upgrade-cmd`
- `cs/docs/update-readme-cli`

```bash
git checkout -b <branch-name> $DEFAULT_BRANCH
```

## Step 4: Stage and commit

### Staging rules

- If there are already staged files, commit ONLY those. Leave unstaged files alone.
- If nothing is staged, stage the relevant files for the change. Never use `git add -A` or `git add .` blindly — stage specific files.

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

- `<type>` must match the branch type
- `<scope>` is optional, a noun in parentheses describing the area (e.g. `feat(cli):`, `fix(rules):`)
- `<description>` is a concise imperative summary, lowercase, no period, under 72 chars

#### Body

- Summarize the changes as concise 1-line bullets
- Explain WHY the change was made, not just WHAT changed
- Separate from the title by a blank line

#### File manifest

- List every file in the commit with a status prefix: `A` (added), `M` (modified), `D` (deleted)

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

### Commit message examples

```
feat(cli): add push subcommand for contributing configs upstream

- Add push action that copies project configs into dotfiles repo
- Spawn background Claude process to create PR after push
- Add --force flag to overwrite existing entries

Files changed:
- M: bin/skills-cli
- M: README.md
```

```
fix(ghostty): use no-cursor prefix for shell integration

- Ghostty merges default shell-integration-features back in
- Omitting 'cursor' doesn't disable it; must use 'no-cursor' prefix
- Fixes block cursor not applying on new tabs

Files changed:
- M: ghostty/config
```

## Step 5: Push the branch

```bash
git push -u origin <branch-name>
```

## Step 6: Open or update the PR

Use the `gh` CLI. First check if a PR already exists for this branch:

```bash
gh pr view --json number 2>/dev/null
```

### If no PR exists, create one:

```bash
gh pr create --title "<title>" --body "<body>"
```

### If a PR already exists, update it:

```bash
gh pr edit --title "<title>" --body "<body>"
```

### PR title

Same as the commit title (Conventional Commits format). If the branch has multiple commits, summarize the overall change.

### PR description format

The body MUST contain these four sections:

```markdown
## Why

<1-3 sentences explaining the motivation. What problem does this solve? Why now?>

## What

<Bulleted list of the concrete changes made. One bullet per logical change.>

## How

<Brief explanation of the approach/implementation. Mention key design decisions, trade-offs, or alternatives considered.>

## Validation

<How this was tested or verified. Include:>
- [ ] Manual testing steps taken
- [ ] Automated tests added/updated (if applicable)
- [ ] Edge cases considered
```

### PR description example

```markdown
## Why

The skills-cli had no way to contribute project-local configs back to the
shared dotfiles repo. Users had to manually copy files and create PRs.

## What

- Add `push` subcommand that copies a config from project editor dirs into dotfiles
- Auto-spawn Claude Code in the background to create a branch and open a PR
- Add `--force` flag to overwrite existing entries
- Ensure default branch checkout before writing to repo

## How

Push scans .cursor/, .claude/, .codex/ dirs for the named config, copies it
to the dotfiles category directory, then spawns a detached Claude process
with a prompt to create the branch, commit, and open the PR via gh CLI.

## Validation

- [x] Tested push with new config -> file copied, Claude spawned
- [x] Tested push without --force on existing -> correctly refused
- [x] Tested push --force -> overwrites and spawns PR
- [x] Tested with no claude in PATH -> graceful skip with message
```

## Rules

1. NEVER commit directly to the default branch (`main`/`master`). Always branch first.
2. NEVER use `git add -A` or `git add .`. Stage specific files.
3. NEVER amend commits that have been pushed. Create new commits instead.
4. ALWAYS include the file manifest in the commit body.
5. ALWAYS open/update a PR after pushing.
6. ALWAYS include Why/What/How/Validation sections in the PR description.
7. If the PR already exists, update its title and description to reflect ALL commits on the branch (not just the latest).
