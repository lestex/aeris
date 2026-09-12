#!/bin/bash
# The name, in the two places it shows up.
#
# ID stays "fedora" on purpose: dnf, COPRs and $releasever resolution all key
# off it, so renaming it breaks package resolution. Only the display strings
# change — the same split Omarchy uses for TARGET_OS_NAME.
set -euo pipefail

NAME="AerisOS"
release=$(rpm -E %fedora)

# /etc/os-release is a symlink to /usr/lib/os-release on Fedora. A real file
# at /etc wins per the os-release spec, and survives package upgrades.
sed -E \
  -e "s|^NAME=.*|NAME=\"$NAME\"|" \
  -e "s|^PRETTY_NAME=.*|PRETTY_NAME=\"$NAME $release\"|" \
  /usr/lib/os-release > /etc/os-release.new
mv -f /etc/os-release.new /etc/os-release
chmod 0644 /etc/os-release

# GRUB menu title
if ! grep -qx "GRUB_DISTRIBUTOR=\"$NAME\"" /etc/default/grub; then
  sed -i -E "/^GRUB_DISTRIBUTOR=/d" /etc/default/grub
  echo "GRUB_DISTRIBUTOR=\"$NAME\"" >> /etc/default/grub
  grub2-mkconfig -o /boot/grub2/grub.cfg
fi
