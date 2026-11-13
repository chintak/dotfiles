# mise

Global mise config (`~/.config/mise/config.toml`).

- **`[tools]`**: `uv = "latest"`, `go = "latest"`, `rust = "stable"` are the
  default toolchains outside any project. A project's own `mise.toml` pins
  exact versions and wins inside that project. Rust is installed through
  rustup and reuses `~/.rustup` / `~/.cargo` (mise sets `RUSTUP_HOME`,
  `CARGO_HOME`, `RUSTUP_TOOLCHAIN=stable`). Run `mise install` after apply;
  `mise upgrade` moves `latest` tools forward.

- **`python.uv_venv_auto = "source"`**: entering any directory under a
  `uv.lock` activates that project's `.venv` (sets `VIRTUAL_ENV`, prepends
  `.venv/bin` to `PATH`), and leaving deactivates it. Repos need no
  `.envrc` or `mise.toml`. Starship's `python` module then shows the venv
  name.
- `"source"` never creates or syncs the venv. Run `uv sync` after cloning or
  after a lockfile change. Use `"create|source"` to have mise create it.

Requires the `mise activate zsh` hook in the `zsh` config. mise itself is
installed by `brewfile`.
