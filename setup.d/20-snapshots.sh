#!/bin/bash
# Snapper + per-transaction snapshots + bootable snapshot entries.
#
# This is the load-bearing step. Do not consider it done until you have
# actually rolled back once — see "Verify the rollback" in the README.
#
# Everything except grub-btrfs is arch-independent, so the aarch64 VM still
# exercises snapper and the dnf hook. The GRUB submenu is x86_64-only and
# must be verified on the real machine.
set -euo pipefail

dnf -y install --setopt=install_weak_deps=False \
  snapper libdnf5-plugin-actions btrfs-progs

# `snapper create-config` refuses to run when /.snapshots already exists, and
# the kickstart mounts a dedicated subvolume there. So stand our mount aside,
# let snapper create its own, then swap ours back in.
#
# The separate subvolume is worth this dance: it lives outside the root
# subvolume, so `snapper rollback` — which makes a *different* subvolume the
# default root — leaves the snapshot history untouched. A /.snapshots nested
# inside root would travel with whichever root you rolled onto.
if [[ ! -f /etc/snapper/configs/root ]]; then
  remount=0
  if mountpoint -q /.snapshots; then
    umount /.snapshots
    remount=1
  fi
  rmdir /.snapshots 2>/dev/null || true

  snapper -c root create-config /

  # snapper just made /.snapshots its own subvolume; drop it and restore the
  # fstab-managed one.
  if btrfs subvolume show /.snapshots &>/dev/null; then
    btrfs subvolume delete /.snapshots
  fi
  mkdir -p /.snapshots
  (( remount )) && mount /.snapshots
  chmod 0750 /.snapshots
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

systemctl enable --now snapper-cleanup.timer

# `snapper rollback` only understands the openSUSE layout; see the header of
# bin/aeris-rollback for why this layout needs its own tool.
install -Dm0755 "$AERIS_ROOT/bin/aeris-rollback" /usr/local/bin/aeris-rollback

# Snapshot entries in the boot menu — x86_64 only, see 10-repos.sh.
if [[ $(uname -m) == "x86_64" ]]; then
  dnf -y install grub-btrfs
  systemctl enable --now grub-btrfsd
else
  echo "  skipping grub-btrfs: no $(uname -m) build — boot-menu entries UNVERIFIED on this host"
fi

# Fail loudly rather than leaving a half-wired system that looks fine.
snapper -c root get-config >/dev/null
echo "  snapper root config present; /.snapshots $(mountpoint -q /.snapshots && echo mounted || echo 'NOT mounted')"
