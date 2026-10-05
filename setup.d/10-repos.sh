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

dnf -y makecache
