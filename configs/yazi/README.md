# yazi

File manager with inline previews — useful for watching agents mutate files.

- Previews images and PDFs inline. PDFs need `poppler`'s `pdftoppm`; `chafa` is
  the fallback for terminals without a graphics protocol (Ghostty has one).
- `Enter` opens with the right opener: `hx` for code, `glow` for markdown,
  the system viewer for PDFs/images.
- Markdown previews render through the official `piper.yazi` plugin
  (vendored in `files/piper.yazi`, sourced from yazi-rs/plugins@main) shelling
  out to `glow` with glamour's built-in `dracula` style (readable on the
  dark Ghostty terminal). The command in `yazi.toml` sets `CLICOLOR_FORCE=1`
  (piper pipes glow's output), pins `-s dracula` explicitly (an env-set
  style alone makes glow fall back to notty when not a tty, and relying on
  the parent env makes the theme depend on how yazi was launched), and
  `PAGER=cat` so glow's `pager: true` doesn't run `less` in the pane.
- UI theme is the upstream `tokyo-night` flavor
  (BennyOe/tokyo-night.yazi, pinned at `8e6296f`, vendored in
  `files/flavors/tokyo-night.yazi` like `piper.yazi` — declarative, no
  `ya pkg add`), selected via `[flavor] dark` in `theme.toml`, which keeps
  only local overrides (row highlight, empty status separators).
- Openers use yazi's `%s` shell formatting — `$@` was deprecated in yazi 26
  and stopped passing the file to `hx`.
- `e` edits in Helix; `y` yanks the path.
- Six official plugins vendored under `files/plugins/` (yazi-rs/plugins,
  pinned at `7200d7374462ba11c0fa5662115a96dd6ef8c9ab`, declarative like
  `piper.yazi` — never `ya pkg add`):
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
  - `toggle-pane.yazi` (`T`) — `min-preview`: hide/show the preview pane
    (upstream's key example; free in the preset).
  - `diff.yazi` (`<C-p>`) — diff selected vs hovered, copy patch to
    clipboard. Upstream suggests `<C-d>`, but that's preset half-page-down,
    so `<C-p>` (patch mnemonic, free in `mgr`) instead.

Needs the terminal to expose a graphics protocol — Ghostty does
(`kitty_graphics = true` in `herdr/config.toml`).
