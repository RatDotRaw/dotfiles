#!/bin/bash

source ./helpers.sh

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$DOTFILES_DIR/.backup_$(date +%s)"
mkdir -p "$BACKUP_DIR"

link_recursive() {
    local src_root="$1"
    local dest_root="$2"

    find "$src_root" -type f | while read -r src; do
        # Get relative path from root
        rel_path="${src#$src_root/}"
        dest="$dest_root/$rel_path"

        # Ensure destination directory exists
        mkdir -p "$(dirname "$dest")"

        # Backup if file exists and is not a symlink
        if [ -e "$dest" ] && [ ! -L "$dest" ]; then
            echo "⚠️ Backing up $dest to $BACKUP_DIR/$rel_path"
            mkdir -p "$BACKUP_DIR/$(dirname "$rel_path")"
            mv "$dest" "$BACKUP_DIR/$rel_path"
        fi

        # Link (or overwrite symlink)
        ln -sf "$src" "$dest"
        echo "✅ Linked $src → $dest"
    done
}

echo "Linking home/ to \$HOME/"
REAL_HOME="$(eval echo ~${SUDO_USER:-$USER})"
link_recursive "$DOTFILES_DIR/home" "$REAL_HOME"

echo "Linking etc/ to /etc/"
link_recursive "$DOTFILES_DIR/etc" "/etc"

echo "Done. Backup (if any): $BACKUP_DIR"
