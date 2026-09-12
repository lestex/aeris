#!/bin/bash
# Snapper + per-transaction snapshots + bootable snapshot entries.
#
# This is the load-bearing step. Do not move past it until you have
# actually rolled back once — see the "Verify" section of the README.
set -euo pipefail

dnf -y install --setopt=install_weak_deps=False \
  snapper libdnf5-plugin-actions btrfs-progs

# Create the root config only if it is absent.
if ! snapper -c root list &>/dev/null; then
  snapper -c root create-config /
fi

# Transaction-driven, not clock-driven: timeline snapshots bury the
# transaction boundaries you actually want to roll back to.
snapper -c root set-config \
  TIMELINE_CREATE=no \
  NUMBER_CLEANUP=yes \
  NUMBER_MIN_AGE=0 \
  NUMBER_LIMIT=10 \
  NUMBER_LIMIT_IMPORTANT=10

install -Dm0644 "$AERIS_ROOT/etc/dnf/libdnf5-plugins/actions.d/snapper.actions" \
  /etc/dnf/libdnf5-plugins/actions.d/snapper.actions

dnf -y install grub-btrfs

systemctl enable --now snapper-cleanup.timer
systemctl enable --now grub-btrfsd
