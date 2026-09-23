# Spec: `dot` — a versioned, selective dotfiles CLI

- **Status:** final (rev 3)
- **Owner:** Chintak
- **Date:** 2026-09-21
- **Supersedes:** the symlink-everything model in `install.sh`
- **Canonical copy:** `dotfiles/specs/dot-cli.md`. A frozen snapshot is kept at
  `scratchpad/specs/dot-cli.md`.

---

## 1. Motivation

Today, `install.sh` symlinks **every** config from the repo into place. That is
simple and drift-free, but it has no notion of a lifecycle:

- **All-or-nothing** — every machine gets every config, including ones it can't
  use (Ghostty on a headless server).
- **No installed version** — the target is always repo `HEAD`. `apply`,
  `forget`, `update`, `rollback` are meaningless.
- **No discovery** — you can't ask "what configs exist, what's installed, what's
  out of date?"
- **No drift detection** — nothing notices if a tool rewrites its own config.

`dot` fixes this by treating each config as a **small, versioned, selectively
installable package**.

---

## 2. Goals

| # | Goal |
|---|------|
| G1 | One command sets up a whole machine: `curl … \| sh -s -- init --profile mac` |
| G2 | Selective install — per config or per profile; nothing is forced everywhere |
| G3 | Semver per config, with apply / forget / update / rollback |
| G4 | **No drift** — installed files are symlinks into an immutable versioned store |
| G5 | **Detect drift** when it happens (lockfile + content hash) |
| G6 | **Ephemeral mode** for VMs/images: install configs, then purge repo + CLI + store, leaving plain files |
| G7 | Flat, discoverable structure — one folder per config, grouped by a `category` tag |
| G8 | Bash only — no runtime deps beyond `git` + `jq` + coreutils |

## 3. Non-goals

- Templating or host conditionals *inside* config files. Host differences go in
  `~/.zshrc.local` and `localenvs/*.local`.
- Being a general-purpose package manager (no dependency graph beyond `requires`).
- Windows.
- `parts/` composition (deferred — see §14).

---

## 4. Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| **D1** | Install mechanism = **versioned store + symlink** | You can't `chmod` a symlink, so immutability needs a real file; and `apply/update/rollback` need *installed ≠ HEAD*. Symlinking to a store copy keeps today's zero-drift property while adding versions. |
| **D2** | Written in **bash** | Zero runtime deps, works on a bare Hetzner/RunPod image. Deps: `git`, `jq`, coreutils. |
| **D3** | **No `chmod 444` in v1** | Store + symlink + lockfile already *detect* drift by hash. 444 adds friction, not detection, and can break tools that rewrite their own config. Ship `--lock` as opt-in later. |
| **D4** | **No `parts/` in v1** | Don't build a composition language before a config needs it. |
| **D5** | **chezmoi verbs** | `init`, `apply`, `forget`, `update`, `add`, `edit`, `diff`, `status`, `doctor`, `cd` — familiar, well-understood semantics. Plus `rollback`, `purge`, `bump`, `list`, `info`, `profiles` for the versioning layer chezmoi lacks. |
| **D6** | **Copy mode exists only for ephemeral installs** | The store is the normal path; ephemeral copies to the target and then deletes the store so nothing dangles. |
| **D7** | **Flat structure: `configs/<tool>/`**, with `category` as metadata | The atomic unit is a config, so the directory mirrors that. A hierarchy would imply nesting the install model doesn't have. Categories are a *view* (grouping in `dot list`), not a location — so "is starship `shell` or `prompt`?" stops being a structural question. See §6. |
| **D8** | **JSON lockfile** | `jq` is already a dependency; JSON nests cleanly (targets as a list) and is trivially queryable. |
| **D9** | **`update` pulls with `--rebase --autostash`** | Matches chezmoi: `git -C "$repo" pull --rebase --autostash`, then apply. `--no-pull` opts out. |
| **D10** | **Edits go through `dot edit`, not hand-editing** | Keeps the repo clean and the lifecycle explicit. |

---

## 5. Architecture

```
                 ┌─────────────────────────────────────────────┐
  curl | sh ───▶ │ bootstrap.sh  → installs `dot`, runs it      │
                 └─────────────────────────────────────────────┘
                                        │
                                        ▼
   repo (git)                     ┌───────────┐
   configs/<tool>/           ───▶ │   dot     │
     manifest · files/ · README   └─────┬─────┘
                                        │
                 ┌──────────────────────┼──────────────────────┐
                 ▼                      ▼                      ▼
        store (versioned)         targets (symlinks)        lockfile
   ~/.local/share/dot/store/     ~/.config/ghostty/config   ~/.local/state/dot/
     ghostty/1.0.0/config          └─▶ store/ghostty/1.0.0/config   installed.json
```

### Paths

| Purpose | Path | Override |
|---------|------|----------|
| CLI binary | `~/.local/bin/dot` | `DOT_BIN_DIR` |
| Repo clone | `~/.local/share/dot/repo` | `DOT_REPO` |
| Versioned store | `~/.local/share/dot/store/<config>/<version>/` | `DOT_STORE` |
| Lockfile | `~/.local/state/dot/installed.json` | `DOT_STATE` |
| User config | `~/.config/dot/config` | — |

The repo lives under `~/.local/share/dot/repo` (not `~/git`) to keep `~` clean.
You don't hand-edit it — you use `dot edit <config>`, which opens the file in
`$EDITOR` from inside the clone.

Resolution order for the repo: `--repo` flag → `$DOT_REPO` →
`~/.config/dot/config` → the checkout `dot` itself lives in (dev mode) →
`~/.local/share/dot/repo`.

---

## 6. Repository layout

**Flat: one folder per config.** Categories are a tag, not a directory.

```
dotfiles/
├── dot                          # the CLI (bash, executable)
├── bootstrap.sh                 # curl entrypoint
├── README.md                    # lifecycle + how to use `dot`
├── specs/
│   └── dot-cli.md               # this document
├── profiles/
│   ├── mac.conf
│   └── server.conf
└── configs/
    ├── README.md                # index + category legend + design rationale
    ├── zsh/                     { README.md, manifest, files/zshrc }
    ├── starship/                { README.md, manifest, files/starship.toml, files/starship.mobile.toml }
    ├── ghostty/                 { README.md, manifest, files/config }
    ├── herdr/                   { README.md, manifest, files/config.toml }
    ├── tmux/                    { README.md, manifest, files/tmux.conf }
    ├── zellij/                  { README.md, manifest, files/config.kdl, files/layouts/*.kdl }
    ├── git/                     { README.md, manifest, files/gitconfig }
    ├── skills/                  { README.md, manifest, files/… }
    ├── brewfile/                { README.md, manifest, files/Brewfile }
    └── uv-tools/                { README.md, manifest, files/tools.txt }
```

### Why flat, and what `category` buys

- **Identity is the folder name.** `configs/herdr/` *is* the `herdr` config.
  Moving it into a group would change its name and break `requires` and
  profiles.
- **Categories are a view.** `category = multiplexer` groups `herdr`, `tmux`,
  and `zellij` in `dot list` without pretending they live in a shared folder.
- **The ambiguous cases disappear.** `starship` is `category = prompt`, not a
  debate about whether a prompt is part of a "shell domain".

Suggested categories (free-form strings, not an enum):
`shell`, `prompt`, `terminal`, `multiplexer`, `vcs`, `editor`, `agents`,
`packages`.

### READMEs

- `configs/README.md` — the index: category legend, the overall rationale,
  and how the pieces relate.
- `configs/<tool>/README.md` — the opinionated choices *for that tool*: why it's
  configured this way, the non-obvious settings, and the trade-offs.

Keep them short. They are *why*, not tutorials — the root README links out for
the *how*.

---

## 7. Config package format

`configs/ghostty/manifest` — plain `key = value`, one per line, no parser:

```
version     = 1.0.0
description = Ghostty — fast renderer; hands its chords to herdr
category    = terminal
platform    = mac
requires    = zsh
file        = config|~/.config/ghostty/config
# post_apply = brew bundle --file ~/.config/dot/Brewfile
```

| Key | Required | Meaning |
|-----|----------|---------|
| `version` | yes | semver of this config (§15) |
| `description` | yes | one line, shown by `dot list` / `dot info` |
| `category` | yes | grouping tag (§6) |
| `file` | yes (≥1, unless `post_apply`) | `src-rel-path\|target` — repeatable |
| `requires` | no | comma-separated config names applied first |
| `platform` | no | `mac` / `linux` / `any` (default `any`) |
| `post_apply` | no | one command run after the config is (re)installed |

`file` sources are relative to the config's `files/` directory. Targets support
`~` and `${VAR}` expansion.

**`post_apply` is deliberately the only hook.** It exists so configs whose job is
an *action* rather than a *file* (package installation) fit the model. It is one
line, has no templating, no conditionals, and no ordering guarantees beyond
"after this config's files are in place". Idempotency is the config author's
responsibility.

**When it runs.** The lockfile records an `applyHash` — a hash of the config's
`version` + file contents + the `post_apply` string. `post_apply` runs whenever
that hash changes, so a new tool added to `uv-tools.txt`, a version bump, and an
edited `post_apply` line all trigger it, while re-applying an unchanged config
does not. `--force-post` overrides.

---

## 8. Versioning, store, lockfile

**Store** — every installed version is retained, so rollback is a re-link:

```
~/.local/share/dot/store/ghostty/1.0.0/config
~/.local/share/dot/store/ghostty/0.9.0/config   # kept for rollback
```

**Lockfile** — `~/.local/state/dot/installed.json`:

```json
{
  "lockfileVersion": 1,
  "configs": {
    "ghostty": {
      "version": "1.0.0",
      "mode": "symlink",
      "category": "terminal",
      "hash": "sha256:a1b2c3…",
      "store": "~/.local/share/dot/store/ghostty/1.0.0",
      "targets": ["~/.config/ghostty/config"],
      "installedAt": "2026-09-21T13:52:00Z"
    }
  }
}
```

The lockfile is the record of *what this machine has*, which is what makes
`status`, `update`, `rollback`, and `doctor` possible. It is also the thing that
gets deleted in ephemeral mode.

---

## 9. Drift detection — and why `status` and `doctor` are different

**No 444 in v1.** Detection, not prevention.

Following chezmoi, the two commands answer **different questions** and are not
redundant:

| | `dot status` | `dot doctor` |
|---|---|---|
| Question | "What would `apply` change?" | "Is my setup broken?" |
| Scope | per-config content state | environment, tooling, manifest validity |
| Run it | daily, or in a prompt | when something misbehaves |
| chezmoi | `chezmoi status` | `chezmoi doctor` |

### `dot status` — content drift

Compares each config's target against the repo's current version:

| Situation | Detected by | Reported as |
|-----------|-------------|-------------|
| Target content differs from the store copy | hash ≠ lockfile hash | `modified` |
| Repo version > installed version | manifest vs lockfile | `stale` |
| Target is no longer a symlink into the store | `lstat` check | `drifted` |
| Store version directory missing | path check | `broken` |
| `requires` config not installed | lockfile check | `unmet` |
| Config `platform` ≠ this host | manifest vs `uname` | `inapplicable` |
| Installed and in sync | — | `ok` |

Exits 0 by default. `--exit-code` exits non-zero when anything is pending, which
makes it usable in a shell prompt or a script. `dot diff <config>` shows the
actual change.

### `dot doctor` — environment health

Checks the machinery, not the configs:

- `git`, `jq`, `curl` present and usable
- repo clone exists, is a git repo, on a branch, not mid-rebase
- `~/.local/bin` is on `PATH`
- store and state directories exist and are writable
- lockfile parses, and every entry points at a real store directory
- every `manifest` in the repo parses and carries a valid semver
- the clone is not behind its upstream

Exits non-zero on any failure. `--fix` repairs what it safely can (missing
directories, dangling links, stale lockfile rows).

If friction is wanted later, `dot apply --lock` adds `chmod 444` (plus
`chflags uchg` on macOS), with `dot edit` / `update` / `rollback` unlocking first.

---

## 10. Install modes

**symlink (default).** Stage repo files into the store, then symlink targets at
the store copy. Enables update/rollback; zero drift.

**copy / ephemeral.** Copy repo files directly to targets; no store, no symlinks.
Used only with `--ephemeral`, which then purges the tooling (§13).

Algorithm (both modes):

1. Resolve requested configs, expand `requires`, drop `platform` mismatches.
2. Stage each config's `files/` into the store (or a temp dir).
3. Back up any existing target as `<target>.bak.<timestamp>`.
4. Link (or copy) each `file` mapping into place.
5. Run `post_apply`, if declared.
6. Write the lockfile entry.

Every step is idempotent; re-running is safe.

---

## 11. CLI surface

Verbs match `chezmoi` where an equivalent exists.

| Command | Does | chezmoi |
|---------|------|---------|
| `dot init [--profile P] [--repo URL] [--ref R] [--ephemeral]` | Clone repo, then apply | `init` |
| `dot apply [<config>…] [--profile P] [--dry-run] [--lock]` | Install/reinstall | `apply` |
| `dot forget <config>…` | Remove symlinks + lockfile entries (store kept) | `forget` |
| `dot update [<config>…] [--no-pull] [--dry-run]` | `git pull --rebase --autostash`, then apply newer | `update` |
| `dot rollback <config> [version]` | Re-point symlinks at an older store version | — |
| `dot purge [--yes]` | Delete repo, store, lockfile, and the CLI | — |
| `dot add <path>` | Adopt a file: copy into repo, replace target with a link | `add` |
| `dot edit <config>` | Open the repo file in `$EDITOR` | `edit` |
| `dot diff <config>` | Repo vs installed | `diff` |
| `dot status [--exit-code] [--json]` | What `apply` would change (content drift) | `status` |
| `dot doctor [--fix]` | Environment + tooling health; `--fix` repairs what it can | `doctor` |
| `dot cd` | Shell into the repo clone | `cd` |
| `dot list [--installed\|--available] [--category C] [--json]` | Discover configs | `managed` |
| `dot info <config>` | Files, targets, requires, version, state | — |
| `dot profiles` | List profiles and their configs | — |
| `dot bump <config> major\|minor\|patch` | Bump version, commit | — |

```
$ dot status
config     category      installed  available  state
ghostty    terminal      1.0.0      1.0.0      ok
zsh        shell         1.4.1      1.5.0      stale
starship   prompt        1.0.0      1.0.0      modified
herdr      multiplexer   —          0.9.0      not installed

$ dot update
→ git pull --rebase --autostash (repo)
→ zsh 1.4.1 → 1.5.0   store: …/store/zsh/1.5.0   target: ~/.zshrc   ok
✓ 1 updated, 0 failed
```

**`dot add` uses adopt-and-replace** (chezmoi semantics): the file is copied into
`configs/<name>/files/`, a `manifest` is created or appended (patch bump), and
the target is replaced with a symlink into the store. The original is kept as
`<target>.bak.<timestamp>`.

---

## 12. Bootstrap & curl install

`bootstrap.sh` is the single entrypoint: it downloads `dot`, puts it on `PATH`,
and forwards all arguments to it.

```bash
# install the CLI only, then inspect
sh -c "$(curl -fsSL https://raw.githubusercontent.com/chintak/dotfiles/master/bootstrap.sh)" -- --help

# whole machine in one command
sh -c "$(curl -fsSL https://raw.githubusercontent.com/chintak/dotfiles/master/bootstrap.sh)" \
  -- init --profile mac

# minimal server
sh -c "$(curl -fsSL https://raw.githubusercontent.com/chintak/dotfiles/master/bootstrap.sh)" \
  -- init --profile server

# throwaway VM: install, then purge all tooling
sh -c "$(curl -fsSL https://raw.githubusercontent.com/chintak/dotfiles/master/bootstrap.sh)" \
  -- init --profile server --ephemeral
```

Contract:

1. Requires only `bash`, `curl`, `git`, `jq`.
2. Installs `dot` to `~/.local/bin/dot` (`DOT_BIN_DIR` to override).
3. Warns if that directory is not on `PATH`.
4. `exec dot "$@"`.
5. Overrides: `DOT_REPO_URL`, `DOT_REF` (default `master`), `DOT_BIN_DIR`,
   `DOT_REPO`, `DOT_STORE`, `DOT_STATE`.

Pinning for reproducibility: `--ref v1.0.0` or `--ref <sha>`.

---

## 13. Ephemeral / VM mode

Goal: **configure the machine, then leave nothing behind but the config files.**
For VM images, CI runners, and one-shot containers where updates are not a
concern.

`dot init --profile server --ephemeral`:

1. Shallow-clone the repo to a temp dir.
2. Apply configs in **copy** mode (plain files at targets).
3. Optionally write `~/.config/dot/installed.json` for reference
   (`--no-manifest` to skip).
4. **Purge**: delete the clone, the store, `~/.local/bin/dot`, and
   `~/.local/share/dot` / `~/.local/state/dot`.

Result: a lean image with real config files and zero tooling. No future update
path — by design.

```
$ dot init --profile server --ephemeral
→ resolving profile 'server' (6 configs)
→ zsh 1.4.1        ~/.zshrc                     copied
→ starship 1.0.0   ~/.config/starship.toml      copied
→ herdr 0.9.0      ~/.config/herdr/config.toml  copied
→ tmux 1.0.0       ~/.config/tmux/tmux.conf     copied
→ git 1.0.0        ~/.gitconfig                 copied
→ uv-tools 1.0.0   post_apply: uv tool install  ok
→ purging repo, store, and CLI
✓ done (ephemeral) — configs installed, no tooling left behind
```

Safety: refuse to purge unless `--ephemeral` was passed **and** every install
succeeded. Print the purge list and require `--yes` when on a TTY.

---

## 14. Profiles & composability

Three primitives, then stop.

1. **Profiles** — `profiles/<name>.conf`, one config name per line. The answer to
   "don't install everything everywhere."

   ```
   # profiles/mac.conf
   zsh
   starship
   ghostty
   herdr
   zellij
   git
   brewfile
   uv-tools
   skills

   # profiles/server.conf
   zsh
   starship
   herdr
   tmux
   git
   uv-tools
   ```

2. **`requires`** — hard dependencies between configs (`herdr` requires `zsh`,
   because its config drives zsh hooks).

3. **`parts/`** — *deferred.* When added: a config folder containing `parts/*`
   gets them concatenated in lexical order into one installed file
   (`10-path`, `20-history`, `30-fzf`, …).

Explicitly **not** built: templating, per-file variables, host conditionals,
nested fragments. Those are where dotfile managers turn into programming
languages.

**No `ios` profile.** The phone (Termius) doesn't run `dot` — it SSHes into a
host that already has one of the profiles above. The mobile *prompt* is selected
at runtime by `zshrc` from `$SSH_CONNECTION`, not by profile.

---

## 15. Semver convention for configs

Without a convention, semver becomes noise.

| Bump | When |
|------|------|
| **major** | Breaking: target path moves, an option is renamed/removed, a newer tool version is required |
| **minor** | Backward-compatible: new option, new binding, new file in the package |
| **patch** | Comments, formatting, typo |

`dot bump <config> <level>` edits `manifest`, commits with a conventional
message, and prints the `dot update` to run.

---

## 16. Packages

Two package configs, split by platform — this is why `brewfile` does **not**
belong in the `server` profile.

| Config | Platform | Installs | Mechanism |
|--------|----------|----------|-----------|
| `brewfile` | **mac only** | ~30 Homebrew formulae **plus two casks** — Ghostty and the JetBrains Mono Nerd Font | `file = Brewfile\|~/.config/dot/Brewfile`, `post_apply = brew bundle --file ~/.config/dot/Brewfile` |
| `uv-tools` | any (needs `uv`) | Python CLIs: `ruff`, `pytest`, `nvitop`, `huggingface_hub` | `file = tools.txt\|~/.config/dot/uv-tools.txt`, `post_apply = xargs -a ~/.config/dot/uv-tools.txt uv tool install` |

`brewfile` is mac-only because **casks don't exist on Linux** and a headless GPU
box has no use for a terminal emulator or a font. On a server it would be slow,
partly broken, and unwanted. `uv-tools` is platform-agnostic and safe to include
in both profiles.

Package installation is deliberately an *action*, not a file — which is exactly
what `post_apply` (§7) exists for.

---

## 17. Migration plan

Phased; each phase is independently useful and reversible.

**Phase 0 — spec.** Agree on D1–D10.

**Phase 1 — restructure.** `git mv` configs into flat `configs/<tool>/files/`;
add `manifest` + `README.md` per config and a `configs/README.md` index. The old
`install.sh` still installs them, so nothing breaks.

**Phase 2 — `dot` MVP.** `list`, `info`, `apply`, `forget`, `status`, `diff`,
`doctor` in symlink mode. Store + JSON lockfile. `install.sh` becomes a thin shim
that calls `dot apply --profile mac`.

**Phase 3 — lifecycle.** `update`, `rollback`, `edit`, `add`, `bump`, `cd`.

**Phase 4 — bootstrap.** `bootstrap.sh`, the curl one-liner, `dot init`.

**Phase 5 — ephemeral.** `--ephemeral`, copy mode, `dot purge`.

**Phase 6 — docs.** Rewrite the root `README.md` around the lifecycle; keep the
per-tool blurbs.

**Phase 7 (optional) — `--lock`** (444 / `uchg`) and **`parts/`**.

Safety: today's symlinks-to-repo and their `.bak` files stay until `dot doctor`
passes on the new layout.

---

## 18. Resolved questions

| # | Question | Decision |
|---|----------|----------|
| 1 | `dot add` defaults | Prompt for `category` and `description`; folder name is the `description` default |
| 2 | `post_apply` re-run rule | Runs when the config's `applyHash` changes (version + files + `post_apply`); `--force-post` overrides |
| 3 | Store pruning | Keep all versions in v1; a `dot gc` (keep last N) is deferred |
| 4 | `status` vs `doctor` | Kept separate, chezmoi-style: `status` = content drift, `doctor` = environment health. `status --exit-code` for prompts |
| 5 | Spec copies | Repo copy is canonical; the scratchpad copy is a frozen snapshot |

## 19. Out of scope / future

- `parts/` composition (§14).
- `--lock` immutability (§9).
- Secrets management — stays in `localenvs/*.local` and `~/.env`, git-ignored.
- `dot sync` to push local edits back into the repo (today: `dot edit` →
  commit → `dot bump` → `dot update`).
- Multi-repo / third-party config sources.
