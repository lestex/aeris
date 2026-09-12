#!/bin/bash
# Hyprland + Quickshell. Started from a TTY with `Hyprland` — no display
# manager, deliberately: one less moving part while the base settles.
set -euo pipefail

mapfile -t pkgs < <(
  grep -hvE '^\s*(#|$)' \
    "$AERIS_ROOT/packages/base.txt" \
    "$AERIS_ROOT/packages/desktop.txt" | sort -u
)

dnf -y install --setopt=install_weak_deps=False "${pkgs[@]}"

systemctl --global enable pipewire.socket wireplumber.service
