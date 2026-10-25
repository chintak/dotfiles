# pnpm shell init. `pnpm setup` appends this to ~/.zshrc by copy-and-append,
# which replaces the dot symlink with a real file (dot status: drifted) — so
# it lives here instead and is delivered to mac-personal by the manifest
# variant. $HOME, not the absolute path pnpm wrote, so a rename cannot break it.
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  ":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
