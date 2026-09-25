# git

Two files, both versioned:

- `files/config` → `~/.config/git/config` — the **XDG** global path: delta
  pager, difftastic aliases, zdiff3 merges.
- `files/gitconfig` → `~/.gitconfig` — user identity (`user.name`/`user.email`)
  and the gh credential helper. Git reads both.

- **delta is the pager**: every `git diff`/`show`/`log -p` gets side-by-side,
  syntax-aware diffs for free.
- **difftastic is opt-in** via `git dft` / `dfst` / `dshow` / `difftool`. We
  deliberately do **not** set `diff.external`: it breaks `git add -p`,
  `git stash -p`, and anything that parses diffs.
- `merge.conflictStyle = zdiff3` shows the common ancestor in conflicts.

Verify: `git config --list | grep -E 'core.pager|difftool.difftastic'`.
