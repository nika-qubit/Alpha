# Neovim (LazyVim + Catppuccin) Setup

Portable LazyVim configuration template (`Catppuccin`, `Neo-tree`, `Telescope`, `mini.diff`, Markdown/SQL highlighting).

## Deploy / Sync

```bash
bash ~/workspace/Alpha/nvim/setup_nvim.sh --sync-plugins
```

- Backs up any existing `~/.config/nvim` to `~/.config/nvim.bak.<timestamp>`.
- Syncs `init.lua`, `lua/`, and `after/` cleanly via `rsync --delete` (removing stale config files) while preserving machine-local `lazy-lock.json` and `lazyvim.json`.
- `--sync-plugins` runs `nvim --headless "+Lazy! sync" +qa` so new plugins install immediately.
