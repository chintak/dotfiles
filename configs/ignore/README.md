# ignore

One global ignore file, `~/.ignore`, shared by every tool built on the
`ignore` crate: ripgrep, fd (and so fzf, whose `FZF_DEFAULT_COMMAND` runs fd),
and the helix file picker and global search.

Why one file: these tools read `.ignore` in each parent of the directory they
search, so `~/.ignore` applies to every project under `~`. A `.ignore` match
is checked before `.gitignore`, so a `!` rule here re-includes a path that a
repo's `.gitignore` hides. `!.worktrees/` and `!data/` keep git worktrees
and data directories visible to fzf, rg and helix.

The list also hides dependency, build and cache directories (`node_modules/`,
`.venv/`, `target/`, …) that are not always gitignored.

Add a rule here instead of a per-tool ignore file; helix no longer ships its
own `~/.config/helix/ignore`.
