#!/bin/sh
# Host-side flash. Usage: flash.sh <image> [block-device]
# FLASH_METHOD=uuu flashes over USB (see flash-uuu.sh, no device needed);
# default is dd to an SD card block device.
# Set ASSUME_YES=1 for unattended use (e.g. by the reproducer).
# Powers the board off first (host/power.sh) when POWER_BACKEND is set.
set -eu
here=$(dirname "$0")
if [ "${FLASH_METHOD:-dd}" = uuu ]; then exec "$here/flash-uuu.sh" "${1:?image}"; fi
img=${1:?image}; dev=${2:?device}
[ -f "$img" ] || { echo "no image: $img" >&2; exit 1; }
[ -b "$dev" ] || { echo "not a block device: $dev" >&2; exit 1; }
if [ "${ASSUME_YES:-0}" != 1 ]; then
    printf 'Overwrite %s with %s? [y/N] ' "$dev" "$img"
    read -r a; [ "$a" = y ] || exit 1
fi
[ -z "${POWER_BACKEND:-}" ] || "$here/power.sh" off
dd if="$img" of="$dev" bs=4M conv=fsync status=progress
sync
