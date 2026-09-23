# helix

The editor for browsing and editing *inside panes*. Chosen over nvim here
because it needs no plugin manager: it auto-detects and starts LSP servers found
on `PATH`.

`languages.toml` only pins what auto-detection gets wrong (Python, Lua).
`$EDITOR=hx` is set in `zshrc`; `git config` uses `core.editor = hx`.

Code browsing = `hx <worktree>` in a pane, or `yazi` → Enter.
