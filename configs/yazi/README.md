# yazi

File manager with inline previews — useful for watching agents mutate files.

- Previews images and PDFs inline. PDFs need `poppler`'s `pdftoppm`; `chafa` is
  the fallback for terminals without a graphics protocol (Ghostty has one).
- `Enter` opens with the right opener: `hx` for code, `rich` for markdown
  (dracula), the system viewer for PDFs/images.
- **Preview stack** — plugins vendored under `files/plugins/`, declarative
  (never `ya pkg add`), each pinned at its upstream HEAD (see the table below):
  - Markdown → `rich-preview.yazi` (AnirudhG07), shelling out to `rich`
    (rich-cli). Its `main.lua` is edited to add `--theme=dracula` to the `rich`
    args (upstream sanctions editing the args). Needs `rich-cli` (installed via
    the `uv-tools` config).
  - Notebooks (`.ipynb`) → `nbpreview.yazi` (AnirudhG07), edited to
    `--theme=dracula` (upstream default was `ansi_dark`). Needs `nbpreview`
    (also via `uv-tools`).
  - Data files (`.csv`/`.tsv`/`.json`) → `mux.yazi` (peterfication) cycles
    `duckdb → rich → code` on `M`. `duckdb.yazi` (wylie102) renders a table /
    DuckDB `SUMMARIZE` summary; `rich` is a mux alias for `rich-preview.yazi`
    (mux resolves each name via `require()` and the plugin dir is
    `rich-preview`, not `rich` — the alias is set in `init.lua`); `code` is
    yazi's builtin previewer. `duckdb.yazi` needs the `duckdb` CLI on PATH and
    `require("duckdb"):setup {}` in `init.lua`; `yazi.toml` adds csv/tsv/json
    preloaders (upstream's `name =` key is rejected by yazi 26.9.1, so `url =`
    is used; only the duckdb-previewed types are preloaded).
  - `piper.yazi` and `glow` are gone.
- **Keys**:
  - `M` — cycle the mux previewer for csv/tsv/json (duckdb → rich → code).
  - `H` / `L` — scroll the duckdb preview one column left/right. These shadow
    the preset `H`/`L` (`back`/`forward` directory history). Column scrolling is
    core to the wide-table duckdb preview and `h` still leaves to the parent
    dir; remap duckdb to `<C-h>`/`<C-l>` if history navigation is wanted.
  - `K` (at the top of a data file) toggles duckdb standard/summarized mode;
    `J`/`K` scroll rows.
  - `T` / `i` — hide/show and maximize/restore the preview pane.
  - `e` edits in Helix; `y` yanks the path.
- **dracula**: markdown and notebook previews render with the dracula theme
  (`--theme=dracula`); markdown also opens via `rich --pager --theme dracula`
  (block). Openers use yazi's `%s` shell formatting — `$@` was deprecated in
  yazi 26 and stopped passing the file to `hx`.
- UI theme is the upstream `tokyo-night` flavor (BennyOe/tokyo-night.yazi,
  pinned at `8e6296f`, vendored in `files/flavors/tokyo-night.yazi` like the
  plugins — declarative), selected via `[flavor] dark` in `theme.toml`, which
  keeps only local overrides (row highlight, empty status separators).
- Official plugins vendored under `files/plugins/` (yazi-rs/plugins, pinned at
  `7200d7374462ba11c0fa5662115a96dd6ef8c9ab`, declarative like the preview
  plugins — never `ya pkg add`):
  - `git.yazi` — git status as linemode signs (`init.lua` runs
    `require("git"):setup { order = 1500 }`; `yazi.toml` registers the `*`
    and `*/` fetchers). Signs colored dracula via `[git]` in `theme.toml`
    (untracked pink, unstaged yellow, staged/added green, deleted red,
    updated orange, ignored comment-grey).
  - `vcs-files.yazi` (`g c`) — flat view of git-changed files. Shadows the
    preset `g c` (`cd ~/.config`); prepend wins. Includes upstream `old.lua`
    (runtime fallback the plugin `require`s when the `vf` VFS global is
    absent).
  - `smart-enter.yazi` (`l`) — enter dir or open file in one key. Shadows
    preset `l` (`enter`) — the plugin's intended use. No setup call:
    hovered-only default matches the `Enter`/`e` convention.
  - `jump-to-char.yazi` (`f`) — vim-like `f<char>` jump to next file by
    first char. Shadows preset `f` (`filter --smart`); `/` find still
    available.
  - `toggle-pane.yazi` (`T`, `i`) — `min-preview` on `T` hides/shows the
    preview pane (upstream's key example; free in the preset); `max-preview`
    on `i` maximizes/restores it (both are actions of the one vendored
    plugin). `[preview] max_width`/`max_height` are raised to `2000` so the
    enlarged pane renders larger images/PDFs.
  - `diff.yazi` (`<C-p>`) — diff selected vs hovered, copy patch to
    clipboard. Upstream suggests `<C-d>`, but that's preset half-page-down,
    so `<C-p>` (patch mnemonic, free in `mgr`) instead.

Needs the terminal to expose a graphics protocol — Ghostty does
(`kitty_graphics = true` in `herdr/config.toml`).

## Vendored plugin sources (pinned SHAs)

| Plugin | Repo | HEAD |
| --- | --- | --- |
| `rich-preview.yazi` | AnirudhG07/rich-preview.yazi | `02597c4a129a36e3ab013b1fd052cf0f555d5490` |
| `nbpreview.yazi` | AnirudhG07/nbpreview.yazi | `b50459402c52cbfd8d9262ae91e353d3300f8a8c` |
| `duckdb.yazi` | wylie102/duckdb.yazi | `3f8c8633d4b02d3099cddf9e892ca5469694ba22` |
| `mux.yazi` | peterfication/mux.yazi | `e4e67713d5043fb7a25491cf4a29ee51e556f32e` |

> `rich-preview.yazi/main.lua` and `nbpreview.yazi/main.lua` are edited for the
> dracula theme — re-apply the `--theme=dracula` edits when re-vendoring.
