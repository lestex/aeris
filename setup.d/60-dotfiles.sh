#!/bin/bash
# Symlink dotfiles/ into the target user's ~/.config, backing up anything
# real that is already there. Symlinks mean editing the repo edits the
# live config — no copy step, no drift.
set -euo pipefail

src="$AERIS_ROOT/dotfiles"
dest="$TARGET_HOME/.config"

[[ -d $src ]] || { echo "no dotfiles/ yet"; exit 0; }

install -d -o "$TARGET_USER" -g "$TARGET_USER" "$dest"

shopt -s nullglob
for path in "$src"/*; do
  name=${path##*/}
  target="$dest/$name"

  if [[ -L $target ]]; then
    [[ $(readlink -f "$target") == "$(readlink -f "$path")" ]] && continue
    rm -f "$target"
  elif [[ -e $target ]]; then
    mv -- "$target" "$target.bak.$(date +%s)"
  fi

  ln -sfn -- "$path" "$target"
  chown -h "$TARGET_USER:$TARGET_USER" "$target"
  echo "  linked $name"
done
