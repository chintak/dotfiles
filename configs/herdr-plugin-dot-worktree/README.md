# herdr-plugin-dot-worktree

Herdr plugin `dot.worktree` — the tab-per-task worktree workflow described in
[`specs/agentic-dev-mvp.md` §11.1](../../specs/agentic-dev-mvp.md).

## Why

The environment is one Herdr **workspace per project**, with worktrees demoted
to **tabs** (§8–§9). That layout is owned by `dot`, not by Herdr: `dot` knows
the task id, branch, worktree path, panes, and dev server. The plugin only
surfaces those operations in the Herdr UI, so the workflow is discoverable
without memorising `dot` subcommands.

## What

`files/` is a Herdr plugin source tree:

```
files/
├── herdr-plugin.toml   # actions, board pane, link handler, worktree event
└── bin/                # thin wrappers; every one ends in a `dot …` call
    ├── new-task.sh
    ├── finish-task.sh
    ├── apply-layout.sh
    ├── open-review.sh
    └── task-board.sh
```

The plugin keeps **no state of its own**. `dot` owns
`~/.local/state/dot/dev/state.json`; the wrappers read the injected Herdr
context (`HERDR_BIN_PATH`, `HERDR_WORKSPACE_ID`, `HERDR_PANE_ID`) and delegate
to the runtime verbs in `specs/agentic-dev-mvp.md` §3.2.

| Action / pane  | Wrapper           | Delegates to            |
|----------------|-------------------|-------------------------|
| `new-task`     | `new-task.sh`     | `dot task new …`        |
| `finish-task`  | `finish-task.sh`  | `dot task finish …`     |
| `apply-layout` | `apply-layout.sh` | `dot up`                |
| `open-review`  | `open-review.sh`  | `dot review …`          |
| `board` pane   | `task-board.sh`   | `dot task list --watch` |

## How

`dot apply herdr-plugin-dot-worktree` copies `files/` recursively to
`~/.config/dot/plugins/dot.worktree` (the manifest's `file = .|…` directory
source), then `post_apply` links and enables it:

```bash
herdr plugin link ~/.config/dot/plugins/dot.worktree
herdr plugin enable dot.worktree
```

Verify with `herdr plugin list`. The plugin requires `herdr` (declared via
`requires`) and a running Herdr server. It is *not* symlinked like the file
configs — Herdr owns the linked plugin directory, so `dot` stages a copy.

Schema note: `contexts = ["workspace"]`, `placement = "overlay"`, and
`on = "worktree.created"` were checked against the installed `herdr 0.9.0`
(`herdr api schema`) and are all valid.
