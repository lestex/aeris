#!/bin/bash
# Machine-specific fixes. Mostly empty until you know what this machine needs.
#
# How to fill it in:
#   1. Install, then look for what is broken — suspend, wifi, brightness,
#      audio, fn-keys, touchpad, camera.
#   2. Check whether Omarchy already solved it: its install/hardware/ tree has
#      fixes for Framework, ThinkPad, XPS, ASUS ROG, Surface, Tuxedo, and a
#      pile of Intel and Broadcom issues.
#   3. Read the fix, understand it, add it here as an idempotent block.
#      Do not port their detection framework — you have one machine.
set -euo pipefail

arch=$(uname -m)

# CPU microcode. x86_64 only, and @core with weak deps off does not pull it.
if [[ $arch == "x86_64" ]]; then
  dnf -y install --setopt=install_weak_deps=False microcode_ctl
fi

# Example shape for a machine-specific fix:
#
# if [[ $(</sys/class/dmi/id/product_name) == "Framework"* ]]; then
#   install -Dm0644 "$AERIS_ROOT/etc/modprobe.d/framework.conf" \
#     /etc/modprobe.d/framework.conf
# fi

echo "  no machine-specific fixes configured yet"
