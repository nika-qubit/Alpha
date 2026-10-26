#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_NVIM_DIR="${TARGET_NVIM_DIR:-$HOME/.config/nvim}"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.config}"
SYNC_PLUGINS=false

for arg in "$@"; do
  case "$arg" in
    --sync-plugins)
      SYNC_PLUGINS=true
      ;;
    -h|--help)
      echo "Usage: $(basename "$0") [--sync-plugins]"
      echo
      echo "Deploys Alpha/nvim template to ~/.config/nvim (preserving lazy-lock.json and lazyvim.json)."
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

if [ -L "$TARGET_NVIM_DIR" ]; then
  rm "$TARGET_NVIM_DIR"
elif [ -d "$TARGET_NVIM_DIR" ]; then
  backup="$BACKUP_ROOT/nvim.bak.$(date +%Y%m%d_%H%M%S)"
  cp -R "$TARGET_NVIM_DIR" "$backup"
  echo "Backed up existing Neovim config: $backup"
fi

mkdir -p "$TARGET_NVIM_DIR"

rsync -a --delete \
  --exclude='lazy-lock.json' \
  --exclude='lazyvim.json' \
  --exclude='.DS_Store' \
  --exclude='setup_nvim.sh' \
  --exclude='README.md' \
  "$SCRIPT_DIR/" "$TARGET_NVIM_DIR/"

echo "Synced Neovim config -> $TARGET_NVIM_DIR"

if [ "$SYNC_PLUGINS" = true ] && command -v nvim >/dev/null 2>&1; then
  echo "Syncing LazyVim plugins headlessly..."
  nvim --headless "+Lazy! sync" +qa
  echo "LazyVim plugins synced."
fi
