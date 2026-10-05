#!/bin/bash
# COPRs. Everything enabled here sits outside Fedora's own release testing,
# so each one is a dependency on someone's personal build infrastructure.
#
# Arch matters: the dev VM is aarch64 (native hvf on Apple Silicon) while the
# target machine is x86_64, and grub-btrfs is built for x86_64 only. Enabling
# a COPR never fails on a missing arch — the install does, later — so gate it
# here, where the reason is visible.
set -euo pipefail

arch=$(uname -m)

# Snapshot entries in the GRUB menu.
if [[ $arch == "x86_64" ]]; then
  dnf -y copr enable kylegospo/grub-btrfs
else
  echo "  skipping grub-btrfs COPR: no $arch build available"
fi

# Hyprland is not in Fedora's repos at all, so it needs a COPR. The default
# is what ML4W ships; see packages/compositor-hyprland.txt for alternates and
# how to check a COPR's release/arch coverage before trusting it.
if [[ ${AERIS_COMPOSITOR:-hyprland} == "hyprland" ]]; then
  dnf -y copr enable "${AERIS_HYPRLAND_COPR:-lionheartp/Hyprland}"
fi

# ghostty is not in Fedora either, and unlike Hyprland no COPR has clear
# standing — several carry a *failed* latest build. Opt in by naming one:
#   AERIS_GHOSTTY_COPR=scottames/ghostty sudo -E ./setup 10 40
# scottames/ghostty is the one to start from: 1.3.1-4, a successful release
# build, aarch64 and x86_64 on f44.
if [[ -n ${AERIS_GHOSTTY_COPR:-} ]]; then
  dnf -y copr enable "$AERIS_GHOSTTY_COPR"
fi

# quickshell needs no COPR of its own: it is in Fedora f44 updates, and the
# hyprland COPR above also carries it. Re-enable only if your release lacks it:
#   dnf -y copr enable errornointernet/quickshell

dnf -y makecache
