#!/bin/sh
# Host-side unit tests for the on-target shell library.
lib=$(dirname "$0")/../external/board/common/overlay/usr/lib/wl-test/lib.sh
WL_CONF=/dev/null
# shellcheck source=../external/board/common/overlay/usr/lib/wl-test/lib.sh
. "$lib"
n=0; bad=0
t() { # t <name> <expected> <actual>
    n=$((n + 1))
    [ "$2" = "$3" ] || { bad=$((bad + 1)); echo "not ok $n - $1: expected '$2' got '$3'"; }
}

splat=$(printf '%s\n' '[ 1.0] wlan0 up' '[ 2.0] WARNING: CPU: 0 at foo' '[ 3.0] BUG: KASAN: use-after-free' | wl_bad_lines | wc -l)
t "detects WARN and KASAN" 2 "$splat"
clean=$(printf '%s\n' '[ 1.0] wlan0: associated' '[ 2.0] Bluetooth: hci0 ready' | wl_bad_lines | wc -l)
t "clean log" 0 "$clean"
t "lockdep" 1 "$(echo '[ 1] possible circular locking dependency detected' | wl_bad_lines | wc -l)"
t "iperf Mbits" 94.1 "$(echo '[  5]   0.00-10.00  sec   112 MBytes  94.1 Mbits/sec                  receiver' | wl_iperf_mbps)"
t "iperf Gbits" 1500 "$(echo '[  5]   0.00-10.00  sec   1 GBytes  1.5 Gbits/sec    receiver' | wl_iperf_mbps)"
t "iperf Kbits" 0.5 "$(echo '[  5]   0.00-10.00  sec   1 KBytes  500 Kbits/sec    receiver' | wl_iperf_mbps)"
WL_NAME=x
t "pass fmt" "PASS x: ok" "$(pass ok)"
fail boom >/dev/null
t "fail sets rc" 1 "$WL_RC"

[ "$bad" = 0 ] && echo "ok: $n lib tests passed"
exit "$bad"
