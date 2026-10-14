#!/bin/sh
# Flash over USB with NXP uuu (i.MX serial download mode); no SD card handling.
# Usage: flash-uuu.sh <image> [bootloader]
# Env: UUU_TARGET  uuu built-in script: emmc_all (default) or sd_all
#      UUU_BOOTLOADER  imx-boot/flash.bin (else 2nd arg, else <image dir>/imx-boot)
# The board must be in serial download mode (boot-mode switches/jumper) and
# connected via the USB OTG/download port. With a programmable power module the
# board is power-cycled first (host/power.sh) so it enumerates in download mode.
set -eu
here=$(dirname "$0")
img=${1:?image}
boot=${2:-${UUU_BOOTLOADER:-$(dirname "$img")/imx-boot}}
target=${UUU_TARGET:-emmc_all}
command -v uuu >/dev/null 2>&1 || { echo "uuu not found (https://github.com/nxp-imx/mfgtools)" >&2; exit 1; }
[ -f "$img" ] || { echo "no image: $img" >&2; exit 1; }
[ -f "$boot" ] || { echo "no bootloader: $boot (set UUU_BOOTLOADER)" >&2; exit 1; }
[ -z "${POWER_BACKEND:-}" ] || "$here/power.sh" cycle
uuu -b "$target" "$boot" "$img"
