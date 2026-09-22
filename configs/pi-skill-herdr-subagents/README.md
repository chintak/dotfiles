# pi-skill-herdr-subagents

A Pi **skill** that teaches a Pi agent to delegate work to subagents inside
Herdr — each in its own worktree and its own tab — and then wait for and collect
their results.

## Why

Pi's own `herdr --skill` guidance puts subagents in split panes. In this setup a
subagent is a *task*: it owns a branch, a worktree, a review pane and a dev
pane. Giving it a pane would bury it inside the lead agent's tab and lose that
topology. The skill therefore encodes a deliberate override — **subagents get a
NEW TAB, never a pane** — and hands the agent thin, correct wrappers so it does
not have to remember the `dot task new` / `herdr agent` incantations.

## What

`~/.pi/agent/skills/herdr-subagents/` gets:

- `SKILL.md` — the rule and the spawn/wait/collect workflow.
- `scripts/spawn.sh` — `dot task new <type> <words…> --kind pi --no-focus`,
  then prints the task id and agent tab id.
- `scripts/wait.sh` — `herdr agent wait <task> --until done --timeout 900000`.
- `scripts/collect.sh` — `herdr agent read <task> --source recent-unwrapped --lines 200`.

All three guard on `HERDR_ENV=1` and exit non-zero outside Herdr.

## How

```bash
spawn.sh feat add oauth login --prompt "Implement OAuth login…"
wait.sh feat-add-oauth-login
collect.sh feat-add-oauth-login
```

The naming helper (`dot name`) guarantees that the task's tab, branch and agent
name all match, so the id `spawn.sh` prints is the one `wait.sh` and
`collect.sh` expect. Installed by `dot` as a symlink; `dot apply
pi-skill-herdr-subagents`.
