#!/bin/bash
# Install the theme command and its data, then apply a theme so the generated
# files exist.
#
# This has to run before a Hyprland session starts: dotfiles/hypr/hyprland.conf
# sources ~/.local/state/aerisos/current/hyprland.conf, and Hyprland treats a
# missing source as fatal.
#
# themes/ and themed/ are copied rather than symlinked, so the command works
# with no checkout present. While iterating on templates, point at the repo
# instead:  AERIS_ROOT=~/aerisos aeris-theme set <name>
set -euo pipefail

share=/usr/local/share/aerisos

install -Dm0755 "$AERIS_ROOT/bin/aeris-theme" /usr/local/bin/aeris-theme
install -Dm0755 "$AERIS_ROOT/bin/aeris-menu"  /usr/local/bin/aeris-menu
install -Dm0755 "$AERIS_ROOT/bin/aeris-background" /usr/local/bin/aeris-background

rm -rf "$share"
install -d "$share"
cp -r "$AERIS_ROOT/themes" "$AERIS_ROOT/themed" "$AERIS_ROOT/backgrounds" "$share/"

count=$(find "$share/themes" -name colors.toml | wc -l | tr -d ' ')
echo "  installed aeris-theme with $count palettes"

# Render as the user; everything lands under their ~/.local/state. No
# AERIS_ROOT here on purpose, so this exercises the installed lookup path.
theme=${AERIS_THEME:-tokyo-night}
sudo -u "$TARGET_USER" -H /usr/local/bin/aeris-theme set "$theme"
