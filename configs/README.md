# configs

One folder per config. Each is a **package**:

```
configs/<name>/
├── README.md   # why it's configured this way
├── manifest    # version, targets, optional post_apply
└── files/      # what gets installed, paths relative to here
```

## Why flat

The atomic unit of `dot` is a config, so the directory mirrors that. A
`configs/shell/starship/` hierarchy would imply nesting the install model
doesn't have, and would make `requires`/profiles depend on a folder path.
There are no categories — `dot list` is one flat, alphabetical table.

## The manifest

```
version     = 1.0.0                 # semver — see specs/dot-cli.md §15
description = one line, shown by `dot list`
platform    = mac | linux | any     # optional; skipped when mismatched
requires    = other,configs         # optional; applied first
file        = src|target            # repeatable; src is relative to files/
post_apply  = one command           # optional; runs when applyHash changes
```

## Adding a config

```bash
mkdir -p configs/<name>/files
# write configs/<name>/manifest, README.md, and files/…
dot list                       # it should appear
dot apply <name> --dry-run
dot apply <name>
dot bump <name> minor
```

## Profiles

`profiles/<name>.conf` is a plain list of config names. `dot apply --profile mac`
installs them in order. See `profiles/`.
