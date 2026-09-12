#!/bin/bash
# COPRs. Both are outside Fedora's own release testing — if either lacks a
# build for your release, that is worth knowing before you depend on it.
set -euo pipefail

# Snapshot entries in the GRUB menu.
dnf -y copr enable kylegospo/grub-btrfs

# Quickshell. Check whether your release carries it already:
#   dnf info quickshell
# If it is in Fedora proper, drop this line.
dnf -y copr enable errornointernet/quickshell

dnf -y makecache
