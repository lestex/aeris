#!/bin/bash
# Install the theme command and apply a theme, so the generated files exist.
#
# This has to run: dotfiles/hypr/hyprland.conf sources
# ~/.local/state/aerisos/current/hyprland.conf, and Hyprland treats a missing
# source as fatal. foot is more forgiving about a missing include, but the
# colours would simply be absent.
set -euo pipefail

install -Dm0755 "$AERIS_ROOT/bin/aeris-theme" /usr/local/bin/aeris-theme

# Render as the user: everything lands under their ~/.local/state.
theme=${AERIS_THEME:-tokyo-night}
sudo -u "$TARGET_USER" -H env "AERIS_ROOT=$AERIS_ROOT" \
  /usr/local/bin/aeris-theme set "$theme"
