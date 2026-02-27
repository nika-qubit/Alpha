#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Override via env if needed
WORKSPACE_DIR="${WORKSPACE_DIR:-/Users/ningk/workspace}"
PLUGINS_DIR="${PLUGINS_DIR:-$WORKSPACE_DIR/tmux-plugins}"
RESURRECT_DIR="${RESURRECT_DIR:-$WORKSPACE_DIR/tmux-resurrect-data}"
TARGET_TMUX_CONF="${TARGET_TMUX_CONF:-$HOME/.tmux.conf}"
TEMPLATE_CONF="$SCRIPT_DIR/tmux.conf"

clone_or_update() {
  local repo_url="$1"
  local dest="$2"

  if [ -d "$dest/.git" ]; then
    echo "Updating: $dest"
    git -C "$dest" pull --ff-only
  else
    echo "Cloning: $repo_url -> $dest"
    git clone "$repo_url" "$dest"
  fi
}

mkdir -p "$PLUGINS_DIR" "$RESURRECT_DIR"

clone_or_update "https://github.com/tmux-plugins/tmux-resurrect" "$PLUGINS_DIR/tmux-resurrect"
clone_or_update "https://github.com/tmux-plugins/tmux-continuum" "$PLUGINS_DIR/tmux-continuum"
clone_or_update "https://github.com/tmux-plugins/tpm" "$PLUGINS_DIR/tpm"

if [ ! -f "$TEMPLATE_CONF" ]; then
  echo "ERROR: template not found: $TEMPLATE_CONF" >&2
  exit 1
fi

if [ -f "$TARGET_TMUX_CONF" ]; then
  backup="$TARGET_TMUX_CONF.bak.$(date +%Y%m%d_%H%M%S)"
  cp "$TARGET_TMUX_CONF" "$backup"
  echo "Backed up existing config: $backup"
fi

# Fill placeholders in template and install to ~/.tmux.conf
sed \
  -e "s|__RESURRECT_DIR__|$RESURRECT_DIR|g" \
  -e "s|__PLUGINS_DIR__|$PLUGINS_DIR|g" \
  "$TEMPLATE_CONF" > "$TARGET_TMUX_CONF"

echo "Installed tmux config: $TARGET_TMUX_CONF"
echo "Resurrect data dir: $RESURRECT_DIR"
echo

echo "Next steps:"
echo "1) Start tmux: tmux"
echo "2) Reload config in tmux: tmux source-file $TARGET_TMUX_CONF"
echo "3) Manual save: Ctrl-b then Ctrl-s"
echo "4) Manual restore: Ctrl-b then Ctrl-r"
