# tmux Session Persistence Setup

This folder contains a reusable setup for tmux session persistence (save/restore across restarts).

## Files

- `setup_tmux_persistence.sh`: one-click setup script
- `tmux.conf`: template config used by the setup script

## What It Configures

- `tmux-resurrect` for manual save/restore
- `tmux-continuum` for periodic autosave and automatic restore
- Save directory: `~/.tmux/resurrect`
- Plugin directory: `~/.tmux/plugins`

## Quick Start

```bash
bash ~/workspace/Alpha/tmux/setup_tmux_persistence.sh
```

## Optional Overrides

You can override default paths using environment variables:

```bash
TMUX_HOME="$HOME/.tmux" \
PLUGINS_DIR="$HOME/.tmux/plugins" \
RESURRECT_DIR="$HOME/.tmux/resurrect" \
TARGET_TMUX_CONF="$HOME/.tmux.conf" \
bash ~/workspace/Alpha/tmux/setup_tmux_persistence.sh
```

## Apply / Verify

1. Start tmux:

```bash
tmux
```

2. Reload config inside tmux:

```bash
tmux source-file ~/.tmux.conf
```

3. Manual save (inside tmux):

- `Ctrl-b` then `Ctrl-s`

4. Manual restore (inside tmux):

- `Ctrl-b` then `Ctrl-r`

## Verify Saved Snapshot

```bash
ls -lah ~/.tmux/resurrect
```

Expected artifacts include:

- `last` (symlink)
- `tmux_resurrect_*.txt`
- `pane_contents.tar.gz`

## Notes

- The setup script backs up existing `~/.tmux.conf` to `~/.tmux.conf.bak.<timestamp>` if present.
- Autosave interval is set to 15 minutes.
