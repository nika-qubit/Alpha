# tmux Session Persistence Setup

This folder contains a reusable setup for tmux session persistence (save/restore across restarts).

## Files

- `setup_tmux_persistence.sh`: one-click setup script
- `tmux.conf`: template config used by the setup script

## What It Configures

- `tmux-resurrect` for manual save/restore
- `tmux-continuum` for periodic autosave and automatic restore
- Save directory: `/Users/ningk/workspace/tmux-resurrect-data`
- Plugin directory: `/Users/ningk/workspace/tmux-plugins`

## Quick Start

```bash
bash /Users/ningk/workspace/Alpha/tmux/setup_tmux_persistence.sh
```

## Optional Overrides

You can override default paths using environment variables:

```bash
WORKSPACE_DIR=/Users/ningk/workspace \
PLUGINS_DIR=/Users/ningk/workspace/tmux-plugins \
RESURRECT_DIR=/Users/ningk/workspace/tmux-resurrect-data \
TARGET_TMUX_CONF=/Users/ningk/.tmux.conf \
bash /Users/ningk/workspace/Alpha/tmux/setup_tmux_persistence.sh
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
ls -lah /Users/ningk/workspace/tmux-resurrect-data
```

Expected artifacts include:

- `last` (symlink)
- `tmux_resurrect_*.txt`
- `pane_contents.tar.gz`

## Notes

- The setup script backs up existing `~/.tmux.conf` to `~/.tmux.conf.bak.<timestamp>` if present.
- Autosave interval is set to 15 minutes.
