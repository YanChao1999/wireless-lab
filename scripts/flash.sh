#!/bin/sh
# Usage: flash.sh <image> <block-device>
set -eu
img=${1:?image}; dev=${2:?device}
[ -f "$img" ] || { echo "no image: $img" >&2; exit 1; }
[ -b "$dev" ] || { echo "not a block device: $dev" >&2; exit 1; }
printf 'Overwrite %s with %s? [y/N] ' "$dev" "$img"
read -r a; [ "$a" = y ] || exit 1
dd if="$img" of="$dev" bs=4M conv=fsync status=progress
sync
