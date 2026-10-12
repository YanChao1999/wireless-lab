#!/bin/sh
# Record the upstream commit IDs this build tracks. Usage: record-commits.sh <file>
# Resolved just before the build with git ls-remote, so the build may be a few
# commits newer if upstream moves meanwhile.
set -eu
out=${1:?manifest}
root=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$(dirname "$out")"
{
    echo "wireless-lab $(git -C "$root" rev-parse HEAD)"
    echo "date $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    while read -r name url ref; do
        id=$(git ls-remote "$url" "refs/heads/$ref" | cut -f1)
        echo "$name $url $ref $id"
    done <<LIST
linux https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git master
iw https://git.kernel.org/pub/scm/linux/kernel/git/jberg/iw.git master
hostap https://w1.fi/hostap.git main
bluez https://git.kernel.org/pub/scm/bluetooth/bluez.git master
wireless-regdb https://git.kernel.org/pub/scm/linux/kernel/git/wens/wireless-regdb.git master
linux-firmware https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git main
LIST
} > "$out"
