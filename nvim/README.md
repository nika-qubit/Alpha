# Neovim (LazyVim + Catppuccin) Setup

Portable LazyVim configuration template (`Catppuccin`, `Neo-tree`, `Telescope`, `mini.diff`, Markdown/SQL highlighting).

## Deploy / Sync

```bash
bash ~/workspace/Alpha/nvim/setup_nvim.sh --sync-plugins
```

- Backs up `~/.config/nvim` to `~/.config/nvim.bak.<timestamp>` whenever files actually differ (pass `--no-backup` to skip).
- Syncs `init.lua`, `lua/`, and `after/` cleanly via `rsync --delete` (removing stale config files) while preserving machine-local `lazy-lock.json` and `lazyvim.json`.
- Enforces `GIT_DEFAULT_REF_FORMAT=files` (and auto-migrates any `reftable` plugin clones) so `lazy.nvim` works cleanly on corporate hosts (gMac / Cloudtop) as well as personal Macs and Linux.
- `--sync-plugins` runs `nvim --headless "+Lazy! sync" +qa` so new plugins install immediately.
