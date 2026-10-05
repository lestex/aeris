# AerisOS — unattended Fedora install
#
# Edit before first use:
#   - the disk name in ignoredisk/clearpart/part (lsblk on the target)
#   - timezone, keyboard, username
#   - the LUKS passphrase and the user password hash
#
# Password hash:  openssl passwd -6
# Boot it via:    mkksiso, or a FAT32 stick labelled OEMDRV holding this as ks.cfg

text
lang en_US.UTF-8
keyboard us
timezone America/New_York --utc

rootpw --lock
user --name=lestex --groups=wheel --iscrypted --password=REPLACE_WITH_OPENSSL_PASSWD_6

# --- disk -----------------------------------------------------------------
ignoredisk --only-use=nvme0n1
clearpart --all --initlabel --drives=nvme0n1

part /boot/efi --fstype=efi   --size=1024 --ondisk=nvme0n1
part /boot     --fstype=ext4  --size=1024 --ondisk=nvme0n1
# One line: kickstart has no backslash continuations.
part btrfs.01  --fstype=btrfs --grow       --ondisk=nvme0n1 --encrypted --luks-version=luks2 --passphrase=REPLACE_ME

btrfs none --label=aeris btrfs.01
btrfs /           --subvol --name=root      LABEL=aeris
btrfs /home       --subvol --name=home      LABEL=aeris
btrfs /.snapshots --subvol --name=snapshots LABEL=aeris
btrfs /var/log    --subvol --name=var_log   LABEL=aeris
btrfs /var/cache  --subvol --name=var_cache LABEL=aeris
# NOTE: /var/lib is deliberately NOT split out. The RPM database lives in
# /var/lib/rpm and must sit inside the snapshotted root subvolume, or a
# rollback desyncs the package database from the filesystem.

# --- system ---------------------------------------------------------------
bootloader --append="quiet"
selinux --enforcing
firewall --enabled
services --enabled=NetworkManager
reboot

# --- packages -------------------------------------------------------------
# --exclude-weakdeps is the minimalism lever: Fedora pulls a great deal
# through Recommends:, and this turns all of it off.
%packages --exclude-weakdeps
@core

# pam_systemd.so. systemd only *recommends* systemd-pam, so --exclude-weakdeps
# drops it — and then no login registers a logind session, XDG_RUNTIME_DIR is
# never set, and nothing graphical can acquire DRM master. It fails silently
# because Fedora's PAM stack says "-session optional pam_systemd.so", where the
# leading - means skip quietly when the module is missing.
systemd-pam

btrfs-progs
snapper
libdnf5-plugin-actions
git-core
vim-enhanced
-subscription-manager
%end

# --- bootstrap only; the real work is ./setup -----------------------------
%post --log=/root/ks-post.log
git clone https://github.com/lestex/aerisos /root/aerisos || true
%end
