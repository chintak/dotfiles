# mise

Global mise settings (`~/.config/mise/config.toml`).

- **`python.uv_venv_auto = "source"`**: entering any directory under a
  `uv.lock` activates that project's `.venv` (sets `VIRTUAL_ENV`, prepends
  `.venv/bin` to `PATH`), and leaving deactivates it. Repos need no
  `.envrc` or `mise.toml`. Starship's `python` module then shows the venv
  name.
- `"source"` never creates or syncs the venv. Run `uv sync` after cloning or
  after a lockfile change. Use `"create|source"` to have mise create it.

Requires the `mise activate zsh` hook in the `zsh` config. mise itself is
installed by `brewfile`.
