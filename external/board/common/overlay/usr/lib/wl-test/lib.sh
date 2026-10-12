# wl-test shell library: source it from a test. Tests print PASS/FAIL/SKIP lines
# and set WL_RC=1 on failure (use `exit $WL_RC` at the end).
WL_CONF=${WL_CONF:-/etc/wl-test.conf}
# shellcheck disable=SC1090
[ -f "$WL_CONF" ] && . "$WL_CONF"
WL_CYCLES=${WL_CYCLES:-10}
WL_SOAK_SECS=${WL_SOAK_SECS:-60}
WL_IPERF_SECS=${WL_IPERF_SECS:-30}
WL_MIN_MBPS=${WL_MIN_MBPS:-10}
WL_LEAK_KB=${WL_LEAK_KB:-2048}
WL_SUSPEND_CYCLES=${WL_SUSPEND_CYCLES:-3}
WL_SUSPEND_MODE=${WL_SUSPEND_MODE:-mem}
WL_NAME=${WL_NAME:-test}
WL_RC=0

pass() { echo "PASS $WL_NAME: $*"; }
fail() { echo "FAIL $WL_NAME: $*"; WL_RC=1; }
skip() { echo "SKIP $WL_NAME: $*"; }

# Kernel splats that must fail a run.
WL_BAD_RE='WARNING:|BUG:|Oops|KASAN:|KFENCE:|kmemleak: [0-9]+ new suspected|possible circular locking|inconsistent lock state|possible recursive locking|Unable to handle kernel|hung task|blocked for more than'
wl_bad_lines() { grep -E "$WL_BAD_RE"; }

# Check only what the kernel logged since the mark (if the ring buffer wraps
# during a long test the mark is lost; enlarge LOG_BUF_SHIFT if that happens).
wl_dmesg_mark() { WL_MARK=$(dmesg | wc -l); }
wl_dmesg_check() {
    bad=$(dmesg | tail -n +"$((${WL_MARK:-0} + 1))" | wl_bad_lines)
    if [ -n "$bad" ]; then
        echo "$bad"
        fail "kernel splat in dmesg"
    else
        pass "dmesg clean"
    fi
}

wl_wifi_if() {
    for p in /sys/class/ieee80211/*/device/net/*; do
        [ -e "$p" ] && { echo "${p##*/}"; return 0; }
    done
    return 1
}
wl_hci() {
    for p in /sys/class/bluetooth/hci*; do
        [ -e "$p" ] && { echo "${p##*/}"; return 0; }
    done
    return 1
}

wl_slab_kb() { awk '/^(Slab|SUnreclaim):/ {s+=$2} END {print s+0}' /proc/meminfo; }

# Fail if slab grew by more than WL_LEAK_KB since $1 (kB); also run kmemleak.
wl_leak_check() {
    now=$(wl_slab_kb)
    grow=$((now - $1))
    if [ "$grow" -gt "$WL_LEAK_KB" ]; then fail "slab grew ${grow}kB (limit ${WL_LEAK_KB}kB)"
    else pass "slab growth ${grow}kB"; fi
    if [ -w /sys/kernel/debug/kmemleak ]; then
        echo scan > /sys/kernel/debug/kmemleak
        if [ -s /sys/kernel/debug/kmemleak ]; then
            head -n 20 /sys/kernel/debug/kmemleak
            fail "kmemleak reports leaks"
        else pass "kmemleak clean"; fi
    fi
}

# Connect $1 to the fixed AP; needs WL_SSID. Returns 0 once COMPLETED.
wl_wifi_connect() {
    [ -n "${WL_SSID:-}" ] || return 2
    {
        echo "ctrl_interface=/var/run/wpa_supplicant"
        echo "network={"
        echo "  ssid=\"$WL_SSID\""
        if [ -n "${WL_PSK:-}" ]; then echo "  psk=\"$WL_PSK\""; else echo "  key_mgmt=NONE"; fi
        echo "}"
    } > /tmp/wl-wpa.conf
    wpa_supplicant -B -i "$1" -c /tmp/wl-wpa.conf -P /tmp/wl-wpa.pid >/dev/null 2>&1 || return 1
    t=0
    while [ "$t" -lt 30 ]; do
        wpa_cli -i "$1" status 2>/dev/null | grep -q 'wpa_state=COMPLETED' && return 0
        sleep 1; t=$((t + 1))
    done
    return 1
}
wl_wifi_disconnect() {
    [ -f /tmp/wl-wpa.pid ] && kill "$(cat /tmp/wl-wpa.pid)" 2>/dev/null
    rm -f /tmp/wl-wpa.pid
    sleep 1
}

# Mbit/s of the receiver line from iperf3 text output on stdin.
wl_iperf_mbps() {
    awk '/receiver/ { for (i = 2; i <= NF; i++) if ($i ~ /bits\/sec/) {
        v = $(i-1); u = $i
        if (u ~ /^K/) v /= 1000; else if (u ~ /^G/) v *= 1000
        print v } }'
}
