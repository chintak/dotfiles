# direnv

`direnv.toml` sets a `[whitelist] prefix` on `~/git`, so any `.envrc` under
it loads without `direnv allow`, even after the file changes.

A uv project needs only a one-line `.envrc`:

```sh
echo 'layout uv' > .envrc
```

On `cd`, `layout uv` runs `uv sync --frozen`, exports `VIRTUAL_ENV`, and puts
`.venv/bin` first on `PATH`. Leaving the directory undoes it. Starship's
`python` module then shows the venv name.

The shell hook itself lives in the `zsh` config (`zshrc`). direnv is
installed by `brewfile`.
