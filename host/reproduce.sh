#!/bin/sh
# Reproducer driver (for humans or an AI agent): flash, power-cycle, boot,
# run the on-target tests over the serial console, and collect logs.
# Usage: reproduce.sh <image> <block-device|-> <serial-tty> [outdir]  (use - with FLASH_METHOD=uuu)
# Env: POWER_BACKEND etc. (see power.sh), BOOT_WAIT (s, default 60), BAUD (115200), TEST_TIMEOUT (s, 3600)
set -eu
here=$(dirname "$0")
img=${1:?image}; dev=${2:?device}; tty=${3:?serial tty}
out=${4:-logs/$(date +%Y%m%d-%H%M%S)}
mkdir -p "$out"

ASSUME_YES=1 "$here/flash.sh" "$img" "$dev"
stty -F "$tty" "${BAUD:-115200}" raw -echo
cat "$tty" > "$out/console.log" &
cap=$!
trap 'kill $cap 2>/dev/null || true' EXIT
"$here/power.sh" cycle
sleep "${BOOT_WAIT:-60}"
printf '\nwl-test-all; echo WL_DONE rc=$?\n' > "$tty"
for _ in $(seq "${TEST_TIMEOUT:-3600}"); do
    grep -q '^WL_DONE' "$out/console.log" && break
    sleep 1
done
grep -q '^WL_DONE' "$out/console.log" || { echo "timeout waiting for tests" >&2; exit 2; }
grep -E '^(PASS|FAIL|SKIP)' "$out/console.log" | tee "$out/results.txt"
! grep -q '^FAIL' "$out/results.txt"
