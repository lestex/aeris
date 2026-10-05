#!/bin/bash
# COPRs. Both sit outside Fedora's own release testing.
#
# Arch matters here: the dev VM is aarch64 (native hvf on Apple Silicon)
# while the target machine is x86_64, and grub-btrfs is only built for
# x86_64. Enabling a COPR never fails on a missing arch — the install does,
# later — so gate it here where the reason is visible.
set -euo pipefail

arch=$(uname -m)

dnf -y copr enable errornointernet/quickshell   # aarch64 + x86_64

if [[ $arch == "x86_64" ]]; then
  dnf -y copr enable kylegospo/grub-btrfs
else
  echo "  skipping grub-btrfs COPR: no $arch build available"
fi

# Hyprland is not in Fedora's repos at all, so it needs a COPR — and the
# available ones are personal repos with uneven release/arch coverage. Opt in
# explicitly rather than having setup pick a stranger's repo for you.
if [[ ${AERIS_COMPOSITOR:-sway} == "hyprland" ]]; then
  if [[ -n ${AERIS_HYPRLAND_COPR:-} ]]; then
    dnf -y copr enable "$AERIS_HYPRLAND_COPR"
  else
    echo "  AERIS_COMPOSITOR=hyprland but AERIS_HYPRLAND_COPR is unset" >&2
    echo "  pick one and check its chroots first; see packages/compositor-hyprland.txt" >&2
    exit 1
  fi
fi

dnf -y makecache
