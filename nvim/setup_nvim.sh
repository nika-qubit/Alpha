#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_NVIM_DIR="${TARGET_NVIM_DIR:-$HOME/.config/nvim}"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.config}"
LAZY_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
SYNC_PLUGINS=false
NO_BACKUP=false

for arg in "$@"; do
  case "$arg" in
    --sync-plugins)
      SYNC_PLUGINS=true
      ;;
    --no-backup)
      NO_BACKUP=true
      ;;
    -h|--help)
      echo "Usage: $(basename "$0") [--sync-plugins] [--no-backup]"
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

export GIT_DEFAULT_REF_FORMAT=files

if [ -L "$TARGET_NVIM_DIR" ]; then
  rm "$TARGET_NVIM_DIR"
elif [ -d "$TARGET_NVIM_DIR" ] && [ "$NO_BACKUP" = false ]; then
  dry_changes="$(rsync -ani --delete \
    --exclude='lazy-lock.json' \
    --exclude='lazyvim.json' \
    --exclude='.DS_Store' \
    --exclude='setup_nvim.sh' \
    --exclude='README.md' \
    "$SCRIPT_DIR/" "$TARGET_NVIM_DIR/" || true)"
  if [ -n "$dry_changes" ]; then
    backup="$BACKUP_ROOT/nvim.bak.$(date +%Y%m%d_%H%M%S)"
    cp -R "$TARGET_NVIM_DIR" "$backup"
    echo "Backed up existing Neovim config: $backup"
  fi
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

# Migrate any existing reftable plugin clones (e.g. from corporate git defaults)
# so lazy.nvim's .git/HEAD parser never hits `commit is nil`.
if [ -d "$LAZY_DIR" ] && command -v git >/dev/null 2>&1; then
  for repo in "$LAZY_DIR"/*; do
    if [ -f "$repo/.git/HEAD" ] && grep -q "refs/heads/\.invalid" "$repo/.git/HEAD" 2>/dev/null; then
      echo "Migrating reftable plugin repo to files format: $(basename "$repo")"
      git -C "$repo" refs migrate --ref-format=files
    fi
  done
fi

if [ "$SYNC_PLUGINS" = true ] && command -v nvim >/dev/null 2>&1; then
  echo "Syncing LazyVim plugins headlessly..."
  nvim --headless "+Lazy! sync" +qa
  echo "LazyVim plugins synced."
fi
