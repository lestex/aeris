#!/bin/bash
# Shared Wayland stack plus one compositor. Started from a TTY — no display
# manager, deliberately: one less moving part while the base settles.
#
#   AERIS_COMPOSITOR=hyprland  (default) from a COPR, both arches
#   AERIS_COMPOSITOR=sway      from Fedora proper, if you want no COPR at all
set -euo pipefail

compositor=${AERIS_COMPOSITOR:-hyprland}
list="$AERIS_ROOT/packages/compositor-$compositor.txt"
[[ -f $list ]] || { echo "no package list for compositor '$compositor'" >&2; exit 1; }

mapfile -t pkgs < <(
  grep -hvE '^\s*(#|$)' \
    "$AERIS_ROOT/packages/base.txt" \
    "$AERIS_ROOT/packages/desktop.txt" \
    "$list" | sort -u
)

echo "  compositor: $compositor"
dnf -y install --setopt=install_weak_deps=False "${pkgs[@]}"

systemctl --global enable pipewire.socket wireplumber.service
