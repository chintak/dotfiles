---
name: herdr-subagents
description: Delegate work to subagents in Herdr. Use when a task should be
  parallelized across agents or isolated in its own worktree. Requires HERDR_ENV=1.
---

# Herdr subagents

Guard: `test "${HERDR_ENV:-}" = 1`.

## Rule: subagents get a NEW TAB, not a pane
Deliberate override of `herdr --skill`. Never `pane split` for a subagent.

## Spawn
scripts/spawn.sh <type> <word>… [--prompt TEXT]
  → dot task new <type> <word>… --kind pi --prompt TEXT --no-focus
  → prints the task id and agent tab id

## Wait / collect
herdr agent wait <task> --until done --timeout 900000
herdr agent read <task> --source recent-unwrapped --lines 200

## Full skill
The Herdr CLI is authoritative: run `herdr --help`, `herdr agent`, `herdr tab`.
Read IDs from JSON (`.result.*`), never predict them.
