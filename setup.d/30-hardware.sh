#!/bin/bash
# Machine-specific fixes. Empty until you know what this machine needs.
#
# How to fill it in:
#   1. Install, then look for what is broken — suspend, wifi, brightness,
#      audio, fn-keys, touchpad, camera.
#   2. Check whether Omarchy already solved it: the omarchy checkout has
#      install/hardware/ with fixes for Framework, ThinkPad, XPS, ASUS ROG,
#      Surface, Tuxedo, and a pile of Intel and Broadcom issues.
#   3. Read the fix, understand it, and add it here as an idempotent block.
#      Do not port their detection framework — you have one machine.
set -euo pipefail

# Example shape:
#
# if [[ $(cat /sys/class/dmi/id/product_name) == "Framework"* ]]; then
#   install -Dm0644 "$AERIS_ROOT/etc/modprobe.d/framework.conf" \
#     /etc/modprobe.d/framework.conf
# fi

echo "no hardware fixes configured yet"
